#!/usr/bin/env bash
# projex-commit.sh — Stage explicit files and commit atomically
# Usage: projex-commit.sh <repo-root> "commit message" ["--flag [value]" ...] file1 [file2 ...]
#
# Any trailing argument starting with '--' is treated as an extra git commit flag.
# A flag+value pair can be passed as a single quoted string: "--trailer Co-authored-by: Claude".
# File paths (which never start with '--') are staged and committed.

set -euo pipefail

if [ $# -lt 3 ]; then
  echo "Usage: projex-commit.sh <repo-root> \"commit message\" [\"--flag [value]\" ...] file1 [file2 ...]" >&2
  exit 1
fi

REPO_ROOT="$1"
COMMIT_MSG="$2"
shift 2

# Separate extra commit flags (start with '--') from file paths
EXTRA_FLAGS=()
FILES=()

for arg in "$@"; do
  if [[ "$arg" == --* ]]; then
    if [[ "$arg" == *" "* ]]; then
      # Flag+value pair in one string — split at first space
      EXTRA_FLAGS+=("${arg%% *}" "${arg#* }")
    else
      EXTRA_FLAGS+=("$arg")
    fi
  else
    FILES+=("$arg")
  fi
done

if [ ${#FILES[@]} -eq 0 ]; then
  echo "Error: no files specified" >&2
  exit 1
fi

# Validate repo
if ! git -C "$REPO_ROOT" rev-parse --git-dir > /dev/null 2>&1; then
  echo "Error: '$REPO_ROOT' is not a git repository" >&2
  exit 1
fi

# Validate all file paths are known to git (tracked or untracked) and have changes
BAD=()
for f in "${FILES[@]}"; do
  if [ -z "$(git -C "$REPO_ROOT" status --porcelain -- "$f")" ]; then
    BAD+=("$f")
  fi
done
if [ ${#BAD[@]} -gt 0 ]; then
  echo "Error: files not found or unchanged: ${BAD[*]}" >&2
  exit 1
fi

# Snapshot index for rollback
INDEX_TREE=$(git -C "$REPO_ROOT" write-tree)

# Stage files
if ! git -C "$REPO_ROOT" add "${FILES[@]}"; then
  git -C "$REPO_ROOT" read-tree "$INDEX_TREE" 2>/dev/null || true
  echo "Error: git add failed — index rolled back" >&2
  exit 1
fi

# Commit — rollback index on failure
if ! COMMIT_OUT=$(git -C "$REPO_ROOT" commit "${EXTRA_FLAGS[@]}" -m "$COMMIT_MSG" 2>&1); then
  git -C "$REPO_ROOT" read-tree "$INDEX_TREE" 2>/dev/null || true
  echo "Error: git commit failed — index rolled back" >&2
  echo "$COMMIT_OUT" >&2
  exit 1
fi

HASH=$(git -C "$REPO_ROOT" rev-parse --short HEAD)
echo "Committed: $COMMIT_MSG ($HASH)"
