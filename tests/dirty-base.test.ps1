# PowerShell dirty-base suite — mechanically parallel to dirty-base.test.sh, because the .ps1
# finalizers duplicate the .sh logic rather than sharing it. Every refusal case asserts non-mutation
# directly (base ref, ephemeral ref, file bytes, worktree registration); "exit 1" alone would also
# pass on a half-done close.
$S = Split-Path -Parent $PSScriptRoot
$Root = Join-Path $env:TEMP ("pxdb-" + [guid]::NewGuid().ToString('N').Substring(0,8))
$script:Pass = 0; $script:Fail = 0
function Chk($name, $got, $want) {
    if ("$got" -eq "$want") { $script:Pass++ } else { $script:Fail++; Write-Host "FAIL: $name (want '$want' got '$got')" }
}
function GitQ { git @args *>&1 | Out-Null }
function GitC { git @args }
function Sha($R, $Ref) { (git -C $R rev-parse $Ref 2>$null | Select-Object -First 1) }
function Alive($R, $Ref) { git -C $R rev-parse --verify -q $Ref 2>$null | Out-Null; if ($LASTEXITCODE -eq 0) { 'y' } else { 'n' } }
function WtReg($R, $Name) {
    if (git -C $R worktree list --porcelain | Where-Object { $_ -match ('/\.projexwt/' + [regex]::Escape($Name) + '$') }) { 'y' } else { 'n' }
}
function Merging($R) { if (Test-Path (Join-Path $R '.git/MERGE_HEAD')) { 'y' } else { 'n' } }
function Rebasing($R) {
    $g = Join-Path $R '.git/worktrees/eph'
    if ((Test-Path (Join-Path $g 'rebase-merge')) -or (Test-Path (Join-Path $g 'rebase-apply'))) { 'y' } else { 'n' }
}
function Body($p) { ((Get-Content $p) -join '') }
function Porcelain($R) { (@(git -C $R status --porcelain) -join '') }
function GatedDirt($R) { (@(git -C $R status --porcelain --untracked-files=no --ignore-submodules=dirty) -join '') }

# $Mode selects how main has moved on since the branch point: 0 not at all, 1 conflicting edit to
# a.txt, 2 an unrelated commit so a rebase really replays and rewrites the ephemeral SHAs. Mode 2 is
# what makes the rebase collision case reproduce the pre-fix bug — without an advanced base the
# rebase is a no-op and the ephemeral ref never moves anyway.
function MkPx($Name, $Mode = 0) {
    $R = Join-Path $Root $Name
    New-Item -ItemType Directory -Force $R | Out-Null
    GitQ -C $R init -q -b main
    'v0' | Set-Content (Join-Path $R 'a.txt')
    GitQ -C $R add a.txt
    GitQ -C $R -c user.email=t@t -c user.name=t commit -qm init
    GitQ -C $R branch projex/eph
    Add-Content (Join-Path $R '.git/info/exclude') '.projexwt/'   # projex-worktree.ps1 does this
    $W = Join-Path $R '.projexwt\eph'
    GitQ -C $R worktree add -q $W projex/eph
    'eph' | Set-Content (Join-Path $W 'a.txt'); 'new' | Set-Content (Join-Path $W 'new.txt')
    GitQ -C $W add a.txt new.txt
    GitQ -C $W -c user.email=t@t -c user.name=t commit -qm eph
    if ($Mode -eq 1) {
        'base' | Set-Content (Join-Path $R 'a.txt'); GitQ -C $R add a.txt
        GitQ -C $R -c user.email=t@t -c user.name=t commit -qm base
    } elseif ($Mode -eq 2) {
        'unrelated' | Set-Content (Join-Path $R 'b.txt'); GitQ -C $R add b.txt
        GitQ -C $R -c user.email=t@t -c user.name=t commit -qm advance
    }
    return $R
}

# Normalises the differing argument shapes; leaves $LASTEXITCODE for the caller to capture.
function Invoke-Close($t, $R, $B) {
    switch ($t) {
        'merge'  { & "$S\projex-merge-close.ps1"  $R $B projex/eph "msg" -Worktree *>&1 | Out-Null }
        'squash' { & "$S\projex-squash-close.ps1" $R $B projex/eph "msg" -Worktree *>&1 | Out-Null }
        'rebase' { & "$S\projex-rebase-close.ps1" $R $B projex/eph -Worktree *>&1 | Out-Null }
    }
}

