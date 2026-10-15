#!/bin/bash
# fetch updated drivers from gist, kill stale runs, relaunch appropriately
G=https://gist.github.com/EngineeringWithJay/d6df9a52625bb2ea2063938b843f4f97/raw
cd /root
for f in g5.sh g1_setup.sh g1_run.sh g2_run.sh; do curl -sL $G/$f -o $f 2>/dev/null; done
pkill -f 'g5.sh' || true; pkill -f 'g1_setup' || true; pkill -f 'g1_run' || true; pkill -f 'llama-' || true
sleep 1
if [ -n "$ROLE" ]; then :; fi
echo REDPLY_READY
