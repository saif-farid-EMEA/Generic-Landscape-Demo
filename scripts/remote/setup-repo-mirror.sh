#!/usr/bin/env bash
# =============================================================================
# setup-repo-mirror.sh: create the GPG signing key for the internal mirror.
# Runs on: the server VM, as the normal "ubuntu" user.
# You don't run this yourself: scripts/06-repo-mirror.sh copies it into the VM
# and runs it for you.
# Usage:   setup-repo-mirror.sh <key-file-name>
#
# Why only a key? In Landscape 26.04, repository mirrors are handled by the new
# Debarchive service, and the old command-line (legacy API) commands for mirrors
# were removed. You now create the mirror itself in the web portal (steps in
# docs/03-portal-prestaging.md). What we CAN prepare here is the signing key.
#
# What's a GPG signing key? Ubuntu only trusts a repository if its package list
# is digitally signed, like a wax seal proving nobody changed it. Landscape
# signs your mirror with the PRIVATE key; clients check the seal with the
# matching PUBLIC key. "gpg" is the standard tool for making such keys.
#
# Safe to run again: an existing key is reused, not replaced.
# =============================================================================

# Stop on the first error (see scripts/00-host-prep.sh for details).
set -euo pipefail
# The first argument: the base name for the exported key files, e.g. "mirror-key"
KEY="$1"
# A made-up email address that labels the signing key.
KEY_EMAIL="mirror@demo.internal"

# Create the key, unless one exists already. The first command checks for it;
# only if it's missing ("||"), the second creates one. Landscape requires the
# key to have NO passphrase ("--passphrase ''"), because it signs
# automatically, with nobody there to type one.
gpg --list-secret-keys "$KEY_EMAIL" >/dev/null 2>&1 || \
  gpg --batch --passphrase '' --quick-gen-key "Landscape Demo Mirror <$KEY_EMAIL>" rsa3072 sign never

# Save both halves of the key as text files in this user's home folder.
# ("--armor" saves them as readable text instead of binary.)
#   $KEY-private.asc  you paste this into the portal's Publication "Signing GPG key"
#   $KEY-public.asc   you paste this into the Repository profile's "GPG key"
gpg --armor --export-secret-keys "$KEY_EMAIL" > "$HOME/$KEY-private.asc"
gpg --armor --export "$KEY_EMAIL" > "$HOME/$KEY-public.asc"
# Make the private key readable only by this user.
chmod 600 "$HOME/$KEY-private.asc"
