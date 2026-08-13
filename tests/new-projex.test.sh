#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
scaffold="$root/new-projex.sh"
fixture="$root/tests/fixtures/new-projex-cases.tsv"
creators="$root/tests/fixtures/projex-creators.txt"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
repo="$tmp/repo"
mkdir -p "$repo/.projex/closed"

pass=0
fail=0
cases=0
check() { cases=$((cases + 1)); if "$@"; then pass=$((pass + 1)); else fail=$((fail + 1)); echo "FAIL: $*" >&2; fi; }
check_eq() { cases=$((cases + 1)); if [ "$1" = "$2" ]; then pass=$((pass + 1)); else fail=$((fail + 1)); echo "FAIL: expected '$1', got '$2'" >&2; fi; }
contains() { [[ "$1" == *"$2"* ]]; }
count_usage() { printf '%s\n' "$1" | awk '$0 ~ /^Usage: new-projex\.sh / {n++} END {print n + 0}'; }
snapshot() {
    {
        find "$repo" -mindepth 1 -printf '%y\t%P\n' | sort
        while IFS= read -r path; do
            printf 'hash\t%s\t' "$path"
            sha256sum "$repo/$path" | cut -d' ' -f1
        done < <(find "$repo" -type f -printf '%P\n' | sort)
    }
}

