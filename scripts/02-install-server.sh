#!/usr/bin/env bash
# =============================================================================
# 02-install-server.sh: install Landscape Server 26.04 LTS inside the server VM.
# Runs on: your host machine (your laptop). It copies the real install script,
#          scripts/remote/install-server.sh, into the VM and runs it there.
# How to run: ./scripts/02-install-server.sh
# Takes about 10 minutes. Lots of text scrolling past is normal.
# =============================================================================

# Stop on the first error (see 00-host-prep.sh for details).
set -euo pipefail
# Load shared helpers and all settings from config/demo.env.
source "$(dirname "$0")/lib.sh"

# Read the Ubuntu Pro token from config/pro.env (stops here if it's missing),
# then attach the server VM to Ubuntu Pro (skipped if already attached).
load_pro_token
log "Attaching $SERVER_VM to Ubuntu Pro"
pro_attach "$SERVER_VM"

log "Installing Landscape Server from $LANDSCAPE_PPA (about 10 minutes)"
# run_remote_sudo (from lib.sh) copies a script into a VM and runs it as root
# (administrator). The arguments are:
#   1. "$SERVER_VM"         which VM to run it in
#   2. ".../install-server.sh"  which script to copy and run
#   3. "$LANDSCAPE_PPA"     passed on to that script: where to download
#                           Landscape from (a PPA is an extra software source)
#   4. "$FQDN"              the server's full name, used to set up the web server
#   5. "$SERVER_SWAP"       how much swap (overflow memory) to give the VM
# The remote script ends with a health check and fails (stopping this script
# too) if Landscape is not actually serving, so "installed" below is real.
# Safe to run again: re-running it also repairs a half-finished install.
run_remote_sudo "$SERVER_VM" "$REPO_ROOT/scripts/remote/install-server.sh" \
  "$LANDSCAPE_PPA" "$FQDN" "$SERVER_SWAP"

log "Landscape Server installed and healthy. Next: scripts/03-host-dns.sh"
