#!/usr/bin/env bash
# projex-squash-close.sh — Squash-merge ephemeral branch into base, then delete ephemeral
# Usage: projex-squash-close.sh <repo-root> <base-branch> <ephemeral-branch> "commit message" [--worktree]
#
# --worktree: merge from base, then best-effort remove the worktree at <repo>/.projexwt/<branch-suffix>.
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

if [ ${#POSITIONAL[@]} -ne 4 ]; then
  echo "Usage: projex-squash-close.sh <repo-root> <base-branch> <ephemeral-branch> \"commit message\" [--worktree]" >&2
  exit 1
fi

REPO_ROOT="${POSITIONAL[0]}"
BASE="${POSITIONAL[1]}"
EPHEMERAL="${POSITIONAL[2]}"
COMMIT_MSG="${POSITIONAL[3]}"

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
  # Worktree mode: merge first; cleanup happens after commit so locks cannot block close.
  WT_PATH="${REPO_ROOT%/}/.projexwt/${EPHEMERAL##*/}"
else
  # Checkout mode: require clean tree, switch to base
  if ! git -C "$REPO_ROOT" diff --quiet 2>/dev/null || ! git -C "$REPO_ROOT" diff --cached --quiet 2>/dev/null; then
    echo "Error: working tree has uncommitted changes — commit or stash before closing" >&2
    exit 1
  fi

  if ! git -C "$REPO_ROOT" checkout "$BASE" 2>&1; then
    echo "Error: could not checkout '$BASE' — still on ephemeral branch, no state changed" >&2
    exit 1
  fi
fi

# Pre-flight cleanliness gate (worktree mode) — refuse to finalize over a non-clean worktree
if [ "$WORKTREE_MODE" = true ]; then
  DIRTY=$(git -C "$WT_PATH" status --porcelain 2>/dev/null || true)
  if [ -n "$DIRTY" ]; then
    echo "Error: worktree '$WT_PATH' is not clean — commit tracked edits, and commit or remove untracked tooling, then re-run:" >&2
    echo "$DIRTY" | head -n 10 >&2
    exit 1
  fi
  IGNORED=$(git -C "$WT_PATH" status --porcelain --ignored=matching 2>/dev/null | grep '^!!' || true)
  if [ -n "$IGNORED" ]; then
    echo "Warning: worktree contains ignored content (deps/build output) — removal may leave a directory to clean manually:" >&2
    echo "$IGNORED" | head -n 5 >&2
  fi
fi

# Squash merge
if ! git -C "$REPO_ROOT" merge --squash "$EPHEMERAL" 2>&1; then
  git -C "$REPO_ROOT" reset --hard HEAD 2>/dev/null || true
  if [ "$WORKTREE_MODE" = true ]; then
    echo "Error: merge --squash failed — reset to clean state on '$BASE'. Branch '$EPHEMERAL' still exists; re-create worktree with: git worktree add $WT_PATH $EPHEMERAL" >&2
  elif git -C "$REPO_ROOT" checkout "$EPHEMERAL" 2>/dev/null; then
    echo "Error: merge --squash failed — rolled back to '$EPHEMERAL'" >&2
  else
    echo "Error: merge --squash failed — reset to clean state on '$BASE'" >&2
  fi
  exit 1
fi

# Commit squash
if ! git -C "$REPO_ROOT" commit -m "$COMMIT_MSG" 2>&1; then
  git -C "$REPO_ROOT" reset HEAD 2>/dev/null || true
  if [ "$WORKTREE_MODE" = true ]; then
    echo "Error: commit failed — squashed changes unstaged but preserved in working tree on '$BASE'. Retry: git commit -m '...'. Branch '$EPHEMERAL' still exists; re-create worktree with: git worktree add $WT_PATH $EPHEMERAL" >&2
  else
    echo "Error: commit failed — squashed changes unstaged but preserved in working tree on '$BASE'. Retry: git commit -m '...'. Or rollback: git checkout -- ." >&2
  fi
  exit 1
fi

if [ "$WORKTREE_MODE" = true ]; then
  if ! git -C "$REPO_ROOT" worktree remove "$WT_PATH" 2>&1; then
    WT_SUFFIX="${EPHEMERAL##*/}"
    if git -C "$REPO_ROOT" worktree list --porcelain | grep -q "/\.projexwt/${WT_SUFFIX}\$"; then
      echo "Warning: could not remove worktree '$WT_PATH' — close succeeded. Blocking content:" >&2
      { git -C "$WT_PATH" status --porcelain --ignored=matching 2>/dev/null || true; } | head -n 10 >&2
      echo "Remove the files above (or release any lock/open handle on the worktree — an empty list above means the block is a lock, not dirty content), then: git -C $REPO_ROOT worktree remove $WT_PATH" >&2
    else
      echo "Warning: worktree unregistered but directory remains at '$WT_PATH' — close succeeded; inspect and delete the plain directory manually, then run: git -C $REPO_ROOT worktree prune" >&2
    fi
  fi
fi

git -C "$REPO_ROOT" worktree prune 2>/dev/null || true

# Delete ephemeral branch (non-fatal)
if ! git -C "$REPO_ROOT" branch -D "$EPHEMERAL" 2>&1; then
  echo "Warning: could not delete '$EPHEMERAL' — changes are merged, delete manually: git branch -D $EPHEMERAL"
else
  echo "Squash-merged '$EPHEMERAL' -> '$BASE'. Branch deleted."
fi
