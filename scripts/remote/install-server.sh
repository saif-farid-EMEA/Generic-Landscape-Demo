#!/usr/bin/env bash
# =============================================================================
# install-server.sh: install Landscape Server (quickstart mode).
# Runs on: the server VM, as root (called by scripts/02-install-server.sh).
# Usage:   install-server.sh <landscape-ppa>
# =============================================================================
set -euo pipefail
PPA="$1"

# Refresh the VM's package lists
apt-get update
# Install the tool that lets us add PPAs
apt-get install -y software-properties-common
# Add the Landscape Server package repository (PPA)
add-apt-repository -y "$PPA"
# Refresh package lists again so the PPA's packages are visible
apt-get update
# Install Landscape Server plus all its parts (PostgreSQL, RabbitMQ, Apache).
# Takes about 5 minutes; the noninteractive flag skips all prompts.
DEBIAN_FRONTEND=noninteractive apt-get install -y landscape-server-quickstart
# Install the Landscape API command-line client (used for repository setup)
snap install landscape-api
