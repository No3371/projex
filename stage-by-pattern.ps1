# stage-by-pattern.ps1 — Stage only diff lines whose content matches a regex
# Usage: stage-by-pattern.ps1 <repo-root> <pattern> [-v] [-n] [-- file1 file2 ...]
#
# Filters unstaged changes through a pattern and stages only matching +/- lines.
# Useful for structured changes like renames or method signature updates where
# the diff is highly regular and describable with a precise regex.
#
# -v inverts (stage lines NOT matching). -n dry-runs (prints filtered diff).
#
# Pattern uses .NET regex syntax and is matched against the content of changed
# lines (without the +/- prefix). Context lines are never filtered.
#
# For replacement pairs (-old / +new), the pattern should match BOTH sides.
# E.g. renaming getFoo->getBar: use 'getFoo|getBar', not just 'getBar'.

param(
    [Parameter(Mandatory)][string]$RepoRoot,
    [Parameter(Mandatory)][string]$Pattern,
    [Parameter(ValueFromRemainingArguments)][string[]]$RemainingArgs
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

# Snapshot staging area state — verification only runs when staging was clean
git -C $RepoRoot diff --cached --quiet 2>$null
$cleanStage = ($LASTEXITCODE -eq 0)

# Parse options and files
$Invert = $false
$DryRun = $false
$Files = @()
$pastSeparator = $false

foreach ($arg in $RemainingArgs) {
    if ($pastSeparator) { $Files += $arg; continue }
    switch ($arg) {
        '-v'  { $Invert = $true }
        '-n'  { $DryRun = $true }
        '--'  { $pastSeparator = $true }
        default { $Files += $arg }
    }
}

# Validate file paths belong to this repo
if ($Files.Count -gt 0) {
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
}

# Capture unstaged diff
if ($Files.Count -gt 0) {
    $diff = git -C $RepoRoot diff -- @Files
} else {
    $diff = git -C $RepoRoot diff
}
if ($LASTEXITCODE -ne 0) {
    Write-Error "git diff failed"
    exit 1
}

if (-not $diff) {
    Write-Host "No unstaged changes."
    exit 0
}

$diffLines = $diff -split "`n"
$regex = [regex]::new($Pattern)

# State
$fileBuf = ""
$fileHasOut = $false
$inHunk = $false
$adj = 0
$lastDropped = $false
# Use explicit LF throughout — git apply requires LF, not CRLF
$output = [System.Text.StringBuilder]::new()

function Test-Want([string]$text) {
    $m = $regex.IsMatch($text)
    if ($Invert) { return -not $m } else { return $m }
}

function Flush-Hunk {
    if (-not $script:inHunk) { return }
    $script:inHunk = $false

    $oc = 0; $nc = 0; $has = $false
    foreach ($e in $script:hunkEntries) {
        switch ($e.Type) {
            'c' { $oc++; $nc++ }
            'd' { $oc++; $has = $true }
            'a' { $nc++; $has = $true }
        }
    }

    if (-not $has) {
        $script:adj += $script:origAdd - $script:origDel
        $script:hunkEntries = @()
        return
    }

    if (-not $script:fileHasOut -and $script:fileBuf) {
        [void]$script:output.Append($script:fileBuf)
        $script:fileHasOut = $true
    }

    $adjustedNew = $script:curNewStart - $script:adj
    [void]$script:output.Append("@@ -$($script:curOldStart),$oc +$adjustedNew,$nc @@$($script:curSuffix)`n")

    $fn = 0
    foreach ($e in $script:hunkEntries) {
        if ($e.Type -eq 'a') { $fn++ }
        if ($e.Type -eq 'd') { $fn-- }
    }
    $script:adj += ($script:origAdd - $script:origDel) - $fn

    foreach ($e in $script:hunkEntries) {
        [void]$script:output.Append("$($e.Line)`n")
    }
    $script:hunkEntries = @()
}

function Emit-File {
    $script:fileBuf = ""
    $script:adj = 0
}

$hunkEntries = @()
$origAdd = 0; $origDel = 0
$curOldStart = 0; $curNewStart = 0; $curSuffix = ""

foreach ($line in $diffLines) {
    # Strip trailing CR if present (git may output CRLF on Windows)
    $line = $line.TrimEnd("`r")

    # Hunk body MUST be checked first — prevents file-header patterns from
    # matching content inside hunks (e.g. a line starting with "+index ...")
    if ($inHunk) {
        $ch = if ($line.Length -gt 0) { $line[0] } else { $null }

        # Context line (or empty line from whitespace-stripped context)
        if ($ch -eq ' ' -or $null -eq $ch) {
            $hunkEntries += @{ Line = $line; Type = 'c' }
            $lastDropped = $false
        }
        elseif ($ch -eq '-') {
            $origDel++
            $content = $line.Substring(1)
            if (Test-Want $content) {
                $hunkEntries += @{ Line = $line; Type = 'd' }
            } else {
                $hunkEntries += @{ Line = " $content"; Type = 'c' }
            }
            $lastDropped = $false
        }
        elseif ($ch -eq '+') {
            $origAdd++
            $content = $line.Substring(1)
            if (Test-Want $content) {
                $hunkEntries += @{ Line = $line; Type = 'a' }
                $lastDropped = $false
            } else {
                $lastDropped = $true
            }
        }
        elseif ($line -match '^\\ ') {
            # "\ No newline at end of file" — belongs to the preceding line.
            # If that line was dropped, this must be dropped too.
            if (-not $lastDropped) {
                $hunkEntries += @{ Line = $line; Type = 'm' }
            }
            # Do not reset lastDropped: meta line is not a real content line
        }
        continue
    }

    # File header
    if ($line -match '^diff --git ') {
        Flush-Hunk
        Emit-File
        $fileBuf = "$line`n"
        $fileHasOut = $false
        continue
    }
    if ($line -match '^(index |old mode|new mode|new file|deleted file|similarity|rename |copy |Binary|---|\+\+\+)') {
        $fileBuf += "$line`n"
        continue
    }

    # Hunk header
    if ($line -match '^@@ -(\d+)(?:,\d+)? \+(\d+)(?:,\d+)? @@(.*)$') {
        Flush-Hunk
        $inHunk = $true
        $hunkEntries = @()
        $origAdd = 0; $origDel = 0
        $lastDropped = $false
        $curOldStart = [int]$Matches[1]
        $curNewStart = [int]$Matches[2]
        $curSuffix = $Matches[3]
        continue
    }

    [void]$output.Append("$line`n")
}

Flush-Hunk
Emit-File

$filtered = $output.ToString().TrimEnd("`n")

if (-not $filtered) {
    Write-Host "No changes match the pattern."
    exit 0
}

if ($DryRun) {
    Write-Host $filtered
    exit 0
}

# Write to temp file with LF line endings for git apply
$tmpFile = [System.IO.Path]::GetTempFileName()
try {
    # Ensure LF-only and UTF-8 no BOM
    $bytes = [System.Text.UTF8Encoding]::new($false).GetBytes($filtered + "`n")
    [System.IO.File]::WriteAllBytes($tmpFile, $bytes)

    $applyOut = git -C $RepoRoot apply --cached $tmpFile 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Error "git apply --cached failed`n$applyOut"
        exit 1
    }
} finally {
    Remove-Item $tmpFile -ErrorAction SilentlyContinue
}

