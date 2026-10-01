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

fixtures="$root/tests/fixtures/projex-tree"
usage_line='projex-tree: E_USAGE: invocation: expected <repo-root> <filename>'
expect() {
    local label=$1 code=$2 want_out=$3 want_err=$4 rc
    shift 4
    # stdin from /dev/null: the engine's children would otherwise drain the utf8-cases.tsv read loop's stdin, ending it after one row
    set +e; "$tree" "$@" </dev/null >"$tmp/out" 2>"$tmp/err"; rc=$?; set -e
    cases=$((cases + 3))
    if [ "$rc" = "$code" ]; then pass=$((pass + 1)); else fail=$((fail + 1)); echo "FAIL: $label: exit $rc, expected $code" >&2; fi
    if cmp -s "$want_out" "$tmp/out"; then pass=$((pass + 1)); else fail=$((fail + 1)); echo "FAIL: $label: stdout" >&2; fi
    if cmp -s "$want_err" "$tmp/err"; then pass=$((pass + 1)); else fail=$((fail + 1)); echo "FAIL: $label: stderr" >&2; fi
}
want() { printf "$@" > "$tmp/want"; }
copy_fixture() { rm -rf "$tmp/fx"; cp -R "$fixtures/$1" "$tmp/fx"; }
doc() { mkdir -p "$(dirname "$1")"; printf '# t\n> **Parent:** %s\n---\n' "$2" > "$1"; }
is_windows() { case $(uname -s) in MINGW* | MSYS* | CYGWIN*) return 0 ;; esac; return 1; }
deny() {
    if is_windows; then MSYS2_ARG_CONV_EXCL='*' icacls "$(cygpath -w "$1")" /deny "$USERNAME:($2)" >/dev/null 2>&1
    elif [ "$(id -u)" -ne 0 ]; then chmod 000 "$1"
    else return 1; fi
}
allow() {
    if is_windows; then MSYS2_ARG_CONV_EXCL='*' icacls "$(cygpath -w "$1")" /remove:d "$USERNAME" >/dev/null 2>&1 || true
    else chmod 755 "$1" 2>/dev/null || true; fi
}
skip() { echo "SKIP $1: $2"; }

# nested .projex inside a .projex root is walked once
copy_fixture nested-projex
expect nested-projex-root 0 "$fixtures/nested-projex/expected.stdout" /dev/null "$tmp/fx" 2609100000-root-proposal.md
expect nested-projex-inner 0 "$fixtures/nested-projex/expected.stdout" /dev/null "$tmp/fx" 2609100001-inner-plan.md

# nested repositories (.git dir or file below the root) are pruned; .GIT is not .git
copy_fixture nested-repo
expect nested-repo-none 0 "$fixtures/nested-repo/expected.stdout" /dev/null "$tmp/fx" 2609110000-host-proposal.md
mkdir "$tmp/fx/vendor/.git"
expect nested-repo-dir 0 "$fixtures/nested-repo/expected-pruned.stdout" /dev/null "$tmp/fx" 2609110000-host-proposal.md
expect nested-repo-dir-target 2 /dev/null "$fixtures/nested-repo/expected-vendored-pruned.stderr" "$tmp/fx" 2609110001-vendored-plan.md
rmdir "$tmp/fx/vendor/.git"
printf 'gitdir: x\n' > "$tmp/fx/vendor/.git"
expect nested-repo-file 0 "$fixtures/nested-repo/expected-pruned.stdout" /dev/null "$tmp/fx" 2609110000-host-proposal.md
expect nested-repo-file-target 2 /dev/null "$fixtures/nested-repo/expected-vendored-pruned.stderr" "$tmp/fx" 2609110001-vendored-plan.md
rm "$tmp/fx/vendor/.git"
mkdir "$tmp/fx/vendor/.GIT"
expect nested-repo-upper 0 "$fixtures/nested-repo/expected.stdout" /dev/null "$tmp/fx" 2609110000-host-proposal.md

# an undiscovered Parent becomes the "(missing)" root; documents naming it are its children
copy_fixture dangling-parent
expect dangling-chain 0 "$fixtures/dangling-parent/expected.stdout" /dev/null "$tmp/fx" 2609200002-orphan-log.md
expect dangling-sibling 0 "$fixtures/dangling-parent/expected.stdout" /dev/null "$tmp/fx" 2609200001-sibling-patch.md
expect dangling-other 0 "$fixtures/dangling-parent/expected-stray.stdout" /dev/null "$tmp/fx" 2609200003-stray-patch.md

