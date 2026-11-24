#!/usr/bin/env bash
# =============================================================================
# 99-cleanup.sh: delete the whole lab from your laptop.
# Runs on: your host machine. This is permanent: VMs and snapshots are removed.
# =============================================================================
set -euo pipefail
source "$(dirname "$0")/lib.sh"

# Ask for confirmation before deleting anything
read -r -p "Delete ALL demo VMs and snapshots? Type 'yes' to continue: " answer
[[ "$answer" == "yes" ]] || { echo "Aborted."; exit 0; }

log "Deleting VMs"
# Delete every VM in the lab and free its disk space immediately
multipass delete --purge $(all_vms)

log "Removing the server name from /etc/hosts"
# Remove the hosts entry that pointed at the server
sudo sed -i "/[[:space:]]$FQDN\$/d" /etc/hosts

log "Removing generated files"
# Delete the build folder (generated cloud-init files)
rm -rf "$BUILD_DIR"

log "Cleanup complete."
