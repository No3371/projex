param (
    [Parameter(Mandatory = $true)]
    [string]$Path,

    [int]$From = 0,

    [int]$To = 0,

    [string[]]$Pattern,

    [int]$Context = 3
)

if (-not (Test-Path $Path)) {
    Write-Error "File not found: $Path"
    exit 1
}

# ---------- Resolve range ----------
$RangeStart = if ($From -gt 0) { $From } else { 1 }
$HasPattern = $Pattern -and $Pattern.Count -gt 0

# ---------- Read only what we need ----------
# With -To: read up to To lines (+ context buffer for pattern search)
# Without -To: must read entire file
if ($To -gt 0) {
    $ReadTo   = if ($HasPattern) { $To + $Context } else { $To }
    $AllLines = Get-Content $Path -TotalCount $ReadTo
} else {
    $AllLines = Get-Content $Path
}

$Total = $AllLines.Count

if ($Total -eq 0) {
    Write-Output "(empty file)"
    exit 0
}

$RangeEnd = if ($To -gt 0) { [Math]::Min($To, $Total) } else { $Total }

if ($RangeStart -gt $Total) {
    Write-Error "From ($RangeStart) exceeds total lines ($Total)"
    exit 1
}

# ---------- Line number formatting ----------
$Pad = "$RangeEnd".Length

# ---------- No patterns: dump lines in range ----------
if (-not $HasPattern) {
    for ($i = $RangeStart; $i -le $RangeEnd; $i++) {
        Write-Output "$("$i".PadLeft($Pad, '0'))  $($AllLines[$i - 1])"
    }
    exit 0
}

# ---------- Pattern search within range ----------
# Context lines may extend beyond RangeEnd up to what we read
$CtxFloor   = [Math]::Max(1, $RangeStart - $Context)
$CtxCeiling = [Math]::Min($Total, $RangeEnd + $Context)

$Hits = [System.Collections.Generic.SortedSet[int]]::new()

foreach ($pat in $Pattern) {
    for ($i = $RangeStart; $i -le $RangeEnd; $i++) {
        if ($AllLines[$i - 1] -match $pat) {
            $ctxStart = [Math]::Max($CtxFloor,   $i - $Context)
            $ctxEnd   = [Math]::Min($CtxCeiling, $i + $Context)
            for ($j = $ctxStart; $j -le $ctxEnd; $j++) {
                [void]$Hits.Add($j)
            }
        }
    }
}

if ($Hits.Count -eq 0) {
    Write-Output "(no matches)"
    exit 0
}

# ---------- Output with gap markers ----------
$Prev = 0
foreach ($ln in $Hits) {
    if ($Prev -ne 0 -and ($ln - $Prev) -gt 1) {
        Write-Output "---"
    }
    Write-Output "$("$ln".PadLeft($Pad, '0'))  $($AllLines[$ln - 1])"
    $Prev = $ln
}
