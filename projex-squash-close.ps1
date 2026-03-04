# projex-squash-close.ps1 — Squash-merge ephemeral branch into base, then delete ephemeral
# Usage: projex-squash-close.ps1 <repo-root> <base-branch> <ephemeral-branch> "commit message"

param(
    [Parameter(Mandatory)][string]$RepoRoot,
    [Parameter(Mandatory)][string]$Base,
    [Parameter(Mandatory)][string]$Ephemeral,
    [Parameter(Mandatory)][string]$CommitMsg
)

# Validate repo
git -C $RepoRoot rev-parse --git-dir 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Error "'$RepoRoot' is not a git repository"
    exit 1
}

# Validate branches exist
git -C $RepoRoot rev-parse --verify $Base | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Error "Base branch '$Base' does not exist"
    exit 1
}

git -C $RepoRoot rev-parse --verify $Ephemeral | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Error "Ephemeral branch '$Ephemeral' does not exist"
    exit 1
}

if ($Base -eq $Ephemeral) {
    Write-Error "Base and ephemeral branch cannot be the same ('$Base')"
    exit 1
}

# Require clean working tree — reset --hard is used on squash failure and must not destroy other changes
git -C $RepoRoot diff --quiet 2>$null
$diffClean = $LASTEXITCODE -eq 0
git -C $RepoRoot diff --cached --quiet 2>$null
$indexClean = $LASTEXITCODE -eq 0
if (-not $diffClean -or -not $indexClean) {
    Write-Error "Working tree has uncommitted changes — commit or stash before closing"
    exit 1
}

# Checkout base
git -C $RepoRoot checkout $Base
if ($LASTEXITCODE -ne 0) {
    Write-Error "Could not checkout '$Base' — still on ephemeral branch, no state changed"
    exit 1
}

# Squash merge
git -C $RepoRoot merge --squash $Ephemeral
if ($LASTEXITCODE -ne 0) {
    git -C $RepoRoot reset --hard HEAD 2>$null
    git -C $RepoRoot checkout $Ephemeral 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Error "merge --squash failed — rolled back to '$Ephemeral'"
    } else {
        Write-Error "merge --squash failed — reset to clean state on '$Base'"
    }
    exit 1
}

# Commit squash
git -C $RepoRoot commit -m $CommitMsg
if ($LASTEXITCODE -ne 0) {
    git -C $RepoRoot reset --hard HEAD 2>$null
    git -C $RepoRoot checkout $Ephemeral 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Error "Commit failed — reset to clean state, rolled back to '$Ephemeral'"
    } else {
        Write-Error "Commit failed — reset to clean state on '$Base'"
    }
    exit 1
}

# Delete ephemeral branch (non-fatal)
git -C $RepoRoot branch -D $Ephemeral
if ($LASTEXITCODE -ne 0) {
    Write-Warning "Could not delete '$Ephemeral' — changes are merged, delete manually: git branch -D $Ephemeral"
} else {
    Write-Host "Squash-merged '$Ephemeral' -> '$Base'. Branch deleted."
}
