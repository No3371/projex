#!/usr/bin/env bash
# execute-precheck.sh — Pre-execution validation for a plan
# Usage: execute-precheck.sh <plan-file>
#
# Validates mechanical checklist items before execution:
#   - Plan file exists and is committed to current branch
#   - Plan status is "Ready"
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
ERRORS=()

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
  echo "FAIL  Plan is not committed to branch '$BRANCH'"
  ERRORS+=("Plan must be committed to base branch before execution")
fi

# --- Check: Plan status is Ready ---

STATUS_LINE=$(grep -m1 -E '^\s*>?\s*\*{0,2}Status\*{0,2}:' "$PLAN_FILE" 2>/dev/null || true)
if [ -n "$STATUS_LINE" ]; then
  # Strip markdown formatting: > **Status:** value  →  value
  STATUS=$(echo "$STATUS_LINE" | sed 's/.*[Ss]tatus\*\*:[[:space:]]*//' | sed 's/`//g' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
  if echo "$STATUS" | grep -qi '^ready'; then
    echo "PASS  Plan status is '$STATUS'"
  else
    echo "FAIL  Plan status is '$STATUS' — expected 'Ready'"
    ERRORS+=("Plan status must be 'Ready' to execute")
  fi
else
  echo "FAIL  No Status field found in plan"
  ERRORS+=("Plan must contain a Status field")
fi

# --- Check: Clean working state ---

DIRTY=$(git -C "$REPO_ROOT" status --porcelain 2>/dev/null)
if [ -z "$DIRTY" ]; then
  echo "PASS  Working tree is clean"
else
  DIRTY_COUNT=$(printf '%s\n' "$DIRTY" | wc -l | tr -d '[:space:]')
  echo "WARN  Working tree has $DIRTY_COUNT uncommitted change(s)"
fi

# --- Result ---

echo ""
if [ ${#ERRORS[@]} -eq 0 ]; then
  echo "PRE-CHECK PASSED"
  exit 0
else
  echo "PRE-CHECK FAILED (${#ERRORS[@]} issue(s)):"
  for e in "${ERRORS[@]}"; do
    echo "  - $e"
  done
  exit 1
fi
