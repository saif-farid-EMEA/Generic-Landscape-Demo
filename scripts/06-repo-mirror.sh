#!/usr/bin/env bash
# =============================================================================
# 06-repo-mirror.sh: prepare the internal repository for the repo-management demo.
# Runs on: your host machine (your laptop).
# How to run: ./scripts/06-repo-mirror.sh
#
# Background: Ubuntu installs software from "repositories" (repos): online
# collections of packages. Companies often keep their own copy ("mirror") of a
# repo so they control exactly what their machines can install. For the demo we
# mirror the small Google Chrome repo and hand it out to client machines.
#
# In Landscape 26.04 the mirror itself is created in the web portal (the old
# command-line way was removed). This script does the preparation: it creates
# the signing key and copies it to your laptop so you can paste it into the
# portal. Then follow docs/03-portal-prestaging.md, "Repository management".
# =============================================================================

# Stop on the first error (see 00-host-prep.sh for details).
set -euo pipefail
# Load shared helpers and all settings from config/demo.env.
source "$(dirname "$0")/lib.sh"

log "Creating the mirror signing key in $SERVER_VM"
# Copy scripts/remote/setup-repo-mirror.sh into the server VM and run it as
# the "ubuntu" user, telling it what to call the key files.
run_remote "$SERVER_VM" "$REPO_ROOT/scripts/remote/setup-repo-mirror.sh" "$REPO_GPG_KEY_NAME"

log "Copying the key files to $BUILD_DIR"
# Copy both key files from the VM's home folder (/home/ubuntu) to your laptop's
# build/ folder. build/ and *.asc files are git-ignored, so the private key is
# never committed (uploaded) by accident.
for half in private public; do
  multipass transfer "$SERVER_VM:/home/ubuntu/$REPO_GPG_KEY_NAME-$half.asc" "$BUILD_DIR/"
done

# Print everything you'll need to type into the portal, in one place.
# "cat <<EOF ... EOF" prints the lines in between, with variables filled in.
log "Now create the mirror in the portal (docs/03-portal-prestaging.md). Values to use:"
cat <<EOF
  Mirror name ............ $MIRROR_NAME
  Source URL ............. $MIRROR_URI
  Distribution ........... $MIRROR_SUITE
  Components ............. $MIRROR_COMPONENT
  Architectures .......... $MIRROR_ARCH
  Publication target path  $PUBLICATION_PATH
  Repository profile ..... $REPO_PROFILE
  APT source line ........ deb http://$FQDN:8000$PUBLICATION_PATH $MIRROR_SUITE $MIRROR_COMPONENT
  Signing key (private) .. $BUILD_DIR/$REPO_GPG_KEY_NAME-private.asc
  Profile key (public) ... $BUILD_DIR/$REPO_GPG_KEY_NAME-public.asc

  To print a key so you can copy it, run for example:
    cat $BUILD_DIR/$REPO_GPG_KEY_NAME-private.asc
EOF
log "When the portal steps are done, run scripts/07-snapshot.sh"
