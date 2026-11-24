#!/bin/bash
# Landscape demo script "System report": paste this into the portal (Scripts -> Add script).
# Run it as root against tag:demo (meaning: every machine tagged "demo").
# You don't run this file on your laptop. Landscape sends it to each machine,
# runs it there, and shows you each machine's output in the portal.

# Show the machine's name, operating system version and kernel (Linux core) version
hostnamectl
# Show how long the machine has been running ("up") and its load average
# (roughly: how busy the CPU has been over the last 1, 5 and 15 minutes)
uptime
# Show used and free space on the main disk ("/" is the top-level folder).
# "-h" means "human-readable": sizes in G/M instead of long raw numbers.
df -h /
# Show used and free memory (RAM), also in human-readable sizes
free -h
