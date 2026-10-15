#!/bin/bash
set -u; cd /root
NEW=https://github.com/PrismML-Eng/llama.cpp/releases/download/prism-b10777-e3de715/llama-prism-b10777-e3de715-bin-linux-cuda-12.4-x64.tar.gz
[ -x bin/llama-server ] || { curl -sL $NEW | tar xz; }
SRV=$(find /root -name llama-server -type f | head -1); BINDIR=$(dirname $SRV)
echo "SRV=$SRV"; $SRV --help 2>&1 | grep -iE 'drafter|model-draft' | head -4
HF=https://huggingface.co/prism-ml/Ternary-Bonsai-27B-gguf/resolve/main
[ -f Ternary-Bonsai-27B-Q2_g64.gguf ] || curl -sL $HF/Ternary-Bonsai-27B-Q2_g64.gguf -o Ternary-Bonsai-27B-Q2_g64.gguf
[ -f Ternary-Bonsai-27B-dspark-Q4_1.gguf ] || curl -sL $HF/Ternary-Bonsai-27B-dspark-Q4_1.gguf -o Ternary-Bonsai-27B-dspark-Q4_1.gguf
cd /root/Bonsai-demo
python3 /root/Bonsai-demo/scripts/spec_bench/spec_bench.py \
  --bin-dir $BINDIR \
  --model /root/Ternary-Bonsai-27B-Q2_g64.gguf \
  --drafter-v1 /root/Ternary-Bonsai-27B-dspark-Q4_1.gguf \
  --slots 1 --repeats 1 --allow-busy-gpu \
  --out /root/spec_results_titanv 2>&1 | tail -30
echo G2_DONE
