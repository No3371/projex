# projex-worktree.ps1 — Create a worktree in .projexwt/ with gitignore enforcement
# Usage: projex-worktree.ps1 <repo-root> <branch-name> [<base-ref>]
#
# Creates .projexwt/<branch-suffix>/ where <branch-suffix> is the last path segment
# of <branch-name> (e.g., projex/20260307-foo → 20260307-foo).
#
# Gitignore gate: if .projexwt/ is not in .gitignore, the script adds it and commits
# before creating the worktree. This is a hard prerequisite — never bypassed.

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
$WtPath = Join-Path $RepoRoot ".projexwt" $WtSuffix

# --- Gitignore gate ---
git -C $RepoRoot check-ignore -q .projexwt 2>$null
if ($LASTEXITCODE -ne 0) {
    $GitignorePath = Join-Path $RepoRoot ".gitignore"
    if (Test-Path $GitignorePath) {
        Add-Content -Path $GitignorePath -Value ".projexwt/"
    } else {
        Set-Content -Path $GitignorePath -Value ".projexwt/"
    }
    git -C $RepoRoot add .gitignore
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Error: could not stage .gitignore"
        exit 1
    }
    $commitOut = git -C $RepoRoot commit -m "projex: gitignore .projexwt/" 2>&1
    if ($LASTEXITCODE -ne 0) {
        git -C $RepoRoot restore --staged .gitignore 2>$null
        Write-Error "Error: could not commit .gitignore update"
        exit 1
    }
    Write-Host "Added .projexwt/ to .gitignore and committed."
}

# Check worktree doesn't already exist
if (Test-Path $WtPath) {
    Write-Error "Error: worktree already exists at '$WtPath'"
    exit 1
}

# Create .projexwt/ directory if needed
$projexwtDir = Join-Path $RepoRoot ".projexwt"
if (-not (Test-Path $projexwtDir)) {
    New-Item -ItemType Directory -Path $projexwtDir -Force | Out-Null
}

# Create worktree
$wtOut = git -C $RepoRoot worktree add $WtPath -b $BranchName $BaseRef 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Error "Error: could not create worktree at '$WtPath'"
    exit 1
}

Write-Host "Worktree created: $WtPath (branch: $BranchName, base: $BaseRef)"
