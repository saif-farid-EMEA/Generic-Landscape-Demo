#!/usr/bin/env bash
# =============================================================================
# run-script-via-api.sh: run a saved Landscape script through the API.
# Runs on: your host machine (calls landscape-api inside the server VM).
# Usage:   scripts/demo/run-script-via-api.sh <script-id> [query]
#          Leave out <script-id> to list your saved scripts and their IDs.
# =============================================================================
set -euo pipefail
source "$(dirname "$0")/../lib.sh"

SCRIPT_ID="${1:-}"
QUERY="${2:-tag:demo}"

if [[ -z "$SCRIPT_ID" ]]; then
  # No ID given: list the saved scripts so you can pick one
  multipass exec "$SERVER_VM" -- bash -c 'source ~/.landscape-api.rc && landscape-api get-scripts'
  exit 0
fi

# Run the chosen script as root on every machine matching the query
multipass exec "$SERVER_VM" -- bash -c \
  "source ~/.landscape-api.rc && landscape-api execute-script '$QUERY' '$SCRIPT_ID' --username root"
