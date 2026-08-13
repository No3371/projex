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
    function Snapshot {
        $rows = [Collections.Generic.List[string]]::new()
        foreach ($Item in (Get-ChildItem -LiteralPath $Repo -Recurse -Force | Sort-Object FullName)) {
            $Rel = $Item.FullName.Substring($Repo.Length + 1).Replace('\', '/')
            if ($Item.PSIsContainer) { $rows.Add("d`t$Rel") }
            else { $rows.Add("f`t$Rel`t$((Get-FileHash -LiteralPath $Item.FullName -Algorithm SHA256).Hash)") }
        }
        return ($rows -join "`n")
    }
    function AssertParserReject([string]$Id, [string[]]$Args) {
        $Before = Snapshot
        $ErrPath = Join-Path $Temp "$Id.err"
        $Output = & pwsh -NoProfile -File $Scaffold @Args 2> $ErrPath
        $Rc = $LASTEXITCODE
        $Stderr = Get-Content -LiteralPath $ErrPath -Raw
        $After = Snapshot
        $UsageCount = @($Stderr -split "`r?`n" | Where-Object { $_ -match '^Usage: new-projex\.ps1 ' }).Count
        CheckEq '2' ([string]$Rc)
        CheckEq '1' ([string]$UsageCount)
        Check { @($Output).Count -eq 0 } "stdout $Id"
        CheckEq $Before $After
    }

    foreach ($Row in (Get-Content -LiteralPath $Fixture)) {
        if (-not $Row -or $Row.StartsWith('#')) { continue }
        $Parts = $Row -split "`t", 3
        $Id = $Parts[0]; $Parent = $Parts[1]; $Result = $Parts[2]
        $Title = "matrix-$Id"
        $Before = Snapshot
        if ($Result -eq 'success') {
            $Output = & pwsh -NoProfile -File $Scaffold -RepoRoot $Repo -Type plan -Title $Title -Parent $Parent -ProjexDir ".projex/$Id" 2>$null
            $Path = [string]$Output[0]
            Check { Test-Path -LiteralPath $Path -PathType Leaf } "created $Id"
            $Content = Get-Content -LiteralPath $Path -Raw
            $ParentCount = @($Content -split "`r?`n" | Where-Object { $_ -match '^> \*\*Parent:\*\*' }).Count
            CheckEq '1' ([string]$ParentCount)
            Check { Contains $Content "> **Parent:** $Parent" } "header $Id"
        } else {
            $Output = & pwsh -NoProfile -File $Scaffold -RepoRoot $Repo -Type plan -Title $Title -Parent $Parent -ProjexDir ".projex/$Id" 2>$null
            $Rc = $LASTEXITCODE
            Check { $Rc -ne 0 } "reject $Id"
            CheckEq $Before (Snapshot)
            Check { @($Output).Count -eq 0 } "stdout $Id"
        }
    }

    $DefaultOutput = & pwsh -NoProfile -File $Scaffold -RepoRoot $Repo -Type memo -Title default-directory -Parent User
    $DefaultPath = [string]$DefaultOutput[0]
    Check { $DefaultPath.StartsWith((Join-Path $Repo '.projex')) } 'default directory'
    Check { Test-Path -LiteralPath $DefaultPath -PathType Leaf } 'default created'

    AssertParserReject missing-repo @('-Type','plan','-Title','bad','-Parent','User')
    AssertParserReject missing-type @('-RepoRoot',$Repo,'-Title','bad','-Parent','User')
    AssertParserReject missing-title @('-RepoRoot',$Repo,'-Type','plan','-Parent','User')
    AssertParserReject missing-parent @('-RepoRoot',$Repo,'-Type','plan','-Title','bad')
    AssertParserReject duplicate-repo @('-RepoRoot',$Repo,'-reporoot',$Repo,'-Type','plan','-Title','bad','-Parent','User')
    AssertParserReject duplicate-type @('-RepoRoot',$Repo,'-Type','plan','-type','memo','-Title','bad','-Parent','User')
    AssertParserReject duplicate-title @('-RepoRoot',$Repo,'-Type','plan','-Title','bad','-title','worse','-Parent','User')
    AssertParserReject duplicate-parent @('-RepoRoot',$Repo,'-Type','plan','-Title','bad','-Parent','User','-parent','User')
    AssertParserReject duplicate-projex-dir @('-RepoRoot',$Repo,'-Type','plan','-Title','bad','-Parent','User','-ProjexDir','.projex','-projexdir','.projex/other')
    AssertParserReject missing-repo-value @('-RepoRoot','-Type','plan','-Title','bad','-Parent','User')
    AssertParserReject missing-type-value @('-RepoRoot',$Repo,'-Type','-Title','bad','-Parent','User')
    AssertParserReject missing-title-value @('-RepoRoot',$Repo,'-Type','plan','-Title','-Parent','User')
    AssertParserReject missing-parent-value @('-RepoRoot',$Repo,'-Type','plan','-Title','bad','-Parent','-ProjexDir','.projex')
    AssertParserReject missing-projex-dir-value @('-RepoRoot',$Repo,'-Type','plan','-Title','bad','-Parent','User','-ProjexDir')
    AssertParserReject unknown-option @('-RepoRoot',$Repo,'-Type','plan','-Title','bad','-Parent','User','-Unknown','value')
    AssertParserReject stray-positional @($Repo,'-Type','plan','-Title','bad','-Parent','User')
    AssertParserReject legacy-positional @($Repo,'plan','bad','User','.projex/legacy')

    $MixedOutput = & pwsh -NoProfile -File $Scaffold -rEpOrOoT $Repo -tYpE memo -tItLe mixed-case -pArEnT User -pRoJeXdIr .projex/mixed
    $MixedPath = [string]$MixedOutput[0]
    Check { Test-Path -LiteralPath $MixedPath -PathType Leaf } 'mixed case created'
    $MixedContent = Get-Content -LiteralPath $MixedPath -Raw
    CheckEq '1' ([string](@($MixedContent -split "`r?`n" | Where-Object { $_ -match '^> \*\*Parent:\*\*' }).Count))
    Check { Contains $MixedContent '> **Parent:** User' } 'mixed case parent'

    $Stamp = Get-Date -Format 'yyMMddHHmm'
    $SelfName = "$Stamp-self-check-plan.md"
    $Before = Snapshot
    $null = & pwsh -NoProfile -File $Scaffold -RepoRoot $Repo -Type plan -Title self-check -Parent $SelfName -ProjexDir .projex/self 2>$null
    Check { $LASTEXITCODE -eq 2 } 'self parent'
    CheckEq $Before (Snapshot)

    $CollisionName = "$Stamp-collision-check-plan.md"
    Set-Content -LiteralPath (Join-Path $Repo ".projex/closed/$CollisionName") -Value '# existing' -NoNewline
    $Before = Snapshot
    $null = & pwsh -NoProfile -File $Scaffold -RepoRoot $Repo -Type plan -Title collision-check -Parent User -ProjexDir .projex/collision 2>$null
    Check { $LASTEXITCODE -eq 2 } 'collision'
    CheckEq $Before (Snapshot)

    $Actual = [Collections.Generic.List[string]]::new()
    Get-ChildItem -LiteralPath $Root -Filter '*-projex.md' -File | ForEach-Object {
        if ((Get-Content -LiteralPath $_.FullName -Raw).Contains('new-projex.sh')) { $Actual.Add("scaffold:$($_.Name)") }
    }
    foreach ($Name in @('execute-projex.md','close-projex.md','debug-projex.md','sprint-projex.md')) { $Actual.Add("manual:$Name") }
    $Expected = @(Get-Content -LiteralPath $Creators | Sort-Object)
    Check { (Compare-Object $Expected @($Actual | Sort-Object)).Count -eq 0 } 'creator inventory'
    Get-ChildItem -LiteralPath $Root -Filter '*-projex.md' -File | ForEach-Object {
        $Lines = Get-Content -LiteralPath $_.FullName
        $ShellLines = @($Lines | Where-Object { $_.Contains('new-projex.sh') })
        $PowerShellLines = @($Lines | Where-Object { $_.Contains('new-projex.ps1') })
        if ($ShellLines.Count -gt 0) {
            CheckEq '1' ([string]$ShellLines.Count)
            CheckEq '1' ([string]$PowerShellLines.Count)
            Check { $ShellLines[0].Contains('--repo-root') -and $ShellLines[0].Contains('--type') -and $ShellLines[0].Contains('--title') -and $ShellLines[0].Contains('--parent') -and $ShellLines[0].Contains('--projex-dir') } "shell named $($_.Name)"
            Check { $PowerShellLines[0].Contains('-RepoRoot') -and $PowerShellLines[0].Contains('-Type') -and $PowerShellLines[0].Contains('-Title') -and $PowerShellLines[0].Contains('-Parent') -and $PowerShellLines[0].Contains('-ProjexDir') } "powershell named $($_.Name)"
        }
    }
    Check { Contains (Get-Content -LiteralPath (Join-Path $Root 'execute-projex.md') -Raw) '> **Parent:** {plan-filename}' } 'execute Parent'
    Check { Contains (Get-Content -LiteralPath (Join-Path $Root 'close-projex.md') -Raw) '> **Parent:** [plan filename]' } 'close Parent'
    Check { Contains (Get-Content -LiteralPath (Join-Path $Root 'debug-projex.md') -Raw) '> **Parent:** {debug-parent}' } 'debug Parent'
    Check { Contains (Get-Content -LiteralPath (Join-Path $Root 'debug-projex.md') -Raw) '> **Parent:** {debug-log-filename}' } 'debug final Parent'
    Check { Contains (Get-Content -LiteralPath (Join-Path $Root 'sprint-projex.md') -Raw) '> **Parent:** {sprint-parent}' } 'sprint Parent'

    "PASS=$Pass FAIL=$Fail"
} finally {
    if (Test-Path -LiteralPath $Temp) { Remove-Item -LiteralPath $Temp -Recurse -Force }
}
if ($Fail -ne 0) { exit 1 }
exit 0
