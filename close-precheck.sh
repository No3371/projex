#!/usr/bin/env bash
# close-precheck.sh — report-only close-context preflight
# Usage: close-precheck.sh [<plan-file>]
#
# The report is advisory. It never changes refs, the index, worktrees, files, or stashes.

set -euo pipefail

LC_ALL=C
export LC_ALL

MAX_OUTPUT=$((8 * 1024 * 1024))
TMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/close-precheck.XXXXXX") || exit 1
OUT_FILE="$TMP_DIR/report"
mkdir -p "$TMP_DIR"
: > "$OUT_FILE"
trap 'rm -rf "$TMP_DIR"' EXIT

# Bash cannot safely carry NUL bytes in variables. Git ref names, paths, and subjects
# are line-oriented here; every other byte is escaped before entering the report.
percent_encode() {
  local value=${1-} out='' byte code hex
  while [ -n "$value" ]; do
    byte=${value%"${value#?}"}
    value=${value#?}
    case "$byte" in
      [A-Za-z0-9._~-]) out+="$byte" ;;
      *)
        printf -v code '%d' "'${byte}"
        printf -v hex '%02X' "$code"
        out+="%$hex"
        ;;
    esac
  done
  printf '%s' "$out"
}

budget_error() {
  : > "$OUT_FILE"
  printf 'SCHEMA_VERSION=1\n' >> "$OUT_FILE"
  printf 'ERROR=%s\n' "$(percent_encode 'report output exceeds 8 MiB budget')" >> "$OUT_FILE"
  printf 'RESULT=ERROR\n' >> "$OUT_FILE"
  cat "$OUT_FILE"
  exit 1
}

emit_line() {
  local line=${1-} size
  printf '%s\n' "$line" >> "$OUT_FILE" || {
    : > "$OUT_FILE"
    printf 'SCHEMA_VERSION=1\n' >> "$OUT_FILE"
    printf 'ERROR=%s\n' "$(percent_encode 'unable to write report')" >> "$OUT_FILE"
    printf 'RESULT=ERROR\n' >> "$OUT_FILE"
    cat "$OUT_FILE"
    exit 1
  }
  size=$(wc -c < "$OUT_FILE")
  size=${size//[[:space:]]/}
  if [ "$size" -gt "$MAX_OUTPUT" ]; then
    budget_error
  fi
}

fatal() {
  local message=${1-unknown error}
  : > "$OUT_FILE"
  printf 'SCHEMA_VERSION=1\n' >> "$OUT_FILE"
  printf 'ERROR=%s\n' "$(percent_encode "$message")" >> "$OUT_FILE"
  printf 'RESULT=ERROR\n' >> "$OUT_FILE"
  cat "$OUT_FILE"
  exit 1
}

if [ "$#" -gt 1 ]; then
  fatal 'usage: close-precheck.sh [plan-file]'
fi

is_under() {
  local child=$1 parent=$2
  [ "$child" = "$parent" ] || case "$child" in "$parent"/*) return 0 ;; *) return 1 ;; esac
}

canonical_file() {
  local path=$1
  [ -f "$path" ] || return 1
  readlink -f -- "$path"
}

canonical_dir() {
  local path=$1
  [ -d "$path" ] || return 1
  readlink -f -- "$path"
}

relative_to() {
  local path=$1 root=$2
  if [ "$path" = "$root" ]; then
    printf ''
  elif is_under "$path" "$root"; then
    printf '%s' "${path#"$root"/}"
  else
    return 1
  fi
}

git_common_dir() {
  local dir=$1 raw
  raw=$(git -C "$dir" rev-parse --git-common-dir 2>/dev/null) || return 1
  case "$raw" in
    /*) readlink -f -- "$raw" ;;
    *) readlink -f -- "$dir/$raw" ;;
  esac
}

# Resolve the explicit plan or the sole plan whose filename suffix matches the
# current projex/* branch. No-argument inference is intentionally narrow.
if [ "$#" -eq 1 ]; then
  PLAN_ARG=$1
  [ -f "$PLAN_ARG" ] || fatal 'plan file not found'
  PLAN_PATH=$(canonical_file "$PLAN_ARG") || fatal 'plan file is inaccessible'
else
  CALLER_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || fatal 'cannot resolve repository from current directory'
  CALLER_ROOT=$(readlink -f -- "$CALLER_ROOT") || fatal 'repository root is inaccessible'
  CURRENT_BRANCH=$(git -C "$CALLER_ROOT" branch --show-current 2>/dev/null) || fatal 'cannot resolve current branch'
  case "$CURRENT_BRANCH" in
    projex/*) ;;
    *) fatal 'no-argument inference requires a projex/* branch' ;;
  esac
  BRANCH_SUFFIX=${CURRENT_BRANCH#projex/}
  case "$BRANCH_SUFFIX" in
    [0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-*)
      BRANCH_NAME=${BRANCH_SUFFIX:11} ;;
    *) BRANCH_NAME=$BRANCH_SUFFIX ;;
  esac
  CANDIDATE_FILE="$TMP_DIR/candidates"
  : > "$CANDIDATE_FILE"
  while IFS= read -r -d '' candidate; do
    candidate_base=${candidate##*/}
    case "$candidate_base" in
      [0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-*-plan.md) ;;
      *) continue ;;
    esac
    candidate_stem=${candidate_base%.md}
    candidate_suffix=${candidate_stem:11}
    [ "$candidate_suffix" = "$BRANCH_NAME" ] || continue
    printf '%s\n' "$candidate" >> "$CANDIDATE_FILE"
  done < <(find -P "$CALLER_ROOT" \( -type d \( -name .git -o -name .projexwt \) -prune \) -o \( -type f -path '*/.projex/*-plan.md' -print0 \))
  mapfile -t CANDIDATES < "$CANDIDATE_FILE"
  [ "${#CANDIDATES[@]}" -eq 1 ] || fatal 'no-argument plan inference is missing or ambiguous'
  PLAN_PATH=$(canonical_file "${CANDIDATES[0]}") || fatal 'inferred plan file is inaccessible'
