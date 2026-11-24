#!/usr/bin/env bash
# =============================================================================
# 00-host-prep.sh: get your laptop ready to run the demo VMs.
# Runs on: your host machine.
# =============================================================================
set -euo pipefail
source "$(dirname "$0")/lib.sh"

log "Checking hardware virtualisation"
# Refresh the host's package lists
sudo apt-get update
# Install cpu-checker, which provides the kvm-ok tool
sudo apt-get install -y cpu-checker
# Confirm KVM is usable (Multipass needs it to run VMs at full speed)
kvm-ok

log "Installing Multipass"
# Install Multipass, the tool that creates and manages the Ubuntu VMs
sudo snap install multipass
# Print the Multipass version to confirm it works
multipass version

log "Host is ready. Next: scripts/01-launch-server.sh"
