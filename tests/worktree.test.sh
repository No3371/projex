#!/usr/bin/env bash
# Worktree-mode coverage: the conflict gate runs against a different directory in each script.
SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOT="$(mktemp -d)"
PASS=0; FAIL=0
chk() { if [ "$2" = "$3" ]; then PASS=$((PASS+1)); else FAIL=$((FAIL+1)); echo "FAIL: $1 (want '$3' got '$2')"; fi; }
gc() { git -C "$1" -c user.email=t@t -c user.name=t "${@:2}"; }
eph_alive() { git -C "$1" rev-parse --verify -q projex/eph >/dev/null && echo y || echo n; }

mkwt() { # $1=name $2=1 to also conflict src.txt
  R="$ROOT/$1"; mkdir -p "$R/.projex"; git -C "$R" init -q -b main
  printf 'v0\n' > "$R/.projex/doc.md"; printf 's0\n' > "$R/src.txt"
  git -C "$R" add .projex/doc.md src.txt >/dev/null; gc "$R" commit -qm init
  git -C "$R" branch projex/eph >/dev/null
  echo '.projexwt/' >> "$R/.git/info/exclude"   # projex-worktree.sh does this; keeps parent status clean
  git -C "$R" worktree add -q "$R/.projexwt/eph" projex/eph 2>/dev/null
  W="$R/.projexwt/eph"
  printf 'eph\n' > "$W/.projex/doc.md"; [ "$2" = 1 ] && printf 'eph\n' > "$W/src.txt"
  git -C "$W" add .projex/doc.md src.txt >/dev/null; gc "$W" commit -qm eph
  printf 'base\n' > "$R/.projex/doc.md"; [ "$2" = 1 ] && printf 'base\n' > "$R/src.txt"
  git -C "$R" add .projex/doc.md src.txt >/dev/null; gc "$R" commit -qm base
  echo "$R"
}

echo "--- merge --worktree"
R=$(mkwt m-cov 0)
"$SCRIPTS/projex-merge-close.sh" "$R" main projex/eph "msg" --worktree --resolve-conflicts .projex/ >/dev/null 2>&1
chk "wt merge covered exit" "$?" "2"
chk "wt merge covered MERGE_HEAD kept" "$([ -f "$R/.git/MERGE_HEAD" ] && echo y || echo n)" "y"
chk "wt merge covered worktree intact" "$([ -d "$R/.projexwt/eph" ] && echo y || echo n)" "y"
"$SCRIPTS/projex-merge-close.sh" "$R" main projex/eph "msg" --worktree --resolve-conflicts .projex/ >/dev/null 2>&1
chk "wt merge bare re-run refuses" "$?" "1"
chk "wt merge bare re-run preserves merge" "$([ -f "$R/.git/MERGE_HEAD" ] && echo y || echo n)" "y"
printf 'r\n' > "$R/.projex/doc.md"; git -C "$R" add .projex/doc.md; gc "$R" commit -q --no-edit
"$SCRIPTS/projex-merge-close.sh" "$R" main projex/eph "msg" --worktree --resolve-conflicts .projex/ >/dev/null 2>&1
chk "wt merge resume closes" "$?" "0"
chk "wt merge resume branch gone" "$(eph_alive "$R")" "n"
chk "wt merge resume worktree removed" "$([ -d "$R/.projexwt/eph" ] && echo y || echo n)" "n"

R=$(mkwt m-unc 1)
out=$("$SCRIPTS/projex-merge-close.sh" "$R" main projex/eph "msg" --worktree --resolve-conflicts .projex/ 2>&1)
chk "wt merge uncovered exit" "$?" "1"
chk "wt merge uncovered aborted" "$([ -f "$R/.git/MERGE_HEAD" ] && echo y || echo n)" "n"
chk "wt merge uncovered worktree kept" "$([ -d "$R/.projexwt/eph" ] && echo y || echo n)" "y"
chk "wt merge uncovered branch kept" "$(eph_alive "$R")" "y"

