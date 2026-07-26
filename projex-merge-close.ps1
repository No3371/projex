# projex-merge-close.ps1 — Merge with full history into base, then delete ephemeral
# Usage: projex-merge-close.ps1 <repo-root> <base-branch> <ephemeral-branch> "merge message" [-Worktree] [-ResolveConflicts <paths>]
#
# -Worktree: merge from base, then best-effort remove the worktree at <repo>/.projexwt/<branch-suffix>.
#            The main working directory must already be on the base branch.
#
# -ResolveConflicts: repo-relative paths (files or directory prefixes) where conflicts are ANTICIPATED.
#            Default behaviour on conflict is unchanged: abort and roll back. With this parameter,
#            if EVERY conflicted path is covered by the list, the merge is left in progress (exit 2)
#            so the caller can resolve it. A conflict in any path outside the list still aborts.
#            Once the caller commits the resolution, re-running this exact command finishes the close.
#
# Exit codes: 0 = closed, 1 = failed and rolled back, 2 = left in progress for the caller to resolve.

param(
    [Parameter(Mandatory)][string]$RepoRoot,
    [Parameter(Mandatory)][string]$Base,
    [Parameter(Mandatory)][string]$Ephemeral,
    [Parameter(Mandatory)][string]$MergeMsg,
    [switch]$Worktree,
    [string[]]$ResolveConflicts = @()
)

# Paths git reports as unmerged (conflicted) in $Dir
function Get-UnmergedPaths([string]$Dir) {
    return @(git -C $Dir diff --name-only --diff-filter=U 2>$null | Where-Object { $_ -ne '' })
}

# Conflicted paths NOT covered by -ResolveConflicts (exact file match or directory prefix)
function Get-UncoveredConflicts([string[]]$Conflicted, [string[]]$Allowed) {
    $norm = @($Allowed | ForEach-Object { ($_ -replace '\\', '/').TrimEnd('/') } | Where-Object { $_ -ne '' })
    return @($Conflicted | Where-Object {
        $p = $_ -replace '\\', '/'
        -not @($norm | Where-Object { $p -eq $_ -or $p.StartsWith("$_/") })
    })
}

# Unfinished git operation in $Dir — 'rebase', 'merge', 'conflict', or $null
function Get-InProgressOp([string]$Dir) {
    $gitDir = git -C $Dir rev-parse --absolute-git-dir 2>$null
    if (-not $gitDir) { return $null }
    if ((Test-Path (Join-Path $gitDir 'rebase-merge')) -or (Test-Path (Join-Path $gitDir 'rebase-apply'))) { return 'rebase' }
    if (Test-Path (Join-Path $gitDir 'MERGE_HEAD')) { return 'merge' }
    if ((Get-UnmergedPaths $Dir).Count -gt 0) { return 'conflict' }
    return $null
}

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

# Refuse to start on top of an unfinished operation — never silently discard someone's half-done resolution
$inProgress = Get-InProgressOp $RepoRoot
if ($inProgress) {
    $verb = if ($inProgress -eq 'rebase') { "git -C $RepoRoot rebase --continue" } else { "git -C $RepoRoot commit --no-edit" }
    Write-Error "A $inProgress is already in progress in '$RepoRoot' — nothing was changed. Finish it (resolve, git -C $RepoRoot add <paths>, $verb) then re-run, or cancel it first (git -C $RepoRoot merge --abort / rebase --abort)."
    exit 1
}

if ($Worktree) {
    # Worktree mode: merge first; cleanup happens after merge so Windows locks cannot block close.
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

# Merge with full history
git -C $RepoRoot merge $Ephemeral --no-ff -m $MergeMsg
if ($LASTEXITCODE -ne 0) {
    $conflicted = Get-UnmergedPaths $RepoRoot
    if ($ResolveConflicts.Count -gt 0 -and $conflicted.Count -gt 0) {
        $uncovered = Get-UncoveredConflicts $conflicted $ResolveConflicts
        if ($uncovered.Count -eq 0) {
            $clist = ($conflicted | ForEach-Object { "  $_" }) -join "`n"
            Write-Host "Anticipated conflicts — merge left IN PROGRESS on '$Base' in '$RepoRoot' (not aborted):`n$clist`nResolve them, then:`n  git -C $RepoRoot add <paths>`n  git -C $RepoRoot commit --no-edit`nThen re-run this exact command to finish the close (the merge will be a no-op; cleanup and branch deletion proceed)."
            exit 2
        }
        git -C $RepoRoot merge --abort 2>$null
        $ulist = ($uncovered | ForEach-Object { "  $_" }) -join "`n"
        Write-Error "Merge conflict outside -ResolveConflicts — aborted on '$Base'. Unanticipated conflicts:`n$ulist"
        exit 1
    }
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
    Write-Warning "Could not delete '$Ephemeral' — changes are merged, delete manually: git branch -d $Ephemeral"
} else {
    Write-Host "Merged '$Ephemeral' -> '$Base' with history. Branch deleted."
}
