import struct

def parse_exports(path):
    buf = open(path, "rb").read()
    pe_off = struct.unpack_from("<I", buf, 0x3C)[0]
    opt_off = pe_off + 24
    magic = struct.unpack_from("<H", buf, opt_off)[0]
    is64 = magic == 0x20B
    dd_off = opt_off + (112 if is64 else 96)
    exp_rva, exp_size = struct.unpack_from("<II", buf, dd_off)
    nsec = struct.unpack_from("<H", buf, pe_off + 6)[0]
    size_opt = struct.unpack_from("<H", buf, pe_off + 20)[0]
    sec_off = opt_off + size_opt
    if buf[sec_off:sec_off+5] != b".text":
        sec_off = opt_off + 0xD4  # empirical for these packed binaries
        if buf[sec_off:sec_off+5] != b".text":
            print("WARN: no .text at expected sec table");
    img_base = struct.unpack_from("<I" if not is64 else "<Q", buf, opt_off + 28)[0]
    secs = []
    for i in range(nsec):
        o = sec_off + i * 40
        name = "".join(chr(c) if 32 <= c < 127 else "?" for c in buf[o:o+8]).rstrip("\0").rstrip("?")
        vsize, vaddr, rsize, rptr = struct.unpack_from("<IIII", buf, o + 8)
        print(f"  sec {name!r} VA {img_base+vaddr:08X} vsize {vsize:06X} raw {rsize:06X} @ {rptr:06X}")
        secs.append((vaddr, vsize, rptr, rsize))
    for i in range(16):
        rva, sz = struct.unpack_from("<II", buf, dd_off + i * 8)
        if rva or sz:
            print(f"  dd[{i}] rva {rva:08X} size {sz:08X}")
    def rva2off(rva):
        for vaddr, vsize, rptr, rsize in secs:
            if vaddr <= rva < vaddr + max(vsize, rsize):
                return rptr + (rva - vaddr)
        return None
    off = rva2off(exp_rva)
    if off is None:
        print("no exports"); return
    n_funcs, n_names = struct.unpack_from("<II", buf, off + 20)[0], struct.unpack_from("<II", buf, off + 24)[0]
    ord_base = struct.unpack_from("<I", buf, off + 16)[0]
    funcs_rva, names_rva, ords_rva = struct.unpack_from("<III", buf, off + 28)
    names_off, funcs_off, ords_off = rva2off(names_rva), rva2off(funcs_rva), rva2off(ords_rva)
    print(f"exports: {n_funcs} funcs, {n_names} names, ordinal base {ord_base}")
    print(f"  funcs_rva {funcs_rva:X} -> {funcs_off:X}, names_rva {names_rva:X} -> {names_off:X}, ords_rva {ords_rva:X} -> {ords_off:X}")
    # sample first ords entries
    print("  first ords:", [struct.unpack_from("<H", buf, ords_off + i * 2)[0] for i in range(8)])
    for i in range(n_names):
        nrva = struct.unpack_from("<I", buf, names_off + i * 4)[0]
        noff = rva2off(nrva)
        name = buf[noff:buf.index(b"\0", noff)].decode("latin1")
        ordi = struct.unpack_from("<H", buf, ords_off + i * 2)[0]
        frva = struct.unpack_from("<I", buf, funcs_off + (ordi - ord_base) * 4)[0]
        print(f"  ord {ordi:4d} rva {frva:08X}  {name}")

parse_exports(r"C:\Program Files (x86)\Javelin3\DrumlinRast.dll")
print()
parse_exports(r"C:\Program Files (x86)\Javelin3\CNT.dll")
