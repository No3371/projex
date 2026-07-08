# Patch: Util Script Output Hints & Stale projex-commit Fix

> **Status:** Closed
> **Date:** 2026-07-09
> **Author:** Claude (orchestrated subagent)
> **Directive:** Implement Option A of 2607090215-util-script-output-hints-next-step-proposal.md — fix stale `projex-commit` refs, add `stage-n-commit` next-step hints to stage-only scripts, add worktree redirect hint.
> **Source Plan:** Direct (proposal Option A / Recommended Approach; audited "Accept with Conditions" in 2607090220-util-script-output-hints-proposal-verification-audit.md)
> **Related Projex:** 2607090215-util-script-output-hints-next-step-proposal.md | 2607090220-util-script-output-hints-proposal-verification-audit.md
> **Result:** Success

---

## Summary

Two problems fixed. (1) Scripts + docs referenced a nonexistent `projex-commit.{sh,ps1}` — real committer is `stage-n-commit.{sh,ps1}`; an agent copy-pasting the printed hint got `command not found`. (2) The three stage-only scripts (`del-n-stage`, `move-n-stage`, `stage-by-pattern`) staged changes but printed no hint that `stage-n-commit` is the required follow-up, and `projex-worktree` stated its path without framing it as a mandatory redirect. Change is additive stdout + 4 corrective renames; no behavior/exit-code/logic change.

---

## Changes

### Stale `projex-commit` → `stage-n-commit` rename

**Files:** `new-projex.sh` (commit-hint line), `new-projex.ps1` (commit-hint line), `AGENTS.md` (§ Repository Structure tree line 14; § Git Rules point 3 line 71), `CLAUDE.md` (same two spots)
**Change Type:** Modified
**What Changed:**
- `new-projex.sh` / `.ps1`: `# commit:` hint now invokes `stage-n-commit.{sh,ps1}` instead of dead `projex-commit.{sh,ps1}`.
- `AGENTS.md` line 14 tree entry renamed (comment + column alignment preserved); line 71 prose script list renamed.
- `CLAUDE.md`: same two edits, applied on disk.

**Why:** `projex-commit.{sh,ps1}` does not exist anywhere in the repo; `stage-n-commit` is the real, framework-wide committer (referenced correctly in 15 workflow specs).

**Note:** `CLAUDE.md` is gitignored (`.gitignore` line 2) in this repo, so its fix lives on disk but is not in the commit. `AGENTS.md` is the tracked mirror carrying the correction into git history.

### Next-step hints on stage-only scripts

**Files:** `del-n-stage.{sh,ps1}`, `move-n-stage.{sh,ps1}`, `stage-by-pattern.{sh,ps1}`
**Change Type:** Modified
**What Changed:**
- `del-n-stage`: after the "Deleted N file(s)" listing, prints `# next:` line hinting `stage-n-commit <repo> "<msg>" <deleted files>` (`DONE_FILES`).
- `move-n-stage`: after the "Moved N file(s)" listing, hints with destination paths now in index (`DONE_DST`), not sources.
- `stage-by-pattern`: after the "Staged filtered changes" listing, hints with the files that had matching hunks staged — **only on the `git apply --cached` path**. No hint on `-n` dry-run, "No unstaged changes", or "No changes match the pattern" early exits.

**Why:** These scripts stage but never commit; the hint reinforces the required follow-up at the moment an agent is most likely to skip it. `<msg>` placeholder used since the script can't know intent (same convention `new-projex` uses).

### Worktree redirect hint

**File:** `projex-worktree.{sh,ps1}`
**Change Type:** Modified
**What Changed:** After "Worktree created: ..." prints a `# next:` instruction that all subsequent script/git calls must target the worktree path as the working repo root (not the original repo-root) until the worktree is closed (squash-merged or abandoned).

**Why:** The path alone read as a fact, not the directive it needs to be; agents were liable to keep operating against the original root.

---

## Verification

**Method:** `bash -n` syntax check (5 `.sh`); PowerShell AST `ParseFile` (5 `.ps1`); live smoke test in a throwaway git repo exercising each stage-only script; grep for residual `projex-commit`; live re-run of `new-projex.ps1` (scaffolding this doc).

**Result:**
```
syntax OK: del-n-stage.sh move-n-stage.sh stage-by-pattern.sh projex-worktree.sh new-projex.sh
parse OK:  all 5 .ps1
del-n-stage    → # next: ... stage-n-commit.sh <repo> "<msg>" gone.txt
move-n-stage   → # next: ... stage-n-commit.sh <repo> "<msg>" mv2.txt   (destination, not source)
stage-by-pattern apply path → # next: ... "<msg>" keep.txt
stage-by-pattern -n dry-run → no hint (correct)
stage-by-pattern no-match   → no hint (correct)
residual projex-commit in 4 renamed files → NONE
new-projex.ps1 rerun → printed "# commit: ...stage-n-commit.ps1..." (fix confirmed live)
```

**Status:** PASS

**Code commit:** 49256e4 (11 tracked files; CLAUDE.md gitignored, fixed on disk only)

---

## Impact on Related Projex

| Document | Relationship | Update Made |
|----------|-------------|-------------|
| 2607090215-util-script-output-hints-next-step-proposal.md | Source proposal (Option A) | Status → Accepted; Related Projex notes this patch as the implementation |
| 2607090220-util-script-output-hints-proposal-verification-audit.md | Pre-acceptance audit | Referenced; its one condition (Appendix citation) was fixed pre-patch by orchestrator |

---

## Notes

- Option B of the proposal (a workflow that programmatically parses this stdout) was NOT implemented — out of directive scope; the hints are human/agent-readable only.
- CRLF warnings on commit are the repo's normal `core.autocrlf` behavior, not errors.
- `2604031730-util-script-ideas-imagine.md` also mentions `projex-commit` but is a generative/hypothetical doc — intentionally left untouched (not in directive scope).
