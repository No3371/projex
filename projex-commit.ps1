# projex-commit.ps1 — Stage explicit files and commit atomically
# Usage: projex-commit.ps1 <repo-root> "commit message" ["--flag [value]" ...] file1 [file2 ...]
#
# Any trailing argument starting with '--' is treated as an extra git commit flag.
# A flag+value pair can be passed as a single quoted string: "--trailer Co-authored-by: Claude".
# File paths (which never start with '--') are staged and committed.

param(
    [Parameter(Mandatory)][string]$RepoRoot,
    [Parameter(Mandatory)][string]$CommitMsg,
    [Parameter(Mandatory, ValueFromRemainingArguments)][string[]]$RemainingArgs
)

# Separate extra commit flags (start with '--') from file paths
$ExtraFlags = @()
$Files = @()

foreach ($arg in $RemainingArgs) {
    if ($arg -like '--*') {
        if ($arg -match ' ') {
            # Flag+value pair in one string — split at first space
            $parts = $arg -split ' ', 2
            $ExtraFlags += $parts[0]
            $ExtraFlags += $parts[1]
        } else {
            $ExtraFlags += $arg
        }
    } else {
        $Files += $arg
    }
}

if ($Files.Count -eq 0) {
    Write-Error "No files specified"
    exit 1
}

# Validate repo
git -C $RepoRoot rev-parse --git-dir 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Error "'$RepoRoot' is not a git repository"
    exit 1
}

# Validate all file paths are known to git (tracked or untracked) and have changes
$bad = @()
foreach ($f in $Files) {
    $st = git -C $RepoRoot status --porcelain -- $f
    if (-not $st) {
        $bad += $f
    }
}
if ($bad.Count -gt 0) {
    Write-Error "Files not found or unchanged: $($bad -join ', ')"
    exit 1
}

# Snapshot index for rollback
$indexTree = git -C $RepoRoot write-tree
if ($LASTEXITCODE -ne 0) {
    Write-Error "git write-tree failed — cannot snapshot index"
    exit 1
}

# Stage files
git -C $RepoRoot add @Files
if ($LASTEXITCODE -ne 0) {
    git -C $RepoRoot read-tree $indexTree 2>$null
    Write-Error "git add failed — index rolled back"
    exit 1
}

# Commit — rollback index on failure
$commitOutput = git -C $RepoRoot commit @ExtraFlags -m $CommitMsg 2>&1
if ($LASTEXITCODE -ne 0) {
    git -C $RepoRoot read-tree $indexTree 2>$null
    Write-Error "git commit failed — index rolled back`n$commitOutput"
    exit 1
}

$hash = git -C $RepoRoot rev-parse --short HEAD
Write-Host "Committed: $CommitMsg ($hash)"
