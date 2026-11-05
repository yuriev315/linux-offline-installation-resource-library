#!/bin/bash
# Build and run every sample. Each check prints PASS, FAIL or SKIP; exit code is the FAIL count.
# usage: verify_dev_environment.sh [--report FILE]
LIB_ROOT="${LIB_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"; S="$LIB_ROOT/15_DEVELOPMENT_ENVIRONMENT/samples"
REPORT=""; [ "${1:-}" = --report ] && REPORT=$2
[ -f /etc/profile.d/linux-offline-dev-paths.sh ] && . /etc/profile.d/linux-offline-dev-paths.sh
W=$(mktemp -d); trap 'rm -rf "$W"' EXIT; cd "$W" || exit 99
export HOME="$W/home"; mkdir -p "$HOME"; export GOFLAGS=-mod=mod GOPROXY=off GOCACHE="$W/gocache" GOTOOLCHAIN=local
P=0; F=0; K=0
out() { echo "$1 $2${3:+  ($3)}"; [ -z "$REPORT" ] || echo "$1,$2,$3" >> "$REPORT"; }
check() { # check NAME EXPECTED_TEXT COMMAND...
  local n=$1 want=$2; shift 2; local o rc f="$W/.check_output"
  # Output goes to a file: a leftover child holding a pipe open must not hang the whole run.
  timeout -k 10 "${CHECK_TIMEOUT:-300}" "$@" >"$f" 2>&1 </dev/null; rc=$?; o=$(cat "$f")
  if [ $rc = 0 ] && { [ -z "$want" ] || grep -qF -- "$want" <<<"$o"; }; then out PASS "$n" "$(head -1 <<<"$o" | cut -c1-90 | tr -d ',')"; P=$((P+1));
  else out FAIL "$n" "rc=$rc $(tail -2 <<<"$o" | cut -c1-160 | tr '\n,' ' ')"; F=$((F+1)); fi; }
