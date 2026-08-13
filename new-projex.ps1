# new-projex.ps1 — Scaffold a new projex file with minimal common header
# Usage: new-projex.ps1 <repo-root> <type> <title> <parent> [<projex-dir>]
#   <parent>: User|Orchestrator|{yymmddhhmm}-{name}-{type}.md
#   <projex-dir>: defaults to ".projex" (relative to repo-root)
# Prints the created file's path on success.

[CmdletBinding()]
param(
    [Parameter(Mandatory, Position = 0)][string]$RepoRoot,
    [Parameter(Mandatory, Position = 1)][string]$Type,
    [Parameter(Mandatory, Position = 2)][string]$Title,
    [Parameter(Mandatory, Position = 3)][string]$Parent,
    [Parameter(Position = 4)][string]$ProjexDir = ".projex"
)

$ErrorActionPreference = 'Stop'

function Fail([string]$Message, [int]$Code = 2) {
    [Console]::Error.WriteLine($Message)
    exit $Code
}

$Sep = [IO.Path]::DirectorySeparatorChar
$RepoRoot = ($RepoRoot -replace '/', $Sep).TrimEnd($Sep)
$ProjexDir = (($ProjexDir -replace '\\', '/') -replace '/+', '/').Trim('/')
if (-not $RepoRoot) { Fail 'repo-root required' }
if (-not $Title) { Fail 'title required' }
if (-not $Parent) { Fail 'parent required' }
if (-not $ProjexDir) { $ProjexDir = '.projex' }
if (-not (Test-Path -LiteralPath $RepoRoot -PathType Container)) { Fail "Repository root not found: $RepoRoot" }

$TypeInfo = @{
    propose   = @('Proposal', 'proposal');   plan      = @('Plan', 'plan')
    eval      = @('Evaluation', 'eval');      review    = @('Review', 'review')
    redteam   = @('Red Team', 'redteam');     stress    = @('Stress', 'stress')
    audit     = @('Audit', 'audit')
    interview = @('Interview', 'interview');  coach     = @('Coach', 'coach')
    log       = @('Log', 'log')
    memo      = @('Memo', 'memo');            patch     = @('Patch', 'patch')
    preplan   = @('Preplan', 'preplan');       debug    = @('Debug', 'debug')
    define    = @('Definition', 'def');       navigate  = @('Navigation', 'nav')
    map       = @('Map', 'map');              scan      = @('Scan', 'scan')
    explore   = @('Exploration', 'explore');  guide     = @('Guide', 'guide')
    imagine   = @('Imagination', 'imagine');  archive   = @('Archive', 'archive')
    conclude  = @('Conclude', 'conclude')
}
if (-not $TypeInfo.ContainsKey($Type)) { Fail "Unknown type '$Type'. Valid: $($TypeInfo.Keys -join ' ')" }

$ParentPattern = '^[0-9]{10}-[a-z0-9][a-z0-9-]*-[a-z0-9][a-z0-9-]*\.md$'
if (($Parent -ne 'User') -and ($Parent -ne 'Orchestrator') -and ($Parent -notmatch $ParentPattern)) {
    Fail "Invalid parent: $Parent (expected User, Orchestrator, or a projex filename)"
}

function Get-ProjexRoots([string]$Root) {
    $stack = [Collections.Generic.Stack[string]]::new()
    $stack.Push((Resolve-Path -LiteralPath $Root).Path)
    $roots = [Collections.Generic.List[string]]::new()
    while ($stack.Count -gt 0) {
        $current = $stack.Pop()
        try { $children = @(Get-ChildItem -LiteralPath $current -Directory -Force -ErrorAction Stop) } catch { Fail "Unable to inspect repository: $current" 4 }
        foreach ($child in $children) {
            if ($child.Name -in @('.git', '.projexwt')) { continue }
            if (($child.FullName -ne (Resolve-Path -LiteralPath $Root).Path) -and (Test-Path -LiteralPath (Join-Path $child.FullName '.git') -PathType Container)) { continue }
            if ($child.Name -eq '.projex') { $roots.Add($child.FullName) }
            $stack.Push($child.FullName)
        }
    }
    return $roots
}

$BornClosed = @('log', 'archive', 'patch', 'preplan', 'scan', 'guide', 'conclude')
$IsBornClosed = $BornClosed -contains $Type
$Status = if ($IsBornClosed) { 'Closed' } else { 'Draft' }
$RelDir = if ($IsBornClosed) { "$ProjexDir/closed" } else { $ProjexDir }
$Dir = Join-Path $RepoRoot ($RelDir -replace '/', $Sep)

$Slug = ($Title.ToLowerInvariant() -replace '[^a-z0-9]+', '-').Trim('-')
if (-not $Slug) { Fail 'Title produces an empty slug' }
$Suffix = $TypeInfo[$Type][1]
$Stamp = Get-Date -Format 'yyMMddHHmm'
$FileName = "$Stamp-$Slug-$Suffix.md"
if ($Parent -eq $FileName) { Fail "Parent cannot equal generated filename: $FileName" }
$Path = Join-Path $Dir $FileName

foreach ($ProjexRoot in (Get-ProjexRoots $RepoRoot)) {
    try {
        $collision = @(Get-ChildItem -LiteralPath $ProjexRoot -File -Filter '*.md' -Recurse -Force -ErrorAction Stop | Where-Object {
            $_.Name -eq $FileName -and $_.FullName -notmatch '[\\/]\.git[\\/]' -and $_.FullName -notmatch '[\\/]\.projexwt[\\/]'
        } | Select-Object -First 1)
    } catch { Fail "Unable to inspect repository: $ProjexRoot" 4 }
    if ($collision.Count -gt 0) { Fail "Filename collision: $FileName already discovered at $($collision[0].FullName)" }
}

New-Item -ItemType Directory -Path $Dir -Force | Out-Null
$Content = @"
# $Title

> **Status:** $Status
> **Author:** [name or agent]
> **Parent:** $Parent
> **Related Projex:** [none yet]

---
"@
try {
    [IO.File]::WriteAllText($Path, $Content, [Text.UTF8Encoding]::new($false))
} catch { Fail "Failed to create file: $Path — $_" 1 }
if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { Fail "Failed to create file: $Path" 1 }

$RelPath = "$RelDir/$FileName"
Write-Output $Path
Write-Output "# next: scaffold contains header only — update the format, structure and content per $Type-projex.md"
Write-Output "# commit: $PSScriptRoot$Sep`stage-n-commit.ps1 $RepoRoot `"projex($Type): add $Slug`" $RelPath"
