# Run of show (about 5 minutes)

**T-10 min:** `scripts/09-preflight.sh`
**T-2 min:** `scripts/demo/cpu-spike.sh db-01 300`

| # | Section | Time | What to do live |
|---|---------|------|-----------------|
| 1 | Monitoring & alerts | ~60 s | Open `db-01` and show the CPU spike on the graphs. Show the alert counts on the dashboard. |
| 2 | Packages & upgrades | ~60 s | Filter by `tag:legacy` and show pending security updates. Apply them to `legacy-01`, or install `htop` on `tag:demo`. |
| 3 | Remote scripting | ~45 s | Run **System report** on `tag:demo` and open a result. Optionally show the same run from the API with `scripts/demo/run-script-via-api.sh <id>`. |
| 4 | Repository management | ~60 s | Link the `internal-apps` profile to `tag:web`. Run `scripts/demo/show-apt-sources.sh web-01`, then install `google-chrome-stable` on `web-01` from the portal. |
| 5 | Users & RBAC | ~45 s | Show the **Ops read-only** role, then move `legacy-01` into access group `lab`. |

**Afterwards:** `scripts/08-reset.sh`
