import struct, shutil, os

SRC_DIR = r"C:\Program Files (x86)\Javelin3"
DST_DIR = r"%USERPROFILE%\Documents\github\rea\mountainmaps\j3patched"
PATH = r"%USERPROFILE%\Documents\github\rea\mountainmaps\dump.bin"
STUB_VA = 0x10137000
WRITTEN_VA = 0x101373FC
PATH_VA = 0x10137400
ORIG_LOOP = 0x10008D0A

os.makedirs(DST_DIR, exist_ok=True)
for f in os.listdir(DST_DIR):
    p = os.path.join(DST_DIR, f)
    if os.path.isfile(p) and f.lower() != "drumlinrast.dll":
        os.remove(p)
for f in os.listdir(SRC_DIR):
    p = os.path.join(SRC_DIR, f)
    if f.lower() in ("unins000.exe", "unins000.dat") or os.path.isdir(p):
        continue
    shutil.copy2(p, os.path.join(DST_DIR, f))

buf = bytearray(open(os.path.join(DST_DIR, "DrumlinRast.dll"), "rb").read())

def rel(rel_field_va, dst_va):
    return struct.pack("<i", dst_va - (rel_field_va + 4))

def i32(v):
    return struct.pack("<I", v)

stub = bytearray()
stub += b"\x55"                                   # push ebp
stub += b"\x56"                                   # push esi
stub += b"\x57"                                   # push edi
stub += b"\x53"                                   # push ebx
stub += b"\x8B\x74\x24\x14"                       # mov esi,[esp+0x14] buf
stub += b"\x8B\x7C\x24\x18"                       # mov edi,[esp+0x18] len
stub += b"\x6A\x00"
stub += b"\x68\x80\x00\x00\x00"
stub += b"\x6A\x02"
stub += b"\x6A\x00"
stub += b"\x6A\x01"
stub += b"\x68\x00\x00\x00\x40"
stub += b"\x68" + i32(PATH_VA)
stub += b"\xFF\x15\x74\xC0\x0E\x10"               # call [CreateFileW]
stub += b"\x8B\xD8"                               # mov ebx,eax (hFile)
stub += b"\x6A\x00"
stub += b"\x68" + i32(WRITTEN_VA)
stub += b"\x6A\x04"
stub += b"\x8D\x44\x24\x24"                       # lea eax,[esp+0x24] -> &len
stub += b"\x50"
stub += b"\x53"                                   # push hFile
stub += b"\xFF\x15\x50\xC0\x0E\x10"               # call [WriteFile] (len header)
stub += b"\x6A\x00"
stub += b"\x68" + i32(WRITTEN_VA)
stub += b"\x57"                                   # push edi (len)
stub += b"\x56"                                   # push esi (buf)
stub += b"\x53"                                   # push hFile
stub += b"\xFF\x15\x50\xC0\x0E\x10"               # call [WriteFile] (data)
stub += b"\x53"
stub += b"\xFF\x15\xBC\xC0\x0E\x10"               # call [CloseHandle]
stub += b"\x5B"                                   # pop ebx
stub += b"\x5F"                                   # pop edi
stub += b"\x5E"                                   # pop esi
stub += b"\x5D"                                   # pop ebp
stub += b"\x31\xC0"                               # xor eax,eax (loop counter)
stub += b"\x8B\x54\x24\x08"                       # mov edx,[esp+8] len
stub += b"\xE9" + rel(STUB_VA + len(stub) + 1, ORIG_LOOP)
print("stub size:", len(stub))
off_stub = 0x134000 + (STUB_VA - 0x10137000)
buf[off_stub:off_stub + len(stub)] = stub

p = PATH.encode("utf-16-le") + b"\x00\x00"
off_path = 0x134000 + (PATH_VA - 0x10137000)
buf[off_path:off_path + len(p)] = p

entry = 0x8D00
buf[entry:entry + 5] = b"\xE9" + rel(0x10000000 + entry + 1, STUB_VA)

pe_off = struct.unpack_from("<I", buf, 0x3C)[0]
opt_off = pe_off + 24
nsec = struct.unpack_from("<H", buf, pe_off + 6)[0]
size_opt = struct.unpack_from("<H", buf, pe_off + 20)[0]
sec_off = opt_off + size_opt
if buf[sec_off:sec_off + 5] != b".text":
    sec_off = opt_off + 0xD4
for i in range(nsec):
    o = sec_off + i * 40
    name = buf[o:o + 8].rstrip(b"\0")
    if name == b".reloc":
        ch = struct.unpack_from("<I", buf, o + 36)[0]
        print(".reloc chars:", hex(ch), "->", hex((ch & ~0x02000000) | 0xA0000000))
        struct.pack_into("<I", buf, o + 36, (ch & ~0x02000000) | 0xA0000000)

open(os.path.join(DST_DIR, "DrumlinRast.dll"), "wb").write(buf)
print("patched DLL written, size", len(buf))
