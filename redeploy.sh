#!/bin/bash
# fetch updated drivers from gist, kill stale runs, relaunch appropriately
A=https://api.github.com/repos/EngineeringWithJay/gwork-fleet/contents
cd /root
for f in g5.sh g1_setup.sh g1_run.sh g2_run.sh; do curl -sL -H 'Accept: application/vnd.github.raw' $A/$f -o $f 2>/dev/null; done
pkill -f 'g5.sh' || true; pkill -f 'g1_setup' || true; pkill -f 'g1_run' || true; pkill -f 'llama-' || true
sleep 1

echo REDPLY_READY
