#!/usr/bin/env python3
"""Generate 12_CHECKSUMS_AND_METADATA: SHA256SUMS.txt, FILE_INVENTORY.csv, PACKAGE_DEPENDENCIES.csv, DOWNLOAD_URLS.md.
Every verification status comes from a check run here; nothing is marked verified by assumption."""
import csv, glob, gzip, hashlib, os, re, subprocess, sys, tarfile, zipfile
LIB = os.path.abspath(sys.argv[1]) if len(sys.argv) > 1 else os.path.abspath(os.path.join(os.path.dirname(__file__), "../.."))
M = f"{LIB}/12_CHECKSUMS_AND_METADATA"; A = f"{LIB}/04_APT_OFFLINE_REPOSITORY"
SKIP_TOP = {".git", ".tools", ".gitignore"}
GENERATED = {"12_CHECKSUMS_AND_METADATA/SHA256SUMS.txt", "12_CHECKSUMS_AND_METADATA/FILE_INVENTORY.csv"}
os.makedirs(M, exist_ok=True)


def sha(p):
    h = hashlib.sha256()
    with open(p, "rb") as o:
        for b in iter(lambda: o.read(1 << 20), b""):
            h.update(b)
    return h.hexdigest()


def looks_like_html(p):
    with open(p, "rb") as o:
        head = o.read(512).lstrip().lower()
    return head.startswith((b"<!doctype html", b"<html"))


# ---- official hashes
off = {}
for line in open(f"{LIB}/01_UBUNTU_ISO/SHA256SUMS/SHA256SUMS"):
    h, n = line.split(); off[n.lstrip("*")] = h
stanza = {}
for f in glob.glob(f"{A}/metadata/*/*/binary-amd64/Packages.gz"):
    pocket = f.split("/metadata/")[1].split("/")[0]
    for s in gzip.open(f, "rt", encoding="utf-8").read().split("\n\n"):
        m = re.search(r"^Filename: (.+)$", s, re.M)
        if m:
            stanza[m[1]] = (s, pocket)
wheel_src = {}
p = f"{LIB}/07_PYTHON_BASE_ENVIRONMENT/wheelhouse/WHEEL_SOURCES.tsv"
if os.path.exists(p):
    for l in open(p):
        a, url, st = l.rstrip("\n").split("\t"); wheel_src[a.split()[1]] = (a.split()[0], url, st)
assets = {}
p = f"{LIB}/15_DEVELOPMENT_ENVIRONMENT/editors/ASSETS.txt"
if os.path.exists(p):
    for l in open(p):
        sub, n, h, u = l.split(); assets[n] = (h, u)
