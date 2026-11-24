#!/usr/bin/env bash
# =============================================================================
# run-script-via-api.sh: run a saved Landscape script through the API.
# FALLBACK ONLY: the demo normally does this from the web portal (see
# docs/04-run-of-show.md). Use this terminal version if the portal is slow.
# Runs on: your host machine (your laptop), during the demo. It runs the
#          landscape-api tool inside the server VM for you.
# Usage:   scripts/demo/run-script-via-api.sh <script-id> [query]
#   Step 1: run it with no arguments to list your saved scripts and their IDs:
#             scripts/demo/run-script-via-api.sh
#   Step 2: run it again with the ID number you want, e.g.:
#             scripts/demo/run-script-via-api.sh 3
#   The optional [query] picks which machines to run on (default: "tag:demo",
#   i.e. every machine tagged "demo").
# =============================================================================

# Stop on the first error (see scripts/00-host-prep.sh for details).
set -euo pipefail
# Load shared helpers and settings. This script lives one folder deeper
# (scripts/demo/), hence the "/.." to step up to scripts/ first.
source "$(dirname "$0")/../lib.sh"

# The first argument, or an empty value if none was given.
SCRIPT_ID="${1:-}"
# The second argument, or "tag:demo" if none was given.
QUERY="${2:-tag:demo}"

# "-z" is true when a value is empty, i.e. no script ID was given.
if [[ -z "$SCRIPT_ID" ]]; then
  # No ID given: list the saved scripts so you can pick one.
  # Inside the server VM, "bash -c '...'" runs the commands in quotes:
  # first load the API settings, then ("&&" = "and if that worked") list scripts.
  multipass exec "$SERVER_VM" -- bash -c 'source ~/.landscape-api.rc && landscape-api get-scripts'
  # Stop here successfully; there's nothing to run yet.
  exit 0
fi

# Run the chosen script, as root, on every machine matching the query.
# You can then watch the results appear in the portal under Activities.
multipass exec "$SERVER_VM" -- bash -c \
  "source ~/.landscape-api.rc && landscape-api execute-script '$QUERY' '$SCRIPT_ID' --username root"
