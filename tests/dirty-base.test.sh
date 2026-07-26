#!/usr/bin/env bash
# Dirty-base safety: what the finalizers must refuse in the checkout they are about to mutate, and
# what they must still allow. Every refusal case asserts non-mutation directly — base ref, EPHEMERAL
# ref, file bytes, worktree registration — because "exit 1" on its own also passes on a half-done
# close. The ephemeral-ref assertion is the one that catches rebase-close rewriting history before
# it discovers a collision at the base worktree.
SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOT="$(mktemp -d)"
PASS=0; FAIL=0
chk() { if [ "$2" = "$3" ]; then PASS=$((PASS+1)); else FAIL=$((FAIL+1)); echo "FAIL: $1 (want '$3' got '$2')"; fi; }
gc() { git -C "$1" -c user.email=t@t -c user.name=t "${@:2}"; }
sha() { git -C "$1" rev-parse "$2" 2>/dev/null; }
alive() { git -C "$1" rev-parse --verify -q "$2" >/dev/null && echo y || echo n; }
wt_reg() { git -C "$1" worktree list --porcelain | grep -q "/\.projexwt/$2\$" && echo y || echo n; }
merging() { [ -f "$1/.git/MERGE_HEAD" ] && echo y || echo n; }
rebasing() { { [ -d "$1/.git/worktrees/eph/rebase-merge" ] || [ -d "$1/.git/worktrees/eph/rebase-apply" ]; } && echo y || echo n; }
body() { tr -d '\r\n' < "$1"; }

# $1 = repo name. main holds a.txt; projex/eph (worktree at .projexwt/eph) rewrites a.txt and adds
# new.txt. $2 selects how main has moved on since the branch point:
#   0 (default) — not at all; rebase replays nothing and rewrites no SHAs
#   1           — conflicting edit to a.txt
#   2           — unrelated commit, so a rebase really does replay and rewrite the ephemeral SHAs.
#                 Mode 2 is what makes the rebase collision case reproduce the pre-fix bug: without
#                 an advanced base the rebase is a no-op and the ephemeral ref never moves anyway.
mk() {
  R="$ROOT/$1"; mkdir -p "$R"; git -C "$R" init -q -b main
  printf 'v0\n' > "$R/a.txt"; git -C "$R" add a.txt >/dev/null; gc "$R" commit -qm init
  git -C "$R" branch projex/eph >/dev/null
  echo '.projexwt/' >> "$R/.git/info/exclude"   # projex-worktree.sh does this
  git -C "$R" worktree add -q "$R/.projexwt/eph" projex/eph 2>/dev/null
  W="$R/.projexwt/eph"
  printf 'eph\n' > "$W/a.txt"; printf 'new\n' > "$W/new.txt"
  git -C "$W" add a.txt new.txt >/dev/null; gc "$W" commit -qm eph
  case "${2:-0}" in
    1) printf 'base\n' > "$R/a.txt"; git -C "$R" add a.txt >/dev/null; gc "$R" commit -qm base ;;
    2) printf 'unrelated\n' > "$R/b.txt"; git -C "$R" add b.txt >/dev/null; gc "$R" commit -qm advance ;;
  esac
  echo "$R"
}

# close <type> <repo-root> <base> [extra args...] — normalises the differing argument shapes
close() {
  local t="$1" r="$2" b="$3"; shift 3
  case "$t" in
    merge)  "$SCRIPTS/projex-merge-close.sh"  "$r" "$b" projex/eph "msg" --worktree "$@" ;;
    squash) "$SCRIPTS/projex-squash-close.sh" "$r" "$b" projex/eph "msg" --worktree "$@" ;;
    rebase) "$SCRIPTS/projex-rebase-close.sh" "$r" "$b" projex/eph --worktree "$@" ;;
  esac
}

