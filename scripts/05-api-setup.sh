#!/usr/bin/env bash
# =============================================================================
# 05-api-setup.sh: give the server VM your API keys and test the API.
# Runs on: your host machine (your laptop).
# Needs:   config/api.env with your keys in it. Create it first:
#            cp config/api.env.example config/api.env
#          ("cp" copies a file), then open config/api.env in a text editor
#          and paste in the keys from the web portal.
# How to run: ./scripts/05-api-setup.sh
#
# What is an API? An "application programming interface" lets scripts control
# Landscape directly, instead of clicking around in the web portal. The API
# keys are like a username and password for scripts.
# =============================================================================

# Stop on the first error (see 00-host-prep.sh for details).
set -euo pipefail
# Load shared helpers and all settings from config/demo.env.
source "$(dirname "$0")/lib.sh"

# Stop early with a helpful message if the keys file hasn't been created yet.
#   [[ ... ]]   a test that is either true or false
#   -f FILE     true if FILE exists
#   !           flips the result, so this reads "if the file does NOT exist"
if [[ ! -f "$REPO_ROOT/config/api.env" ]]; then
  # ">&2" prints the message as an error message rather than normal output.
  echo "Missing config/api.env. Copy config/api.env.example and add your keys." >&2
  # End the script. "exit 1" means "finished with an error" (0 means success).
  exit 1
fi

log "Copying API keys into $SERVER_VM"
# Copy the keys file from your laptop into the server VM's /tmp folder.
# The format "VM:path" means "this path inside that VM".
multipass transfer "$REPO_ROOT/config/api.env" "$SERVER_VM:/tmp/api.env"

log "Configuring landscape-api and testing the connection"
# Copy scripts/remote/setup-api.sh into the server VM and run it as the normal
# "ubuntu" user (not root), passing it the server's name.
run_remote "$SERVER_VM" "$REPO_ROOT/scripts/remote/setup-api.sh" "$FQDN"

log "API ready. Next: scripts/06-repo-mirror.sh"
