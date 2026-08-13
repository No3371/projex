$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$Scaffold = Join-Path $Root 'new-projex.ps1'
$Fixture = Join-Path $Root 'tests/fixtures/new-projex-cases.tsv'
$Creators = Join-Path $Root 'tests/fixtures/projex-creators.txt'
$Temp = Join-Path ([IO.Path]::GetTempPath()) ('projex-scaffold-' + [guid]::NewGuid())
$Repo = Join-Path $Temp 'repo'
New-Item -ItemType Directory -Path (Join-Path $Repo '.projex/closed') -Force | Out-Null
try {
    $Pass = 0; $Fail = 0; $Cases = 0
    function Check([scriptblock]$Condition, [string]$Label) {
        $script:Cases++
        if (& $Condition) { $script:Pass++ } else { $script:Fail++; [Console]::Error.WriteLine("FAIL: $Label") }
    }
    function CheckEq([string]$Expected, [string]$Actual) {
        $script:Cases++
        if ($Expected -ceq $Actual) { $script:Pass++ } else { $script:Fail++; [Console]::Error.WriteLine("FAIL: expected '$Expected', got '$Actual'") }
    }
    function Contains([string]$Text, [string]$Needle) { return $Text.Contains($Needle) }
    $Rows = Get-Content -LiteralPath $Fixture
    foreach ($Row in $Rows) {
        if (-not $Row -or $Row.StartsWith('#')) { continue }
        $Parts = $Row -split "`t", 3
        $Id = $Parts[0]; $Parent = $Parts[1]; $Result = $Parts[2]
        $Title = "matrix-$Id"
        $Before = @(Get-ChildItem -LiteralPath $Repo -File -Filter '*.md' -Recurse).Count
        if ($Result -eq 'success') {
            $Output = & pwsh -NoProfile -File $Scaffold $Repo plan $Title $Parent ".projex/$Id" 2>$null
            $Path = [string]$Output[0]
            Check { Test-Path -LiteralPath $Path -PathType Leaf } "created $Id"
            $Content = Get-Content -LiteralPath $Path -Raw
            $ParentCount = @($Content -split "`r?`n" | Where-Object { $_ -match '^> \*\*Parent:\*\*' }).Count
            CheckEq '1' ([string]$ParentCount)
            Check { Contains $Content "> **Parent:** $Parent" } "header $Id"
        } else {
            & pwsh -NoProfile -File $Scaffold $Repo plan $Title $Parent ".projex/$Id" 2>$null | Out-Null
            $Rc = $LASTEXITCODE
            $After = @(Get-ChildItem -LiteralPath $Repo -File -Filter '*.md' -Recurse).Count
            Check { $Rc -ne 0 } "reject $Id"
            CheckEq ([string]$Before) ([string]$After)
        }
    }
    $Stamp = Get-Date -Format 'yyMMddHHmm'
    $SelfName = "$Stamp-self-check-plan.md"
    $Before = @(Get-ChildItem -LiteralPath $Repo -File -Filter '*.md' -Recurse).Count
    & pwsh -NoProfile -File $Scaffold $Repo plan 'self-check' $SelfName '.projex/self' 2>$null | Out-Null
    Check { $LASTEXITCODE -ne 0 } 'self parent'
    CheckEq ([string]$Before) ([string](@(Get-ChildItem -LiteralPath $Repo -File -Filter '*.md' -Recurse).Count))

    & pwsh -NoProfile -File $Scaffold $Repo plan 'extra-operand' User '.projex/extra' unexpected 2>$null | Out-Null
    Check { $LASTEXITCODE -ne 0 } 'extra operand'

    $CollisionName = "$Stamp-collision-check-plan.md"
    Set-Content -LiteralPath (Join-Path $Repo ".projex/closed/$CollisionName") -Value '# existing' -NoNewline
    $Before = @(Get-ChildItem -LiteralPath $Repo -File -Filter '*.md' -Recurse).Count
    & pwsh -NoProfile -File $Scaffold $Repo plan 'collision-check' User '.projex/collision' 2>$null | Out-Null
    Check { $LASTEXITCODE -ne 0 } 'collision'
    CheckEq ([string]$Before) ([string](@(Get-ChildItem -LiteralPath $Repo -File -Filter '*.md' -Recurse).Count))

    $Actual = [Collections.Generic.List[string]]::new()
    Get-ChildItem -LiteralPath $Root -Filter '*-projex.md' -File | ForEach-Object {
        if ((Get-Content -LiteralPath $_.FullName -Raw).Contains('new-projex')) { $Actual.Add("scaffold:$($_.Name)") }
    }
    foreach ($Name in @('execute-projex.md','close-projex.md','debug-projex.md','sprint-projex.md')) { $Actual.Add("manual:$Name") }
    $Expected = @(Get-Content -LiteralPath $Creators | Sort-Object)
    Check { (Compare-Object $Expected @($Actual | Sort-Object)).Count -eq 0 } 'creator inventory'
    Get-ChildItem -LiteralPath $Root -Filter '*-projex.md' -File | ForEach-Object {
        foreach ($Line in (Get-Content -LiteralPath $_.FullName)) {
            if ($Line.Contains('new-projex') -and $Line.Contains('<projex-folder>')) { Check { $Line.Contains('{parent}') } "arity $($_.Name)" }
        }
    }
    Check { Contains (Get-Content -LiteralPath (Join-Path $Root 'execute-projex.md') -Raw) '> **Parent:** {plan-filename}' } 'execute Parent'
    Check { Contains (Get-Content -LiteralPath (Join-Path $Root 'close-projex.md') -Raw) '> **Parent:** [plan filename]' } 'close Parent'
    Check { Contains (Get-Content -LiteralPath (Join-Path $Root 'debug-projex.md') -Raw) '> **Parent:** {debug-parent}' } 'debug Parent'
    Check { Contains (Get-Content -LiteralPath (Join-Path $Root 'debug-projex.md') -Raw) '> **Parent:** {debug-log-filename}' } 'debug final Parent'
    Check { Contains (Get-Content -LiteralPath (Join-Path $Root 'sprint-projex.md') -Raw) '> **Parent:** {sprint-parent}' } 'sprint Parent'
    "PASS=$Pass FAIL=$Fail CASES=$Cases"
    if ($Fail -ne 0) { exit 1 }
} finally {
    if (Test-Path -LiteralPath $Temp) { Remove-Item -LiteralPath $Temp -Recurse -Force }
}
