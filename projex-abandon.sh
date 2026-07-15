#!/usr/bin/env bash
# projex-abandon.sh — Checkout base and force-delete ephemeral branch without merging
# Usage: projex-abandon.sh <repo-root> <base-branch> <ephemeral-branch> [--worktree]
#
# --worktree: remove the worktree at <repo>/.projexwt/<branch-suffix> instead of checking out base.
#             The main working directory must already be on the base branch.

set -euo pipefail

# Parse --worktree flag
WORKTREE_MODE=false
POSITIONAL=()
for arg in "$@"; do
  if [ "$arg" = "--worktree" ]; then
    WORKTREE_MODE=true
  else
    POSITIONAL+=("$arg")
  fi
done

if [ ${#POSITIONAL[@]} -ne 3 ]; then
  echo "Usage: projex-abandon.sh <repo-root> <base-branch> <ephemeral-branch> [--worktree]" >&2
  exit 1
fi

REPO_ROOT="${POSITIONAL[0]}"
BASE="${POSITIONAL[1]}"
EPHEMERAL="${POSITIONAL[2]}"

# Validate repo
if ! git -C "$REPO_ROOT" rev-parse --git-dir > /dev/null 2>&1; then
  echo "Error: '$REPO_ROOT' is not a git repository" >&2
  exit 1
fi

# Validate branches exist
if ! git -C "$REPO_ROOT" rev-parse --verify "$BASE" > /dev/null 2>&1; then
  echo "Error: base branch '$BASE' does not exist" >&2
  exit 1
fi

if ! git -C "$REPO_ROOT" rev-parse --verify "$EPHEMERAL" > /dev/null 2>&1; then
  echo "Error: ephemeral branch '$EPHEMERAL' does not exist" >&2
  exit 1
fi

if [ "$BASE" = "$EPHEMERAL" ]; then
  echo "Error: base and ephemeral branch cannot be the same ('$BASE')" >&2
  exit 1
fi

if [ "$WORKTREE_MODE" = true ]; then
  # Worktree mode: remove worktree (already on base branch)
  WT_PATH="${REPO_ROOT%/}/.projexwt/${EPHEMERAL##*/}"
  UNTRACKED=$(git -C "$WT_PATH" status --porcelain 2>/dev/null | grep '^??' || true)
  if [ -n "$UNTRACKED" ]; then
    echo "Note: discarding untracked files with the worktree:" >&2
    echo "$UNTRACKED" | head -n 10 >&2
  fi
  if ! git -C "$REPO_ROOT" worktree remove "$WT_PATH" --force 2>&1; then
    if git -C "$REPO_ROOT" worktree list --porcelain | grep -q "/\.projexwt/${EPHEMERAL##*/}\$"; then
      echo "Warning: could not remove worktree '$WT_PATH' — remove manually: git worktree remove $WT_PATH --force" >&2
    else
      echo "Warning: worktree unregistered but directory remains at '$WT_PATH' — inspect and delete the plain directory manually, then run: git worktree prune" >&2
    fi
  fi
else
  # Checkout mode: switch to base
  if ! git -C "$REPO_ROOT" checkout "$BASE" 2>&1; then
    echo "Error: could not checkout '$BASE' — still on '$EPHEMERAL', nothing lost" >&2
    exit 1
  fi
fi

# Force-delete ephemeral (non-fatal)
if ! git -C "$REPO_ROOT" branch -D "$EPHEMERAL" 2>&1; then
  echo "Warning: could not delete '$EPHEMERAL' — delete manually: git branch -D $EPHEMERAL"
else
  echo "Abandoned '$EPHEMERAL'. Back on '$BASE'."
fi
