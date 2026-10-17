import ctypes, sys, struct

base = int(open(r"%USERPROFILE%\Documents\github\rea\mountainmaps\base.txt").read().strip(), 16)
PROCESS_VM_READ = 0x10
PROCESS_QUERY_INFORMATION = 0x400

k32 = ctypes.WinDLL("kernel32", use_last_error=True)

class PROCESSENTRY32(ctypes.Structure):
    _fields_ = [("dwSize", ctypes.c_ulong),
                ("cntUsage", ctypes.c_ulong),
                ("th32ProcessID", ctypes.c_ulong),
                ("th32DefaultHeapID", ctypes.POINTER(ctypes.c_ulong)),
                ("th32ModuleID", ctypes.c_ulong),
                ("cntThreads", ctypes.c_ulong),
                ("th32ParentProcessID", ctypes.c_ulong),
                ("pcPriClassBase", ctypes.c_long),
                ("dwFlags", ctypes.c_ulong),
                ("szExeFile", ctypes.c_char * 260)]

snap = k32.CreateToolhelp32Snapshot(0x2, 0)
pe = PROCESSENTRY32()
pe.dwSize = ctypes.sizeof(PROCESSENTRY32)
pid = 0
if k32.Process32First(snap, ctypes.byref(pe)):
    while True:
        if pe.szExeFile.lower() == b"javelin3.exe":
            pid = pe.th32ProcessID
        if not k32.Process32Next(snap, ctypes.byref(pe)):
            break
k32.CloseHandle(snap)
print("pid", pid)
if not pid:
    sys.exit("no Javelin3.exe")

h = k32.OpenProcess(PROCESS_QUERY_INFORMATION | PROCESS_VM_READ, False, pid)
print("handle", h)
if not h:
    sys.exit(f"OpenProcess failed {ctypes.get_last_error()}")

SLOT = base + 0xEBCE0
buf = ctypes.create_string_buffer(8)
n = ctypes.c_size_t()
ok = k32.ReadProcessMemory(h, ctypes.c_void_p(SLOT), buf, 8, ctypes.byref(n))
if not ok:
    sys.exit(f"read slot failed {ctypes.get_last_error()}")
ptr, ln = struct.unpack("<II", buf.raw)
print(f"captured ptr=0x{ptr:08X} len={ln}")

if ln == 0 or ln > 0x10000000:
    sys.exit("bad len - reopen doc first")

out = open(r"%USERPROFILE%\Documents\github\rea\mountainmaps\dump2.bin", "wb")
out.write(struct.pack("<I", ln))
CH = 0x100000
off = 0
b = ctypes.create_string_buffer(CH)
while off < ln:
    cur = min(CH, ln - off)
    ok = k32.ReadProcessMemory(h, ctypes.c_void_p(ptr + off), b, cur, ctypes.byref(n))
    if not ok or n.value == 0:
        print(f"read stop at {off} err={ctypes.get_last_error()}")
        break
    out.write(b.raw[:n.value])
    off += n.value
out.close()
k32.CloseHandle(h)
print("dumped", off, "bytes")
