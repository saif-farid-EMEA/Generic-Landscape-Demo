#!/usr/bin/env bash
# =============================================================================
# 99-cleanup.sh: delete the whole lab from your laptop.
# Runs on: your host machine (your laptop).
# How to run: ./scripts/99-cleanup.sh   (asks you to type "yes" first)
# WARNING: this is permanent. All VMs and snapshots are deleted and cannot be
# brought back. You would have to run the setup from 00 again.
# (Multipass itself stays installed.)
# =============================================================================

# Stop on the first error (see 00-host-prep.sh for details).
set -euo pipefail
# Load shared helpers and all settings from config/demo.env.
source "$(dirname "$0")/lib.sh"

# Ask for confirmation before deleting anything.
# "read -p" shows the question and waits for you to type an answer and press
# Enter; what you type is stored in the variable "answer".
read -r -p "Delete ALL demo VMs and snapshots? Type 'yes' to continue: " answer
# If the answer is exactly "yes", carry on. Otherwise ("||" = "if not"), print
# "Aborted." and exit without deleting anything.
[[ "$answer" == "yes" ]] || { echo "Aborted."; exit 0; }

log "Deleting VMs"
# Delete every lab VM that exists. VMs that were never created (for example
# after a setup that stopped halfway) are skipped: asking Multipass to delete
# a VM that isn't there is an error, which would stop this script early.
# "--purge" frees the disk space immediately instead of keeping deleted VMs
# around in a recoverable state.
# Each VM is first detached from Ubuntu Pro, which frees its place on your Pro
# token; otherwise every rebuild would use up more of the token's machines.
for vm in $(all_vms); do
  if vm_exists "$vm"; then
    pro_detach "$vm"
    multipass delete --purge "$vm"
    echo "Deleted $vm"
  fi
done

log "Removing the server name from /etc/hosts"
# Delete the line that 03-host-dns.sh added to your laptop's /etc/hosts file
# (see that script for how this "sed" command works).
sudo sed -i "/[[:space:]]$FQDN\$/d" /etc/hosts

log "Removing generated files"
# Delete the build/ folder (generated cloud-init files).
# "rm -rf" removes a folder and everything in it without asking. Be careful
# with this command in your own work: there is no recycle bin.
rm -rf "$BUILD_DIR"

log "Cleanup complete."