echo "--- tracked changes in the integration checkout block every close type"
for kind in unstaged staged; do
  for t in merge rebase squash; do
    R=$(mk "d-$kind-$t"); B0=$(sha "$R" main); E0=$(sha "$R" projex/eph)
    printf 'PRECIOUS\n' > "$R/a.txt"
    [ "$kind" = staged ] && git -C "$R" add a.txt >/dev/null
    close "$t" "$R" main >/dev/null 2>&1; rc=$?
    chk "$t $kind exit" "$rc" "1"
    chk "$t $kind edit survives" "$(body "$R/a.txt")" "PRECIOUS"
    chk "$t $kind base unmoved" "$(sha "$R" main)" "$B0"
    chk "$t $kind ephemeral unmoved" "$(sha "$R" projex/eph)" "$E0"
    chk "$t $kind worktree still registered" "$(wt_reg "$R" eph)" "y"
    chk "$t $kind no merge started" "$(merging "$R")" "n"
    chk "$t $kind no rebase started" "$(rebasing "$R")" "n"
  done
done

echo "--- unrelated untracked content at the integration checkout does not block"
for t in merge rebase squash; do
  R=$(mk "u-$t")
  printf 'bystander\n' > "$R/keep.txt"
  close "$t" "$R" main >/dev/null 2>&1; rc=$?
  chk "$t bystander exit" "$rc" "0"
  chk "$t bystander survives byte-for-byte" "$(body "$R/keep.txt")" "bystander"
  chk "$t bystander close landed" "$(git -C "$R" show main:new.txt | tr -d '\r\n')" "new"
  chk "$t bystander branch deleted" "$(alive "$R" projex/eph)" "n"
done

echo "--- an untracked path the ephemeral branch adds as tracked fails before ANY mutation"
for t in merge rebase squash; do
  R=$(mk "c-$t" 2); B0=$(sha "$R" main); E0=$(sha "$R" projex/eph)
  printf 'squatter\n' > "$R/new.txt"
  close "$t" "$R" main >/dev/null 2>&1; rc=$?
  chk "$t collision exit" "$rc" "1"
  chk "$t collision no overwrite" "$(body "$R/new.txt")" "squatter"
  chk "$t collision base unmoved" "$(sha "$R" main)" "$B0"
  chk "$t collision ephemeral tip unmoved" "$(sha "$R" projex/eph)" "$E0"
  chk "$t collision worktree still registered" "$(wt_reg "$R" eph)" "y"
done

echo "--- a dirty submodule alone must not block close"
SUB="$ROOT/subsrc"; mkdir -p "$SUB"; git -C "$SUB" init -q -b main
printf 's0\n' > "$SUB/f.txt"; git -C "$SUB" add f.txt >/dev/null; gc "$SUB" commit -qm s0
SUBOK=y
for t in merge rebase squash; do
  R="$ROOT/sm-$t"; mkdir -p "$R"; git -C "$R" init -q -b main
  printf 'v0\n' > "$R/a.txt"; git -C "$R" add a.txt >/dev/null; gc "$R" commit -qm init
  if ! git -C "$R" -c protocol.file.allow=always -c user.email=t@t -c user.name=t \
        submodule add -q "$SUB" sub >/dev/null 2>&1; then SUBOK=n; break; fi
  git -C "$R" add .gitmodules sub >/dev/null; gc "$R" commit -qm addsub
  git -C "$R" branch projex/eph >/dev/null
  echo '.projexwt/' >> "$R/.git/info/exclude"
  git -C "$R" worktree add -q "$R/.projexwt/eph" projex/eph 2>/dev/null
  printf 'new\n' > "$R/.projexwt/eph/new.txt"
  git -C "$R/.projexwt/eph" add new.txt >/dev/null; gc "$R/.projexwt/eph" commit -qm eph
  printf 'DIRTY\n' > "$R/sub/f.txt"          # submodule content dirty, recorded commit unchanged
  gated=$(git -C "$R" status --porcelain --untracked-files=no --ignore-submodules=dirty)
  chk "$t submodule dirt invisible to gate" "$gated" ""
  close "$t" "$R" main >/dev/null 2>&1; rc=$?
  chk "$t submodule dirt does not block" "$rc" "0"
  chk "$t submodule dirt preserved" "$(body "$R/sub/f.txt")" "DIRTY"
done
[ "$SUBOK" = y ] || echo "FAIL: submodule scenarios could not be set up (git submodule add refused)"

