#!/usr/bin/env bash
# =============================================================================
# install-server.sh: install Landscape Server 26.04 LTS (quickstart mode).
# Runs on: the server VM, as root (administrator).
# You don't run this yourself: scripts/02-install-server.sh copies it into the
# VM and runs it for you.
# Usage:   install-server.sh <landscape-ppa> <fqdn> [swap-size, e.g. 8G]
#
# "Quickstart mode" installs everything Landscape needs on this one machine,
# which is perfect for a demo (a real deployment would spread it out).
#
# Landscape 26.04 needs three extra helper services that older versions didn't,
# each installed as a snap with its own database:
#   landscape-task-handler  runs background jobs for the server
#   landscape-outbox        hands those jobs over to the task handler
#   landscape-debarchive    the new repository manager (mirrors, publications)
# Note: Landscape's quickstart is only supported on Ubuntu 24.04 or 22.04,
# NOT on Ubuntu 26.04, so the server VM runs Ubuntu 24.04 (see config/demo.env).
#
# Safe to run again: steps that create things check first whether they exist.
# =============================================================================

# Stop on the first error (see scripts/00-host-prep.sh for details).
set -euo pipefail
# "$1" is the first argument given to this script: the PPA to install from.
# A PPA ("Personal Package Archive") is an extra software source, on top of
# the ones Ubuntu comes with. "$2" is the server's full name (FQDN).
PPA="$1"
FQDN="$2"
# "$3" is how much swap to add; "${3:-8G}" means "use $3, or 8G if it's missing".
SWAP_SIZE="${3:-8G}"

# The Landscape services that must be running for the portal and the clients
# to work: web portal, client messages, client "pings" and the API.
CORE_SERVICES=(landscape-appserver landscape-msgserver landscape-pingserver landscape-api)

# core_services_running: succeed only if every service above is running.
# "systemctl is-active --quiet" succeeds for a running service, silently.
core_services_running() { systemctl is-active --quiet "${CORE_SERVICES[@]}"; }

# --- 0. Swap (overflow memory) ------------------------------------------------

# Landscape's one-time setup ("landscape-quickstart") loads a big package
# database and briefly needs more memory than the VM has. Without swap, Linux's
# "out of memory killer" stops it halfway. The package then still reports
# success, but Landscape's services are never started and clients can't
# connect. A swap file on disk gives it room to finish.
# "swapon --show" prints active swap; if it prints nothing, there is none yet.
if [[ -z "$(swapon --show --noheadings)" ]]; then
  echo "Adding $SWAP_SIZE of swap at /swapfile"
  # Create the file once (re-runs reuse it), allocate its space up front, and
  # make it readable only by root (it may hold copies of memory contents).
  if [[ ! -f /swapfile ]]; then
    fallocate -l "$SWAP_SIZE" /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
  fi
  swapon /swapfile
  # Also switch it on at every boot (only add the line once).
  grep -q '^/swapfile ' /etc/fstab || echo '/swapfile none swap sw 0 0' >> /etc/fstab
fi
swapon --show

# --- 1. Landscape Server itself ----------------------------------------------

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

# Make sure the setup really finished. The package's own install script runs
# "landscape-quickstart" but ignores it if that fails (for example when it
# runs out of memory): apt still says "success", yet Landscape's services
# are never started. So we check for ourselves, and if they aren't running we
# run the package's setup again ("dpkg-reconfigure" repeats it). This is also
# what repairs a server left half-installed by an earlier attempt.
for attempt in 1 2 3; do
  core_services_running && break
  echo "Landscape services are not running; re-running its setup (attempt $attempt of 3)"
  DEBIAN_FRONTEND=noninteractive dpkg-reconfigure -fnoninteractive landscape-server-quickstart
done
# Still not running after three tries: stop here with a pointer to the logs,
# instead of carrying on and leaving a broken server that looks fine.
if ! core_services_running; then
  echo "ERROR: Landscape's setup did not finish. Look at:" >&2
  echo "  sudo tail -n 50 /var/log/landscape-server/landscape-quickstart.log" >&2
  echo "  sudo journalctl -k | grep -i 'out of memory'" >&2
  exit 1
fi
# Install "landscape-api", a command-line tool for talking to Landscape from
# scripts (used later by setup-api.sh and the demo helpers).
snap install landscape-api

# A tiny helper: run one SQL command as the "postgres" database administrator.
# "-tAc" prints only the bare answer (no table borders), handy for checks.
psql_admin() { sudo -u postgres psql -tAc "$@"; }

# --- 2. Task handler -----------------------------------------------------------

