import struct
buf = open(r"C:\Program Files (x86)\Javelin3\DrumlinRast.dll", "rb").read()
for name in (b"WriteFile\0", b"CloseHandle\0", b"CreateFileW\0", b"SetFilePointer\0", b"CreateFileA\0"):
    off = buf.find(name)
    print(name, "at", hex(off) if off >= 0 else None, "rva", hex(off) if off >= 0 else "")
# IAT region scan: dwords in 0xEC000..0xEC300 that equal each name rva
for name in (b"WriteFile\0", b"CloseHandle\0", b"CreateFileW\0"):
    off = buf.find(name)
    if off < 0:
        continue
    hits = []
    for i in range(0xEC000, 0xEC400, 4):
        if struct.unpack_from("<I", buf, i)[0] == off - 2:
            hits.append(i)
    print(name.decode(), "IAT slots:", [hex(h) for h in hits])
