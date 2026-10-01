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
    $PwshPath = (Get-Process -Id $PID).Path
    # ProcessStartInfo.ArgumentList hands every argument (empty strings, -Verbose, --) to pwsh -File verbatim; output read as raw bytes
    function InvokePwsh([string[]]$Lead, [string[]]$Argv, [string]$Dir) {
        $Info = [Diagnostics.ProcessStartInfo]::new($PwshPath)
        foreach ($A in $Lead) { $Info.ArgumentList.Add($A) }
        if ($Argv) { foreach ($A in $Argv) { $Info.ArgumentList.Add($A) } }
        if ($Dir) { $Info.WorkingDirectory = $Dir }
        $Info.UseShellExecute = $false
        $Info.RedirectStandardInput = $true; $Info.RedirectStandardOutput = $true; $Info.RedirectStandardError = $true
        $P = [Diagnostics.Process]::Start($Info)
        $P.StandardInput.Close()
        $O = [IO.MemoryStream]::new(); $E = [IO.MemoryStream]::new()
        $TaskO = $P.StandardOutput.BaseStream.CopyToAsync($O); $TaskE = $P.StandardError.BaseStream.CopyToAsync($E)
        $P.WaitForExit(); $TaskO.Wait(); $TaskE.Wait()
        return [pscustomobject]@{ Code = $P.ExitCode; Out = $O.ToArray(); Err = $E.ToArray() }
    }
    function InvokeTree([string[]]$Argv) { return InvokePwsh @('-NoProfile', '-File', $Tree) $Argv '' }
    # pwsh "2>file" re-encodes a native command's stderr lines with CRLF; RunRaw stores the raw bytes instead
    function RunRaw([string]$Name) {
        $R = InvokeTree @($Repo, $Name)
        [IO.File]::WriteAllBytes((Join-Path $Temp 'out'), $R.Out); [IO.File]::WriteAllBytes((Join-Path $Temp 'err'), $R.Err)
        return $R.Code
    }
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
    Set-Content -LiteralPath (Join-Path $Repo '.projex/2609000002-self-plan.md') -Value "# self`n> **Parent:** 2609000002-self-plan.md`n---`n" -NoNewline
    RunError '2609000002-self-plan.md' 'E_PARENT_SELF' 'names the document itself'
    Set-Content -LiteralPath (Join-Path $Repo '.projex/2609000003-cycle-a-plan.md') -Value "# a`n> **Parent:** 2609000004-cycle-b-plan.md`n---`n" -NoNewline
    Set-Content -LiteralPath (Join-Path $Repo '.projex/2609000004-cycle-b-plan.md') -Value "# b`n> **Parent:** 2609000003-cycle-a-plan.md`n---`n" -NoNewline
    RunError '2609000003-cycle-a-plan.md' 'E_CYCLE' 'Parent chain cycles'
    Copy-Item (Join-Path $DuplicateFixture 'input.md') (Join-Path $Repo '.projex/2609000006-duplicate-child-plan.md')
    $Out = Join-Path $Temp 'out'; $Err = Join-Path $Temp 'err'; $rc = RunRaw '2608051553-feature-proposal.md'
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
    $rc = RunRaw '2609000007-invalid-utf8-plan.md'
    CheckEq (Get-Content -LiteralPath (Join-Path $InvalidUtf8Fixture 'expected.exit') -Raw).Trim() ([string]$rc)
    Check { (Get-Item $Out).Length -eq 0 } 'invalid UTF-8 stdout'
    Check { (Get-FileHash $Err).Hash -eq (Get-FileHash (Join-Path $InvalidUtf8Fixture 'expected.stderr')).Hash } 'invalid UTF-8 stderr'

    $Fixtures = Join-Path $Root 'tests/fixtures/projex-tree'
    $Utf8 = [Text.UTF8Encoding]::new($false)
    $None = [byte[]]::new(0)
    function Bytes([string]$Text) { return , $Utf8.GetBytes($Text) }
    function FileBytes([string]$Path) { return , [IO.File]::ReadAllBytes($Path) }
    function Same([byte[]]$A, [byte[]]$B) { return [Linq.Enumerable]::SequenceEqual($A, $B) }
    function Tally([bool]$Ok, [string]$Label) { $script:Cases++; if ($Ok) { $script:Pass++ } else { $script:Fail++; [Console]::Error.WriteLine("FAIL: $Label") } }
    function Expect([string]$Label, [int]$Code, [byte[]]$WantOut, [byte[]]$WantErr, [string[]]$Argv) {
        $R = InvokeTree $Argv
        Tally ($R.Code -eq $Code) "${Label}: exit $($R.Code), expected $Code"
        Tally (Same $WantOut $R.Out) "${Label}: stdout"
        Tally (Same $WantErr $R.Err) "${Label}: stderr"
    }
    function CopyTree([string]$From, [string]$To) {
        [IO.Directory]::CreateDirectory($To) | Out-Null
        foreach ($F in [IO.Directory]::GetFiles($From)) { [IO.File]::Copy($F, (Join-Path $To ([IO.Path]::GetFileName($F)))) }
        foreach ($D in [IO.Directory]::GetDirectories($From)) { CopyTree $D (Join-Path $To ([IO.Path]::GetFileName($D))) }
    }
    function CopyFixture([string]$Name) {
        $Fx = Join-Path $Temp 'fx'
        if (Test-Path -LiteralPath $Fx) { Remove-Item -LiteralPath $Fx -Recurse -Force }
        CopyTree (Join-Path $Fixtures $Name) $Fx
        return $Fx
    }
    function Doc([string]$Path, [string]$Parent) {
        [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($Path)) | Out-Null
        [IO.File]::WriteAllBytes($Path, $Utf8.GetBytes("# t`n> **Parent:** $Parent`n---`n"))
    }
    function Deny([string]$Path, [string]$Rights) {
        if ($IsWindows) { & icacls $Path /deny "${env:USERNAME}:($Rights)" | Out-Null; return $LASTEXITCODE -eq 0 }
        if ((& id -u) -eq '0') { return $false }
        & chmod 000 $Path; return $LASTEXITCODE -eq 0
    }
    function Allow([string]$Path) {
        if ($IsWindows) { & icacls $Path /remove:d $env:USERNAME | Out-Null } else { & chmod 755 $Path }
    }
    function Skip([string]$Case, [string]$Why) { "SKIP ${Case}: $Why" }

    # nested .projex inside a .projex root is walked once
    $Fx = CopyFixture 'nested-projex'
    Expect 'nested-projex-root' 0 (FileBytes "$Fixtures/nested-projex/expected.stdout") $None @($Fx, '2609100000-root-proposal.md')
    Expect 'nested-projex-inner' 0 (FileBytes "$Fixtures/nested-projex/expected.stdout") $None @($Fx, '2609100001-inner-plan.md')

    # nested repositories (.git dir or file below the root) are pruned; .GIT is not .git
    $Fx = CopyFixture 'nested-repo'
    $VendorGit = Join-Path $Fx 'vendor/.git'
    Expect 'nested-repo-none' 0 (FileBytes "$Fixtures/nested-repo/expected.stdout") $None @($Fx, '2609110000-host-proposal.md')
    [IO.Directory]::CreateDirectory($VendorGit) | Out-Null
    Expect 'nested-repo-dir' 0 (FileBytes "$Fixtures/nested-repo/expected-pruned.stdout") $None @($Fx, '2609110000-host-proposal.md')
    Expect 'nested-repo-dir-target' 2 $None (FileBytes "$Fixtures/nested-repo/expected-vendored-pruned.stderr") @($Fx, '2609110001-vendored-plan.md')
    [IO.Directory]::Delete($VendorGit)
    [IO.File]::WriteAllBytes($VendorGit, (Bytes "gitdir: x`n"))
    Expect 'nested-repo-file' 0 (FileBytes "$Fixtures/nested-repo/expected-pruned.stdout") $None @($Fx, '2609110000-host-proposal.md')
    Expect 'nested-repo-file-target' 2 $None (FileBytes "$Fixtures/nested-repo/expected-vendored-pruned.stderr") @($Fx, '2609110001-vendored-plan.md')
    [IO.File]::Delete($VendorGit)
    [IO.Directory]::CreateDirectory((Join-Path $Fx 'vendor/.GIT')) | Out-Null
    Expect 'nested-repo-upper' 0 (FileBytes "$Fixtures/nested-repo/expected.stdout") $None @($Fx, '2609110000-host-proposal.md')

    # an undiscovered Parent becomes the "(missing)" root; documents naming it are its children
    $Fx = CopyFixture 'dangling-parent'
    Expect 'dangling-chain' 0 (FileBytes "$Fixtures/dangling-parent/expected.stdout") $None @($Fx, '2609200002-orphan-log.md')
    Expect 'dangling-sibling' 0 (FileBytes "$Fixtures/dangling-parent/expected.stdout") $None @($Fx, '2609200001-sibling-patch.md')
    Expect 'dangling-other' 0 (FileBytes "$Fixtures/dangling-parent/expected-stray.stdout") $None @($Fx, '2609200003-stray-patch.md')

    # code-point child order, case-sensitive identity
    $Fx = CopyFixture 'sort-order'
    Expect 'sort-order' 0 (FileBytes "$Fixtures/sort-order/expected.stdout") $None @($Fx, '2609120002-case-plan.md')

    # header grammar edge cases
    $Fx = CopyFixture 'header-quirks'
    Expect 'header-quirks' 0 (FileBytes "$Fixtures/header-quirks/expected.stdout") $None @($Fx, '2609130000-root-proposal.md')
    Expect 'header-empty-parent' 3 $None (FileBytes "$Fixtures/header-quirks/expected-empty-parent.stderr") @($Fx, '2609130009-empty-parent-plan.md')

    # errors sorted by (code, locator, detail) tuple
    $Fx = CopyFixture 'error-order'
    Expect 'error-order' 3 $None (FileBytes "$Fixtures/error-order/expected.stderr") @($Fx, '2609140000-root-proposal.md')

    # first unreadable document in walk order: files before subdirectories, x before x-y
    $Fx = CopyFixture 'io-order'
    foreach ($Bad in '2609150002-bad-plan.md', '0/2609150001-bad-plan.md', 'x/2609150003-bad-plan.md', 'x-y/2609150004-bad-plan.md') {
        $BadPath = Join-Path $Fx ".projex/$Bad"
        [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($BadPath)) | Out-Null
        [IO.File]::WriteAllBytes($BadPath, [byte[]](0xFF))
    }
    Expect 'io-order-first' 4 $None (FileBytes "$Fixtures/io-order/expected-first.stderr") @($Fx, '2609150000-root-proposal.md')
    Remove-Item -LiteralPath (Join-Path $Fx '.projex/2609150002-bad-plan.md'), (Join-Path $Fx '.projex/0') -Recurse -Force
    Expect 'io-order-second' 4 $None (FileBytes "$Fixtures/io-order/expected-second.stderr") @($Fx, '2609150000-root-proposal.md')

    # UTF-8 well-formedness table
    $U8 = Join-Path $Temp 'u8'
    foreach ($Row in [IO.File]::ReadAllLines((Join-Path $Fixtures 'utf8-cases.tsv'))) {
        $Label, $Hex, $Verdict = $Row.Split("`t")
        if (Test-Path -LiteralPath $U8) { Remove-Item -LiteralPath $U8 -Recurse -Force }
        [IO.Directory]::CreateDirectory((Join-Path $U8 '.projex')) | Out-Null
        [IO.File]::WriteAllBytes((Join-Path $U8 '.projex/2609160000-utf8-plan.md'), [byte[]]((Bytes "# t`n> **Parent:** User`n---`n") + [Convert]::FromHexString($Hex)))
        if ($Verdict -ceq 'valid') {
            Expect "utf8-$Label" 0 (Bytes "2609160000-utf8-plan.md`n") $None @($U8, '2609160000-utf8-plan.md')
        } else {
            Expect "utf8-$Label" 4 $None (Bytes "projex-tree: E_IO: .projex/2609160000-utf8-plan.md: invalid UTF-8`n") @($U8, '2609160000-utf8-plan.md')
        }
    }

    # target must be a bare filename: no / \ or :
    foreach ($Target in 'a\b.md', 'c:x.md', 'a:b.md') {
        Expect "target-name $Target" 2 $None (Bytes "projex-tree: E_TARGET_NAME: ${Target}: filename basename required`n") @($Repo, $Target)
    }

    # invocation: exactly two arguments
    $Usage = Bytes "projex-tree: E_USAGE: invocation: expected <repo-root> <filename>`n"
    Expect 'usage-0' 2 $None $Usage @()
    Expect 'usage-1' 2 $None $Usage @('.')
    Expect 'usage-3' 2 $None $Usage @('.', '2608051553-feature-proposal.md', 'extra')
    Expect 'usage-verbose' 2 $None $Usage @('.', '2608051553-feature-proposal.md', '-Verbose')
    Expect 'usage-dashdash' 2 $None $Usage @('.', '2608051553-feature-proposal.md', '--')
    Expect 'empty-repo' 2 $None (Bytes "projex-tree: E_REPO: : repository root not found`n") @('', '2608051553-feature-proposal.md')
    Expect 'empty-target' 2 $None (Bytes "projex-tree: E_TARGET_NAME: <empty>: filename basename required`n") @('.', '')

    # repository root that is itself a .projex directory
    $Dp = Join-Path $Temp 'dp'
    CopyTree $Fixture $Dp
    Expect 'dot-projex-root' 0 (FileBytes "$Fixture/expected.stdout") $None @((Join-Path $Dp '.projex'), '2608051553-feature-proposal.md')
    Expect 'dot-projex-rel' 3 $None (Bytes "projex-tree: E_PARENT_MALFORMED: unrelated-malformed.md: Parent is not a projex filename: bad/path.md`n") @((Join-Path $Dp '.projex'), 'unrelated-malformed.md')

    # relative repository root resolves against the caller's location. Called in-process after Set-Location, which
    # moves $PWD but not the process working directory (here the repository), so a child "pwsh -File" cannot catch it.
    $Session = "Set-Location -LiteralPath '$Temp'; & '$Tree' dp 2608051553-feature-proposal.md; exit `$LASTEXITCODE"
    $R = InvokePwsh @('-NoProfile', '-Command', $Session) @() $Root
    Tally ($R.Code -eq 0) "relative-repo: exit $($R.Code), expected 0"
    Tally (Same (FileBytes "$Fixture/expected.stdout") $R.Out) 'relative-repo: stdout'
    Tally (Same $None $R.Err) 'relative-repo: stderr'

    # NUL inside a Parent value survives to stderr; the directory is not named "nul", a Windows reserved
    # device name that makes the repository root unresolvable (E_REPO)
    $NulRepo = Join-Path $Temp 'nulparent'
    [IO.Directory]::CreateDirectory((Join-Path $NulRepo '.projex')) | Out-Null
    [IO.File]::WriteAllBytes((Join-Path $NulRepo '.projex/2609170000-nul-plan.md'), (Bytes "# t`n> **Parent:** a`0b`n---`n"))
    Expect 'nul-parent' 3 $None (Bytes "projex-tree: E_PARENT_MALFORMED: .projex/2609170000-nul-plan.md: Parent is not a projex filename: a`0b`n") @($NulRepo, '2609170000-nul-plan.md')

    # symlinked directories are not descended; symlinked files are not documents
    $Lk = Join-Path $Temp 'lk'; $LkTarget = Join-Path $Temp 'lktarget'; $LkFile = Join-Path $Temp 'lkfile.md'
    Doc (Join-Path $Lk '.projex/2609180000-root-proposal.md') 'User'
    Doc (Join-Path $LkTarget '2609180001-linked-plan.md') '2609180000-root-proposal.md'
    Doc $LkFile '2609180000-root-proposal.md'
    $LkRoot = Bytes "2609180000-root-proposal.md`n"
    $LinkDir = Join-Path $Lk '.projex/linked'
    try { New-Item -ItemType Junction -Path $LinkDir -Target $LkTarget | Out-Null } catch { }
    if ((Test-Path -LiteralPath $LinkDir) -and $null -ne (Get-Item -LiteralPath $LinkDir -Force).LinkTarget) {
        Expect 'link-dir-root' 0 $LkRoot $None @($Lk, '2609180000-root-proposal.md')
        Expect 'link-dir-target' 2 $None (Bytes "projex-tree: E_TARGET_NOT_FOUND: 2609180001-linked-plan.md: document not found`n") @($Lk, '2609180001-linked-plan.md')
    } else { Skip 'link-dir' 'link creation unsupported' }
    $LinkFile = Join-Path $Lk '.projex/2609180002-filelink-plan.md'
    try { New-Item -ItemType SymbolicLink -Path $LinkFile -Target $LkFile | Out-Null } catch { }
    if ((Test-Path -LiteralPath $LinkFile) -and $null -ne (Get-Item -LiteralPath $LinkFile -Force).LinkTarget) {
        Expect 'link-file-root' 0 $LkRoot $None @($Lk, '2609180000-root-proposal.md')
        Expect 'link-file-target' 2 $None (Bytes "projex-tree: E_TARGET_NOT_FOUND: 2609180002-filelink-plan.md: document not found`n") @($Lk, '2609180002-filelink-plan.md')
    } else { Skip 'link-file' 'link creation unsupported' }

    # unreadable document -> read failed; unenterable repository -> E_REPO
    $Rf = Join-Path $Temp 'rf'
    Doc (Join-Path $Rf '.projex/2609190000-root-proposal.md') 'User'
    $Locked = Join-Path $Rf '.projex/2609190001-locked-plan.md'
    Doc $Locked '2609190000-root-proposal.md'
    $Readable = $true
    if (Deny $Locked 'R') { try { [IO.File]::ReadAllBytes($Locked) | Out-Null } catch { $Readable = $false } }
    if (-not $Readable) {
        Expect 'read-failed' 4 $None (Bytes "projex-tree: E_IO: .projex/2609190001-locked-plan.md: read failed`n") @($Rf, '2609190000-root-proposal.md')
    } else { Skip 'read-failed' 'read denial unsupported' }
    Allow $Locked
    $Readable = $true
    if (Deny $Rf 'RX') { try { [IO.Directory]::GetFileSystemEntries($Rf) | Out-Null } catch { $Readable = $false } }
    if (-not $Readable) {
        Expect 'unenterable-repo' 2 $None (Bytes "projex-tree: E_REPO: ${Rf}: repository root not found`n") @($Rf, '2609190000-root-proposal.md')
    } else { Skip 'unenterable-repo' 'directory denial unsupported' }
    Allow $Rf

    "PASS=$Pass FAIL=$Fail"
    if ($Fail -ne 0) { exit 1 }
} finally { if (Test-Path $Temp) { Remove-Item $Temp -Recurse -Force } }
