#!/usr/bin/env bash
# =============================================================================
# setup-api.sh: configure the landscape-api CLI inside the server VM.
# Runs on: the server VM, as the "ubuntu" user (called by scripts/05-api-setup.sh).
# Usage:   setup-api.sh <fqdn>   (expects /tmp/api.env to exist)
# =============================================================================
set -euo pipefail
FQDN="$1"

# Save the server's self-signed certificate so the API client trusts it
openssl s_client -connect "$FQDN:443" -servername "$FQDN" </dev/null 2>/dev/null \
  | openssl x509 > "$HOME/landscape-server.pem"

# Load the API keys that were copied in from config/api.env
source /tmp/api.env

# Write an rc file holding the keys, API address and certificate path
cat > "$HOME/.landscape-api.rc" <<EOF
export LANDSCAPE_API_KEY="$LANDSCAPE_API_KEY"
export LANDSCAPE_API_SECRET="$LANDSCAPE_API_SECRET"
export LANDSCAPE_API_URI="https://$FQDN/api/"
export LANDSCAPE_API_SSL_CA_FILE="$HOME/landscape-server.pem"
EOF
# Make the rc file readable only by this user (it contains secrets)
chmod 600 "$HOME/.landscape-api.rc"
# Delete the temporary copy of the keys
rm -f /tmp/api.env

# Load the rc file into this shell
source "$HOME/.landscape-api.rc"
# Test the connection: list up to 5 registered computers
landscape-api get-computers --limit 5
