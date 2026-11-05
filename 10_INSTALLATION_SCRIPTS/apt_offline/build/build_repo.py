#!/usr/bin/env python3
"""Build a signed local APT repository from the pool using the official index stanzas verbatim
(only Phased-Update-Percentage is dropped, so upgrades are not randomly held back offline)."""
import glob, gzip, hashlib, os, re, shutil, subprocess, sys, time
R = os.environ.get("LIB_ROOT", os.path.abspath(os.path.join(os.path.dirname(__file__), "../../..")))
A = f"{R}/04_APT_OFFLINE_REPOSITORY"; SUITE = "noble-offline"; COMPS = ("main", "restricted", "universe", "multiverse")
GH = os.environ.get("REPO_GNUPGHOME", f"{R}/.tools/gpg_local")
want = {l.split("\t")[1]: l.split("\t")[3].strip() for l in open(f"{R}/.tools/closure_uris.tsv")}
st = {}
for f in glob.glob(f"{A}/metadata/*/*/binary-amd64/Packages.gz"):
    for s in gzip.open(f, "rt", encoding="utf-8").read().split("\n\n"):
        m = re.search(r"^Filename: (.+)$", s, re.M)
        if m and m[1] in want: st[m[1]] = s.strip()
miss = set(want) - set(st)
if miss: sys.exit(f"missing official stanza: {sorted(miss)[:5]}")
seen = {}
for fn, s in st.items():
    k = re.search(r"^Package: (.+)$", s, re.M)[1]
    if k in seen: print("WARNING two versions of", k, fn, seen[k])
    seen[k] = fn
    arch = re.search(r"^Architecture: (.+)$", s, re.M)[1]
    assert arch in ("amd64", "all"), fn
for c in COMPS:
    d = f"{A}/dists/{SUITE}/{c}/binary-amd64"; os.makedirs(d, exist_ok=True)
    rows = [st[f] for f in sorted(st) if f.startswith(f"pool/{c}/")]
    txt = "\n\n".join(re.sub(r"^Phased-Update-Percentage: .*\n", "", s, flags=re.M) for s in rows)
    txt = txt + "\n\n" if txt else ""
    open(f"{d}/Packages", "w", encoding="utf-8").write(txt)
    with open(f"{d}/Packages.gz", "wb") as o:
        with gzip.GzipFile(fileobj=o, mode="wb", mtime=0) as g: g.write(txt.encode())
    open(f"{d}/Release", "w").write(f"Archive: {SUITE}\nComponent: {c}\nOrigin: LinuxOfflineLibrary\nLabel: Ubuntu 24.04 offline subset\nArchitecture: amd64\n")
    print(c, len(rows))
D = f"{A}/dists/{SUITE}"
files = sorted(os.path.relpath(p, D) for p in glob.glob(f"{D}/*/binary-amd64/*"))
rel = (f"Origin: LinuxOfflineLibrary\nLabel: Ubuntu 24.04 offline subset\nSuite: {SUITE}\nCodename: {SUITE}\nVersion: 24.04\n"
       f"Date: {time.strftime('%a, %d %b %Y %H:%M:%S UTC', time.gmtime())}\nArchitectures: amd64\nComponents: {' '.join(COMPS)}\n"
       "Description: Dependency-closed subset of official Ubuntu 24.04 noble, noble-updates, noble-security\nSHA256:\n")
for f in files:
    b = open(f"{D}/{f}", "rb").read(); rel += f" {hashlib.sha256(b).hexdigest()} {len(b):>12} {f}\n"
open(f"{D}/Release", "w").write(rel)
os.makedirs(GH, mode=0o700, exist_ok=True)
g = ["gpg", "--homedir", GH, "--batch", "--yes", "--no-tty"]
if not subprocess.run(g + ["--list-secret-keys"], capture_output=True, text=True).stdout.strip():
    subprocess.run(g + ["--passphrase", "", "--quick-generate-key", "Linux Offline Library local repository signing key", "ed25519", "sign", "never"], check=True)
for extra, out in ((["--clearsign"], "InRelease"), (["-abs"], "Release.gpg")):
    subprocess.run(g + extra + ["-o", f"{D}/{out}", f"{D}/Release"], check=True)
subprocess.run(g + ["--export", "-o", f"{A}/repository_keys/offline-repo-signing-key.gpg"], check=True)
print(subprocess.run(["gpgv", "--keyring", f"{A}/repository_keys/offline-repo-signing-key.gpg", f"{D}/InRelease"], capture_output=True, text=True).stderr)
print("packages:", len(st))
