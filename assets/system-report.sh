#!/bin/bash
# Landscape demo script "System report": paste this into the portal (Scripts -> Add script).
# Run it as root against tag:demo.

# Show the machine's hostname, OS and kernel
hostnamectl
# Show how long the machine has been up and its load average
uptime
# Show free and used space on the root disk
df -h /
# Show memory usage
free -h
