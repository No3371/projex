#!/usr/bin/env bash
# projex-worktree.sh — Create a worktree in <repo>/.projexwt/ (inside the repo)
# Usage: projex-worktree.sh <repo-root> <branch-name> [<base-ref>]
#
# Creates <repo>/.projexwt/<branch-suffix>/ where <branch-suffix> is the last path segment
# of <branch-name> (e.g., projex/2603071430-foo → 2603071430-foo).
# The worktree sits inside the repo so it stays in the editor workspace; .projexwt/ is
# registered in the repo's .git/info/exclude so the parent's git status stays clean.

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
WT_BASE="${REPO_ROOT%/}/.projexwt"
WT_PATH="$WT_BASE/$WT_SUFFIX"

# Check worktree doesn't already exist
if [ -d "$WT_PATH" ]; then
  echo "Error: worktree already exists at '$WT_PATH'" >&2
  exit 1
fi

# Keep the in-repo worktree dir out of the parent's git status (local, not committed)
EXCLUDE_FILE="$(git -C "$REPO_ROOT" rev-parse --path-format=absolute --git-common-dir)/info/exclude"
mkdir -p "$(dirname "$EXCLUDE_FILE")"
if ! grep -qxF '.projexwt/' "$EXCLUDE_FILE" 2>/dev/null; then
  echo '.projexwt/' >> "$EXCLUDE_FILE"
fi

# Create worktree base directory if needed
mkdir -p "$WT_BASE"

# Fail if branch already exists
if git -C "$REPO_ROOT" rev-parse --verify "refs/heads/$BRANCH_NAME" > /dev/null 2>&1; then
  echo "Error: branch '$BRANCH_NAME' already exists" >&2
  exit 1
fi

# Create worktree
wt_out=$(git -C "$REPO_ROOT" worktree add "$WT_PATH" -b "$BRANCH_NAME" "$BASE_REF" 2>&1) || {
  echo "Error: could not create worktree at '$WT_PATH'" >&2
  echo "$wt_out" >&2
  exit 1
}

echo "Worktree created: $WT_PATH (branch: $BRANCH_NAME, base: $BASE_REF)"
echo "# next: from now on, target $WT_PATH as the working repo root for all script/git calls (not $REPO_ROOT), until this worktree is closed (squash-merged or abandoned)."
echo "# cleanup: anything created here that git does not track (deps, build output, scratch) must be removed before close — untracked leftovers block worktree removal."
