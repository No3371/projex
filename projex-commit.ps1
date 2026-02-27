# projex-commit.ps1 — Stage explicit files and commit atomically
# Usage: projex-commit.ps1 <repo-root> "commit message" file1 [file2 ...]

param(
    [Parameter(Mandatory)][string]$RepoRoot,
    [Parameter(Mandatory)][string]$CommitMsg,
    [Parameter(Mandatory, ValueFromRemainingArguments)][string[]]$Files
)

# Validate repo
git -C $RepoRoot rev-parse --git-dir 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Error "'$RepoRoot' is not a git repository"
    exit 1
}

# Stage files
git -C $RepoRoot add @Files
if ($LASTEXITCODE -ne 0) {
    git -C $RepoRoot restore --staged @Files 2>$null
    Write-Error "git add failed — partial staging rolled back"
    exit 1
}

# Commit — rollback staging on failure
$commitOutput = git -C $RepoRoot commit -m $CommitMsg 2>&1
if ($LASTEXITCODE -ne 0) {
    git -C $RepoRoot restore --staged @Files 2>$null
    Write-Error "git commit failed — staging rolled back`n$commitOutput"
    exit 1
}

$hash = git -C $RepoRoot rev-parse --short HEAD
Write-Host "Committed: $CommitMsg ($hash)"
