#!/usr/bin/env bash
# =============================================================================
# 09-preflight.sh: demo-day check. Starts everything and confirms it's healthy.
# Runs on: your host machine (your laptop).
# How to run: ./scripts/09-preflight.sh
# When: about 10 minutes before you present.
# Read the output: look for "HTTP 200" (or 301/302) and no "WARNING" lines.
# =============================================================================

# Stop on the first error (see 00-host-prep.sh for details).
set -euo pipefail
# Load shared helpers and all settings from config/demo.env.
source "$(dirname "$0")/lib.sh"

log "Starting all VMs"
# Boot every VM in the lab. VMs that are already running are left alone.
multipass start $(all_vms)

log "Refreshing /etc/hosts"
# Make sure your laptop still knows the server's current IP address.
"$REPO_ROOT/scripts/03-host-dns.sh"

log "Checking the web portal responds"
# "curl" fetches a web page from the command line. Here we only want to know
# whether the server answers, so:
#   -s           silent: no progress bar
#   -k           accept the server's self-made ("self-signed") certificate,
#                which browsers and curl don't trust by default
#   -o /dev/null throw the page itself away
#   -w "..."     print just the HTTP status code. 200 means "OK"; 301/302 mean
#                "go to another page" (also fine). Anything else is a problem.
curl -sk -o /dev/null -w "HTTP %{http_code}\n" "https://$FQDN/"

# Check each client in turn (the list comes from config/demo.env).
for spec in "${CLIENTS[@]}"; do
  # Keep only the VM name from an entry like "web-01:24.04:demo,web".
  name="${spec%%:*}"
  log "Checking registration on $name"
  # Ask the client whether it is still registered with the server.
  # "A || B" means "run A, and only if A fails, run B". So we print a warning
  # instead of stopping the whole script when one client has a problem.
  multipass exec "$name" -- sudo landscape-config --is-registered || \
    echo "WARNING: $name does not look registered."
done

log "Current VM status"
# Show a table of every VM with its state (Running/Stopped) and IP address.
multipass list

log "Preflight done. See docs/04-run-of-show.md for the demo sequence."
