import struct, re

def dump_pe(path):
    buf = open(path, "rb").read()
    pe_off = struct.unpack_from("<I", buf, 0x3C)[0]
    nsec = struct.unpack_from("<H", buf, pe_off + 6)[0]
    opt_off = pe_off + 24
    magic = struct.unpack_from("<H", buf, opt_off)[0]
    is64 = magic == 0x20B
    size_opt = struct.unpack_from("<H", buf, opt_off)[0]
    sec_off = opt_off + size_opt
    print("====", path.split("\\")[-1], "pe32+" if is64 else "pe32")
    img_base = struct.unpack_from("<I" if not is64 else "<Q", buf, opt_off + 28)[0]
    print("ImageBase", hex(img_base))
    for i in range(nsec):
        o = sec_off + i * 40
        name = buf[o:o+8].rstrip(b"\0").decode("latin1")
        name = "".join(c if 32 <= ord(c) < 127 else "?" for c in name)
        vsize, vaddr, rsize, rptr = struct.unpack_from("<IIII", buf, o + 8)
        print(f"  {name:8s} VA {img_base+vaddr:08X} vsize {vsize:8X} raw {rsize:8X} @ {rptr:8X}")
    # exports
    dd_off = opt_off + (112 if is64 else 96)
    exp_rva, exp_size = struct.unpack_from("<II", buf, dd_off)
    imp_rva, imp_size = struct.unpack_from("<II", buf, dd_off + 8)
    print("exports rva", hex(exp_rva), "imports rva", hex(imp_rva))
    # ascii strings
    print("--- ascii strings ---")
    for m in re.finditer(rb"[ -~]{6,}", buf):
        s = m.group().decode("latin1")
        if re.search(r"rijndael|aes|crypt|key|decrypt|encrypt|DRMPDK|drmz|drmx|javelin|password|IV", s, re.I):
            print(hex(m.start()), s[:100])
    print("--- utf16 strings ---")
    for m in re.finditer(rb"(?:[\x20-\x7e]\x00){5,}", buf):
        s = m.group().decode("utf-16-le")
        if re.search(r"rijndael|aes|crypt|key|decrypt|encrypt|DRMPDK|drmz|drmx|javelin|password", s, re.I):
            print(hex(m.start()), s[:100])
    return buf, img_base

dump_pe(r"C:\Program Files (x86)\Javelin3\CNT.dll")
print()
dump_pe(r"C:\Program Files (x86)\Javelin3\DrumlinRast.dll")
