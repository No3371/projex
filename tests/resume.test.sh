#!/usr/bin/env bash
# Sloppy-resume suite: what a careless agent actually does between exit 2 and the re-run.
# Every case must end in exactly one of: correct close, or refusal with the work preserved.
SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOT="$(mktemp -d)"
PASS=0; FAIL=0
chk() { if [ "$2" = "$3" ]; then PASS=$((PASS+1)); else FAIL=$((FAIL+1)); echo "FAIL: $1 (want '$3' got '$2')"; fi; }
gc() { git -C "$1" -c user.email=t@t -c user.name=t "${@:2}"; }
inprog() { [ -f "$1/.git/MERGE_HEAD" ] || [ -d "$1/.git/rebase-merge" ] || [ -d "$1/.git/rebase-apply" ] || [ -n "$(git -C "$1" diff --name-only --diff-filter=U)" ] && echo y || echo n; }
eph_alive() { git -C "$1" rev-parse --verify -q projex/eph >/dev/null && echo y || echo n; }

mkrepo() { # $1=name $2=1 to also conflict src.txt  $3=1 for a SECOND conflicting commit on eph
  R="$ROOT/$1"; mkdir -p "$R/.projex"; git -C "$R" init -q -b main
  printf 'v0\n' > "$R/.projex/doc.md"; printf 's0\n' > "$R/src.txt"
  git -C "$R" add .projex/doc.md src.txt >/dev/null; gc "$R" commit -qm init
  git -C "$R" checkout -qb projex/eph
  printf 'eph\n' > "$R/.projex/doc.md"; [ "$2" = 1 ] && printf 'eph\n' > "$R/src.txt"
  git -C "$R" add .projex/doc.md src.txt >/dev/null; gc "$R" commit -qm eph1
  if [ "$3" = 1 ]; then
    printf 'eph2\n' > "$R/.projex/doc.md"; git -C "$R" add .projex/doc.md >/dev/null; gc "$R" commit -qm eph2
  fi
  git -C "$R" checkout -q main
  printf 'base\n' > "$R/.projex/doc.md"; [ "$2" = 1 ] && printf 'base\n' > "$R/src.txt"
  git -C "$R" add .projex/doc.md src.txt >/dev/null; gc "$R" commit -qm base
  echo "$R"
}
stop_merge() { "$SCRIPTS/projex-merge-close.sh" "$1" main projex/eph "msg" --resolve-conflicts .projex/ >/dev/null 2>&1; }
stop_rebase() { "$SCRIPTS/projex-rebase-close.sh" "$1" main projex/eph --resolve-conflicts .projex/ >/dev/null 2>&1; }
stop_squash() { "$SCRIPTS/projex-squash-close.sh" "$1" main projex/eph "msg" --resolve-conflicts .projex/ >/dev/null 2>&1; }

echo "--- agent re-runs having done NOTHING at all"
for kind in merge rebase squash; do
  R=$(mkrepo "noop-$kind" 0 0); stop_$kind "$R"
  before=$(git -C "$R" rev-parse HEAD)
  "stop_$kind" "$R"; rc=$?
  chk "$kind: bare re-run refuses" "$rc" "1"
  chk "$kind: bare re-run preserves operation" "$(inprog "$R")" "y"
  chk "$kind: bare re-run moves no commit" "$(git -C "$R" rev-parse HEAD)" "$before"
  chk "$kind: bare re-run keeps branch" "$(eph_alive "$R")" "y"
done

echo "--- agent edits the file but forgets git add"
for kind in merge rebase squash; do
  R=$(mkrepo "noadd-$kind" 0 0); stop_$kind "$R"
  printf 'resolved\n' > "$R/.projex/doc.md"     # markers gone, never staged
  "stop_$kind" "$R"; chk "$kind: unstaged resolution refuses" "$?" "1"
  chk "$kind: unstaged resolution preserved" "$(cat "$R/.projex/doc.md" | tr -d '\r\n')" "resolved"
  chk "$kind: unstaged keeps branch" "$(eph_alive "$R")" "y"
done

echo "--- agent stages but forgets to commit / continue"
for kind in merge rebase squash; do
  R=$(mkrepo "nocommit-$kind" 0 0); stop_$kind "$R"
  printf 'resolved\n' > "$R/.projex/doc.md"; git -C "$R" add .projex/doc.md
  "stop_$kind" "$R"; chk "$kind: staged-not-committed refuses" "$?" "1"
  chk "$kind: staged content survives" "$(git -C "$R" show :.projex/doc.md | tr -d '\r\n')" "resolved"
  chk "$kind: staged keeps branch" "$(eph_alive "$R")" "y"
done

echo "--- agent commits conflict markers verbatim (script cannot know; must still close cleanly)"
R=$(mkrepo markers 0 0); stop_merge "$R"
git -C "$R" add .projex/doc.md; gc "$R" commit -q --no-edit
"$SCRIPTS/projex-merge-close.sh" "$R" main projex/eph "msg" --resolve-conflicts .projex/ >/dev/null 2>&1
chk "merge: markers-committed still closes" "$?" "0"
chk "merge: markers-committed deletes branch" "$(eph_alive "$R")" "n"

