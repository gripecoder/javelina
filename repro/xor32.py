"""Javelin3 .drmz decryptor, reconstructed and verified 2026-10-17.

Layout: 8-byte magic {DRMPDK}, u32 version, u32 header length at offset 12;
PDF payload starts exactly at the header length. Payload is XORed with a
32-byte repeating keystream: two constant 16-byte blocks alternated.
"""
import os
import sys

KEY = bytes.fromhex("DEDAFF1FFDEDBDDCD80DCDDEDD011111" "51ACAFD1171119F184F724B548434219")


def ks_stream(n):
    return (KEY * (n // 32 + 2))[:n]


def decrypt(path):
    with open(path, "rb") as f:
        d = f.read()
    if d[:8] != b"{DRMPDK}":
        raise ValueError("not a DRMZ file: magic %r" % d[:8])
    start = int.from_bytes(d[12:16], "little")
    ct = d[start:]
    ks = ks_stream(len(ct))
    return bytes(a ^ b for a, b in zip(ct, ks)), start


def check(path, deep=False):
    pt, start = decrypt(path)
    r = {"file": os.path.basename(path), "hdr": start, "payload": len(pt), "head": pt[:8].decode("latin1")}
    r["head_ok"] = pt.startswith(b"%PDF-1.")
    r["eof"] = b"%%EOF" in pt[-1024:]
    r["startxref"] = b"startxref" in pt[-2048:]
    r["xref"] = b"\nxref" in pt[-65536:] or b"\r\nxref" in pt[-65536:]
    r["obj"] = pt.count(b" endobj")
    if deep:
        import pypdf
        try:
            rd = pypdf.PdfReader(__import__("io").BytesIO(pt), strict=False)
            r["pages"] = len(rd.pages)
            r["page1"] = " ".join((rd.pages[0].extract_text() or "").split())[:90]
        except Exception as e:
            r["pages"] = "FAIL %s: %s" % (type(e).__name__, str(e)[:90])
    return r


def main(argv=None):
    import argparse

    ap = argparse.ArgumentParser(
        prog="xor32.py",
        description="Inspect Javelin3 .drmz files: report header length, payload size, "
                    "PDF head, %%EOF/startxref presence and page count via pypdf. "
                    "With -o, also write each decrypted PDF into the given directory.",
    )
    ap.add_argument("files", nargs="+", metavar="DRMZ", help="one or more .drmz / .DRMZ files")
    ap.add_argument("-q", "--quiet", action="store_true", help="one line per file, no pypdf page text")
    ap.add_argument("-o", "--out", metavar="DIR", help="also write each decrypted PDF into DIR")
    a = ap.parse_args(argv)

    rc = 0
    for p in a.files:
        try:
            r = check(p, deep=not a.quiet)
            if a.out:
                pt, _ = decrypt(p)
                name = os.path.splitext(os.path.basename(p))[0] + ".pdf"
                with open(os.path.join(a.out, name), "wb") as f:
                    f.write(pt)
        except Exception as e:
            print("%s: %s: %s" % (p, type(e).__name__, e))
            rc = 1
            continue
        if a.quiet:
            print("%-46s hdr=%-5d payload=%-9d %s eof=%s startxref=%s" % (
                r["file"], r["hdr"], r["payload"], r["head"][:8], r["eof"], r["startxref"]))
        else:
            print(r)
    return rc


if __name__ == "__main__":
    sys.exit(main())
