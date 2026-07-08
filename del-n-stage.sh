#!/usr/bin/env bash
# del-n-stage.sh — Batch git rm with rollback on failure
# Usage: del-n-stage.sh <repo-root> file1 [file2 ...]
#
# Deletes each file and stages the deletion.
# Uses git rm for tracked files; plain rm + git add for untracked files.
# Does NOT commit. On failure, rolls back all completed deletions in reverse order.

set -euo pipefail

trap 'cleanup_backups 2>/dev/null' EXIT

if [ $# -lt 2 ]; then
  echo "Usage: del-n-stage.sh <repo-root> file1 [file2 ...]" >&2
  exit 1
fi

REPO_ROOT="$1"
shift

# Validate repo root
TOPLEVEL=$(git -C "$REPO_ROOT" rev-parse --show-toplevel 2>/dev/null) || {
  echo "Error: '$REPO_ROOT' is not a git repository" >&2
  exit 1
}
REPO_CANONICAL=$(cd "$REPO_ROOT" && pwd -P)
TOP_CANONICAL=$(cd "$TOPLEVEL" && pwd -P)
if [ "$REPO_CANONICAL" != "$TOP_CANONICAL" ]; then
  echo "Error: '$REPO_ROOT' is not a repo root — toplevel is '$TOPLEVEL'" >&2
  echo "  The <repo-root> argument must be the repository's top-level directory." >&2
  exit 1
fi

FILES=("$@")

# Validate all paths belong to this repo
for f in "${FILES[@]}"; do
  check_dir="$REPO_ROOT/$f"
  while [ ! -d "$check_dir" ]; do check_dir=$(dirname "$check_dir"); done
  FILE_TOP=$(cd "$check_dir" && git rev-parse --show-toplevel 2>/dev/null) || true
  if [ -z "$FILE_TOP" ]; then
    echo "Error: '$f' is not inside any git repository" >&2
    echo "  Expected repo root: $TOPLEVEL" >&2
    exit 1
  fi
  FILE_TOP_CANONICAL=$(cd "$FILE_TOP" && pwd -P)
  if [ "$FILE_TOP_CANONICAL" != "$TOP_CANONICAL" ]; then
    echo "Error: '$f' belongs to a different repo than '$REPO_ROOT'" >&2
    echo "  File's repo root: $FILE_TOP" >&2
    echo "  Expected repo root: $TOPLEVEL" >&2
    echo "  Verify the <repo-root> argument matches the repository containing these files." >&2
    exit 1
  fi
done

# Track completed deletions for rollback
DONE_FILES=()
DONE_TRACKED=()
DONE_BACKUPS=()

cleanup_backups() {
  for bk in "${DONE_BACKUPS[@]}"; do
    rm -f "$bk" 2>/dev/null || true
  done
}

rollback() {
  if [ ${#DONE_FILES[@]} -eq 0 ]; then return; fi
  echo "Rolling back ${#DONE_FILES[@]} completed deletion(s)..." >&2
  local failed=0
  for (( i=${#DONE_FILES[@]}-1; i>=0; i-- )); do
    local f="${DONE_FILES[$i]}"
    local bk="${DONE_BACKUPS[$i]}"
    local full="$REPO_ROOT/$f"

    # Restore the file from backup
    RESTORE_DIR=$(dirname "$full")
    mkdir -p "$RESTORE_DIR" 2>/dev/null || true
    if ! cp -- "$bk" "$full" 2>&1; then
      echo "  Warning: could not restore '$f' from backup" >&2
      failed=1
      continue
    fi

    if [ "${DONE_TRACKED[$i]}" -eq 1 ]; then
      # Unstage the deletion without touching the working tree (preserves backup content)
      if ! git -C "$REPO_ROOT" reset HEAD -- "$f" > /dev/null 2>&1; then
        # Fallback: just add it back
        git -C "$REPO_ROOT" add -- "$f" 2>/dev/null || true
      fi
    fi
    # Untracked: nothing to unstage, file is simply restored on disk
  done
  cleanup_backups
  if [ "$failed" -eq 1 ]; then
    echo "Rollback incomplete — manual intervention required." >&2
  else
    echo "Rollback complete." >&2
  fi
}

# Execute deletions
for f in "${FILES[@]}"; do
  FULL_PATH="$REPO_ROOT/$f"

  # Verify file exists
  if [ ! -f "$FULL_PATH" ]; then
    echo "Error: '$f' does not exist" >&2
    rollback
    exit 1
  fi

  # Back up before deleting
  BACKUP=$(mktemp)
  if ! CP_OUT=$(cp -- "$FULL_PATH" "$BACKUP" 2>&1); then
    echo "Error: could not back up '$f'" >&2
    echo "$CP_OUT" >&2
    rm -f "$BACKUP" 2>/dev/null || true
    rollback
    exit 1
  fi

  # Check if source is tracked by git
  TRACKED=0
  if git -C "$REPO_ROOT" ls-files --error-unmatch -- "$f" > /dev/null 2>&1; then
    TRACKED=1
  fi

  if [ "$TRACKED" -eq 1 ]; then
    if ! RM_OUT=$(git -C "$REPO_ROOT" rm -- "$f" 2>&1); then
      echo "Error: git rm '$f' failed" >&2
      echo "$RM_OUT" >&2
      rm -f "$BACKUP" 2>/dev/null || true
      rollback
      exit 1
    fi
  else
    if ! RM_OUT=$(rm -- "$FULL_PATH" 2>&1); then
      echo "Error: rm '$f' failed" >&2
      echo "$RM_OUT" >&2
      rm -f "$BACKUP" 2>/dev/null || true
      rollback
      exit 1
    fi
  fi

  DONE_FILES+=("$f")
  DONE_TRACKED+=("$TRACKED")
  DONE_BACKUPS+=("$BACKUP")
done

cleanup_backups

echo "Deleted ${#DONE_FILES[@]} file(s):"
for (( i=0; i<${#DONE_FILES[@]}; i++ )); do
  if [ "${DONE_TRACKED[$i]}" -eq 1 ]; then
    echo "  ${DONE_FILES[$i]}"
  else
    echo "  ${DONE_FILES[$i]}  (untracked, removed from disk only)"
  fi
done

script_dir="$(cd "$(dirname "$0")" && pwd)"
echo "# next: $script_dir/stage-n-commit.sh $REPO_ROOT \"<msg>\" ${DONE_FILES[*]}"
