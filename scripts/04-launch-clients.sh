#!/usr/bin/env bash
# =============================================================================
# 04-launch-clients.sh: create the client VMs and register them with Landscape.
# Runs on: your host machine (your laptop).
# How to run: ./scripts/04-launch-clients.sh
#
# "Clients" are the machines Landscape will manage (in real life: your company's
# servers and desktops). "Registering" a client means introducing it to the
# Landscape server so it shows up in the web portal.
# The list of clients comes from the CLIENTS setting in config/demo.env.
# =============================================================================

# Stop on the first error (see 00-host-prep.sh for details).
set -euo pipefail
# Load shared helpers and all settings from config/demo.env.
source "$(dirname "$0")/lib.sh"

# Look up the server VM's IP address so the clients can find it.
IP="$(server_ip)"

# A "for" loop repeats the code between "do" and "done" once per item.
# "${CLIENTS[@]}" means "every entry in the CLIENTS list". On each round,
# the current entry is stored in "spec", e.g. "web-01:24.04:demo,web".
for spec in "${CLIENTS[@]}"; do
  # Split the entry at each ":" into three variables:
  #   name="web-01"   release="24.04"   tags="demo,web"
  # (IFS=: tells "read" to split on colons; "<<<" feeds it the text in $spec.)
  IFS=: read -r name release tags <<< "$spec"

  log "Launching $name (Ubuntu $release, tags: $tags)"
  # Create and boot the client VM, unless it already exists.
  if vm_exists "$name"; then
    echo "$name already exists, skipping launch."
  else
    # Same as the server launch in 01-launch-server.sh, but smaller and with
    # no cloud-init file. The "\" continues the command on the next line.
    multipass launch "$release" --name "$name" \
      --cpus "$CLIENT_CPUS" --memory "$CLIENT_MEM" --disk "$CLIENT_DISK"
  fi

  log "Registering $name with $FQDN"
  # Copy scripts/remote/register-client.sh into the client and run it as root.
  # Everything after the script path is handed to that script, in this order:
  # client name, tags, server IP, server name, and three check-in timings.
  run_remote_sudo "$name" "$REPO_ROOT/scripts/remote/register-client.sh" \
    "$name" "$tags" "$IP" "$FQDN" \
    "$EXCHANGE_INTERVAL" "$URGENT_EXCHANGE_INTERVAL" "$PING_INTERVAL"
done

log "All clients registered. Accept them in the portal: Computers -> Pending."
log "Next: create API keys (docs/02-first-login.md), then scripts/05-api-setup.sh"
