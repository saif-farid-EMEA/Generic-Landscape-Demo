# Run of show (about 5 minutes)

Everything during the demo happens in the **Landscape web portal**. The only
terminal command is the health check before you start.

**T-10 min (terminal):** `scripts/09-preflight.sh`
**T-2 min (portal):** **Scripts** → `CPU spike` → run on `db-01` as `root`.

| # | Section | Time | What to do live (all in the portal) |
|---|---------|------|-------------------------------------|
| 1 | Monitoring & alerts | ~60 s | Open `db-01` and show the CPU spike on its graphs. Open the `CPU spike` activity to show it was started from the portal. Show the alert counts on the dashboard. |
| 2 | Packages & upgrades | ~60 s | Filter by `tag:legacy` and show pending security updates. Apply them to `legacy-01`, or install `htop` on `tag:demo`. |
| 3 | Remote scripting | ~45 s | Run **System report** on `tag:demo` and open one machine's result. |
| 4 | Repository management | ~60 s | Associate the `internal-apps` profile with `tag:web`. Run **Show APT sources** on `tag:web` and open the result, then install `google-chrome-stable` on `web-01` from **Packages**. |
| 5 | Users & RBAC | ~45 s | Show the **Ops read-only** role, then move `legacy-01` into access group `lab`. |

**Afterwards (terminal):** `scripts/08-reset.sh`

**Fallbacks:** if the portal is slow to start a script, the same actions exist as
terminal helpers in `scripts/demo/` (`cpu-spike.sh`, `show-apt-sources.sh`,
`run-script-via-api.sh`).
