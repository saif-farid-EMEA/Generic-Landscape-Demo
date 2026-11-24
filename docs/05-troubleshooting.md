# Troubleshooting

| Symptom | Fix |
|---------|-----|
| Browser can't reach `landscape.demo.internal` | The server IP probably changed. Re-run `scripts/03-host-dns.sh`. |
| `multipass transfer` / `--cloud-init` says "permission denied" | The Multipass snap can only read files in your home folder. Clone the repo under `~`. |
| A client never shows up under Pending | Run `multipass exec <vm> -- sudo tail -50 /var/log/landscape/broker.log`. Usually the client can't reach the server name or doesn't trust its certificate. Re-run `scripts/04-launch-clients.sh`. |
| `landscape-api` gives SSL errors | Re-run `scripts/05-api-setup.sh` to fetch the server certificate again. |
| **Repositories → Mirrors** gives an error | Debarchive isn't running or isn't reachable. Run `multipass exec landscape-server -- sudo snap services landscape-debarchive` (expect `active`) and `multipass exec landscape-server -- sudo snap logs landscape-debarchive -n 50`. |
| Mirror update fails or is slow | Check the mirror's progress in **Repositories → Mirrors**. Change `MIRROR_URI` in `config/demo.env` to try another repo. |
| Clients can't download from the mirror | Open `http://landscape.demo.internal:8000/chrome/` and check that `dists/` is there. Make sure the profile's `deb` line points at that same folder. |
| Something looks stuck after install | Check the 26.04 helper services: `multipass exec landscape-server -- sudo snap services landscape-task-handler landscape-outbox landscape-debarchive`. |
| Graphs are empty | Monitoring data needs a few exchanges. Wait 2–3 minutes after the clients boot. |
