#!/usr/bin/env bash
# Behavioural contract for close-precheck.sh. Fixtures are throwaway repositories.
set -u

SCRIPT_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)
SCRIPT="$SCRIPT_ROOT/close-precheck.sh"
TMP_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/close-precheck-test.XXXXXX")
PASS_COUNT=0
FAIL_COUNT=0
FIXTURE_REPO=''
FIXTURE_CHILD=''
CHECKOUT_REPO=''

cleanup() {
  if [ -n "$FIXTURE_REPO" ] && [ -d "$FIXTURE_REPO" ]; then
    git -C "$FIXTURE_REPO" worktree remove --force "$FIXTURE_CHILD" >/dev/null 2>&1 || true
  fi
  rm -rf "$TMP_ROOT"
}
trap cleanup EXIT

chk() {
  local name=$1 got=$2 want=$3
  if [ "$got" = "$want" ]; then PASS_COUNT=$((PASS_COUNT + 1)); else printf 'FAIL: %s (got=%q want=%q)\n' "$name" "$got" "$want"; FAIL_COUNT=$((FAIL_COUNT + 1)); fi
}

has() {
  local name=$1 haystack=$2 needle=$3
  if printf '%s\n' "$haystack" | grep -F -q -- "$needle"; then PASS_COUNT=$((PASS_COUNT + 1)); else printf 'FAIL: %s (missing %q)\n' "$name" "$needle"; FAIL_COUNT=$((FAIL_COUNT + 1)); fi
}

not_has() {
  local name=$1 haystack=$2 needle=$3
  if printf '%s\n' "$haystack" | grep -F -q -- "$needle"; then printf 'FAIL: %s (unexpected %q)\n' "$name" "$needle"; FAIL_COUNT=$((FAIL_COUNT + 1)); else PASS_COUNT=$((PASS_COUNT + 1)); fi
}

at_least() {
  local name=$1 got=$2 minimum=$3
  if [ "$got" -ge "$minimum" ]; then PASS_COUNT=$((PASS_COUNT + 1)); else printf 'FAIL: %s (got=%s minimum=%s)\n' "$name" "$got" "$minimum"; FAIL_COUNT=$((FAIL_COUNT + 1)); fi
}

run_report() {
  local cwd=$1 plan=$2
  set +e
  REPORT=$(cd "$cwd" && bash "$SCRIPT" "$plan" 2>/dev/null)
  REPORT_RC=$?
  set -e
}

run_noarg() {
  local cwd=$1
  set +e
  NOARG_REPORT=$(cd "$cwd" && bash "$SCRIPT" 2>/dev/null)
  NOARG_RC=$?
  set -e
}

run_failure() {
  local cwd=$1 plan=$2
  set +e
  FAILURE_REPORT=$(cd "$cwd" && bash "$SCRIPT" "$plan" 2>/dev/null)
  FAILURE_RC=$?
  set -e
}

make_git_repo() {
  local repo=$1
  mkdir -p "$repo"
  git init -q "$repo"
  git -C "$repo" checkout -q -b main
  git -C "$repo" config user.email fixture@example.invalid
  git -C "$repo" config user.name fixture
  printf 'fixture\n' > "$repo/README"
  git -C "$repo" add README
  git -C "$repo" commit -qm 'fixture: initial'
  mkdir -p "$repo/.projex"
}

PLAN_NAME=2608081953-close-precheck-script-plan.md
LOG_NAME=fixture-close-precheck-log.md
BRANCH_NAME=projex/2608090541-close-precheck-script-plan

# --- Worktree-mode fixture ---
FIXTURE_REPO="$TMP_ROOT/worktree-repo"
make_git_repo "$FIXTURE_REPO"
printf '# Plan\n\n> **Status:** In Progress\n> **Log:** %s\n\n%s\n' "$LOG_NAME" "$PLAN_NAME" > "$FIXTURE_REPO/.projex/$PLAN_NAME"
git -C "$FIXTURE_REPO" add ".projex/$PLAN_NAME"
git -C "$FIXTURE_REPO" commit -qm 'fixture: plan'
FIXTURE_CHILD="$FIXTURE_REPO/.projexwt/child"
git -C "$FIXTURE_REPO" worktree add -q -b "$BRANCH_NAME" "$FIXTURE_CHILD" main
cat > "$FIXTURE_CHILD/.projex/$LOG_NAME" <<EOF
# Execution Log

