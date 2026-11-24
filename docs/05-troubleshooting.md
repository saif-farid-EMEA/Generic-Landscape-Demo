# Troubleshooting

| Symptom | Fix |
|---------|-----|
| Browser can't reach `landscape.demo.internal` | The server IP probably changed. Re-run `scripts/03-host-dns.sh`. |
| `multipass transfer` / `--cloud-init` says "permission denied" | The Multipass snap can only read files in your home folder. Clone the repo under `~`. |
| A client never shows up under Pending | Run `multipass exec <vm> -- sudo tail -50 /var/log/landscape/broker.log`. Usually the client can't reach the server name or doesn't trust its certificate. Re-run `scripts/04-launch-clients.sh`. |
| `landscape-api` gives SSL errors | Re-run `scripts/05-api-setup.sh` to fetch the server certificate again. |
| Mirror sync fails or is slow | Check the activity with `landscape-api get-activities --query type:SyncPocketRequest --limit 1`. Change `MIRROR_URI` in `config/demo.env` to try another repo. |
| Graphs are empty | Monitoring data needs a few exchanges. Wait 2–3 minutes after the clients boot. |
