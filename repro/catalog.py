"""Catalogue every .drmz in the corpus: pages, title, first-page text."""
import glob, io, os, sys, time, json

sys.path.insert(0, "repro")
import xor32
import pymupdf

paths = sorted({os.path.normcase(p): p for p in glob.glob("javelin-samples/*.drmz") + glob.glob("javelin-samples/*.DRMZ")}.items())
paths = sorted((p for _, p in paths), key=lambda p: os.path.basename(p).lower())
print("files:", len(paths))

rows = []
t0 = time.time()
for i, p in enumerate(paths, 1):
    name = os.path.basename(p)
    try:
        pt, start = xor32.decrypt(p)
        doc = pymupdf.open(stream=pt, filetype="pdf")
        meta = doc.metadata or {}
        title = (meta.get("title") or "").strip()
        txt = doc[0].get_text() if doc.page_count else ""
        snippet = " ".join(txt.split())[:110]
        rows.append({
            "file": name,
            "mb": round(len(pt) / 1e6, 1),
            "pages": doc.page_count,
            "title": title,
            "snippet": snippet,
        })
        doc.close()
    except Exception as e:
        rows.append({"file": name, "mb": round(os.path.getsize(p) / 1e6, 1), "pages": -1,
                     "title": "", "snippet": "FAIL %s: %s" % (type(e).__name__, str(e)[:60])})
    if i % 20 == 0:
        print("  %3d/%d  %.0fs" % (i, len(paths), time.time() - t0), flush=True)

with open("repro/corpus.json", "w", encoding="utf-8") as f:
    json.dump(rows, f, indent=1)

with open("repro/corpus.md", "w", encoding="utf-8") as f:
    f.write("| file | MB | pages | description |\n|---|---|---|---|\n")
    for r in rows:
        desc = (r["title"] or "").strip()
        if not desc:
            desc = r["snippet"]
        desc = desc.replace("|", "/").strip()
        f.write("| %s | %.1f | %s | %s |\n" % (r["file"], r["mb"], r["pages"], desc[:120]))

print("done", len(rows), "rows in %.0fs" % (time.time() - t0))
