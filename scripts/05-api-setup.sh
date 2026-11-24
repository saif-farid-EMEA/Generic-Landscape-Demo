#!/usr/bin/env bash
# =============================================================================
# 05-api-setup.sh: give the server VM your API keys and test the API.
# Runs on: your host machine. Needs config/api.env (copy from api.env.example).
# =============================================================================
set -euo pipefail
source "$(dirname "$0")/lib.sh"

# Stop early if the API keys file hasn't been created yet
if [[ ! -f "$REPO_ROOT/config/api.env" ]]; then
  echo "Missing config/api.env. Copy config/api.env.example and add your keys." >&2
  exit 1
fi

log "Copying API keys into $SERVER_VM"
# Copy the keys file into the server VM's /tmp
multipass transfer "$REPO_ROOT/config/api.env" "$SERVER_VM:/tmp/api.env"

log "Configuring landscape-api and testing the connection"
# Run the API setup script inside the server VM as the ubuntu user
run_remote "$SERVER_VM" "$REPO_ROOT/scripts/remote/setup-api.sh" "$FQDN"

log "API ready. Next: scripts/06-repo-mirror.sh"