fi

PLAN_DIR=$(dirname "$PLAN_PATH")
PLAN_BASE=${PLAN_PATH##*/}
PLAN_REPO=$(git -C "$PLAN_DIR" rev-parse --show-toplevel 2>/dev/null) || fatal 'plan is not inside a Git repository'
PLAN_REPO=$(readlink -f -- "$PLAN_REPO") || fatal 'plan repository root is inaccessible'
PLAN_COMMON=$(git_common_dir "$PLAN_DIR") || fatal 'cannot resolve plan repository identity'

# Read the plan's authoritative log pointer. A fallback is only the sibling
# <plan-stem>-log.md file; no directory traversal is accepted in a pointer.
LOG_COUNT=0
LOG_VALUE=''
while IFS= read -r plan_line || [ -n "$plan_line" ]; do
  case "$plan_line" in
    '> **Log:** '*)
      LOG_COUNT=$((LOG_COUNT + 1))
      LOG_VALUE=${plan_line#'> **Log:** '}
      ;;
    '> **Log:**'*) fatal 'malformed Log header in plan' ;;
  esac
done < "$PLAN_PATH"
[ "$LOG_COUNT" -le 1 ] || fatal 'duplicate Log header in plan'
if [ "$LOG_COUNT" -eq 1 ]; then
  [ -n "$LOG_VALUE" ] || fatal 'empty Log header in plan'
  case "$LOG_VALUE" in
    /*|*/*|*\\*|*..*) fatal 'Log header must name a sibling filename' ;;
  esac
  LOG_PATH=$(canonical_file "$PLAN_DIR/$LOG_VALUE") || fatal 'execution log from plan is missing or inaccessible'
else
  LOG_PATH=$(canonical_file "$PLAN_DIR/${PLAN_BASE%.md}-log.md") || fatal 'execution log is missing or inaccessible'
fi

LOG_DIR=$(dirname "$LOG_PATH")
LOG_COMMON=$(git_common_dir "$LOG_DIR") || fatal 'execution log is not in a Git worktree'
[ "$LOG_COMMON" = "$PLAN_COMMON" ] || fatal 'plan and execution log are not in the same repository'

