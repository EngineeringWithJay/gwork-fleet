#!/bin/bash
set -u; cd /root
M="$1"
SRV=$(find /root -maxdepth 3 -name llama-server -type f | head -1)
[ -n "$SRV" ] || { echo NO_SERVER; exit 1; }
"$SRV" -m $M.gguf --host 127.0.0.1 --port 8080 -ngl 99 -c 3072 --flash atTN > server_$M.log 2>&1 &
SPID=$!
until curl -s http://127.0.0.1:8080/health | grep -q ok; do sleep 5; done
python3 g1_eval.py $M out_$M 2>&1 | tee eval_$M.log
kill $SPID 2>/dev/null || true
