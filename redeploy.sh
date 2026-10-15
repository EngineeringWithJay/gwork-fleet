#!/bin/bash
# usage: bash redeploy.sh <role>  (role in: g1 g5 g2)
A=https://api.github.com/repos/EngineeringWithJay/gwork-fleet/contents
cd /root
for f in g5.sh g1_setup.sh g1_run.sh g2_run.sh run_g1.sh run_g5.sh run_g2.sh g1_eval.py; do
  curl -s -H 'Accept: application/vnd.github.raw' $A/$f -o $f
done
pkill -f 'run_g' || true; pkill -f 'llama-' || true
sleep 1
case "$1" in
  g1) setsid nohup bash /root/run_g1.sh > /root/g1.log 2>&1 & ;;
  g5) setsid nohup bash /root/run_g5.sh > /root/g5.log 2>&1 & ;;
  g2) setsid nohup bash /root/run_g2.sh > /root/g2.log 2>&1 & ;;
esac
echo REDEPLOYED_$1
