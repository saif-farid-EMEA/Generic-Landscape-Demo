# Landscape self-hosted demo lab

A reproducible lab for demoing **self-hosted Canonical Landscape** in 3–6 minutes on a
single Ubuntu laptop. It uses Multipass to run one Landscape Server VM and three managed client VMs.

It covers Landscape's five core functions:

| Function | What the demo shows |
|----------|---------------------|
| Monitoring & alerts | Live CPU graphs and alert counts |
| Packages & upgrades | Pending security updates, applied from the portal |
| Remote scripting | Running one script on many machines, from the portal or API |
| Repository management | An internal apt mirror pushed to machines by tag |
| Users & RBAC | Roles and access groups |

## Requirements

- Ubuntu 22.04 or 24.04 desktop with KVM (tested target: ThinkPad P16s Gen 4, 32 GB RAM, Ubuntu 24.04)
- About 14 GB free RAM and 80 GB free disk
- Internet access (for packages and the mirror sync)
- This repo cloned **under your home folder**, because the Multipass snap can only read files there

## Repository layout

```
config/
  demo.env              All settings (VM names, sizes, FQDN, mirror). Edit here only.
  api.env.example       Template for your Landscape API keys (copy to api.env, git-ignored)
scripts/
  lib.sh                Shared helpers used by every script
  00-host-prep.sh       Install Multipass and check KVM
  01-launch-server.sh   Create the server VM with its FQDN
  02-install-server.sh  Install Landscape Server (quickstart)
  03-host-dns.sh        Point your laptop at the server by name
  04-launch-clients.sh  Create and register the client VMs
  05-api-setup.sh       Configure the landscape-api CLI in the server
  06-repo-mirror.sh     Build the internal apt mirror and repository profile
  07-snapshot.sh        Snapshot the ready lab
  08-reset.sh           Restore the snapshot after a rehearsal
  09-preflight.sh       Demo-day health check
  99-cleanup.sh         Delete everything
  remote/               Scripts that run inside the VMs (pushed by the scripts above)
  demo/                 Helpers you run live during the demo
assets/
  system-report.sh      Script to paste into the Landscape portal
docs/
  01-architecture.md    Lab layout and design choices
  02-first-login.md     Browser steps: admin account, API keys, accepting clients
  03-portal-prestaging.md  Portal setup before the snapshot
  04-run-of-show.md     The 5-minute demo script
  05-troubleshooting.md Common problems and fixes
```

## Setup

```bash
# Make all scripts executable
chmod +x scripts/*.sh scripts/remote/*.sh scripts/demo/*.sh

# 1. Install Multipass and check KVM
./scripts/00-host-prep.sh
# 2. Create the Landscape Server VM
./scripts/01-launch-server.sh
# 3. Install Landscape Server inside it (~5 min)
./scripts/02-install-server.sh
# 4. Let your browser find the server by name
./scripts/03-host-dns.sh
```

➡️ Now follow [docs/02-first-login.md](docs/02-first-login.md): create the admin account and API keys.

```bash
# 5. Create the three client VMs and register them
./scripts/04-launch-clients.sh
```

➡️ Accept the three clients in the portal (**Computers → Pending**).

```bash
# 6. Give the server your API keys and test the API
./scripts/05-api-setup.sh
# 7. Build the internal apt mirror and repository profile
./scripts/06-repo-mirror.sh
```

➡️ Follow [docs/03-portal-prestaging.md](docs/03-portal-prestaging.md).

```bash
# 8. Save the ready-to-demo state
./scripts/07-snapshot.sh
```

## Demo day

```bash
# Start everything and check it's healthy
./scripts/09-preflight.sh
```

Then follow [docs/04-run-of-show.md](docs/04-run-of-show.md). Afterwards:

```bash
# Roll the lab back to the ready state
./scripts/08-reset.sh
```

## Customising

Everything is in [`config/demo.env`](config/demo.env): add or remove clients, change VM sizes,
point the mirror at a different repository, or switch the Landscape PPA.

## Teardown

```bash
# Delete all VMs, snapshots and the hosts entry
./scripts/99-cleanup.sh
```

## References

- [Landscape quickstart installation](https://ubuntu.com/landscape/docs/how-to-guides/landscape-installation-and-set-up/quickstart-installation/)
- [Landscape getting-started tutorial](https://ubuntu.com/landscape/docs/tutorial/)
- [Install Landscape Client](https://ubuntu.com/landscape/docs/how-to-guides/landscape-installation-and-set-up/install-landscape-client/)
- [Manage repositories with the API](https://ubuntu.com/landscape/docs/repositories)
- [Legacy API command-line client](https://ubuntu.com/landscape/docs/how-to-guides/api/use-the-legacy-api-command-line-client/)
