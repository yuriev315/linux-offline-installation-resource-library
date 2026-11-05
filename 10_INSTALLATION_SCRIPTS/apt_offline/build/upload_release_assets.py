#!/usr/bin/env python3
"""Upload the Release assets in RELEASE_MANIFEST.tsv and confirm each from GitHub's SHA256 digest. Resumable.
Each part is rebuilt from the library just before upload and removed afterwards, so the shared disk stays free.
usage: upload_release_assets.py [name-substring ...]"""
import hashlib, json, os, subprocess, sys, time
LIB = os.environ.get("LIB_ROOT", os.path.abspath(os.path.join(os.path.dirname(__file__), "../../..")))
REPO = "yuriev315/linux-offline-installation-resource-library"; TAG = "library-2026.11.05"; PART = 1400 * 2**20
OUT = f"{LIB}/.tools/release"; LOG = f"{LIB}/14_LOGS_AND_REPORTS/upload.log"; os.makedirs(OUT, exist_ok=True)
TARS = {"apt-pool.tar": ["04_APT_OFFLINE_REPOSITORY/pool"], "language-runtimes.tar": ["07_PYTHON_BASE_ENVIRONMENT/wheelhouse", "15_DEVELOPMENT_ENVIRONMENT/language_runtimes/node"]}
only = sys.argv[1:]


def log(m):
    line = time.strftime("%FT%TZ ", time.gmtime()) + m
    print(line, flush=True)
    with open(LOG, "a") as o:
        o.write(line + "\n")


def remote():
    rels = json.loads(subprocess.run(["gh", "api", f"repos/{REPO}/releases?per_page=30"], capture_output=True, text=True, check=True).stdout)
    r = next(x for x in rels if x["tag_name"] == TAG)
    return {a["name"]: a for a in r["assets"]}


def sha(p):
    h = hashlib.sha256()
    with open(p, "rb") as o:
        for b in iter(lambda: o.read(1 << 20), b""):
            h.update(b)
    return h.hexdigest()


def tar_path(name):
    t = f"{OUT}/{name}"
    if not os.path.exists(t):
        subprocess.run(["tar", "-cf", t, "--sort=name", "--owner=0", "--group=0", "--numeric-owner", "--mtime=2026-11-05 00:00Z", "-C", LIB, *TARS[name]], check=True)
    return t


def build(name, kind, target):
    """Return the path of the asset, creating it when it is a slice or a tar."""
    if kind == "file":
        return f"{LIB}/{target}"
    if kind == "tar":
        return tar_path(name)
    src = tar_path(target) if kind == "tarpart" else f"{LIB}/{target}"
    n = int(name.rsplit("-", 1)[1]); p = f"{OUT}/{name}"
    with open(src, "rb") as i, open(p, "wb") as o:
        i.seek(n * PART); left = PART
        while left:
            b = i.read(min(1 << 20, left))
            if not b:
                break
            o.write(b); left -= len(b)
    return p


rows = [l.rstrip("\n").split("\t") for l in open(f"{LIB}/12_CHECKSUMS_AND_METADATA/RELEASE_MANIFEST.tsv")]
fail = 0
for name, want, size, kind, target in rows:
    if only and not any(o in name for o in only):
        continue
    for attempt in range(4):
        a = remote().get(name)
        if a and a.get("state") == "uploaded" and a.get("digest") == f"sha256:{want}" and str(a["size"]) == size:
            log(f"OK {name} digest match")
            break
        p = build(name, kind, target)
        if sha(p) != want:
            log(f"LOCAL MISMATCH {name}: rebuilt file differs from the manifest; run package_release.py")
            fail += 1
            break
        t = time.time()
        q = subprocess.run(["gh", "release", "upload", TAG, p, "-R", REPO, "--clobber"], capture_output=True, text=True)
        log(f"upload {name} rc={q.returncode} {time.time() - t:.0f}s {q.stderr.strip()[:200]}")
        if kind != "file" and p.startswith(OUT):
            os.remove(p)
    else:
        log(f"FAILED {name}")
        fail += 1
for t in TARS:
    if os.path.exists(f"{OUT}/{t}"):
        os.remove(f"{OUT}/{t}")
ok = all((a := remote().get(r[0])) and a.get("digest") == f"sha256:{r[1]}" for r in rows if not only or any(o in r[0] for o in only))
log(f"upload run finished, failed={fail}, all selected assets match={ok}")
sys.exit(0 if ok and not fail else 1)