echo "--- conflicted squash rolls back to a clean pre-merge state, no hard reset"
R=$(mk s-conf 1); B0=$(sha "$R" main); E0=$(sha "$R" projex/eph)
out=$("$SCRIPTS/projex-squash-close.sh" "$R" main projex/eph "msg" --worktree 2>&1); rc=$?
chk "squash conflict exit" "$rc" "1"
chk "squash conflict base unmoved" "$(sha "$R" main)" "$B0"
chk "squash conflict ephemeral kept" "$(sha "$R" projex/eph)" "$E0"
chk "squash conflict checkout clean" "$(git -C "$R" status --porcelain)" ""
chk "squash conflict base content restored" "$(body "$R/a.txt")" "base"
chk "squash conflict branch survives" "$(alive "$R" projex/eph)" "y"
chk "squash conflict worktree survives" "$(wt_reg "$R" eph)" "y"
chk "squash conflict reports safe rollback" "$(echo "$out" | grep -c 'rolled back to a clean pre-merge state')" "1"
chk "squash conflict never claims a hard reset" "$(echo "$out" | grep -c 'reset --hard')" "0"

# The rollback-FAILURE branch of safe_rollback is not constructible as a deterministic regression
# case; it is reachable only through the documented gate->merge window. The tracked-clean gate plus
# the in-progress gate leave the tree tracked-clean when `merge --squash` runs, but nothing re-checks
# in between: a concurrent writer leaving a tracked file at index != HEAD != worktree makes the merge
# refuse pre-mutation AND `reset --merge HEAD` fail. A test cannot pre-seed that state because the
# gate rejects it up front. See the execution log for the five constructions attempted. The closest
# reachable case is the documented gate hole below, which exercises safe_rollback on a tree the merge
# refused to touch.
echo "--- known hole: skip-worktree dirt is invisible to the gate; merge refuses pre-mutation"
R=$(mk s-skip); B0=$(sha "$R" main); E0=$(sha "$R" projex/eph)
printf 'LOCAL\n' > "$R/a.txt"; git -C "$R" update-index --skip-worktree a.txt
chk "skip-worktree invisible to gate" "$(git -C "$R" status --porcelain --untracked-files=no --ignore-submodules=dirty)" ""
"$SCRIPTS/projex-squash-close.sh" "$R" main projex/eph "msg" --worktree >/dev/null 2>&1
chk "skip-worktree squash exit" "$?" "1"
chk "skip-worktree local content survives rollback" "$(body "$R/a.txt")" "LOCAL"
chk "skip-worktree base unmoved" "$(sha "$R" main)" "$B0"
chk "skip-worktree ephemeral kept" "$(sha "$R" projex/eph)" "$E0"

echo "--- happy path retained for every close type"
for t in merge rebase squash; do
  R=$(mk "h-$t")
  close "$t" "$R" main >/dev/null 2>&1; rc=$?
  chk "$t happy exit" "$rc" "0"
  chk "$t happy base updated" "$(git -C "$R" show main:new.txt | tr -d '\r\n')" "new"
  chk "$t happy branch deleted" "$(alive "$R" projex/eph)" "n"
  chk "$t happy worktree unregistered" "$(wt_reg "$R" eph)" "n"
done

echo "--- Base must resolve to a local branch"
R=$(mk nb); B0=$(sha "$R" main); E0=$(sha "$R" projex/eph)
git -C "$R" tag v1
git -C "$R" update-ref refs/remotes/origin/main "$B0"
for ref in v1 origin/main "$B0"; do
  label=$([ "$ref" = "$B0" ] && echo raw-sha || echo "$ref")
  for t in merge rebase squash; do
    close "$t" "$R" "$ref" >/dev/null 2>&1
    chk "$t base=$label exit" "$?" "1"
  done
  chk "base=$label base unmoved" "$(sha "$R" main)" "$B0"
  chk "base=$label ephemeral unmoved" "$(sha "$R" projex/eph)" "$E0"
done

echo "--- the integration checkout must still have Base checked out"
R=$(mk mm); B0=$(sha "$R" main); E0=$(sha "$R" projex/eph)
git -C "$R" checkout -qb sidebranch
for t in merge rebase squash; do
  close "$t" "$R" main >/dev/null 2>&1
  chk "$t mismatched origin exit" "$?" "1"
done
chk "mismatched origin base unmoved" "$(sha "$R" main)" "$B0"
chk "mismatched origin ephemeral unmoved" "$(sha "$R" projex/eph)" "$E0"
chk "mismatched origin worktree kept" "$(wt_reg "$R" eph)" "y"

