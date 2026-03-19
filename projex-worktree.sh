#!/usr/bin/env bash
# projex-worktree.sh — Create a worktree in <repo>.projexwt/ (sibling to repo)
# Usage: projex-worktree.sh <repo-root> <branch-name> [<base-ref>]
#
# Creates <repo>.projexwt/<branch-suffix>/ where <branch-suffix> is the last path segment
# of <branch-name> (e.g., .projex/2603071430-foo → 2603071430-foo).
# The worktree directory sits next to the repo, not inside it.

set -euo pipefail

if [ $# -lt 2 ] || [ $# -gt 3 ]; then
  echo "Usage: projex-worktree.sh <repo-root> <branch-name> [<base-ref>]" >&2
  exit 1
fi

REPO_ROOT="$1"
BRANCH_NAME="$2"
BASE_REF="${3:-HEAD}"

# Validate repo
if ! git -C "$REPO_ROOT" rev-parse --git-dir > /dev/null 2>&1; then
  echo "Error: '$REPO_ROOT' is not a git repository" >&2
  exit 1
fi

# Derive worktree suffix from branch name (last path segment)
WT_SUFFIX="${BRANCH_NAME##*/}"
WT_BASE="${REPO_ROOT%/}.projexwt"
WT_PATH="$WT_BASE/$WT_SUFFIX"

# Check worktree doesn't already exist
if [ -d "$WT_PATH" ]; then
  echo "Error: worktree already exists at '$WT_PATH'" >&2
  exit 1
fi

# Create sibling worktree directory if needed
mkdir -p "$WT_BASE"

# Create worktree
if ! git -C "$REPO_ROOT" worktree add "$WT_PATH" -b "$BRANCH_NAME" "$BASE_REF" 2>&1; then
  echo "Error: could not create worktree at '$WT_PATH'" >&2
  exit 1
fi

echo "Worktree created: $WT_PATH (branch: $BRANCH_NAME, base: $BASE_REF)"
