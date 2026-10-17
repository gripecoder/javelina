import os, sys, time

KEY = bytes.fromhex("DEDAFF1FFDEDBDDCD80DCDDEDD011111")
KEY32 = bytes.fromhex("DEDAFF1FFDEDBDDCD80DCDDEDD011111") * 2


def decrypt(src, dst):
    t0 = time.time()
    with open(src, "rb") as f:
        h = f.read(16)
        if h[:8] != b"{DRMPDK}":
            raise SystemExit("not a drmz: magic %r" % h[:8])
        start = int.from_bytes(h[12:16], "little")
        f.seek(start)
        ct = f.read()
    n = len(ct)
    ks = (KEY32 * (n // 32 + 1))[:n]
    pt = bytes(a ^ b for a, b in zip(ct, ks)) if n <= 20_000_000 else None
    if pt is None:
        out = bytearray(ct)
        for i in range(n):
            out[i] ^= KEY[i & 15]
        pt = bytes(out)
    with open(dst, "wb") as f:
        f.write(pt)
    return start, n, pt, time.time() - t0


def validate(path, pt):
    res = {}
    res["head"] = pt[:15]
    res["has_eof"] = b"%%EOF" in pt[-2048:]
    res["xref"] = b"startxref" in pt[-4096:]
    try:
        import pypdf
        r = pypdf.PdfReader(path, strict=False)
        res["pages"] = len(r.pages)
        res["encrypted"] = r.is_encrypted
        txt = r.pages[0].extract_text() or ""
        res["page1_text"] = " ".join(txt.split())[:160]
    except Exception as e:
        res["pages"] = "FAIL %s: %s" % (type(e).__name__, str(e)[:120])
    return res


if __name__ == "__main__":
    src = sys.argv[1]
    dst = sys.argv[2]
    start, n, pt, secs = decrypt(src, dst)
    v = validate(dst, pt)
    print("src      :", os.path.basename(src), "hdr", start, "payload", n)
    print("decrypted:", os.path.basename(dst), len(pt), "in %.1fs" % secs)
    print("head     :", v["head"])
    print("%%EOF+xref:", v["has_eof"], v["xref"])
    print("pages    :", v["pages"], "| encrypted:", v.get("encrypted"))
    print("page1    :", v.get("page1_text"))
