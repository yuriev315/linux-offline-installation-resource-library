#!/bin/bash
# usage: fetch.sh URL DEST [sha256]  — resumable, retrying, skips verified files, refuses to run below the free-space floor.
R=${LIB_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}
LOG=$R/14_LOGS_AND_REPORTS/download.log; ERR=$R/14_LOGS_AND_REPORTS/errors.log
FLOOR_GB=${FLOOR_GB:-120}
url=$1; dest=$2; want=${3:-}
ts(){ date -u +%FT%TZ; }
free=$(df --output=avail -BG "$R" | tail -1 | tr -dc 0-9)
if [ "$free" -lt "$FLOOR_GB" ]; then echo "$(ts) STOP free=${free}G floor=${FLOOR_GB}G $url" | tee -a "$ERR" "$LOG"; exit 75; fi
if [ -f "$dest" ] && [ -n "$want" ] && [ "$(sha256sum "$dest"|cut -d' ' -f1)" = "$want" ]; then echo "$(ts) SKIP-verified $dest" >>"$LOG"; exit 0; fi
mkdir -p "$(dirname "$dest")"
echo "$(ts) START $url -> $dest" >>"$LOG"
ionice -c2 -n7 nice -n10 curl -fL --retry 8 --retry-delay 5 --retry-all-errors --connect-timeout 30 -C - -sS -A 'offline-library-builder' -o "$dest" "$url" 2>>"$ERR"; rc=$?
if [ $rc -ne 0 ]; then echo "$(ts) FAIL rc=$rc $url" | tee -a "$ERR" "$LOG"; exit $rc; fi
if [ -n "$want" ]; then got=$(sha256sum "$dest"|cut -d' ' -f1); if [ "$got" != "$want" ]; then echo "$(ts) SHA-MISMATCH $dest got=$got want=$want" | tee -a "$ERR" "$LOG"; exit 2; fi; fi
echo "$(ts) OK $(stat -c%s "$dest") $dest" >>"$LOG"
