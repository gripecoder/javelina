import sys, re, os

DRMZ = r"%USERPROFILE%\Documents\maps\MountainDirectory\MountainDirectoryCombined.drmz"
BINS = [r"C:\Program Files (x86)\Javelin3\Javelin3.exe",
        r"C:\Program Files (x86)\Javelin3\DrumlinRast.dll",
        r"C:\Program Files (x86)\Javelin3\DCL.dll",
        r"C:\Program Files (x86)\Javelin3\CNT.dll",
        r"C:\Program Files (x86)\Javelin3\Brandll.dll"]

data = open(DRMZ, "rb").read()
print("size", len(data), hex(len(data)))
print("magic:", data[:8])
print("ver :", data[8:12].hex(), "| fld:", data[12:16].hex(), "=", int.from_bytes(data[12:16], "little"))
print("blob 16..32:", data[16:32].hex())
# exact layout around header
for i in range(32, 140):
    if data[i] != 0:
        print("first nonzero after 16:", hex(i))
        break
print("bytes 32..111:", data[32:112].hex())

start = 16
while start < len(data) and data[start] == 0:
    start += 1
ct = data[start:]
print("content start", hex(start), "content len", len(ct))
print("tail:", data[-64:].hex())

# known plaintext "%PDF-1.7" -> first 8 keystream bytes
key8 = bytes(a ^ b for a, b in zip(ct[:8], b"%PDF-1.7"))
print("key8:", key8.hex())

# search bins for key8 and for the magic
for b in BINS:
    if not os.path.exists(b):
        continue
    buf = open(b, "rb").read()
    hits = [m.start() for m in re.finditer(re.escape(key8), buf)]
    m1 = [m.start() for m in re.finditer(re.escape(b"{DRMPDK}"), buf)]
    m2 = [m.start() for m in re.finditer(re.escape(b".drmz"), buf)]
    sbox = bytes([0x63, 0x7C, 0x77, 0x7B, 0xF2, 0x6B, 0x6F, 0xC5])
    s = [m.start() for m in re.finditer(re.escape(sbox), buf)]
    print(os.path.basename(b), "key8 hits:", [hex(h) for h in hits],
          "| DRMPDK:", [hex(h) for h in m1],
          "| .drmz:", [hex(h) for h in m2],
          "| AES sbox:", [hex(h) for h in s])

# try period-8 decrypt, score printable
def decrypt(key, c):
    return bytes(c[i] ^ key[i % len(key)] for i in range(len(c)))

pt8 = decrypt(key8, ct)
score = lambda p: sum(1 for x in p if x in (9, 10, 13) or 32 <= x < 127) / len(p)
print("period-8 printable ratio:", round(score(pt8), 4))
print("head(period-8):", pt8[:48])
# keywords present with period 8?
for kw in [b"obj", b"endobj", b"stream", b"xref", b"trailer", b"%%EOF", b"/Type", b"startxref"]:
    n = pt8.count(kw)
    if n:
        print("kw", kw, "count", n)