# Find the password Landscape uses for its own databases. The quickstart stores
# it in /etc/landscape/service.conf, under the [stores] section, as "password".
# Sometimes it is stored "base64"-encoded (scrambled into letters and digits)
# with a "b64:" in front, so we decode it in that case. This small Python
# program reads the file and prints the plain password.
DB_PASSWORD="$(python3 - <<'PY'
import base64, configparser
c = configparser.ConfigParser(interpolation=None)
c.read("/etc/landscape/service.conf")
p = c["stores"]["password"]
print(base64.b64decode(p[4:]).decode() if p.startswith("b64:") else p)
PY
)"

# Install the task handler snap.
snap install landscape-task-handler
# Create its database, unless it exists already. The check asks PostgreSQL
# "is there a database with this name?"; "grep -q 1" succeeds if the answer is yes.
psql_admin "SELECT 1 FROM pg_database WHERE datname='landscape-standalone-task-handler'" | grep -q 1 || \
  sudo -u postgres createdb landscape-standalone-task-handler
# Allow Landscape's database user ("landscape") to connect to it and create tables.
sudo -u postgres psql landscape-standalone-task-handler -c \
  "GRANT CONNECT ON DATABASE \"landscape-standalone-task-handler\" TO landscape;"
sudo -u postgres psql landscape-standalone-task-handler -c \
  "GRANT CREATE ON SCHEMA public TO landscape;"
# Tell the task handler where its database is and how to log in to it.
# "snap set" stores settings for a snap; each "key=value" is one setting.
snap set landscape-task-handler \
  landscape.database.task-handler.host=localhost \
  landscape.database.task-handler.port=5432 \
  landscape.database.task-handler.name=landscape-standalone-task-handler \
  landscape.database.task-handler.user=landscape \
  landscape.database.task-handler.password="$DB_PASSWORD" \
  landscape.database.task-handler.ssl=disable \
  landscape.task-handler.server.grpc-port=50053 \
  landscape.task-handler.server.host=localhost

# --- 3. Outbox -----------------------------------------------------------------

# Install the outbox snap and connect it to the task handler. "snap connect"
# lets two snaps share something; here, the certificates they use to talk
# securely to each other.
snap install landscape-outbox
snap connect landscape-outbox:grpc-client-certs landscape-task-handler:grpc-client-certs

# --- 4. Debarchive (repository management) -----------------------------------

# Install the Debarchive snap. It will complain that it can't reach its
# database until the steps below are done; that's expected.
snap install landscape-debarchive --channel=latest/stable

# Debarchive gets its own database user. We keep its password in a file in
# root's home folder so that re-running this script reuses the same one.
# "openssl rand -hex 16" makes a random 32-character password.
DEBARCHIVE_PW_FILE=/root/debarchive-db-password
[[ -f "$DEBARCHIVE_PW_FILE" ]] || openssl rand -hex 16 > "$DEBARCHIVE_PW_FILE"
# "chmod 600" makes the file readable only by root (it holds a password).
chmod 600 "$DEBARCHIVE_PW_FILE"
DEBARCHIVE_PW="$(cat "$DEBARCHIVE_PW_FILE")"

# Create the database user, or reset its password if it already exists.
if psql_admin "SELECT 1 FROM pg_roles WHERE rolname='landscape_debarchive'" | grep -q 1; then
  psql_admin "ALTER ROLE landscape_debarchive WITH LOGIN PASSWORD '$DEBARCHIVE_PW';"
else
  psql_admin "CREATE ROLE landscape_debarchive WITH LOGIN PASSWORD '$DEBARCHIVE_PW';"
fi
# Create Debarchive's database (owned by that user), unless it exists already.
psql_admin "SELECT 1 FROM pg_database WHERE datname='landscape-standalone-debarchive'" | grep -q 1 || \
  sudo -u postgres createdb --owner=landscape_debarchive landscape-standalone-debarchive
# Let the user create tables in it.
sudo -u postgres psql -d landscape-standalone-debarchive -c \
  "GRANT USAGE, CREATE ON SCHEMA public TO landscape_debarchive;"
# Tell Debarchive how to log in to its database. It creates its own tables
# the first time it connects.
snap set landscape-debarchive \
  deb.archive.database.name=landscape-standalone-debarchive \
  deb.archive.database.user=landscape_debarchive \
  deb.archive.database.password="$DEBARCHIVE_PW"
# Restart it so it picks up the new settings.
snap restart landscape-debarchive

