# projex-worktree.ps1 — Create a worktree in <repo>/.projexwt/ (inside the repo)
# Usage: projex-worktree.ps1 <repo-root> <branch-name> [<base-ref>]
#
# Creates <repo>/.projexwt/<branch-suffix>/ where <branch-suffix> is the last path segment
# of <branch-name> (e.g., projex/2603071430-foo → 2603071430-foo).
# The worktree sits inside the repo so it stays in the editor workspace; .projexwt/ is
# registered in the repo's .git/info/exclude so the parent's git status stays clean.

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
$WtBase = Join-Path $RepoRoot ".projexwt"
$WtPath = Join-Path $WtBase $WtSuffix

# Check worktree doesn't already exist
if (Test-Path $WtPath) {
    Write-Error "Error: worktree already exists at '$WtPath'"
    exit 1
}

# Keep the in-repo worktree dir out of the parent's git status (local, not committed)
$CommonDir = git -C $RepoRoot rev-parse --path-format=absolute --git-common-dir
$ExcludeFile = Join-Path $CommonDir "info/exclude"
$ExcludeDir = Split-Path $ExcludeFile -Parent
if (-not (Test-Path $ExcludeDir)) { New-Item -ItemType Directory -Path $ExcludeDir -Force | Out-Null }
if (-not ((Test-Path $ExcludeFile) -and (Select-String -Path $ExcludeFile -Pattern '^\.projexwt/$' -Quiet))) {
    Add-Content -Path $ExcludeFile -Value '.projexwt/'
}

# Create worktree base directory if needed
if (-not (Test-Path $WtBase)) {
    New-Item -ItemType Directory -Path $WtBase -Force | Out-Null
}

# Fail if branch already exists
$_prev = $ErrorActionPreference; $ErrorActionPreference = "SilentlyContinue"
git -C $RepoRoot rev-parse --verify "refs/heads/$BranchName" 2>&1 | Out-Null
$ErrorActionPreference = $_prev
if ($LASTEXITCODE -eq 0) {
    Write-Error "Error: branch '$BranchName' already exists"
    exit 1
}

# Create worktree
$wtOut = git -C $RepoRoot worktree add $WtPath -b $BranchName $BaseRef 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Error "Error: could not create worktree at '$WtPath'`n$wtOut"
    exit 1
}

Write-Host "Worktree created: $WtPath (branch: $BranchName, base: $BaseRef)"
