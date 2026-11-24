#!/bin/bash
# Landscape demo script "CPU spike": paste this into the portal (Scripts -> Add script).
# Run it as root on db-01 (search for "db-01", or use tag:db) about 2 minutes
# before you show the monitoring graphs, so the spike has time to appear.
# You don't run this file on your laptop. Landscape sends it to the machine and
# runs it there, and you start and follow it entirely from the portal.

# Keep one CPU core busy at 100% for 4 minutes, then stop by itself.
# "stress-ng" was installed on every client by scripts/remote/register-client.sh.
# 240 seconds stays under the portal's default script time limit of 300 seconds,
# so Landscape reports the run as a success instead of a time-out.
stress-ng --cpu 1 --timeout 240s
