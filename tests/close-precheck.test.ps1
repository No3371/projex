# Independent PowerShell behavioural coverage for close-precheck.ps1.
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$ScriptRoot = Split-Path -Parent $PSScriptRoot
$Script = Join-Path $ScriptRoot 'close-precheck.ps1'
$TempRoot = Join-Path ([IO.Path]::GetTempPath()) ('close-precheck-test-' + [Guid]::NewGuid().ToString('N'))
$PassCount = 0
$FailCount = 0
$Repo = $null
$Child = $null

function Write-Fixture {
    param([string]$Path, [string]$Content)
    $parent = Split-Path -Parent $Path
    New-Item -ItemType Directory -Force -Path $parent | Out-Null
    [IO.File]::WriteAllText($Path, $Content)
}

function Invoke-GitFixture {
    param([string]$Directory, [string[]]$Arguments)
    $result = @(& git -C $Directory @Arguments 2>$null)
    if ($LASTEXITCODE -ne 0) { throw ('fixture git failed: ' + ($Arguments -join ' ')) }
    $result
}

function Assert-Equal {
    param([string]$Name, [object]$Got, [object]$Want)
    if ([string]$Got -eq [string]$Want) { $script:PassCount++ } else { Write-Host "FAIL: $Name (got=$Got want=$Want)"; $script:FailCount++ }
}

function Assert-Contains {
    param([string]$Name, [object[]]$Output, [string]$Needle)
    $text = $Output -join "`n"
    if ($text.IndexOf($Needle, [StringComparison]::Ordinal) -ge 0) { $script:PassCount++ } else { Write-Host "FAIL: $Name (missing $Needle)"; $script:FailCount++ }
}

function Assert-NotContains {
    param([string]$Name, [object[]]$Output, [string]$Needle)
    $text = $Output -join "`n"
    if ($text.IndexOf($Needle, [StringComparison]::Ordinal) -lt 0) { $script:PassCount++ } else { Write-Host "FAIL: $Name (unexpected $Needle)"; $script:FailCount++ }
}

function Assert-AtLeast {
    param([string]$Name, [int]$Got, [int]$Minimum)
    if ($Got -ge $Minimum) { $script:PassCount++ } else { Write-Host "FAIL: $Name (got=$Got minimum=$Minimum)"; $script:FailCount++ }
}

function Invoke-Precheck {
    param([string]$WorkingDirectory, [string]$Plan)
    Push-Location $WorkingDirectory
    try {
        $output = @(& $Script -PlanFile $Plan 2>$null)
        $code = $LASTEXITCODE
    } finally { Pop-Location }
    [pscustomobject]@{ Output = $output; Code = $code }
}

try {
    New-Item -ItemType Directory -Force -Path $TempRoot | Out-Null
    $Repo = Join-Path $TempRoot 'repo'
    New-Item -ItemType Directory -Force -Path $Repo | Out-Null
    Invoke-GitFixture $Repo @('init', '-q') | Out-Null
    Invoke-GitFixture $Repo @('checkout', '-q', '-b', 'main') | Out-Null
    Invoke-GitFixture $Repo @('config', 'user.email', 'fixture@example.invalid') | Out-Null
    Invoke-GitFixture $Repo @('config', 'user.name', 'fixture') | Out-Null
    Write-Fixture (Join-Path $Repo 'README') "fixture`n"
    Invoke-GitFixture $Repo @('add', 'README') | Out-Null
    Invoke-GitFixture $Repo @('commit', '-qm', 'fixture: initial') | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $Repo '.projex') | Out-Null

    $planName = '2608081953-close-precheck-script-plan.md'
    $logName = 'fixture-close-precheck-log.md'
    $branch = 'projex/2608090541-close-precheck-script-plan'
    $planPath = Join-Path $Repo ('.projex/' + $planName)
    Write-Fixture $planPath @"
# Plan

> **Status:** In Progress
> **Log:** $logName

$planName
"@
    Invoke-GitFixture $Repo @('add', ('.projex/' + $planName)) | Out-Null
    Invoke-GitFixture $Repo @('commit', '-qm', 'fixture: plan') | Out-Null
    $Child = Join-Path $Repo '.projexwt/child'
    Invoke-GitFixture $Repo @('worktree', 'add', '-q', '-b', $branch, $Child, 'main') | Out-Null
    $logPath = Join-Path $Child ('.projex/' + $logName)
    Write-Fixture $logPath @"
# Execution Log

