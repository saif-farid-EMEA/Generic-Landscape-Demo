#!/usr/bin/env bash
# =============================================================================
# 07-snapshot.sh: save the fully prepared lab so you can reset to it later.
# Runs on: your host machine (your laptop).
# How to run: ./scripts/07-snapshot.sh
# When: once, after everything is set up and working.
#
# A "snapshot" is a saved copy of a VM's disk at a moment in time, a bit like a
# save point in a video game. After rehearsing the demo, 08-reset.sh loads
# this save point so every run starts from the same clean state.
# =============================================================================

# Stop on the first error (see 00-host-prep.sh for details).
set -euo pipefail
# Load shared helpers and all settings from config/demo.env.
source "$(dirname "$0")/lib.sh"

log "Stopping all VMs (snapshots require stopped VMs)"
# Shut down every VM. $(all_vms) is replaced by the list of VM names
# (server and clients), so this becomes e.g.
#   multipass stop landscape-server web-01 db-01 legacy-01
multipass stop $(all_vms)

# Repeat for every VM: take a snapshot with the same name on each one.
for vm in $(all_vms); do
  log "Snapshotting $vm as $SNAPSHOT_NAME"
  # Save this VM's current state under the name from config/demo.env.
  multipass snapshot "$vm" --name "$SNAPSHOT_NAME"
done

log "Starting all VMs again"
# Boot every VM back up.
multipass start $(all_vms)

log "Snapshot '$SNAPSHOT_NAME' saved. Use scripts/08-reset.sh to return to it."