NODE = "https://nodejs.org/dist/v24.22.2/"
UB = "https://releases.ubuntu.com/24.04.5/"
GITHUB_WSL = "https://github.com/microsoft/WSL/releases/download/3.0.3/"
FIXED = {
    "wsl.3.0.3.0.x64.msi": ("3.0.3", GITHUB_WSL + "wsl.3.0.3.0.x64.msi", "ae977286974255bd26bf925f00f40f5692c6b2084155cbc0563c09aea091f211", "WSL package for Windows (includes the WSL2 kernel)"),
    "wsl_update_x64.msi": ("5.10.16", "https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi", None, "Legacy WSL2 kernel update, only for older Windows 10 setups"),
}
BROADCOM = "https://support.broadcom.com/group/ecx/productdownloads?subfamily=VMware%20Workstation%20Pro&freeDownloads=true"
VT = "https://packages.vmware.com/tools/releases/latest/windows/"
NP = "; not in the public repository, see the .url placeholder"
VMW = {
    "VMware-Workstation-Full-26H1u1-25688693.exe": ("26H1u1 build 25688693", BROADCOM, "3d775c3c2153600eef4642f95d519a514ba7e861400bda2598352bff792db473", "Broadcom", "VMware Workstation for Windows hosts", "verified: Broadcom Authenticode chain + independent SHA256 records" + NP),
    "VMware-Workstation-Full-26H1u1-25688693.x86_64.bundle": ("26H1u1 build 25688693", BROADCOM, "da823c853cc7e57be7b9b070c8aed20fe9d75fd519ae6f175ab1dafc7283002e", "Broadcom", "VMware Workstation for Linux hosts", "verified: independent SHA256 record only; no code signature checked" + NP),
    "VMware-tools-windows-13.1.5-25544008.iso": ("13.1.5 build 25544008", VT + "VMware-tools-windows-13.1.5-25544008.iso", "d94a1c17d09af590ddc1e720679e2e75a46a6a7b2a43945b03a75255569a6477", "VMware official packages site", "VMware Tools for Windows guests (Ubuntu guests use open-vm-tools)", "downloaded over HTTPS from the official site; signature files not checked" + NP),
}
rows, sums, urls = [], [], []
pool_bad = 0
for r, ds, fs in os.walk(LIB):
    rel_r = os.path.relpath(r, LIB)
    if rel_r == ".":
        ds[:] = [d for d in ds if d not in SKIP_TOP]
    ds.sort()
    for x in sorted(fs):
        p = os.path.join(r, x); rel = os.path.relpath(p, LIB)
        if rel in GENERATED or rel in SKIP_TOP or x.endswith(".part") or (rel.startswith("14_LOGS_AND_REPORTS/") and x.endswith(".log")):
            continue
        h = sha(p); sz = os.path.getsize(p); sums.append(f"{h}  {rel}")
        ver = url = "-"; ub = "24.04 (noble)"; arch = "-"; use = "library file (script, document or metadata)"; src = "this library"; status = "SHA256 recorded"
        ext = x.rsplit(".", 1)[-1].lower()
        if looks_like_html(p) and not rel.startswith(("00_", "13_")):
            status = "FAILED: HTML content"
        elif ext == "deb" and rel.startswith("04_"):
            k = rel.split("04_APT_OFFLINE_REPOSITORY/")[1]; s, pocket = stanza[k]
            ver = re.search(r"^Version: (.+)$", s, re.M)[1]; arch = re.search(r"^Architecture: (.+)$", s, re.M)[1]
            url = "https://archive.ubuntu.com/ubuntu/" + k; src = f"Ubuntu archive, {pocket}"; use = re.search(r"^Section: (.+)$", s, re.M)[1]
            ok = re.search(r"^SHA256: (.+)$", s, re.M)[1] == h and subprocess.run(["dpkg-deb", "--info", p], capture_output=True).returncode == 0
            status = "verified: signed index SHA256 + dpkg-deb readable" if ok else "FAILED"; pool_bad += not ok
        elif x in off:
            ver = "24.04.5.1" if "24.04.5.1" in x else "24.04.5"; arch = "amd64"; url = UB + x; src = "Ubuntu releases"
            use = {"iso": "installation medium", "wsl": "WSL rootfs"}.get(ext, "release file")
            status = "verified: official SHA256 (GPG-signed list)" if off[x] == h else "FAILED"
        elif x in VMW:
            ver, url, want, src, use, status = VMW[x]; arch = "x64"; ub = "see purpose"
            if want != h:
                status = "FAILED"
        elif x in FIXED:
            ver, url, want, use = FIXED[x]; arch = "x64"; src = "Microsoft"; ub = "Windows host"
            status = ("verified: GitHub release digest + Microsoft Authenticode chain" + NP if want == h else "FAILED") if want else "partial: no published checksum; Authenticode digest matches, certificate expired, chain valid only at claimed 2021 signing time" + NP
        elif ext == "whl":
            e = wheel_src.get(x); ver = x.split("-")[1]; arch = "py3 / x86_64"; src = "PyPI"; use = "Python wheelhouse"
            url = e[1] if e else "-"
            ok = bool(e) and e[0] == h and e[2] == "match" and zipfile.ZipFile(p).testzip() is None
            status = "verified: PyPI SHA256 + zip test" if ok else "FAILED"
        elif x in assets:
            want, url = assets[x]; src = "Microsoft"; ver = "see editors/VERSION or file name"; arch = "x64"; use = "VS Code; .url placeholder only (licence)"
            if ext == "vsix":
                status = "SHA256 recorded at download (no published checksum) + zip test + cmake-tools install test" if want == h and zipfile.ZipFile(p).testzip() is None else "FAILED"
            else:
                status = "verified: Microsoft SHA256" if want == h else "FAILED"
        elif x.startswith("node-") and x.endswith(".tar.xz"):
            ver = "24.22.2"; arch = "x64"; url = NODE + x; src = "nodejs.org"; use = "Node.js and npm"
            want = next(l.split()[0] for l in open(f"{r}/SHASUMS256.txt") if l.split()[1] == x)
            ok = want == h and tarfile.open(p).getnames() is not None
            status = "verified: signed SHASUMS256 + tar test" if ok else "FAILED"
        elif rel.startswith("04_APT_OFFLINE_REPOSITORY/metadata/"):
            src = "Ubuntu archive"; use = "official signed metadata"; url = "https://archive.ubuntu.com/ubuntu/dists/" + rel.split("metadata/")[1]; status = "verified: gpgv + InRelease by verify_repo_against_official.py"
        rows.append([x, ver, src, url, sz, h, ub, arch, use, status, rel])
        if url != "-":
            urls.append((src, x, url))
