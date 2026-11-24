# Portal pre-staging (manual, before taking the snapshot)

Set these up in the web portal so each demo section takes one or two clicks.

## Monitoring & alerts
- Turn on these alerts: **security updates available**, **package updates available** and **computer offline**.
- Open a computer's monitoring graphs once so you know where they are.

## Packages & upgrades
- Nothing to do. `legacy-01` (22.04) will have plenty of pending updates.
- **Don't** apply updates before the snapshot.

## Remote scripting
- **Scripts → Add script**: title `System report`, run as `root`, body from
  [`assets/system-report.sh`](../assets/system-report.sh).
- Optional: run `scripts/demo/run-script-via-api.sh` with no arguments to find its ID.

## Repository management
- Check that the mirror sync finished (see the end of `scripts/06-repo-mirror.sh`).
- Leave the `internal-apps` repository profile **unassociated**. You'll link it live.

## Users & RBAC
- Create access group `lab`.
- Create role **Ops read-only** with view-only permissions on `lab`.

## Then
Run `scripts/07-snapshot.sh` to save this state.