> **Status:** In Progress
> **Repo Root:** $FIXTURE_REPO
> **Plan File:** .projex/$PLAN_NAME
> **Base Branch:** main
> **Worktree Path:** $FIXTURE_CHILD

$PLAN_NAME
EOF
git -C "$FIXTURE_CHILD" add ".projex/$LOG_NAME"
git -C "$FIXTURE_CHILD" commit -qm 'fixture: execution log'
printf 'ephemeral change\n' > "$FIXTURE_CHILD/changed.txt"
git -C "$FIXTURE_CHILD" add changed.txt
git -C "$FIXTURE_CHILD" commit -qm 'fixture: implementation'
printf '# Base-only auxiliary\n%s\n\n> **Status:** Draft\n' "$PLAN_NAME" > "$FIXTURE_REPO/.projex/base-only.md"
git -C "$FIXTURE_REPO" add .projex/base-only.md
git -C "$FIXTURE_REPO" commit -qm 'fixture: base auxiliary'
printf '# Untracked auxiliary\n%s\n\n> **Status:** Draft\n' "$PLAN_NAME" > "$FIXTURE_REPO/.projex/untracked.md"
printf '# Child-only auxiliary\n%s\n' "$PLAN_NAME" > "$FIXTURE_CHILD/.projex/child-only.md"
printf '%s\n' 'before report' > "$FIXTURE_REPO/preexisting.txt"

BASE_BEFORE=$(git -C "$FIXTURE_REPO" rev-parse refs/heads/main)
EPHEMERAL_BEFORE=$(git -C "$FIXTURE_REPO" rev-parse "refs/heads/$BRANCH_NAME")
WORKTREES_BEFORE=$(git -C "$FIXTURE_REPO" worktree list --porcelain | sha256sum)
run_report "$FIXTURE_CHILD" ".projex/$PLAN_NAME"
chk 'explicit worktree run succeeds with warnings' "$REPORT_RC" 0
has 'schema version' "$REPORT" 'SCHEMA_VERSION=1'
has 'encoded repo root' "$REPORT" 'REPO_ROOT=%2F'
has 'encoded ephemeral branch slash' "$REPORT" 'EPHEMERAL_BRANCH=projex%2F'
has 'snapshot base sha' "$REPORT" 'BASE_SHA='
has 'snapshot ephemeral sha' "$REPORT" 'EPHEMERAL_SHA='
has 'worktree identity path' "$REPORT" 'WORKTREE_PATH=%2F'
has 'commit section' "$REPORT" 'SECTION=COMMITS'
has 'diff section' "$REPORT" 'SECTION=DIFF_STAT'
has 'inventory section' "$REPORT" 'SECTION=PROJEX_INVENTORY'
has 'stash section' "$REPORT" 'SECTION=STASHES'
has 'gate section' "$REPORT" 'SECTION=GATES'
has 'ephemeral inventory class' "$REPORT" 'tracked-on-ephemeral'
has 'base-only inventory class' "$REPORT" 'tracked-on-base'
has 'untracked inventory class' "$REPORT" 'untracked'
has 'child inventory location' "$REPORT" $'\tCHILD\t'
has 'also on base annotation' "$REPORT" $'\tyes'
has 'child gate warning' "$REPORT" $'GATE\tCHILD_WORKTREE\tWARN\t'
has 'warning result' "$REPORT" 'RESULT=PASS_WITH_WARNINGS'
not_has 'raw worktree path is not emitted' "$REPORT" "$FIXTURE_CHILD"
chk 'base ref unchanged' "$(git -C "$FIXTURE_REPO" rev-parse refs/heads/main)" "$BASE_BEFORE"
chk 'ephemeral ref unchanged' "$(git -C "$FIXTURE_REPO" rev-parse "refs/heads/$BRANCH_NAME")" "$EPHEMERAL_BEFORE"
chk 'worktree registration unchanged' "$(git -C "$FIXTURE_REPO" worktree list --porcelain | sha256sum)" "$WORKTREES_BEFORE"

run_noarg "$FIXTURE_CHILD"
chk 'no-argument branch inference succeeds' "$NOARG_RC" 0
has 'no-argument result' "$NOARG_REPORT" 'RESULT=PASS_WITH_WARNINGS'

