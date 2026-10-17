import json, urllib.request, zipfile, os, sys

base = r"%USERPROFILE%\Documents\github\rea\mountainmaps"
os.makedirs(os.path.join(base, "tmp"), exist_ok=True)
os.makedirs(os.path.join(base, "py"), exist_ok=True)

info = json.load(urllib.request.urlopen("https://pypi.org/pypi/capstone/json", timeout=30))
ver = info["info"]["version"]
url = None
for u in info["urls"]:
    if u["filename"].endswith("win_amd64.whl"):
        url = u["url"]
print("wheel:", url)
whl = os.path.join(base, "tmp", "capstone.whl")
urllib.request.urlretrieve(url, whl)
print("downloaded", os.path.getsize(whl), "bytes")
with zipfile.ZipFile(whl) as z:
    z.extractall(os.path.join(base, "py"))
sys.path.insert(0, os.path.join(base, "py"))
import capstone
print("capstone OK, version", capstone.__version__)
