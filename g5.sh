#!/bin/bash
# G5: gen-2 PQ2_0 CUDA rows + gen-1 tg recovery with full capture
set -u; cd /root
F=https://github.com/EngineeringWithJay/prism-releases/releases/download/prism-b10777-e3de715
HF=https://huggingface.co/prism-ml/Ternary-Bonsai-27B-gguf/resolve/main
[ -x llama-bench ] || [ -x bin/llama-bench ] || { curl -sL https://github.com/EngineeringWithJay/prism-releases/releases/download/prism-b10777-e3de715/llama-prism-b10777-e3de715-bin-linux-cuda-12.4-x64.tar.gz|tar xz; }
[ -f PQ2_0.gguf ] || curl -sL $HF/Ternary-Bonsai-27B-PQ2_0.gguf -o PQ2_0.gguf
[ -f Q2_g64.gguf ] || curl -sL $HF/Ternary-Bonsai-27B-Q2_g64.gguf -o Q2_g64.gguf
B=/home/dst/Ternary-Bonsai-27B-Q1_0.gguf
[ -f Q1_0.gguf ] || { curl -sL $HF/../../Bonsai-27B-gguf/resolve/main/Bonsai-27B-Q1_0.gguf -o Q1_0.gguf; }
for t in PQ2_0 Q2_g64 Q1_0; do
  for r in 1 2 3; do
    for m in "512 128" "4096 256"; do
      set -- $m
      echo "### $t -p $1 -n $2 r$r"
      ./llama-bench -m $t.gguf -ngl 99 -fa 1 -p $1 -n $2 -r 1 -o csv 2>/dev/null | sed -n '2,6p'
    done
  done
done
sha256sum *.gguf | cut -c1-16
nvidia-smi --query-gpu=name,memory.total --format=csv,noheader
echo B5_DONE
