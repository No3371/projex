# Runs every PowerShell suite. Each suite builds throwaway repos under $env:TEMP and cleans up after
# itself; nothing touches the repo you run it from.
# Usage: pwsh tests/run-all.ps1
$suites = @('resolve-conflicts.test.ps1', 'worktree.test.ps1', 'dirty-base.test.ps1', 'close-precheck.test.ps1')
$totalPass = 0
$totalFail = 0
$status = 0
$closePrecheckRuns = 0

foreach ($suite in $suites) {
    Write-Host "=== $suite"
    if ($suite -eq 'close-precheck.test.ps1') { $closePrecheckRuns++ }
    # 6>&1 folds the information stream in: suites report via Write-Host, which plain
    # capture does not collect. 2>$null drops git's CRLF/LF advisories on Windows checkouts.
    try {
        $out = @(& (Join-Path $PSScriptRoot $suite) 6>&1 2>$null)
        $suiteStatus = $LASTEXITCODE
    } catch {
        $out = @()
        $suiteStatus = 1
    }
    $out | Select-String -Pattern '^FAIL|^PASS=|NOT RUN' | ForEach-Object { Write-Host $_.Line }
    $summaries = @($out | Select-String -Pattern '^PASS=(\d+) FAIL=(\d+)$')
    if ($suiteStatus -ne 0 -or $summaries.Count -ne 1) {
        Write-Host '  (suite failed or did not emit exactly one PASS=N FAIL=M summary)'
        $status = 1
        continue
    }
    $line = $summaries[0].Line
    if ($line -match '^PASS=(\d+) FAIL=(\d+)$') {
        $totalPass += [int]$Matches[1]
        $totalFail += [int]$Matches[2]
        if ([int]$Matches[2] -gt 0) { $status = 1 }
    } else {
        Write-Host '  (invalid summary line)'
        $status = 1
    }
}

if ($closePrecheckRuns -ne 1) {
    Write-Host "  (close-precheck.test.ps1 must execute exactly once; got $closePrecheckRuns)"
    $status = 1
}

Write-Host "=== total: PASS=$totalPass FAIL=$totalFail"
exit $status
