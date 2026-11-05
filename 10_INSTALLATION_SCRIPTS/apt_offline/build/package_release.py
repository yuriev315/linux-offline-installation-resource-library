#!/usr/bin/env python3
"""Split large files into GitHub Release assets and write 12_CHECKSUMS_AND_METADATA/RELEASE_MANIFEST.tsv.
Asset columns: asset, sha256, size, kind (file|part|tarpart), target path relative to the library root.
Output goes to .tools/release. Source files are only read. Safe to re-run: valid parts are kept."""
import hashlib, os, subprocess, sys
LIB = os.environ.get("LIB_ROOT", os.path.abspath(os.path.join(os.path.dirname(__file__), "../../..")))
OUT = f"{LIB}/.tools/release"; PART = 1400 * 2**20; os.makedirs(OUT, exist_ok=True)
WHOLE = ["02_WSL2/ubuntu_rootfs/ubuntu-24.04.5-wsl-amd64.wsl"]  # licence-restricted files become .url placeholders instead
SPLIT = ["01_UBUNTU_ISO/ubuntu_desktop/ubuntu-24.04.5.1-desktop-amd64.iso", "01_UBUNTU_ISO/ubuntu_server/ubuntu-24.04.5-live-server-amd64.iso"]
TARS = {"apt-pool.tar": ["04_APT_OFFLINE_REPOSITORY/pool"],
        "language-runtimes.tar": ["07_PYTHON_BASE_ENVIRONMENT/wheelhouse", "15_DEVELOPMENT_ENVIRONMENT/language_runtimes/node"]}


def sha(p):
    h = hashlib.sha256()
    with open(p, "rb") as o:
        for b in iter(lambda: o.read(1 << 20), b""):
            h.update(b)
    return h.hexdigest()


def split(src, base):
    n = 0; made = []; size = os.path.getsize(src)
    with open(src, "rb") as i:
        while True:
            name = f"{base}.part-{n:03d}"; p = f"{OUT}/{name}"; want = min(PART, size - n * PART)
            if want <= 0:
                break
            if not (os.path.exists(p) and os.path.getsize(p) == want):
                with open(p, "wb") as o:
                    left = want
                    while left:
                        b = i.read(min(1 << 20, left)); o.write(b); left -= len(b)
            made.append(name); n += 1; i.seek(n * PART)
    return made


rows = []
for rel in WHOLE:
    src = f"{LIB}/{rel}"; dst = f"{OUT}/{os.path.basename(rel)}"
    if not os.path.exists(dst):
        os.link(src, dst)
    rows.append((os.path.basename(rel), "file", rel))
for rel in SPLIT:
    for n in split(f"{LIB}/{rel}", os.path.basename(rel)):
        rows.append((n, "part", rel))
for tar, dirs in TARS.items():
    t = f"{OUT}/{tar}"
    subprocess.run(["tar", "-cf", t, "--sort=name", "--owner=0", "--group=0", "--numeric-owner", "--mtime=2026-11-05 00:00Z", "-C", LIB, *dirs], check=True)
    if os.path.getsize(t) <= PART:
        rows.append((tar, "tar", "."))
    else:
        for n in split(t, tar):
            rows.append((n, "tarpart", tar))
with open(f"{LIB}/12_CHECKSUMS_AND_METADATA/RELEASE_MANIFEST.tsv", "w") as o:
    for name, kind, target in rows:
        p = f"{OUT}/{name}"; o.write(f"{name}\t{sha(p)}\t{os.path.getsize(p)}\t{kind}\t{target}\n"); print(name, os.path.getsize(p))
print(len(rows), "assets;", round(sum(os.path.getsize(f"{OUT}/{r[0]}") for r in rows) / 2**30, 2), "GiB")
