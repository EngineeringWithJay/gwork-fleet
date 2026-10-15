#!/bin/bash
# G3: measured max -c per VRAM w/ Bonsai-2 PQ2_0 (-ngl 99) + RAM-tier check
set -u; cd /root
HF2=https://huggingface.co/prism-ml/Ternary-Bonsai-2-27B-gguf/resolve/main
[ -f gen2_PQ2_0.gguf ] || curl -sL $HF2/Ternary-Bonsai-2-27B-PQ2_0.gguf -o gen2_PQ2_0.gguf
SRV=$(find /root -name llama-server -type f | head -1)
[ -n "$SRV" ] || { echo NO_SERVER; exit 1; }
_mem_kb=$(awk '/MemTotal/ {print $2}' /proc/meminfo); _mem_gb=$((_mem_kb/1048576))
if [ $_mem_gb -le 11 ]; then DE=8192; elif [ $_mem_gb -le 23 ]; then DE=16384; elif [ $_mem_gb -le 35 ]; then DE=32768; elif [ $_mem_gb -le 71 ]; then DE=65536; else DE=131072; fi
echo "RAM_GB=$_mem_gb default_tier_by_their_function=$DE"
for C in 8192 16384 32768 65536 131072; do
  $SRV -m gen2_PQ2_0.gguf --host 127.0.0.1 --port 8199 -ngl 99 -c $C > probe_$C.log 2>&1 &
  P=$!; OK=0
  for i in $(seq 1 60); do sleep 2; curl -s http://127.0.0.1:8199/health | grep -q ok && { OK=1; break; }; kill -0 $P 2>/dev/null || break; done
  MEM=$(nvidia-smi --query-gpu=memory.used --format=csv,noheader)
  if [ $OK = 1 ]; then echo "C=$C FITS mem_used=$MEM"; else echo "C=$C FAILS"; tail -2 probe_$C.log | head -1; fi
  kill $P 2>/dev/null; wait $P 2>/dev/null; sleep 2
done
nvidia-smi --query-gpu=name,memory.total --format=csv,noheader
echo G3_DONE
