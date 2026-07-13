#!/usr/bin/env bash
# projex-rebase-close.sh — Rebase ephemeral onto base for linear history, fast-forward base, delete ephemeral
# Usage: projex-rebase-close.sh <repo-root> <base-branch> <ephemeral-branch> [--worktree]
#
# Replays the ephemeral branch's commits onto the tip of base (rewriting their SHAs),
# then fast-forwards base to include them. No merge commit is created.
#
# --worktree: the ephemeral branch is checked out in a worktree at <repo>/.projexwt/<branch-suffix>.
#             The rebase runs inside that worktree; the main working directory must be on base.
#             The worktree is removed after the fast-forward succeeds.

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
  echo "Usage: projex-rebase-close.sh <repo-root> <base-branch> <ephemeral-branch> [--worktree]" >&2
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
  # Worktree mode: rebase inside the worktree (ephemeral is checked out there), then ff base.
  WT_PATH="${REPO_ROOT%/}/.projexwt/${EPHEMERAL##*/}"
  if [ ! -d "$WT_PATH" ]; then
    echo "Error: worktree '$WT_PATH' does not exist — is worktree mode correct?" >&2
    exit 1
  fi
  # Worktree must be clean before rewriting its history
  if ! git -C "$WT_PATH" diff --quiet 2>/dev/null || ! git -C "$WT_PATH" diff --cached --quiet 2>/dev/null; then
    echo "Error: worktree '$WT_PATH' has uncommitted changes — commit or stash before closing" >&2
    exit 1
  fi
  if ! git -C "$WT_PATH" rebase "$BASE" 2>&1; then
    git -C "$WT_PATH" rebase --abort 2>/dev/null || true
    echo "Error: rebase conflict — aborted, worktree '$WT_PATH' left on '$EPHEMERAL'. Resolve manually or use Option A/B." >&2
    exit 1
  fi
else
  # Checkout mode: require clean tree, remember starting branch, rebase ephemeral onto base.
  if ! git -C "$REPO_ROOT" diff --quiet 2>/dev/null || ! git -C "$REPO_ROOT" diff --cached --quiet 2>/dev/null; then
    echo "Error: working tree has uncommitted changes — commit or stash before closing" >&2
    exit 1
  fi

  ORIG_BRANCH="$(git -C "$REPO_ROOT" rev-parse --abbrev-ref HEAD)"

  if ! git -C "$REPO_ROOT" checkout "$EPHEMERAL" 2>&1; then
    echo "Error: could not checkout '$EPHEMERAL' — no state changed" >&2
    exit 1
  fi

  # Rebase ephemeral onto base (rewrites ephemeral's commits)
  if ! git -C "$REPO_ROOT" rebase "$BASE" 2>&1; then
    git -C "$REPO_ROOT" rebase --abort 2>/dev/null || true
    git -C "$REPO_ROOT" checkout "$ORIG_BRANCH" 2>/dev/null || true
    echo "Error: rebase conflict — aborted, restored to '$ORIG_BRANCH'. Resolve manually or use Option A/B." >&2
    exit 1
  fi
fi

# Fast-forward base to the rebased ephemeral tip (no merge commit).
# In checkout mode we must switch to base first; in worktree mode base is already checked out in the main dir.
if [ "$WORKTREE_MODE" = false ]; then
  if ! git -C "$REPO_ROOT" checkout "$BASE" 2>&1; then
    echo "Error: rebased '$EPHEMERAL' but could not checkout '$BASE' to fast-forward — finish manually: git checkout $BASE && git merge --ff-only $EPHEMERAL" >&2
    exit 1
  fi
fi

if ! git -C "$REPO_ROOT" merge --ff-only "$EPHEMERAL" 2>&1; then
  echo "Error: fast-forward of '$BASE' failed unexpectedly after rebase — '$EPHEMERAL' is rebased; finish manually: git merge --ff-only $EPHEMERAL" >&2
  exit 1
fi

if [ "$WORKTREE_MODE" = true ]; then
  if ! git -C "$REPO_ROOT" worktree remove "$WT_PATH" 2>&1; then
    echo "Warning: normal worktree remove failed, retrying with --force..." >&2
    if ! git -C "$REPO_ROOT" worktree remove --force "$WT_PATH" 2>&1; then
      echo "Warning: could not remove worktree '$WT_PATH' — close succeeded; clean up manually, then run: git worktree prune" >&2
    fi
  fi
fi

git -C "$REPO_ROOT" worktree prune 2>/dev/null || true

# Delete ephemeral branch (non-fatal)
if ! git -C "$REPO_ROOT" branch -d "$EPHEMERAL" 2>&1; then
  echo "Warning: could not delete '$EPHEMERAL' — changes are on '$BASE', delete manually: git branch -d $EPHEMERAL"
else
  echo "Rebased '$EPHEMERAL' -> '$BASE' (linear, fast-forward). Branch deleted."
fi
