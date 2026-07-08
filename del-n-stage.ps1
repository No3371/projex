# del-n-stage.ps1 — Batch git rm with rollback on failure
# Usage: del-n-stage.ps1 <repo-root> file1 [file2 ...]
#
# Deletes each file and stages the deletion.
# Uses git rm for tracked files; plain Remove-Item for untracked files.
# Does NOT commit. On failure, rolls back all completed deletions in reverse order.

param(
    [Parameter(Mandatory)][string]$RepoRoot,
    [Parameter(Mandatory, ValueFromRemainingArguments)][string[]]$Files
)

# Validate repo root
$Toplevel = (git -C $RepoRoot rev-parse --show-toplevel 2>$null)
if ($LASTEXITCODE -ne 0 -or -not $Toplevel) {
    Write-Error "'$RepoRoot' is not a git repository"
    exit 1
}
$RepoCanonical = (Resolve-Path $RepoRoot).Path.TrimEnd('\', '/')
$TopCanonical  = (Resolve-Path $Toplevel).Path.TrimEnd('\', '/')
if ($RepoCanonical -ne $TopCanonical) {
    Write-Error "'$RepoRoot' is not a repo root — toplevel is '$Toplevel'.`n  The <repo-root> argument must be the repository's top-level directory."
    exit 1
}

# Validate all paths belong to this repo
foreach ($f in $Files) {
    $checkDir = Join-Path $RepoRoot $f
    while ($checkDir -and -not (Test-Path $checkDir -PathType Container)) {
        $checkDir = Split-Path $checkDir -Parent
    }
    $fileToplevel = $null
    $fileCanonical = $null
    if ($checkDir) {
        $fileToplevel = git -C $checkDir rev-parse --show-toplevel 2>$null
        if ($fileToplevel) {
            $resolved = Resolve-Path $fileToplevel -ErrorAction SilentlyContinue
            if ($resolved) { $fileCanonical = $resolved.Path.TrimEnd('\', '/') }
        }
    }
    if ($fileCanonical -ne $TopCanonical) {
        $msg = "'$f' belongs to a different repo than '$RepoRoot'."
        if ($fileToplevel) { $msg += "`n  File's repo root: $fileToplevel" }
        $msg += "`n  Expected repo root: $Toplevel"
        $msg += "`n  Verify the <repo-root> argument matches the repository containing these files."
        Write-Error $msg
        exit 1
    }
}

# Track completed deletions for rollback
$doneFiles = @()
$doneTracked = @()
$doneBackups = @()

function Cleanup-Backups {
    foreach ($bk in $script:doneBackups) {
        Remove-Item -Path $bk -Force -ErrorAction SilentlyContinue
    }
}

function Rollback {
    if ($script:doneFiles.Count -eq 0) { return }
    Write-Host "Rolling back $($script:doneFiles.Count) completed deletion(s)..."
    $failed = $false
    for ($i = $script:doneFiles.Count - 1; $i -ge 0; $i--) {
        $f = $script:doneFiles[$i]
        $bk = $script:doneBackups[$i]
        $fullPath = Join-Path $RepoRoot $f

        # Restore the file from backup
        try {
            $restoreDir = Split-Path $fullPath -Parent
            if (!(Test-Path $restoreDir)) { New-Item -ItemType Directory -Path $restoreDir -Force | Out-Null }
            Copy-Item -Path $bk -Destination $fullPath -Force
        } catch {
            Write-Host "  Warning: could not restore '$f' from backup"
            Write-Host "  $_"
            $failed = $true
            continue
        }

        if ($script:doneTracked[$i]) {
            # Unstage the deletion without touching the working tree (preserves backup content)
            git -C $RepoRoot reset HEAD -- $f 2>$null | Out-Null
            if ($LASTEXITCODE -ne 0) {
                # Fallback: just add it back
                git -C $RepoRoot add -- $f 2>$null | Out-Null
            }
        }
        # Untracked: nothing to unstage, file is simply restored on disk
    }
    Cleanup-Backups
    if ($failed) {
        Write-Host "Rollback incomplete — manual intervention required."
    } else {
        Write-Host "Rollback complete."
    }
}

# Execute deletions
foreach ($f in $Files) {
    $fullPath = Join-Path $RepoRoot $f

    # Verify file exists
    if (!(Test-Path $fullPath -PathType Leaf)) {
        Write-Error "'$f' does not exist"
        Rollback
        exit 1
    }

    # Back up before deleting
    $backup = [System.IO.Path]::GetTempFileName()
    try {
        Copy-Item -Path $fullPath -Destination $backup -Force
    } catch {
        Write-Error "Could not back up '$f'`n$_"
        Remove-Item -Path $backup -Force -ErrorAction SilentlyContinue
        Rollback
        exit 1
    }

    # Check if source is tracked by git
    git -C $RepoRoot ls-files --error-unmatch -- $f 2>$null | Out-Null
    $tracked = ($LASTEXITCODE -eq 0)

    if ($tracked) {
        $rmOut = git -C $RepoRoot rm -- $f 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Error "git rm '$f' failed`n$rmOut"
            Remove-Item -Path $backup -Force -ErrorAction SilentlyContinue
            Rollback
            exit 1
        }
    } else {
        try {
            Remove-Item -Path $fullPath -Force
        } catch {
            Write-Error "rm '$f' failed`n$_"
            Remove-Item -Path $backup -Force -ErrorAction SilentlyContinue
            Rollback
            exit 1
        }
    }

    $doneFiles += $f
    $doneTracked += $tracked
    $doneBackups += $backup
}

Cleanup-Backups

Write-Host "Deleted $($doneFiles.Count) file(s):"
for ($i = 0; $i -lt $doneFiles.Count; $i++) {
    if ($doneTracked[$i]) {
        Write-Host "  $($doneFiles[$i])"
    } else {
        Write-Host "  $($doneFiles[$i])  (untracked, removed from disk only)"
    }
}

Write-Host "# next: $PSScriptRoot\stage-n-commit.ps1 $RepoRoot `"<msg>`" $($doneFiles -join ' ')"
