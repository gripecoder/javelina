import sys, os
sys.path.insert(0, r"%USERPROFILE%\Documents\github\rea\mountainmaps\py")
from capstone import Cs, CS_ARCH_X86, CS_MODE_32

buf = open(r"C:\Program Files (x86)\Javelin3\DrumlinRast.dll", "rb").read()
md = Cs(CS_ARCH_X86, CS_MODE_32)
md.detail = False

def dis(lo, hi, label):
    print(f"\n===== {label}  0x{lo:X}-0x{hi:X} =====")
    for ins in md.disasm(buf[lo:hi], 0x10000000 + lo):
        print(f"  {ins.address:08X}  {ins.bytes.hex():16}  {ins.mnemonic} {ins.op_str}")

if __name__ == "__main__":
    import argparse
    ap = argparse.ArgumentParser()
    ap.add_argument("lo", type=lambda x: int(x, 16))
    ap.add_argument("hi", type=lambda x: int(x, 16))
    ap.add_argument("label")
    a = ap.parse_args()
    dis(a.lo, a.hi, a.label)
