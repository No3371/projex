# PowerShell worktree-mode suite — the one path the bash suites could not cover for the .ps1 variants.
$S = Split-Path -Parent $PSScriptRoot
$Root = Join-Path $env:TEMP ("pxwt-" + [guid]::NewGuid().ToString('N').Substring(0,8))
$script:Pass = 0; $script:Fail = 0
function Chk($name, $got, $want) {
    if ("$got" -eq "$want") { $script:Pass++ } else { $script:Fail++; Write-Host "FAIL: $name (want '$want' got '$got')" }
}
function GitQ { git @args *>&1 | Out-Null }
function MkWt($name, $conflictSrc) {
    $R = Join-Path $Root $name
    New-Item -ItemType Directory -Force (Join-Path $R '.projex') | Out-Null
    GitQ -C $R init -q -b main
    'v0' | Set-Content (Join-Path $R '.projex/doc.md'); 's0' | Set-Content (Join-Path $R 'src.txt')
    GitQ -C $R add .projex/doc.md src.txt
    GitQ -C $R -c user.email=t@t -c user.name=t commit -qm init
    GitQ -C $R branch projex/eph
    Add-Content (Join-Path $R '.git/info/exclude') '.projexwt/'   # projex-worktree.ps1 does this
    $W = Join-Path $R '.projexwt\eph'
    GitQ -C $R worktree add -q $W projex/eph
    'eph' | Set-Content (Join-Path $W '.projex/doc.md')
    if ($conflictSrc) { 'eph' | Set-Content (Join-Path $W 'src.txt') }
    GitQ -C $W add .projex/doc.md src.txt
    GitQ -C $W -c user.email=t@t -c user.name=t commit -qm eph
    'base' | Set-Content (Join-Path $R '.projex/doc.md')
    if ($conflictSrc) { 'base' | Set-Content (Join-Path $R 'src.txt') }
    GitQ -C $R add .projex/doc.md src.txt
    GitQ -C $R -c user.email=t@t -c user.name=t commit -qm base
    return $R
}
function WtExists($R) { if (Test-Path (Join-Path $R '.projexwt\eph')) { 'y' } else { 'n' } }
function RebaseInFlight($R) {
    $g = Join-Path $R '.git/worktrees/eph'
    if ((Test-Path (Join-Path $g 'rebase-merge')) -or (Test-Path (Join-Path $g 'rebase-apply'))) { 'y' } else { 'n' }
}
function MergeInFlight($R) { if (Test-Path (Join-Path $R '.git/MERGE_HEAD')) { 'y' } else { 'n' } }
function EphAlive($R) { git -C $R rev-parse --verify -q projex/eph 2>$null | Out-Null; if ($LASTEXITCODE -eq 0) { 'y' } else { 'n' } }
function Unmerged($R) { (@(git -C $R diff --name-only --diff-filter=U) -join ',') }

Write-Host '--- merge -Worktree'
$R = MkWt 'm-cov' $false
& "$S\projex-merge-close.ps1" $R main projex/eph "msg" -Worktree -ResolveConflicts '.projex/' *>&1 | Out-Null
Chk 'psw merge covered exit' $LASTEXITCODE 2
Chk 'psw merge covered MERGE_HEAD kept' (MergeInFlight $R) 'y'
Chk 'psw merge covered worktree intact' (WtExists $R) 'y'
Chk 'psw merge covered branch kept' (EphAlive $R) 'y'
& "$S\projex-merge-close.ps1" $R main projex/eph "msg" -Worktree -ResolveConflicts '.projex/' *>&1 | Out-Null
Chk 'psw merge bare re-run refuses' $LASTEXITCODE 1
Chk 'psw merge bare re-run preserves merge' (MergeInFlight $R) 'y'
'r' | Set-Content (Join-Path $R '.projex/doc.md'); GitQ -C $R add .projex/doc.md
GitQ -C $R -c user.email=t@t -c user.name=t commit -q --no-edit
& "$S\projex-merge-close.ps1" $R main projex/eph "msg" -Worktree -ResolveConflicts '.projex/' *>&1 | Out-Null
Chk 'psw merge resume closes' $LASTEXITCODE 0
Chk 'psw merge resume branch gone' (EphAlive $R) 'n'
Chk 'psw merge resume worktree removed' (WtExists $R) 'n'
Chk 'psw merge resume content' ((git -C $R show main:.projex/doc.md) -join '') 'r'

$R = MkWt 'm-unc' $true
$out = & "$S\projex-merge-close.ps1" $R main projex/eph "msg" -Worktree -ResolveConflicts '.projex/' *>&1
Chk 'psw merge uncovered exit' $LASTEXITCODE 1
Chk 'psw merge uncovered aborted' (MergeInFlight $R) 'n'
Chk 'psw merge uncovered worktree kept' (WtExists $R) 'y'
Chk 'psw merge uncovered names src only' ([bool](($out | Out-String) -match 'Unanticipated conflicts:[\s\S]*src\.txt')) $true