echo "--- rebase --worktree (gate must target the WORKTREE dir, not the repo root)"
R=$(mkwt r-cov 0)
out=$("$SCRIPTS/projex-rebase-close.sh" "$R" main projex/eph --worktree --resolve-conflicts .projex/ 2>&1)
chk "wt rebase covered exit" "$?" "2"
chk "wt rebase in progress in worktree" "$([ -d "$R/.git/worktrees/eph/rebase-merge" ] || [ -d "$R/.git/worktrees/eph/rebase-apply" ] && echo y || echo n)" "y"
chk "wt rebase message points at worktree" "$(echo "$out" | grep -c '.projexwt/eph rebase --continue')" "1"
"$SCRIPTS/projex-rebase-close.sh" "$R" main projex/eph --worktree --resolve-conflicts .projex/ >/dev/null 2>&1
chk "wt rebase mid-flight re-run refuses" "$?" "1"
chk "wt rebase mid-flight not aborted" "$([ -d "$R/.git/worktrees/eph/rebase-merge" ] || [ -d "$R/.git/worktrees/eph/rebase-apply" ] && echo y || echo n)" "y"
printf 'r\n' > "$R/.projexwt/eph/.projex/doc.md"; git -C "$R/.projexwt/eph" add .projex/doc.md
GIT_EDITOR=true gc "$R/.projexwt/eph" rebase --continue >/dev/null 2>&1
"$SCRIPTS/projex-rebase-close.sh" "$R" main projex/eph --worktree --resolve-conflicts .projex/ >/dev/null 2>&1
chk "wt rebase resume closes" "$?" "0"
chk "wt rebase resume branch gone" "$(eph_alive "$R")" "n"
chk "wt rebase resume worktree removed" "$([ -d "$R/.projexwt/eph" ] && echo y || echo n)" "n"
chk "wt rebase resume content" "$(git -C "$R" show main:.projex/doc.md | tr -d '\r\n')" "r"

R=$(mkwt r-unc 1)
"$SCRIPTS/projex-rebase-close.sh" "$R" main projex/eph --worktree --resolve-conflicts .projex/ >/dev/null 2>&1
chk "wt rebase uncovered exit" "$?" "1"
chk "wt rebase uncovered aborted" "$([ -d "$R/.git/worktrees/eph/rebase-merge" ] || [ -d "$R/.git/worktrees/eph/rebase-apply" ] && echo y || echo n)" "n"
chk "wt rebase uncovered worktree kept" "$([ -d "$R/.projexwt/eph" ] && echo y || echo n)" "y"

echo "--- squash --worktree"
R=$(mkwt s-cov 0)
out=$("$SCRIPTS/projex-squash-close.sh" "$R" main projex/eph "msg" --worktree --resolve-conflicts .projex/ 2>&1)
chk "wt squash covered exit" "$?" "2"
chk "wt squash covered unmerged kept" "$(git -C "$R" diff --name-only --diff-filter=U)" ".projex/doc.md"
chk "wt squash finish cmds include worktree remove" "$(echo "$out" | grep -c 'worktree remove')" "1"
chk "wt squash covered worktree intact" "$([ -d "$R/.projexwt/eph" ] && echo y || echo n)" "y"

R=$(mkwt s-unc 1)
"$SCRIPTS/projex-squash-close.sh" "$R" main projex/eph "msg" --worktree --resolve-conflicts .projex/ >/dev/null 2>&1
chk "wt squash uncovered exit" "$?" "1"
chk "wt squash uncovered clean" "$(git -C "$R" status --porcelain)" ""
chk "wt squash uncovered worktree kept" "$([ -d "$R/.projexwt/eph" ] && echo y || echo n)" "y"

echo "--- dirty worktree still blocks before anything is attempted"
R=$(mkwt dirty 0)
printf 'scratch\n' > "$R/.projexwt/eph/untracked.txt"
"$SCRIPTS/projex-merge-close.sh" "$R" main projex/eph "msg" --worktree --resolve-conflicts .projex/ >/dev/null 2>&1
chk "wt dirty worktree refuses" "$?" "1"
chk "wt dirty no merge started" "$([ -f "$R/.git/MERGE_HEAD" ] && echo y || echo n)" "n"

echo "--- paths with spaces are matched correctly"
R="$ROOT/spaces"; mkdir -p "$R/my docs"; git -C "$R" init -q -b main
printf 'v0\n' > "$R/my docs/a b.md"; git -C "$R" add "my docs/a b.md" >/dev/null; gc "$R" commit -qm init
git -C "$R" checkout -qb projex/eph; printf 'eph\n' > "$R/my docs/a b.md"
git -C "$R" add "my docs/a b.md" >/dev/null; gc "$R" commit -qm eph
git -C "$R" checkout -q main; printf 'base\n' > "$R/my docs/a b.md"
git -C "$R" add "my docs/a b.md" >/dev/null; gc "$R" commit -qm base
"$SCRIPTS/projex-merge-close.sh" "$R" main projex/eph "msg" --resolve-conflicts 'my docs/' >/dev/null 2>&1
chk "spaced dir prefix covers conflict" "$?" "2"

echo "PASS=$PASS FAIL=$FAIL"
rm -rf "$ROOT"
[ "$FAIL" -eq 0 ]
