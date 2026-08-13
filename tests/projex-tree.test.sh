#!/usr/bin/env bash
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
tree="$root/projex-tree.sh"
fixture="$root/tests/fixtures/projex-tree/basic"
duplicate_fixture="$root/tests/fixtures/projex-tree/duplicate-parent"
invalid_utf8_fixture="$root/tests/fixtures/projex-tree/invalid-utf8"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
repo="$tmp/repo"
cp -R "$fixture" "$repo"
pass=0; fail=0; cases=0
mkdir -p "$repo/.projex/closed"
check() { cases=$((cases + 1)); if "$@"; then pass=$((pass + 1)); else fail=$((fail + 1)); echo "FAIL: $*" >&2; fi; }
check_eq() { cases=$((cases + 1)); if [ "$1" = "$2" ]; then pass=$((pass + 1)); else fail=$((fail + 1)); echo "FAIL: expected '$1', got '$2'" >&2; fi; }
run_basic() {
    local name=$1 out="$tmp/out" err="$tmp/err" rc
    set +e; "$tree" "$repo" "$name" >"$out" 2>"$err"; rc=$?; set -e
    check_eq 0 "$rc"; check cmp "$fixture/expected.stdout" "$out"; check test ! -s "$err"
}
run_basic 2608051553-feature-proposal.md
run_basic 2608052327-feature-plan.md
run_basic 2608052327-feature-log.md

cat > "$repo/.projex/2609000000-malformed-plan.md" <<'EOF'
# malformed
> **Parent:** bad/path.md
---
EOF
run_basic 2608051553-feature-proposal.md
run_error() {
    local name=$1 code=$2 detail=$3 out="$tmp/out" err="$tmp/err" rc
    set +e; "$tree" "$repo" "$name" >"$out" 2>"$err"; rc=$?; set -e
    check_eq 3 "$rc"; check test ! -s "$out"; check grep -q "projex-tree: $code:" "$err"
    check grep -q "$detail" "$err"
}
run_error 2609000000-malformed-plan.md E_PARENT_MALFORMED 'bad/path.md'
cat > "$repo/.projex/2609000001-dangling-plan.md" <<'EOF'
# dangling
> **Parent:** 2609000009-missing-plan.md
---
EOF
run_error 2609000001-dangling-plan.md E_PARENT_DANGLING 'missing-plan.md'
cat > "$repo/.projex/2609000002-self-plan.md" <<'EOF'
# self
> **Parent:** 2609000002-self-plan.md
---
EOF
run_error 2609000002-self-plan.md E_PARENT_SELF 'names the document itself'
cat > "$repo/.projex/2609000003-cycle-a-plan.md" <<'EOF'
# a
> **Parent:** 2609000004-cycle-b-plan.md
---
EOF
cat > "$repo/.projex/2609000004-cycle-b-plan.md" <<'EOF'
# b
> **Parent:** 2609000003-cycle-a-plan.md
---
EOF
run_error 2609000003-cycle-a-plan.md E_CYCLE 'Parent chain cycles'
cp "$duplicate_fixture/input.md" "$repo/.projex/2609000006-duplicate-child-plan.md"
set +e; "$tree" "$repo" 2608051553-feature-proposal.md >"$tmp/out" 2>"$tmp/err"; rc=$?; set -e
check_eq "$(tr -d '\n' < "$duplicate_fixture/expected.exit")" "$rc"
check test ! -s "$tmp/out"
check cmp "$duplicate_fixture/expected.stderr" "$tmp/err"
cp "$repo/.projex/2608051553-feature-proposal.md" "$repo/.projex/closed/2608051553-feature-proposal.md"
set +e; "$tree" "$repo" 2608051553-feature-proposal.md >"$tmp/out" 2>"$tmp/err"; rc=$?; set -e
check_eq 2 "$rc"; check test ! -s "$tmp/out"; check grep -q 'E_TARGET_AMBIGUOUS' "$tmp/err"
set +e; "$tree" "$repo" missing.md >"$tmp/out" 2>"$tmp/err"; rc=$?; set -e
check_eq 2 "$rc"; check test ! -s "$tmp/out"; check grep -q 'E_TARGET_NOT_FOUND' "$tmp/err"
set +e; "$tree" "$repo" .projex/2608051553-feature-proposal.md >"$tmp/out" 2>"$tmp/err"; rc=$?; set -e
check_eq 2 "$rc"; check test ! -s "$tmp/out"; check grep -q 'E_TARGET_NAME' "$tmp/err"
mkdir -p "$repo/.projex/crlf"
printf '\357\273\277# BOM\r\n> **Parent:** User\r\n---\r\n' > "$repo/.projex/crlf/2609000005-bom-root-plan.md"
set +e; "$tree" "$repo" 2609000005-bom-root-plan.md >"$tmp/out" 2>"$tmp/err"; rc=$?; set -e
check_eq 0 "$rc"; check cmp <(printf '2609000005-bom-root-plan.md\n') "$tmp/out"; check test ! -s "$tmp/err"
printf '\377' > "$repo/.projex/2609000007-invalid-utf8-plan.md"
set +e; "$tree" "$repo" 2609000007-invalid-utf8-plan.md >"$tmp/out" 2>"$tmp/err"; rc=$?; set -e
check_eq "$(tr -d '\n' < "$invalid_utf8_fixture/expected.exit")" "$rc"
check test ! -s "$tmp/out"
check cmp "$invalid_utf8_fixture/expected.stderr" "$tmp/err"
printf 'PASS=%d FAIL=%d CASES=%d\n' "$pass" "$fail" "$cases"
[ "$fail" -eq 0 ]
