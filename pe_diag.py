import struct

for path in [r"C:\Program Files (x86)\Javelin3\DrumlinRast.dll",
             r"C:\Program Files (x86)\Javelin3\CNT.dll"]:
    buf = open(path, "rb").read()
    pe_off = struct.unpack_from("<I", buf, 0x3C)[0]
    print("====", path.split("\\")[-1], "e_lfanew", hex(pe_off), "sig", buf[pe_off:pe_off+4])
    opt_off = pe_off + 24
    magic = struct.unpack_from("<H", buf, opt_off)[0]
    size_opt = struct.unpack_from("<H", buf, opt_off + 16)[0]
    nsec = struct.unpack_from("<H", buf, pe_off + 6)[0]
    print("magic", hex(magic), "size_opt", hex(size_opt), "nsec", nsec)
    print("opt header first 64:", buf[opt_off:opt_off+64].hex())
    # imagebase
    ib = struct.unpack_from("<I", buf, opt_off + 28)[0]
    print("imagebase", hex(ib))
    # try standard sec table at opt_off+size_opt
    for cand_off in (opt_off + size_opt, opt_off + 0xE0, opt_off + 0xF0):
        name = buf[cand_off:cand_off+8]
        print(f"  sec@{cand_off:X}: name={name!r}")
