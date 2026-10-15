#!/bin/bash
set -e; cd /root
F=https://github.com/EngineeringWithJay/prism-releases/releases/download/prism-b10777-e3de715
[ -x llama-server ] || [ -x bin/llama-server ] || curl -sL https://github.com/EngineeringWithJay/prism-releases/releases/download/prism-b10777-e3de715/llama-prism-b10777-e3de715-bin-linux-cuda-12.4-x64.tar.gz|tar xz
pip -q install datasets sympy pyarrow huggingface_hub 2>/dev/null || pip -q install datasets sympy pyarrow
python3 - <<'PY'
from huggingface_hub import snapshot_download
snapshot_download(repo_id="HuggingFaceH4/MATH-500", repo_type="dataset", local_dir="/root/math500")
PY
curl -sL https://huggingface.co/prism-ml/Ternary-Bonsai-27B-gguf/resolve/main/Ternary-Bonsai-27B-PQ2_0.gguf -o gen1_PQ2_0.gguf &
curl -sL https://huggingface.co/prism-ml/Ternary-Bonsai-2-27B-gguf/resolve/main/Ternary-Bonsai-2-27B-PQ2_0.gguf -o gen2_PQ2_0.gguf &
wait; git clone -q --depth 1 https://github.com/PrismML-Eng/Bonsai-demo; echo G1_READY
