#!/usr/bin/env bash
# =============================================================================
# 01-launch-server.sh: create the VM that will host Landscape Server.
# Runs on: your host machine (your laptop).
# How to run: ./scripts/01-launch-server.sh
# Safe to run again: if the VM already exists, it is not created twice.
# =============================================================================

# Stop on the first error (see 00-host-prep.sh for what each letter means).
set -euo pipefail
# Load shared helpers and all settings from config/demo.env.
source "$(dirname "$0")/lib.sh"

log "Writing cloud-init for $SERVER_VM"
# cloud-init is a standard way to give a brand-new VM instructions for its very
# first boot. Here we tell it which name to use for itself.
#
# How this command works:
#   cat > FILE <<EOF ... EOF
# writes all the lines between "<<EOF" and the closing "EOF" into FILE.
# (">" means "send the output into this file, replacing what was there".)
# Variables such as $FQDN inside the block are replaced with their values.
#
# The settings written:
#   hostname          the short machine name, e.g. "landscape"
#   fqdn              the "fully qualified domain name": the complete name,
#                     e.g. "landscape.demo.internal", used in the browser
#   manage_etc_hosts  keeps the VM's /etc/hosts file (a simple name-to-address
#                     list) pointing that name at the VM itself
cat > "$BUILD_DIR/server-init.yaml" <<EOF
#cloud-config
hostname: $SERVER_HOSTNAME
fqdn: $FQDN
manage_etc_hosts: true
EOF

log "Launching $SERVER_VM ($SERVER_CPUS vCPU / $SERVER_MEM RAM / $SERVER_DISK disk)"
# "if ...; then ... else ... fi" is Bash's if/else ("fi" is "if" backwards and
# marks the end). vm_exists (from lib.sh) checks whether the VM is already there.
if vm_exists "$SERVER_VM"; then
  # "echo" simply prints text to the screen.
  echo "$SERVER_VM already exists, skipping launch."
else
  # Create and boot a new VM:
  #   "$SERVER_RELEASE"  which Ubuntu version to install, e.g. 24.04
  #   --name             the VM's name
  #   --cpus/--memory/--disk  how much of your laptop's resources it may use
  #   --cloud-init       the first-boot instructions file we just wrote
  # The "\" at the end of a line means "this command continues on the next line".
  multipass launch "$SERVER_RELEASE" --name "$SERVER_VM" \
    --cpus "$SERVER_CPUS" --memory "$SERVER_MEM" --disk "$SERVER_DISK" \
    --cloud-init "$BUILD_DIR/server-init.yaml"
fi

log "Verifying hostname"
# "multipass exec VM -- COMMAND" runs COMMAND inside the VM.
# "hostname -f" prints the VM's full name; it should match $FQDN.
multipass exec "$SERVER_VM" -- hostname -f

# $(server_ip) runs the server_ip helper and inserts the IP address it prints.
log "Server VM is up at $(server_ip). Next: scripts/02-install-server.sh"