Write-Host '--- tracked changes in the integration checkout block every close type'
foreach ($kind in @('unstaged', 'staged')) {
    foreach ($t in @('merge', 'rebase', 'squash')) {
        $R = MkPx "d-$kind-$t"; $b0 = Sha $R main; $e0 = Sha $R projex/eph
        'PRECIOUS' | Set-Content (Join-Path $R 'a.txt')
        if ($kind -eq 'staged') { GitQ -C $R add a.txt }
        Invoke-Close $t $R main; $rc = $LASTEXITCODE
        Chk "$t $kind exit" $rc 1
        Chk "$t $kind edit survives" (Body (Join-Path $R 'a.txt')) 'PRECIOUS'
        Chk "$t $kind base unmoved" (Sha $R main) $b0
        Chk "$t $kind ephemeral unmoved" (Sha $R projex/eph) $e0
        Chk "$t $kind worktree still registered" (WtReg $R 'eph') 'y'
        Chk "$t $kind no merge started" (Merging $R) 'n'
        Chk "$t $kind no rebase started" (Rebasing $R) 'n'
    }
}

Write-Host '--- unrelated untracked content at the integration checkout does not block'
foreach ($t in @('merge', 'rebase', 'squash')) {
    $R = MkPx "u-$t"
    'bystander' | Set-Content (Join-Path $R 'keep.txt')
    Invoke-Close $t $R main; $rc = $LASTEXITCODE
    Chk "$t bystander exit" $rc 0
    Chk "$t bystander survives byte-for-byte" (Body (Join-Path $R 'keep.txt')) 'bystander'
    Chk "$t bystander close landed" ((git -C $R show main:new.txt) -join '') 'new'
    Chk "$t bystander branch deleted" (Alive $R projex/eph) 'n'
}

Write-Host '--- an untracked path the ephemeral branch adds as tracked fails before ANY mutation'
foreach ($t in @('merge', 'rebase', 'squash')) {
    $R = MkPx "c-$t" 2; $b0 = Sha $R main; $e0 = Sha $R projex/eph
    'squatter' | Set-Content (Join-Path $R 'new.txt')
    Invoke-Close $t $R main; $rc = $LASTEXITCODE
    Chk "$t collision exit" $rc 1
    Chk "$t collision no overwrite" (Body (Join-Path $R 'new.txt')) 'squatter'
    Chk "$t collision base unmoved" (Sha $R main) $b0
    Chk "$t collision ephemeral tip unmoved" (Sha $R projex/eph) $e0
    Chk "$t collision worktree still registered" (WtReg $R 'eph') 'y'
}

Write-Host '--- a dirty submodule alone must not block close'
$Sub = Join-Path $Root 'subsrc'
New-Item -ItemType Directory -Force $Sub | Out-Null
GitQ -C $Sub init -q -b main
's0' | Set-Content (Join-Path $Sub 'f.txt'); GitQ -C $Sub add f.txt
GitQ -C $Sub -c user.email=t@t -c user.name=t commit -qm s0
$SubUrl = ($Sub -replace '\\', '/')
foreach ($t in @('merge', 'rebase', 'squash')) {
    $R = Join-Path $Root "sm-$t"
    New-Item -ItemType Directory -Force $R | Out-Null
    GitQ -C $R init -q -b main
    'v0' | Set-Content (Join-Path $R 'a.txt'); GitQ -C $R add a.txt
    GitQ -C $R -c user.email=t@t -c user.name=t commit -qm init
    GitQ -C $R -c protocol.file.allow=always -c user.email=t@t -c user.name=t submodule add -q $SubUrl sub
    GitQ -C $R add .gitmodules sub
    GitQ -C $R -c user.email=t@t -c user.name=t commit -qm addsub
    GitQ -C $R branch projex/eph
    Add-Content (Join-Path $R '.git/info/exclude') '.projexwt/'
    $W = Join-Path $R '.projexwt\eph'
    GitQ -C $R worktree add -q $W projex/eph
    'new' | Set-Content (Join-Path $W 'new.txt'); GitQ -C $W add new.txt
    GitQ -C $W -c user.email=t@t -c user.name=t commit -qm eph
    'DIRTY' | Set-Content (Join-Path $R 'sub\f.txt')   # dirty content, recorded commit unchanged
    Chk "$t submodule dirt invisible to gate" (GatedDirt $R) ''
    Invoke-Close $t $R main; $rc = $LASTEXITCODE
    Chk "$t submodule dirt does not block" $rc 0
    Chk "$t submodule dirt preserved" (Body (Join-Path $R 'sub\f.txt')) 'DIRTY'
}

