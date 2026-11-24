#!/usr/bin/env bash
# =============================================================================
# 06-repo-mirror.sh: set up the internal repository for the repo-management demo.
# Runs on: your host machine (your laptop).
# How to run: ./scripts/06-repo-mirror.sh   (run 05-api-setup.sh first)
#
# Background: Ubuntu installs software from "repositories" (repos): online
# collections of packages. Companies often keep their own copy ("mirror") of a
# repo so they control exactly what their machines can install. This script
# makes Landscape create a small mirror (of the Google Chrome repo) that we
# can later hand out to client machines during the demo.
# =============================================================================

# Stop on the first error (see 00-host-prep.sh for details).
set -euo pipefail
# Load shared helpers and all settings from config/demo.env.
source "$(dirname "$0")/lib.sh"

log "Creating mirror of $MIRROR_URI ($MIRROR_SUITE) as $REPO_DISTRIBUTION/$REPO_SERIES"
# Copy scripts/remote/setup-repo-mirror.sh into the server VM and run it as the
# "ubuntu" user. The long list after it are settings from config/demo.env,
# passed to that script in the order it expects (see the "Usage" line at the
# top of scripts/remote/setup-repo-mirror.sh).
run_remote "$SERVER_VM" "$REPO_ROOT/scripts/remote/setup-repo-mirror.sh" \
  "$REPO_GPG_KEY_NAME" "$REPO_DISTRIBUTION" "$REPO_SERIES" "$REPO_POCKET" \
  "$MIRROR_COMPONENT" "$MIRROR_ARCH" "$MIRROR_URI" "$MIRROR_SUITE" "$REPO_PROFILE"

log "Sync started. To watch it finish, run:"
# The download keeps going in the background after this script ends.
# This line only PRINTS a command; it does not run it. If you want to watch
# progress, copy the printed command into your terminal. "watch" re-runs a
# command every 2 seconds; press Ctrl+C to stop watching.
echo "  multipass exec $SERVER_VM -- bash -c 'source ~/.landscape-api.rc && watch landscape-api get-activities --query type:SyncPocketRequest --limit 1'"
log "Next: portal pre-staging (docs/03-portal-prestaging.md), then scripts/07-snapshot.sh"
