buf = open(r"C:\Program Files (x86)\Javelin3\DrumlinRast.dll", "rb").read()
# .text: rva 0x1000..0xEC000 (raw same)
best = []
i = 0x1000
run_start = None
while i < 0xF0000:
    if buf[i] == 0xCC:
        if run_start is None:
            run_start = i
    else:
        if run_start is not None and i - run_start >= 40:
            best.append((run_start, i - run_start))
        run_start = None
    i += 1
print("caves >= 40 CC bytes:", [(hex(a), n) for a, n in best][:15])

