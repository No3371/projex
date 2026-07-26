# PowerShell parity check for -ResolveConflicts across the three close scripts.
$S = Split-Path -Parent $PSScriptRoot
$Root = Join-Path $env:TEMP ("pxtest-" + [guid]::NewGuid().ToString('N').Substring(0,8))
$script:Pass = 0; $script:Fail = 0
function Chk($name, $got, $want) {
    if ("$got" -eq "$want") { $script:Pass++ } else { $script:Fail++; Write-Host "FAIL: $name (want '$want' got '$got')" }
}
function MkRepo($name, $conflictSrc) {
    $R = Join-Path $Root $name
    New-Item -ItemType Directory -Force (Join-Path $R '.projex') | Out-Null
    git -C $R init -q -b main
    'v0' | Set-Content (Join-Path $R '.projex/doc.md'); 's0' | Set-Content (Join-Path $R 'src.txt')
    git -C $R add .projex/doc.md src.txt | Out-Null
    git -C $R -c user.email=t@t -c user.name=t commit -qm init | Out-Null
    git -C $R checkout -qb projex/eph
    'eph' | Set-Content (Join-Path $R '.projex/doc.md'); if ($conflictSrc) { 'eph' | Set-Content (Join-Path $R 'src.txt') }
    git -C $R add .projex/doc.md src.txt | Out-Null
    git -C $R -c user.email=t@t -c user.name=t commit -qm eph | Out-Null
    git -C $R checkout -q main
    'base' | Set-Content (Join-Path $R '.projex/doc.md'); if ($conflictSrc) { 'base' | Set-Content (Join-Path $R 'src.txt') }
    git -C $R add .projex/doc.md src.txt | Out-Null
    git -C $R -c user.email=t@t -c user.name=t commit -qm base | Out-Null
    return $R
}
function Unmerged($R) { (@(git -C $R diff --name-only --diff-filter=U) -join ',') }
function EphAlive($R) { git -C $R rev-parse --verify -q projex/eph 2>$null | Out-Null; if ($LASTEXITCODE -eq 0) { 'y' } else { 'n' } }

# merge: covered -> exit 2, merge preserved; then resume by re-run
$R = MkRepo 'm-cov' $false
& "$S\projex-merge-close.ps1" $R main projex/eph "msg" -ResolveConflicts '.projex/' *>&1 | Out-Null
Chk 'ps merge covered exit' $LASTEXITCODE 2
Chk 'ps merge covered MERGE_HEAD kept' (Test-Path (Join-Path $R '.git/MERGE_HEAD')) $true
Chk 'ps merge covered unmerged' (Unmerged $R) '.projex/doc.md'
& "$S\projex-merge-close.ps1" $R main projex/eph "msg" -ResolveConflicts '.projex/' *>&1 | Out-Null
Chk 'ps merge bare re-run refuses' $LASTEXITCODE 1
Chk 'ps merge bare re-run preserves merge' (Test-Path (Join-Path $R '.git/MERGE_HEAD')) $true
'resolved' | Set-Content (Join-Path $R '.projex/doc.md'); git -C $R add .projex/doc.md | Out-Null
git -C $R -c user.email=t@t -c user.name=t commit -q --no-edit | Out-Null
& "$S\projex-merge-close.ps1" $R main projex/eph "msg" -ResolveConflicts '.projex/' *>&1 | Out-Null
Chk 'ps merge resume closes' $LASTEXITCODE 0
Chk 'ps merge resume branch gone' (EphAlive $R) 'n'

# merge: uncovered -> exit 1, aborted
$R = MkRepo 'm-unc' $true
$out = & "$S\projex-merge-close.ps1" $R main projex/eph "msg" -ResolveConflicts '.projex/' *>&1
Chk 'ps merge uncovered exit' $LASTEXITCODE 1
Chk 'ps merge uncovered aborted' (Test-Path (Join-Path $R '.git/MERGE_HEAD')) $false
Chk 'ps merge uncovered names src' ([bool](($out | Out-String) -match 'Unanticipated conflicts:[\s\S]*src\.txt')) $true
Chk 'ps merge uncovered keeps branch' (EphAlive $R) 'y'

# merge: no param -> legacy abort
$R = MkRepo 'm-noflag' $false
& "$S\projex-merge-close.ps1" $R main projex/eph "msg" *>&1 | Out-Null
Chk 'ps merge noflag exit' $LASTEXITCODE 1
Chk 'ps merge noflag aborted' (Test-Path (Join-Path $R '.git/MERGE_HEAD')) $false

