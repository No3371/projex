# close-precheck.ps1 — report-only close-context preflight
# Usage: close-precheck.ps1 [-PlanFile <plan-file>]

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$PlanFile
)

$ErrorActionPreference = 'Stop'
$MaxOutput = 8MB
$Report = New-Object 'System.Collections.Generic.List[string]'
$ReportBytes = 0

function Encode-Value {
    param([AllowNull()][string]$Value)
    if ($null -eq $Value) { $Value = '' }
    $builder = New-Object System.Text.StringBuilder
    foreach ($byte in [System.Text.Encoding]::UTF8.GetBytes($Value)) {
        if (($byte -ge 0x30 -and $byte -le 0x39) -or
            ($byte -ge 0x41 -and $byte -le 0x5A) -or
            ($byte -ge 0x61 -and $byte -le 0x7A) -or
            $byte -in @(0x2D, 0x2E, 0x5F, 0x7E)) {
            [void]$builder.Append([char]$byte)
        } else {
            [void]$builder.Append(('%{0:X2}' -f $byte))
        }
    }
    $builder.ToString()
}

function Emit {
    param([string]$Line)
    $bytes = [System.Text.Encoding]::UTF8.GetByteCount($Line) + 1
    if (($script:ReportBytes + $bytes) -gt $MaxOutput) { throw '__REPORT_BUDGET__' }
    [void]$script:Report.Add($Line)
    $script:ReportBytes += $bytes
}

function Strip-TrailingSeparators {
    param([string]$Path)
    $root = [IO.Path]::GetPathRoot($Path)
    if ($root -and $Path.Equals($root, [StringComparison]::OrdinalIgnoreCase)) { return $root }
    $Path.TrimEnd('\', '/')
}

function Is-Under {
    param([string]$Child, [string]$Parent)
    $childFull = Strip-TrailingSeparators $Child
    $parentFull = Strip-TrailingSeparators $Parent
    if ($parentFull.EndsWith([IO.Path]::DirectorySeparatorChar) -or $parentFull.EndsWith([IO.Path]::AltDirectorySeparatorChar)) {
        $prefix = $parentFull
    } else {
        $prefix = $parentFull + [IO.Path]::DirectorySeparatorChar
    }
    return $childFull.Equals($parentFull, [StringComparison]::OrdinalIgnoreCase) -or
        $childFull.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)
}

function Canonical-Path {
    param([string]$Path, [switch]$Directory)
    $item = Get-Item -LiteralPath $Path -ErrorAction Stop
    if ($Directory -and -not $item.PSIsContainer) { throw 'expected directory path' }
    if (-not $Directory -and $item.PSIsContainer) { throw 'expected file path' }
    Strip-TrailingSeparators $item.FullName
}

