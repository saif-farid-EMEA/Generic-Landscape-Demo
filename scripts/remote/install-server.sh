#!/usr/bin/env bash
# =============================================================================
# install-server.sh: install Landscape Server (quickstart mode).
# Runs on: the server VM, as root (administrator).
# You don't run this yourself: scripts/02-install-server.sh copies it into the
# VM and runs it for you.
# Usage:   install-server.sh <landscape-ppa>
#
# "Quickstart mode" installs everything Landscape needs on this one machine,
# which is perfect for a demo (a real deployment would spread it out).
# =============================================================================

# Stop on the first error (see scripts/00-host-prep.sh for details).
set -euo pipefail
# "$1" is the first argument given to this script: the PPA to install from.
# A PPA ("Personal Package Archive") is an extra software source, on top of
# the ones Ubuntu comes with.
PPA="$1"

# Download the latest list of available software (installs nothing yet).
# No "sudo" needed in this file: the whole script already runs as root.
apt-get update
# Install the tool that provides the "add-apt-repository" command used next.
# "-y" answers "yes" to the confirmation prompt automatically.
apt-get install -y software-properties-common
# Add the Landscape Server PPA to this VM's list of software sources.
add-apt-repository -y "$PPA"
# Refresh the software list again, so packages from the new PPA show up.
apt-get update
# Install Landscape Server plus everything it depends on (a PostgreSQL
# database, the RabbitMQ message queue and the Apache web server).
# Takes about 5 minutes. Some packages normally stop and ask questions while
# installing; DEBIAN_FRONTEND=noninteractive tells them to use the default
# answers instead, so the script never gets stuck waiting for you.
DEBIAN_FRONTEND=noninteractive apt-get install -y landscape-server-quickstart
# Install "landscape-api", a command-line tool for talking to Landscape from
# scripts (used later by setup-api.sh and setup-repo-mirror.sh).
snap install landscape-api
