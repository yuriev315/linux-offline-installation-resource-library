#!/bin/bash
# User-side check, on Linux. Verifies checksums, package readability and the repository chain of trust.
# Files absent by design (VS Code items, VMware installer) are skipped, not failed.
# usage: verify_library.sh [LIB_ROOT]
LIB=${1:-$(cd "$(dirname "$0")/../.." && pwd)}; cd "$LIB" || exit 1; rc=0
echo "== SHA256SUMS"; sha256sum --quiet --ignore-missing -c 12_CHECKSUMS_AND_METADATA/SHA256SUMS.txt || rc=1
echo "== official ISO/WSL checksum signature"
(cd 01_UBUNTU_ISO/SHA256SUMS && gpgv --keyring ../../04_APT_OFFLINE_REPOSITORY/repository_keys/ubuntu-cdimage-key.gpg SHA256SUMS.gpg SHA256SUMS 2>&1 | grep -E 'Good|BAD|Can.t') || rc=1
echo "== .deb files readable"; n=0
while IFS= read -r -d '' f; do n=$((n+1)); dpkg-deb --info "$f" >/dev/null 2>&1 || { echo "BAD DEB: $f"; rc=1; }; done < <(find 04_APT_OFFLINE_REPOSITORY/pool -name '*.deb' -print0)
echo "$n read"
echo "== chain of trust"; python3 -I 10_INSTALLATION_SCRIPTS/integrity_verification/verify_repo_against_official.py "$LIB" | tail -1
[ "${PIPESTATUS[0]}" = 0 ] || rc=1
echo "== shell syntax"; while IFS= read -r -d '' f; do bash -n "$f" || rc=1; done < <(find 10_INSTALLATION_SCRIPTS 13_TESTS -name '*.sh' -print0)
[ $rc = 0 ] && echo "RESULT: OK" || echo "RESULT: PROBLEMS FOUND"; exit $rc
