#!/usr/bin/env bash
# =============================================================================
# 07-snapshot.sh: save the fully prepared lab so you can reset to it later.
# Runs on: your host machine. Run once everything is staged and working.
# =============================================================================
set -euo pipefail
source "$(dirname "$0")/lib.sh"

log "Stopping all VMs (snapshots require stopped VMs)"
# Shut down every VM in the lab
multipass stop $(all_vms)

# Snapshot every VM under the same name
for vm in $(all_vms); do
  log "Snapshotting $vm as $SNAPSHOT_NAME"
  # Save the VM's current state as a named snapshot
  multipass snapshot "$vm" --name "$SNAPSHOT_NAME"
done

log "Starting all VMs again"
# Boot every VM back up
multipass start $(all_vms)

log "Snapshot '$SNAPSHOT_NAME' saved. Use scripts/08-reset.sh to return to it."
