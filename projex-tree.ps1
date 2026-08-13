[CmdletBinding()]
param(
    [Parameter(Position = 0)][string]$RepoRoot,
    [Parameter(Position = 1)][string]$Filename
)
$ErrorActionPreference = 'Stop'
if ($args.Count -gt 0 -or $null -eq $RepoRoot -or $null -eq $Filename -or -not $RepoRoot -or -not $Filename) {
    [Console]::Error.WriteLine('projex-tree: E_USAGE: invocation: expected <repo-root> <filename>')
    exit 2
}
$Python = (Get-Command python3 -ErrorAction SilentlyContinue).Source
if (-not $Python) { $Python = (Get-Command python -ErrorAction SilentlyContinue).Source }
if (-not $Python) {
    [Console]::Error.WriteLine('projex-tree: E_IO: runtime: Python interpreter not found')
    exit 4
}
$Engine = Join-Path $PSScriptRoot '.projex-tree.py'
& $Python $Engine $RepoRoot $Filename
exit $LASTEXITCODE
