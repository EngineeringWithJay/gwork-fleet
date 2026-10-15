#!/usr/bin/env python3
"""G1: independent MATH-500 verification for Ternary-Bonsai (gen-1) + Bonsai-2 (gen-2).
Greedy decode, fixed prompt, exact symbolic verification (sympy) + string-normalized
fallback; unresolvable answers counted separately (abstain-by-verifier). Resumable."""
import json, re, sys, time, urllib.request, subprocess
from pathlib import Path
import sympy as sp
from datasets import load_from_disk

MODEL = sys.argv[1]; OUT = Path(sys.argv[2]); OUT.mkdir(exist_ok=True)
PORT = 8080
prompt_rows = load_from_disk("/root/math500")["train"]

def ask(text, timeout=600):
    body = {"prompt": text, "temperature": 0, "max_tokens": 1024, "stop": ["</s>", "<|"]}
    req = urllib.request.Request(f"http://localhost:{PORT}/v1/completions",
        data=json.dumps(body).encode(), headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.load(r)["choices"][0]["text"]

def boxed(s):
    # last balanced \boxed{...}
    out = None
    for m in re.finditer(r"\\boxed\{", s):
        i = m.end(); depth = 1
        while i < len(s) and depth:
            if s[i] == "{": depth += 1
            elif s[i] == "}": depth -= 1
            i += 1
        out = s[m.end():i-1]
    return out

def norm(x):
    return re.sub(r"\s|\\,|\\;|\\!", "", (x or "")).lower()

def verify(pred, gold):
    if pred is None: return "NO_ANSWER"
    if norm(pred) == norm(gold): return "EQ"
    try:
        a = sp.sympify(pred.replace("$","").replace("\\dfrac","\\frac"))
        b = sp.sympify(gold.replace("$","").replace("\\dfrac","\\frac"))
        if sp.simplify(a - b) == 0: return "EQ"
    except Exception: pass
    return "NEQ"

rows = list(prompt_rows)
done = {}
resf = OUT/f"results_{MODEL}.jsonl"
if resf.exists():
    for line in resf.read_text().splitlines():
        r = json.loads(line); done[r["id"]] = r
log = open(resf, "a")
t0 = time.time()
for i, r in enumerate(rows):
    rid = r.get("id") or i
    if rid in done: continue
    prob = r["problem"]; gold = boxed(r["solution"]) or ""
    prompt = (f"Problem:\n{prob}\n\nSolve step by step. End with your final answer "
              f"as \\boxed{{answer}}.\n\nSolution:\n")
    try:
        gen = ask(prompt)
    except Exception as e:
        print("HTTPERR", e, flush=True); time.sleep(5); gen = None
    v = verify(boxed(gen) if gen else None, gold)
    log.write(json.dumps({"id": rid, "verdict": v, "gold": gold,
                          "pred": boxed(gen) if gen else None}) + "\n"); log.flush()
    if i % 25 == 0:
        vs = [d["verdict"] for d in done.values()] + [json.loads(l)["verdict"] for l in resf.read_text().splitlines()]
        print(f"{i}/{len(rows)} acc={vs.count('EQ')/max(1,len(vs)):.3f} noans={vs.count('NO_ANSWER')/max(1,len(vs)):.3f} {time.time()-t0:.0f}s", flush=True)
print("FINAL", flush=True)
vs = [json.loads(l)["verdict"] for l in resf.read_text().splitlines()]
n = len(vs)
print(json.dumps({"model": MODEL, "n": n, "acc": vs.count("EQ")/n,
                  "wrong": vs.count("NEQ")/n, "unresolved": vs.count("NO_ANSWER")/n}))
