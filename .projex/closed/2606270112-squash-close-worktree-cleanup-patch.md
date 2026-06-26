# Patch: Squash Close Worktree Cleanup

> **Date:** 2026-06-27
> **Author:** Codex
> **Directive:** patch-projex minimal fix from 2606270200-squash-close-worktree-remove-windows-memo.md
> **Source Plan:** Direct
> **Result:** Success

---

## Summary

Close scripts no longer remove worktrees before merge. Worktree cleanup now runs after successful close and warns instead of failing when Windows locks keep the worktree directory open.

---

## Changes

### PowerShell Close Scripts

**Files:** `projex-squash-close.ps1`, `projex-merge-close.ps1`
**Change Type:** Modified
**What Changed:**
- `-Worktree` help text now says cleanup is best-effort after merge: `projex-squash-close.ps1:4`, `projex-merge-close.ps1:4`
- Removed pre-merge `git worktree remove` hard gate: `projex-squash-close.ps1:45`, `projex-merge-close.ps1:45`
- Added post-close cleanup: normal remove, `--force` retry, warning-only failure, prune: `projex-squash-close.ps1:94`, `projex-merge-close.ps1:82`

**Why:**
Windows directory locks should not block merge/commit when branch ref is enough for close.

---

### Shell Close Scripts

**Files:** `projex-squash-close.sh`, `projex-merge-close.sh`
**Change Type:** Modified
**What Changed:**
- `--worktree` help text now says cleanup is best-effort after merge: `projex-squash-close.sh:5`, `projex-merge-close.sh:5`
- Removed pre-merge `git worktree remove` hard gate: `projex-squash-close.sh:54`, `projex-merge-close.sh:54`
- Added post-close cleanup: normal remove, `--force` retry, warning-only failure, prune: `projex-squash-close.sh:94`, `projex-merge-close.sh:83`

**Why:**
Keep behavior aligned across PowerShell and shell variants.

---

## Verification

**Method:** PowerShell parser for `.ps1`; `bash -n` for `.sh`; focused diff review.

**Result:**
```text
OK projex-squash-close.ps1
OK projex-merge-close.ps1
OK projex-squash-close.sh
OK projex-merge-close.sh
```

**Status:** PASS

---

## Impact on Related Projex

| Document | Relationship | Update Made |
|----------|--------------|-------------|
| 2606270200-squash-close-worktree-remove-windows-memo.md | Source issue memo | Addressed by this patch; memo not edited |

---

## Notes

Skipped shared helper/refactor. Four direct edits keep patch small and preserve script independence.
