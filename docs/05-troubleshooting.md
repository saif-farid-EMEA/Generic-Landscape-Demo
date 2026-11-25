# Troubleshooting

| Symptom | Fix |
|---------|-----|
| Browser can't reach `landscape.demo.internal` | The server IP probably changed. Re-run `scripts/03-host-dns.sh`. |
| `multipass transfer` / `--cloud-init` says "permission denied" | The Multipass snap can only read files in your home folder. Clone the repo under `~`. |
| `04-launch-clients.sh` says "no administrator account yet" | Create the first administrator in the browser (`docs/02-first-login.md`), then run the script again. |
| A client appears twice under **Computers → Pending** | An earlier registration attempt (made before the administrator existed) went through late. Accept the newest entry and reject the older one. Re-running `04-launch-clients.sh` skips clients that are already registered, so it won't add more. |
| A client never shows up under Pending | Run `multipass exec <vm> -- sudo tail -50 /var/log/landscape/broker.log`. Usually the client can't reach the server name or doesn't trust its certificate. Re-run `scripts/04-launch-clients.sh`. |
| `landscape-api` gives SSL errors | Re-run `scripts/05-api-setup.sh` to fetch the server certificate again. |
| **Repositories → Mirrors** gives an error | Debarchive isn't running or isn't reachable. Run `multipass exec landscape-server -- sudo snap services landscape-debarchive` (expect `active`) and `multipass exec landscape-server -- sudo snap logs landscape-debarchive -n 50`. |
| Mirror update fails or is slow | Check the mirror's progress in **Repositories → Mirrors**. Change `MIRROR_URI` in `config/demo.env` to try another repo. |
| Clients can't download from the mirror | Open `http://landscape.demo.internal:8000/chrome/` and check that `dists/` is there. Make sure the profile's `deb` line points at that same folder. |
| Portal shows 503 / clients can't connect after install | Landscape's own services aren't running, usually because its one-time setup ran out of memory (`multipass exec landscape-server -- sudo journalctl -k \| grep -i 'out of memory'`). Re-run `scripts/02-install-server.sh`: it adds swap (`SERVER_SWAP` in `config/demo.env`), re-runs the setup and stops with an error if Landscape still isn't answering. Check services with `multipass exec landscape-server -- sudo lsctl status`. |
| Something looks stuck after install | Check the 26.04 helper services: `multipass exec landscape-server -- sudo snap services landscape-task-handler landscape-outbox landscape-debarchive`. |
| Graphs are empty | Monitoring data needs a few exchanges. Wait 2–3 minutes after the clients boot. |
