#!/usr/bin/env bash
# =============================================================================
# setup-repo-mirror.sh: build a small internal apt mirror in Landscape.
# Runs on: the server VM, as the normal "ubuntu" user.
# You don't run this yourself: scripts/06-repo-mirror.sh copies it into the VM
# and runs it for you.
# Usage:   setup-repo-mirror.sh <gpg-key-name> <distribution> <series> <pocket> \
#                               <component> <arch> <mirror-uri> <mirror-suite> <profile>
#
# Safe to run again: the "create" steps end in "|| true", which means "if this
# fails (usually because it already exists), carry on anyway".
#
# Landscape organises a mirror in layers, a bit like nested folders:
#   distribution  (e.g. "internal")   a top-level container
#    └ series     (e.g. "chrome")     one mirrored upstream repository
#       └ pocket  (e.g. "release")    the actual set of packages
# A "repository profile" then hands that pocket out to chosen machines.
# =============================================================================

# Stop on the first error (see scripts/00-host-prep.sh for details).
set -euo pipefail
# Give the nine arguments readable names ($1 is the first, $2 the second...).
KEY="$1"; DIST="$2"; SERIES="$3"; POCKET="$4"; COMPONENT="$5"; ARCH="$6"
URI="$7"; SUITE="$8"; PROFILE="$9"
# A made-up email address that labels the signing key below.
KEY_EMAIL="mirror@demo.internal"

# Load the API keys and server address (created by setup-api.sh).
source "$HOME/.landscape-api.rc"

# Create a "GPG signing key" for the mirror. Ubuntu only trusts a repository if
# its package list is digitally signed, like a wax seal proving nobody changed
# it. "gpg" is the standard tool for making and using such keys.
# The first command checks whether the key already exists; only if it doesn't
# ("||"), the second command creates one with no passphrase ("--passphrase ''").
gpg --list-secret-keys "$KEY_EMAIL" >/dev/null 2>&1 || \
  gpg --batch --passphrase '' --quick-gen-key "Landscape Demo Mirror <$KEY_EMAIL>" rsa3072 sign never
# Export the private part of the key to a text file, so Landscape can use it to
# sign the mirror. ("--armor" saves it as readable text instead of binary.)
gpg --armor --export-secret-keys "$KEY_EMAIL" > "$HOME/$KEY.asc"
# Upload that key file to Landscape under the name in $KEY.
landscape-api import-gpg-key "$KEY" "$HOME/$KEY.asc" || true

# Create the top-level "distribution" that will hold our internal repository.
landscape-api create-distribution "$DIST" || true
# Create a "series" inside it, set up to copy the upstream repo at $URI.
# This only describes the mirror; no packages are downloaded yet.
landscape-api create-series --pockets "$POCKET" --components "$COMPONENT" \
  --architectures "$ARCH" --gpg-key "$KEY" \
  --mirror-uri "$URI" --mirror-series "$SUITE" "$SERIES" "$DIST" || true
# Start downloading the upstream packages into the mirror. Landscape does this
# in the background, so the script continues straight away.
landscape-api sync-mirror-pocket "$POCKET" "$SERIES" "$DIST"

# Create a "repository profile": a rule that will hand this mirror out to
# machines. You link it to machines later, live in the portal, during the demo.
landscape-api create-repository-profile --description "Internally distributed apps" "$PROFILE" || true
# Put our mirror's pocket into the profile (not linked to any machines yet).
landscape-api add-pockets-to-repository-profile "$PROFILE" "$POCKET" "$SERIES" "$DIST" || true

# Show the most recent download job, so you can see it has started.
landscape-api get-activities --query type:SyncPocketRequest --limit 1
