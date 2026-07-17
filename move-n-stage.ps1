# move-n-stage.ps1 — Batch git mv with rollback on failure
# Usage: move-n-stage.ps1 <repo-root> src1 dst1 [src2 dst2 ...]
#
# Moves each source to its destination and stages the result.
# Uses git mv for tracked files; plain mv + git add for untracked files.
# Does NOT commit. On failure, rolls back all completed moves in reverse order.

param(
    [Parameter(Mandatory)][string]$RepoRoot,
    [Parameter(Mandatory, ValueFromRemainingArguments)][string[]]$Paths
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

# Validate pairs
if ($Paths.Count % 2 -ne 0) {
    Write-Error "Arguments must be src/dst pairs (got odd count: $($Paths.Count))"
    exit 1
}

# Validate all src/dst paths belong to this repo
foreach ($p in $Paths) {
    $checkDir = Join-Path $RepoRoot $p
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
        $msg = "'$p' belongs to a different repo than '$RepoRoot'."
        if ($fileToplevel) { $msg += "`n  File's repo root: $fileToplevel" }
        $msg += "`n  Expected repo root: $Toplevel"
        $msg += "`n  Verify the <repo-root> argument matches the repository containing these files."
        Write-Error $msg
        exit 1
    }
}

# Track completed moves for rollback (actual resolved paths)
$doneSrc = @()
$doneDst = @()
$doneTracked = @()

function Rollback {
    if ($script:doneSrc.Count -eq 0) { return }
    Write-Host "Rolling back $($script:doneSrc.Count) completed move(s)..."
    $failed = $false
    # Physically move every completed move back on disk (both tracked and untracked).
    # The index is restored wholesale from the pre-batch snapshot afterwards, so no
    # per-file git commands are used here — git mv would re-stage and lose the original
    # staged/unstaged split.
    for ($i = $script:doneSrc.Count - 1; $i -ge 0; $i--) {
        $fullDst = Join-Path $RepoRoot $script:doneDst[$i]
        $fullSrc = Join-Path $RepoRoot $script:doneSrc[$i]
        try {
            $srcDir = Split-Path $fullSrc -Parent
            if (!(Test-Path $srcDir)) { New-Item -ItemType Directory -Path $srcDir -Force | Out-Null }
            Move-Item -Path $fullDst -Destination $fullSrc -Force
        } catch {
            Write-Host "  Warning: could not reverse '$($script:doneDst[$i])' -> '$($script:doneSrc[$i])'"
            Write-Host "  $_"
            $failed = $true
        }
    }
    # Restore the entire index to its pre-batch snapshot (index only — no -u, so the
    # working tree is untouched). Undoes all staging done by the forward moves.
    git -C $RepoRoot read-tree $script:indexTree 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  Warning: could not restore index from pre-batch snapshot"
        $failed = $true
    }
    if ($failed) {
        Write-Host "Rollback incomplete — manual intervention required."
    } else {
        Write-Host "Rollback complete."
    }
}

# Snapshot the whole index once for rollback (restored wholesale on failure so the
# original staged/unstaged split of each moved file is preserved)
$indexTree = git -C $RepoRoot write-tree
if ($LASTEXITCODE -ne 0) {
    Write-Error "git write-tree failed — cannot snapshot index"
    exit 1
}

# Execute moves
for ($i = 0; $i -lt $Paths.Count; $i += 2) {
    $src = $Paths[$i]
    $dst = $Paths[$i + 1]

    # Check if source is tracked by git
    git -C $RepoRoot ls-files --error-unmatch -- $src 2>$null | Out-Null
    $tracked = ($LASTEXITCODE -eq 0)

    if ($tracked) {
        $mvOut = git -C $RepoRoot mv -- $src $dst 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Error "git mv '$src' '$dst' failed`n$mvOut"
            Rollback
            exit 1
        }
    } else {
        # Untracked file: ensure destination directory exists, move via filesystem, then stage
        $fullSrc = Join-Path $RepoRoot $src
        $fullDstPath = Join-Path $RepoRoot $dst
        if (!(Test-Path $fullDstPath -PathType Container)) {
            $dstDir = Split-Path $fullDstPath -Parent
            if (!(Test-Path $dstDir)) { New-Item -ItemType Directory -Path $dstDir -Force | Out-Null }
        }
        try {
            Move-Item -Path $fullSrc -Destination $fullDstPath -Force
        } catch {
            Write-Error "mv '$src' '$dst' failed`n$_"
            Rollback
            exit 1
        }
        # Resolve actual destination before staging
        if (Test-Path $fullDstPath -PathType Container) {
            $stagePath = "$dst/$([System.IO.Path]::GetFileName($src))"
        } else {
            $stagePath = $dst
        }
        $addOut = git -C $RepoRoot add -- $stagePath 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Error "git add '$stagePath' failed`n$addOut"
            Rollback
            exit 1
        }
    }

    # Resolve actual destination — git mv into a directory lands at dst/basename(src)
    $fullDst = Join-Path $RepoRoot $dst
    if (Test-Path $fullDst -PathType Container) {
        $doneDst += "$dst/$([System.IO.Path]::GetFileName($src))"
    } else {
        $doneDst += $dst
    }
    $doneSrc += $src
    $doneTracked += $tracked
}

Write-Host "Moved $($doneSrc.Count) file(s):"
for ($i = 0; $i -lt $doneSrc.Count; $i++) {
    Write-Host "  $($doneSrc[$i]) -> $($doneDst[$i])"
}

Write-Host "# next: $PSScriptRoot\stage-n-commit.ps1 $RepoRoot `"<msg>`" $($doneDst -join ' ')"
