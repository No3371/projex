#!/usr/bin/env bash
# Exercises --resolve-conflicts across the three close scripts.
SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOT="$(mktemp -d)"
PASS=0; FAIL=0
chk() { if [ "$2" = "$3" ]; then PASS=$((PASS+1)); else FAIL=$((FAIL+1)); echo "FAIL: $1 (want '$3' got '$2')"; fi; }

# conflicting repo: base and ephemeral both edit .projex/doc.md and (optionally) src.txt
mkrepo() { # $1=name  $2=1 to also conflict src.txt
  R="$ROOT/$1"; mkdir -p "$R/.projex"; git -C "$R" init -q -b main
  printf 'v0\n' > "$R/.projex/doc.md"; printf 's0\n' > "$R/src.txt"
  git -C "$R" add .projex/doc.md src.txt >/dev/null; git -C "$R" -c user.email=t@t -c user.name=t commit -qm init
  git -C "$R" checkout -qb projex/eph
  printf 'eph\n' > "$R/.projex/doc.md"; [ "$2" = 1 ] && printf 'eph\n' > "$R/src.txt"
  git -C "$R" add .projex/doc.md src.txt >/dev/null; git -C "$R" -c user.email=t@t -c user.name=t commit -qm eph
  git -C "$R" checkout -q main
  printf 'base\n' > "$R/.projex/doc.md"; [ "$2" = 1 ] && printf 'base\n' > "$R/src.txt"
  git -C "$R" add .projex/doc.md src.txt >/dev/null; git -C "$R" -c user.email=t@t -c user.name=t commit -qm base
  echo "$R"
}

# --- merge: covered conflict -> exit 2, merge left in progress, then resume by re-run
R=$(mkrepo merge-cov 0)
out=$("$SCRIPTS/projex-merge-close.sh" "$R" main projex/eph "msg" --resolve-conflicts .projex/ 2>&1); chk "merge covered exit" "$?" "2"
chk "merge covered MERGE_HEAD kept" "$([ -f "$R/.git/MERGE_HEAD" ] && echo y || echo n)" "y"
chk "merge covered unmerged listed" "$(git -C "$R" diff --name-only --diff-filter=U)" ".projex/doc.md"
printf 'resolved\n' > "$R/.projex/doc.md"; git -C "$R" add .projex/doc.md
git -C "$R" -c user.email=t@t -c user.name=t commit -q --no-edit
"$SCRIPTS/projex-merge-close.sh" "$R" main projex/eph "msg" --resolve-conflicts .projex/ >/dev/null 2>&1; chk "merge resume exit" "$?" "0"
chk "merge resume branch gone" "$(git -C "$R" branch --list projex/eph)" ""

# --- merge: uncovered conflict -> exit 1, rolled back
R=$(mkrepo merge-unc 1)
out=$("$SCRIPTS/projex-merge-close.sh" "$R" main projex/eph "msg" --resolve-conflicts .projex/ 2>&1); chk "merge uncovered exit" "$?" "1"
chk "merge uncovered aborted" "$([ -f "$R/.git/MERGE_HEAD" ] && echo y || echo n)" "n"
chk "merge uncovered lists only src" "$(echo "$out" | sed -n '/Unanticipated/,$p' | tail -n +2 | tr -d ' \r')" "src.txt"
chk "merge uncovered branch kept" "$(git -C "$R" branch --list projex/eph | tr -d ' *')" "projex/eph"

# --- merge: no flag -> old behaviour (abort, exit 1)
R=$(mkrepo merge-noflag 0)
"$SCRIPTS/projex-merge-close.sh" "$R" main projex/eph "msg" >/dev/null 2>&1; chk "merge noflag exit" "$?" "1"
chk "merge noflag aborted" "$([ -f "$R/.git/MERGE_HEAD" ] && echo y || echo n)" "n"

# --- rebase: covered -> exit 2, rebase in progress, resume by re-run
R=$(mkrepo rebase-cov 0)
"$SCRIPTS/projex-rebase-close.sh" "$R" main projex/eph --resolve-conflicts .projex/doc.md >/dev/null 2>&1; chk "rebase covered exit" "$?" "2"
chk "rebase covered in progress" "$([ -d "$R/.git/rebase-merge" ] || [ -d "$R/.git/rebase-apply" ] && echo y || echo n)" "y"
printf 'resolved\n' > "$R/.projex/doc.md"; git -C "$R" add .projex/doc.md
GIT_EDITOR=true git -C "$R" -c user.email=t@t -c user.name=t rebase --continue >/dev/null 2>&1
"$SCRIPTS/projex-rebase-close.sh" "$R" main projex/eph --resolve-conflicts .projex/doc.md >/dev/null 2>&1; chk "rebase resume exit" "$?" "0"
chk "rebase resume branch gone" "$(git -C "$R" branch --list projex/eph)" ""
chk "rebase resume on main" "$(git -C "$R" rev-parse --abbrev-ref HEAD)" "main"