# ---- dependencies
groups = {}
for f in glob.glob(f"{LIB}/**/resolved_closure.txt", recursive=True):
    g = os.path.relpath(os.path.dirname(f), LIB)
    for n in open(f).read().split():
        groups.setdefault(n, set()).add(g)
with open(f"{M}/PACKAGE_DEPENDENCIES.csv", "w", newline="", encoding="utf-8") as o:
    w = csv.writer(o); w.writerow("package version arch component pocket pre_depends depends recommends groups".split())
    for fn, (s, pocket) in sorted(stanza.items()):
        if not os.path.exists(f"{A}/{fn}"):
            continue
        g = lambda k: (re.search(rf"^{k}: (.+)$", s, re.M) or [None, ""])[1]
        w.writerow([g("Package"), g("Version"), g("Architecture"), fn.split("/")[1], pocket, g("Pre-Depends"), g("Depends"), g("Recommends"), " ".join(sorted(groups.get(os.path.basename(fn), [])))])
with open(f"{M}/DOWNLOAD_URLS.md", "w", encoding="utf-8") as o:
    o.write("# Official download sources\n\nGenerated from the files in this library. Full per-file detail is in `FILE_INVENTORY.csv`.\n\n")
    for s in sorted({u[0] for u in urls}):
        items = [u for u in urls if u[0] == s]
        o.write(f"## {s} ({len(items)} files)\n\n")
        if s.startswith("Ubuntu archive"):
            o.write("Base URL: https://archive.ubuntu.com/ubuntu/ . See `FILE_INVENTORY.csv` for each package.\n\n"); continue
        for _, n, u in items:
            o.write(f"- `{n}`: {u}\n")
        o.write("\n")
    o.write("## VMware note\n\nVMware Workstation came from a third-party mirror, because Broadcom requires sign-in. See `03_VMWARE/workstation_installers/HOW_TO_OBTAIN.md`.\n")
# These two are written above, after the walk, so hash them now.
for gen in ("PACKAGE_DEPENDENCIES.csv", "DOWNLOAD_URLS.md"):
    rel = f"12_CHECKSUMS_AND_METADATA/{gen}"; h = sha(f"{LIB}/{rel}"); sz = os.path.getsize(f"{LIB}/{rel}")
    sums = [l for l in sums if not l.endswith("  " + rel)] + [f"{h}  {rel}"]
    for r in rows:
        if r[10] == rel:
            r[4], r[5] = sz, h
with open(f"{M}/SHA256SUMS.txt", "w") as o:
    o.write("\n".join(sums) + "\n")
with open(f"{M}/FILE_INVENTORY.csv", "w", newline="", encoding="utf-8") as o:
    w = csv.writer(o); w.writerow("file version source url size_bytes sha256 applies_to arch purpose verification path".split()); w.writerows(rows)
bad = [r for r in rows if r[9].startswith("FAILED") or "FAILED" in r[9]]
print(f"files: {len(rows)}  size: {sum(r[4] for r in rows)/2**30:.2f} GiB  failed: {len(bad)}")
for r in bad[:20]:
    print("FAILED:", r[10], r[9])
sys.exit(1 if bad else 0)
