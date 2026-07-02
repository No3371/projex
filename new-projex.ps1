# new-projex.ps1 — Scaffold a new projex file with minimal common header
# Usage: new-projex.ps1 <repo-root> <type> <title> [<projex-dir>]
#   <type>: propose|plan|eval|review|redteam|audit|interview|log|memo|patch|
#           simulate|debug|define|navigate|map|scan|explore|guide|imagine|archive
#   <projex-dir>: defaults to ".projex" (relative to repo-root)
# Prints the created file's path on success.

param(
    [Parameter(Mandatory)][string]$RepoRoot,
    [Parameter(Mandatory)][string]$Type,
    [Parameter(Mandatory)][string]$Title,
    [string]$ProjexDir = ".projex"
)

# type -> @(DisplayName, filename suffix). Suffix is authoritative per each *-projex.md spec
# and does NOT always match the type key (e.g. propose->proposal, simulate->simulation,
# define->def, navigate->nav).
$TypeInfo = @{
    propose   = @("Proposal", "proposal");   plan      = @("Plan", "plan")
    eval      = @("Evaluation", "eval");      review    = @("Review", "review")
    redteam   = @("Red Team", "redteam");     audit     = @("Audit", "audit")
    interview = @("Interview", "interview");  log       = @("Log", "log")
    memo      = @("Memo", "memo");            patch     = @("Patch", "patch")
    simulate  = @("Simulation", "simulation"); debug    = @("Debug", "debug")
    define    = @("Definition", "def");       navigate  = @("Navigation", "nav")
    map       = @("Map", "map");              scan      = @("Scan", "scan")
    explore   = @("Exploration", "explore");  guide     = @("Guide", "guide")
    imagine   = @("Imagination", "imagine");  archive   = @("Archive", "archive")
}

if (-not $TypeInfo.ContainsKey($Type)) {
    Write-Error "Unknown type '$Type'. Valid: $($TypeInfo.Keys -join ', ')"
    exit 1
}

$BornClosed = @('log', 'archive', 'patch', 'simulate', 'scan', 'guide')
$IsBornClosed = $BornClosed -contains $Type

$Dir = if ($IsBornClosed) {
    Join-Path $RepoRoot $ProjexDir "closed"
} else {
    Join-Path $RepoRoot $ProjexDir
}
if (-not (Test-Path $Dir)) {
    New-Item -ItemType Directory -Path $Dir -Force | Out-Null
}

$Slug = ($Title.ToLower() -replace '[^a-z0-9]+', '-').Trim('-')
if (-not $Slug) {
    Write-Error "Title produces an empty slug"
    exit 1
}

$Suffix = $TypeInfo[$Type][1]
$Status = if ($IsBornClosed) { 'Closed' } else { 'Draft' }

$Stamp = Get-Date -Format "yyMMddHHmm"
$FileName = "$Stamp-$Slug-$Suffix.md"
$Path = Join-Path $Dir $FileName
$RelDir = if ($IsBornClosed) { "$ProjexDir/closed" } else { $ProjexDir }
$RelPath = "$RelDir/$FileName"

if (Test-Path $Path) {
    Write-Error "File already exists: $Path"
    exit 1
}

$Today = Get-Date -Format "yyyy-MM-dd"

$Content = @"
# $Title

> **Status:** $Status
> **Created:** $Today
> **Author:** [name or agent]
> **Related Projex:** [none yet]

---
"@

Set-Content -Path $Path -Value $Content -NoNewline
Write-Host $Path
Write-Host "# next: scaffold contains header only — update the format, structure and content per $Type-projex.md"
Write-Host "# commit: $PSScriptRoot\projex-commit.ps1 $RepoRoot `"projex($Type): add $Slug`" $RelPath"
