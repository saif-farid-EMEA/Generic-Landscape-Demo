#!/usr/bin/env bash
# =============================================================================
# show-apt-sources.sh: prove the repository profile reached a client.
# Runs on: your host machine, after you link the repo profile in the portal.
# Usage:   scripts/demo/show-apt-sources.sh [vm-name]   (default: web-01)
# =============================================================================
set -euo pipefail
VM="${1:-web-01}"

# List the apt source files on the client (Landscape adds a new one here)
multipass exec "$VM" -- ls -l /etc/apt/sources.list.d/
# Print the contents of every Landscape-managed source file
multipass exec "$VM" -- bash -c 'grep -H . /etc/apt/sources.list.d/*landscape* 2>/dev/null || echo "No Landscape sources yet; give it ~30 seconds."'