while IFS=$'\t' read -r id parent result; do
    [[ -n "$id" && "$id" != \#* ]] || continue
    title="matrix-$id"
    before=$(snapshot)
    if [ "$result" = success ]; then
        output=$(bash "$scaffold" --repo-root "$repo" --type plan --title "$title" --parent "$parent" --projex-dir ".projex/$id" 2>/dev/null)
        path=$(printf '%s\n' "$output" | sed -n '1p')
        check test -f "$path"
        check_eq 1 "$(awk '/^> \*\*Parent:\*\*/ { c++ } END { print c + 0 }' "$path")"
        check contains "$(cat "$path")" "> **Parent:** $parent"
    else
        set +e
        stdout=$(bash "$scaffold" --repo-root "$repo" --type plan --title "$title" --parent "$parent" --projex-dir ".projex/$id" 2>"$tmp/semantic.err")
        rc=$?
        set -e
        check test "$rc" -ne 0
        check_eq "$before" "$(snapshot)"
        check test -z "$stdout"
    fi
done < "$fixture"

# Default optional directory remains .projex.
default_output=$(bash "$scaffold" --repo-root "$repo" --type memo --title default-directory --parent User 2>/dev/null)
default_path=$(printf '%s\n' "$default_output" | sed -n '1p')
check contains "$default_path" "$repo/.projex/"
check test -f "$default_path"

assert_parser_reject() {
    local id=$1
    shift
    local before stdout stderr after rc usage_count
    before=$(snapshot)
    set +e
    stdout=$(bash "$scaffold" "$@" 2>"$tmp/$id.err")
    rc=$?
    set -e
    stderr=$(<"$tmp/$id.err")
    after=$(snapshot)
    usage_count=$(count_usage "$stderr")
    check_eq 2 "$rc"
    check_eq 1 "$usage_count"
    check test -z "$stdout"
    check_eq "$before" "$after"
}

# Every parser-negative case has a stable ID and verifies exit, stderr, stdout, and full state.
assert_parser_reject missing-repo --type plan --title bad --parent User
assert_parser_reject missing-type --repo-root "$repo" --title bad --parent User
assert_parser_reject missing-title --repo-root "$repo" --type plan --parent User
assert_parser_reject missing-parent --repo-root "$repo" --type plan --title bad
assert_parser_reject duplicate-repo --repo-root "$repo" --repo-root "$repo" --type plan --title bad --parent User
assert_parser_reject duplicate-type --repo-root "$repo" --type plan --type memo --title bad --parent User
assert_parser_reject duplicate-title --repo-root "$repo" --type plan --title bad --title worse --parent User
assert_parser_reject duplicate-parent --repo-root "$repo" --type plan --title bad --parent User --parent User
assert_parser_reject duplicate-projex-dir --repo-root "$repo" --type plan --title bad --parent User --projex-dir .projex --projex-dir .projex/other
assert_parser_reject missing-repo-value --repo-root --type plan --title bad --parent User
assert_parser_reject missing-type-value --repo-root "$repo" --type --title bad --parent User
assert_parser_reject missing-title-value --repo-root "$repo" --type plan --title --parent User
assert_parser_reject missing-parent-value --repo-root "$repo" --type plan --title bad --parent --projex-dir .projex
assert_parser_reject missing-projex-dir-value --repo-root "$repo" --type plan --title bad --parent User --projex-dir
assert_parser_reject unknown-option --repo-root "$repo" --type plan --title bad --parent User --unknown value
assert_parser_reject stray-positional "$repo" --type plan --title bad --parent User
assert_parser_reject legacy-positional "$repo" plan bad User .projex/legacy

stamp=$(date +%y%m%d%H%M)
self_name="${stamp}-self-check-plan.md"
before=$(snapshot)
set +e
bash "$scaffold" --repo-root "$repo" --type plan --title self-check --parent "$self_name" --projex-dir .projex/self >/dev/null 2>"$tmp/self.err"
rc=$?
set -e
check test "$rc" -eq 2
check_eq "$before" "$(snapshot)"

collision_name="${stamp}-collision-check-plan.md"
printf '# existing\n' > "$repo/.projex/closed/$collision_name"
before=$(snapshot)
set +e
bash "$scaffold" --repo-root "$repo" --type plan --title collision-check --parent User --projex-dir .projex/collision >/dev/null 2>"$tmp/collision.err"
rc=$?
set -e
check test "$rc" -eq 2
check_eq "$before" "$(snapshot)"

actual="$tmp/actual-creators"
: > "$actual"
for file in "$root"/*-projex.md; do
    content=$(<"$file")
    if [[ "$content" == *new-projex.sh* ]]; then printf 'scaffold:%s\n' "$(basename "$file")" >> "$actual"; fi
done
for file in execute-projex.md close-projex.md debug-projex.md sprint-projex.md; do printf 'manual:%s\n' "$file" >> "$actual"; done
check diff -u <(sort "$creators") <(sort "$actual")
for file in "$root"/*-projex.md; do
    shell_count=$(awk '/new-projex\.sh/ {n++} END {print n + 0}' "$file")
    ps_count=$(awk '/new-projex\.ps1/ {n++} END {print n + 0}' "$file")
    if [ "$shell_count" -gt 0 ]; then
        check_eq 1 "$shell_count"
        check_eq 1 "$ps_count"
        bad=$(awk '/new-projex\.sh/ && ($0 !~ /--repo-root/ || $0 !~ /--type/ || $0 !~ /--title/ || $0 !~ /--parent/ || $0 !~ /--projex-dir/) {n++} END {print n + 0}' "$file")
        check_eq 0 "$bad"
        bad=$(awk '/new-projex\.ps1/ && ($0 !~ /-RepoRoot/ || $0 !~ /-Type/ || $0 !~ /-Title/ || $0 !~ /-Parent/ || $0 !~ /-ProjexDir/) {n++} END {print n + 0}' "$file")
        check_eq 0 "$bad"
    fi
done
check contains "$(<"$root/execute-projex.md")" '> **Parent:** {plan-filename}'
check contains "$(<"$root/close-projex.md")" '> **Parent:** [plan filename]'
check contains "$(<"$root/debug-projex.md")" '> **Parent:** {debug-parent}'
check contains "$(<"$root/debug-projex.md")" '> **Parent:** {debug-log-filename}'
check contains "$(<"$root/sprint-projex.md")" '> **Parent:** {sprint-parent}'

printf 'PASS=%d FAIL=%d\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
