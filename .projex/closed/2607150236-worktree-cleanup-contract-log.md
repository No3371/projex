# Execution Log: Worktree Cleanup Contract + Close-Script Removal Diagnosis

Started: 20260715 03:00
Repo Root: S:/Repos/projex
Plan File: .projex/2607150236-worktree-cleanup-contract-plan.md
Base Branch: main
Worktree Path: projex/.projexwt/2607150236-worktree-cleanup-contract

## Pre-Check Results

```
REPO_ROOT=S:/Repos/projex
BRANCH=main
PLAN_REL=.projex/2607150236-worktree-cleanup-contract-plan.md

WARN  Plan is not committed to branch 'main' - commit the plan before proceeding
WARN  Working tree has 11 uncommitted change(s)

PRE-CHECK PASSED
```

Resolution: committed the plan file + its red-team file (`2607150312-worktree-cleanup-contract-plan-redteam.md`) to base `main`
as `projex: start execution of worktree-cleanup-contract-plan` (107844e), per orchestrator approval. Remaining untracked
`.projex/*` and `.github/`/`.gitignore` entries are unrelated pre-existing files, left untouched. Ephemeral worktree branch
`projex/2607150236-worktree-cleanup-contract` created from HEAD.

## Steps

### [20260715 03:05] - Step 1: Cleanup contract in SKILL.md + execute-projex.md
**Action:** Appended cleanup-contract bullet to SKILL.md § Worktree Mode "How it works" list (after "No stashing needed", now ln 274). Appended contract sentence to execute-projex.md ln 97 (worktree init) and inserted cleanup paragraph into step 7.5 (after "Leave pre-existing resources alone", now ln 216).
**Result:** Grep confirms "cleanup contract" anchor present in both files (SKILL.md:274, execute-projex.md:97) and the step-7.5 insert at execute-projex.md:216. Wording matches plan Step 1 verbatim.
**Status:** Success

### [20260715 03:12] - Step 2: close-projex.md hygiene gate, stale fix, recovery guidance
**Action:** In § 7 FINALIZE GIT BRANCH: (1) added a "Worktree mode — also check the worktree for leftovers" block (`git -C <worktree-path> status --porcelain --ignored=matching`) after the base-repo status check; (2) replaced the stale "removes the worktree before merging/abandoning" sentence with the corrected "merges first, then removes the worktree as best-effort cleanup" wording; (3) added the leftover-recovery note (registered vs unregistered branches) after the rebase-conflict Note.
**Result:** All three edits applied. Recovery note names both `worktree list`-still-listed and no-longer-listed branches and the `git worktree prune` self-heal. Stale sentence no longer claims removal happens before merge.
**Status:** Success

### [20260715 03:30] - Step 3: Merge-type close scripts — pre-flight gate + removal diagnosis
**Action:** In all 6 merge-type scripts (squash/merge/rebase-close × sh/ps1): (a) inserted the unified pre-flight cleanliness gate (`git status --porcelain` -> exit 1 on any dirty state, before the first merge/rebase; ignored-content `^!!` warning) and (b) replaced the blind `worktree remove --force` retry with registered-vs-unregistered diagnosis (`worktree list --porcelain` suffix match; SIGPIPE-guarded `{ ... ; } | head` in sh). For squash/merge the gate is a new worktree-mode block after the checkout/else branch; for rebase it replaces the pre-existing tracked-only clean-check (already inside the worktree-mode branch, so inlined without a redundant `if WORKTREE_MODE` wrapper -- behavior identical to squash/merge). ps1 mirrors via `[regex]::Escape($WtSuffix)` suffix match on forward-slash paths.
**Result:** `bash -n` clean on all 3 sh; PowerShell `Parser::ParseFile` reports 0 errors on all 3 ps1. Grep confirms zero `worktree remove --force` occurrences across the 6 merge-type scripts. shellcheck not installed on host (noted; bash -n covers syntax).
**Status:** Success (behavior verification deferred to Step 6 matrix)

