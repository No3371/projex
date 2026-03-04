#!/usr/bin/env bash
# projex-squash-close.sh — Squash-merge ephemeral branch into base, then delete ephemeral
# Usage: projex-squash-close.sh <repo-root> <base-branch> <ephemeral-branch> "commit message"

set -euo pipefail

if [ $# -ne 4 ]; then
  echo "Usage: projex-squash-close.sh <repo-root> <base-branch> <ephemeral-branch> \"commit message\"" >&2
  exit 1
fi

REPO_ROOT="$1"
BASE="$2"
EPHEMERAL="$3"
COMMIT_MSG="$4"

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

# Require clean working tree — reset --hard is used on squash failure and must not destroy other changes
if ! git -C "$REPO_ROOT" diff --quiet 2>/dev/null || ! git -C "$REPO_ROOT" diff --cached --quiet 2>/dev/null; then
  echo "Error: working tree has uncommitted changes — commit or stash before closing" >&2
  exit 1
fi

# Checkout base
if ! git -C "$REPO_ROOT" checkout "$BASE" 2>&1; then
  echo "Error: could not checkout '$BASE' — still on ephemeral branch, no state changed" >&2
  exit 1
fi

# Squash merge
if ! git -C "$REPO_ROOT" merge --squash "$EPHEMERAL" 2>&1; then
  git -C "$REPO_ROOT" reset --hard HEAD 2>/dev/null || true
  if git -C "$REPO_ROOT" checkout "$EPHEMERAL" 2>/dev/null; then
    echo "Error: merge --squash failed — rolled back to '$EPHEMERAL'" >&2
  else
    echo "Error: merge --squash failed — reset to clean state on '$BASE'" >&2
  fi
  exit 1
fi

# Commit squash
if ! git -C "$REPO_ROOT" commit -m "$COMMIT_MSG" 2>&1; then
  git -C "$REPO_ROOT" reset --hard HEAD 2>/dev/null || true
  if git -C "$REPO_ROOT" checkout "$EPHEMERAL" 2>/dev/null; then
    echo "Error: commit failed — reset to clean state, rolled back to '$EPHEMERAL'" >&2
  else
    echo "Error: commit failed — reset to clean state on '$BASE'" >&2
  fi
  exit 1
fi

# Delete ephemeral branch (non-fatal)
if ! git -C "$REPO_ROOT" branch -D "$EPHEMERAL" 2>&1; then
  echo "Warning: could not delete '$EPHEMERAL' — changes are merged, delete manually: git branch -D $EPHEMERAL"
else
  echo "Squash-merged '$EPHEMERAL' -> '$BASE'. Branch deleted."
fi
