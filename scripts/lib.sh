#!/usr/bin/env bash
# =============================================================================
# lib.sh: shared helpers ("library") loaded by every host-side script.
#
# You never run this file yourself. The other scripts load it with the line
#   source "$(dirname "$0")/lib.sh"
# "source" means "read this file and run it inside my own script", so every
# variable and function defined here becomes available to the script that
# loaded it. This saves repeating the same code in every script.
#
# Quick Bash vocabulary used throughout this repo:
#   NAME="value"      Creates a variable called NAME (no spaces around "=").
#   "$NAME"           Uses the variable's value. The double quotes keep values
#                     with spaces in them together as one piece.
#   $(command)        Runs a command and puts its output right here, e.g.
#                     IP="$(server_ip)" stores the server's IP address in IP.
#   name() { ... }    Defines a function: a small reusable command you can call
#                     later just by typing its name.
#   $1, $2, ...       Inside a function or script: the 1st, 2nd... argument
#                     (the words typed after the command name).
#   # text            Everything after a "#" is a comment; Bash ignores it.
# =============================================================================

# Work out where this repository lives on your disk, so scripts work no matter
# which folder you run them from.
#   ${BASH_SOURCE[0]}  = the path to this lib.sh file
#   dirname            = strips the file name, leaving its folder (scripts/)
#   cd .../.. && pwd   = goes one folder up and prints the full path
# Result: REPO_ROOT holds something like /home/you/Generic-Landscape-Demo
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Load all demo settings (VM names, sizes, server name, mirror details) from
# config/demo.env. After this line, variables like $SERVER_VM and $FQDN exist.
# (The "shellcheck" line below is a hint for a code-checking tool; Bash
#  treats it as an ordinary comment.)
# shellcheck source=../config/demo.env
source "$REPO_ROOT/config/demo.env"

# A folder for files the scripts generate (for example cloud-init files).
# It is a normal, visible folder because Multipass (installed as a "snap")
# is not allowed to read hidden folders (ones whose names start with a dot).
BUILD_DIR="$REPO_ROOT/build"
# "mkdir" makes a folder; "-p" means "don't complain if it already exists".
mkdir -p "$BUILD_DIR"

# log: print a bold yellow heading so you can see which step is running.
# Usage: log "Installing things"
#   printf      prints formatted text
#   \n          a blank line before the heading
#   \033[1;33m  a special code that switches the terminal to bold yellow
#   \033[0m     switches colours back to normal
#   "$*"        all the words passed to log, joined into one line
log() { printf '\n\033[1;33m==> %s\033[0m\n' "$*"; }

# server_ip: print the IP address of the server VM.
# "multipass info" prints details about a VM; the "|" (a "pipe") sends that
# text into "awk", which finds the line containing "IPv4", prints the 2nd
# word on it (the address) and then stops ("exit") after the first match.
server_ip() { multipass info "$SERVER_VM" | awk '/IPv4/{print $2; exit}'; }

# vm_exists: succeed if a VM with the given name exists, fail otherwise.
# Usage: if vm_exists "web-01"; then ... fi
# ">/dev/null 2>&1" throws away all of the command's output (normal output and
# error messages), because we only care whether it succeeded, not what it said.
vm_exists() { multipass info "$1" >/dev/null 2>&1; }

# run_remote: copy a script from your laptop into a VM and run it there,
# as the VM's normal user (called "ubuntu").
# Usage: run_remote <vm-name> <script-path> [extra arguments for the script...]
run_remote() {
  # Save the first two arguments under readable names ("local" means these
  # variables only exist inside this function). Then "shift 2" removes those
  # two arguments, so "$@" now holds only the extra arguments meant for the
  # remote script. (The ";" lets two commands share one line.)
  local vm=$1 script=$2; shift 2
  # Copy the script into the VM's /tmp folder (a scratch folder for temp files).
  multipass transfer "$script" "$vm:/tmp/"
  # Run it inside the VM. "basename" strips the folder part of the path, leaving
  # just the file name. "--" separates Multipass's own options from the command
  # to run, and "$@" passes the extra arguments along unchanged.
  multipass exec "$vm" -- bash "/tmp/$(basename "$script")" "$@"
}

# run_remote_sudo: same as run_remote, but runs the script as "root", the
# all-powerful administrator account. "sudo" means "run this as root"; it is
# needed for things like installing software or editing system files.
run_remote_sudo() {
  local vm=$1 script=$2; shift 2
  multipass transfer "$script" "$vm:/tmp/"
  multipass exec "$vm" -- sudo bash "/tmp/$(basename "$script")" "$@"
}

# all_vms: print the name of every VM in the lab, one per line: the server
# first, then each client. Other scripts use it like: multipass stop $(all_vms)
all_vms() {
  echo "$SERVER_VM"
  # CLIENTS (from config/demo.env) is a list of entries like
  # "web-01:24.04:demo,web". "${spec%%:*}" chops off everything from the first
  # ":" onward, leaving only the VM name ("web-01").
  for spec in "${CLIENTS[@]}"; do echo "${spec%%:*}"; done
}
