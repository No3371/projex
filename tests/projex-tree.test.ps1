$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$Tree = Join-Path $Root 'projex-tree.ps1'
$Fixture = Join-Path $Root 'tests/fixtures/projex-tree/basic'
$DuplicateFixture = Join-Path $Root 'tests/fixtures/projex-tree/duplicate-parent'
$InvalidUtf8Fixture = Join-Path $Root 'tests/fixtures/projex-tree/invalid-utf8'
$Temp = Join-Path ([IO.Path]::GetTempPath()) ('projex-tree-' + [guid]::NewGuid())
$Repo = Join-Path $Temp 'repo'
New-Item -ItemType Directory -Path (Join-Path $Repo '.projex/closed') -Force | Out-Null
Copy-Item -Path (Join-Path $Fixture '*') -Destination $Repo -Recurse -Force
try {
    $Pass = 0; $Fail = 0; $Cases = 0
    function Check([scriptblock]$Condition, [string]$Label) { $script:Cases++; if (& $Condition) { $script:Pass++ } else { $script:Fail++; [Console]::Error.WriteLine("FAIL: $Label") } }
    function CheckEq([string]$Expected, [string]$Actual) { $script:Cases++; if ($Expected -ceq $Actual) { $script:Pass++ } else { $script:Fail++; [Console]::Error.WriteLine("FAIL: expected '$Expected', got '$Actual'") } }
    function Contains([string]$Text, [string]$Needle) { return $Text.Contains($Needle) }
    function RunBasic([string]$Name) {
        $Out = Join-Path $Temp 'out'; $Err = Join-Path $Temp 'err'
        & pwsh -NoProfile -File $Tree $Repo $Name 1>$Out 2>$Err
        $rc = $LASTEXITCODE
        CheckEq '0' ([string]$rc); Check { (Get-FileHash $Out).Hash -eq (Get-FileHash (Join-Path $Fixture 'expected.stdout')).Hash } "stdout $Name"; Check { (Get-Item $Err).Length -eq 0 } "stderr $Name"
    }
    function RunError([string]$Name, [string]$Code, [string]$Detail) {
        $Out = Join-Path $Temp 'out'; $Err = Join-Path $Temp 'err'
        & pwsh -NoProfile -File $Tree $Repo $Name 1>$Out 2>$Err
        $rc = $LASTEXITCODE; $Text = Get-Content -LiteralPath $Err -Raw
        CheckEq '3' ([string]$rc); Check { (Get-Item $Out).Length -eq 0 } "empty stdout $Name"; Check { Contains $Text "projex-tree: ${Code}:" } "code $Name"; Check { Contains $Text $Detail } "detail $Name"
    }
    RunBasic '2608051553-feature-proposal.md'; RunBasic '2608052327-feature-plan.md'; RunBasic '2608052327-feature-log.md'
    Set-Content -LiteralPath (Join-Path $Repo '.projex/2609000000-malformed-plan.md') -Value "# malformed`n> **Parent:** bad/path.md`n---`n" -NoNewline
    RunBasic '2608051553-feature-proposal.md'
    RunError '2609000000-malformed-plan.md' 'E_PARENT_MALFORMED' 'bad/path.md'
    Set-Content -LiteralPath (Join-Path $Repo '.projex/2609000001-dangling-plan.md') -Value "# dangling`n> **Parent:** 2609000009-missing-plan.md`n---`n" -NoNewline
    RunError '2609000001-dangling-plan.md' 'E_PARENT_DANGLING' 'missing-plan.md'
    Set-Content -LiteralPath (Join-Path $Repo '.projex/2609000002-self-plan.md') -Value "# self`n> **Parent:** 2609000002-self-plan.md`n---`n" -NoNewline
    RunError '2609000002-self-plan.md' 'E_PARENT_SELF' 'names the document itself'
    Set-Content -LiteralPath (Join-Path $Repo '.projex/2609000003-cycle-a-plan.md') -Value "# a`n> **Parent:** 2609000004-cycle-b-plan.md`n---`n" -NoNewline
    Set-Content -LiteralPath (Join-Path $Repo '.projex/2609000004-cycle-b-plan.md') -Value "# b`n> **Parent:** 2609000003-cycle-a-plan.md`n---`n" -NoNewline
    RunError '2609000003-cycle-a-plan.md' 'E_CYCLE' 'Parent chain cycles'
    Copy-Item (Join-Path $DuplicateFixture 'input.md') (Join-Path $Repo '.projex/2609000006-duplicate-child-plan.md')
    $Out = Join-Path $Temp 'out'; $Err = Join-Path $Temp 'err'; & pwsh -NoProfile -File $Tree $Repo '2608051553-feature-proposal.md' 1>$Out 2>$Err; $rc = $LASTEXITCODE
    CheckEq (Get-Content -LiteralPath (Join-Path $DuplicateFixture 'expected.exit') -Raw).Trim() ([string]$rc)
    Check { (Get-Item $Out).Length -eq 0 } 'duplicate stdout'
    Check { (Get-FileHash $Err).Hash -eq (Get-FileHash (Join-Path $DuplicateFixture 'expected.stderr')).Hash } 'duplicate stderr'
    Copy-Item (Join-Path $Repo '.projex/2608051553-feature-proposal.md') (Join-Path $Repo '.projex/closed/2608051553-feature-proposal.md')
    $Out = Join-Path $Temp 'out'; $Err = Join-Path $Temp 'err'; & pwsh -NoProfile -File $Tree $Repo '2608051553-feature-proposal.md' 1>$Out 2>$Err; $rc = $LASTEXITCODE; $Text = Get-Content $Err -Raw
    CheckEq '2' ([string]$rc); Check { (Get-Item $Out).Length -eq 0 } 'ambiguous stdout'; Check { Contains $Text 'E_TARGET_AMBIGUOUS' } 'ambiguous code'
    & pwsh -NoProfile -File $Tree $Repo missing.md 1>$Out 2>$Err; $rc = $LASTEXITCODE; $Text = Get-Content $Err -Raw
    CheckEq '2' ([string]$rc); Check { (Get-Item $Out).Length -eq 0 } 'missing stdout'; Check { Contains $Text 'E_TARGET_NOT_FOUND' } 'missing code'
    & pwsh -NoProfile -File $Tree $Repo '.projex/2608051553-feature-proposal.md' 1>$Out 2>$Err; $rc = $LASTEXITCODE; $Text = Get-Content $Err -Raw
    CheckEq '2' ([string]$rc); Check { (Get-Item $Out).Length -eq 0 } 'path stdout'; Check { Contains $Text 'E_TARGET_NAME' } 'path code'
    New-Item -ItemType Directory -Path (Join-Path $Repo '.projex/crlf') -Force | Out-Null
    [IO.File]::WriteAllText((Join-Path $Repo '.projex/crlf/2609000005-bom-root-plan.md'), "`u{FEFF}# BOM`r`n> **Parent:** User`r`n---`r`n", [Text.UTF8Encoding]::new($false))
    & pwsh -NoProfile -File $Tree $Repo '2609000005-bom-root-plan.md' 1>$Out 2>$Err; $rc = $LASTEXITCODE
    CheckEq '0' ([string]$rc); Check { (Get-Content $Out -Raw) -eq "2609000005-bom-root-plan.md`n" } 'bom stdout'; Check { (Get-Item $Err).Length -eq 0 } 'bom stderr'
    [IO.File]::WriteAllBytes((Join-Path $Repo '.projex/2609000007-invalid-utf8-plan.md'), [byte[]](0xff))
    & pwsh -NoProfile -File $Tree $Repo '2609000007-invalid-utf8-plan.md' 1>$Out 2>$Err; $rc = $LASTEXITCODE
    CheckEq (Get-Content -LiteralPath (Join-Path $InvalidUtf8Fixture 'expected.exit') -Raw).Trim() ([string]$rc)
    Check { (Get-Item $Out).Length -eq 0 } 'invalid UTF-8 stdout'
    Check { (Get-FileHash $Err).Hash -eq (Get-FileHash (Join-Path $InvalidUtf8Fixture 'expected.stderr')).Hash } 'invalid UTF-8 stderr'
    "PASS=$Pass FAIL=$Fail CASES=$Cases"
    if ($Fail -ne 0) { exit 1 }
} finally { if (Test-Path $Temp) { Remove-Item $Temp -Recurse -Force } }