function Relative-To {
    param([string]$Path, [string]$Root)
    if (-not (Is-Under $Path $Root)) { throw 'path is outside repository root' }
    $rootFull = Strip-TrailingSeparators $Root
    if ($Path.Equals($rootFull, [StringComparison]::OrdinalIgnoreCase) -or $Path.Equals($Root, [StringComparison]::OrdinalIgnoreCase)) { return '' }
    $prefixLength = if ($rootFull.EndsWith([IO.Path]::DirectorySeparatorChar) -or $rootFull.EndsWith([IO.Path]::AltDirectorySeparatorChar)) { $rootFull.Length } else { $rootFull.Length + 1 }
    $Path.Substring($prefixLength).Replace('\', '/')
}

function Invoke-Git {
    param(
        [Parameter(Mandatory)][string]$Directory,
        [Parameter(Mandatory)][string[]]$Arguments
    )
    $result = @(& git -C $Directory @Arguments 2>$null)
    if ($LASTEXITCODE -ne 0) { throw ('git read failed: ' + ($Arguments -join ' ')) }
    $result
}

function Git-One {
    param([string]$Directory, [string[]]$Arguments)
    $lines = @(Invoke-Git -Directory $Directory -Arguments $Arguments)
    if ($lines.Count -ne 1 -or [string]::IsNullOrEmpty([string]$lines[0])) { throw 'expected one Git value' }
    [string]$lines[0]
}

function Git-CommonDir {
    param([string]$Directory)
    $raw = Git-One -Directory $Directory -Arguments @('rev-parse', '--git-common-dir')
    if ([IO.Path]::IsPathRooted($raw)) { Canonical-Path -Path $raw -Directory } else { Canonical-Path -Path ([IO.Path]::Combine($Directory, $raw)) -Directory }
}

function Parse-Header {
    param([string[]]$Lines, [string]$Name, [switch]$Optional)
    $prefix = '> **' + $Name + ':**'
    $values = @()
    foreach ($line in $Lines) {
        if ($line.StartsWith($prefix, [StringComparison]::Ordinal)) {
            if (-not $line.StartsWith($prefix + ' ', [StringComparison]::Ordinal)) { throw ('malformed ' + $Name + ' header') }
            $values += $line.Substring(($prefix + ' ').Length)
        }
    }
    if (-not $Optional -and $values.Count -ne 1) { throw ('execution log must contain exactly one ' + $Name + ' header') }
    if ($Optional -and $values.Count -gt 1) { throw ('duplicate ' + $Name + ' header') }
    if ($values.Count -eq 0) { return $null }
    if ([string]::IsNullOrEmpty($values[0])) { throw ('empty ' + $Name + ' header') }
    [string]$values[0]
}

function Parse-Plan-Log {
    param([string[]]$Lines)
    $prefix = '> **Log:**'
    $values = @()
    foreach ($line in $Lines) {
        if ($line.StartsWith($prefix, [StringComparison]::Ordinal)) {
            if (-not $line.StartsWith($prefix + ' ', [StringComparison]::Ordinal)) { throw 'malformed Log header in plan' }
            $values += $line.Substring(($prefix + ' ').Length)
        }
    }
    if ($values.Count -gt 1) { throw 'duplicate Log header in plan' }
    if ($values.Count -eq 0) { return $null }
    if ([string]::IsNullOrEmpty($values[0])) { throw 'empty Log header in plan' }
    $values[0]
}

function Get-WorktreeRecords {
    param([string[]]$Lines)
    $records = @()
    $current = $null
    foreach ($line in $Lines) {
        if ($line.StartsWith('worktree ', [StringComparison]::Ordinal)) {
            if ($null -ne $current) { $records += $current }
            $current = [ordered]@{ Path = $line.Substring(9); Head = ''; Branch = '' }
        } elseif ($null -ne $current -and $line.StartsWith('HEAD ', [StringComparison]::Ordinal)) {
            $current.Head = $line.Substring(5)
        } elseif ($null -ne $current -and $line.StartsWith('branch ', [StringComparison]::Ordinal)) {
            $current.Branch = $line.Substring(7)
        }
    }
    if ($null -ne $current) { $records += $current }
    $records
}

function Get-Status-Value {
    param([string]$Path)
    foreach ($line in (Get-Content -LiteralPath $Path)) {
        if ($line.StartsWith('> **Status:** ', [StringComparison]::Ordinal)) { return $line.Substring(14) }
    }
    'MISSING'
}

function Add-Inventory-Candidates {
    param([string]$Root, [string]$Location, [hashtable]$Inventory, [string]$PlanBase, [string]$PlanPath, [string]$LogPath, [string]$ChildRoot)
    $files = @(Get-ChildItem -LiteralPath $Root -Recurse -File -Filter '*.md' -ErrorAction Stop)
    foreach ($item in $files) {
        $full = $item.FullName
        $normalized = $full.Replace('\', '/')
        if ($normalized -match '/\.git/' -or $normalized -match '/\.projexwt/') { continue }
        if ($normalized -notmatch '/\.projex/') { continue }
        $canonical = Canonical-Path -Path $full
        if ($Location -eq 'ORIGIN') {
            if (-not (Is-Under $canonical $REPO_ROOT)) { throw 'origin inventory symlink escapes Repo Root' }
            $relative = Relative-To -Path $canonical -Root $REPO_ROOT
        } else {
            if (-not (Is-Under $canonical $ChildRoot)) { throw 'child inventory symlink escapes Worktree Path' }
            $relative = Relative-To -Path $canonical -Root $ChildRoot
        }
        $content = Get-Content -LiteralPath $canonical -Raw
        if ($content.IndexOf($PlanBase, [StringComparison]::Ordinal) -ge 0 -or $canonical.Equals($PlanPath, [StringComparison]::OrdinalIgnoreCase) -or $canonical.Equals($LogPath, [StringComparison]::OrdinalIgnoreCase)) {
            # CHILD is deterministic precedence for a path present in both roots.
            $Inventory[$relative] = $Location
        }
    }
}

try {
    if ($PlanFile) {
        $planPath = Canonical-Path -Path $PlanFile
    } else {
        $callerRoot = Canonical-Path -Path (Git-One -Directory (Get-Location).Path -Arguments @('rev-parse', '--show-toplevel')) -Directory
        $currentBranch = Git-One -Directory $callerRoot -Arguments @('branch', '--show-current')
        if (-not $currentBranch.StartsWith('projex/', [StringComparison]::Ordinal)) { throw 'no-argument inference requires a projex/* branch' }
        $branchSuffix = $currentBranch.Substring(6)
        if ($branchSuffix -match '^\d{10}-(.*)$') { $branchName = $Matches[1] } else { $branchName = $branchSuffix }
        $matches = @(Get-ChildItem -LiteralPath $callerRoot -Recurse -File -Filter '*-plan.md' -ErrorAction Stop | Where-Object {
            $p = $_.FullName.Replace('\', '/')
            $p -notmatch '/\.git/' -and $p -notmatch '/\.projexwt/' -and
            $p -match '/\.projex/' -and $_.Name -match '^\d{10}-(.*-plan)\.md$' -and $Matches[1] -eq $branchName
        })
        if ($matches.Count -ne 1) { throw 'no-argument plan inference is missing or ambiguous' }
        $planPath = Canonical-Path -Path $matches[0].FullName
    }

    $planDir = Split-Path -LiteralPath $planPath -Parent
    $planBase = Split-Path -LiteralPath $planPath -Leaf
    $planRepo = Canonical-Path -Path (Git-One -Directory $planDir -Arguments @('rev-parse', '--show-toplevel')) -Directory
    $planCommon = Git-CommonDir -Directory $planDir
    $planLines = @(Get-Content -LiteralPath $planPath)
    $logPointer = Parse-Plan-Log -Lines $planLines
    if ($logPointer) {
        if ([IO.Path]::IsPathRooted($logPointer) -or $logPointer.Contains('/') -or $logPointer.Contains('\') -or $logPointer.Contains('..')) { throw 'Log header must name a sibling filename' }
        $logPath = Canonical-Path -Path ([IO.Path]::Combine($planDir, $logPointer))
    } else {
        $logPath = Canonical-Path -Path ([IO.Path]::Combine($planDir, ($planBase.Substring(0, $planBase.Length - 3) + '-log.md')))
    }
    $logCommon = Git-CommonDir -Directory (Split-Path -LiteralPath $logPath -Parent)
    if ($logCommon -ne $planCommon) { throw 'plan and execution log are not in the same repository' }

    $logLines = @(Get-Content -LiteralPath $logPath)
    $recordedRootRaw = Parse-Header -Lines $logLines -Name 'Repo Root'
    $baseBranch = Parse-Header -Lines $logLines -Name 'Base Branch'
    $worktreeRaw = Parse-Header -Lines $logLines -Name 'Worktree Path' -Optional
    $recordedRoot = Canonical-Path -Path $recordedRootRaw -Directory
    if (-not $recordedRoot.Equals($planRepo, [StringComparison]::OrdinalIgnoreCase) -and (Git-CommonDir -Directory $recordedRoot) -ne $planCommon) { throw 'recorded Repo Root is not the plan repository' }
    $REPO_ROOT = $recordedRoot
    if ($baseBranch -match '(^-|^refs/|\.\.|//|/$|^/)') { throw 'invalid Base Branch header' }
    $baseRef = 'refs/heads/' + $baseBranch
    $baseRefLine = @(Invoke-Git -Directory $REPO_ROOT -Arguments @('show-ref', '--verify', $baseRef))
    if ($LASTEXITCODE -ne 0 -or $baseRefLine.Count -eq 0) { throw 'Base Branch is not a local branch' }
    $baseSha = Git-One -Directory $REPO_ROOT -Arguments @('rev-parse', '--verify', $baseRef)
    $rootCurrentBranch = Git-One -Directory $REPO_ROOT -Arguments @('branch', '--show-current')
    $originHead = Git-One -Directory $REPO_ROOT -Arguments @('rev-parse', '--verify', 'HEAD')

    $worktreeMode = [bool]$worktreeRaw
    $worktreePath = $null
    $worktreeBranch = $null
    $worktreeHead = $null
    if ($worktreeMode) {
        if ([IO.Path]::IsPathRooted($worktreeRaw)) { $worktreeCandidate = $worktreeRaw } else { $worktreeCandidate = [IO.Path]::Combine($REPO_ROOT, $worktreeRaw) }
        $worktreePath = Canonical-Path -Path $worktreeCandidate -Directory
        if (-not (Is-Under $worktreePath $REPO_ROOT) -or $worktreePath.Equals($REPO_ROOT, [StringComparison]::OrdinalIgnoreCase)) { throw 'recorded Worktree Path escapes or reuses Repo Root' }
    }
    $worktreeSnapshot = @(Invoke-Git -Directory $REPO_ROOT -Arguments @('worktree', 'list', '--porcelain'))
    $worktrees = @(Get-WorktreeRecords -Lines $worktreeSnapshot)
    if ($worktreeMode) {
        $found = @($worktrees | Where-Object { (Canonical-Path -Path $_.Path -Directory).Equals($worktreePath, [StringComparison]::OrdinalIgnoreCase) })
        if ($found.Count -ne 1) { throw 'recorded Worktree Path is not uniquely registered' }
        if (-not $found[0].Branch.StartsWith('refs/heads/', [StringComparison]::Ordinal)) { throw 'recorded worktree is detached' }
        $worktreeBranch = $found[0].Branch.Substring(11)
        $worktreeHead = $found[0].Head
        if (-not $worktreeBranch.StartsWith('projex/', [StringComparison]::Ordinal)) { throw 'recorded worktree branch is not ephemeral' }
        $ephemeralBranch = $worktreeBranch
        $ephemeralSha = Git-One -Directory $REPO_ROOT -Arguments @('rev-parse', '--verify', ('refs/heads/' + $ephemeralBranch))
        if ($ephemeralSha -ne $worktreeHead) { throw 'recorded worktree HEAD does not match ephemeral branch' }
        if ($rootCurrentBranch -ne $baseBranch) { throw 'originating checkout is not on recorded Base Branch' }
        if ((Git-One -Directory $worktreePath -Arguments @('rev-parse', '--verify', 'HEAD')) -ne $worktreeHead) { throw 'recorded worktree checkout HEAD drifted' }
    } else {
        if (-not $rootCurrentBranch.StartsWith('projex/', [StringComparison]::Ordinal)) { throw 'checkout-mode execution must be on a projex/* branch' }
        $ephemeralBranch = $rootCurrentBranch
        $ephemeralSha = Git-One -Directory $REPO_ROOT -Arguments @('rev-parse', '--verify', ('refs/heads/' + $ephemeralBranch))
        if ($originHead -ne $ephemeralSha) { throw 'ephemeral checkout HEAD does not match branch' }
    }

    $planRel = Relative-To -Path $planPath -Root $REPO_ROOT
    $logRel = Relative-To -Path $logPath -Root $REPO_ROOT
    Emit 'SCHEMA_VERSION=1'
    Emit ('GENERATED_AT_UTC=' + (Encode-Value ([DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ'))))
    Emit ('REPO_ROOT=' + (Encode-Value $REPO_ROOT))
    Emit ('BASE_BRANCH=' + (Encode-Value $baseBranch))
    Emit ('EPHEMERAL_BRANCH=' + (Encode-Value $ephemeralBranch))
    Emit ('PLAN_REL=' + (Encode-Value $planRel))
    Emit ('LOG_REL=' + (Encode-Value $logRel))
    Emit ('BASE_SHA=' + (Encode-Value $baseSha))
    Emit ('EPHEMERAL_SHA=' + (Encode-Value $ephemeralSha))
    Emit ('ORIGIN_HEAD=' + (Encode-Value $originHead))
    if ($worktreeMode) {
        Emit ('WORKTREE_PATH=' + (Encode-Value $worktreePath))
        Emit ('WORKTREE_BRANCH=' + (Encode-Value $worktreeBranch))
        Emit ('WORKTREE_HEAD=' + (Encode-Value $worktreeHead))
    }

    $commits = @(Invoke-Git -Directory $REPO_ROOT -Arguments @('log', '--oneline', ($baseSha + '..' + $ephemeralSha)))
    $diff = @(Invoke-Git -Directory $REPO_ROOT -Arguments @('diff', '--stat', $baseSha, $ephemeralSha))
    $stashes = @(Invoke-Git -Directory $REPO_ROOT -Arguments @('stash', 'list'))
    $baseTree = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::Ordinal)
    $ephemeralTree = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::Ordinal)
    foreach ($path in @(Invoke-Git -Directory $REPO_ROOT -Arguments @('ls-tree', '-r', '--name-only', $baseSha))) { [void]$baseTree.Add([string]$path) }
    foreach ($path in @(Invoke-Git -Directory $REPO_ROOT -Arguments @('ls-tree', '-r', '--name-only', $ephemeralSha))) { [void]$ephemeralTree.Add([string]$path) }

    Emit 'SECTION=COMMITS'
    if ($commits.Count -eq 0) { Emit "RECORD=NONE`tCOMMITS" } else {
        foreach ($line in $commits) {
            $parts = ([string]$line) -split ' ', 2
            $subject = if ($parts.Count -eq 2) { $parts[1] } else { '' }
            Emit ("RECORD=COMMIT`t" + (Encode-Value $parts[0]) + "`t" + (Encode-Value $subject))
        }
    }
    Emit 'SECTION=DIFF_STAT'
    if ($diff.Count -eq 0) { Emit "RECORD=NONE`tDIFF_STAT" } else { foreach ($line in $diff) { Emit ("RECORD=DIFF_STAT`t" + (Encode-Value ([string]$line))) } }

    $inventory = @{}
    Add-Inventory-Candidates -Root $REPO_ROOT -Location 'ORIGIN' -Inventory $inventory -PlanBase $planBase -PlanPath $planPath -LogPath $logPath -ChildRoot $null
    if ($worktreeMode) { Add-Inventory-Candidates -Root $worktreePath -Location 'CHILD' -Inventory $inventory -PlanBase $planBase -PlanPath $planPath -LogPath $logPath -ChildRoot $worktreePath }
    Emit 'SECTION=PROJEX_INVENTORY'
    $warnings = 0
    foreach ($relative in @($inventory.Keys | Sort-Object)) {
        $location = [string]$inventory[$relative]
        $treePath = $relative
        if ($location -eq 'CHILD') { $physical = [IO.Path]::Combine($worktreePath, $relative) } else { $physical = [IO.Path]::Combine($REPO_ROOT, $relative) }
        if ($ephemeralTree.Contains($treePath)) {
            $classification = 'tracked-on-ephemeral'
            $alsoOnBase = if ($baseTree.Contains($treePath)) { 'yes' } else { 'no' }
        } elseif ($baseTree.Contains($treePath)) {
            $classification = 'tracked-on-base'
            $alsoOnBase = 'yes'
        } else {
            $classification = 'untracked'
            $alsoOnBase = 'no'
        }
        $status = if (Test-Path -LiteralPath $physical -PathType Leaf) { Get-Status-Value -Path $physical } else { 'MISSING' }
        Emit ("RECORD=PROJEX`t" + (Encode-Value $relative) + "`t$location`t$classification`t" + (Encode-Value $status) + "`t$alsoOnBase")
    }
    if ($inventory.Count -eq 0) { Emit "RECORD=NONE`tPROJEX_INVENTORY" }

    Emit 'SECTION=STASHES'
    if ($stashes.Count -eq 0) { Emit "RECORD=NONE`tSTASHES" } else { $warnings = 1; foreach ($line in $stashes) { Emit ("RECORD=STASH`t" + (Encode-Value ([string]$line))) } }
    Emit 'SECTION=GATES'
    $originStatus = @(Invoke-Git -Directory $REPO_ROOT -Arguments @('status', '--porcelain', '--untracked-files=no', '--ignore-submodules=dirty'))
    if ($originStatus.Count -gt 0) { $warnings = 1; Emit ("RECORD=GATE`tORIGIN_BASE`tWARN`t" + (Encode-Value (($originStatus -join ' ').Trim()))) } else { Emit ("RECORD=GATE`tORIGIN_BASE`tPASS`t" + (Encode-Value 'tracked checkout clean')) }
    if ($worktreeMode) {
        $childStatus = @(Invoke-Git -Directory $worktreePath -Arguments @('status', '--porcelain', '--ignored=matching'))
        if ($childStatus.Count -gt 0) { $warnings = 1; Emit ("RECORD=GATE`tCHILD_WORKTREE`tWARN`t" + (Encode-Value (($childStatus -join ' ').Trim()))) } else { Emit ("RECORD=GATE`tCHILD_WORKTREE`tPASS`t" + (Encode-Value 'worktree fully clean')) }
    } else { Emit ("RECORD=GATE`tCHILD_WORKTREE`tN/A`t" + (Encode-Value 'no recorded child worktree')) }

    $baseShaEnd = Git-One -Directory $REPO_ROOT -Arguments @('rev-parse', '--verify', ('refs/heads/' + $baseBranch))
    $ephemeralShaEnd = Git-One -Directory $REPO_ROOT -Arguments @('rev-parse', '--verify', ('refs/heads/' + $ephemeralBranch))
    $originHeadEnd = Git-One -Directory $REPO_ROOT -Arguments @('rev-parse', '--verify', 'HEAD')
    if ($baseShaEnd -ne $baseSha -or $ephemeralShaEnd -ne $ephemeralSha -or $originHeadEnd -ne $originHead) {
        Emit ('WARNING=' + (Encode-Value 'snapshot identity changed during report'))
        Emit 'RESULT=STALE'
        $Report | ForEach-Object { $_ }
        exit 1
    }
    if ($worktreeMode) {
        $worktreeSnapshotEnd = @(Invoke-Git -Directory $REPO_ROOT -Arguments @('worktree', 'list', '--porcelain'))
        if (($worktreeSnapshotEnd -join "`n") -ne ($worktreeSnapshot -join "`n")) { Emit ('WARNING=' + (Encode-Value 'worktree registration changed during report')); Emit 'RESULT=STALE'; $Report | ForEach-Object { $_ }; exit 1 }
        $endRecords = @(Get-WorktreeRecords -Lines $worktreeSnapshotEnd)
        $same = @($endRecords | Where-Object { (Canonical-Path -Path $_.Path -Directory).Equals($worktreePath, [StringComparison]::OrdinalIgnoreCase) -and $_.Branch -eq ('refs/heads/' + $ephemeralBranch) -and $_.Head -eq $ephemeralSha })
        if ($same.Count -ne 1) { Emit ('WARNING=' + (Encode-Value 'worktree registration changed during report')); Emit 'RESULT=STALE'; $Report | ForEach-Object { $_ }; exit 1 }
    }
    if ($warnings -eq 1) { Emit 'RESULT=PASS_WITH_WARNINGS' } else { Emit 'RESULT=PASS' }
    $Report | ForEach-Object { $_ }
    exit 0
} catch {
    $Report.Clear()
    $script:ReportBytes = 0
    $message = if ($_.Exception.Message -eq '__REPORT_BUDGET__') { 'report output exceeds 8 MiB budget' } else { $_.Exception.Message }
    $Report.Add('SCHEMA_VERSION=1')
    $Report.Add('ERROR=' + (Encode-Value $message))
    $Report.Add('RESULT=ERROR')
    $Report | ForEach-Object { $_ }
    exit 1
}
