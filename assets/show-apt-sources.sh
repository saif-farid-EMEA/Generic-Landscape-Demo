#!/bin/bash
# Landscape demo script "Show APT sources": paste this into the portal (Scripts -> Add script).
# Run it as root on tag:web after you link the internal-apps repository profile,
# then open the result in the portal to show that the internal mirror arrived.
# You don't run this file on your laptop. Landscape sends it to the machine,
# runs it there, and shows you its output in the portal.

# Ubuntu keeps its list of software sources as small files in this folder.
# "ls -l" lists them with details; a new Landscape file appears here once the
# repository profile has been applied.
ls -l /etc/apt/sources.list.d/
# Print every line of each Landscape-managed source file, prefixed with the
# file's name ("grep -H ."). If there are none yet ("||"), say so instead.
# "2>/dev/null" hides the error message shown when no file matches.
grep -H . /etc/apt/sources.list.d/*landscape* 2>/dev/null || echo "No Landscape sources yet; wait ~30 seconds and run this again."