> **Status:** In Progress
> **Repo Root:** $Repo
> **Plan File:** .projex/$planName
> **Base Branch:** main
> **Worktree Path:** $Child

$planName
"@
    Invoke-GitFixture $Child @('add', ('.projex/' + $logName)) | Out-Null
    Invoke-GitFixture $Child @('commit', '-qm', 'fixture: execution log') | Out-Null
    Write-Fixture (Join-Path $Child '.projex/child-only.md') "# Child`n$planName`n"

    $beforeBase = (Invoke-GitFixture $Repo @('rev-parse', 'refs/heads/main'))[0]
    $beforeEphemeral = (Invoke-GitFixture $Repo @('rev-parse', ('refs/heads/' + $branch)))[0]
    $result = Invoke-Precheck $Child ('.projex/' + $planName)
    Assert-Equal 'explicit worktree run succeeds' $result.Code 0
    Assert-Contains 'schema' $result.Output 'SCHEMA_VERSION=1'
    Assert-Contains 'encoded branch' $result.Output 'EPHEMERAL_BRANCH=projex%2F'
    Assert-Contains 'worktree identity' $result.Output 'WORKTREE_PATH='
    Assert-Contains 'inventory' $result.Output 'SECTION=PROJEX_INVENTORY'
    Assert-Contains 'child record' $result.Output "`tCHILD`t"
    Assert-Contains 'warning result' $result.Output 'RESULT=PASS_WITH_WARNINGS'
    Assert-Equal 'base ref unchanged' ((Invoke-GitFixture $Repo @('rev-parse', 'refs/heads/main'))[0]) $beforeBase
    Assert-Equal 'ephemeral ref unchanged' ((Invoke-GitFixture $Repo @('rev-parse', ('refs/heads/' + $branch)))[0]) $beforeEphemeral

    Push-Location $Child
    try { $noArgOutput = @(& $Script 2>$null); $noArgCode = $LASTEXITCODE } finally { Pop-Location }
    Assert-Equal 'no-argument inference succeeds' $noArgCode 0
    Assert-Contains 'no-argument result' $noArgOutput 'RESULT=PASS_WITH_WARNINGS'

    Write-Fixture $logPath @"
# Execution Log

