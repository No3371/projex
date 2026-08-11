#!/usr/bin/env bash
# execute-precheck.sh — Pre-execution validation for a plan
# Usage: execute-precheck.sh <plan-file>
#
# Validates mechanical checklist items before execution:
#   - Plan file exists
#   - Plan is committed to current branch (warning if not)
#   - Working tree cleanliness (warning, not failure)
#
# Outputs key=value pairs for use by the caller:
#   REPO_ROOT, BRANCH, PLAN_REL

set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: execute-precheck.sh <plan-file>" >&2
  exit 1
fi

PLAN_FILE="$1"

# --- Resolve paths ---

if [ ! -f "$PLAN_FILE" ]; then
  echo "FAIL  Plan file not found: $PLAN_FILE" >&2
  exit 1
fi

PLAN_DIR="$(cd "$(dirname "$PLAN_FILE")" && pwd -P)"
PLAN_BASE="$(basename "$PLAN_FILE")"

REPO_ROOT=$(git -C "$PLAN_DIR" rev-parse --show-toplevel 2>/dev/null) || {
  echo "FAIL  Not inside a git repository: $PLAN_DIR" >&2
  exit 1
}
REPO_ROOT_P="$(cd "$REPO_ROOT" && pwd -P)"

BRANCH=$(git -C "$REPO_ROOT" branch --show-current 2>/dev/null) || BRANCH="(detached)"

# Compute plan path relative to repo root
PLAN_ABS="$PLAN_DIR/$PLAN_BASE"
PLAN_REL="${PLAN_ABS#"$REPO_ROOT_P"/}"

echo "REPO_ROOT=$REPO_ROOT"
echo "BRANCH=$BRANCH"
echo "PLAN_REL=$PLAN_REL"
echo ""

# --- Check: Plan is committed ---

COMMIT=$(git -C "$REPO_ROOT" log --oneline -1 -- "$PLAN_REL" 2>/dev/null || true)
if [ -n "$COMMIT" ]; then
  echo "PASS  Plan is committed ($COMMIT)"
else
  echo "WARN  Plan is not committed to branch '$BRANCH' — commit the plan before proceeding"
fi

# --- Check: Clean working state ---

DIRTY=$(git -C "$REPO_ROOT" status --porcelain 2>/dev/null)
if [ -z "$DIRTY" ]; then
  echo "PASS  Working tree is clean"
else
  DIRTY_COUNT=$(printf '%s\n' "$DIRTY" | wc -l | tr -d '[:space:]')
  echo "WARN  Working tree has $DIRTY_COUNT uncommitted change(s)"
fi

# --- Opportunistic Worktree Mode guardrail ---
grep -Fq -- "> **Worktree:** Yes" "$PLAN_ABS" && echo -e "\nExecuting in Worktree mode? Remember to bootstrap the branch/worktree (missing dev deps, etc.)"

# --- Result ---

echo ""
echo "PRE-CHECK PASSED"
exit 0