# Verify: when staging was clean before, every staged +/- line must match the pattern.
# If any line doesn't, the filtering logic produced an incorrect diff — rollback.
if ($cleanStage) {
    $stagedDiff = git -C $RepoRoot diff --cached
    $ih = $false
    $badLines = @()
    foreach ($vline in ($stagedDiff -split "`n")) {
        $vline = $vline.TrimEnd("`r")
        if ($vline -match '^@@ ')        { $ih = $true;  continue }
        if ($vline -match '^diff --git ') { $ih = $false; continue }
        if ($ih -and $vline.Length -gt 0 -and ($vline[0] -eq '+' -or $vline[0] -eq '-')) {
            $content = $vline.Substring(1)
            $m = $regex.IsMatch($content)
            $keep = if ($Invert) { -not $m } else { $m }
            if (-not $keep) { $badLines += $vline }
        }
    }
    if ($badLines.Count -gt 0) {
        Write-Error "Verification failed — staged diff contains lines not matching the pattern:"
        $badLines | ForEach-Object { Write-Host "  $_" }
        git -C $RepoRoot reset HEAD 2>$null | Out-Null
        Write-Host "Rolled back — staging area restored to clean state."
        exit 1
    }
}

$count = ($filtered -split "`n" | Where-Object { $_ -match '^diff --git ' }).Count
Write-Host "Staged filtered changes in $count file(s):"
$stagedFiles = @()
$filtered -split "`n" | Where-Object { $_ -match '^diff --git a/(.+) b/' } | ForEach-Object {
    Write-Host "  $($Matches[1])"
    $stagedFiles += $Matches[1]
}
Write-Host "# next: $PSScriptRoot\stage-n-commit.ps1 $RepoRoot `"<msg>`" $($stagedFiles -join ' ')"
