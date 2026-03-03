#!/usr/bin/env bash
# move-n-stage.sh — Batch git mv with rollback on failure
# Usage: move-n-stage.sh <repo-root> src1 dst1 [src2 dst2 ...]
#
# Moves each source to its destination via git mv (stages automatically).
# Does NOT commit. On failure, rolls back all completed moves in reverse order.

set -euo pipefail

if [ $# -lt 3 ]; then
  echo "Usage: move-n-stage.sh <repo-root> src1 dst1 [src2 dst2 ...]" >&2
  exit 1
fi

REPO_ROOT="$1"
shift

# Validate repo
if ! git -C "$REPO_ROOT" rev-parse --git-dir > /dev/null 2>&1; then
  echo "Error: '$REPO_ROOT' is not a git repository" >&2
  exit 1
fi

# Collect pairs
PAIRS=("$@")
if [ $(( ${#PAIRS[@]} % 2 )) -ne 0 ]; then
  echo "Error: arguments must be src/dst pairs (got odd count: ${#PAIRS[@]})" >&2
  exit 1
fi

# Track completed moves for rollback (actual resolved paths)
DONE_SRC=()
DONE_DST=()

rollback() {
  if [ ${#DONE_SRC[@]} -eq 0 ]; then return; fi
  echo "Rolling back ${#DONE_SRC[@]} completed move(s)..." >&2
  local failed=0
  for (( i=${#DONE_SRC[@]}-1; i>=0; i-- )); do
    if ! RB_OUT=$(git -C "$REPO_ROOT" mv -- "${DONE_DST[$i]}" "${DONE_SRC[$i]}" 2>&1); then
      echo "  Warning: could not reverse '${DONE_DST[$i]}' -> '${DONE_SRC[$i]}'" >&2
      echo "  $RB_OUT" >&2
      failed=1
    fi
  done
  if [ "$failed" -eq 1 ]; then
    echo "Rollback incomplete — manual intervention required." >&2
  else
    echo "Rollback complete." >&2
  fi
}

# Execute moves
for (( i=0; i<${#PAIRS[@]}; i+=2 )); do
  SRC="${PAIRS[$i]}"
  DST="${PAIRS[$((i+1))]}"

  if ! MV_OUT=$(git -C "$REPO_ROOT" mv -- "$SRC" "$DST" 2>&1); then
    echo "Error: git mv '$SRC' '$DST' failed" >&2
    echo "$MV_OUT" >&2
    rollback
    exit 1
  fi

  # Resolve actual destination — git mv into a directory lands at dst/basename(src)
  if [ -d "$REPO_ROOT/$DST" ]; then
    DONE_DST+=("$DST/$(basename "$SRC")")
  else
    DONE_DST+=("$DST")
  fi
  DONE_SRC+=("$SRC")
done

echo "Moved ${#DONE_SRC[@]} file(s):"
for (( i=0; i<${#DONE_SRC[@]}; i++ )); do
  echo "  ${DONE_SRC[$i]} -> ${DONE_DST[$i]}"
done
