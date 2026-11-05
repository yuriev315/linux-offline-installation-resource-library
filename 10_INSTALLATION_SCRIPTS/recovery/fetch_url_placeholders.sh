#!/bin/bash
# ONLINE step. Fetch the licence-restricted files named by the .url placeholders, directly from their publishers,
# and check each SHA256. Files that need a sign-in are listed for you to download by hand. Safe to re-run.
# usage: fetch_url_placeholders.sh [--only vmware|wsl|vscode]
set -uo pipefail
LIB=$(cd "$(dirname "$0")/../.." && pwd); cd "$LIB" || exit 1
ONLY=""; [ "${1:-}" = --only ] && ONLY=${2:?}
case "$ONLY" in vmware) ROOTS=(03_VMWARE);; wsl) ROOTS=(02_WSL2);; vscode) ROOTS=(15_DEVELOPMENT_ENVIRONMENT);; "") ROOTS=(02_WSL2 03_VMWARE 15_DEVELOPMENT_ENVIRONMENT);; *) echo "unknown: $ONLY" >&2; exit 2;; esac
ok=0; manual=0; fail=0
field() { tr -d '\r' < "$1" | sed -n "s/^$2=//p" | head -1; }
while IFS= read -r -d '' u; do
  dst=${u%.url}; want=$(field "$u" SHA256); url=$(field "$u" URL)
  if [ -f "$dst" ] && [ "$(sha256sum "$dst" | cut -d' ' -f1)" = "$want" ]; then echo "have      $dst"; ok=$((ok+1)); continue; fi
  if [ "$(field "$u" DirectDownload)" != yes ]; then echo "BY HAND   $dst"; echo "          $url"; echo "          SHA256 must be $want"; manual=$((manual+1)); continue; fi
  echo "download  $dst"
  if curl -fL --retry 5 --retry-delay 5 --compressed -o "$dst.part" "$url" && [ "$(sha256sum "$dst.part" | cut -d' ' -f1)" = "$want" ]; then mv -f "$dst.part" "$dst"; ok=$((ok+1))
  else echo "FAILED    $dst (download error or SHA256 mismatch; the publisher may have replaced this version)" >&2; fail=$((fail+1)); fi
done < <(find "${ROOTS[@]}" -name '*.url' -print0 | sort -z)
echo "ready=$ok by_hand=$manual failed=$fail"; [ "$fail" = 0 ]
