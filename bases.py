import struct
for p in [r"C:\Program Files (x86)\Javelin3\DrumlinRast.dll",
          r"C:\Program Files (x86)\Javelin3\CNT.dll",
          r"C:\Program Files (x86)\Javelin3\DCL.dll",
          r"C:\Program Files (x86)\Javelin3\Brandll.dll",
          r"C:\Program Files (x86)\Javelin3\Javelin3.exe"]:
    buf = open(p, "rb").read()
    pe = struct.unpack_from("<I", buf, 0x3C)[0]
    opt = pe + 24
    magic = struct.unpack_from("<H", buf, opt)[0]
    ib = struct.unpack_from("<I", buf, opt + 28)[0]
    dllch = struct.unpack_from("<H", buf, opt + 70)[0]
    print(f"{p.split(chr(92))[-1]:20s} magic {magic:04X} ImageBase {ib:08X} DllChars {dllch:04X} (DYNAMIC_BASE={bool(dllch & 0x40)})")
