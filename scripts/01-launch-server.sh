#!/usr/bin/env bash
# =============================================================================
# 01-launch-server.sh: create the VM that will host Landscape Server.
# Runs on: your host machine.
# =============================================================================
set -euo pipefail
source "$(dirname "$0")/lib.sh"

log "Writing cloud-init for $SERVER_VM"
# Generate a cloud-init file that gives the VM its full domain name (FQDN)
# and keeps /etc/hosts pointing that name at the VM itself
cat > "$BUILD_DIR/server-init.yaml" <<EOF
#cloud-config
hostname: $SERVER_HOSTNAME
fqdn: $FQDN
manage_etc_hosts: true
EOF

log "Launching $SERVER_VM ($SERVER_CPUS vCPU / $SERVER_MEM RAM / $SERVER_DISK disk)"
# Create and boot the server VM, unless it already exists
if vm_exists "$SERVER_VM"; then
  echo "$SERVER_VM already exists, skipping launch."
else
  multipass launch "$SERVER_RELEASE" --name "$SERVER_VM" \
    --cpus "$SERVER_CPUS" --memory "$SERVER_MEM" --disk "$SERVER_DISK" \
    --cloud-init "$BUILD_DIR/server-init.yaml"
fi

log "Verifying hostname"
# Print the VM's full hostname; it should match $FQDN
multipass exec "$SERVER_VM" -- hostname -f

log "Server VM is up at $(server_ip). Next: scripts/02-install-server.sh"