Write-Host '--- rebase -Worktree (gate must target the worktree dir, not the repo root)'
$R = MkWt 'r-cov' $false
$out = & "$S\projex-rebase-close.ps1" $R main projex/eph -Worktree -ResolveConflicts '.projex/' *>&1
Chk 'psw rebase covered exit' $LASTEXITCODE 2
Chk 'psw rebase in progress in worktree' (RebaseInFlight $R) 'y'
Chk 'psw rebase msg points at worktree' ([bool](($out | Out-String) -match [regex]::Escape('.projexwt\eph') + ' rebase --continue')) $true
& "$S\projex-rebase-close.ps1" $R main projex/eph -Worktree -ResolveConflicts '.projex/' *>&1 | Out-Null
Chk 'psw rebase mid-flight re-run refuses' $LASTEXITCODE 1
Chk 'psw rebase mid-flight NOT aborted' (RebaseInFlight $R) 'y'
'r' | Set-Content (Join-Path $R '.projexwt\eph\.projex\doc.md')
GitQ -C (Join-Path $R '.projexwt\eph') add .projex/doc.md
$env:GIT_EDITOR = 'true'
GitQ -C (Join-Path $R '.projexwt\eph') -c user.email=t@t -c user.name=t rebase --continue
& "$S\projex-rebase-close.ps1" $R main projex/eph -Worktree -ResolveConflicts '.projex/' *>&1 | Out-Null
Chk 'psw rebase resume closes' $LASTEXITCODE 0
Chk 'psw rebase resume branch gone' (EphAlive $R) 'n'
Chk 'psw rebase resume worktree removed' (WtExists $R) 'n'
Chk 'psw rebase resume content' ((git -C $R show main:.projex/doc.md) -join '') 'r'
Chk 'psw rebase resume linear (no merge commit)' ((git -C $R log --merges --oneline) -join '') ''

$R = MkWt 'r-unc' $true
& "$S\projex-rebase-close.ps1" $R main projex/eph -Worktree -ResolveConflicts '.projex/' *>&1 | Out-Null
Chk 'psw rebase uncovered exit' $LASTEXITCODE 1
Chk 'psw rebase uncovered aborted' (RebaseInFlight $R) 'n'
Chk 'psw rebase uncovered worktree kept' (WtExists $R) 'y'
Chk 'psw rebase uncovered branch kept' (EphAlive $R) 'y'

Write-Host '--- squash -Worktree'
$R = MkWt 's-cov' $false
$out = & "$S\projex-squash-close.ps1" $R main projex/eph "msg" -Worktree -ResolveConflicts '.projex/' *>&1
Chk 'psw squash covered exit' $LASTEXITCODE 2
Chk 'psw squash covered unmerged kept' (Unmerged $R) '.projex/doc.md'
Chk 'psw squash covered worktree intact' (WtExists $R) 'y'
Chk 'psw squash finish cmds include worktree remove' ([bool](($out | Out-String) -match 'worktree remove')) $true
Chk 'psw squash warns against re-run' ([bool](($out | Out-String) -match 'Do NOT re-run')) $true

$R = MkWt 's-unc' $true
& "$S\projex-squash-close.ps1" $R main projex/eph "msg" -Worktree -ResolveConflicts '.projex/' *>&1 | Out-Null
Chk 'psw squash uncovered exit' $LASTEXITCODE 1
Chk 'psw squash uncovered clean' ((@(git -C $R status --porcelain) -join '')) ''
Chk 'psw squash uncovered worktree kept' (WtExists $R) 'y'

Write-Host '--- dirty worktree blocks before anything is attempted'
$R = MkWt 'dirty' $false
'scratch' | Set-Content (Join-Path $R '.projexwt\eph\untracked.txt')
& "$S\projex-merge-close.ps1" $R main projex/eph "msg" -Worktree -ResolveConflicts '.projex/' *>&1 | Out-Null
Chk 'psw dirty worktree refuses' $LASTEXITCODE 1
Chk 'psw dirty no merge started' (MergeInFlight $R) 'n'
Chk 'psw dirty file preserved' ((Get-Content (Join-Path $R '.projexwt\eph\untracked.txt')) -join '') 'scratch'

Write-Host "PASS=$script:Pass FAIL=$script:Fail"
Remove-Item -Recurse -Force $Root -ErrorAction SilentlyContinue
if ($script:Fail -gt 0) { exit 1 } else { exit 0 }
