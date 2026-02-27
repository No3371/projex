#!/usr/bin/env bash
# projex-merge-close.sh — Merge with full history into base, then delete ephemeral
# Usage: projex-merge-close.sh <repo-root> <base-branch> <ephemeral-branch> "merge message"

set -euo pipefail

if [ $# -ne 4 ]; then
  echo "Usage: projex-merge-close.sh <repo-root> <base-branch> <ephemeral-branch> \"merge message\"" >&2
  exit 1
fi

REPO_ROOT="$1"
BASE="$2"
EPHEMERAL="$3"
MERGE_MSG="$4"

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

# Require clean working tree — merge with dirty tree contaminates the merge commit
if ! git -C "$REPO_ROOT" diff --quiet 2>/dev/null || ! git -C "$REPO_ROOT" diff --cached --quiet 2>/dev/null; then
  echo "Error: working tree has uncommitted changes — commit or stash before closing" >&2
  exit 1
fi

# Checkout base
if ! git -C "$REPO_ROOT" checkout "$BASE" 2>&1; then
  echo "Error: could not checkout '$BASE' — still on ephemeral, no state changed" >&2
  exit 1
fi

# Merge with full history
if ! git -C "$REPO_ROOT" merge "$EPHEMERAL" --no-ff -m "$MERGE_MSG" 2>&1; then
  git -C "$REPO_ROOT" merge --abort 2>/dev/null || true
  git -C "$REPO_ROOT" checkout "$EPHEMERAL" 2>/dev/null || true
  echo "Error: merge failed — aborted, rolled back to '$EPHEMERAL'" >&2
  exit 1
fi

# Delete ephemeral branch (non-fatal)
if ! git -C "$REPO_ROOT" branch -d "$EPHEMERAL" 2>&1; then
  echo "Warning: could not delete '$EPHEMERAL' — changes are merged, delete manually: git branch -d $EPHEMERAL"
else
  echo "Merged '$EPHEMERAL' -> '$BASE' with history. Branch deleted."
fi
