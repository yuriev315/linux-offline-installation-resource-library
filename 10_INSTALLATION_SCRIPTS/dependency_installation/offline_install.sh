#!/bin/bash
# Install from the local repository only. Safe to re-run. Reports missing dependencies; never forces.
# usage: sudo ./offline_install.sh [--deep-check] [--dry-run] [--list]
#                                  (--profile NAME | --group DIR | --packages "a b c")...
set -euo pipefail
. "$(cd "$(dirname "$0")" && pwd)/lib_offline.sh"
declare -A PROFILE=(
 [base]="05_SYSTEM_PACKAGES/base_system 05_SYSTEM_PACKAGES/system_management"
 [dev]="06_DEVELOPMENT_TOOLCHAIN/build_essentials 06_DEVELOPMENT_TOOLCHAIN/gcc_gpp 06_DEVELOPMENT_TOOLCHAIN/cmake 06_DEVELOPMENT_TOOLCHAIN/ninja 06_DEVELOPMENT_TOOLCHAIN/make 06_DEVELOPMENT_TOOLCHAIN/pkg_config 06_DEVELOPMENT_TOOLCHAIN/git 06_DEVELOPMENT_TOOLCHAIN/openssh 06_DEVELOPMENT_TOOLCHAIN/gdb"
 [llvm]="06_DEVELOPMENT_TOOLCHAIN/clang_llvm 08_SYSTEM_LIBRARIES/openmp"
 [cross]="06_DEVELOPMENT_TOOLCHAIN/cross_compilation"
 [python]="07_PYTHON_BASE_ENVIRONMENT/python_installers 07_PYTHON_BASE_ENVIRONMENT/pip 07_PYTHON_BASE_ENVIRONMENT/setuptools 07_PYTHON_BASE_ENVIRONMENT/wheel 07_PYTHON_BASE_ENVIRONMENT/virtualenv"
 [libs]="08_SYSTEM_LIBRARIES/openssl 08_SYSTEM_LIBRARIES/zlib 08_SYSTEM_LIBRARIES/libffi 08_SYSTEM_LIBRARIES/sqlite 08_SYSTEM_LIBRARIES/libxml 08_SYSTEM_LIBRARIES/libxslt 08_SYSTEM_LIBRARIES/blas 08_SYSTEM_LIBRARIES/lapack 08_SYSTEM_LIBRARIES/openmp 08_SYSTEM_LIBRARIES/protobuf 08_SYSTEM_LIBRARIES/other_libraries"
 [net]="09_NETWORK_AND_STORAGE_TOOLS/network_utilities 09_NETWORK_AND_STORAGE_TOOLS/ssh_sftp 09_NETWORK_AND_STORAGE_TOOLS/rsync 09_NETWORK_AND_STORAGE_TOOLS/curl_wget"
 [storage]="09_NETWORK_AND_STORAGE_TOOLS/disk_management 09_NETWORK_AND_STORAGE_TOOLS/filesystem_tools 09_NETWORK_AND_STORAGE_TOOLS/archive_tools 09_NETWORK_AND_STORAGE_TOOLS/monitoring"
 [kernel]="05_SYSTEM_PACKAGES/kernel 05_SYSTEM_PACKAGES/firmware"
 [vmware-guest]="03_VMWARE/open_vm_tools"
 [desktop]="05_SYSTEM_PACKAGES/desktop"
 [apt-tools]="04_APT_OFFLINE_REPOSITORY/package_manifests/apt_tools"
 [wsl-system]="02_WSL2/ubuntu_packages"
 [extras]="05_SYSTEM_PACKAGES/system_extras 03_VMWARE/open_vm_tools_extras 15_DEVELOPMENT_ENVIRONMENT/language_runtimes/rust_extras 15_DEVELOPMENT_ENVIRONMENT/language_runtimes/php_extras 15_DEVELOPMENT_ENVIRONMENT/language_runtimes/java_extras 15_DEVELOPMENT_ENVIRONMENT/c_cpp_more 15_DEVELOPMENT_ENVIRONMENT/python_more 15_DEVELOPMENT_ENVIRONMENT/editors/gui_editors"
)
PROFILE[c-cpp]="${PROFILE[dev]} ${PROFILE[llvm]} ${PROFILE[libs]} 06_DEVELOPMENT_TOOLCHAIN/c_cpp_extras"
PROFILE[python-dev]="${PROFILE[python]} 15_DEVELOPMENT_ENVIRONMENT/python_dev"
PROFILE[shell]="15_DEVELOPMENT_ENVIRONMENT/shell_tools"
PROFILE[languages]="15_DEVELOPMENT_ENVIRONMENT/language_runtimes/java 15_DEVELOPMENT_ENVIRONMENT/language_runtimes/go 15_DEVELOPMENT_ENVIRONMENT/language_runtimes/rust 15_DEVELOPMENT_ENVIRONMENT/language_runtimes/php"
PROFILE[editors]="15_DEVELOPMENT_ENVIRONMENT/editors/terminal_editors"
PROFILE[vscode-deps]="15_DEVELOPMENT_ENVIRONMENT/editors/vscode_dependencies"
PROFILE[debug]="15_DEVELOPMENT_ENVIRONMENT/debug_and_profiling"
PROFILE[fulldev]="${PROFILE[c-cpp]} ${PROFILE[python-dev]} ${PROFILE[shell]} ${PROFILE[languages]} ${PROFILE[editors]} ${PROFILE[debug]} ${PROFILE[net]} ${PROFILE[base]} ${PROFILE[storage]}"
PROFILE[server]="${PROFILE[base]} ${PROFILE[dev]} ${PROFILE[python]} ${PROFILE[libs]} ${PROFILE[net]} ${PROFILE[storage]}"
PROFILE[wsl]="${PROFILE[server]}"
PKGS=(); DRY=0; DEEP=""
add_group() { local f="$LIB_ROOT/$1/packages.list"; [ -f "$f" ] || die "unknown group: $1" 2; mapfile -t L < "$f"; PKGS+=("${L[@]}"); }
while [ $# -gt 0 ]; do case "$1" in
  --profile) [ -n "${PROFILE[${2:-}]:-}" ] || die "unknown profile: ${2:-} (try --list)" 2; for g in ${PROFILE[$2]}; do add_group "$g"; done; shift 2;;
  --group) add_group "${2:?}"; shift 2;;
  --packages) read -r -a L <<<"${2:?}"; PKGS+=("${L[@]}"); shift 2;;
  --dry-run) DRY=1; shift;;
  --deb) PKGS+=("$(realpath "${2:?}")"); shift 2;;
  --deep-check) DEEP=--deep; shift;;
  --list) printf 'profiles: %s\n' "${!PROFILE[*]}"; (cd "$LIB_ROOT" && find . -name packages.list | sed 's#^\./##; s#/packages.list##' | sort); exit 0;;
  -h|--help) sed -n 2,4p "$0"; exit 0;;
  *) die "unknown argument: $1" 2;;
