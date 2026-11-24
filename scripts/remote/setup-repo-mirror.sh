#!/usr/bin/env bash
# =============================================================================
# setup-repo-mirror.sh: build a small internal apt mirror in Landscape.
# Runs on: the server VM, as the "ubuntu" user (called by scripts/06-repo-mirror.sh).
# Usage:   setup-repo-mirror.sh <gpg-key-name> <distribution> <series> <pocket> \
#                               <component> <arch> <mirror-uri> <mirror-suite> <profile>
# Create steps end in "|| true" so the script can be re-run safely.
# =============================================================================
set -euo pipefail
KEY="$1"; DIST="$2"; SERIES="$3"; POCKET="$4"; COMPONENT="$5"; ARCH="$6"
URI="$7"; SUITE="$8"; PROFILE="$9"
KEY_EMAIL="mirror@demo.internal"

# Load the API keys and server address
source "$HOME/.landscape-api.rc"

# Create a signing key for the mirror (no passphrase), unless one exists already
gpg --list-secret-keys "$KEY_EMAIL" >/dev/null 2>&1 || \
  gpg --batch --passphrase '' --quick-gen-key "Landscape Demo Mirror <$KEY_EMAIL>" rsa3072 sign never
# Export the private key so Landscape can sign the mirror with it
gpg --armor --export-secret-keys "$KEY_EMAIL" > "$HOME/$KEY.asc"
# Upload the signing key to Landscape
landscape-api import-gpg-key "$KEY" "$HOME/$KEY.asc" || true

# Create a Landscape "distribution" to hold the internal repo
landscape-api create-distribution "$DIST" || true
# Create a series inside it that mirrors the upstream repo (no download yet)
landscape-api create-series --pockets "$POCKET" --components "$COMPONENT" \
  --architectures "$ARCH" --gpg-key "$KEY" \
  --mirror-uri "$URI" --mirror-series "$SUITE" "$SERIES" "$DIST" || true
# Start downloading the upstream packages into the mirror (runs in the background)
landscape-api sync-mirror-pocket "$POCKET" "$SERIES" "$DIST"

# Create a repository profile that will hand this mirror out to machines
landscape-api create-repository-profile --description "Internally distributed apps" "$PROFILE" || true
# Add the mirror's pocket to the profile (not linked to any machines yet)
landscape-api add-pockets-to-repository-profile "$PROFILE" "$POCKET" "$SERIES" "$DIST" || true

# Show the latest sync job so you can see its progress
landscape-api get-activities --query type:SyncPocketRequest --limit 1
