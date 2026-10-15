#!/usr/bin/env python3
"""G1: independent MATH-500 verification for Ternary-Bonsai (gen-1) + Bonsai-2 (gen-2).
Greedy decode, fixed prompt, exact symbolic verification (sympy) + string-normalized
fallback; unresolvable answers counted separately. Resumable via results jsonl."""
import glob, json, re, sys, time, urllib.request
from pathlib import Path
import sympy as sp
from datasets import load_from_disk, load_dataset

MODEL = sys.argv[1]; OUT = Path(sys.argv[2]); OUT.mkdir(exist_ok=True)
PORT = 8080

try:
    dd = load_from_disk("/root/math500")
    _rows = dd["train"] if "train" in dd else dd[list(dd.keys())[0]]
except Exception:
    files = sorted(glob.glob("/root/math500/**/*.parquet", recursive=True))
    _rows = load_dataset("parquet", data_files=files, split="train")
rows = list(_rows)
print(f"MATH500 rows={len(rows)}", flush=True)

def ask(text, timeout=600):
    body = {"prompt": text, "temperature": 0, "max_tokens": 1024, "stop": ["</s>", "<|"]}
    req = urllib.request.Request(f"http://localhost:{PORT}/v1/completions",
        data=json.dumps(body).encode(), headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.load(r)["choices"][0]["text"]

def boxed(s):
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
    except Exception:
        pass
    return "NEQ"

resf = OUT / f"results_{MODEL}.jsonl"
done = set()
if resf.exists():
    for line in resf.read_text().splitlines():
        try: done.add(json.loads(line)["id"])
        except Exception: pass
log = open(resf, "a")
t0 = time.time(); nerr = 0
for i, r in enumerate(rows):
    rid = r.get("id") or r.get("unique_id") or i
    if rid in done: continue
    prob = r["problem"]; gold = boxed(r["solution"]) or ""
    prompt = (f"Problem:\n{prob}\n\nSolve step by step. End with your final answer "
              f"as \\boxed{{answer}}.\n\nSolution:\n")
    gen = None
    try:
        gen = ask(prompt)
    except Exception as e:
        nerr += 1
        print("HTTPERR", nerr, repr(e)[:120], flush=True)
        time.sleep(3)
        if nerr >= 10:
            print("TOO_MANY_HTTPERR_ABORT", flush=True)
            break
    v = verify(boxed(gen) if gen else None, gold)
    log.write(json.dumps({"id": rid, "verdict": v, "gold": gold,
                          "pred": boxed(gen) if gen else None}) + "\n"); log.flush()
    if i % 25 == 0:
        vs = [json.loads(l)["verdict"] for l in resf.read_text().splitlines() if l.strip()]
        print(f"{i}/{len(rows)} acc={vs.count('EQ')/max(1,len(vs)):.3f} noans={vs.count('NO_ANSWER')/max(1,len(vs)):.3f} {time.time()-t0:.0f}s", flush=True)
vs = [json.loads(l)["verdict"] for l in resf.read_text().splitlines() if l.strip()]
n = max(1, len(vs))
print("FINAL", json.dumps({"model": MODEL, "n": len(vs), "acc": vs.count("EQ")/n,
      "wrong": vs.count("NEQ")/n, "unresolved": vs.count("NO_ANSWER")/n, "httperr": nerr}), flush=True)
