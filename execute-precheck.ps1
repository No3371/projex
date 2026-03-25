# execute-precheck.ps1 — Pre-execution validation for a plan
# Usage: execute-precheck.ps1 <plan-file>
#
# Validates mechanical checklist items before execution:
#   - Plan file exists and is committed to current branch
#   - Plan status is "Ready"
#   - Working tree cleanliness (warning, not failure)
#
# Outputs key=value pairs for use by the caller:
#   REPO_ROOT, BRANCH, PLAN_REL

param(
    [Parameter(Mandatory)][string]$PlanFile
)

$Errors = @()

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
    Write-Host "FAIL  Plan is not committed to branch '$Branch'"
    $Errors += "Plan must be committed to base branch before execution"
}

# --- Check: Plan status is Ready ---

$StatusLine = (Get-Content $PlanAbs | Select-String -Pattern '^\s*>?\s*\*{0,2}Status\*{0,2}:' | Select-Object -First 1)
if ($StatusLine) {
    # Strip markdown formatting: > **Status:** value  →  value
    $Status = $StatusLine.Line -replace '.*[Ss]tatus\*\*:\s*', '' -replace '`', '' -replace '\s*$', ''
    if ($Status -match '^[Rr]eady') {
        Write-Host "PASS  Plan status is '$Status'"
    } else {
        Write-Host "FAIL  Plan status is '$Status' - expected 'Ready'"
        $Errors += "Plan status must be 'Ready' to execute"
    }
} else {
    Write-Host "FAIL  No Status field found in plan"
    $Errors += "Plan must contain a Status field"
}

# --- Check: Clean working state ---

$Dirty = git -C $RepoRoot status --porcelain 2>$null
if (-not $Dirty) {
    Write-Host "PASS  Working tree is clean"
} else {
    $DirtyCount = @($Dirty -split "`n").Count
    Write-Host "WARN  Working tree has $DirtyCount uncommitted change(s)"
}

# --- Result ---

Write-Host ""
if ($Errors.Count -eq 0) {
    Write-Host "PRE-CHECK PASSED"
    exit 0
} else {
    Write-Host "PRE-CHECK FAILED ($($Errors.Count) issue(s)):"
    foreach ($e in $Errors) {
        Write-Host "  - $e"
    }
    exit 1
}
