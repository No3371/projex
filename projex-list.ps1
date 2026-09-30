# Read-only listing of projex documents, newest first: one block per document (path, then
# state/type/created/status lines), blocks separated by an empty line.
# Missing fields print "?". Active only unless folder toggles are given.
param(
    [string]$RepoRoot,
    [switch]$Closed,
    [switch]$Archived,
    [switch]$Abandoned,
    [switch]$All
)
$ErrorActionPreference = 'Stop'
if ($args.Count -gt 0 -or -not $RepoRoot) {
    [Console]::Error.WriteLine('projex-list: E_USAGE: invocation: expected <repo-root> [-Closed] [-Archived] [-Abandoned] [-All]')
    exit 2
}
if (-not (Test-Path -LiteralPath $RepoRoot -PathType Container)) {
    [Console]::Error.WriteLine("projex-list: E_REPO: ${RepoRoot}: repository root not found")
    exit 2
}
$Root = (Resolve-Path -LiteralPath $RepoRoot).ProviderPath.TrimEnd('\', '/')
$States = @('active')
if ($Closed) { $States += 'closed' }
if ($Archived) { $States += 'archived' }
if ($Abandoned) { $States += 'abandoned' }

function IsRepo([string]$Dir) { Test-Path -LiteralPath (Join-Path $Dir '.git') }

# .projex roots, never entering .git, .projexwt, or nested repositories
function FindRoots([string]$Dir) {
    foreach ($Sub in [IO.Directory]::GetDirectories($Dir)) {
        $Name = [IO.Path]::GetFileName($Sub)
        if ($Name -ceq '.git' -or $Name -ceq '.projexwt' -or (IsRepo $Sub)) { continue }
        if ($Name -ceq '.projex') { $Sub; continue }
        FindRoots $Sub
    }
}
function FindDocs([string]$Dir) {
    foreach ($File in [IO.Directory]::GetFiles($Dir, '*.md')) { $File }
    foreach ($Sub in [IO.Directory]::GetDirectories($Dir)) {
        $Name = [IO.Path]::GetFileName($Sub)
        if ($Name -ceq '.git' -or $Name -ceq '.projexwt' -or (IsRepo $Sub)) { continue }
        FindDocs $Sub
    }
}
function ReadStatus([string]$Path) {
    try { $Text = [IO.File]::ReadAllText($Path, [Text.UTF8Encoding]::new($false)) } catch { return '?' }
    $Started = $false
    $Index = 0
    foreach ($Line in ($Text.TrimStart([char]0xFEFF) -split "\r\n|\n|\r")) {
        if ($Index++ -eq 0 -and $Line.StartsWith('#')) { $Started = $true; continue }
        if ($Line.Trim() -ceq '---') { break }
        if ($Line.StartsWith('> ')) {
            $Started = $true
            if ($Line.StartsWith('> **Status:**')) {
                $Status = $Line.Substring(13).Trim()
                if (-not $Status) { return '?' }
                return $Status.Replace("`t", ' ')
            }
            continue
        }
        if ($Line.Trim() -eq '') { continue }
        if ($Started) { break }
    }
    return '?'
}

$Rows = [Collections.Generic.List[object]]::new()
foreach ($ProjexRoot in FindRoots $Root) {
    foreach ($Path in FindDocs $ProjexRoot) {
        $Sub = $Path.Substring($ProjexRoot.Length + 1).Replace('\', '/')
        $State = if ($Sub.Contains('/')) { $Sub.Substring(0, $Sub.IndexOf('/')) } else { 'active' }
        if (-not $All -and $States -notcontains $State) { continue }
        $Name = [IO.Path]::GetFileName($Path)
        if ($Name -cmatch '^([0-9]{10})-[a-z0-9][a-z0-9-]*-([a-z0-9]+)\.md$') {
            $Stamp = $Matches[1]; $Kind = $Matches[2]
            $Created = "20$($Stamp.Substring(0, 2))-$($Stamp.Substring(2, 2))-$($Stamp.Substring(4, 2)) $($Stamp.Substring(6, 2)):$($Stamp.Substring(8, 2))"
        } else {
            $Stamp = ''; $Kind = '?'; $Created = '?'
        }
        $Rel = $Path.Substring($Root.Length + 1).Replace('\', '/')
        $Rows.Add([pscustomobject]@{ Stamp = $Stamp; Rel = $Rel; State = $State; Kind = $Kind; Created = $Created; Status = (ReadStatus $Path) })
    }
}
# newest first; undated files last, by path
$Rows.Sort([Comparison[object]] {
    param($A, $B)
    $C = [string]::CompareOrdinal($B.Stamp, $A.Stamp)
    if ($C -ne 0) { return $C }
    return [string]::CompareOrdinal($A.Rel, $B.Rel)
})
$Blocks = foreach ($Row in $Rows) {
    "$($Row.Rel)`nstate: $($Row.State)`ntype: $($Row.Kind)`ncreated: $($Row.Created)`nstatus: $($Row.Status)`n"
}
$Out = [Text.StringBuilder]::new(($Blocks -join "`n"))
$Bytes = [Text.UTF8Encoding]::new($false).GetBytes($Out.ToString())
$Stdout = [Console]::OpenStandardOutput()
$Stdout.Write($Bytes, 0, $Bytes.Length)
$Stdout.Flush()
exit 0
