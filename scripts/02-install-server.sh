#!/usr/bin/env bash
# =============================================================================
# 02-install-server.sh: install Landscape Server inside the server VM.
# Runs on: your host machine (your laptop). It copies the real install script,
#          scripts/remote/install-server.sh, into the VM and runs it there.
# How to run: ./scripts/02-install-server.sh
# Takes about 5 minutes. Lots of text scrolling past is normal.
# =============================================================================

# Stop on the first error (see 00-host-prep.sh for details).
set -euo pipefail
# Load shared helpers and all settings from config/demo.env.
source "$(dirname "$0")/lib.sh"

log "Installing Landscape Server from $LANDSCAPE_PPA (about 5 minutes)"
# run_remote_sudo (from lib.sh) copies a script into a VM and runs it as root
# (administrator). The arguments are:
#   1. "$SERVER_VM"         which VM to run it in
#   2. ".../install-server.sh"  which script to copy and run
#   3. "$LANDSCAPE_PPA"     passed on to that script: where to download
#                           Landscape from (a PPA is an extra software source)
run_remote_sudo "$SERVER_VM" "$REPO_ROOT/scripts/remote/install-server.sh" "$LANDSCAPE_PPA"

log "Landscape Server installed. Next: scripts/03-host-dns.sh"
