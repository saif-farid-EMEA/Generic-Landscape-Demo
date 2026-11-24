# Lab architecture

```
 Your laptop (Ubuntu 24.04, 32 GB RAM)
 ├── Browser ──────────────► https://landscape.demo.internal
 └── Multipass (KVM)
     ├── landscape-server   24.04  4 vCPU / 8 GB / 50 GB   Landscape Server 26.04 LTS (quickstart)
     ├── web-01             24.04  1 vCPU / 2 GB / 10 GB   tags: demo, web
     ├── db-01              24.04  1 vCPU / 8 GB / 10 GB   tags: demo, db
     └── legacy-01          22.04  1 vCPU / 2 GB / 10 GB   tags: demo, legacy
```

Total: about 20 GiB RAM, leaving about 12 GiB for the host, browser and screen recording.

## Design choices

- **Landscape 26.04 LTS on an Ubuntu 24.04 server VM.** Landscape's quickstart install
  isn't supported on Ubuntu 26.04, so the server VM stays on 24.04. On top of the quickstart
  package, `scripts/remote/install-server.sh` sets up the three snaps 26.04 needs:
  `landscape-task-handler`, `landscape-outbox` and `landscape-debarchive`.
- **Repository management through Debarchive.** 26.04 removed the legacy API commands for
  mirrors, so the mirror, publication and repository profile are created in the portal
  (see `docs/03-portal-prestaging.md`). Published files are served by Apache on port 8000.
- **Portal first.** Every demo action is done in the web portal, including starting the
  CPU spike and checking APT sources (as Landscape scripts). Terminal helpers in
  `scripts/demo/` remain only as fallbacks.
- **8 GiB on db-01.** It runs the most demo scripts (the 4-minute CPU spike plus the
  System report), so it gets the extra memory. The other clients stay at 2 GiB to
  keep the laptop comfortable. Change it per client in `CLIENTS` in `config/demo.env`.
- **Multipass VMs.** These match the official Landscape tutorial, and snapshots make it easy to reset between rehearsals.
- **`.internal` domain.** This domain is reserved for private use and doesn't clash with mDNS (`.local`).
- **Fast client intervals.** Exchange every 60 s and ping every 10 s, so graphs,
  package changes and script results appear during the demo instead of minutes later.
  Don't use these settings in production.
- **Unattended upgrades disabled on clients.** This keeps pending security updates
  available to show in the demo.
