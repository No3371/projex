# projex-merge-close.ps1 — Merge with full history into base, then delete ephemeral
# Usage: projex-merge-close.ps1 <repo-root> <base-branch> <ephemeral-branch> "merge message" [-Worktree]
#
# -Worktree: remove the worktree at <repo>.projexwt/<branch-suffix> instead of checking out base.
#            The main working directory must already be on the base branch.

param(
    [Parameter(Mandatory)][string]$RepoRoot,
    [Parameter(Mandatory)][string]$Base,
    [Parameter(Mandatory)][string]$Ephemeral,
    [Parameter(Mandatory)][string]$MergeMsg,
    [switch]$Worktree
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

$WtSuffix = ($Ephemeral -split '/')[-1]
$WtBase = Join-Path (Split-Path $RepoRoot -Parent) ("$(Split-Path $RepoRoot -Leaf).projexwt")
$WtPath = Join-Path $WtBase $WtSuffix

if ($Worktree) {
    # Worktree mode: remove worktree, then merge (already on base branch)
    git -C $RepoRoot worktree remove $WtPath
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Could not remove worktree '$WtPath' — branch '$Ephemeral' still exists for manual recovery"
        exit 1
    }
} else {
    # Checkout mode: require clean tree, switch to base
    git -C $RepoRoot diff --quiet 2>$null
    $diffClean = $LASTEXITCODE -eq 0
    git -C $RepoRoot diff --cached --quiet 2>$null
    $indexClean = $LASTEXITCODE -eq 0
    if (-not $diffClean -or -not $indexClean) {
        Write-Error "Working tree has uncommitted changes — commit or stash before closing"
        exit 1
    }

    git -C $RepoRoot checkout $Base
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Could not checkout '$Base' — still on ephemeral, no state changed"
        exit 1
    }
}

# Merge with full history
git -C $RepoRoot merge $Ephemeral --no-ff -m $MergeMsg
if ($LASTEXITCODE -ne 0) {
    git -C $RepoRoot merge --abort 2>$null
    if ($Worktree) {
        Write-Error "Merge failed — aborted on '$Base'. Branch '$Ephemeral' still exists; re-create worktree with: git worktree add $WtPath $Ephemeral"
    } else {
        git -C $RepoRoot checkout $Ephemeral 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Error "Merge failed — aborted, rolled back to '$Ephemeral'"
        } else {
            Write-Error "Merge failed — aborted, still on '$Base'"
        }
    }
    exit 1
}

# Delete ephemeral branch (non-fatal)
git -C $RepoRoot branch -d $Ephemeral
if ($LASTEXITCODE -ne 0) {
    Write-Warning "Could not delete '$Ephemeral' — changes are merged, delete manually: git branch -d $Ephemeral"
} else {
    Write-Host "Merged '$Ephemeral' -> '$Base' with history. Branch deleted."
}
