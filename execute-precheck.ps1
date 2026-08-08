# execute-precheck.ps1 — Pre-execution validation for a plan
# Usage: execute-precheck.ps1 <plan-file>
#
# Validates mechanical checklist items before execution:
#   - Plan file exists
#   - Plan is committed to current branch (warning if not)
#   - Working tree cleanliness (warning, not failure)
#
# Outputs key=value pairs for use by the caller:
#   REPO_ROOT, BRANCH, PLAN_REL

param(
    [Parameter(Mandatory)][string]$PlanFile
)

# --- Resolve paths ---

if (-not (Test-Path $PlanFile -PathType Leaf)) {
    Write-Error "Plan file not found: $PlanFile"
    exit 1
}

$PlanAbs  = (Resolve-Path $PlanFile).Path
$PlanDir  = Split-Path $PlanAbs -Parent
$PlanBase = Split-Path $PlanAbs -Leaf

$RepoRoot = git -C $PlanDir rev-parse --show-toplevel 2>$null
if ($LASTEXITCODE -ne 0 -or -not $RepoRoot) {
    Write-Error "Not inside a git repository: $PlanDir"
    exit 1
}
$RepoRootResolved = (Resolve-Path $RepoRoot).Path.TrimEnd('\', '/')

$Branch = git -C $RepoRoot branch --show-current 2>$null
if (-not $Branch) { $Branch = "(detached)" }

# Compute plan path relative to repo root
$PlanRel = $PlanAbs.Substring($RepoRootResolved.Length + 1).Replace('\', '/')

Write-Host "REPO_ROOT=$RepoRoot"
Write-Host "BRANCH=$Branch"
Write-Host "PLAN_REL=$PlanRel"
Write-Host ""

# --- Check: Plan is committed ---

$Commit = git -C $RepoRoot log --oneline -1 -- $PlanRel 2>$null
if ($Commit) {
    Write-Host "PASS  Plan is committed ($Commit)"
} else {
    Write-Host "WARN  Plan is not committed to branch '$Branch' - commit the plan before proceeding"
}

# --- Check: Clean working state ---

$Dirty = git -C $RepoRoot status --porcelain 2>$null
if (-not $Dirty) {
    Write-Host "PASS  Working tree is clean"
} else {
    $DirtyCount = @($Dirty -split "`n").Count
    Write-Host "WARN  Working tree has $DirtyCount uncommitted change(s)"
}

# --- Opportunistic Worktree Mode guardrail ---
if (Select-String -Path $PlanAbs -Pattern "> **Worktree:** Yes" -Quiet) {
    Write-Host "`nExecuting in Worktree mode? Remember to bootstrap the branch/worktree (missing dev deps, etc.)"
}

# --- Result ---

Write-Host ""
Write-Host "PRE-CHECK PASSED"
exit 0
