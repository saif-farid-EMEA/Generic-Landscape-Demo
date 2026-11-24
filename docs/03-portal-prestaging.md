# Portal pre-staging (manual, before taking the snapshot)

Set these up in the web portal so each demo section takes one or two clicks.

## Monitoring & alerts
- Turn on these alerts: **security updates available**, **package updates available** and **computer offline**.
- Open a computer's monitoring graphs once so you know where they are.

## Packages & upgrades
- Nothing to do. `legacy-01` (22.04) will have plenty of pending updates.
- **Don't** apply updates before the snapshot.

## Remote scripting
Add these three scripts in **Scripts → Add script**. Run each as `root`, and paste
the whole contents of its file as the script body:

| Title | Body | Used in |
|-------|------|---------|
| `System report` | [`assets/system-report.sh`](../assets/system-report.sh) | Remote scripting |
| `CPU spike` | [`assets/cpu-spike.sh`](../assets/cpu-spike.sh) | Monitoring (start it 2 min early) |
| `Show APT sources` | [`assets/show-apt-sources.sh`](../assets/show-apt-sources.sh) | Repository management |

## Repository management (Landscape 26.04: done in the portal)

In 26.04, mirrors are managed by the Debarchive service and created in the portal.
Run `scripts/06-repo-mirror.sh` first: it creates the signing key and prints every
value below. To copy a key, print it with `cat build/mirror-key-private.asc` (or
`-public.asc`) and copy **everything**, including the `-----BEGIN` and `-----END` lines.

1. **Check Debarchive works:** open **Repositories → Mirrors**. If the page loads and
   lets you add a mirror, it's ready.
2. **Create the mirror:** **Repositories → Mirrors → Add mirror**.
   - Name `chrome`, Source URL `https://dl.google.com/linux/chrome/deb/`
   - Distribution `stable`, Components `main`, Architectures `amd64`
   - Leave **Preserve upstream signing key** unticked, so Landscape re-signs it with your key.
3. **Download the packages:** select the `chrome` mirror and click **Update**. It's small,
   so it should finish in a few minutes.
4. **Create a publication target:** **Repositories → Publication targets → Add publication target**.
   Type **Filesystem**, Path `/chrome`.
5. **Create a publication:** **Repositories → Publications → Add publication**.
   Source type **Mirror**, Source `chrome`, the target from step 4, Architectures `amd64`,
   and paste the **private** key into **Signing GPG key**.
6. **Publish:** **Repositories → Mirrors**, select `chrome`, click **Publish**, choose
   **Existing publication**, then **Publish Mirror**.
7. **Check the files are served:** open `http://landscape.demo.internal:8000/chrome/` in
   your browser. You should see `dists/` and `pool/` folders. If they are in a different
   place, adjust the `deb` line in the next step to match.
8. **Create the profile:** **Repositories → Repository profiles → Add repository profile**.
   - Profile name `internal-apps`, description "Internally distributed apps"
   - **Add source**: name `chrome`, line
     `deb http://landscape.demo.internal:8000/chrome stable main`,
     and paste the **public** key into **GPG key**.
   - Leave it **unassociated**. You'll link it to `tag:web` live during the demo.

## Users & RBAC
- Create access group `lab`.
- Create role **Ops read-only** with view-only permissions on `lab`.

## Then
Run `scripts/07-snapshot.sh` to save this state.
