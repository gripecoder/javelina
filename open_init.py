import sys, subprocess, re
sys.path.insert(0, r"%USERPROFILE%\Documents\github\rea\mountainmaps\py")
from capstone import Cs, CS_ARCH_X86, CS_MODE_32

buf = open(r"C:\Program Files (x86)\Javelin3\DrumlinRast.dll", "rb").read()
md = Cs(CS_ARCH_X86, CS_MODE_32)

lo, hi = 0x1B9B0, 0x1CB00
lines = []
for ins in md.disasm(buf[lo:hi], 0x10000000 + lo):
    op = ins.op_str
    # highlight references to key statics and crypto calls
    mark = ""
    for va in (0x1012EFC0, 0x1012EFE0, 0x1012F000, 0x1012F020, 0x1012F040, 0x1012F060,
               0x1012F080, 0x1012F0A0, 0x1012F0C0, 0x1012F0E0, 0x10133F10, 0x10133F30,
               0x10114A48, 0x100F06E8):
        if hex(va) in op or (ins.mnemonic in ("call", "jmp") and hex(va).endswith(op.replace("0x", "").strip())):
            mark = f"  <== ref {hex(va)}"
    tgt = ""
    if ins.mnemonic == "call" and op.startswith("0x"):
        tgt = f"  [-> {op}]"
    line = f"{ins.address:08X}  {ins.bytes.hex():14}  {ins.mnemonic} {op}"
    if mark or tgt or ins.mnemonic in ("call",):
        lines.append(line + tgt + mark)

out = "\n".join(lines)
open(r"%USERPROFILE%\Documents\github\rea\mountainmaps\open_init.txt", "w").write(out)
print(len(lines), "lines written")
# print the key-static refs and calls only
for l in lines:
    if "<== ref" in l or "[-> 0x1000b" in l or "[-> 0x10008" in l or "[-> 0x10007" in l:
        print(l)
