import json, os, sys

sys.path.insert(0, "repro")
import xor32
import pymupdf

rows = json.load(open("repro/corpus.json", encoding="utf-8"))
JUNK = {"", "cover", "layout 2", "an", "00 quark new", "table of contents", "second edition 2026"}
need = []
for r in rows:
    d = (r["title"] or r["snippet"]).strip()
    if d.lower() in JUNK or len(d) < 18 or "graffle" in d or d.startswith("Microsoft Word"):
        need.append(r["file"])
print("need better description:", len(need))

PATH = {os.path.basename(p): p for p in os.listdir("javelin-samples")}
path_of = {}
import glob
for p in glob.glob("javelin-samples/*.drmz") + glob.glob("javelin-samples/*.DRMZ"):
    path_of[os.path.basename(p)] = p

out = {}
for f in need:
    p = path_of.get(f)
    if not p:
        continue
    pt, _ = xor32.decrypt(p)
    doc = pymupdf.open(stream=pt, filetype="pdf")
    cands = []
    for i in range(min(12, doc.page_count)):
        t = " ".join(doc[i].get_text().split())
        if len(t) > 10:
            cands.append("p%d: %s" % (i + 1, t[:130]))
        if len(cands) >= 3:
            break
    out[f] = cands
    doc.close()
    line = "%-46s %s" % (f, " || ".join(c[:80] for c in cands[:2]))
    print(line.encode("ascii", "replace").decode("ascii"))
json.dump(out, open("repro/corpus_more.json", "w", encoding="utf-8"), indent=1)