Write-Host '--- conflicted squash rolls back to a clean pre-merge state, no hard reset'
$R = MkPx 's-conf' 1; $b0 = Sha $R main; $e0 = Sha $R projex/eph
$out = (& "$S\projex-squash-close.ps1" $R main projex/eph "msg" -Worktree *>&1 | Out-String)
$rc = $LASTEXITCODE
Chk 'squash conflict exit' $rc 1
Chk 'squash conflict base unmoved' (Sha $R main) $b0
Chk 'squash conflict ephemeral kept' (Sha $R projex/eph) $e0
Chk 'squash conflict checkout clean' (Porcelain $R) ''
Chk 'squash conflict base content restored' (Body (Join-Path $R 'a.txt')) 'base'
Chk 'squash conflict branch survives' (Alive $R projex/eph) 'y'
Chk 'squash conflict worktree survives' (WtReg $R 'eph') 'y'
Chk 'squash conflict reports safe rollback' ([bool]($out -match 'rolled back to a clean pre-merge state')) $true
Chk 'squash conflict never claims a hard reset' ([bool]($out -match 'reset --hard')) $false

# The rollback-FAILURE branch of Invoke-SafeRollback is not constructible as a deterministic
# regression case; it is reachable only through the documented gate->merge window. The tracked-clean
# gate plus the in-progress gate leave the tree tracked-clean when `merge --squash` runs, but nothing
# re-checks in between: a concurrent writer leaving a tracked file at index != HEAD != worktree makes
# the merge refuse pre-mutation AND `reset --merge HEAD` fail. A test cannot pre-seed that state
# because the gate rejects it up front. See the execution log for the five constructions attempted.
# The closest reachable case is the documented gate hole below, which exercises the rollback on a
# tree the merge refused to touch.
Write-Host '--- known hole: skip-worktree dirt is invisible to the gate; merge refuses pre-mutation'
$R = MkPx 's-skip'; $b0 = Sha $R main; $e0 = Sha $R projex/eph
'LOCAL' | Set-Content (Join-Path $R 'a.txt')
GitQ -C $R update-index --skip-worktree a.txt
Chk 'skip-worktree invisible to gate' (GatedDirt $R) ''
& "$S\projex-squash-close.ps1" $R main projex/eph "msg" -Worktree *>&1 | Out-Null
Chk 'skip-worktree squash exit' $LASTEXITCODE 1
Chk 'skip-worktree local content survives rollback' (Body (Join-Path $R 'a.txt')) 'LOCAL'
Chk 'skip-worktree base unmoved' (Sha $R main) $b0
Chk 'skip-worktree ephemeral kept' (Sha $R projex/eph) $e0

Write-Host '--- happy path retained for every close type'
foreach ($t in @('merge', 'rebase', 'squash')) {
    $R = MkPx "h-$t"
    Invoke-Close $t $R main; $rc = $LASTEXITCODE
    Chk "$t happy exit" $rc 0
    Chk "$t happy base updated" ((git -C $R show main:new.txt) -join '') 'new'
    Chk "$t happy branch deleted" (Alive $R projex/eph) 'n'
    Chk "$t happy worktree unregistered" (WtReg $R 'eph') 'n'
}

Write-Host '--- Base must resolve to a local branch'
$R = MkPx 'nb'; $b0 = Sha $R main; $e0 = Sha $R projex/eph
GitQ -C $R tag v1
GitQ -C $R update-ref refs/remotes/origin/main $b0
foreach ($ref in @('v1', 'origin/main', $b0)) {
    $label = if ($ref -eq $b0) { 'raw-sha' } else { $ref }
    foreach ($t in @('merge', 'rebase', 'squash')) {
        Invoke-Close $t $R $ref
        Chk "$t base=$label exit" $LASTEXITCODE 1
    }
    Chk "base=$label base unmoved" (Sha $R main) $b0
    Chk "base=$label ephemeral unmoved" (Sha $R projex/eph) $e0
}

Write-Host '--- the integration checkout must still have Base checked out'
$R = MkPx 'mm'; $b0 = Sha $R main; $e0 = Sha $R projex/eph
GitQ -C $R checkout -qb sidebranch
foreach ($t in @('merge', 'rebase', 'squash')) {
    Invoke-Close $t $R main
    Chk "$t mismatched origin exit" $LASTEXITCODE 1
}
Chk 'mismatched origin base unmoved' (Sha $R main) $b0
Chk 'mismatched origin ephemeral unmoved' (Sha $R projex/eph) $e0
Chk 'mismatched origin worktree kept' (WtReg $R 'eph') 'y'

