#!/bin/bash
cd /root
until ! pgrep -f g3.sh >/dev/null && ! pgrep -f llama-server >/dev/null; do sleep 10; done
A=https://api.github.com/repos/EngineeringWithJay/gwork-fleet/contents
for f in g5.sh g3.sh; do curl -s -H 'Accept: application/vnd.github.raw' $A/$f -o $f; done
bash g5.sh > g5.log 2>&1
bash g3.sh > g3.log 2>&1
echo RERUN_ALL_DONE >> g3.log
