# projex-rebase-close.ps1 — Rebase ephemeral onto base for linear history, fast-forward base, delete ephemeral
# Usage: projex-rebase-close.ps1 <repo-root> <base-branch> <ephemeral-branch> [-Worktree]
#
# Replays the ephemeral branch's commits onto the tip of base (rewriting their SHAs),
# then fast-forwards base to include them. No merge commit is created.
#
# -Worktree: the ephemeral branch is checked out in a worktree at <repo>/.projexwt/<branch-suffix>.
#            The rebase runs inside that worktree; the main working directory must be on base.
#            The worktree is removed after the fast-forward succeeds.

param(
    [Parameter(Mandatory)][string]$RepoRoot,
    [Parameter(Mandatory)][string]$Base,
    [Parameter(Mandatory)][string]$Ephemeral,
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
$WtBase = Join-Path $RepoRoot ".projexwt"
$WtPath = Join-Path $WtBase $WtSuffix

if ($Worktree) {
    # Worktree mode: rebase inside the worktree (ephemeral is checked out there), then ff base.
    if (-not (Test-Path $WtPath)) {
        Write-Error "Worktree '$WtPath' does not exist — is worktree mode correct?"
        exit 1
    }
    # Pre-flight cleanliness gate — refuse to rewrite history / finalize over a non-clean worktree
    # (unified: git status --porcelain covers untracked AND uncommitted tracked, replacing the old tracked-only check)
    $dirty = @(git -C $WtPath status --porcelain 2>$null)
    if ($dirty.Count -gt 0) {
        $list = ($dirty | Select-Object -First 10) -join "`n"
        Write-Error "Worktree '$WtPath' is not clean — commit tracked edits, and commit or remove untracked tooling, then re-run:`n$list"
        exit 1
    }
    $ignored = @(git -C $WtPath status --porcelain --ignored=matching 2>$null | Where-Object { $_ -match '^!!' })
    if ($ignored.Count -gt 0) {
        $ilist = ($ignored | Select-Object -First 5) -join "`n"
        Write-Warning "Worktree contains ignored content (deps/build output) — removal may leave a directory to clean manually:`n$ilist"
    }

    git -C $WtPath rebase $Base
    if ($LASTEXITCODE -ne 0) {
        git -C $WtPath rebase --abort 2>$null
        Write-Error "Rebase conflict — aborted, worktree '$WtPath' left on '$Ephemeral'. Resolve manually or use Option A/B."
        exit 1
    }
} else {
    # Checkout mode: require clean tree, remember starting branch, rebase ephemeral onto base.
    git -C $RepoRoot diff --quiet 2>$null
    $diffClean = $LASTEXITCODE -eq 0
    git -C $RepoRoot diff --cached --quiet 2>$null
    $indexClean = $LASTEXITCODE -eq 0
    if (-not $diffClean -or -not $indexClean) {
        Write-Error "Working tree has uncommitted changes — commit or stash before closing"
        exit 1
    }

    $OrigBranch = git -C $RepoRoot rev-parse --abbrev-ref HEAD

    git -C $RepoRoot checkout $Ephemeral
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Could not checkout '$Ephemeral' — no state changed"
        exit 1
    }

    # Rebase ephemeral onto base (rewrites ephemeral's commits)
    git -C $RepoRoot rebase $Base
    if ($LASTEXITCODE -ne 0) {
        git -C $RepoRoot rebase --abort 2>$null
        git -C $RepoRoot checkout $OrigBranch 2>$null
        Write-Error "Rebase conflict — aborted, restored to '$OrigBranch'. Resolve manually or use Option A/B."
        exit 1
    }
}

# Fast-forward base to the rebased ephemeral tip (no merge commit).
# In checkout mode we must switch to base first; in worktree mode base is already checked out in the main dir.
if (-not $Worktree) {
    git -C $RepoRoot checkout $Base
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Rebased '$Ephemeral' but could not checkout '$Base' to fast-forward — finish manually: git checkout $Base; git merge --ff-only $Ephemeral"
        exit 1
    }
}

git -C $RepoRoot merge --ff-only $Ephemeral
if ($LASTEXITCODE -ne 0) {
    Write-Error "Fast-forward of '$Base' failed unexpectedly after rebase — '$Ephemeral' is rebased; finish manually: git merge --ff-only $Ephemeral"
    exit 1
}

if ($Worktree) {
    git -C $RepoRoot worktree remove $WtPath
    if ($LASTEXITCODE -ne 0) {
        $registered = git -C $RepoRoot worktree list --porcelain | Where-Object { $_ -match ('/\.projexwt/' + [regex]::Escape($WtSuffix) + '$') }
        if ($registered) {
            $blocking = (git -C $WtPath status --porcelain --ignored=matching 2>$null | Select-Object -First 10) -join "`n"
            Write-Warning "Could not remove worktree '$WtPath' — close succeeded. Blocking content:`n$blocking`nRemove the files above (or release any lock/open handle on the worktree — an empty list means the block is a lock, not dirty content), then: git -C $RepoRoot worktree remove $WtPath"
        } else {
            Write-Warning "Worktree unregistered but directory remains at '$WtPath' — close succeeded; inspect and delete the plain directory manually, then run: git -C $RepoRoot worktree prune"
        }
    }
}

git -C $RepoRoot worktree prune 2>$null

# Delete ephemeral branch (non-fatal)
git -C $RepoRoot branch -d $Ephemeral
if ($LASTEXITCODE -ne 0) {
    Write-Warning "Could not delete '$Ephemeral' — changes are on '$Base', delete manually: git branch -d $Ephemeral"
} else {
    Write-Host "Rebased '$Ephemeral' -> '$Base' (linear, fast-forward). Branch deleted."
}