$R = MkPx 'det'; $b0 = Sha $R main; $e0 = Sha $R projex/eph
GitQ -C $R checkout -q --detach
foreach ($t in @('merge', 'rebase', 'squash')) {
    Invoke-Close $t $R main
    Chk "$t detached origin exit" $LASTEXITCODE 1
}
Chk 'detached origin base unmoved' (Sha $R main) $b0
Chk 'detached origin ephemeral unmoved' (Sha $R projex/eph) $e0

Write-Host '--- a child closes into its recorded parent worktree/branch, never main'
$R = Join-Path $Root 'nest'
New-Item -ItemType Directory -Force $R | Out-Null
GitQ -C $R init -q -b main
'v0' | Set-Content (Join-Path $R 'a.txt'); GitQ -C $R add a.txt
GitQ -C $R -c user.email=t@t -c user.name=t commit -qm init
$main0 = Sha $R main
Add-Content (Join-Path $R '.git/info/exclude') '.projexwt/'
GitQ -C $R branch projex/outer
$O = Join-Path $R '.projexwt\outer'
GitQ -C $R worktree add -q $O projex/outer
'outer' | Set-Content (Join-Path $O 'o.txt'); GitQ -C $O add o.txt
GitQ -C $O -c user.email=t@t -c user.name=t commit -qm outer
GitQ -C $R branch projex/inner projex/outer
$I = Join-Path $O '.projexwt\inner'
GitQ -C $O worktree add -q $I projex/inner
'inner' | Set-Content (Join-Path $I 'i.txt'); GitQ -C $I add i.txt
GitQ -C $I -c user.email=t@t -c user.name=t commit -qm inner
& "$S\projex-squash-close.ps1" $O projex/outer projex/inner "msg" -Worktree *>&1 | Out-Null
Chk 'nested close exit' $LASTEXITCODE 0
Chk 'nested parent got the child content' ((git -C $R show projex/outer:i.txt) -join '') 'inner'
Chk 'nested main untouched' (Sha $R main) $main0
Chk 'nested child branch deleted' (Alive $R projex/inner) 'n'
Chk 'nested child worktree unregistered' (WtReg $R 'inner') 'n'

# Same topology, but the recorded parent worktree is dirty: the gate must fire against THAT
# worktree, not the primary one, and must not fall back to main.
$R2 = Join-Path $Root 'nest2'
New-Item -ItemType Directory -Force $R2 | Out-Null
GitQ -C $R2 init -q -b main
'v0' | Set-Content (Join-Path $R2 'a.txt'); GitQ -C $R2 add a.txt
GitQ -C $R2 -c user.email=t@t -c user.name=t commit -qm init
Add-Content (Join-Path $R2 '.git/info/exclude') '.projexwt/'
GitQ -C $R2 branch projex/outer
$O2 = Join-Path $R2 '.projexwt\outer'
GitQ -C $R2 worktree add -q $O2 projex/outer
'outer' | Set-Content (Join-Path $O2 'o.txt'); GitQ -C $O2 add o.txt
GitQ -C $O2 -c user.email=t@t -c user.name=t commit -qm outer
GitQ -C $R2 branch projex/inner projex/outer
$I2 = Join-Path $O2 '.projexwt\inner'
GitQ -C $O2 worktree add -q $I2 projex/inner
'inner' | Set-Content (Join-Path $I2 'i.txt'); GitQ -C $I2 add i.txt
GitQ -C $I2 -c user.email=t@t -c user.name=t commit -qm inner
$outer0 = Sha $R2 projex/outer; $inner0 = Sha $R2 projex/inner
'PRECIOUS' | Set-Content (Join-Path $O2 'o.txt')      # dirty the recorded PARENT worktree
& "$S\projex-squash-close.ps1" $O2 projex/outer projex/inner "msg" -Worktree *>&1 | Out-Null
Chk 'nested dirty parent exit' $LASTEXITCODE 1
Chk 'nested dirty parent edit survives' (Body (Join-Path $O2 'o.txt')) 'PRECIOUS'
Chk 'nested dirty parent ref unmoved' (Sha $R2 projex/outer) $outer0
Chk 'nested dirty parent child unmoved' (Sha $R2 projex/inner) $inner0

Write-Host "PASS=$script:Pass FAIL=$script:Fail"
Remove-Item -Recurse -Force $Root -ErrorAction SilentlyContinue
if ($script:Fail -gt 0) { exit 1 } else { exit 0 }
