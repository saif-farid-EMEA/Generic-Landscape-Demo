#!/usr/bin/env bash
# =============================================================================
# show-apt-sources.sh: prove the repository profile reached a client.
# Runs on: your host machine (your laptop), during the demo.
# When: after you link the repository profile to machines in the portal.
# Usage:   scripts/demo/show-apt-sources.sh [vm-name]   (default: web-01)
#
# Ubuntu keeps its list of software sources as small files in the folder
# /etc/apt/sources.list.d/. When Landscape pushes the internal mirror to a
# machine, a new file appears there; this script shows it.
# =============================================================================

# Stop on the first error (see scripts/00-host-prep.sh for details).
set -euo pipefail
# "${1:-web-01}" means "the first argument, or web-01 if none was given".
VM="${1:-web-01}"

# List the files in the client's software-sources folder ("ls -l" lists files
# with details such as size and date). Look for a new Landscape file.
multipass exec "$VM" -- ls -l /etc/apt/sources.list.d/
# Print what's inside every Landscape source file.
#   grep -H .     prints every non-empty line, prefixed with its file name
#   *landscape*   matches any file name containing "landscape"
#   2>/dev/null   hides the error if no such file exists yet
#   || echo ...   if nothing was found, print a friendly message instead
multipass exec "$VM" -- bash -c 'grep -H . /etc/apt/sources.list.d/*landscape* 2>/dev/null || echo "No Landscape sources yet; give it ~30 seconds."'
