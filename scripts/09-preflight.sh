#!/usr/bin/env bash
# =============================================================================
# 09-preflight.sh: demo-day check. Starts everything and confirms it's healthy.
# Runs on: your host machine, about 10 minutes before you present.
# =============================================================================
set -euo pipefail
source "$(dirname "$0")/lib.sh"

log "Starting all VMs"
# Boot every VM in the lab (no-op for ones already running)
multipass start $(all_vms)

log "Refreshing /etc/hosts"
# Make sure the host still points the server name at the right IP
"$REPO_ROOT/scripts/03-host-dns.sh"

log "Checking the web portal responds"
# Request the portal page and print the HTTP status code (expect 200 or 30x)
curl -sk -o /dev/null -w "HTTP %{http_code}\n" "https://$FQDN/"

# Confirm each client is still registered
for spec in "${CLIENTS[@]}"; do
  name="${spec%%:*}"
  log "Checking registration on $name"
  # Ask the client whether it is registered with the server
  multipass exec "$name" -- sudo landscape-config --is-registered || \
    echo "WARNING: $name does not look registered."
done

log "Current VM status"
# Show every VM with its state and IP
multipass list

log "Preflight done. See docs/04-run-of-show.md for the demo sequence."
