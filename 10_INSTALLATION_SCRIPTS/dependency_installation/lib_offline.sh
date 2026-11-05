#!/bin/bash
# Shared helpers. Source only. Writes nothing outside /var/log/linux-offline and /etc/apt unless asked.
LIB_ROOT="${LIB_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
REPO="$LIB_ROOT/04_APT_OFFLINE_REPOSITORY"
SUITE=noble-offline
LOG_DIR="${LOG_DIR:-/var/log/linux-offline}"
LOG_FILE="$LOG_DIR/install.log"
log()  { mkdir -p "$LOG_DIR" 2>/dev/null; printf '%s %s\n' "$(date -u +%FT%TZ)" "$*" | tee -a "$LOG_FILE" >&2; }
die()  { log "ERROR: $*"; exit "${2:-1}"; }
need_root() { [ "$(id -u)" = 0 ] || die "must run as root (use sudo)"; }
check_target() {
  . /etc/os-release
  [ "${VERSION_CODENAME:-}" = noble ] || die "this library is for Ubuntu 24.04 (noble); found '${PRETTY_NAME:-unknown}'. Refusing to mix releases." 10
  local a; a=$(dpkg --print-architecture)
  [ "$a" = amd64 ] || die "this library holds amd64 packages only; found '$a'." 11
  log "target OK: ${PRETTY_NAME} / $a"
}
check_repo_files() { # quick: index present, every indexed file present with the right size. --deep adds SHA256.
  local deep="${1:-}"
  [ -f "$REPO/dists/$SUITE/InRelease" ] || die "repository index not found under $REPO. Was the pool archive unpacked?" 12
  gpgv --keyring "$REPO/repository_keys/offline-repo-signing-key.gpg" "$REPO/dists/$SUITE/InRelease" >/dev/null 2>&1 \
    || die "InRelease signature check failed" 13
  python3 -I - "$REPO" "$SUITE" "$deep" <<'PY' || die "repository is incomplete or damaged (see the list above)" 14
import glob, hashlib, os, re, sys
repo, suite, deep = sys.argv[1:4]; bad = n = 0
for f in glob.glob(f"{repo}/dists/{suite}/*/binary-amd64/Packages"):
    for st in open(f, encoding="utf-8").read().split("\n\n"):
        if not st.strip(): continue
        n += 1; fn = re.search(r"^Filename: (.+)$", st, re.M)[1]; sz = int(re.search(r"^Size: (\d+)$", st, re.M)[1]); h = re.search(r"^SHA256: (\w+)$", st, re.M)[1]; p = f"{repo}/{fn}"
        if not os.path.isfile(p): print("MISSING", fn, file=sys.stderr); bad += 1; continue
        if os.path.getsize(p) != sz: print("BAD SIZE", fn, file=sys.stderr); bad += 1; continue
        if deep == "--deep":
            d = hashlib.sha256()
            with open(p, "rb") as o:
                for b in iter(lambda: o.read(1 << 20), b""): d.update(b)
            if d.hexdigest() != h: print("BAD SHA256", fn, file=sys.stderr); bad += 1
print(f"checked {n} packages, problems: {bad}", file=sys.stderr); sys.exit(1 if bad else 0)
PY
}
apt_opts() { # apt sees only the local repo; the user's own source files are left alone and ignored for this run.
  APT_OPTS=(-o "Dir::Etc::sourcelist=$RUNTIME_SRC" -o "Dir::Etc::sourceparts=-" -o "APT::Get::List-Cleanup=0" -o "Acquire::Languages=none" -o "Acquire::Retries=0")
  # _apt must be able to read the repository; if it cannot (e.g. under /root), read it as root and say so.
  if command -v runuser >/dev/null && ! runuser -u _apt -- test -r "$REPO/dists/$SUITE/InRelease" 2>/dev/null; then
    log "NOTE: user _apt cannot read $REPO; using APT::Sandbox::User=root for this run"
    APT_OPTS+=(-o "APT::Sandbox::User=root")
  fi
}
prepare_runtime_source() {
  RUNTIME_SRC="$(mktemp /tmp/offline-apt.XXXXXX.list)"
  chmod 644 "$RUNTIME_SRC"; trap 'rm -f "$RUNTIME_SRC"' EXIT
  printf 'deb [arch=amd64 signed-by=%s] file:%s %s main universe\n' "$REPO/repository_keys/offline-repo-signing-key.gpg" "$REPO" "$SUITE" > "$RUNTIME_SRC"
  apt_opts
}
