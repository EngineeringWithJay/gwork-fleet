#!/bin/bash
set -u; cd /root
SRV=$( [ -x llama-server ] && echo ./llama-server || ([ -x bin/llama-server ] && echo ./bin/llama-server) || find /root -name llama-server -type f 2>/dev/null | head -1 )
[ -n "$SRV" ] || { echo NO_SERVER; exit 1; }
for m in gen1_PQ2_0 gen2_PQ2_0; do
  $SRV -m $m.gguf --host 127.0.0.1 --port 8080 -ngl 99 -c 3072 --flash atTN > server_$m.log 2>&1 &
  SPID=$!
  until curl -s http://127.0.0.1:8080/health | grep -q ok; do sleep 5; done
  python3 g1_eval.py $m out_$m 2>&1 | tee eval_$m.log
  kill $SPID; sleep 3
done
echo G1_ALL_DONE
