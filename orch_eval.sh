#!/bin/bash
# $1 = eval model or "bench" for bench-only
cd /root
pkill -f 'rerun_g5_g3' 2>/dev/null; pkill -f 'g3_after' 2>/dev/null; pkill -f 'g1ob' 2>/dev/null; pkill -f 'g1_on_bench' 2>/dev/null
sleep 1; rm -f g5.log g3.log g1ob.log
R=https://raw.githubusercontent.com/EngineeringWithJay/gwork-fleet/main
for f in g5.sh g3.sh g1_setup_bench.sh g1_run_one.sh g1_eval.py; do curl -s $R/$f -o $f; done
for f in g5.sh g3.sh g1_setup_bench.sh g1_run_one.sh g1_eval.py; do head -1 $f | grep -q '^#!' || { echo BAD_FETCH_$f; exit 1; }; done
bash g5.sh > g5.log 2>&1
bash g3.sh > g3.log 2>&1
if [ "$1" != "bench" ]; then
  bash g1_setup_bench.sh > setup.log 2>&1
  bash g1_run_one.sh "$1" > eval.log 2>&1
fi
echo ORCH_ALL_DONE
