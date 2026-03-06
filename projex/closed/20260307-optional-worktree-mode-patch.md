# Patch: Optional Worktree Mode

> **Date:** 2026-03-07
> **Source:** 20260307-optional-worktree-mode-plan.md
> **Related:** 20260306-optional-worktree-mode-proposal.md

---

## Objective

Add optional git worktree support across all projex workflows that use ephemeral branches. Worktrees (`.projexwt/`) provide branch isolation without switching the main working directory, avoiding IDE disruption and stash complexity.

---

## Changes

### New Files

| File | Description |
|------|-------------|
| `projex-worktree.sh` | Bash worktree creation script with `.gitignore` enforcement gate |
| `projex-worktree.ps1` | PowerShell equivalent |

Both scripts: verify `.projexwt/` is gitignored (auto-add + commit if missing), create worktree at `.projexwt/<branch-suffix>/`, accept optional `<base-ref>` argument.

### Modified Scripts (6 files)

| File | Change |
|------|--------|
| `projex-squash-close.sh` | Added `--worktree` flag — removes worktree before squash merge, skips checkout and clean-tree check |
| `projex-squash-close.ps1` | Added `[switch]$Worktree` — same logic |
| `projex-merge-close.sh` | Added `--worktree` flag — removes worktree before merge |
| `projex-merge-close.ps1` | Added `[switch]$Worktree` — same logic |
| `projex-abandon.sh` | Added `--worktree` flag — force-removes worktree |
| `projex-abandon.ps1` | Added `[switch]$Worktree` — same logic |

All scripts: worktree mode skips `git checkout` (main directory already on base), uses `git worktree remove` instead. Recovery messages guide user to re-create worktree on failure.

### Modified Workflow Specs (4 files)

| File | Change |
|------|--------|
| `SKILL.md` | Added "Worktree Creation" subsection, updated Branch Finalization entries with `[--worktree]`, added "Worktree Mode (Optional)" subsection |
| `execute-projex.md` | Step 1.2: worktree mode conditional alongside checkout mode; execution log template: added `Worktree Path:` field |
| `simulate-projex.md` | Step 2: worktree mode as default, checkout as fallback; Step 4: both `--worktree` and non-worktree rollback commands |
| `close-projex.md` | Section 7: worktree mode note, `--worktree` variants for Options A, B, D; Option C note about manual worktree removal |

---

## Opt-in Mechanism

- **Execute:** Add `> **Worktree:** Yes` to plan header
- **Simulate:** Worktree mode is the default (checkout is fallback)
- **Close:** Pass `--worktree` to finalization script

---

## Verification

- All scripts have matching `.sh` / `.ps1` implementations
- `.gitignore` enforcement is a hard gate in `projex-worktree` scripts
- Finalization scripts validate inputs and report failures with recovery guidance
- Workflow specs document both checkout and worktree paths
- SKILL.md consolidates worktree documentation