esac; done
[ ${#PKGS[@]} -gt 0 ] || die "nothing selected. Use --profile, --group or --packages (--list shows them)." 2
need_root; check_target; check_repo_files "$DEEP"; prepare_runtime_source
mapfile -t PKGS < <(printf '%s\n' "${PKGS[@]}" | sort -u)
export DEBIAN_FRONTEND=noninteractive
log "packages requested: ${#PKGS[@]}"
apt-get "${APT_OPTS[@]}" update 2>&1 | tee -a "$LOG_FILE" >&2
# In a WSL or container system the HWE kernel etc. are simply not requested; profiles keep them separate.
if ! SIM=$(apt-get "${APT_OPTS[@]}" -s install "${PKGS[@]}" 2>&1); then
  printf '%s\n' "$SIM" | tee -a "$LOG_FILE" >&2
  die "dependency resolution failed: the local repository cannot satisfy this request. Nothing was changed." 20
fi
if [ "$DRY" = 1 ]; then printf '%s\n' "$SIM" | grep -E '^(Inst|[0-9]+ upgraded)' | tee -a "$LOG_FILE" >&2; log "dry run OK"; exit 0; fi
apt-get "${APT_OPTS[@]}" -y -o Dpkg::Options::=--force-confold -o Dpkg::Options::=--force-confdef install "${PKGS[@]}" 2>&1 | tee -a "$LOG_FILE" >&2
rc=${PIPESTATUS[0]}; [ "$rc" = 0 ] || die "apt-get install failed with status $rc" 21
dpkg --audit | tee -a "$LOG_FILE" >&2
broken=$(dpkg --audit | wc -l); [ "$broken" = 0 ] || die "dpkg reports unconfigured packages" 22
log "install complete: ${#PKGS[@]} requested packages present"
