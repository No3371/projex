# projex-rebase-close.ps1 — Rebase ephemeral onto base for linear history, fast-forward base, delete ephemeral
# Usage: projex-rebase-close.ps1 <repo-root> <base-branch> <ephemeral-branch> [-Worktree] [-ResolveConflicts <paths>]
#
# Replays the ephemeral branch's commits onto the tip of base (rewriting their SHAs),
# then fast-forwards base to include them. No merge commit is created.
#
# -Worktree: the ephemeral branch is checked out in a worktree at <repo>/.projexwt/<branch-suffix>.
#            The rebase runs inside that worktree; the main working directory must be on base.
#            The worktree is removed after the fast-forward succeeds.
#
# -ResolveConflicts: repo-relative paths (files or directory prefixes) where conflicts are ANTICIPATED.
#            Default behaviour on conflict is unchanged: abort and roll back. With this parameter,
#            if EVERY conflicted path is covered by the list, the rebase is left in progress (exit 2)
#            so the caller can resolve it. A conflict in any path outside the list still aborts.
#            Once the caller concludes the rebase, re-running this exact command finishes the close.
#
# Exit codes: 0 = closed, 1 = failed and rolled back, 2 = left in progress for the caller to resolve.

param(
    [Parameter(Mandatory)][string]$RepoRoot,
    [Parameter(Mandatory)][string]$Base,
    [Parameter(Mandatory)][string]$Ephemeral,
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

# Commits still queued behind the current stop, or -1 if it cannot be determined.
# A rebase halts at the FIRST conflicting commit, so a covered stop is not a promise that the
# remaining commits are conflict-free — the same gate is applied again at every later stop.
function Get-RemainingRebaseCommits([string]$Dir) {
    $gitDir = git -C $Dir rev-parse --absolute-git-dir 2>$null
    if (-not $gitDir) { return -1 }
    $todo = Join-Path $gitDir 'rebase-merge/git-rebase-todo'
    if (Test-Path $todo) {
        return @(Get-Content $todo | Where-Object { $_ -match '\S' -and $_ -notmatch '^\s*#' }).Count
    }
    $next = Join-Path $gitDir 'rebase-apply/next'
    $last = Join-Path $gitDir 'rebase-apply/last'
    if ((Test-Path $next) -and (Test-Path $last)) {
        return ([int](Get-Content $last).Trim() - [int](Get-Content $next).Trim())
    }
    return -1
}

# Full symbolic ref name of $Ref as resolved in $Dir, or '' when it is not a ref (raw SHA)
function Get-FullRef([string]$Dir, [string]$Ref) {
    $r = @(git -C $Dir rev-parse --symbolic-full-name $Ref 2>$null)
    if ($r.Count -eq 0) { return '' }
    return "$($r[0])".Trim()
}

# Tracked staged/unstaged content in $Dir. Untracked and ignored files are deliberately NOT counted:
# busy repos keep them around, and .projexwt/ itself surfaces as untracked whenever the
# .git/info/exclude registration is missing, so counting them would self-block worktree mode.
# Submodule dirt is excluded too — a superproject whose recorded submodule commit is unchanged is
# not dirty for integration purposes.
function Get-TrackedDirt([string]$Dir) {
    return @(git -C $Dir status --porcelain --untracked-files=no --ignore-submodules=dirty 2>$null | Where-Object { $_ -ne '' })
}

# Reject a Base that is not a local branch, naming what it actually resolved to.
function Assert-LocalBranch([string]$Dir, [string]$Ref) {
    $full = Get-FullRef $Dir $Ref
    if ($full -like 'refs/heads/*') { return $full }
    if ($full -like 'refs/tags/*') { $kind = "a tag ($full)" }
    elseif ($full -like 'refs/remotes/*') { $kind = "a remote-tracking ref ($full)" }
    elseif ($full -eq '') { $kind = 'a raw commit' }
    else { $kind = "'$full'" }
    Write-Error "Base '$Ref' resolves to $kind, not a local branch (refs/heads/*) — nothing was changed."
    exit 1
}

# Untracked (non-ignored) paths at $Dir that the ephemeral branch would bring in as tracked files.
# Squash and merge close get this refusal free from git, because their integration command runs at
# the base worktree before anything is rewritten. Rebase replays commits first, so it has to ask the
# question itself or it discovers the collision only after the ephemeral SHAs are already rewritten.
function Get-UntrackedCollisions([string]$Dir, [string]$BaseRefName, [string]$EphRefName) {
    $incoming = @(git -C $Dir diff --name-only "$BaseRefName...$EphRefName" 2>$null | Where-Object { $_ -ne '' })
    if ($incoming.Count -eq 0) { return @() }
    $untracked = @(git -C $Dir ls-files --others --exclude-standard 2>$null | Where-Object { $_ -ne '' })
    if ($untracked.Count -eq 0) { return @() }
    return @($incoming | Where-Object { $untracked -contains $_ })
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

# Refuse to start on top of an unfinished operation — never silently discard someone's half-done
# resolution (a mid-flight multi-commit rebase would otherwise be aborted, losing earlier resolutions)
$OpDir = if ($Worktree) { $WtPath } else { $RepoRoot }
$inProgress = Get-InProgressOp $OpDir
if ($inProgress) {
    $verb = if ($inProgress -eq 'rebase') { "git -C $OpDir rebase --continue" } else { "git -C $OpDir commit" }
    Write-Error "A $inProgress is already in progress in '$OpDir' — nothing was changed. Finish it (resolve, git -C $OpDir add <paths>, $verb) then re-run, or cancel it first (git -C $OpDir rebase --abort / merge --abort)."
    exit 1
}

# --- Dirty-base safety gate: everything below runs BEFORE any rebase/checkout/fast-forward -----
# Base must be a local branch. `rev-parse --verify` above also accepts tags, raw SHAs and
# remote-tracking refs; none of those can be advanced by a close, so reject them by name.
$BaseRef = Assert-LocalBranch $RepoRoot $Base

if ($Worktree) {
    # RepoRoot is the recorded originating/base worktree — which may be any registered worktree,
    # not necessarily the primary one. It must still have Base checked out; never guess another.
    $originRef = @(git -C $RepoRoot symbolic-ref --quiet HEAD 2>$null)
    if ($originRef.Count -eq 0) {
        Write-Error "'$RepoRoot' has a detached HEAD, not branch '$Base' — nothing was changed. Check '$Base' out there, or pass the worktree that holds it."
        exit 1
    }
    $originRef = "$($originRef[0])".Trim()
    if ($originRef -ne $BaseRef) {
        Write-Error "'$RepoRoot' has '$($originRef -replace '^refs/heads/', '')' checked out, not '$Base' — nothing was changed. Finalizers never substitute another worktree or branch."
        exit 1
    }
}

# Pre-flight (not a guarantee): the checkout about to be fast-forwarded must have no tracked
# changes. Nothing re-checks between here and the fast-forward, so a concurrent writer can still
# dirty it — git's own overwrite refusal remains the real backstop.
$dirt = Get-TrackedDirt $RepoRoot
if ($dirt.Count -gt 0) {
    $dlist = ($dirt | Select-Object -First 10) -join "`n"
    Write-Error "'$RepoRoot' has tracked changes — commit or stash them before closing; nothing was changed. Untracked and ignored files are fine, and a dirty submodule alone does not count:`n$dlist"
    exit 1
}

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

    # Untracked content at the base worktree is allowed by the gate above, but a path the ephemeral
    # branch adds as tracked would make the later `merge --ff-only` refuse — after the rebase has
    # already rewritten the ephemeral SHAs. Ask now, while nothing has been mutated.
    $colliding = Get-UntrackedCollisions $RepoRoot $Base $Ephemeral
    if ($colliding.Count -gt 0) {
        $clist = ($colliding | Select-Object -First 10 | ForEach-Object { "  $_" }) -join "`n"
        Write-Error "Untracked file(s) at '$RepoRoot' occupy paths that '$Ephemeral' brings in as tracked — the fast-forward would be refused after the rebase had already rewritten history, so nothing was changed. Move, delete or commit these, then re-run:`n$clist"
        exit 1
    }

    git -C $WtPath rebase $Base
    if ($LASTEXITCODE -ne 0) {
        $conflicted = Get-UnmergedPaths $WtPath
        if ($ResolveConflicts.Count -gt 0 -and $conflicted.Count -gt 0) {
            $uncovered = Get-UncoveredConflicts $conflicted $ResolveConflicts
            if ($uncovered.Count -eq 0) {
                $clist = ($conflicted | ForEach-Object { "  $_" }) -join "`n"
                $remaining = Get-RemainingRebaseCommits $WtPath
                $note = if ($remaining -gt 0) { "`n$remaining commit(s) remain to be replayed after this one — a rebase stops at the first conflicting commit, so later stops may surface conflicts outside -ResolveConflicts. The same gate applies at each stop." } else { "" }
                Write-Host "Anticipated conflicts — rebase left IN PROGRESS in worktree '$WtPath' (not aborted):`n$clist$note`nResolve them, then:`n  git -C $WtPath add <paths>`n  git -C $WtPath rebase --continue   (repeat if later commits conflict)`nThen re-run this exact command to finish the close."
                exit 2
            }
            git -C $WtPath rebase --abort 2>$null
            $ulist = ($uncovered | ForEach-Object { "  $_" }) -join "`n"
            Write-Error "Rebase conflict outside -ResolveConflicts — aborted, worktree '$WtPath' left on '$Ephemeral'. Unanticipated conflicts:`n$ulist"
            exit 1
        }
        git -C $WtPath rebase --abort 2>$null
        Write-Error "Rebase conflict — aborted, worktree '$WtPath' left on '$Ephemeral'. Resolve manually or use Option A/B."
        exit 1
    }
} else {
    # Checkout mode: remember starting branch, rebase ephemeral onto base. (Tracked cleanliness was
    # already gated above; `git checkout` refuses to clobber untracked paths, so no pre-check needed.)
    $OrigBranch = git -C $RepoRoot rev-parse --abbrev-ref HEAD

    git -C $RepoRoot checkout $Ephemeral
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Could not checkout '$Ephemeral' — no state changed"
        exit 1
    }

    # Rebase ephemeral onto base (rewrites ephemeral's commits)
    git -C $RepoRoot rebase $Base
    if ($LASTEXITCODE -ne 0) {
        $conflicted = Get-UnmergedPaths $RepoRoot
        if ($ResolveConflicts.Count -gt 0 -and $conflicted.Count -gt 0) {
            $uncovered = Get-UncoveredConflicts $conflicted $ResolveConflicts
            if ($uncovered.Count -eq 0) {
                $clist = ($conflicted | ForEach-Object { "  $_" }) -join "`n"
                $remaining = Get-RemainingRebaseCommits $RepoRoot
                if ($remaining -gt 0) { $clist = "$clist`n$remaining commit(s) remain to be replayed after this one — a rebase stops at the first conflicting commit, so later stops may surface conflicts outside -ResolveConflicts. The same gate applies at each stop." }
                Write-Host "Anticipated conflicts — rebase left IN PROGRESS on '$Ephemeral' in '$RepoRoot' (not aborted):`n$clist`nResolve them, then:`n  git -C $RepoRoot add <paths>`n  git -C $RepoRoot rebase --continue   (repeat if later commits conflict)`nThen re-run this exact command to finish the close."
                exit 2
            }
            git -C $RepoRoot rebase --abort 2>$null
            git -C $RepoRoot checkout $OrigBranch 2>$null
            $ulist = ($uncovered | ForEach-Object { "  $_" }) -join "`n"
            Write-Error "Rebase conflict outside -ResolveConflicts — aborted, restored to '$OrigBranch'. Unanticipated conflicts:`n$ulist"
            exit 1
        }
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
