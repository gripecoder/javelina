import sys
sys.path.insert(0, r"%USERPROFILE%\Documents\github\rea\mountainmaps\py")
import struct

buf = open(r"C:\Program Files (x86)\Javelin3\DrumlinRast.dll", "rb").read()
IMG = 0x10000000

def find_dword(b, val):
    pat = struct.pack("<I", val)
    out, start = [], 0
    while True:
        i = b.find(pat, start)
        if i < 0:
            break
        out.append(i)
        start = i + 1
    return out

# UTF-16LE strings -> their byte representations to xref
def utf16le(s):
    return s.encode("utf-16-le")

targets = {
    "str_UnableToDecrypt": utf16le("Unable to decrypt Document!"),
    "str_AskPassword": utf16le("AskPassword"),
    "str_CannotEncrypt": utf16le("Cannot encrypt the file"),
    "str_DRMPDK": b"{DRMPDK}",
    "str_EmptyKey": b"Empty key",
    "str_IncorrectKeyLen": b"Incorrect key length",
}
for name, pat in targets.items():
    hits = []
    start = 0
    while True:
        i = buf.find(pat, start)
        if i < 0:
            break
        hits.append(i)
        start = i + 1
    print(name, "at:", [hex(h) for h in hits])
    # xrefs to each location
    for loc in hits:
        va = IMG + loc
        print("   xrefs to", hex(va), ":", [hex(x) for x in find_dword(buf, va)])

# ascii strings around the DRMPDK site
print("\n--- strings 0xEFB00-0xEFC40 ---")
for m in __import__("re").finditer(rb"[ -~]{4,}", buf[0xEFB00:0xEFC40]):
    print(hex(0xEFB00 + m.start()), m.group().decode("latin1"))
print("\n--- utf16 strings 0xEF000-0xF0000 ---")
for m in __import__("re").finditer(rb"(?:[\x20-\x7e]\x00){4,}", buf[0xEF000:0xF0000]):
    print(hex(0xEF000 + m.start()), repr(m.group().decode("utf-16-le")))