# --- rebase: uncovered -> exit 1, aborted, restored to original branch
R=$(mkrepo rebase-unc 1)
out=$("$SCRIPTS/projex-rebase-close.sh" "$R" main projex/eph --resolve-conflicts .projex/ 2>&1); chk "rebase uncovered exit" "$?" "1"
chk "rebase uncovered aborted" "$([ -d "$R/.git/rebase-merge" ] || [ -d "$R/.git/rebase-apply" ] && echo y || echo n)" "n"
chk "rebase uncovered restored" "$(git -C "$R" rev-parse --abbrev-ref HEAD)" "main"

# --- squash: covered -> exit 2, conflicts left staged
R=$(mkrepo squash-cov 0)
out=$("$SCRIPTS/projex-squash-close.sh" "$R" main projex/eph "msg" --resolve-conflicts .projex/ 2>&1); chk "squash covered exit" "$?" "2"
chk "squash covered unmerged kept" "$(git -C "$R" diff --name-only --diff-filter=U)" ".projex/doc.md"
chk "squash covered warns against re-run" "$(echo "$out" | grep -c 'Do NOT re-run')" "1"
chk "squash covered lists finish cmds" "$(echo "$out" | grep -c 'branch -D projex/eph')" "1"
# a squash resolution committed by hand must NOT be re-run through the script: it re-conflicts
printf 'resolved\n' > "$R/.projex/doc.md"; git -C "$R" add .projex/doc.md
git -C "$R" -c user.email=t@t -c user.name=t commit -qm msg
"$SCRIPTS/projex-squash-close.sh" "$R" main projex/eph "msg" --resolve-conflicts .projex/ >/dev/null 2>&1
chk "squash re-run after commit re-conflicts (documented)" "$?" "2"
chk "squash re-run leaves resolution commit intact" "$(git -C "$R" log --oneline -1 --format=%s)" "msg"

# --- squash: uncovered -> exit 1, reset clean
R=$(mkrepo squash-unc 1)
"$SCRIPTS/projex-squash-close.sh" "$R" main projex/eph "msg" --resolve-conflicts .projex/ >/dev/null 2>&1; chk "squash uncovered exit" "$?" "1"
chk "squash uncovered clean" "$(git -C "$R" status --porcelain)" ""

# --- multi-entry list + comma form, and non-conflicting close still works end to end
R=$(mkrepo multi 1)
"$SCRIPTS/projex-squash-close.sh" "$R" main projex/eph "msg" --resolve-conflicts '.projex/,src.txt' >/dev/null 2>&1; chk "squash multi-entry exit" "$?" "2"
R="$ROOT/clean"; mkdir -p "$R"; git -C "$R" init -q -b main; printf 'a\n' > "$R/a.txt"
git -C "$R" add a.txt >/dev/null; git -C "$R" -c user.email=t@t -c user.name=t commit -qm init
git -C "$R" checkout -qb projex/eph; printf 'b\n' > "$R/b.txt"; git -C "$R" add b.txt >/dev/null
git -C "$R" -c user.email=t@t -c user.name=t commit -qm add; git -C "$R" checkout -q main
"$SCRIPTS/projex-squash-close.sh" "$R" main projex/eph "msg" --resolve-conflicts .projex/ >/dev/null 2>&1; chk "clean close still exit 0" "$?" "0"

# --- prefix must not match a sibling by string prefix (.projexwt vs .projex)
R="$ROOT/prefix"; mkdir -p "$R/.projexwt"; git -C "$R" init -q -b main
printf 'v0\n' > "$R/.projexwt/f.md"; git -C "$R" add .projexwt/f.md >/dev/null
git -C "$R" -c user.email=t@t -c user.name=t commit -qm init
git -C "$R" checkout -qb projex/eph; printf 'eph\n' > "$R/.projexwt/f.md"; git -C "$R" add .projexwt/f.md >/dev/null
git -C "$R" -c user.email=t@t -c user.name=t commit -qm eph; git -C "$R" checkout -q main
printf 'base\n' > "$R/.projexwt/f.md"; git -C "$R" add .projexwt/f.md >/dev/null
git -C "$R" -c user.email=t@t -c user.name=t commit -qm base
"$SCRIPTS/projex-merge-close.sh" "$R" main projex/eph "msg" --resolve-conflicts .projex >/dev/null 2>&1; chk "sibling prefix not matched" "$?" "1"

echo "PASS=$PASS FAIL=$FAIL"
rm -rf "$ROOT"
[ "$FAIL" -eq 0 ]
