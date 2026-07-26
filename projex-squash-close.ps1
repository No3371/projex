# projex-squash-close.ps1 — Squash-merge ephemeral branch into base, then delete ephemeral
# Usage: projex-squash-close.ps1 <repo-root> <base-branch> <ephemeral-branch> "commit message" [-Worktree] [-ResolveConflicts <paths>]
#
# -Worktree: merge from base, then best-effort remove the worktree at <repo>/.projexwt/<branch-suffix>.
#            The main working directory must already be on the base branch.
#
# -ResolveConflicts: repo-relative paths (files or directory prefixes) where conflicts are ANTICIPATED.
#            Default behaviour on conflict is unchanged: reset and roll back. With this parameter,
#            if EVERY conflicted path is covered by the list, the squash is left staged-with-conflicts
#            (exit 2) so the caller can resolve it. A conflict in any path outside the list still resets.
#            Unlike merge/rebase close this script is NOT re-runnable after a conflicted resolution —
#            a squash commit does not record the ephemeral as a parent, so the squash is recomputed
#            from the same base and conflicts again. The exit-2 message lists the finishing commands.
#
# Exit codes: 0 = closed, 1 = failed and rolled back, 2 = left in progress for the caller to resolve.

param(
    [Parameter(Mandatory)][string]$RepoRoot,
    [Parameter(Mandatory)][string]$Base,
    [Parameter(Mandatory)][string]$Ephemeral,
    [Parameter(Mandatory)][string]$CommitMsg,
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
    $verb = if ($inProgress -eq 'rebase') { "git -C $RepoRoot rebase --continue" } else { "git -C $RepoRoot commit" }
    Write-Error "A $inProgress is already in progress in '$RepoRoot' — nothing was changed. Finish it (resolve, git -C $RepoRoot add <paths>, $verb) then re-run, or cancel it first (git -C $RepoRoot merge --abort / rebase --abort; for a conflicted squash, discarding needs git reset --hard HEAD and your explicit approval)."
    exit 1
}

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
    $conflicted = Get-UnmergedPaths $RepoRoot
    if ($ResolveConflicts.Count -gt 0 -and $conflicted.Count -gt 0) {
        $uncovered = Get-UncoveredConflicts $conflicted $ResolveConflicts
        if ($uncovered.Count -eq 0) {
            $clist = ($conflicted | ForEach-Object { "  $_" }) -join "`n"
            $wtStep = if ($Worktree) { "  git -C $RepoRoot worktree remove $WtPath`n" } else { "" }
            Write-Host "Anticipated conflicts — squash left IN PROGRESS on '$Base' in '$RepoRoot' (not reset):`n$clist`nResolve them, then:`n  git -C $RepoRoot add <paths>`n  git -C $RepoRoot commit -m `"$CommitMsg`"`nThen finish the close by hand:`n$wtStep  git -C $RepoRoot worktree prune`n  git -C $RepoRoot branch -D $Ephemeral`nDo NOT re-run this script after committing: a squash commit does not record '$Ephemeral' as a parent, so the squash would be recomputed from the same base and conflict again."
            exit 2
        }
        git -C $RepoRoot reset --hard HEAD 2>$null
        $ulist = ($uncovered | ForEach-Object { "  $_" }) -join "`n"
        Write-Error "merge --squash conflict outside -ResolveConflicts — reset to clean state on '$Base'. Unanticipated conflicts:`n$ulist"
        exit 1
    }
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

# Commit squash. Nothing staged means there is nothing left to commit — either an earlier run's
# resolution was already committed (resume) or the branch has no net changes. Both are safe to
# carry on from; committing is skipped and cleanup proceeds, so re-running the script is idempotent.
git -C $RepoRoot diff --cached --quiet 2>$null
$nothingStaged = $LASTEXITCODE -eq 0
if ($nothingStaged) {
    Write-Host "Nothing to squash — '$Ephemeral' has no net changes against '$Base' (already integrated, or a resolution from an earlier run was committed). Skipping commit; proceeding to cleanup."
} else {
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
