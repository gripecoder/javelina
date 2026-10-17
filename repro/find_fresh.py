import io, os, re, zipfile, urllib.request as u

UA = {"User-Agent": "Mozilla/5.0"}
CATALOGS = [
    "https://www.drumlinsecurity.com/orders/catalog.xml",
    "https://www.pdfz.org/drumlin.xml",
    "https://www.pdfz.org/aircraftstress.xml",
    "https://www.pdfz.org/edubooks.xml",
    "https://www.pdfz.org/jh.xml",
    "https://www.pdfz.org/lasota.xml",
    "https://www.pdfz.org/matrix.xml",
    "https://www.pdfz.org/naper.xml",
    "https://www.pdfz.org/nki.xml",
    "https://www.pdfz.org/ocean.xml",
    "https://www.pdfz.org/picjur.xml",
    "https://www.pdfz.org/rife.xml",
    "https://www.pdfz.org/syllabis.xml",
    "https://www.pdfz.org/srk.xml",
    "https://www.pdfz.org/sym.xml",
    "https://www.pdfz.org/vsr.xml",
    "https://www.pdfz.org/tccl.xml",
    "https://www.fea-academy.com/fea-academy.xml",
    "https://www.drumlinsecurity.com/orders/library.xml",
    "https://www.drumlinsecurity.com/orders/mi/mi.xml",
]
ZIPS = [
    "https://www.pdfz.org/bhc.zip",
    "https://www.pdfz.org/eastlands.zip",
    "https://www.pdfz.org/flightace.zip",
    "https://www.pdfz.org/thompson-wright.zip",
    "https://www.pdfz.org/upda.zip",
    "https://www.pdfz.org/physiotutors.zip",
    "https://training.aateh.si/catalog-at.zip",
]


def collect(xml):
    return [x.replace("&amp;", "&") for x in re.findall(r"<URL>\s*([^<\s]+)\s*</URL>", xml)]


def get(url, t=45):
    return u.urlopen(u.Request(url, headers=UA), timeout=t).read()


have = {os.path.basename(p).lower() for p in os.listdir("javelin-samples") if p.lower().endswith(".drmz")}
urls = []
for c in CATALOGS:
    try:
        urls += collect(get(c).decode("utf-8", "replace"))
    except Exception as e:
        print("CATFAIL", c, type(e).__name__, str(e)[:70])
for z in ZIPS:
    try:
        zf = zipfile.ZipFile(io.BytesIO(get(z, 90)))
        for n in zf.namelist():
            if n.lower().endswith((".xml", ".catalog")):
                urls += collect(zf.read(n).decode("utf-8", "replace"))
    except Exception as e:
        print("ZIPFAIL", z, type(e).__name__, str(e)[:70])

uniq = list(dict.fromkeys(x.strip() for x in urls))
fresh = [x for x in uniq if x.lower().endswith(".drmz") and os.path.basename(x).lower() not in have]
print("catalog urls", len(uniq), "| corpus", len(have), "| fresh", len(fresh))
for x in fresh:
    print("  ", x)
os.makedirs("repro/in", exist_ok=True)
with open("repro/fresh_urls.txt", "w") as f:
    f.write("\n".join(fresh))