echo "--- agent drops the --resolve-conflicts flag on the re-run"
R=$(mkrepo noflag-m 0 0); stop_merge "$R"
printf 'r\n' > "$R/.projex/doc.md"; git -C "$R" add .projex/doc.md; gc "$R" commit -q --no-edit
"$SCRIPTS/projex-merge-close.sh" "$R" main projex/eph "msg" >/dev/null 2>&1
chk "merge: resume without flag closes" "$?" "0"
R=$(mkrepo noflag-r 0 0); stop_rebase "$R"
printf 'r\n' > "$R/.projex/doc.md"; git -C "$R" add .projex/doc.md
GIT_EDITOR=true gc "$R" rebase --continue >/dev/null 2>&1
"$SCRIPTS/projex-rebase-close.sh" "$R" main projex/eph >/dev/null 2>&1
chk "rebase: resume without flag closes" "$?" "0"

echo "--- agent re-runs the WRONG script to resume (mixed tooling)"
R=$(mkrepo crossed 0 0); stop_merge "$R"
printf 'r\n' > "$R/.projex/doc.md"; git -C "$R" add .projex/doc.md; gc "$R" commit -q --no-edit
"$SCRIPTS/projex-squash-close.sh" "$R" main projex/eph "msg" --resolve-conflicts .projex/ >/dev/null 2>&1
chk "squash after merge-resolve: no false failure" "$?" "0"
chk "squash after merge-resolve: branch gone" "$(eph_alive "$R")" "n"
chk "squash after merge-resolve: tree clean" "$(git -C "$R" status --porcelain)" ""

echo "--- multi-commit rebase: second conflict must not destroy the first resolution"
R=$(mkrepo multi 0 1); stop_rebase "$R"
printf 'first\n' > "$R/.projex/doc.md"; git -C "$R" add .projex/doc.md
GIT_EDITOR=true gc "$R" rebase --continue >/dev/null 2>&1   # stops again on eph2
chk "rebase: stops again mid-flight" "$(inprog "$R")" "y"
"$SCRIPTS/projex-rebase-close.sh" "$R" main projex/eph --resolve-conflicts .projex/ >/dev/null 2>&1
chk "rebase: mid-flight re-run refuses" "$?" "1"
chk "rebase: mid-flight rebase NOT aborted" "$(inprog "$R")" "y"
printf 'second\n' > "$R/.projex/doc.md"; git -C "$R" add .projex/doc.md
GIT_EDITOR=true gc "$R" rebase --continue >/dev/null 2>&1
"$SCRIPTS/projex-rebase-close.sh" "$R" main projex/eph --resolve-conflicts .projex/ >/dev/null 2>&1
chk "rebase: closes after full resolution" "$?" "0"
chk "rebase: final content kept" "$(git -C "$R" show main:.projex/doc.md | tr -d '\r\n')" "second"

echo "--- mid-flight re-run must not abort an UNCOVERED conflict either"
R=$(mkrepo midunc 1 0)
gc "$R" checkout -q main 2>/dev/null
git -C "$R" rebase projex/eph >/dev/null 2>&1 || true   # hand-rolled conflicting rebase, uncovered paths
chk "setup: rebase in flight" "$(inprog "$R")" "y"
"$SCRIPTS/projex-rebase-close.sh" "$R" main projex/eph --resolve-conflicts .projex/ >/dev/null 2>&1
chk "rebase: uncovered mid-flight refuses" "$?" "1"
chk "rebase: uncovered mid-flight not aborted" "$(inprog "$R")" "y"

echo "--- agent resumes, then runs the script a THIRD time (double-close)"
R=$(mkrepo triple 0 0); stop_merge "$R"
printf 'r\n' > "$R/.projex/doc.md"; git -C "$R" add .projex/doc.md; gc "$R" commit -q --no-edit
"$SCRIPTS/projex-merge-close.sh" "$R" main projex/eph "msg" --resolve-conflicts .projex/ >/dev/null 2>&1
head_after=$(git -C "$R" rev-parse HEAD)
"$SCRIPTS/projex-merge-close.sh" "$R" main projex/eph "msg" --resolve-conflicts .projex/ >/dev/null 2>&1
chk "merge: third run refuses (branch gone)" "$?" "1"
chk "merge: third run moves nothing" "$(git -C "$R" rev-parse HEAD)" "$head_after"

echo "--- squash: branch with no net changes is not mistaken for a failure"
R="$ROOT/netzero"; mkdir -p "$R"; git -C "$R" init -q -b main
printf 'a\n' > "$R/a.txt"; git -C "$R" add a.txt >/dev/null; gc "$R" commit -qm init
git -C "$R" checkout -qb projex/eph; printf 'b\n' > "$R/a.txt"; git -C "$R" add a.txt >/dev/null; gc "$R" commit -qm change
printf 'a\n' > "$R/a.txt"; git -C "$R" add a.txt >/dev/null; gc "$R" commit -qm revert
git -C "$R" checkout -q main
"$SCRIPTS/projex-squash-close.sh" "$R" main projex/eph "msg" >/dev/null 2>&1
chk "squash: net-zero branch closes" "$?" "0"
chk "squash: net-zero leaves tree clean" "$(git -C "$R" status --porcelain)" ""
chk "squash: net-zero content intact" "$(git -C "$R" show main:a.txt | tr -d '\r\n')" "a"

echo "--- pre-existing dirt unrelated to the close still blocks (no free-riding)"
R=$(mkrepo dirty 0 0)
printf 'scratch\n' > "$R/src.txt"
"$SCRIPTS/projex-merge-close.sh" "$R" main projex/eph "msg" --resolve-conflicts .projex/ >/dev/null 2>&1
chk "merge: unrelated dirt refuses" "$?" "1"
chk "merge: unrelated dirt preserved" "$(cat "$R/src.txt" | tr -d '\r\n')" "scratch"

echo "PASS=$PASS FAIL=$FAIL"
rm -rf "$ROOT"
[ "$FAIL" -eq 0 ]
