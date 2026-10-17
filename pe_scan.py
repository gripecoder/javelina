import struct, os, hashlib, re

def pe_info(path):
    buf = open(path, "rb").read()
    if buf[:2] != b"MZ":
        return "not PE"
    pe_off = struct.unpack_from("<I", buf, 0x3C)[0]
    if buf[pe_off:pe_off+4] != b"PE\0\0":
        return "bad PE"
    machine = struct.unpack_from("<H", buf, pe_off+4)[0]
    nsec = struct.unpack_from("<H", buf, pe_off+6)[0]
    opt_off = pe_off + 24
    magic = struct.unpack_from("<H", buf, opt_off)[0]
    dd_off = opt_off + (96 if magic == 0x20b else 112)
    ndd = struct.unpack_from("<I", buf, opt_off + (108 if magic == 0x20b else 92))[0]
    com = None
    if ndd > 14:
        com_rva, com_size = struct.unpack_from("<II", buf, dd_off + 14*8)
        com = (com_rva, com_size)
    imp = struct.unpack_from("<II", buf, dd_off + 1*8)
    exp = struct.unpack_from("<II", buf, dd_off + 0*8)
    reloc = struct.unpack_from("<II", buf, dd_off + 5*8)
    print(os.path.basename(path), "machine", hex(machine), "sections", nsec,
          "pe32+" if magic == 0x20b else "pe32",
          "| COM(CLR):", com, "| imports:", imp, "| exports:", exp, "| reloc:", reloc)
    print("  mscoree string:", b"mscoree" in buf.lower())

for p in [r"C:\Program Files (x86)\Javelin3\Javelin3.exe",
          r"C:\Program Files (x86)\Javelin3\DrumlinRast.dll",
          r"C:\Program Files (x86)\Javelin3\CNT.dll",
          r"C:\Program Files (x86)\Javelin3\DCL.dll",
          r"C:\Program Files (x86)\Javelin3\Brandll.dll"]:
    pe_info(p)

# crypto api strings across binaries
for p in [r"C:\Program Files (x86)\Javelin3\Javelin3.exe",
          r"C:\Program Files (x86)\Javelin3\DrumlinRast.dll",
          r"C:\Program Files (x86)\Javelin3\CNT.dll",
          r"C:\Program Files (x86)\Javelin3\DCL.dll"]:
    buf = open(p, "rb").read()
    found = []
    for s in [b"CryptDecrypt", b"CryptEncrypt", b"CryptAcquireContext", b"BCryptDecrypt",
              b"BCryptEncrypt", b"System.Security.Cryptography", b"Rijndael", b"AES",
              b"aes_", b"rijndael", b"EVPCipher", b"evp_"]:
        if s in buf:
            found.append(s.decode())
    print(os.path.basename(p), "crypto strings:", found)

# compare the two copies of the drmz
a = r"%USERPROFILE%\Documents\maps\MountainDirectory\MountainDirectoryCombined.drmz"
b = r"%USERPROFILE%\Documents\dump\MountainDirectoryCombined.drmz"
da = open(a, "rb").read()
db = open(b, "rb").read()
print("copies identical:", da == db, "sizes:", len(da), len(db))
if da != db:
    for i, (x, y) in enumerate(zip(da, db)):
        if x != y:
            print("first diff at", hex(i)); break