# rebase: covered -> exit 2, in progress; resume
$R = MkRepo 'r-cov' $false
& "$S\projex-rebase-close.ps1" $R main projex/eph -ResolveConflicts '.projex/doc.md' *>&1 | Out-Null
Chk 'ps rebase covered exit' $LASTEXITCODE 2
Chk 'ps rebase covered in progress' ((Test-Path (Join-Path $R '.git/rebase-merge')) -or (Test-Path (Join-Path $R '.git/rebase-apply'))) $true
& "$S\projex-rebase-close.ps1" $R main projex/eph -ResolveConflicts '.projex/doc.md' *>&1 | Out-Null
Chk 'ps rebase mid-flight re-run refuses' $LASTEXITCODE 1
Chk 'ps rebase mid-flight not aborted' ((Test-Path (Join-Path $R '.git/rebase-merge')) -or (Test-Path (Join-Path $R '.git/rebase-apply'))) $true
'resolved' | Set-Content (Join-Path $R '.projex/doc.md'); git -C $R add .projex/doc.md | Out-Null
$env:GIT_EDITOR = 'true'; git -C $R -c user.email=t@t -c user.name=t rebase --continue *>&1 | Out-Null
& "$S\projex-rebase-close.ps1" $R main projex/eph -ResolveConflicts '.projex/doc.md' *>&1 | Out-Null
Chk 'ps rebase resume closes' $LASTEXITCODE 0
Chk 'ps rebase resume branch gone' (EphAlive $R) 'n'

# rebase: uncovered -> exit 1, restored
$R = MkRepo 'r-unc' $true
& "$S\projex-rebase-close.ps1" $R main projex/eph -ResolveConflicts '.projex/' *>&1 | Out-Null
Chk 'ps rebase uncovered exit' $LASTEXITCODE 1
Chk 'ps rebase uncovered aborted' ((Test-Path (Join-Path $R '.git/rebase-merge')) -or (Test-Path (Join-Path $R '.git/rebase-apply'))) $false
Chk 'ps rebase uncovered restored' (git -C $R rev-parse --abbrev-ref HEAD) 'main'

# squash: covered -> exit 2, conflicts kept; resume via commit + re-run
$R = MkRepo 's-cov' $false
& "$S\projex-squash-close.ps1" $R main projex/eph "msg" -ResolveConflicts '.projex/' *>&1 | Out-Null
Chk 'ps squash covered exit' $LASTEXITCODE 2
Chk 'ps squash covered unmerged kept' (Unmerged $R) '.projex/doc.md'
& "$S\projex-squash-close.ps1" $R main projex/eph "msg" -ResolveConflicts '.projex/' *>&1 | Out-Null
Chk 'ps squash bare re-run refuses' $LASTEXITCODE 1
Chk 'ps squash bare re-run preserves conflict' (Unmerged $R) '.projex/doc.md'
'resolved' | Set-Content (Join-Path $R '.projex/doc.md'); git -C $R add .projex/doc.md | Out-Null
git -C $R -c user.email=t@t -c user.name=t commit -qm "msg" | Out-Null
# documented: squash is NOT re-runnable — it recomputes from the same base and re-conflicts
& "$S\projex-squash-close.ps1" $R main projex/eph "msg" -ResolveConflicts '.projex/' *>&1 | Out-Null
Chk 'ps squash re-run re-conflicts (documented)' $LASTEXITCODE 2
Chk 'ps squash re-run keeps resolution commit' (git -C $R log --oneline -1 --format=%s) 'msg'
# the documented hand-finish path works
git -C $R merge --abort *>&1 | Out-Null; git -C $R reset --hard HEAD *>&1 | Out-Null
git -C $R branch -D projex/eph *>&1 | Out-Null
Chk 'ps squash hand-finish removes branch' (EphAlive $R) 'n'
Chk 'ps squash hand-finish tree clean' ((@(git -C $R status --porcelain) -join '')) ''

# squash: uncovered -> exit 1, reset clean
$R = MkRepo 's-unc' $true
& "$S\projex-squash-close.ps1" $R main projex/eph "msg" -ResolveConflicts '.projex/' *>&1 | Out-Null
Chk 'ps squash uncovered exit' $LASTEXITCODE 1
Chk 'ps squash uncovered clean' ((@(git -C $R status --porcelain) -join '')) ''

# sibling prefix (.projexwt must not match .projex)
$R = Join-Path $Root 'prefix'
New-Item -ItemType Directory -Force (Join-Path $R '.projexwt') | Out-Null
git -C $R init -q -b main
'v0' | Set-Content (Join-Path $R '.projexwt/f.md'); git -C $R add .projexwt/f.md | Out-Null
git -C $R -c user.email=t@t -c user.name=t commit -qm init | Out-Null
git -C $R checkout -qb projex/eph
'eph' | Set-Content (Join-Path $R '.projexwt/f.md'); git -C $R add .projexwt/f.md | Out-Null
git -C $R -c user.email=t@t -c user.name=t commit -qm eph | Out-Null
git -C $R checkout -q main
'base' | Set-Content (Join-Path $R '.projexwt/f.md'); git -C $R add .projexwt/f.md | Out-Null
git -C $R -c user.email=t@t -c user.name=t commit -qm base | Out-Null
& "$S\projex-merge-close.ps1" $R main projex/eph "msg" -ResolveConflicts '.projex' *>&1 | Out-Null
Chk 'ps sibling prefix not matched' $LASTEXITCODE 1

Write-Host "PASS=$script:Pass FAIL=$script:Fail"
Remove-Item -Recurse -Force $Root -ErrorAction SilentlyContinue
if ($script:Fail -gt 0) { exit 1 } else { exit 0 }
