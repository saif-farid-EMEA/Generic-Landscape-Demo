#!/usr/bin/env bash
# =============================================================================
# 03-host-dns.sh: let your laptop's browser reach the server by name.
# Runs on: your host machine. Safe to re-run (e.g. if the VM's IP changes).
# =============================================================================
set -euo pipefail
source "$(dirname "$0")/lib.sh"

# Look up the server VM's current IP address
IP="$(server_ip)"

log "Pointing $FQDN at $IP in /etc/hosts"
# Remove any old entry for the server name
sudo sed -i "/[[:space:]]$FQDN\$/d" /etc/hosts
# Add a fresh entry mapping the server name to its current IP
echo "$IP $FQDN" | sudo tee -a /etc/hosts

log "Done. Now open https://$FQDN in your browser (see docs/02-first-login.md)."
