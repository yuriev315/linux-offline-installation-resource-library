#!/usr/bin/env python3
"""Offline proof of origin. gpgv checks the official Ubuntu InRelease; each Packages.gz must match it; every .deb in the
local repository must match the SHA256 in those official indexes. Needs only python3 and gpgv."""
import glob, gzip, hashlib, os, re, subprocess, sys
LIB = os.path.abspath(sys.argv[1]) if len(sys.argv) > 1 else os.path.abspath(os.path.join(os.path.dirname(__file__), "../.."))
A = f"{LIB}/04_APT_OFFLINE_REPOSITORY"; KEY = f"{A}/repository_keys/ubuntu-archive-keyring.gpg"; official = {}; bad = 0
for d in sorted(glob.glob(f"{A}/metadata/*")):
    v = subprocess.run(["gpgv", "--keyring", KEY, f"{d}/InRelease"], capture_output=True, text=True)
    if v.returncode: sys.exit(f"BAD SIGNATURE {d}")
    sha = open(f"{d}/InRelease").read().split("SHA256:")[1]
    for f in glob.glob(f"{d}/*/binary-amd64/Packages.gz"):
        rel = os.path.relpath(f, d); m = re.search(rf"^ ([0-9a-f]{{64}})\s+\d+ {re.escape(rel)}$", sha, re.M)
        if not m or hashlib.sha256(open(f, "rb").read()).hexdigest() != m[1]: sys.exit(f"INDEX MISMATCH {f}")
        for st in gzip.open(f, "rt", encoding="utf-8").read().split("\n\n"):
            a = re.search(r"^Filename: (.+)$", st, re.M); b = re.search(r"^SHA256: (.+)$", st, re.M)
            if a: official[a[1]] = b[1]
    print(f"official index OK: {os.path.basename(d)}")
n = 0
for r, _, fs in os.walk(f"{A}/pool"):
    for x in fs:
        p = os.path.join(r, x); rel = os.path.relpath(p, A); n += 1; h = hashlib.sha256()
        with open(p, "rb") as o:
            for b in iter(lambda: o.read(1 << 20), b""): h.update(b)
        if official.get(rel) != h.hexdigest(): print("NOT OFFICIAL OR DAMAGED:", rel); bad += 1
print(f"checked {n} pool files against official signed indexes; problems: {bad}"); sys.exit(1 if bad else 0)
