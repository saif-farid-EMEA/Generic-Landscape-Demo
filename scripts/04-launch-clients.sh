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

# Each client is attached to Ubuntu Pro before registering, which Landscape
# requires. Read the token now, so a missing one stops us before any VM is made.
load_pro_token

# Before creating any client, make sure Landscape is actually running on the
# server. Otherwise every registration would fail, one slow client at a time.
log "Checking Landscape Server is running on $SERVER_VM"
if ! multipass exec "$SERVER_VM" -- systemctl is-active --quiet \
     landscape-appserver landscape-msgserver landscape-pingserver; then
  echo "ERROR: Landscape Server is not running on $SERVER_VM." >&2
  echo "Re-run ./scripts/02-install-server.sh (it repairs a half-finished install)." >&2
  exit 1
fi
# Clients join the "standalone" account, which only exists once the first
# administrator has been created in the browser (docs/02-first-login.md).
# Without it every client fails with "Invalid account name or registration key".
# This asks the server's database how many accounts are named "standalone".
ACCOUNTS="$(multipass exec "$SERVER_VM" -- sudo -u postgres psql -d landscape-standalone-main \
  -tAc "SELECT count(*) FROM account WHERE name='standalone'")"
if [[ "$ACCOUNTS" != "1" ]]; then
  echo "ERROR: Landscape has no administrator account yet." >&2
  echo "Open https://$FQDN, create the first administrator (docs/02-first-login.md)," >&2
  echo "then run this script again." >&2
  exit 1
fi

# Look up the server VM's IP address so the clients can find it.
IP="$(server_ip)"

# A "for" loop repeats the code between "do" and "done" once per item.
# "${CLIENTS[@]}" means "every entry in the CLIENTS list". On each round,
# the current entry is stored in "spec", e.g. "web-01:24.04:demo,web".
for spec in "${CLIENTS[@]}"; do
  # Split the entry at each ":" into four variables, e.g. for
  # "db-01:24.04:demo,db:8G":
  #   name="db-01"   release="24.04"   tags="demo,db"   mem="8G"
  # (IFS=: tells "read" to split on colons; "<<<" feeds it the text in $spec.)
  # If the entry has no memory part, "mem" is left empty.
  IFS=: read -r name release tags mem <<< "$spec"
  # "${mem:-$CLIENT_MEM}" means "use mem, or CLIENT_MEM if mem is empty".
  mem="${mem:-$CLIENT_MEM}"

  log "Launching $name (Ubuntu $release, $mem RAM, tags: $tags)"
  # Create and boot the client VM, unless it already exists.
  if vm_exists "$name"; then
    echo "$name already exists, skipping launch."
  else
    # Same as the server launch in 01-launch-server.sh, but smaller and with
    # no cloud-init file. The "\" continues the command on the next line.
    multipass launch "$release" --name "$name" \
      --cpus "$CLIENT_CPUS" --memory "$mem" --disk "$CLIENT_DISK"
  fi

  log "Attaching $name to Ubuntu Pro"
  # pro_attach (from lib.sh) skips VMs that are already attached.
  pro_attach "$name"

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
