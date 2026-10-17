import struct

buf = open(r"C:\Program Files (x86)\Javelin3\DrumlinRast.dll", "rb").read()
IMG = 0x10000000

def find_dword(b, val):
    pat = struct.pack("<I", val)
    out = []
    start = 0
    while True:
        i = b.find(pat, start)
        if i < 0:
            break
        out.append(i)
        start = i + 1
    return out

targets = {
    "sbox1": 0x100F06E8,
    "sbox2": 0x10114A48,
    "key_static(key0)": 0x1012EFC0,
    "iv_static(iv0)": 0x1012F020,
    "ivUSK_static": 0x10133F30,
    "keyUSK_static": 0x10133F10,
    "m_bPreparedIV": 0x10133E0D,
    "m_bPreparedKey": 0x10133E0C,
    "cFiler_key1": 0x1012F0C0,
    "cFiler_key2": 0x1012EFE0,
}
for name, va in targets.items():
    hits = find_dword(buf, va)
    print(name, hex(va), "xrefs:", [hex(h) for h in hits])