# Parse strict execution-log context headers. Header-like malformed lines are
# rejected rather than silently treated as absent.
REPO_ROOT_COUNT=0
BASE_BRANCH_COUNT=0
WORKTREE_PATH_COUNT=0
RECORDED_ROOT=''
BASE_BRANCH=''
RECORDED_WORKTREE=''
while IFS= read -r log_line || [ -n "$log_line" ]; do
  case "$log_line" in
    '> **Repo Root:** '*)
      REPO_ROOT_COUNT=$((REPO_ROOT_COUNT + 1))
      RECORDED_ROOT=${log_line#'> **Repo Root:** '}
      ;;
    '> **Repo Root:**'*) fatal 'malformed Repo Root header in execution log' ;;
    '> **Base Branch:** '*)
      BASE_BRANCH_COUNT=$((BASE_BRANCH_COUNT + 1))
      BASE_BRANCH=${log_line#'> **Base Branch:** '}
      ;;
    '> **Base Branch:**'*) fatal 'malformed Base Branch header in execution log' ;;
    '> **Worktree Path:** '*)
      WORKTREE_PATH_COUNT=$((WORKTREE_PATH_COUNT + 1))
      RECORDED_WORKTREE=${log_line#'> **Worktree Path:** '}
      ;;
    '> **Worktree Path:**'*) fatal 'malformed Worktree Path header in execution log' ;;
  esac
done < "$LOG_PATH"
[ "$REPO_ROOT_COUNT" -eq 1 ] || fatal 'execution log must contain exactly one Repo Root header'
[ "$BASE_BRANCH_COUNT" -eq 1 ] || fatal 'execution log must contain exactly one Base Branch header'
[ "$WORKTREE_PATH_COUNT" -le 1 ] || fatal 'duplicate Worktree Path header in execution log'
[ -n "$RECORDED_ROOT" ] || fatal 'empty Repo Root header in execution log'
[ -n "$BASE_BRANCH" ] || fatal 'empty Base Branch header in execution log'

RECORDED_ROOT=$(canonical_dir "$RECORDED_ROOT") || fatal 'recorded Repo Root is missing or inaccessible'
[ "$RECORDED_ROOT" = "$PLAN_REPO" ] || {
  # A plan in the child worktree shares the repository but not its checkout root.
  [ "$PLAN_COMMON" = "$(git_common_dir "$RECORDED_ROOT" 2>/dev/null || true)" ] || fatal 'recorded Repo Root is not the plan repository'
}
[ "$RECORDED_ROOT" = "$PLAN_REPO" ] || [ "$PLAN_COMMON" = "$(git_common_dir "$RECORDED_ROOT" 2>/dev/null || true)" ] || fatal 'recorded Repo Root is not the plan repository'
REPO_ROOT=$RECORDED_ROOT

