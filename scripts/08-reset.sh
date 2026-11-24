#!/usr/bin/env bash
# =============================================================================
# 08-reset.sh: roll the whole lab back to the "demo-ready" snapshot.
# Runs on: your host machine (your laptop).
# How to run: ./scripts/08-reset.sh
# When: after each rehearsal, to undo everything you clicked during the demo.
#
# It always restores ALL VMs together. If you only reset some, the server and
# clients would disagree about what has happened, and the demo would misbehave.
# WARNING: any changes made since the snapshot (in any VM) are thrown away.
# =============================================================================

# Stop on the first error (see 00-host-prep.sh for details).
set -euo pipefail
# Load shared helpers and all settings from config/demo.env.
source "$(dirname "$0")/lib.sh"

log "Stopping all VMs"
# Shut down every VM in the lab (a VM must be stopped before it is restored).
multipass stop $(all_vms)

# Repeat for every VM in the lab.
for vm in $(all_vms); do
  log "Restoring $vm from $SNAPSHOT_NAME"
  # Roll this VM back to its snapshot. Multipass names snapshots "vm.snapshot",
  # e.g. "web-01.demo-ready". "--destructive" skips the "are you sure?"
  # question and discards everything that changed since the snapshot.
  multipass restore "$vm.$SNAPSHOT_NAME" --destructive
done

log "Starting all VMs"
# Boot every VM back up.
multipass start $(all_vms)

# The server can get a different IP address after a restart, so run
# 03-host-dns.sh again to update your laptop's /etc/hosts entry.
"$REPO_ROOT/scripts/03-host-dns.sh"

log "Lab reset to '$SNAPSHOT_NAME'."
