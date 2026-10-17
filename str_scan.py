import re

def utf16_strings(path, minlen=4):
    buf = open(path, "rb").read()
    out = []
    for m in re.finditer(rb"(?:[\x20-\x7e]\x00){%d,}" % minlen, buf):
        s = m.group().decode("utf-16-le")
        out.append((m.start(), s))
    return out

for p in [r"C:\Program Files (x86)\Javelin3\DCL.dll",
          r"C:\Program Files (x86)\Javelin3\Javelin3.exe",
          r"C:\Program Files (x86)\Javelin3\DrumlinRast.dll",
          r"C:\Program Files (x86)\Javelin3\CNT.dll"]:
    print("=====", p.split("\\")[-1])
    for off, s in utf16_strings(p):
        if re.search(r"DRMPDK|drmz|drmx|PDK|keycode|KeyCode|%PDF|USK|UserKey|DocKey|EncryptionType|\.lic|licenc|authori|regcode|unlock", s, re.I):
            print(hex(off), repr(s[:120]))
