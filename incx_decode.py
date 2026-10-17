import sys
b = open(r"C:\Program Files (x86)\Javelin3\javelin.incx", "rb").read()
# try single-byte XOR keys and score printable
best = []
for k in range(256):
    d = bytes(x ^ k for x in b)
    score = sum(1 for c in d if 32 <= c < 127 or c in (9, 10, 13))
    best.append((score, k))
best.sort(reverse=True)
for score, k in best[:6]:
    d = bytes(x ^ k for x in b)
    print(f"key {k:02X} score {score}: {d[:120]!r}")
