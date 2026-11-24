#!/usr/bin/env bash
# =============================================================================
# cpu-spike.sh: create CPU load on a client for the monitoring section.
# FALLBACK ONLY: the demo normally does this from the web portal (see
# docs/04-run-of-show.md). Use this terminal version if the portal is slow.
# Runs on: your host machine (your laptop), during the demo.
# When: start it about 2 minutes before you show the graphs, so the spike has
#       time to appear in the portal.
# Usage:   scripts/demo/cpu-spike.sh [vm-name] [seconds]   (default: db-01 180)
#   Square brackets mean "optional". Examples:
#     scripts/demo/cpu-spike.sh               load db-01 for 180 seconds
#     scripts/demo/cpu-spike.sh web-01 60     load web-01 for 60 seconds
# =============================================================================

# Stop on the first error (see scripts/00-host-prep.sh for details).
set -euo pipefail
# "${1:-db-01}" means "use the first argument, or db-01 if none was given".
VM="${1:-db-01}"
# Same idea: the second argument, or 180 seconds by default.
SECONDS_TO_RUN="${2:-180}"

echo "Loading 1 CPU on $VM for $SECONDS_TO_RUN seconds..."
# Run stress-ng inside the client VM to keep one CPU at 100% for the chosen
# time. The "&" at the end runs it in the background, so you get your terminal
# back straight away while the load keeps going.
multipass exec "$VM" -- stress-ng --cpu 1 --timeout "${SECONDS_TO_RUN}s" &
# "$!" is the process ID (PID), a number identifying the background job we just
# started. To stop it early, run: kill <that number>
echo "Running in the background (PID $!)."
