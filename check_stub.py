import sys
sys.path.insert(0, r"%USERPROFILE%\Documents\github\rea\mountainmaps\py")
from capstone import Cs, CS_ARCH_X86, CS_MODE_32

buf = open(r"%USERPROFILE%\Documents\github\rea\mountainmaps\j3patched\DrumlinRast.dll", "rb").read()
md = Cs(CS_ARCH_X86, CS_MODE_32)
print("=== entry 0x8D00 ===")
for ins in md.disasm(buf[0x8D00:0x8D20], 0x10008D00):
    print(f"  {ins.address:08X}  {ins.bytes.hex():16}  {ins.mnemonic} {ins.op_str}")
print("=== stub 0x134000 ===")
for ins in md.disasm(buf[0x134000:0x134060], 0x10137000):
    print(f"  {ins.address:08X}  {ins.bytes.hex():16}  {ins.mnemonic} {ins.op_str}")
