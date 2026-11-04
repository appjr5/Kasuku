"""Swahili Gemma as an AUTHORING tool. Run on a laptop (NOT on the phone). UNTESTED: I could not reach Hugging Face from my sandbox.

  pip install transformers torch accelerate
  python tool/gen_tips.py tips    # more variants of every coaching tip   -> assets/content/tips_sw.generated.json
  python tool/gen_tips.py review  # Gemma's Swahili for every English meaning/note -> tool/sw_review.json
Review the output as a Swahili speaker before merging anything into the app.
"""
import json, re, sys, pathlib
M = "CraneAILabs/swahili-gemma-1b"
ROOT = pathlib.Path(__file__).resolve().parent.parent
from transformers import AutoTokenizer, AutoModelForCausalLM
tok = AutoTokenizer.from_pretrained(M); model = AutoModelForCausalLM.from_pretrained(M, torch_dtype="auto")

def ask(prompt, n=200, temp=0.7):
    ids = tok.apply_chat_template([{"role": "user", "content": prompt}], add_generation_prompt=True, return_tensors="pt")
    out = model.generate(ids, max_new_tokens=n, do_sample=temp > 0, temperature=temp or None, top_p=0.9)
    return tok.decode(out[0][ids.shape[1]:], skip_special_tokens=True).strip()

def tips():
    seed = json.loads((ROOT / "assets/content/tips_sw.json").read_text())
    def more(t):
        txt = ask("Andika tofauti 5 za ushauri huu wa mwalimu mkali lakini mwenye upendo kwa watoto. "
                  "Kila moja katika mstari wake, sentensi 1-2, Kiswahili sanifu. Weka {target} na {heard} kama zilivyo, kama zipo.\n\n" + t, 400)
        return [re.sub(r"^\s*[\d\-\*\.\)]+\s*", "", l).strip() for l in txt.splitlines() if len(l.strip()) > 15]
    out = {}
    for k, v in seed.items():
        if k == "lang":
            out["lang"] = {lg: {kk: [x for t in vv for x in more(t)] for kk, vv in d.items()} for lg, d in v.items()}
        else:
            out[k] = [x for t in v for x in more(t)]
    (ROOT / "assets/content/tips_sw.generated.json").write_text(json.dumps(out, ensure_ascii=False, indent=1))

def review():
    res = {}
    for f in (ROOT / "assets/content").glob("??.json"):
        d = json.loads(f.read_text())
        for u in d["units"]:
            for i, it in enumerate(u["items"]):
                res[f"{u['id']}_{i}"] = {"en": it["m"], "gemma_sw": ask("Tafsiri kwa Kiswahili sanifu, jibu tafsiri tu: " + it["m"], 40, 0)}
    (ROOT / "tool/sw_review.json").write_text(json.dumps(res, ensure_ascii=False, indent=1))

{"tips": tips, "review": review}[sys.argv[1]]()
