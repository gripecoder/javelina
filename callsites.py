import struct, sys
sys.path.insert(0, r"%USERPROFILE%\Documents\github\rea\mountainmaps\py")
buf = open(r"C:\Program Files (x86)\Javelin3\DrumlinRast.dll", "rb").read()

def find_call_sites(target_rva):
    """find 'call rel32' instructions targeting target_rva"""
    out = []
    for i in range(0, len(buf) - 5):
        if buf[i] == 0xE8:
            rel = struct.unpack_from("<i", buf, i + 1)[0]
            if i + 5 + rel == target_rva:
                out.append(i)
    return out

for name, rva in [("KeyScramble_B010", 0xB010), ("IvScramble_B0A0", 0xB0A0),
                  ("Mask_AF50", 0xAF50), ("StreamCtor_BAE0", 0xBAE0),
                  ("StreamRead_BA50", 0xBA50), ("KeyFn_B130", 0xB130),
                  ("ScrambleBuffer_8D00", 0x8D00), ("LoadDocument_7DE0", 0x7DE0),
                  ("ReadHeader_8100", 0x8100), ("LoadHeader_7FC0", 0x7FC0)]:
    sites = find_call_sites(rva)
    print(f"{name} @ {rva:X}: called from {[hex(s) for s in sites]}")

# also dump the RCON table at 0x101135BC
off = 0x1135BC
print("rcon-ish @1135BC:", buf[off:off+64].hex())
# T-tables at 0x100F28E8 etc
print("Te@F28E8:", buf[0xF28E8:0xF28E8+16].hex())
print("Te@F2CE8:", buf[0xF2CE8:0xF2CE8+16].hex())
print("Te@F30E8:", buf[0xF30E8:0xF30E8+16].hex())
print("Te@F34E8:", buf[0xF34E8:0xF34E8+16].hex())
