# projex-squash-close.ps1 — Squash-merge ephemeral branch into base, then delete ephemeral
# Usage: projex-squash-close.ps1 <repo-root> <base-branch> <ephemeral-branch> "commit message" [-Worktree]
#
# -Worktree: merge from base, then best-effort remove the worktree at <repo>/.projexwt/<branch-suffix>.
#            The main working directory must already be on the base branch.

param(
    [Parameter(Mandatory)][string]$RepoRoot,
    [Parameter(Mandatory)][string]$Base,
    [Parameter(Mandatory)][string]$Ephemeral,
    [Parameter(Mandatory)][string]$CommitMsg,
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
    # Worktree mode: merge first; cleanup happens after commit so Windows locks cannot block close.
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
        Write-Error "Could not checkout '$Base' — still on ephemeral branch, no state changed"
        exit 1
    }
}

# Pre-flight cleanliness gate (worktree mode) — refuse to finalize over a non-clean worktree
if ($Worktree) {
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
}

# Squash merge
git -C $RepoRoot merge --squash $Ephemeral
if ($LASTEXITCODE -ne 0) {
    git -C $RepoRoot reset --hard HEAD 2>$null
    if ($Worktree) {
        Write-Error "merge --squash failed — reset to clean state on '$Base'. Branch '$Ephemeral' still exists; re-create worktree with: git worktree add $WtPath $Ephemeral"
    } else {
        git -C $RepoRoot checkout $Ephemeral 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Error "merge --squash failed — rolled back to '$Ephemeral'"
        } else {
            Write-Error "merge --squash failed — reset to clean state on '$Base'"
        }
    }
    exit 1
}

# Commit squash
git -C $RepoRoot commit -m $CommitMsg
if ($LASTEXITCODE -ne 0) {
    git -C $RepoRoot reset HEAD 2>$null
    if ($Worktree) {
        Write-Error "Commit failed — squashed changes unstaged but preserved in working tree on '$Base'. Retry: git commit -m '...'. Branch '$Ephemeral' still exists; re-create worktree with: git worktree add $WtPath $Ephemeral"
    } else {
        Write-Error "Commit failed — squashed changes unstaged but preserved in working tree on '$Base'. Retry: git commit -m '...'. Or rollback: git checkout -- ."
    }
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
git -C $RepoRoot branch -D $Ephemeral
if ($LASTEXITCODE -ne 0) {
    Write-Warning "Could not delete '$Ephemeral' — changes are merged, delete manually: git branch -D $Ephemeral"
} else {
    Write-Host "Squash-merged '$Ephemeral' -> '$Base'. Branch deleted."
}
