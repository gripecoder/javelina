import math, re
b = open(r"C:\Program Files (x86)\Javelin3\javelin.incx", "rb").read()
print("size", len(b))
pat = bytes([0x12, 0x21, 0x23, 0x15])
pos = [m.start() for m in re.finditer(re.escape(pat), b)]
print("pattern at:", pos[:12])
diffs = [pos[i+1]-pos[i] for i in range(len(pos)-1)]
print("diffs:", diffs[:12])
g = 0
for d in diffs:
    g = math.gcd(g, d)
print("gcd:", g)
# try key length = g, XOR with the pattern=spaces assumption
for spacekey in (0x20, 0x00):
    k = bytes(x ^ spacekey for x in pat)
    print("key candidate:", k.hex())
    d = bytes(b[i] ^ k[i % len(k)] for i in range(len(b)))
    print(repr(d[:160]))
    print("---")
