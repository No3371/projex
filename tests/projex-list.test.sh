#!/usr/bin/env bash
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
list="$root/projex-list.sh"
fixture="$root/tests/fixtures/projex-list/basic"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
repo="$tmp/repo"
cp -R "$fixture" "$repo"
rm -f "$repo"/expected-*.stdout
pass=0; fail=0; cases=0
check() { cases=$((cases + 1)); if "$@"; then pass=$((pass + 1)); else fail=$((fail + 1)); echo "FAIL: $*" >&2; fi; }
check_eq() { cases=$((cases + 1)); if [ "$1" = "$2" ]; then pass=$((pass + 1)); else fail=$((fail + 1)); echo "FAIL: expected '$1', got '$2'" >&2; fi; }
run_golden() {
    local golden=$1; shift
    local out="$tmp/out" err="$tmp/err" rc
    set +e; "$list" "$repo" "$@" >"$out" 2>"$err"; rc=$?; set -e
    check_eq 0 "$rc"; check cmp "$fixture/$golden" "$out"; check test ! -s "$err"
}
run_usage() {
    local out="$tmp/out" err="$tmp/err" rc
    set +e; "$list" "$@" >"$out" 2>"$err"; rc=$?; set -e
    check_eq 2 "$rc"; check test ! -s "$out"; check grep -q 'projex-list: E_USAGE:' "$err"
}

# nested repos and worktrees are never walked
mkdir -p "$repo/nested/.git" "$repo/nested/.projex" "$repo/.projexwt/wt/.projex"
printf '# N\n\n> **Status:** Draft\n' > "$repo/nested/.projex/2609090000-nested-plan.md"
printf '# W\n\n> **Status:** Draft\n' > "$repo/.projexwt/wt/.projex/2609090001-worktree-plan.md"

run_golden expected-default.stdout
run_golden expected-closed-abandoned.stdout --closed --abandoned
run_golden expected-closed-abandoned.stdout --abandoned --closed
run_golden expected-all.stdout --all
run_golden expected-all.stdout --closed --all

run_usage
run_usage --all
run_usage "$repo" --bogus
run_usage "$repo" extra
set +e; "$list" "$tmp/missing" >"$tmp/out" 2>"$tmp/err"; rc=$?; set -e
check_eq 2 "$rc"; check test ! -s "$tmp/out"; check grep -q 'projex-list: E_REPO:' "$tmp/err"

# BOM + CRLF header still parses
bom="$tmp/bom"
mkdir -p "$bom/.projex"
printf '\357\273\277# BOM\r\n\r\n> **Status:** In Progress\r\n---\r\n' > "$bom/.projex/2609000005-bom-plan.md"
set +e; "$list" "$bom" >"$tmp/out" 2>"$tmp/err"; rc=$?; set -e
check_eq 0 "$rc"
check_eq 'status: In Progress' "$(sed -n 5p "$tmp/out")"

# empty corpus prints nothing
mkdir -p "$tmp/empty"
set +e; "$list" "$tmp/empty" >"$tmp/out" 2>"$tmp/err"; rc=$?; set -e
check_eq 0 "$rc"; check test ! -s "$tmp/out"

echo "PASS=$pass FAIL=$fail"
[ "$fail" -eq 0 ]
