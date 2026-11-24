#!/usr/bin/env bash
# =============================================================================
# register-client.sh: install Landscape Client and register with the server.
# Runs on: each client VM, as root (called by scripts/04-launch-clients.sh).
# Usage:   register-client.sh <name> <tags> <server-ip> <fqdn> \
#                             <exchange-s> <urgent-exchange-s> <ping-s>
# =============================================================================
set -euo pipefail
NAME="$1"; TAGS="$2"; SERVER_IP="$3"; FQDN="$4"
EXCHANGE="$5"; URGENT="$6"; PING="$7"

# Let this client find the server by name (add a hosts entry once)
grep -q "[[:space:]]$FQDN\$" /etc/hosts || echo "$SERVER_IP $FQDN" >> /etc/hosts

# Turn off automatic upgrades so pending updates stay visible in the demo
systemctl disable --now unattended-upgrades.service apt-daily-upgrade.timer || true

# Refresh package lists (this does NOT upgrade anything)
apt-get update
# Install Landscape Client, plus stress-ng to create CPU load for the monitoring demo
DEBIAN_FRONTEND=noninteractive apt-get install -y landscape-client stress-ng

# Make sure the client's config folder exists
mkdir -p /etc/landscape
# Download the server's self-signed certificate so the client will trust it
openssl s_client -connect "$FQDN:443" -servername "$FQDN" </dev/null 2>/dev/null \
  | openssl x509 > /etc/landscape/server.pem

# Register with the server: account "standalone", tags for grouping,
# remote scripts enabled for any user, and fast check-in intervals
landscape-config --silent \
  --computer-title "$NAME" \
  --account-name standalone \
  --url "https://$FQDN/message-system" \
  --ping-url "http://$FQDN/ping" \
  --ssl-public-key /etc/landscape/server.pem \
  --include-manager-plugins ScriptExecution \
  --script-users ALL \
  --tags "$TAGS" \
  --exchange-interval "$EXCHANGE" \
  --urgent-exchange-interval "$URGENT" \
  --ping-interval "$PING"
