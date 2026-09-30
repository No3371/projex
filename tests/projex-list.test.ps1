$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$List = Join-Path $Root 'projex-list.ps1'
$Fixture = Join-Path $Root 'tests/fixtures/projex-list/basic'
$Temp = Join-Path ([IO.Path]::GetTempPath()) ('projex-list-' + [guid]::NewGuid())
$Repo = Join-Path $Temp 'repo'
New-Item -ItemType Directory -Path $Repo -Force | Out-Null
Copy-Item -Path (Join-Path $Fixture '*') -Destination $Repo -Recurse -Force
Copy-Item -Path (Join-Path $Fixture '.projex') -Destination $Repo -Recurse -Force
Remove-Item -Path (Join-Path $Repo 'expected-*.stdout')
try {
    $Pass = 0; $Fail = 0; $Cases = 0
    function Check([scriptblock]$Condition, [string]$Label) { $script:Cases++; if (& $Condition) { $script:Pass++ } else { $script:Fail++; [Console]::Error.WriteLine("FAIL: $Label") } }
    function CheckEq([string]$Expected, [string]$Actual) { $script:Cases++; if ($Expected -ceq $Actual) { $script:Pass++ } else { $script:Fail++; [Console]::Error.WriteLine("FAIL: expected '$Expected', got '$Actual'") } }
    $Out = Join-Path $Temp 'out'; $Err = Join-Path $Temp 'err'
    function RunGolden([string]$Golden, [string[]]$Flags) {
        & pwsh -NoProfile -File $List $Repo @Flags 1>$Out 2>$Err
        CheckEq '0' ([string]$LASTEXITCODE)
        Check { (Get-FileHash $Out).Hash -eq (Get-FileHash (Join-Path $Fixture $Golden)).Hash } "stdout $Golden $Flags"
        Check { (Get-Item $Err).Length -eq 0 } "stderr $Golden $Flags"
    }
    function RunUsage([string[]]$Argv) {
        & pwsh -NoProfile -File $List @Argv 1>$Out 2>$Err
        CheckEq '2' ([string]$LASTEXITCODE)
        Check { (Get-Item $Out).Length -eq 0 } "empty stdout $Argv"
        Check { (Get-Content -LiteralPath $Err -Raw).Contains('projex-list: E_USAGE:') } "usage $Argv"
    }

    # nested repos and worktrees are never walked
    New-Item -ItemType Directory -Force -Path (Join-Path $Repo 'nested/.git'), (Join-Path $Repo 'nested/.projex'), (Join-Path $Repo '.projexwt/wt/.projex') | Out-Null
    Set-Content -LiteralPath (Join-Path $Repo 'nested/.projex/2609090000-nested-plan.md') -Value "# N`n`n> **Status:** Draft`n" -NoNewline
    Set-Content -LiteralPath (Join-Path $Repo '.projexwt/wt/.projex/2609090001-worktree-plan.md') -Value "# W`n`n> **Status:** Draft`n" -NoNewline

    RunGolden 'expected-default.stdout' @()
    RunGolden 'expected-closed-abandoned.stdout' @('-Closed', '-Abandoned')
    RunGolden 'expected-closed-abandoned.stdout' @('-Abandoned', '-Closed')
    RunGolden 'expected-all.stdout' @('-All')
    RunGolden 'expected-all.stdout' @('-Closed', '-All')

    RunUsage @()
    RunUsage @('-All')
    RunUsage @($Repo, 'extra')
    RunUsage @($Repo, '-Bogus')
    & pwsh -NoProfile -File $List (Join-Path $Temp 'missing') 1>$Out 2>$Err
    CheckEq '2' ([string]$LASTEXITCODE)
    Check { (Get-Content -LiteralPath $Err -Raw).Contains('projex-list: E_REPO:') } 'missing repo'

    # BOM + CRLF header still parses
    $Bom = Join-Path $Temp 'bom'
    New-Item -ItemType Directory -Force -Path (Join-Path $Bom '.projex') | Out-Null
    [IO.File]::WriteAllBytes((Join-Path $Bom '.projex/2609000005-bom-plan.md'), [byte[]](0xEF, 0xBB, 0xBF) + [Text.Encoding]::UTF8.GetBytes("# BOM`r`n`r`n> **Status:** In Progress`r`n---`r`n"))
    & pwsh -NoProfile -File $List $Bom 1>$Out 2>$Err
    CheckEq '0' ([string]$LASTEXITCODE)
    CheckEq 'status: In Progress' (Get-Content -LiteralPath $Out)[4]

    # empty corpus prints nothing
    $Empty = Join-Path $Temp 'empty'
    New-Item -ItemType Directory -Force -Path $Empty | Out-Null
    & pwsh -NoProfile -File $List $Empty 1>$Out 2>$Err
    CheckEq '0' ([string]$LASTEXITCODE)
    Check { (Get-Item $Out).Length -eq 0 } 'empty corpus'

    Write-Host "PASS=$Pass FAIL=$Fail"
    if ($Fail -gt 0) { exit 1 }
    exit 0
} finally {
    Remove-Item -LiteralPath $Temp -Recurse -Force -ErrorAction SilentlyContinue
}