R=$(mk det); B0=$(sha "$R" main); E0=$(sha "$R" projex/eph)
git -C "$R" checkout -q --detach
for t in merge rebase squash; do
  close "$t" "$R" main >/dev/null 2>&1
  chk "$t detached origin exit" "$?" "1"
done
chk "detached origin base unmoved" "$(sha "$R" main)" "$B0"
chk "detached origin ephemeral unmoved" "$(sha "$R" projex/eph)" "$E0"

echo "--- a child closes into its recorded parent worktree/branch, never main"
R="$ROOT/nest"; mkdir -p "$R"; git -C "$R" init -q -b main
printf 'v0\n' > "$R/a.txt"; git -C "$R" add a.txt >/dev/null; gc "$R" commit -qm init
MAIN0=$(sha "$R" main)
echo '.projexwt/' >> "$R/.git/info/exclude"
git -C "$R" branch projex/outer >/dev/null
git -C "$R" worktree add -q "$R/.projexwt/outer" projex/outer 2>/dev/null
O="$R/.projexwt/outer"
printf 'outer\n' > "$O/o.txt"; git -C "$O" add o.txt >/dev/null; gc "$O" commit -qm outer
git -C "$R" branch projex/inner projex/outer >/dev/null
git -C "$O" worktree add -q "$O/.projexwt/inner" projex/inner 2>/dev/null
I="$O/.projexwt/inner"
printf 'inner\n' > "$I/i.txt"; git -C "$I" add i.txt >/dev/null; gc "$I" commit -qm inner
"$SCRIPTS/projex-squash-close.sh" "$O" projex/outer projex/inner "msg" --worktree >/dev/null 2>&1
chk "nested close exit" "$?" "0"
chk "nested parent got the child content" "$(git -C "$R" show projex/outer:i.txt | tr -d '\r\n')" "inner"
chk "nested main untouched" "$(sha "$R" main)" "$MAIN0"
chk "nested child branch deleted" "$(alive "$R" projex/inner)" "n"
chk "nested child worktree unregistered" "$(wt_reg "$R" inner)" "n"

# Same topology, but the recorded parent worktree is dirty: the gate must fire against THAT
# worktree, not the primary one, and must not fall back to main.
R2="$ROOT/nest2"; mkdir -p "$R2"; git -C "$R2" init -q -b main
printf 'v0\n' > "$R2/a.txt"; git -C "$R2" add a.txt >/dev/null; gc "$R2" commit -qm init
echo '.projexwt/' >> "$R2/.git/info/exclude"
git -C "$R2" branch projex/outer >/dev/null
git -C "$R2" worktree add -q "$R2/.projexwt/outer" projex/outer 2>/dev/null
O2="$R2/.projexwt/outer"
printf 'outer\n' > "$O2/o.txt"; git -C "$O2" add o.txt >/dev/null; gc "$O2" commit -qm outer
git -C "$R2" branch projex/inner projex/outer >/dev/null
git -C "$O2" worktree add -q "$O2/.projexwt/inner" projex/inner 2>/dev/null
printf 'inner\n' > "$O2/.projexwt/inner/i.txt"
git -C "$O2/.projexwt/inner" add i.txt >/dev/null; gc "$O2/.projexwt/inner" commit -qm inner
OUTER0=$(sha "$R2" projex/outer); INNER0=$(sha "$R2" projex/inner)
printf 'PRECIOUS\n' > "$O2/o.txt"                      # dirty the recorded PARENT worktree
"$SCRIPTS/projex-squash-close.sh" "$O2" projex/outer projex/inner "msg" --worktree >/dev/null 2>&1
chk "nested dirty parent exit" "$?" "1"
chk "nested dirty parent edit survives" "$(body "$O2/o.txt")" "PRECIOUS"
chk "nested dirty parent ref unmoved" "$(sha "$R2" projex/outer)" "$OUTER0"
chk "nested dirty parent child unmoved" "$(sha "$R2" projex/inner)" "$INNER0"

echo "PASS=$PASS FAIL=$FAIL"
rm -rf "$ROOT"
[ "$FAIL" -eq 0 ]
