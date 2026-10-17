import json, re

rows = json.load(open("repro/corpus.json", encoding="utf-8"))
more = json.load(open("repro/corpus_more.json", encoding="utf-8"))


def desc(r):
    f = r["file"]
    for c in more.get(f, []):
        t = c.split(": ", 1)[1] if ": " in c else c
        if len(t) > 10:
            return t
    return (r["title"] or r["snippet"]).strip()


GROUPS = [
    ("Journal — Marshall Islands Journal (weekly)", r"^MIJournal"),
    ("Aviation maintenance (EASA B1/B2 modules)", r"^(M\d\d|acag)"),
    ("Cisco / networking (Spanish Biblioteca CCNA)", r"(CCNA|CCENT|ROUTE|SPNGN|WLAN|BGP|MPLS|Subredes|Soporte|IA_|Protocolo|Implementac|Enrutamiento|Introduccion|Guia|LabGuide|Apunte|Ap_Rapido|Bridge)"),
    ("Law school outline decks", r"(CivPro|Contracts|Crim|Torts)"),
    ("Automotive EFI tuning (HP Tuners / SCT / Binary Editor / Delta Force)", r"^(hp1|moates1|sct1|delta1|hpgm)"),
    ("Osteopathy / craniosacral / manual therapy", r"(UPLEDGER|Upledger|Cranio|CST|CSOT|CSAMMS|COAPT|Fascia|FADAT|FDF|SER|RCOLL|CELLT|BIB|ATB|IPAY|LAS|MOO|RFPP|RPDMI|MLFPT|MLTOM|PTH|CSOT|Hirata|Somatic|Osteopath)"),
    ("Anatomy / movement (Calais-Germain, Eastland)", r"^(AOB|AOM|AOME|AOMT|AOY|FPAE|MM2|MM_|CST1|sct1)"),
    ("Acupuncture / Chinese medicine", r"(Acupunct|Chinese|Qigong|Moxa|Stems|Herbal|herbal|Plants|acupoints|autism|Menopause|Infertility|dermatology|Cancer|autoimmune|hiddenroots|Live-Well|Journeyman|Women)"),
    ("Math / science / engineering texts", r"(5thEd|5thEdition|difeq|HaVol1|math|ga7|sa\.drmz|sap\.drmz|pfea|abm|OSCE26|OGPE|Oil-and-Gas|towardsnetzero)"),
    ("Business / marketing / logistics", r"(InternationalMarketing|IntLog)"),
    ("Health / wellness / misc books", r"."),
]

NUM = re.compile(r"^M\d\d")
assigned = {}
for name, pat in GROUPS:
    for r in rows:
        f = r["file"]
        if f in assigned:
            continue
        if re.search(pat, f) or (name.startswith("Osteopathy") and re.search(pat, desc(r))):
            assigned[f] = name

lines = ["# Javelin .drmz corpus — pick list", "", "258 files, all decryptable (32-byte XOR keystream). Descriptions from page text.", ""]
for name, _ in GROUPS:
    members = [(r, assigned[r["file"]]) for r in rows if assigned.get(r["file"]) == name]
    if not members:
        continue
    lines.append("## %s — %d files" % (name, len(members)))
    lines.append("")
    lines.append("| file | pp | content |")
    lines.append("|---|---|---|")
    for r, _ in members:
        d = desc(r).replace("|", "/").replace("\u2019", "'")
        lines.append("| %s | %d | %s |" % (r["file"], r["pages"], d[:100]))
    lines.append("")

open("repro/CORPUS.md", "w", encoding="utf-8").write("\n".join(lines))
from collections import Counter
print(Counter(assigned.values()))
print("total", len(assigned))
