#!/usr/bin/env python3
"""Fetch official signed Noble metadata, verify InRelease with gpgv and each Packages.gz against InRelease."""
import hashlib, os, re, subprocess, sys, urllib.request
R = os.environ.get("LIB_ROOT", os.path.abspath(os.path.join(os.path.dirname(__file__), "../../..")))
M = f"{R}/04_APT_OFFLINE_REPOSITORY/metadata"; KEY = f"{R}/04_APT_OFFLINE_REPOSITORY/repository_keys/ubuntu-archive-keyring.gpg"
BASE = "https://archive.ubuntu.com/ubuntu/dists"
def get(url, p):
    os.makedirs(os.path.dirname(p), exist_ok=True); urllib.request.urlretrieve(url, p)
for pocket in ("noble", "noble-updates", "noble-security"):
    d = f"{M}/{pocket}"
    for f in ("InRelease", "Release", "Release.gpg"): get(f"{BASE}/{pocket}/{f}", f"{d}/{f}")
    v = subprocess.run(["gpgv", "--keyring", KEY, f"{d}/InRelease"], capture_output=True, text=True)
    if v.returncode: sys.exit(f"BAD SIGNATURE {pocket}\n{v.stderr}")
    text = open(f"{d}/InRelease").read(); sha = text.split("SHA256:")[1]
    for comp in ("main", "restricted", "universe", "multiverse"):
        rel = f"{comp}/binary-amd64/Packages.gz"; m = re.search(rf"^ ([0-9a-f]{{64}})\s+\d+ {re.escape(rel)}$", sha, re.M)
        if not m: sys.exit(f"{rel} absent from {pocket} InRelease")
        p = f"{d}/{rel}"; get(f"{BASE}/{pocket}/{rel}", p)
        if hashlib.sha256(open(p, "rb").read()).hexdigest() != m[1]: sys.exit(f"HASH MISMATCH {p}")
    print(pocket, "signature OK; 4 Packages.gz match InRelease")
