# move-n-stage.ps1 — Batch git mv with rollback on failure
# Usage: move-n-stage.ps1 <repo-root> src1 dst1 [src2 dst2 ...]
#
# Moves each source to its destination via git mv (stages automatically).
# Does NOT commit. On failure, rolls back all completed moves in reverse order.

param(
    [Parameter(Mandatory)][string]$RepoRoot,
    [Parameter(Mandatory, ValueFromRemainingArguments)][string[]]$Paths
)

# Validate repo
git -C $RepoRoot rev-parse --git-dir 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Error "'$RepoRoot' is not a git repository"
    exit 1
}

# Validate pairs
if ($Paths.Count % 2 -ne 0) {
    Write-Error "Arguments must be src/dst pairs (got odd count: $($Paths.Count))"
    exit 1
}

# Track completed moves for rollback (actual resolved paths)
$doneSrc = @()
$doneDst = @()

function Rollback {
    if ($script:doneSrc.Count -eq 0) { return }
    Write-Host "Rolling back $($script:doneSrc.Count) completed move(s)..."
    $failed = $false
    for ($i = $script:doneSrc.Count - 1; $i -ge 0; $i--) {
        $rbOut = git -C $RepoRoot mv -- $script:doneDst[$i] $script:doneSrc[$i] 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Host "  Warning: could not reverse '$($script:doneDst[$i])' -> '$($script:doneSrc[$i])'"
            Write-Host "  $rbOut"
            $failed = $true
        }
    }
    if ($failed) {
        Write-Host "Rollback incomplete — manual intervention required."
    } else {
        Write-Host "Rollback complete."
    }
}

# Execute moves
for ($i = 0; $i -lt $Paths.Count; $i += 2) {
    $src = $Paths[$i]
    $dst = $Paths[$i + 1]

    $mvOut = git -C $RepoRoot mv -- $src $dst 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Error "git mv '$src' '$dst' failed`n$mvOut"
        Rollback
        exit 1
    }

    # Resolve actual destination — git mv into a directory lands at dst/basename(src)
    $fullDst = Join-Path $RepoRoot $dst
    if (Test-Path $fullDst -PathType Container) {
        $doneDst += "$dst/$([System.IO.Path]::GetFileName($src))"
    } else {
        $doneDst += $dst
    }
    $doneSrc += $src
}

Write-Host "Moved $($doneSrc.Count) file(s):"
for ($i = 0; $i -lt $doneSrc.Count; $i++) {
    Write-Host "  $($doneSrc[$i]) -> $($doneDst[$i])"
}