# code-point child order, case-sensitive identity
copy_fixture sort-order
expect sort-order 0 "$fixtures/sort-order/expected.stdout" /dev/null "$tmp/fx" 2609120002-case-plan.md

# header grammar edge cases
copy_fixture header-quirks
expect header-quirks 0 "$fixtures/header-quirks/expected.stdout" /dev/null "$tmp/fx" 2609130000-root-proposal.md
expect header-empty-parent 3 /dev/null "$fixtures/header-quirks/expected-empty-parent.stderr" "$tmp/fx" 2609130009-empty-parent-plan.md

# errors sorted by (code, locator, detail) tuple
copy_fixture error-order
expect error-order 3 /dev/null "$fixtures/error-order/expected.stderr" "$tmp/fx" 2609140000-root-proposal.md

# first unreadable document in walk order: files before subdirectories, x before x-y
copy_fixture io-order
mkdir -p "$tmp/fx/.projex/0" "$tmp/fx/.projex/x" "$tmp/fx/.projex/x-y"
for bad in 2609150002-bad-plan.md 0/2609150001-bad-plan.md x/2609150003-bad-plan.md x-y/2609150004-bad-plan.md; do printf '\377' > "$tmp/fx/.projex/$bad"; done
expect io-order-first 4 /dev/null "$fixtures/io-order/expected-first.stderr" "$tmp/fx" 2609150000-root-proposal.md
rm -r "$tmp/fx/.projex/2609150002-bad-plan.md" "$tmp/fx/.projex/0"
expect io-order-second 4 /dev/null "$fixtures/io-order/expected-second.stderr" "$tmp/fx" 2609150000-root-proposal.md

