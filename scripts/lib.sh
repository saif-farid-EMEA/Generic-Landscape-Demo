#!/usr/bin/env bash
# =============================================================================
# lib.sh: shared helpers loaded by every host-side script.
# =============================================================================

# Find the repository root (the folder above scripts/)
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Load all demo settings (VM names, sizes, FQDN, mirror details)
# shellcheck source=../config/demo.env
source "$REPO_ROOT/config/demo.env"

# Folder for generated files; not hidden, so the Multipass snap can read it
BUILD_DIR="$REPO_ROOT/build"
mkdir -p "$BUILD_DIR"

# Print a highlighted step heading
log() { printf '\n\033[1;33m==> %s\033[0m\n' "$*"; }

# Print the server VM's first IPv4 address
server_ip() { multipass info "$SERVER_VM" | awk '/IPv4/{print $2; exit}'; }

# Succeed if a Multipass VM with this name already exists
vm_exists() { multipass info "$1" >/dev/null 2>&1; }

# Copy a script into a VM's /tmp and run it there as the default "ubuntu" user
run_remote() {
  local vm=$1 script=$2; shift 2
  multipass transfer "$script" "$vm:/tmp/"
  multipass exec "$vm" -- bash "/tmp/$(basename "$script")" "$@"
}

# Same as run_remote, but runs the script as root
run_remote_sudo() {
  local vm=$1 script=$2; shift 2
  multipass transfer "$script" "$vm:/tmp/"
  multipass exec "$vm" -- sudo bash "/tmp/$(basename "$script")" "$@"
}

# List every VM in the lab: the server first, then all clients
all_vms() {
  echo "$SERVER_VM"
  for spec in "${CLIENTS[@]}"; do echo "${spec%%:*}"; done
}
