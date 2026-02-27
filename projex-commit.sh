#!/usr/bin/env bash
# projex-commit.sh — Stage explicit files and commit atomically
# Usage: projex-commit.sh <repo-root> "commit message" file1 [file2 ...]

set -euo pipefail

if [ $# -lt 3 ]; then
  echo "Usage: projex-commit.sh <repo-root> \"commit message\" file1 [file2 ...]" >&2
  exit 1
fi

REPO_ROOT="$1"
COMMIT_MSG="$2"
shift 2
FILES=("$@")

# Validate repo
if ! git -C "$REPO_ROOT" rev-parse --git-dir > /dev/null 2>&1; then
  echo "Error: '$REPO_ROOT' is not a git repository" >&2
  exit 1
fi

# Stage files
if ! git -C "$REPO_ROOT" add "${FILES[@]}"; then
  git -C "$REPO_ROOT" restore --staged "${FILES[@]}" 2>/dev/null || true
  echo "Error: git add failed — partial staging rolled back" >&2
  exit 1
fi

# Commit — rollback staging on failure
if ! COMMIT_OUT=$(git -C "$REPO_ROOT" commit -m "$COMMIT_MSG" 2>&1); then
  git -C "$REPO_ROOT" restore --staged "${FILES[@]}" 2>/dev/null || true
  echo "Error: git commit failed — staging rolled back" >&2
  echo "$COMMIT_OUT" >&2
  exit 1
fi

HASH=$(git -C "$REPO_ROOT" rev-parse --short HEAD)
echo "Committed: $COMMIT_MSG ($HASH)"
