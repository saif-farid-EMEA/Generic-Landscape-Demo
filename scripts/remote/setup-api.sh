#!/usr/bin/env bash
# =============================================================================
# setup-api.sh: configure the landscape-api command-line tool inside the server VM.
# Runs on: the server VM, as the normal "ubuntu" user.
# You don't run this yourself: scripts/05-api-setup.sh copies it into the VM
# (along with your keys in /tmp/api.env) and runs it for you.
# Usage:   setup-api.sh <fqdn>   (expects /tmp/api.env to exist)
# =============================================================================

# Stop on the first error (see scripts/00-host-prep.sh for details).
set -euo pipefail
# The first argument: the server's full name, e.g. landscape.demo.internal
FQDN="$1"

# Download the server's self-signed certificate and save it in this user's home
# folder, so the API tool trusts the server. ("$HOME" is the current user's
# home folder, here /home/ubuntu. See scripts/remote/register-client.sh for a
# step-by-step explanation of this openssl command.)
openssl s_client -connect "$FQDN:443" -servername "$FQDN" </dev/null 2>/dev/null \
  | openssl x509 > "$HOME/landscape-server.pem"

# Load the API keys that were copied in from config/api.env. After this line,
# the variables LANDSCAPE_API_KEY and LANDSCAPE_API_SECRET exist.
source /tmp/api.env

# Write a small settings file (an "rc" file) that holds the keys, the API
# address and the certificate location. Any later command can load it with
#   source ~/.landscape-api.rc
# instead of typing all of this again. ("~" is a shortcut for $HOME.)
# "export" makes each variable visible to programs started afterwards, such as
# landscape-api. "cat > FILE <<EOF ... EOF" writes the lines in between to FILE.
cat > "$HOME/.landscape-api.rc" <<EOF
export LANDSCAPE_API_KEY="$LANDSCAPE_API_KEY"
export LANDSCAPE_API_SECRET="$LANDSCAPE_API_SECRET"
export LANDSCAPE_API_URI="https://$FQDN/api/"
export LANDSCAPE_API_SSL_CA_FILE="$HOME/landscape-server.pem"
EOF
# Lock the file down so only this user can read or change it (it contains
# secrets). "chmod" changes file permissions; 600 means "owner: read and
# write; everyone else: nothing".
chmod 600 "$HOME/.landscape-api.rc"
# Delete the temporary copy of the keys ("rm" removes a file; "-f" means no
# error if it is already gone).
rm -f /tmp/api.env

# Load the settings file we just wrote into this script.
source "$HOME/.landscape-api.rc"
# Test that everything works by asking Landscape for up to 5 registered
# computers. If you see a list (or an empty list), the API is set up correctly.
landscape-api get-computers --limit 5
