#!/usr/bin/env bash
# =============================================================================
# 02-install-server.sh: install Landscape Server inside the server VM.
# Runs on: your host machine (pushes scripts/remote/install-server.sh to the VM).
# =============================================================================
set -euo pipefail
source "$(dirname "$0")/lib.sh"

log "Installing Landscape Server from $LANDSCAPE_PPA (about 5 minutes)"
# Copy the install script into the server VM and run it as root
run_remote_sudo "$SERVER_VM" "$REPO_ROOT/scripts/remote/install-server.sh" "$LANDSCAPE_PPA"

log "Landscape Server installed. Next: scripts/03-host-dns.sh"
