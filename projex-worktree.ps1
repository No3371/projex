# projex-worktree.ps1 — Create a worktree in <repo>.projexwt/ (sibling to repo)
# Usage: projex-worktree.ps1 <repo-root> <branch-name> [<base-ref>]
#
# Creates <repo>.projexwt/<branch-suffix>/ where <branch-suffix> is the last path segment
# of <branch-name> (e.g., .projex/20260307-foo → 20260307-foo).
# The worktree directory sits next to the repo, not inside it.

param(
    [Parameter(Mandatory=$true)][string]$RepoRoot,
    [Parameter(Mandatory=$true)][string]$BranchName,
    [string]$BaseRef = "HEAD"
)

$ErrorActionPreference = "Stop"

# Validate repo
$gitDir = git -C $RepoRoot rev-parse --git-dir 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Error "Error: '$RepoRoot' is not a git repository"
    exit 1
}

# Derive worktree suffix from branch name (last path segment)
$WtSuffix = ($BranchName -split '/')[-1]
$WtBase = Join-Path (Split-Path $RepoRoot -Parent) ("$(Split-Path $RepoRoot -Leaf).projexwt")
$WtPath = Join-Path $WtBase $WtSuffix

# Check worktree doesn't already exist
if (Test-Path $WtPath) {
    Write-Error "Error: worktree already exists at '$WtPath'"
    exit 1
}

# Create sibling worktree directory if needed
if (-not (Test-Path $WtBase)) {
    New-Item -ItemType Directory -Path $WtBase -Force | Out-Null
}

# Create worktree
$wtOut = git -C $RepoRoot worktree add $WtPath -b $BranchName $BaseRef 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Error "Error: could not create worktree at '$WtPath'"
    exit 1
}

Write-Host "Worktree created: $WtPath (branch: $BranchName, base: $BaseRef)"
