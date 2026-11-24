#!/usr/bin/env bash
# =============================================================================
# 03-host-dns.sh: let your laptop's browser reach the server by name.
# Runs on: your host machine (your laptop).
# How to run: ./scripts/03-host-dns.sh   (asks for your password)
# Safe to run again at any time, e.g. if the VM's IP address changes.
#
# Background: computers find each other by IP address (like 10.1.2.3), but we
# want to type a friendly name (like landscape.demo.internal) in the browser.
# Normally a DNS server translates names to addresses. For a small lab we skip
# that and use /etc/hosts instead: a plain text file on every Linux machine
# where each line says "this name lives at this address".
# =============================================================================

# Stop on the first error (see 00-host-prep.sh for details).
set -euo pipefail
# Load shared helpers and all settings from config/demo.env.
source "$(dirname "$0")/lib.sh"

# Ask Multipass for the server VM's current IP address and store it in "IP".
IP="$(server_ip)"

log "Pointing $FQDN at $IP in /etc/hosts"
# Remove any old line for the server name, so we never end up with two.
#   sed -i      edit the file in place
#   "/.../d"    delete every line matching the pattern between the slashes
#   [[:space:]]$FQDN\$   = a space or tab, then the server name, then the end of
#                the line (the "\$" means "end of line" here)
# "sudo" is needed because /etc/hosts belongs to the administrator.
sudo sed -i "/[[:space:]]$FQDN\$/d" /etc/hosts
# Add a fresh line "IP NAME" to the end of the file.
# "echo" prints the line, "|" passes it to "tee", and "tee -a" appends
# ("-a") it to /etc/hosts. We use "sudo tee" instead of ">>" because a plain
# ">>" would not have administrator rights.
echo "$IP $FQDN" | sudo tee -a /etc/hosts

log "Done. Now open https://$FQDN in your browser (see docs/02-first-login.md)."
