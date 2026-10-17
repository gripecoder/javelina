import sys, re

def stats(path, label):
    b = open(path, "rb").read()
    print("==", label, len(b))
    for kw in [b"obj", b"endobj", b"stream", b"endstream", b"xref", b"trailer", b"startxref", b"%%EOF", b"/Type"]:
        print("   %-10s %d" % (kw.decode(), b.count(kw)))
    print("   head64 :", b[:64])
    # printable ratio per 4KB window, first 8 windows
    for i in range(0, min(len(b), 32768), 4096):
        w = b[i:i + 4096]
        r = sum(1 for x in w if x in (9, 10, 13) or 32 <= x < 127) / len(w)
        print("   win %5d printable %.3f  first %r" % (i, r, w[:24]))

stats(sys.argv[1], sys.argv[2] if len(sys.argv) > 2 else sys.argv[1])