# Missing and duplicate required headers are hard context errors with encoded records.
printf '# Execution Log\n\n> **Repo Root:** %s\n> **Worktree Path:** %s\n' "$FIXTURE_REPO" "$FIXTURE_CHILD" > "$FIXTURE_CHILD/.projex/$LOG_NAME"
run_failure "$FIXTURE_CHILD" ".projex/$PLAN_NAME"
chk 'missing base header fails' "$FAILURE_RC" 1
has 'missing base encoded error' "$FAILURE_REPORT" 'ERROR='
has 'missing base terminal result' "$FAILURE_REPORT" 'RESULT=ERROR'
printf '# Execution Log\n\n> **Repo Root:** %s\n> **Base Branch:** main\n> **Base Branch:** main\n> **Worktree Path:** %s\n' "$FIXTURE_REPO" "$FIXTURE_CHILD" > "$FIXTURE_CHILD/.projex/$LOG_NAME"
run_failure "$FIXTURE_CHILD" ".projex/$PLAN_NAME"
chk 'duplicate base header fails' "$FAILURE_RC" 1
has 'duplicate base terminal result' "$FAILURE_REPORT" 'RESULT=ERROR'

# Explicit missing plan and wrong branch are rejected before a false result.
run_failure "$FIXTURE_CHILD" ".projex/does-not-exist.md"
chk 'missing plan fails' "$FAILURE_RC" 1
has 'missing plan result' "$FAILURE_REPORT" 'RESULT=ERROR'
run_noarg "$FIXTURE_REPO"
chk 'no-argument main branch fails' "$NOARG_RC" 1
has 'main branch result' "$NOARG_REPORT" 'RESULT=ERROR'

# --- Required safety-matrix extensions ---
restore_worktree_log() {
  cat > "$FIXTURE_CHILD/.projex/$LOG_NAME" <<EOF
# Execution Log

> **Status:** In Progress
> **Repo Root:** $FIXTURE_REPO
> **Plan File:** .projex/$PLAN_NAME
> **Base Branch:** main
> **Worktree Path:** $FIXTURE_CHILD

$PLAN_NAME
EOF
}

# Resolution errors: plan log, base branch, relative/aliased/escaping/reused worktree paths.
printf '# Plan\n\n> **Status:** In Progress\n> **Log:** missing-log.md\n' > "$FIXTURE_CHILD/.projex/$PLAN_NAME"
run_failure "$FIXTURE_CHILD" ".projex/$PLAN_NAME"
chk 'missing plan log fails' "$FAILURE_RC" 1
restore_worktree_log
printf '# Plan\n\n> **Status:** In Progress\n> **Log:** %s\n> **Log:** %s\n' "$LOG_NAME" "$LOG_NAME" > "$FIXTURE_CHILD/.projex/$PLAN_NAME"
run_failure "$FIXTURE_CHILD" ".projex/$PLAN_NAME"
chk 'duplicate plan log header fails' "$FAILURE_RC" 1
printf '# Plan\n\n> **Status:** In Progress\n> **Log:** %s\n\n%s\n' "$LOG_NAME" "$PLAN_NAME" > "$FIXTURE_CHILD/.projex/$PLAN_NAME"
restore_worktree_log
printf '%s\n' '> **Base Branch:** refs/remotes/origin/main' >> "$FIXTURE_CHILD/.projex/$LOG_NAME"
run_failure "$FIXTURE_CHILD" ".projex/$PLAN_NAME"
chk 'remote base branch fails' "$FAILURE_RC" 1
restore_worktree_log
sed -i "s|$FIXTURE_CHILD|.projexwt/child|" "$FIXTURE_CHILD/.projex/$LOG_NAME"
run_report "$FIXTURE_CHILD" ".projex/$PLAN_NAME"
chk 'relative worktree path succeeds' "$REPORT_RC" 0
ln -s "$FIXTURE_CHILD" "$FIXTURE_REPO/alias-child"
sed -i "s|.projexwt/child|$FIXTURE_REPO/alias-child|" "$FIXTURE_CHILD/.projex/$LOG_NAME"
run_report "$FIXTURE_CHILD" ".projex/$PLAN_NAME"
chk 'registered in-repo symlink alias succeeds' "$REPORT_RC" 0
ln -s "$TMP_ROOT" "$FIXTURE_REPO/escaping-child"
sed -i "s|$FIXTURE_REPO/alias-child|$FIXTURE_REPO/escaping-child|" "$FIXTURE_CHILD/.projex/$LOG_NAME"
run_failure "$FIXTURE_CHILD" ".projex/$PLAN_NAME"
chk 'escaping worktree symlink fails' "$FAILURE_RC" 1
restore_worktree_log
sed -i "s|$FIXTURE_CHILD|$FIXTURE_REPO|" "$FIXTURE_CHILD/.projex/$LOG_NAME"
run_failure "$FIXTURE_CHILD" ".projex/$PLAN_NAME"
chk 'reused origin worktree path fails' "$FAILURE_RC" 1
restore_worktree_log