# Validate the recorded base as a local branch without guessing main/master.
case "$BASE_BRANCH" in
  ''|-*|refs/*|*'..'*|*/|/*|*'//'*) fatal 'invalid Base Branch header' ;;
esac
if ! git -C "$REPO_ROOT" show-ref --verify --quiet "refs/heads/$BASE_BRANCH"; then
  fatal 'Base Branch is not a local branch'
fi
BASE_SHA=$(git -C "$REPO_ROOT" rev-parse --verify --quiet "refs/heads/$BASE_BRANCH") || fatal 'cannot read Base Branch tip'

ROOT_CURRENT_BRANCH=$(git -C "$REPO_ROOT" branch --show-current 2>/dev/null) || fatal 'cannot read originating checkout branch'
ORIGIN_HEAD=$(git -C "$REPO_ROOT" rev-parse --verify HEAD 2>/dev/null) || fatal 'cannot read originating checkout HEAD'

# Worktree registration is parsed from porcelain output, not inferred from a
# path. This makes a reused path or branch/HEAD mismatch a hard context error.
WORKTREE_MODE=0
WORKTREE_PATH=''
WORKTREE_HEAD=''
WORKTREE_BRANCH=''
if [ "$WORKTREE_PATH_COUNT" -eq 1 ]; then
  [ -n "$RECORDED_WORKTREE" ] || fatal 'empty Worktree Path header in execution log'
  case "$RECORDED_WORKTREE" in
    /*) WORKTREE_CANDIDATE=$RECORDED_WORKTREE ;;
    *) WORKTREE_CANDIDATE="$REPO_ROOT/$RECORDED_WORKTREE" ;;
  esac
  WORKTREE_PATH=$(canonical_dir "$WORKTREE_CANDIDATE") || fatal 'recorded Worktree Path is missing or inaccessible'
  is_under "$WORKTREE_PATH" "$REPO_ROOT" || fatal 'recorded Worktree Path escapes Repo Root'
  [ "$WORKTREE_PATH" != "$REPO_ROOT" ] || fatal 'recorded Worktree Path reuses Repo Root'
  WORKTREE_MODE=1
fi

WT_DATA="$TMP_DIR/worktrees"
git -C "$REPO_ROOT" worktree list --porcelain > "$WT_DATA" 2>/dev/null || fatal 'cannot read worktree registrations'

if [ "$WORKTREE_MODE" -eq 1 ]; then
  FOUND=0
  WT_PATH_RAW=''
  WT_HEAD_RAW=''
  WT_BRANCH_RAW=''
  while IFS= read -r wt_line || [ -n "$wt_line" ]; do
    case "$wt_line" in
      'worktree '*)
        if [ -n "$WT_PATH_RAW" ]; then
          WT_CANON=$(readlink -f -- "$WT_PATH_RAW") || fatal 'invalid worktree registration path'
          if [ "$WT_CANON" = "$WORKTREE_PATH" ]; then
            [ "$FOUND" -eq 0 ] || fatal 'duplicate worktree registration for recorded path'
            FOUND=1
            WT_HEAD_RAW_CURRENT=$WT_HEAD_RAW
            WT_BRANCH_RAW_CURRENT=$WT_BRANCH_RAW
          fi
        fi
        WT_PATH_RAW=${wt_line#worktree }
        WT_HEAD_RAW=''
        WT_BRANCH_RAW=''
        ;;
      'HEAD '*) WT_HEAD_RAW=${wt_line#HEAD } ;;
      'branch '*) WT_BRANCH_RAW=${wt_line#branch } ;;
    esac
  done < "$WT_DATA"
  if [ -n "$WT_PATH_RAW" ]; then
    WT_CANON=$(readlink -f -- "$WT_PATH_RAW") || fatal 'invalid worktree registration path'
    if [ "$WT_CANON" = "$WORKTREE_PATH" ]; then
      [ "$FOUND" -eq 0 ] || fatal 'duplicate worktree registration for recorded path'
      FOUND=1
      WT_HEAD_RAW_CURRENT=$WT_HEAD_RAW
      WT_BRANCH_RAW_CURRENT=$WT_BRANCH_RAW
    fi
  fi
  [ "$FOUND" -eq 1 ] || fatal 'recorded Worktree Path is not registered'
  case "$WT_BRANCH_RAW_CURRENT" in
    refs/heads/*) WORKTREE_BRANCH=${WT_BRANCH_RAW_CURRENT#refs/heads/} ;;
    *) fatal 'recorded worktree is detached or has no branch' ;;
  esac
  [ -n "$WT_HEAD_RAW_CURRENT" ] || fatal 'recorded worktree has no HEAD'
  WORKTREE_HEAD=$WT_HEAD_RAW_CURRENT
  case "$WORKTREE_BRANCH" in
    projex/*) ;;
    *) fatal 'recorded worktree branch is not ephemeral' ;;
  esac
  EPHEMERAL_BRANCH=$WORKTREE_BRANCH
  EPHEMERAL_SHA=$(git -C "$REPO_ROOT" rev-parse --verify --quiet "refs/heads/$EPHEMERAL_BRANCH") || fatal 'ephemeral worktree branch is missing'
  [ "$EPHEMERAL_SHA" = "$WORKTREE_HEAD" ] || fatal 'recorded worktree HEAD does not match ephemeral branch'
  [ "$ROOT_CURRENT_BRANCH" = "$BASE_BRANCH" ] || fatal 'originating checkout is not on recorded Base Branch'
  ORIGIN_REGISTERED_HEAD=$(git -C "$WORKTREE_PATH" rev-parse --verify HEAD 2>/dev/null) || fatal 'cannot read recorded worktree HEAD'
  [ "$ORIGIN_REGISTERED_HEAD" = "$WORKTREE_HEAD" ] || fatal 'recorded worktree checkout HEAD drifted'
else
  case "$ROOT_CURRENT_BRANCH" in
    projex/*) EPHEMERAL_BRANCH=$ROOT_CURRENT_BRANCH ;;
    *) fatal 'checkout-mode execution must be on a projex/* branch' ;;
  esac
  EPHEMERAL_SHA=$(git -C "$REPO_ROOT" rev-parse --verify --quiet "refs/heads/$EPHEMERAL_BRANCH") || fatal 'ephemeral branch is missing'
  [ "$ORIGIN_HEAD" = "$EPHEMERAL_SHA" ] || fatal 'ephemeral checkout HEAD does not match branch'
fi

PLAN_REL=$(relative_to "$PLAN_PATH" "$REPO_ROOT") || fatal 'plan is outside recorded Repo Root'
LOG_REL=$(relative_to "$LOG_PATH" "$REPO_ROOT") || fatal 'execution log is outside recorded Repo Root'

GENERATED_AT=$(date -u '+%Y-%m-%dT%H:%M:%SZ') || fatal 'cannot generate UTC timestamp'
emit_line 'SCHEMA_VERSION=1'
emit_line "GENERATED_AT_UTC=$(percent_encode "$GENERATED_AT")"
emit_line "REPO_ROOT=$(percent_encode "$REPO_ROOT")"
emit_line "BASE_BRANCH=$(percent_encode "$BASE_BRANCH")"
emit_line "EPHEMERAL_BRANCH=$(percent_encode "$EPHEMERAL_BRANCH")"
emit_line "PLAN_REL=$(percent_encode "$PLAN_REL")"
emit_line "LOG_REL=$(percent_encode "$LOG_REL")"
emit_line "BASE_SHA=$(percent_encode "$BASE_SHA")"
emit_line "EPHEMERAL_SHA=$(percent_encode "$EPHEMERAL_SHA")"
emit_line "ORIGIN_HEAD=$(percent_encode "$ORIGIN_HEAD")"
if [ "$WORKTREE_MODE" -eq 1 ]; then
  emit_line "WORKTREE_PATH=$(percent_encode "$WORKTREE_PATH")"
  emit_line "WORKTREE_BRANCH=$(percent_encode "$WORKTREE_BRANCH")"
  emit_line "WORKTREE_HEAD=$(percent_encode "$WORKTREE_HEAD")"
fi

# Gather all Git reads before emitting section records. Every command is in the
# documented read allowlist and receives a distinct quoted argument list.
COMMITS_DATA="$TMP_DIR/commits"
DIFF_DATA="$TMP_DIR/diff"
STASH_DATA="$TMP_DIR/stashes"
BASE_TREE="$TMP_DIR/base-tree"
EPHEMERAL_TREE="$TMP_DIR/ephemeral-tree"
git -C "$REPO_ROOT" log --oneline "$BASE_SHA..$EPHEMERAL_SHA" > "$COMMITS_DATA" 2>/dev/null || fatal 'cannot read ephemeral commit list'
git -C "$REPO_ROOT" diff --stat "$BASE_SHA" "$EPHEMERAL_SHA" > "$DIFF_DATA" 2>/dev/null || fatal 'cannot read ephemeral diff stat'
git -C "$REPO_ROOT" stash list > "$STASH_DATA" 2>/dev/null || fatal 'cannot read stash list'
git -C "$REPO_ROOT" ls-tree -r --name-only "$BASE_SHA" > "$BASE_TREE" 2>/dev/null || fatal 'cannot read base tree'
git -C "$REPO_ROOT" ls-tree -r --name-only "$EPHEMERAL_SHA" > "$EPHEMERAL_TREE" 2>/dev/null || fatal 'cannot read ephemeral tree'

emit_section() { emit_line "SECTION=$1"; }

emit_section COMMITS
if [ -s "$COMMITS_DATA" ]; then
  while IFS= read -r commit_line || [ -n "$commit_line" ]; do
    commit_sha=${commit_line%% *}
    commit_subject=${commit_line#* }
    [ "$commit_sha" != "$commit_line" ] || commit_subject=''
    emit_line "RECORD=COMMIT$(printf '\t')$(percent_encode "$commit_sha")$(printf '\t')$(percent_encode "$commit_subject")"
  done < "$COMMITS_DATA"
else
  emit_line "RECORD=NONE$(printf '\t')COMMITS"
fi

emit_section DIFF_STAT
if [ -s "$DIFF_DATA" ]; then
  while IFS= read -r diff_line || [ -n "$diff_line" ]; do
    emit_line "RECORD=DIFF_STAT$(printf '\t')$(percent_encode "$diff_line")"
  done < "$DIFF_DATA"
else
  emit_line "RECORD=NONE$(printf '\t')DIFF_STAT"
fi

# Inventory candidates are physical files in eligible .projex roots, plus the
# plan/log themselves. Physical paths are canonicalized before containment and
# are emitted relative to the originating repository root.
declare -A INVENTORY_LOCATION=()
collect_inventory() {
  local scan_root=$1 location=$2 file canonical rel
  while IFS= read -r -d '' file; do
    canonical=$(readlink -f -- "$file") || fatal 'inventory path cannot be canonicalized'
    if [ "$location" = ORIGIN ]; then
      is_under "$canonical" "$REPO_ROOT" || fatal 'origin inventory symlink escapes Repo Root'
    else
      is_under "$canonical" "$WORKTREE_PATH" || fatal 'child inventory symlink escapes Worktree Path'
    fi
    if grep -F -q -- "$PLAN_BASE" "$canonical" || [ "$canonical" = "$PLAN_PATH" ] || [ "$canonical" = "$LOG_PATH" ]; then
      if [ "$location" = CHILD ]; then
        rel=$(relative_to "$canonical" "$WORKTREE_PATH") || fatal 'child inventory path is outside Worktree Path'
      else
        rel=$(relative_to "$canonical" "$REPO_ROOT") || fatal 'inventory path is outside Repo Root'
      fi
      # A path present in both roots is one logical record. CHILD wins because
      # its contents and tracking state are the ephemeral execution view.
      INVENTORY_LOCATION["$rel"]=$location
    fi
  done < <(find -P "$scan_root" \( -type d \( -name .git -o -name .projexwt \) -prune \) -o \( -type f -path '*/.projex/*.md' -print0 \))
}
collect_inventory "$REPO_ROOT" ORIGIN
if [ "$WORKTREE_MODE" -eq 1 ]; then
  collect_inventory "$WORKTREE_PATH" CHILD
fi

emit_section PROJEX_INVENTORY
INVENTORY_DATA="$TMP_DIR/inventory"
: > "$INVENTORY_DATA"
for rel in "${!INVENTORY_LOCATION[@]}"; do printf '%s\n' "$rel"; done | LC_ALL=C sort > "$INVENTORY_DATA"
if [ -s "$INVENTORY_DATA" ]; then
  while IFS= read -r rel || [ -n "$rel" ]; do
    location=${INVENTORY_LOCATION["$rel"]}
    if grep -F -q -x -- "$rel" "$EPHEMERAL_TREE"; then
      classification=tracked-on-ephemeral
      if grep -F -q -x -- "$rel" "$BASE_TREE"; then also_on_base=yes; else also_on_base=no; fi
    elif grep -F -q -x -- "$rel" "$BASE_TREE"; then
      classification=tracked-on-base
      also_on_base=yes
    else
      classification=untracked
      also_on_base=no
    fi
    if [ "$location" = CHILD ]; then physical="$WORKTREE_PATH/$rel"; else physical="$REPO_ROOT/$rel"; fi
    status_value=MISSING
    if [ -f "$physical" ]; then
      while IFS= read -r status_line || [ -n "$status_line" ]; do
        case "$status_line" in
          '> **Status:** '*) status_value=${status_line#'> **Status:** '}; break ;;
        esac
      done < "$physical"
    fi
    emit_line "RECORD=PROJEX$(printf '\t')$(percent_encode "$rel")$(printf '\t')$location$(printf '\t')$classification$(printf '\t')$(percent_encode "$status_value")$(printf '\t')$also_on_base"
  done < "$INVENTORY_DATA"
else
  emit_line "RECORD=NONE$(printf '\t')PROJEX_INVENTORY"
fi

emit_section STASHES
if [ -s "$STASH_DATA" ]; then
  while IFS= read -r stash_line || [ -n "$stash_line" ]; do
    emit_line "RECORD=STASH$(printf '\t')$(percent_encode "$stash_line")"
  done < "$STASH_DATA"
  WARNINGS=1
else
  emit_line "RECORD=NONE$(printf '\t')STASHES"
fi

WARNINGS=${WARNINGS:-0}
emit_section GATES
ORIGIN_GATE_DATA="$TMP_DIR/origin-gate"
git -C "$REPO_ROOT" status --porcelain --untracked-files=no --ignore-submodules=dirty > "$ORIGIN_GATE_DATA" 2>/dev/null || fatal 'cannot read originating checkout status'
if [ -s "$ORIGIN_GATE_DATA" ]; then
  emit_line "RECORD=GATE$(printf '\t')ORIGIN_BASE$(printf '\t')WARN$(printf '\t')$(percent_encode "$(tr '\n' ' ' < "$ORIGIN_GATE_DATA")")"
  WARNINGS=1
else
  emit_line "RECORD=GATE$(printf '\t')ORIGIN_BASE$(printf '\t')PASS$(printf '\t')$(percent_encode 'tracked checkout clean')"
fi
if [ "$WORKTREE_MODE" -eq 1 ]; then
  CHILD_GATE_DATA="$TMP_DIR/child-gate"
  git -C "$WORKTREE_PATH" status --porcelain --ignored=matching > "$CHILD_GATE_DATA" 2>/dev/null || fatal 'cannot read child worktree status'
  if [ -s "$CHILD_GATE_DATA" ]; then
    emit_line "RECORD=GATE$(printf '\t')CHILD_WORKTREE$(printf '\t')WARN$(printf '\t')$(percent_encode "$(tr '\n' ' ' < "$CHILD_GATE_DATA")")"
    WARNINGS=1
  else
    emit_line "RECORD=GATE$(printf '\t')CHILD_WORKTREE$(printf '\t')PASS$(printf '\t')$(percent_encode 'worktree fully clean')"
  fi
else
  emit_line "RECORD=GATE$(printf '\t')CHILD_WORKTREE$(printf '\t')N/A$(printf '\t')$(percent_encode 'no recorded child worktree')"
fi

# Snapshot recheck: no terminal PASS is emitted for a moved ref or registration.
BASE_SHA_END=$(git -C "$REPO_ROOT" rev-parse --verify --quiet "refs/heads/$BASE_BRANCH") || fatal 'Base Branch disappeared during report'
EPHEMERAL_SHA_END=$(git -C "$REPO_ROOT" rev-parse --verify --quiet "refs/heads/$EPHEMERAL_BRANCH") || fatal 'ephemeral branch disappeared during report'
ORIGIN_HEAD_END=$(git -C "$REPO_ROOT" rev-parse --verify HEAD 2>/dev/null) || fatal 'originating HEAD disappeared during report'
if [ "$BASE_SHA_END" != "$BASE_SHA" ] || [ "$EPHEMERAL_SHA_END" != "$EPHEMERAL_SHA" ] || [ "$ORIGIN_HEAD_END" != "$ORIGIN_HEAD" ]; then
  emit_line "WARNING=$(percent_encode 'snapshot identity changed during report')"
  emit_line 'RESULT=STALE'
  cat "$OUT_FILE"
  exit 1
fi
if [ "$WORKTREE_MODE" -eq 1 ]; then
  WT_DATA_END="$TMP_DIR/worktrees-end"
  git -C "$REPO_ROOT" worktree list --porcelain > "$WT_DATA_END" 2>/dev/null || fatal 'worktree registrations disappeared during report'
  if ! cmp -s "$WT_DATA" "$WT_DATA_END"; then
    emit_line "WARNING=$(percent_encode 'worktree registration changed during report')"
    emit_line 'RESULT=STALE'
    cat "$OUT_FILE"
    exit 1
  fi
  if ! awk -v target="$WORKTREE_PATH" -v branch="refs/heads/$EPHEMERAL_BRANCH" -v head="$EPHEMERAL_SHA" '
    function check() { return (p == target && b == branch && h == head) }
    /^worktree / { if (seen && check()) found=1; p=substr($0,10); h=""; b=""; seen=1; next }
    /^HEAD / { h=substr($0,6); next }
    /^branch / { b=substr($0,8); next }
    END { if (seen && check()) found=1; exit(found ? 0 : 1) }
  ' "$WT_DATA_END"; then
    emit_line "WARNING=$(percent_encode 'worktree registration changed during report')"
    emit_line 'RESULT=STALE'
    cat "$OUT_FILE"
    exit 1
  fi
fi

if [ "$WARNINGS" -eq 1 ]; then
  emit_line 'RESULT=PASS_WITH_WARNINGS'
else
  emit_line 'RESULT=PASS'
fi
cat "$OUT_FILE"
exit 0
