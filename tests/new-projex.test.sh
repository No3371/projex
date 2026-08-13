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
check() {
    cases=$((cases + 1))
    if "$@"; then pass=$((pass + 1)); else fail=$((fail + 1)); echo "FAIL: $*" >&2; fi
}
contains() { [[ "$1" == *"$2"* ]]; }
check_eq() {
    cases=$((cases + 1))
    if [ "$1" = "$2" ]; then pass=$((pass + 1)); else fail=$((fail + 1)); echo "FAIL: expected '$1', got '$2'" >&2; fi
}

while IFS=$'\t' read -r id parent result; do
    [[ -n "$id" && "$id" != \#* ]] || continue
    title="matrix-$id"
    before=$(find "$repo" -type f -name '*.md' | wc -l)
    if [ "$result" = success ]; then
        output=$("$scaffold" "$repo" plan "$title" "$parent" ".projex/$id" 2>/dev/null)
        path=$(printf '%s\n' "$output" | sed -n '1p')
        check test -f "$path"
        check_eq 1 "$(awk '/^> \*\*Parent:\*\*/ { c++ } END { print c + 0 }' "$path")"
        check contains "$(cat "$path")" "> **Parent:** $parent"
    else
        set +e
        "$scaffold" "$repo" plan "$title" "$parent" ".projex/$id" >/dev/null 2>&1
        rc=$?
        set -e
        after=$(find "$repo" -type f -name '*.md' | wc -l)
        check test "$rc" -ne 0
        check_eq "$before" "$after"
    fi
done < "$fixture"
stamp=$(date +%y%m%d%H%M)
self_name="${stamp}-self-check-plan.md"
before=$(find "$repo" -type f -name '*.md' | wc -l)
set +e
"$scaffold" "$repo" plan "self-check" "$self_name" ".projex/self" >/dev/null 2>&1
rc=$?
set -e
check test "$rc" -ne 0
check_eq "$before" "$(find "$repo" -type f -name '*.md' | wc -l)"

set +e
"$scaffold" "$repo" plan "extra-operand" User ".projex/extra" unexpected >/dev/null 2>&1
rc=$?
set -e
check test "$rc" -ne 0

collision_name="${stamp}-collision-check-plan.md"
printf '# existing\n' > "$repo/.projex/closed/$collision_name"
before=$(find "$repo" -type f -name '*.md' | wc -l)
set +e
"$scaffold" "$repo" plan "collision-check" User ".projex/collision" >/dev/null 2>&1
rc=$?
set -e
check test "$rc" -ne 0
check_eq "$before" "$(find "$repo" -type f -name '*.md' | wc -l)"

# Assert the closed creator inventory and migrated arity from workflow specs.
actual="$tmp/actual-creators"
: > "$actual"
for file in "$root"/*-projex.md; do
    content=$(<"$file")
    if [[ "$content" == *new-projex* ]]; then printf 'scaffold:%s\n' "$(basename "$file")" >> "$actual"; fi
done
for file in execute-projex.md close-projex.md debug-projex.md sprint-projex.md; do
    printf 'manual:%s\n' "$file" >> "$actual"
done
check diff -u <(sort "$creators") <(sort "$actual")
for file in "$root"/*-projex.md; do
    while IFS= read -r line; do
        if [[ "$line" == *new-projex*'<projex-folder>'* ]]; then
            check contains "$line" "{parent}"
        fi
    done < "$file"
done
check contains "$(<"$root/execute-projex.md")" '> **Parent:** {plan-filename}'
check contains "$(<"$root/close-projex.md")" '> **Parent:** [plan filename]'
check contains "$(<"$root/debug-projex.md")" '> **Parent:** {debug-parent}'
check contains "$(<"$root/debug-projex.md")" '> **Parent:** {debug-log-filename}'
check contains "$(<"$root/sprint-projex.md")" '> **Parent:** {sprint-parent}'

printf 'PASS=%d FAIL=%d CASES=%d\n' "$pass" "$fail" "$cases"
[ "$fail" -eq 0 ]
