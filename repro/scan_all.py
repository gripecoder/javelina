import glob, os, random, sys, time, io

sys.path.insert(0, "repro")
import xor32

paths = sorted({os.path.normcase(p): p for p in glob.glob("javelin-samples/*.drmz") + glob.glob("javelin-samples/*.DRMZ")}.items())
paths = sorted(p for _, p in paths)
print("unique files:", len(paths))

ok = 0
fail = []
t0 = time.time()
for p in paths:
    try:
        pt, start = xor32.decrypt(p)
    except Exception as e:
        fail.append((os.path.basename(p), "ERR %s %s" % (type(e).__name__, str(e)[:60])))
        continue
    good = (
        pt.startswith(b"%PDF-1.")
        and b"%%EOF" in pt[-1024:]
        and b"startxref" in pt[-2048:]
        and pt.count(b"endobj") > 5
    )
    if good:
        ok += 1
    else:
        fail.append((os.path.basename(p), pt[:12], b"%%EOF" in pt[-1024:], pt.count(b"endobj")))
print("structurally valid: %d / %d in %.1fs" % (ok, len(paths), time.time() - t0))
for f in fail[:10]:
    print("FAIL", f)

# deep validation on a random sample
random.seed()
sample = random.sample(paths, 12)
import pypdf
print("\ndeep check (pypdf) on 12 random files:")
for p in sample:
    pt, _ = xor32.decrypt(p)
    try:
        r = pypdf.PdfReader(io.BytesIO(pt), strict=False)
        txt = " ".join((r.pages[0].extract_text() or "").split())[:70]
        print("  %-46s %6.1f MB  %4d pages  %s" % (os.path.basename(p), len(pt) / 1e6, len(r.pages), txt))
    except Exception as e:
        print("  %-46s FAIL %s %s" % (os.path.basename(p), type(e).__name__, str(e)[:70]))