> **Repo Root:** $Repo
> **Worktree Path:** $Child
"@
    $bad = Invoke-Precheck $Child ('.projex/' + $planName)
    Assert-Equal 'missing base header fails' $bad.Code 1
    Assert-Contains 'missing base error result' $bad.Output 'RESULT=ERROR'
    Assert-Contains 'missing base encoded error' $bad.Output 'ERROR='
    function Set-WorktreeLog {
        Write-Fixture $logPath @"
# Execution Log

> **Status:** In Progress
> **Repo Root:** $Repo
> **Plan File:** .projex/$planName
> **Base Branch:** main
> **Worktree Path:** $Child

$planName
"@
    }

    function Invoke-NoArg {
        Push-Location $Child
        try { $output = @(& $Script 2>$null); $code = $LASTEXITCODE } finally { Pop-Location }
        [pscustomobject]@{ Output = $output; Code = $code }
    }

    # Required context/path matrix: bad plan pointers, local-base validation, relative path, and reuse.
    Write-Fixture $planPath "# Plan`n`n> **Status:** In Progress`n> **Log:** missing-log.md`n"
    $bad = Invoke-Precheck $Child ('.projex/' + $planName)
    Assert-Equal 'missing plan log fails' $bad.Code 1
    Write-Fixture $planPath "# Plan`n`n> **Status:** In Progress`n> **Log:** $logName`n> **Log:** $logName`n"
    $bad = Invoke-Precheck $Child ('.projex/' + $planName)
    Assert-Equal 'duplicate plan log fails' $bad.Code 1
    Write-Fixture $planPath "# Plan`n`n> **Status:** In Progress`n> **Log:** $logName`n`n$planName`n"
    Set-WorktreeLog
    Add-Content -LiteralPath $logPath -Value '> **Base Branch:** refs/remotes/origin/main'
    $bad = Invoke-Precheck $Child ('.projex/' + $planName)
    Assert-Equal 'remote base branch fails' $bad.Code 1
    Set-WorktreeLog
    (Get-Content -LiteralPath $logPath -Raw).Replace($Child, '.projexwt/child') | Set-Content -LiteralPath $logPath -NoNewline
    $relative = Invoke-Precheck $Child ('.projex/' + $planName)
    Assert-Equal 'relative worktree path succeeds' $relative.Code 0
    Set-WorktreeLog
    (Get-Content -LiteralPath $logPath -Raw).Replace($Child, $Repo) | Set-Content -LiteralPath $logPath -NoNewline
    $bad = Invoke-Precheck $Child ('.projex/' + $planName)
    Assert-Equal 'reused repo worktree path fails' $bad.Code 1
    Set-WorktreeLog

    # Inference, inventory/status, encoded values, gate warnings, stash evidence, and 100x10 scale.
    $duplicatePlan = Join-Path $Child '.projex/2608099999-close-precheck-script-plan.md'
    Write-Fixture $duplicatePlan '# duplicate plan'
    $ambiguous = Invoke-NoArg
    Assert-Equal 'ambiguous no-argument plan fails' $ambiguous.Code 1
    Remove-Item -LiteralPath $duplicatePlan
    Write-Fixture (Join-Path $Child '.projex/missing-status.md') ("# Missing`n" + $planName + "`n")
    $oddPath = Join-Path $Child '.projex/odd %= name.md'
    Write-Fixture $oddPath ("# Odd`n" + $planName + "`n`n> **Status:** Draft%=`n")
    Add-Content -LiteralPath (Join-Path $Repo 'README') -Value 'origin dirty'
    Write-Fixture (Join-Path $Child '.gitignore') "ignored.bin`n"
    Write-Fixture (Join-Path $Child 'ignored.bin') "ignored`n"
    Write-Fixture (Join-Path $Child 'modified.txt') "modified`n"
    $matrix = Invoke-Precheck $Child ('.projex/' + $planName)
    Assert-Equal 'dirty gate report succeeds' $matrix.Code 0
    Assert-Contains 'missing status record' $matrix.Output "`tMISSING`t"
    Assert-Contains 'encoded unsafe path' $matrix.Output 'odd%20%25%3D%20name.md'
    Assert-Contains 'encoded unsafe status' $matrix.Output 'Draft%25%3D'
    Assert-NotContains 'unsafe path is never raw' $matrix.Output 'odd %= name.md'
    Assert-Contains 'origin gate warns' $matrix.Output "GATE`tORIGIN_BASE`tWARN`t"
    Assert-Contains 'child gate warns' $matrix.Output "GATE`tCHILD_WORKTREE`tWARN`t"
    foreach ($d in 1..100) {
        foreach ($n in 1..10) {
            Write-Fixture (Join-Path $Child ("scale-$d/.projex/candidate-$n.md")) ("# Scale`n" + $planName + "`n`n> **Status:** Draft`n")
        }
    }
    $scale = Invoke-Precheck $Child ('.projex/' + $planName)
    Assert-Equal 'scale report succeeds without truncation' $scale.Code 0
    Assert-AtLeast 'scale report inventories 1000 candidates' (@($scale.Output | Where-Object { $_ -like "RECORD=PROJEX`t*" })).Count 1000
    Get-ChildItem -Path (Join-Path $Child 'scale-*') | Remove-Item -Recurse -Force
    Invoke-GitFixture $Child @('stash', 'push', '-u', '-m', 'fixture %= stash') | Out-Null
    $stashExpected = @(Invoke-GitFixture $Repo @('stash', 'list')) -join "`n"
    $stash = Invoke-Precheck $Child ('.projex/' + $planName)
    Assert-Equal 'stash report succeeds' $stash.Code 0
    Assert-Contains 'encoded stash record' $stash.Output 'RECORD=STASH'
    Assert-Equal 'report leaves stash unchanged' ((@(Invoke-GitFixture $Repo @('stash', 'list')) -join "`n")) $stashExpected

    # Source-level guards complement runtime fixtures: fixed budget, stale paths, and no mutating Git command.
    $source = Get-Content -LiteralPath $Script -Raw
    Assert-Contains 'fixed 8 MiB budget source guard' @($source) '$MaxOutput = 8MB'
    Assert-Contains 'ref drift stale source guard' @($source) 'snapshot identity changed during report'
    Assert-Contains 'worktree drift stale source guard' @($source) 'worktree registration changed during report'
    Assert-NotContains 'no eval source guard' @($source) 'eval '

    Write-Host "PASS=$PassCount FAIL=$FailCount"
} finally {
    if ($Repo -and $Child) { & git -C $Repo worktree remove --force $Child 2>$null | Out-Null }
    if (Test-Path -LiteralPath $TempRoot) { Remove-Item -LiteralPath $TempRoot -Recurse -Force }
}

if ($FailCount -ne 0) { exit 1 }
exit 0
