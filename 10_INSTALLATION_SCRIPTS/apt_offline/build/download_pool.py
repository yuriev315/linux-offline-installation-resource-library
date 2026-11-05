#!/usr/bin/env python3
"""Download closure .debs into pool/, keeping the official path. Verified against SHA256 from the signed index.
Resumable: files already matching size+sha256 are skipped. Stops below the free-space floor."""
import concurrent.futures as cf, hashlib, os, shutil, subprocess, sys, time
R = os.environ.get("LIB_ROOT", os.path.abspath(os.path.join(os.path.dirname(__file__), "../../..")))
POOL = f"{R}/04_APT_OFFLINE_REPOSITORY"; LOG = f"{R}/14_LOGS_AND_REPORTS/download.log"; FLOOR = 120 * 2**30
rows = [l.rstrip("\n").split("\t") for l in open(f"{R}/.tools/closure_uris.tsv")]
def sha(p):
    h = hashlib.sha256()
    with open(p, "rb") as f:
        for b in iter(lambda: f.read(1 << 20), b""): h.update(b)
    return h.hexdigest()
def log(m):
    with open(LOG, "a") as f: f.write(time.strftime("%FT%TZ ", time.gmtime()) + m + "\n")
def get(r):
    u, rel, sz, h = r; p = f"{POOL}/{rel}"
    if os.path.exists(p) and os.path.getsize(p) == int(sz) and sha(p) == h: return "skip"
    if shutil.disk_usage(R).free < FLOOR: log(f"STOP floor {u}"); return "floor"
    os.makedirs(os.path.dirname(p), exist_ok=True)
    for a in range(4):
        rc = subprocess.run(["ionice","-c2","-n7","nice","-n10","curl","-fL","--retry","6","--retry-all-errors","--retry-delay","3","-C","-","-sS","-o",p,u]).returncode
        if rc == 0 and sha(p) == h: log(f"OK {sz} {rel}"); return "ok"
        if rc == 0: os.replace(p, p + ".badsha"); log(f"BADSHA {u}")
        if rc == 33 and os.path.exists(p): os.remove(p)
    log(f"FAIL {u}"); return "fail"
with cf.ThreadPoolExecutor(6) as ex: res = list(ex.map(get, rows))
print({k: res.count(k) for k in set(res)}); sys.exit(any(x in ("fail", "floor") for x in res))
