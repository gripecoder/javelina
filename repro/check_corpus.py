import glob, os, random, sys

KEY = bytes.fromhex("DEDAFF1FFDEDBDDCD80DCDDEDD011111")

def head(path, n=16):
    with open(path, "rb") as f:
        h = f.read(16)
        if len(h) < 16 or h[:8] != b"{DRMPDK}":
            return None
        start = int.from_bytes(h[12:16], "little")
        f.seek(start)
        return start, f.read(n)

def check(path):
    got = head(path)
    if not got:
        return "BADMAGIC", None
    start, ct = got
    pt = bytes(a ^ KEY[i % 16] for i, a in enumerate(ct))
    return pt, start

files = sorted(glob.glob(r"javelin-samples\*.drmz") + glob.glob(r"javelin-samples\*.DRMZ"))
print("files:", len(files))
ok = bad = magic = 0
badlist = []
for p in files:
    try:
        r, start = check(p)
    except Exception as e:
        print("ERR", p, e)
        continue
    if r == "BADMAGIC":
        magic += 1
        continue
    if r.startswith(b"%PDF"):
        ok += 1
    else:
        bad += 1
        badlist.append((os.path.basename(p), start, r.hex()))
print("PDF head with fixed CFkey2:", ok)
print("other heads:", bad)
print("bad magic:", magic)
for name, start, h in badlist[:15]:
    print("  MISS", name, start, h)
random.seed()
print("random pick from misses:", random.choice(badlist) if badlist else "none")
