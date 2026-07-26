# Runs every PowerShell suite. Each suite builds throwaway repos under $env:TEMP and cleans up after
# itself; nothing touches the repo you run it from.
# Usage: pwsh tests/run-all.ps1
$suites = @('resolve-conflicts.test.ps1', 'worktree.test.ps1', 'dirty-base.test.ps1')
$totalPass = 0
$totalFail = 0
$status = 0

foreach ($suite in $suites) {
    Write-Host "=== $suite"
    # 6>&1 folds the information stream in: the suites report via Write-Host, which plain
    # capture does not collect. 2>$null drops git's CRLF/LF advisories on Windows checkouts.
    $out = & (Join-Path $PSScriptRoot $suite) 6>&1 2>$null
    $out | Select-String -Pattern '^FAIL|^PASS=' | ForEach-Object { Write-Host $_.Line }
    $line = ($out | Select-String -Pattern '^PASS=' | Select-Object -Last 1).Line
    if ($line -match '^PASS=(\d+) FAIL=(\d+)$') {
        $totalPass += [int]$Matches[1]
        $totalFail += [int]$Matches[2]
        if ([int]$Matches[2] -gt 0) { $status = 1 }
    } else {
        Write-Host "  (no summary line — suite did not complete)"
        $status = 1
    }
}

Write-Host "=== total: PASS=$totalPass FAIL=$totalFail"
exit $status
