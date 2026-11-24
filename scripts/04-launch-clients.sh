#!/usr/bin/env bash
# =============================================================================
# 04-launch-clients.sh: create the client VMs and register them with Landscape.
# Runs on: your host machine.
# =============================================================================
set -euo pipefail
source "$(dirname "$0")/lib.sh"

# Look up the server VM's IP so clients can find it
IP="$(server_ip)"

# Go through every client listed in config/demo.env
for spec in "${CLIENTS[@]}"; do
  # Split "name:release:tags" into its three parts
  IFS=: read -r name release tags <<< "$spec"

  log "Launching $name (Ubuntu $release, tags: $tags)"
  # Create and boot the client VM, unless it already exists
  if vm_exists "$name"; then
    echo "$name already exists, skipping launch."
  else
    multipass launch "$release" --name "$name" \
      --cpus "$CLIENT_CPUS" --memory "$CLIENT_MEM" --disk "$CLIENT_DISK"
  fi

  log "Registering $name with $FQDN"
  # Copy the registration script into the client and run it as root
  run_remote_sudo "$name" "$REPO_ROOT/scripts/remote/register-client.sh" \
    "$name" "$tags" "$IP" "$FQDN" \
    "$EXCHANGE_INTERVAL" "$URGENT_EXCHANGE_INTERVAL" "$PING_INTERVAL"
done

log "All clients registered. Accept them in the portal: Computers -> Pending."
log "Next: create API keys (docs/02-first-login.md), then scripts/05-api-setup.sh"