skip() { out SKIP "$1" "$2"; K=$((K+1)); }
# C / C++
check gcc-c "hello from c" bash -c "gcc -g -Wall -o c_hello '$S/c/hello.c' && ./c_hello"
check gpp-cpp "hello from c++" bash -c "g++ -g -std=c++17 -o cpp_hello '$S/cpp/hello.cpp' && ./cpp_hello"
check clang-c "hello from c" bash -c "clang -o cl_hello '$S/c/hello.c' && ./cl_hello"
check clangpp-cpp "hello from c++" bash -c "clang++ -stdlib=libstdc++ -o clpp_hello '$S/cpp/hello.cpp' && ./clpp_hello"
check lld-link "hello from c" bash -c "clang -fuse-ld=lld -o lld_hello '$S/c/hello.c' && ./lld_hello"
check ccache "hello from c" bash -c "ccache gcc -o cc_hello '$S/c/hello.c' && ./cc_hello"
check make "hello from make" bash -c "printf 'all:\n\t@echo hello from make\n' > Makefile && make"
check autotools "" bash -c "autoconf --version && automake --version && libtool --version"
check pkg-config "" bash -c "pkg-config --exists openssl zlib libffi sqlite3 libcurl libxml-2.0 libxslt protobuf libevent"
check openssl-link "" bash -c "printf '#include <openssl/evp.h>\n#include <zlib.h>\n#include <ffi.h>\n#include <sqlite3.h>\n#include <curl/curl.h>\nint main(void){return EVP_sha256()==0 || zlibVersion()==0 || sqlite3_libversion()==0 || curl_version()==0;}' > l.c && gcc l.c -o l \$(pkg-config --cflags --libs openssl zlib libffi sqlite3 libcurl) && ./l"
check blas-lapack "" bash -c "printf 'extern void dgesv_(int*,int*,double*,int*,int*,double*,int*,int*);int main(void){int n=1,r=1,p,i;double a=2,b=4;dgesv_(&n,&r,&a,&n,&p,&b,&n,&i);return !(b==2);}' > la.c && gcc la.c -o la -llapack -lblas && ./la"
check protobuf "" bash -c "printf 'syntax=\"proto3\";message M{int32 a=1;}' > m.proto && protoc --cpp_out=. m.proto && test -f m.pb.cc"
check cmake-ninja-ctest "100% tests passed" bash -c "cmake -S '$S/cmake' -B cm -G Ninja >/dev/null && cmake --build cm >/dev/null && ./cm/hello && ctest --test-dir cm"
# debuggers and profilers
check gdb "hello from c" bash -c "gdb -q -batch -ex run ./c_hello"
check lldb "hello from c" bash -c "lldb -b -o run ./c_hello"
check valgrind "ERROR SUMMARY: 0" bash -c "valgrind ./c_hello"
check strace "execve" bash -c "strace ./c_hello"
check ltrace "" bash -c "ltrace -V"
check gcov "Lines executed:100" bash -c "gcc --coverage -o gc '$S/c/hello.c' && ./gc && gcov gc-hello.c"
check gprof "Flat profile" bash -c "gcc -pg -o gp '$S/c/hello.c' && ./gp >/dev/null && gprof -b ./gp gmon.out"
check lcov "" bash -c "lcov --version"
PERF=$(ls /usr/lib/linux-tools/*/perf 2>/dev/null | head -1)
if [ -n "$PERF" ]; then check perf "perf version" "$PERF" --version; else skip perf "linux-tools not installed"; fi
# Python
check python3.12 "hello from python" python3 "$S/python/hello.py"
check system-python-intact "" bash -c "test \"\$(readlink -f /usr/bin/python3)\" = /usr/bin/python3.12"
check venv-wheelhouse "venv ready" bash "$LIB_ROOT/10_INSTALLATION_SCRIPTS/dependency_installation/python_offline_env.sh" "$W/v" pytest pytest-cov build virtualenv py-spy
check pytest-from-wheels "1 passed" "$W/v/bin/python" -m pytest -q -p no:cacheprovider "$S/python/test_hello.py"
check virtualenv-from-wheels "" bash -c "'$W/v/bin/python' -m virtualenv --no-download v2 && v2/bin/python --version"
check python-cprofile "function calls" python3 -m cProfile "$S/python/hello.py"
check python3-dbg "" python3-dbg -c "import sys; assert hasattr(sys, 'gettotalrefcount')"
check python-apt-pytest "" python3 -m pytest --version
check pyspy-installed "py-spy" "$W/v/bin/py-spy" --version
# Shell
check bash "hello from bash" bash "$S/shell/hello.sh" bash
check zsh "zsh" zsh --version
check shellcheck "" shellcheck "$S/shell/hello.sh"
check shellcheck-catches-bad "SC2086" bash -c "printf '#!/bin/bash\necho \$1\n' > b.sh; shellcheck b.sh || true"
check shfmt "" shfmt -d "$S/shell/hello.sh"
check jq "2" bash -c "echo '{\"a\":2}' | jq .a"
check yq "2" bash -c "printf 'a: 2\n' | yq .a"
check perl "hello from perl" perl "$S/perl/hello.pl"
check ruby "hello from ruby" ruby "$S/ruby/hello.rb"
check expect "ok" expect -c 'puts ok'
# Git
check git "initial" bash -c "git init -q r && cd r && git config user.email t@example.invalid && git config user.name t && echo x>a && git add a && git commit -qm initial && git log --oneline"
check git-lfs "git-lfs" git lfs version
check tig "" tig --version
# Languages
check java "hello from java" bash -c "javac -d jv '$S/java/Hello.java' && java -cp jv Hello"
if command -v node >/dev/null; then check node "hello from node" node "$S/node/hello.js"; check npm "" npm --version; check npm-local "" bash -c "mkdir -p np && cd np && npm init -y --silent >/dev/null && npm pack --silent >/dev/null"; else skip node "Node.js not installed (run install_dev_environment.sh)"; fi
check go "hello from go go1.26" bash -c "cp -r '$S/go' g && cd g && go run ."
check rust-rustc "hello from rust" bash -c "rustc -o rs '$S/rust/hello.rs' && ./rs"
check rust-cargo "hello from cargo" bash -c "cargo new --vcs none cg --name cg >/dev/null 2>&1; sed -i 's/Hello, world!/hello from cargo/' cg/src/main.rs; cd cg && cargo run --offline -q"
check php "hello from php" php "$S/php/hello.php"
# Editors
check vim "VIM" vim --version
check neovim "NVIM" nvim --version
check emacs "GNU Emacs" emacs --version
if command -v code >/dev/null; then check vscode "" code --version --user-data-dir "$W/vs" --no-sandbox; else skip vscode "VS Code not installed (install_vscode.sh)"; fi
echo "RESULT PASS=$P FAIL=$F SKIP=$K"; [ -z "$REPORT" ] || echo "RESULT,PASS=$P FAIL=$F SKIP=$K," >> "$REPORT"
exit "$F"
