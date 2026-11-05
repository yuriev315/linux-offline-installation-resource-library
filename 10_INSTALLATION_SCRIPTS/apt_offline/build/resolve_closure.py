#!/usr/bin/env python3
"""Resolve the dependency closure with apt's own solver against real system baselines.
Writes .tools/closure_uris.tsv (uri, filename, size, sha256) — union of every solve."""
import glob, gzip, os, re, subprocess, sys, urllib.parse
R = os.environ.get("LIB_ROOT", os.path.abspath(os.path.join(os.path.dirname(__file__), "../../..")))
B = f"{R}/10_INSTALLATION_SCRIPTS/apt_offline/build"; T = f"{R}/.tools"
env = dict(os.environ, APT_CONFIG=f"{T}/apt.conf")
groups = dict(l.rstrip("\n").split("\t") for l in open(f"{B}/groups.tsv") if l.strip())
ALL = sorted({p for v in groups.values() for p in v.split()})
BASE = ["?essential", "?priority(required)", "?priority(important)"]
line = re.compile(r"^'([^']+)' (\S+) (\d+) \S+$")
def solve(args, status=None, rec=True):
    cmd = ["apt-get", "-y", "-qq", "--print-uris", "-o", f"APT::Install-Recommends={str(rec).lower()}", "-o", "Debug::NoLocking=1"]
    if status: cmd += ["-o", f"Dir::State::status={status}"]
    p = subprocess.run(cmd + args, env=env, capture_output=True, text=True)
    if p.returncode: sys.exit(f"SOLVE FAILED {status} {args[:3]}...\n{p.stderr}")
    return {m[1]: m.groups() for m in map(line.match, p.stdout.splitlines()) if m}
# apt may print MD5 here, so the SHA256 is taken from the gpg-verified official indexes.
idx = {}
for f in glob.glob(f"{R}/04_APT_OFFLINE_REPOSITORY/metadata/*/*/binary-amd64/Packages.gz"):
    for st in gzip.open(f, "rt", encoding="utf-8").read().split("\n\n"):
        fn = re.search(r"^Filename: (.+)$", st, re.M); sh = re.search(r"^SHA256: (.+)$", st, re.M); sz = re.search(r"^Size: (.+)$", st, re.M)
        if fn: idx[fn[1]] = (sh[1], sz[1])
union = {}
def add(name, res):
    new = len(set(res) - set(union)); union.update(res)
    print(f"{name:45s} solve={len(res):5d} new={new:5d} total={len(union):5d}", flush=True)
add("empty: all groups + essential/required/important", solve(["install", *ALL, *BASE]))
for s in sorted(glob.glob(f"{T}/baselines/status.*")):
    n = os.path.basename(s)
    add(f"{n}: dist-upgrade", solve(["dist-upgrade"], s))
    add(f"{n}: install all groups", solve(["install", *ALL], s))
# Every group must also resolve on its own, on a bare system.
per = {}
for g, pk in groups.items():
    r = solve(["install", *pk.split()]); per[g] = sorted(v[1] for v in r.values()); add(f"group {g}", r)
    d = f"{R}/{g}"; os.makedirs(d, exist_ok=True)
    open(f"{d}/packages.list", "w").write("\n".join(pk.split()) + "\n")
    open(f"{d}/resolved_closure.txt", "w").write("\n".join(per[g]) + "\n")
with open(f"{T}/closure_uris.tsv", "w") as f:
    for u, n, sz, *_ in sorted(union.values(), key=lambda x: x[1]):
        fn = urllib.parse.unquote(urllib.parse.urlsplit(u).path).split("/ubuntu/", 1)[1]
        h, osz = idx[fn]  # KeyError here means a package not in a signed index: must fail
        assert osz == sz, fn
        f.write(f"{u}\t{fn}\t{sz}\t{h}\n")
print("TOTAL", len(union), round(sum(int(v[2]) for v in union.values()) / 2**30, 2), "GiB")
