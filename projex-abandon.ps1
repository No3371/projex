# projex-abandon.ps1 — Checkout base and force-delete ephemeral branch without merging
# Usage: projex-abandon.ps1 <repo-root> <base-branch> <ephemeral-branch>

param(
    [Parameter(Mandatory)][string]$RepoRoot,
    [Parameter(Mandatory)][string]$Base,
    [Parameter(Mandatory)][string]$Ephemeral
)

# Validate repo
git -C $RepoRoot rev-parse --git-dir 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Error "'$RepoRoot' is not a git repository"
    exit 1
}

# Validate branches exist
git -C $RepoRoot rev-parse --verify $Base | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Error "Base branch '$Base' does not exist"
    exit 1
}

git -C $RepoRoot rev-parse --verify $Ephemeral | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Error "Ephemeral branch '$Ephemeral' does not exist"
    exit 1
}

if ($Base -eq $Ephemeral) {
    Write-Error "Base and ephemeral branch cannot be the same ('$Base')"
    exit 1
}

# Checkout base
git -C $RepoRoot checkout $Base
if ($LASTEXITCODE -ne 0) {
    Write-Error "Could not checkout '$Base' — still on '$Ephemeral', nothing lost"
    exit 1
}

# Force-delete ephemeral (non-fatal)
git -C $RepoRoot branch -D $Ephemeral
if ($LASTEXITCODE -ne 0) {
    Write-Warning "Could not delete '$Ephemeral' — delete manually: git branch -D $Ephemeral"
} else {
    Write-Host "Abandoned '$Ephemeral'. Back on '$Base'."
}
