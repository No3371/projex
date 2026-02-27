#!/usr/bin/env bash
# projex-abandon.sh — Checkout base and force-delete ephemeral branch without merging
# Usage: projex-abandon.sh <repo-root> <base-branch> <ephemeral-branch>

set -euo pipefail

if [ $# -ne 3 ]; then
  echo "Usage: projex-abandon.sh <repo-root> <base-branch> <ephemeral-branch>" >&2
  exit 1
fi

REPO_ROOT="$1"
BASE="$2"
EPHEMERAL="$3"

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

# Checkout base
if ! git -C "$REPO_ROOT" checkout "$BASE" 2>&1; then
  echo "Error: could not checkout '$BASE' — still on '$EPHEMERAL', nothing lost" >&2
  exit 1
fi

# Force-delete ephemeral (non-fatal)
if ! git -C "$REPO_ROOT" branch -D "$EPHEMERAL" 2>&1; then
  echo "Warning: could not delete '$EPHEMERAL' — delete manually: git branch -D $EPHEMERAL"
else
  echo "Abandoned '$EPHEMERAL'. Back on '$BASE'."
fi
