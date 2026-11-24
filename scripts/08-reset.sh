#!/usr/bin/env bash
# =============================================================================
# 08-reset.sh: roll the whole lab back to the "demo-ready" snapshot.
# Runs on: your host machine. Use after each rehearsal.
# Always restores ALL VMs together so the server and clients stay in sync.
# =============================================================================
set -euo pipefail
source "$(dirname "$0")/lib.sh"

log "Stopping all VMs"
# Shut down every VM in the lab
multipass stop $(all_vms)

# Restore every VM from the shared snapshot
for vm in $(all_vms); do
  log "Restoring $vm from $SNAPSHOT_NAME"
  # Roll the VM back, discarding everything since the snapshot
  multipass restore "$vm.$SNAPSHOT_NAME" --destructive
done

log "Starting all VMs"
# Boot every VM back up
multipass start $(all_vms)

# Refresh the host's /etc/hosts entry in case the server IP changed
"$REPO_ROOT/scripts/03-host-dns.sh"

log "Lab reset to '$SNAPSHOT_NAME'."