# The web portal talks to Debarchive at https://<FQDN>/debarchive, so the
# Apache web server must forward that address to Debarchive (which listens on
# port 8100 on this machine). We add two "RewriteRule" lines to the HTTPS
# (port 443) section of Landscape's Apache config, just before its final
# catch-all rule. The small Python program below does that edit, and does
# nothing if the lines are already there.
#
# The config file's name depends on the Landscape version (it may be named
# after the server, e.g. landscape.demo.internal.conf), so instead of guessing
# the name, the program looks through every switched-on Apache site in
# /etc/apache2/sites-enabled/ and picks the one with an HTTPS (port 443)
# section that contains rewrite rules.
python3 - <<'PY'
import glob, os, re, sys
https_section = re.compile(r"<VirtualHost [^>]*:443>")
path = None
for candidate in sorted(glob.glob("/etc/apache2/sites-enabled/*")):
    real = os.path.realpath(candidate)  # sites-enabled holds shortcuts; follow them
    text = open(real).read()
    if https_section.search(text) and "RewriteRule" in text:
        path = real
        break
if path is None:
    sys.exit("Could not find Landscape's HTTPS site in /etc/apache2/sites-enabled/")
print(f"Adding Debarchive rules to {path}")
text = open(path).read()
if "localhost:8100" not in text:
    start = https_section.search(text).start()
    end = text.index("</VirtualHost>", start)
    block = text[start:end]
    last_rule = list(re.finditer(r"^[ \t]*RewriteRule\b.*$", block, re.M))[-1]
    indent = re.match(r"[ \t]*", last_rule.group(0)).group(0)
    rules = (f"{indent}# Landscape Debarchive\n"
             f"{indent}RewriteRule ^/debarchive$ /debarchive/ [R=permanent]\n"
             f"{indent}RewriteRule ^/debarchive/(.*) http://localhost:8100/$1 [P,L]\n")
    pos = start + last_rule.start()
    open(path, "w").write(text[:pos] + rules + text[pos:])
PY

# --- 5. Serve published repositories to the clients --------------------------

# When you "publish" a mirror, Debarchive writes ordinary repository files to
# a folder on this server. Landscape doesn't serve that folder itself, so we
# set up a second small Apache website on port 8000 that does. Clients then
# download packages from http://<FQDN>:8000/...
PUBLISHED_ROOT=/var/snap/landscape-debarchive/common/publications
# Make sure the folder exists ("-p": no error if it already does).
mkdir -p "$PUBLISHED_ROOT"
# Tell Apache to also listen on port 8000 (only add the line once).
grep -q '^Listen 8000$' /etc/apache2/ports.conf || echo 'Listen 8000' >> /etc/apache2/ports.conf
# Write the website's config file. "Options Indexes" shows a file listing in
# the browser, handy for checking what was published.
cat > /etc/apache2/sites-available/filesystem-repo.conf <<EOF
<VirtualHost *:8000>
    ServerName $FQDN
    DocumentRoot $PUBLISHED_ROOT
    <Directory $PUBLISHED_ROOT>
        Options Indexes FollowSymLinks
        Require all granted
    </Directory>
</VirtualHost>
EOF
# Switch the new website on ("a2ensite" = "Apache 2: enable site"), then
# restart Apache so all the changes above take effect.
a2ensite filesystem-repo.conf
systemctl restart apache2

# --- 6. Health check -------------------------------------------------------------

# Show whether each helper service is running (look for "active").
snap services landscape-task-handler landscape-outbox landscape-debarchive

# Ask Apache for each address the browser and the clients use, and check that
# a real Landscape service answers behind it. Apache itself answers 502 or 503
# when the service behind it is down, and curl prints 000 when nothing answers
# at all; any other code (200, 302, 401, 405, ...) means it's alive.
# Services take a little while to start, so we retry for up to 5 minutes.
#   name|address
CHECKS=(
  "Web portal|https://$FQDN/"
  "Client messages|https://$FQDN/message-system"
  "Client pings|http://$FQDN/ping"
  "API|https://$FQDN/api/"
  "Debarchive|https://$FQDN/debarchive/v1/mirrors"
)
healthy=true
for check in "${CHECKS[@]}"; do
  # Split "name|address" at the "|".
  name="${check%%|*}" url="${check#*|}"
  # Try every 5 seconds, 60 times (= 5 minutes).
  for _ in $(seq 60); do
    # "|| true" keeps going if curl fails; we judge by the code it printed.
    code="$(curl -sk -o /dev/null -w '%{http_code}' --max-time 10 "$url" || true)"
    [[ "$code" =~ ^(000|502|503|504)$ ]] || break
    sleep 5
  done
  if [[ "$code" =~ ^(000|502|503|504)$ ]]; then
    echo "FAIL  $name ($url): HTTP $code"
    healthy=false
  else
    echo "OK    $name ($url): HTTP $code"
  fi
done
if [[ "$healthy" != true ]]; then
  echo "ERROR: Landscape Server is installed but not answering. Check:" >&2
  echo "  sudo lsctl status" >&2
  exit 1
fi
echo "Landscape Server is up at https://$FQDN/"
