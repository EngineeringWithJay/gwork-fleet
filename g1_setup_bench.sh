#!/bin/bash
set -e; cd /root
[ -d /root/math500 ] || pip -q install huggingface_hub && python3 -c "
from huggingface_hub import snapshot_download
snapshot_download(repo_id='HuggingFaceH4/MATH-500', repo_type='dataset', local_dir='/root/math500')"
pip -q install datasets sympy pyarrow 2>/dev/null || pip -q install datasets sympy
# reuse bench files: gen-1 PQ2_0 already downloaded by g5 as PQ2_0.gguf; gen-2 by g3 as gen2_PQ2_0.gguf
[ -f gen1_PQ2_0.gguf ] || ln -sf /root/PQ2_0.gguf gen1_PQ2_0.gguf
[ -f gen2_PQ2_0.gguf ] || ln -sf /root/gen2_PQ2_0.gguf gen2_PQ2_0.gguf 2>/dev/null || curl -sL https://huggingface.co/prism-ml/Ternary-Bonsai-2-27B-gguf/resolve/main/Ternary-Bonsai-2-27B-PQ2_0.gguf -o gen2_PQ2_0.gguf
echo BENCH_G1_READY
