#!/bin/bash
# $1 = model to eval (gen1_PQ2_0|gen2_PQ2_0); waits for bench chain to end
cd /root
M="$1"
until ! pgrep -f 'g5.sh|g3.sh|rerun_g5_g3' >/dev/null && ! pgrep -f 'llama-' >/dev/null; do sleep 20; done
R=https://raw.githubusercontent.com/EngineeringWithJay/gwork-fleet/main
for f in g1_setup_bench.sh g1_run_one.sh g1_eval.py; do curl -s $R/$f -o $f; done
bash g1_setup_bench.sh && bash g1_run_one.sh "$M"
echo G1_BENCH_DONE
