#!/usr/bin/env bash
# =============================================================================
# cpu-spike.sh: create CPU load on a client for the monitoring section.
# Runs on: your host machine. Start it ~2 minutes before showing graphs.
# Usage:   scripts/demo/cpu-spike.sh [vm-name] [seconds]   (default: db-01 180)
# =============================================================================
set -euo pipefail
VM="${1:-db-01}"
SECONDS_TO_RUN="${2:-180}"

echo "Loading 1 CPU on $VM for $SECONDS_TO_RUN seconds..."
# Run stress-ng inside the client in the background to max out one CPU
multipass exec "$VM" -- stress-ng --cpu 1 --timeout "${SECONDS_TO_RUN}s" &
echo "Running in the background (PID $!)."
