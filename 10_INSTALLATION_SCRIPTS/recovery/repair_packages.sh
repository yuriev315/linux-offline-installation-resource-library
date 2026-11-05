#!/bin/bash
# Repair an interrupted dpkg/apt state using only the local repository.
set -euo pipefail
. "$(cd "$(dirname "$0")/../dependency_installation" && pwd)/lib_offline.sh"
need_root; check_target; check_repo_files; prepare_runtime_source
export DEBIAN_FRONTEND=noninteractive
dpkg --configure -a 2>&1 | tee -a "$LOG_FILE"
apt-get "${APT_OPTS[@]}" update 2>&1 | tee -a "$LOG_FILE"
apt-get "${APT_OPTS[@]}" -y -f install 2>&1 | tee -a "$LOG_FILE"
dpkg --audit | tee -a "$LOG_FILE"
log "repair finished"
