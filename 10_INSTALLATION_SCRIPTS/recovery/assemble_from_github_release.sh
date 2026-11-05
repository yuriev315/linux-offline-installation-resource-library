#!/bin/bash
# ONLINE step. Run from a clone of the repository: downloads the Release assets, checks each one, then rebuilds
# the ISOs, WSL files, APT pool, wheels and Node.js in place. Resumable. Needs about 30 GB free while assembling.
# usage: assemble_from_github_release.sh [--only iso|wsl|apt|runtime|all] [--keep-parts]
set -euo pipefail
LIB=$(cd "$(dirname "$0")/../.." && pwd); cd "$LIB"
REPO_URL="https://github.com/yuriev315/linux-offline-installation-resource-library/releases/download/library-2026.11.05"
M=12_CHECKSUMS_AND_METADATA/RELEASE_MANIFEST.tsv; DL=.release-download; mkdir -p "$DL"
ONLY=all; KEEP=0
while [ $# -gt 0 ]; do case "$1" in --only) ONLY=$2; shift 2;; --keep-parts) KEEP=1; shift;; *) echo "unknown argument: $1" >&2; exit 2;; esac; done
wanted() { # asset name
  case "$ONLY:$1" in
    all:*|iso:*.iso.part-*|wsl:*.wsl|apt:apt-pool*|runtime:language-runtimes*) return 0;; *) return 1;; esac; }
while IFS=$'\t' read -r name sha size kind target; do
  wanted "$name" || continue
  case "$kind" in part) [ -f "$target" ] && continue;; file) if [ -f "$target" ] && [ "$(sha256sum "$target" | cut -d' ' -f1)" = "$sha" ]; then continue; fi;; esac
  f="$DL/$name"
  if [ -f "$f" ] && [ "$(stat -c%s "$f")" = "$size" ] && [ "$(sha256sum "$f" | cut -d' ' -f1)" = "$sha" ]; then echo "have $name"; continue; fi
  echo "download $name"; curl -fL --retry 8 --retry-delay 5 --retry-all-errors -C - -o "$f" "$REPO_URL/$name"
  [ "$(sha256sum "$f" | cut -d' ' -f1)" = "$sha" ] || { echo "SHA256 mismatch: $name; delete it and re-run" >&2; exit 3; }
done < "$M"
join_parts() { # target name-prefix
  local t=$1 pre=$2; mkdir -p "$(dirname "$t")"
  compgen -G "$DL/$pre.part-*" >/dev/null || return 0
  echo "assemble $t"; cat "$DL/$pre".part-* > "$t.tmp" && mv "$t.tmp" "$t"
}
if [ "$ONLY" = all ] || [ "$ONLY" = wsl ]; then
  awk -F'\t' '$4=="file"{print $1"\t"$5}' "$M" | while IFS=$'\t' read -r n t; do [ -f "$DL/$n" ] || continue; mkdir -p "$(dirname "$t")"; mv "$DL/$n" "$t"; done
fi
if [ "$ONLY" = all ] || [ "$ONLY" = iso ]; then
  awk -F'\t' '$4=="part"{print $5}' "$M" | sort -u | while read -r t; do [ -f "$t" ] || join_parts "$t" "$(basename "$t")"; done
fi
if [ "$ONLY" = all ] || [ "$ONLY" = apt ]; then
  if compgen -G "$DL/apt-pool.tar.part-*" >/dev/null; then cat "$DL"/apt-pool.tar.part-* | tar -xf - -C .; fi
fi
if [ "$ONLY" = all ] || [ "$ONLY" = runtime ]; then
  [ -f "$DL/language-runtimes.tar" ] && tar -xf "$DL/language-runtimes.tar" -C .
fi
echo "checking against 12_CHECKSUMS_AND_METADATA/SHA256SUMS.txt"
sha256sum --quiet --ignore-missing -c 12_CHECKSUMS_AND_METADATA/SHA256SUMS.txt
[ "$KEEP" = 1 ] || rm -rf "$DL"
echo "OK. Licence-restricted files are .url placeholders: fetch them with 10_INSTALLATION_SCRIPTS/recovery/fetch_url_placeholders.sh"
