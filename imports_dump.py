import struct, sys
sys.path.insert(0, r"%USERPROFILE%\Documents\github\rea\mountainmaps\py")

buf = bytearray(open(r"C:\Program Files (x86)\Javelin3\DrumlinRast.dll", "rb").read())
pe_off = struct.unpack_from("<I", buf, 0x3C)[0]
opt_off = pe_off + 24
nsec = struct.unpack_from("<H", buf, pe_off + 6)[0]
size_opt = struct.unpack_from("<H", buf, pe_off + 20)[0]
sec_off = opt_off + size_opt
if buf[sec_off:sec_off+5] != b".text":
    sec_off = opt_off + 0xD4
secs = []
for i in range(nsec):
    o = sec_off + i * 40
    vsize, vaddr, rsize, rptr = struct.unpack_from("<IIII", buf, o + 8)
    secs.append((vaddr, vsize, rptr, rsize))
def rva2off(rva):
    for vaddr, vsize, rptr, rsize in secs:
        if vaddr <= rva < vaddr + max(vsize, rsize):
            return rptr + (rva - vaddr)
    return None
dd_off = opt_off + 96
imp_rva = struct.unpack_from("<I", buf, dd_off + 8)[0]
print("imp_rva", hex(imp_rva))
imp_off = rva2off(imp_rva)
found = {}
entry_off = imp_off
while True:
    oft_rva, name_rva, ft_rva = struct.unpack_from("<III", buf, entry_off + 0), struct.unpack_from("<I", buf, entry_off + 12)[0], struct.unpack_from("<I", buf, entry_off + 16)[0]
    if oft_rva == 0 and name_rva == 0:
        break
    dllname = buf[rva2off(name_rva):].split(b"\0")[0].decode()
    thunk = ft_rva if ft_rva else oft_rva
    t_off = rva2off(thunk)
    i = 0
    while True:
        val = struct.unpack_from("<I", buf, t_off + i * 4)[0]
        if val == 0:
            break
        if not (val & 0x80000000):
            name = buf[rva2off(val) + 2:].split(b"\0")[0].decode()
            found.setdefault(name, []).append(thunk + i * 4)
        i += 1
    entry_off += 20
for n in ("CreateFileW", "WriteFile", "CloseHandle", "CreateFileA", "SetFilePointer"):
    print(n, ":", [hex(x) for x in found.get(n, [])])
