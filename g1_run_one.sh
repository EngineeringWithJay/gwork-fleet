#!/bin/bash
set -u; cd /root
M="$1"
SRV=$(find /root -maxdepth 3 -name llama-server -type f | head -1)
[ -n "$SRV" ] || { echo NO_SERVER; exit 1; }
[ -f $M.gguf ] || { echo NO_MODEL_$M; exit 1; }
[ -d /root/math500 ] || { echo NO_MATH500; exit 1; }
"$SRV" -m $M.gguf --host 127.0.0.1 --port 8080 -ngl 99 -c 3072 > server_$M.log 2>&1 &
SPID=$!
OK=0
for i in $(seq 1 72); do curl -s http://127.0.0.1:8080/health | grep -q ok && { OK=1; break; }; kill -0 $SPID 2>/dev/null || break; sleep 5; done
if [ "$OK" != 1 ]; then echo SERVER_FAIL; tail -5 server_$M.log; exit 1; fi
python3 g1_eval.py $M out_$M 2>&1 | tee eval_$M.log
kill $SPID 2>/dev/null || true
echo EVAL_DONE_$M
