import re
buf = open(r"C:\Program Files (x86)\Javelin3\DrumlinRast.dll", "rb").read()

def u16(off, n=80):
    return buf[off:off+n].decode("utf-16-le", errors="replace").replace("\x00", " ")

locs = {
    0xEF6DC: "UnableToDecrypt", 0xEF714: "LoadDocFail", 0xEF94C: "AskPassword",
    0xEFBD8: "CEX_a1null", 0xEFC00: "CreateExeFail", 0xEFC28: "CreateFileInFail",
    0xEFC78: "OpenFail", 0xEFCBC: "CannotEncrypt", 0xEFCF0: "CreateOutFail",
    0xEFD48: "WriteFail", 0xEFDA8: "WriteFail2", 0xEFE0C: "AddValueFail",
    0xEFE48: "WriteFail3", 0xEFEA0: "Done?"
}
for off, name in locs.items():
    print(f"{name:20s} @ {off:X}: {u16(off)!r}")
