#!/usr/bin/env bash
# =============================================================================
# 00-host-prep.sh: get your laptop ready to run the demo VMs.
# Runs on: your host machine (your laptop, not inside a VM).
# How to run: open a terminal in the repo folder and type
#   ./scripts/00-host-prep.sh
# You will be asked for your password, because installing software needs
# administrator rights.
#
# What is a VM? A "virtual machine" is a pretend computer that runs inside your
# real one. This lab uses several small Ubuntu VMs instead of real servers.
# =============================================================================

# The first line of this file ("#!/usr/bin/env bash", called a "shebang") tells
# Linux to run this file with Bash, the standard command-line shell.

# Safety settings that make the script stop as soon as something goes wrong,
# instead of carrying on and making a mess:
#   -e           stop if any command fails
#   -u           stop if we use a variable that was never set (catches typos)
#   -o pipefail  if commands are chained with "|", fail if ANY of them fails
set -euo pipefail

# Load the shared helpers and settings (see scripts/lib.sh).
# "$(dirname "$0")" means "the folder this script is in".
source "$(dirname "$0")/lib.sh"

# "log" (defined in lib.sh) prints a highlighted heading for this step.
log "Checking hardware virtualisation"
# "sudo" runs a command as the administrator (root). It may ask your password.
# "apt-get" is Ubuntu's package manager: the tool that installs software.
# "update" downloads the latest list of available software (it does not install
# or upgrade anything by itself).
sudo apt-get update
# Install the "cpu-checker" package, which provides the kvm-ok tool.
# "-y" answers "yes" automatically to the "Do you want to continue?" prompt.
sudo apt-get install -y cpu-checker
# Check that KVM works. KVM is the part of Linux that uses your CPU's built-in
# virtualisation features so VMs run at near full speed. If this prints an
# error, enable "Virtualization" (VT-x / AMD-V) in your laptop's BIOS settings.
kvm-ok

log "Installing Multipass"
# Install Multipass, the tool that creates and manages the Ubuntu VMs.
# "snap" is a second way Ubuntu installs software (alongside apt).
sudo snap install multipass
# Print the Multipass version, just to prove it installed and runs.
multipass version

log "Host is ready. Next: scripts/01-launch-server.sh"
