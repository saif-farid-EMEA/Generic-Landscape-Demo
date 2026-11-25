#!/usr/bin/env bash
# =============================================================================
# register-client.sh: install Landscape Client and register with the server.
# Runs on: each client VM, as root (administrator).
# You don't run this yourself: scripts/04-launch-clients.sh copies it into
# each client VM and runs it for you.
# Usage:   register-client.sh <name> <tags> <server-ip> <fqdn> \
#                             <exchange-s> <urgent-exchange-s> <ping-s>
#
# "Landscape Client" is a small background program that runs on every managed
# machine. It reports to the Landscape server and carries out its instructions.
# =============================================================================

# Stop on the first error (see scripts/00-host-prep.sh for details).
set -euo pipefail
# Give the seven arguments readable names. $1 is the first argument, $2 the
# second, and so on. The ";" lets several commands share one line.
#   NAME       the name to show for this machine in the portal
#   TAGS       labels used to group machines, e.g. "demo,web"
#   SERVER_IP  the server's IP address
#   FQDN       the server's full name, e.g. landscape.demo.internal
#   EXCHANGE, URGENT, PING   how often (in seconds) to check in with the server
NAME="$1"; TAGS="$2"; SERVER_IP="$3"; FQDN="$4"
EXCHANGE="$5"; URGENT="$6"; PING="$7"

# Let this client find the server by name, by adding a line to its /etc/hosts
# file (see scripts/03-host-dns.sh for what that file does).
#   grep -q   searches the file quietly, only reporting "found" or "not found"
#   ||        "only if not found", add the line
#   >>        append to the end of the file (a single ">" would wipe it)
grep -q "[[:space:]]$FQDN\$" /etc/hosts || echo "$SERVER_IP $FQDN" >> /etc/hosts

# Turn off Ubuntu's automatic updates on this client. Otherwise it would quietly
# install its own updates and there would be nothing left to show in the demo.
#   systemctl         controls background services
#   disable --now     stop it right away AND keep it off after reboots
#   || true           if this fails (e.g. the service doesn't exist), carry on
#                     anyway instead of stopping the script
systemctl disable --now unattended-upgrades.service apt-daily-upgrade.timer || true

# Download the latest list of available software (this does NOT upgrade anything).
apt-get update
# Install Landscape Client, plus "stress-ng", a tool that keeps the CPU busy
# so the monitoring demo has something to show.
# DEBIAN_FRONTEND=noninteractive stops packages from pausing to ask questions.
DEBIAN_FRONTEND=noninteractive apt-get install -y landscape-client stress-ng

# Make sure the client's settings folder exists ("-p": no error if it does).
mkdir -p /etc/landscape
# Download the server's certificate and save it, so the client trusts the server.
# A certificate is what proves a website is who it says it is (the padlock in
# your browser). Our demo server made its own ("self-signed") certificate, which
# nobody trusts automatically, so we hand the client a copy to trust.
#   openssl s_client   connects to the server on port 443 (HTTPS)
#   </dev/null         sends it no input, so it disconnects straight away
#   2>/dev/null        hides its chatter
#   | openssl x509     picks out just the certificate from the output
#   > .../server.pem   and saves it to this file
openssl s_client -connect "$FQDN:443" -servername "$FQDN" </dev/null 2>/dev/null \
  | openssl x509 > /etc/landscape/server.pem

# is_registered: succeed if this machine is already registered with Landscape.
# "landscape-config --is-registered" answers that; we hide its printout.
is_registered() { landscape-config --is-registered >/dev/null 2>&1; }

# Already registered (for example when 04-launch-clients.sh is run again)?
# Then stop here: registering again would add a duplicate machine in the portal.
if is_registered; then
  echo "$NAME is already registered with $FQDN, nothing to do."
  exit 0
fi

# Register this machine with the Landscape server. Each "--option" is one
# setting, and the "\" at line ends continue the command onto the next line.
#   --silent                  don't ask questions; use the options given here
#   --computer-title          the name shown in the portal
#   --account-name standalone the account name self-hosted Landscape always uses
#   --url / --ping-url        where the server is
#   --ssl-public-key          the certificate saved above
#   --include-manager-plugins ScriptExecution / --script-users ALL
#                             allow the server to run scripts on this machine,
#                             as any user (needed for the remote-scripting demo)
#   --tags                    labels for grouping machines in the portal
#   --exchange-interval etc.  check in every few seconds instead of the normal
#                             several minutes, so the demo feels instant
register() {
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
}

# Try up to 3 times. Before each try, stop the Landscape client service:
# after a failed earlier attempt (for example before the portal's administrator
# existed) it keeps running in a stale state, and landscape-config then fails
# with "ConnectError: No such file or directory".
# landscape-config can print an error yet still report success, so we judge
# each try by asking afterwards whether the machine is really registered.
for attempt in 1 2 3; do
  systemctl stop landscape-client || true
  # "|| true": a failed try shouldn't stop the script; the check below decides.
  register || true
  if is_registered; then
    echo "$NAME registered with $FQDN."
    exit 0
  fi
  echo "Registration of $NAME didn't take (attempt $attempt of 3); retrying in 10 seconds."
  sleep 10
done
echo "ERROR: $NAME could not register with $FQDN." >&2
echo "Look at: sudo tail -n 30 /var/log/landscape/broker.log" >&2
exit 1