# Ambiguity, status, encoding, gates, stash, and 100x10 candidate scale fixture.
printf '# Duplicate plan\n' > "$FIXTURE_CHILD/.projex/2608099999-close-precheck-script-plan.md"
run_noarg "$FIXTURE_CHILD"
chk 'ambiguous no-argument plan fails' "$NOARG_RC" 1
rm "$FIXTURE_CHILD/.projex/2608099999-close-precheck-script-plan.md"
printf '# Missing status\n%s\n' "$PLAN_NAME" > "$FIXTURE_CHILD/.projex/missing-status.md"
printf '# Odd\n%s\n\n> **Status:** Draft%%=\n' "$PLAN_NAME" > "$FIXTURE_CHILD/.projex/odd %= name.md"
printf 'ignored.bin\n' > "$FIXTURE_CHILD/.gitignore"
printf 'ignored\n' > "$FIXTURE_CHILD/ignored.bin"
printf 'modified\n' > "$FIXTURE_CHILD/modified.txt"
printf 'origin dirty\n' >> "$FIXTURE_REPO/README"
run_report "$FIXTURE_CHILD" ".projex/$PLAN_NAME"
chk 'dirty origin and child report succeeds' "$REPORT_RC" 0
has 'missing status remains factual' "$REPORT" $'\tMISSING\t'
has 'encoded unsafe path' "$REPORT" 'odd%20%25%3D%20name.md'
has 'encoded unsafe status' "$REPORT" 'Draft%25%3D'
not_has 'unsafe path never raw record text' "$REPORT" 'odd %= name.md'
has 'origin gate warning' "$REPORT" $'GATE\tORIGIN_BASE\tWARN\t'
has 'ignored child gate warning' "$REPORT" $'GATE\tCHILD_WORKTREE\tWARN\t'
for d in $(seq 1 100); do
  mkdir -p "$FIXTURE_CHILD/scale-$d/.projex"
  for n in $(seq 1 10); do printf '# Scale\n%s\n\n> **Status:** Draft\n' "$PLAN_NAME" > "$FIXTURE_CHILD/scale-$d/.projex/candidate-$n.md"; done
done
run_report "$FIXTURE_CHILD" ".projex/$PLAN_NAME"
chk 'scale report succeeds without truncation' "$REPORT_RC" 0
at_least 'scale inventory has 1000 candidates' "$(printf '%s\n' "$REPORT" | grep -c $'RECORD=PROJEX\t')" 1000
rm -rf "$FIXTURE_CHILD"/scale-*

# A wrapper injects an over-budget read result and snapshot drift without altering the utility.
WRAPPER_DIR="$TMP_ROOT/git-wrapper"
mkdir -p "$WRAPPER_DIR"
REAL_GIT=$(command -v git)
cat > "$WRAPPER_DIR/git" <<'EOF'
#!/usr/bin/env bash
set -u
count_file=${CLOSE_PRECHECK_COUNT_FILE:?}
mode=${CLOSE_PRECHECK_MODE:?}
if [[ " $* " == *' stash list '* ]] && [ "$mode" = budget ]; then
  i=0
  while [ "$i" -lt 100 ]; do printf 'stash@{%s}: %060d\n' "$i" "$i"; i=$((i + 1)); done
  exit 0
fi
if [[ " $* " == *' rev-parse --verify --quiet refs/heads/main '* ]] && [ "$mode" = ref ]; then
  n=0; [ -f "$count_file" ] && n=$(cat "$count_file")
  n=$((n + 1)); printf '%s' "$n" > "$count_file"
  if [ "$n" -eq 2 ]; then "$REAL_GIT" -C "$CLOSE_PRECHECK_DRIFT_REPO" commit --allow-empty -qm 'fixture: ref drift'; fi
fi
if [[ " $* " == *' worktree list --porcelain '* ]] && [ "$mode" = worktree ]; then
  n=0; [ -f "$count_file" ] && n=$(cat "$count_file")
  n=$((n + 1)); printf '%s' "$n" > "$count_file"
  if [ "$n" -eq 2 ]; then "$REAL_GIT" -C "$CLOSE_PRECHECK_DRIFT_REPO" worktree lock --reason drift "$CLOSE_PRECHECK_DRIFT_CHILD"; fi
