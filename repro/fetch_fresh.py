import hashlib, os, sys, urllib.request as u

sys.path.insert(0, "repro")
import xor32

UA = {"User-Agent": "Mozilla/5.0"}
CANDIDATES = [
    "https://www.drumlinsecurity.com/orders/edubooks/drmz/Ingenier%C3%ADa_de_Prompt_v1.0.drmz",
    "https://www.drumlinsecurity.com/orders/library/pharmaguide.drmz",
]
os.makedirs("repro/in", exist_ok=True)

def sha(b):
    return hashlib.sha256(b).hexdigest()[:16]

for url in CANDIDATES:
    name = url.rsplit("/", 1)[1].replace("%C3%AD", "i")
    try:
        data = u.urlopen(u.Request(url, headers=UA), timeout=90).read()
    except Exception as e:
        print("FAIL", name, type(e).__name__, str(e)[:80])
        continue
    path = os.path.join("repro/in", name)
    with open(path, "wb") as f:
        f.write(data)
    print("downloaded", name, len(data), "magic", data[:8], "sha", sha(data))
    pt, start = xor32.decrypt(path)
    print("   hdr", start, "head", pt[:16], "%%EOF", b"%%EOF" in pt[-1024:], "endobj", pt.count(b"endobj"))
    import pypdf, io
    try:
        r = pypdf.PdfReader(io.BytesIO(pt), strict=False)
        print("   pages", len(r.pages))
    except Exception as e:
        print("   pypdf FAIL", type(e).__name__, str(e)[:80])

# same book already in the corpus?
local = "javelin-samples/Ingenieria_de_Prompt_v1.0.drmz"
if os.path.exists(local):
    a = open(local, "rb").read()
    for f in os.listdir("repro/in"):
        b = open(os.path.join("repro/in", f), "rb").read()
        print("corpus", local, sha(a), "| fresh", f, sha(b), "| identical", a == b)
