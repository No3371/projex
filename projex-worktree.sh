#!/usr/bin/env bash
# projex-worktree.sh — Create a worktree in .projexwt/ with gitignore enforcement
# Usage: projex-worktree.sh <repo-root> <branch-name> [<base-ref>]
#
# Creates .projexwt/<branch-suffix>/ where <branch-suffix> is the last path segment
# of <branch-name> (e.g., projex/20260307-foo → 20260307-foo).
#
# Gitignore gate: if .projexwt/ is not in .gitignore, the script adds it and commits
# before creating the worktree. This is a hard prerequisite — never bypassed.

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
WT_PATH="$REPO_ROOT/.projexwt/$WT_SUFFIX"

# --- Gitignore gate ---
if ! git -C "$REPO_ROOT" check-ignore -q .projexwt 2>/dev/null; then
  GITIGNORE="$REPO_ROOT/.gitignore"
  if [ -f "$GITIGNORE" ]; then
    echo ".projexwt/" >> "$GITIGNORE"
  else
    echo ".projexwt/" > "$GITIGNORE"
  fi
  if ! git -C "$REPO_ROOT" add .gitignore; then
    echo "Error: could not stage .gitignore" >&2
    exit 1
  fi
  if ! git -C "$REPO_ROOT" commit -m "projex: gitignore .projexwt/" 2>&1; then
    git -C "$REPO_ROOT" restore --staged .gitignore 2>/dev/null || true
    echo "Error: could not commit .gitignore update" >&2
    exit 1
  fi
  echo "Added .projexwt/ to .gitignore and committed."
fi

# Check worktree doesn't already exist
if [ -d "$WT_PATH" ]; then
  echo "Error: worktree already exists at '$WT_PATH'" >&2
  exit 1
fi

# Create .projexwt/ directory if needed
mkdir -p "$REPO_ROOT/.projexwt"

# Create worktree
if ! git -C "$REPO_ROOT" worktree add "$WT_PATH" -b "$BRANCH_NAME" "$BASE_REF" 2>&1; then
  echo "Error: could not create worktree at '$WT_PATH'" >&2
  exit 1
fi

echo "Worktree created: $WT_PATH (branch: $BRANCH_NAME, base: $BASE_REF)"
