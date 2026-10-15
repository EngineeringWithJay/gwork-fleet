#!/bin/bash
# G5: gen-2 PQ2_0 CUDA rows + gen-1 tg recovery with full capture
set -u; cd /root
[ -x llama-bench ] || [ -x bin/llama-bench ] || { curl -sL https://github.com/PrismML-Eng/llama.cpp/releases/download/prism-b10777-e3de715/llama-prism-b10777-e3de715-bin-linux-cuda-12.4-x64.tar.gz | tar xz; }
BIN=$(find /root -maxdepth 3 -name llama-bench -type f | head -1)
[ -n "$BIN" ] || { echo NO_BENCH; exit 1; }
HF=https://huggingface.co/prism-ml/Ternary-Bonsai-27B-gguf/resolve/main
[ -f PQ2_0.gguf ] || curl -sL $HF/Ternary-Bonsai-27B-PQ2_0.gguf -o PQ2_0.gguf
[ -f Q2_g64.gguf ] || curl -sL $HF/Ternary-Bonsai-27B-Q2_g64.gguf -o Q2_g64.gguf
[ -f Q1_0.gguf ] || curl -sL https://huggingface.co/prism-ml/Bonsai-27B-gguf/resolve/main/Bonsai-27B-Q1_0.gguf -o Q1_0.gguf
for t in PQ2_0 Q2_g64 Q1_0; do
  for m in "512 128" "4096 256"; do
    set -- $m
    echo "### $t -p $1 -n $2"
    $BIN -m $t.gguf -ngl 99 -p $1 -n $2 -r 3 -o csv 2>&1
  done
done
sha256sum *.gguf | cut -c1-16
nvidia-smi --query-gpu=name,memory.total --format=csv,noheader
echo B5_DONE
