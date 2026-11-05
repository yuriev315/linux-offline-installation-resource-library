#!/bin/bash
# ONLINE step: fetch VS Code, VS Code Server and the extensions directly from Microsoft, checking SHA256.
# The repository only has .url placeholders, because Microsoft's license does not allow redistribution.
# recovery/fetch_url_placeholders.sh does the same for every restricted file.
set -euo pipefail
LIB_ROOT="${LIB_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"; E="$LIB_ROOT/15_DEVELOPMENT_ENVIRONMENT/editors"
mkdir -p "$E/vscode" "$E/vscode_server" "$E/vsix"
while read -r sub name sha url; do
  [ -z "${sub:-}" ] && continue
  dst="$E/$sub/$name"
  [ -f "$dst" ] && [ "$(sha256sum "$dst" | cut -d' ' -f1)" = "$sha" ] && { echo "OK (already): $name"; continue; }
  curl -fL --retry 5 -C - --compressed -o "$dst" "$url"
  [ "$(sha256sum "$dst" | cut -d' ' -f1)" = "$sha" ] || { echo "SHA256 mismatch: $name" >&2; exit 2; }
  echo "OK: $name"
done < "$E/ASSETS.txt"