fi
exec "$REAL_GIT" "$@"
EOF
chmod +x "$WRAPPER_DIR/git"
run_wrapped() {
  local mode=$1 runner=${2:-$SCRIPT}
  rm -f "$TMP_ROOT/wrapper-count"
  set +e
  REPORT=$(cd "$FIXTURE_CHILD" && PATH="$WRAPPER_DIR:$PATH" REAL_GIT="$REAL_GIT" CLOSE_PRECHECK_COUNT_FILE="$TMP_ROOT/wrapper-count" CLOSE_PRECHECK_MODE="$mode" CLOSE_PRECHECK_DRIFT_REPO="$FIXTURE_REPO" CLOSE_PRECHECK_DRIFT_CHILD="$FIXTURE_CHILD" bash "$runner" ".projex/$PLAN_NAME" 2>/dev/null)
  REPORT_RC=$?
  set -e
}
BUDGET_SCRIPT="$TMP_ROOT/close-precheck-small-budget.sh"
sed 's/^MAX_OUTPUT=.*/MAX_OUTPUT=1024/' "$SCRIPT" > "$BUDGET_SCRIPT"
chmod +x "$BUDGET_SCRIPT"
run_wrapped budget "$BUDGET_SCRIPT"
chk 'controlled output budget breach fails closed' "$REPORT_RC" 1
has 'output budget terminal error' "$REPORT" 'RESULT=ERROR'
run_wrapped ref
chk 'ref snapshot drift fails closed' "$REPORT_RC" 1
has 'ref snapshot stale result' "$REPORT" 'RESULT=STALE'
run_wrapped worktree
chk 'worktree registration drift fails closed' "$REPORT_RC" 1
has 'worktree snapshot stale result' "$REPORT" 'RESULT=STALE'
git -C "$FIXTURE_REPO" worktree unlock "$FIXTURE_CHILD"

# Static contract guard: no implementation mutation command or eval construction.
if grep -E -q '^[[:space:]]*git -C "[^\"]*" (add|commit|checkout|merge|rebase|reset|stash (push|pop|drop)|worktree (add|remove))([[:space:]]|$)|^[[:space:]]*eval([[:space:]]|$)' "$SCRIPT"; then
  chk 'read-only Git allowlist' bad good
else
  chk 'read-only Git allowlist' good good
fi

# --- Checkout-mode fixture ---
CHECKOUT_REPO="$TMP_ROOT/checkout-repo"
make_git_repo "$CHECKOUT_REPO"
CHECKOUT_PLAN=2608090000-checkout-plan.md
CHECKOUT_LOG=2608090000-checkout-plan-log.md
CHECKOUT_BRANCH=projex/2608090000-checkout-plan
printf '# Checkout plan\n\n> **Status:** In Progress\n> **Log:** %s\n\n%s\n' "$CHECKOUT_LOG" "$CHECKOUT_PLAN" > "$CHECKOUT_REPO/.projex/$CHECKOUT_PLAN"
git -C "$CHECKOUT_REPO" add ".projex/$CHECKOUT_PLAN"
git -C "$CHECKOUT_REPO" commit -qm 'fixture: checkout plan'
git -C "$CHECKOUT_REPO" checkout -q -b "$CHECKOUT_BRANCH"
cat > "$CHECKOUT_REPO/.projex/$CHECKOUT_LOG" <<EOF
# Execution Log

> **Status:** In Progress
> **Repo Root:** $CHECKOUT_REPO
> **Plan File:** .projex/$CHECKOUT_PLAN
> **Base Branch:** main

$CHECKOUT_PLAN
EOF
git -C "$CHECKOUT_REPO" add ".projex/$CHECKOUT_LOG"
git -C "$CHECKOUT_REPO" commit -qm 'fixture: checkout log'
run_report "$CHECKOUT_REPO" ".projex/$CHECKOUT_PLAN"
chk 'checkout-mode run succeeds' "$REPORT_RC" 0
has 'checkout-mode child gate N/A' "$REPORT" $'GATE\tCHILD_WORKTREE\tN/A\t'
has 'checkout-mode result' "$REPORT" 'RESULT=PASS'
has 'checkout commit list record' "$REPORT" $'RECORD=COMMIT\t'

printf 'PASS=%s FAIL=%s\n' "$PASS_COUNT" "$FAIL_COUNT"
[ "$FAIL_COUNT" -eq 0 ]
