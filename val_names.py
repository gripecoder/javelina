buf = open(r"C:\Program Files (x86)\Javelin3\DrumlinRast.dll", "rb").read()
for off in (0xEF7F8, 0xEF800, 0xEF810, 0xEF830, 0xEF840, 0xEF850):
    print(hex(off), repr(buf[off:off+64].decode("utf-16-le", errors="replace").replace("\x00", " ")))
