import struct, re
buf = open(r"C:\Program Files (x86)\Javelin3\DrumlinRast.dll", "rb").read()
IMG = 0x10000000

def u16(s):
    return s.encode("utf-16-le")

def xrefs(pat):
    hits, start = [], 0
    while True:
        i = buf.find(pat, start)
        if i < 0:
            break
        hits.append(i)
        start = i + 1
    out = []
    for loc in hits:
        va = IMG + loc
        patb = struct.pack("<I", va)
        for j in range(len(buf) - 3):
            if buf[j:j+4] == patb:
                out.append((loc, j))
    return hits, out

for name, pat in [("AskPassword", u16("AskPassword")), ("MustBeOnline", u16("MustBeOnline")),
                  ("EnableClipboard", u16("EnableClipboard")), ("regcode", u16("regcode")),
                  ("keycode", u16("keycode")), ("Authorize", u16("Authorize")),
                  ("authoriz", u16("authoriz")), ("activation", u16("activation")),
                  ("online", u16("online")), ("password", u16("password"))]:
    hits, xr = xrefs(pat)
    print(name, "str at", [hex(h) for h in hits], "| xrefs (code):", [hex(x) for _, x in xr][:12])