### [20260715 03:40] - Step 4: projex-abandon — name destroyed files + failure diagnosis
**Action:** In projex-abandon.{sh,ps1}: before the intentional `worktree remove --force`, list untracked (`^??`) files being discarded ("Note: discarding untracked files…"); on removal failure, branch on registered-vs-unregistered (`worktree list --porcelain` suffix match) instead of the flat manual-retry advice. `--force`-first retained (abandon's discard contract).
**Result:** `bash -n` clean on projex-abandon.sh; PowerShell parser 0 errors on projex-abandon.ps1.
**Status:** Success (behavior verification deferred to Step 6 matrix)

### [20260715 03:44] - Step 5: projex-worktree — creation-side cleanup hint
**Action:** Appended a `# cleanup:` hint line to projex-worktree.{sh,ps1} output (echo / Write-Host) after the existing `# next:` line: "anything created here that git does not track … must be removed before close — untracked leftovers block worktree removal."
**Result:** `bash -n` clean; PowerShell parser 0 errors. Hint verified present in both tails. Live-print check deferred to Step 6 row 9.
**Status:** Success

### [20260715 04:10] - Step 6: Scratch-repo verification battery (sh + ps1)
**Action:** Built two throwaway-repo harnesses (`scratchpad/harness_sh.sh`, `scratchpad/harness_ps.ps1`) exercising the full 9-row matrix against the edited scripts, once per family. Each row: fresh `git init` repo + `projex-worktree` worktree + a commit on the ephemeral branch, then the close/abandon script under test; assertions on exit code, base HEAD movement, worktree/branch existence, and required output substrings. ps1 scripts invoked via `pwsh -NoProfile -File` child processes so their `exit` does not terminate the harness.
**Result:** sh family PASS=32 FAIL=0; ps1 family PASS=31 FAIL=0. Row-by-row (both families identical unless noted):
- Row 1 (clean squash-close): exit 0, base HEAD advanced, worktree removed, branch deleted.
- Row 2 (+untracked): exit 1 pre-merge, `scratch.txt` listed, base HEAD unchanged, worktree intact.
- Row 3 (+tracked edit, no untracked — Finding 1): exit 1 pre-merge, `feat.txt` listed, base HEAD unchanged. Confirms the unified gate catches tracked-dirty state an untracked-only gate would miss.
- Row 4 (+ignored file): "ignored content" warning printed, gate passes, close succeeds, branch deleted.
- Row 5 (half-removal — admin dir `rm`ed): close succeeds, "unregistered but directory remains … git worktree prune" message, no `--force`, no fatal.
- Row 6 (locked worktree): close succeeds; still-registered "Blocking content:" diagnosis + retry line printed; no "retrying with --force"; branch-delete emits its non-fatal "could not delete" warning; script exits 0. Confirms Finding 4 SIGPIPE guard leaves the prune/branch-delete tail reachable.
- Row 7 (non-clean → rebase-close & merge-close): both exit 1 pre-mutation, base HEAD unchanged.
- Row 8 (+untracked → abandon): "discarding untracked files" note, `--force` removal succeeds, branch gone.
- Row 9 (projex-worktree fresh create): `# cleanup:` hint line printed.
Windows git printed forward-slash worktree paths, so the ps1 `[regex]::Escape($WtSuffix)` suffix match resolved correctly (rows 5/6). Only-cosmetic difference in check count: sh row 5 had an extra `no-fatal` assertion the ps1 harness omitted; behavior identical.
**Status:** Success

### [20260715 04:20] - Step 7: Complete execution (verification + review + cleanup)
**Action:** Ran final verification pass; validated success criteria; spec-compliance and quality review; cleaned up scratch resources; set plan Status -> Complete.
**Result:**
- Automated checks: `bash -n` clean on all 5 touched `.sh`; PowerShell parser 0 errors on all 5 `.ps1`; Step 6 matrix all rows pass both families (sh 32/32, ps1 31/31). shellcheck unavailable on host — noted, not blocking.
- `--force` audit: the 6 merge-type close scripts contain zero `worktree remove --force`; `projex-abandon.{sh,ps1}` retains its intentional `--force` (2 refs each family) — matches Success Criteria and the "abandon keeps its one" acceptance note.
- Success Criteria: all 8 boxes satisfied (no auto-force; non-clean gate pre-mutation with listing; clean close unchanged; unregistered diagnosis + prune hint; registered diagnosis + retry line, no force/fatal; specs carry contract + hygiene check + corrected ordering sentence + recovery note; worktree creation hint; sh/ps1 parity).
- Spec-compliance review: re-read edited sections of SKILL.md § Worktree Mode (cleanup-contract bullet), execute-projex.md (ln 97 sentence + step-7.5 paragraph), close-projex.md § 7 (worktree leftover check, corrected removal-ordering sentence, recovery note). All requirements met, wording coherent in context.
- Quality review: one intentional structural deviation from a literal reading of Step 3 — rebase-close's unified gate is inlined into the existing worktree-mode branch rather than re-wrapped in a redundant `if WORKTREE_MODE`, since that region is already worktree-only. Behavior verified identical to squash/merge (row 7 rebase). No dead code, naming drift, or incomplete error paths found.
- Cleanup: removed scratch repos (`scratchpad/shtest`, `scratchpad/pstest`) and harness files; `git worktree list` on the main repo shows only the base checkout and this execution worktree — no strays.
**Status:** Success

## Deviations
- Step 3 rebase-close: unified pre-flight gate inlined into the pre-existing worktree-mode branch (which already guards `if [ "$WORKTREE_MODE" = true ]` / `if ($Worktree)`) instead of adding a second nested wrapper as the squash/merge insertion does. Strictly broader than and replaces the old tracked-only clean-check; behavior identical across all three scripts (verified, Step 6 row 7 rebase). No outcome impact.
- ps1 gate/diagnosis output uses `Write-Error`/`Write-Warning` with embedded newline-joined lists rather than the sh `echo … | head` to stderr, matching the existing ps1 file conventions. Same observable behavior (exit code + blocking list shown); verified by matrix substring assertions.

## Issues Encountered
- Initial execution-log Write accidentally left stray `</content>`/`</invoke>` markup at EOF and the Step 3 entry was first inserted out of order; both corrected before the Step 3 commit. No impact on committed content.

## Data Gathered
- Verification battery results captured inline under Step 6 (sh 32/32, ps1 31/31).

