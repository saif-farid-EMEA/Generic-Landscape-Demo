#!/usr/bin/env bash
# =============================================================================
# 06-repo-mirror.sh: set up the internal repository for the repo-management demo.
# Runs on: your host machine.
# =============================================================================
set -euo pipefail
source "$(dirname "$0")/lib.sh"

log "Creating mirror of $MIRROR_URI ($MIRROR_SUITE) as $REPO_DISTRIBUTION/$REPO_SERIES"
# Run the mirror setup script inside the server VM as the ubuntu user
run_remote "$SERVER_VM" "$REPO_ROOT/scripts/remote/setup-repo-mirror.sh" \
  "$REPO_GPG_KEY_NAME" "$REPO_DISTRIBUTION" "$REPO_SERIES" "$REPO_POCKET" \
  "$MIRROR_COMPONENT" "$MIRROR_ARCH" "$MIRROR_URI" "$MIRROR_SUITE" "$REPO_PROFILE"

log "Sync started. To watch it finish, run:"
# Print the command for watching the sync job (the user runs it if wanted)
echo "  multipass exec $SERVER_VM -- bash -c 'source ~/.landscape-api.rc && watch landscape-api get-activities --query type:SyncPocketRequest --limit 1'"
log "Next: portal pre-staging (docs/03-portal-prestaging.md), then scripts/07-snapshot.sh"