# UTF-8 well-formedness table
tab=$(printf '\t')
while IFS=$tab read -r label hex verdict; do
    rm -rf "$tmp/u8"; mkdir -p "$tmp/u8/.projex"
    bytes=''
    while [ -n "$hex" ]; do
        rest=${hex#??}
        bytes="$bytes\\$(printf '%03o' "0x${hex%"$rest"}")"
        hex=$rest
    done
    printf "# t\n> **Parent:** User\n---\n$bytes" > "$tmp/u8/.projex/2609160000-utf8-plan.md"
    if [ "$verdict" = valid ]; then
        want '2609160000-utf8-plan.md\n'
        expect "utf8-$label" 0 "$tmp/want" /dev/null "$tmp/u8" 2609160000-utf8-plan.md
    else
        want 'projex-tree: E_IO: .projex/2609160000-utf8-plan.md: invalid UTF-8\n'
        expect "utf8-$label" 4 /dev/null "$tmp/want" "$tmp/u8" 2609160000-utf8-plan.md
    fi
done < "$fixtures/utf8-cases.tsv"

# target must be a bare filename: no / \ or :
for target in 'a\b.md' 'c:x.md' 'a:b.md'; do
    want 'projex-tree: E_TARGET_NAME: %s: filename basename required\n' "$target"
    expect "target-name $target" 2 /dev/null "$tmp/want" "$repo" "$target"
done

# invocation: exactly two arguments
want '%s\n' "$usage_line"
cp "$tmp/want" "$tmp/usage"
expect usage-0 2 /dev/null "$tmp/usage"
expect usage-1 2 /dev/null "$tmp/usage" .
expect usage-3 2 /dev/null "$tmp/usage" . 2608051553-feature-proposal.md extra
expect usage-verbose 2 /dev/null "$tmp/usage" . 2608051553-feature-proposal.md -Verbose
expect usage-dashdash 2 /dev/null "$tmp/usage" . 2608051553-feature-proposal.md --
want 'projex-tree: E_REPO: : repository root not found\n'
expect empty-repo 2 /dev/null "$tmp/want" '' 2608051553-feature-proposal.md
want 'projex-tree: E_TARGET_NAME: <empty>: filename basename required\n'
expect empty-target 2 /dev/null "$tmp/want" . ''

# repository root that is itself a .projex directory
rm -rf "$tmp/dp"; cp -R "$fixtures/basic" "$tmp/dp"
expect dot-projex-root 0 "$fixtures/basic/expected.stdout" /dev/null "$tmp/dp/.projex" 2608051553-feature-proposal.md
want 'projex-tree: E_PARENT_MALFORMED: unrelated-malformed.md: Parent is not a projex filename: bad/path.md\n'
expect dot-projex-rel 3 /dev/null "$tmp/want" "$tmp/dp/.projex" unrelated-malformed.md

# relative repository root resolves against the caller's working directory
cd "$tmp"
expect relative-repo 0 "$fixtures/basic/expected.stdout" /dev/null dp 2608051553-feature-proposal.md
cd "$OLDPWD"

# NUL inside a Parent value survives to stderr; the directory is not named "nul", a Windows reserved
# device name that makes the repository root unresolvable (E_REPO)
rm -rf "$tmp/nulparent"; mkdir -p "$tmp/nulparent/.projex"
printf '# t\n> **Parent:** a\000b\n---\n' > "$tmp/nulparent/.projex/2609170000-nul-plan.md"
want 'projex-tree: E_PARENT_MALFORMED: .projex/2609170000-nul-plan.md: Parent is not a projex filename: a\000b\n'
expect nul-parent 3 /dev/null "$tmp/want" "$tmp/nulparent" 2609170000-nul-plan.md

# symlinked directories are not descended; symlinked files are not documents
rm -rf "$tmp/lk" "$tmp/lktarget"; mkdir -p "$tmp/lk/.projex" "$tmp/lktarget"
doc "$tmp/lk/.projex/2609180000-root-proposal.md" User
doc "$tmp/lktarget/2609180001-linked-plan.md" 2609180000-root-proposal.md
doc "$tmp/lkfile.md" 2609180000-root-proposal.md
want '2609180000-root-proposal.md\n'; cp "$tmp/want" "$tmp/lkroot"
want 'projex-tree: E_TARGET_NOT_FOUND: 2609180001-linked-plan.md: document not found\n'
if MSYS=winsymlinks:nativestrict ln -s "$tmp/lktarget" "$tmp/lk/.projex/linked" 2>/dev/null && [ -L "$tmp/lk/.projex/linked" ]; then
    expect link-dir-root 0 "$tmp/lkroot" /dev/null "$tmp/lk" 2609180000-root-proposal.md
    expect link-dir-target 2 /dev/null "$tmp/want" "$tmp/lk" 2609180001-linked-plan.md
else
    skip link-dir 'link creation unsupported'
fi
want 'projex-tree: E_TARGET_NOT_FOUND: 2609180002-filelink-plan.md: document not found\n'
if MSYS=winsymlinks:nativestrict ln -s "$tmp/lkfile.md" "$tmp/lk/.projex/2609180002-filelink-plan.md" 2>/dev/null && [ -L "$tmp/lk/.projex/2609180002-filelink-plan.md" ]; then
    expect link-file-root 0 "$tmp/lkroot" /dev/null "$tmp/lk" 2609180000-root-proposal.md
    expect link-file-target 2 /dev/null "$tmp/want" "$tmp/lk" 2609180002-filelink-plan.md
else
    skip link-file 'link creation unsupported'
fi

# unreadable document -> read failed; unenterable repository -> E_REPO
rm -rf "$tmp/rf"; mkdir -p "$tmp/rf/.projex"
doc "$tmp/rf/.projex/2609190000-root-proposal.md" User
doc "$tmp/rf/.projex/2609190001-locked-plan.md" 2609190000-root-proposal.md
locked="$tmp/rf/.projex/2609190001-locked-plan.md"
if deny "$locked" R && ! cat "$locked" >/dev/null 2>&1; then
    want 'projex-tree: E_IO: .projex/2609190001-locked-plan.md: read failed\n'
    expect read-failed 4 /dev/null "$tmp/want" "$tmp/rf" 2609190000-root-proposal.md
else
    skip read-failed 'read denial unsupported'
fi
allow "$locked"
if deny "$tmp/rf" RX && ! ls "$tmp/rf" >/dev/null 2>&1; then
    want 'projex-tree: E_REPO: %s: repository root not found\n' "$tmp/rf"
    expect unenterable-repo 2 /dev/null "$tmp/want" "$tmp/rf" 2609190000-root-proposal.md
else
    skip unenterable-repo 'directory denial unsupported'
fi
allow "$tmp/rf"

printf 'PASS=%d FAIL=%d\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
