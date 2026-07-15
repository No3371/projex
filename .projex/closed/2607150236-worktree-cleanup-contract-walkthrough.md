# Walkthrough: Worktree Cleanup Contract + Close-Script Removal Diagnosis

> **Execution Date:** 2026-07-15
> **Completed By:** agent (Claude)
> **Source Plan:** 2607150236-worktree-cleanup-contract-plan.md
> **Duration:** 03:00–04:20 (~80 min)
> **Result:** Success

---

## Summary

Replaced blind `worktree remove --force` retries in the four close scripts with a pre-flight cleanliness gate (rejects any non-clean worktree before merge/rebase) and a registered-vs-unregistered removal diagnosis. Established the worktree cleanup contract in SKILL.md/execute-projex.md/close-projex.md. All 8 success criteria met; verification matrix sh 32/32, ps1 31/31; independent post-execution audit (Accept, all dimensions High) re-verified sh 13/13, ps1 10/10 in fresh scratch repos. All 5 red-team findings folded into the plan before execution and confirmed closed by the audit.

---

## Objectives Completion

| Objective | Status | Notes |
|-----------|--------|-------|
| No merge-type close script auto-invokes `worktree remove --force` | Complete | grep confirms 0 occurrences across squash/merge/rebase-close (sh+ps1) |
| Non-clean worktree (untracked or tracked-dirty) blocks finalize pre-merge | Complete | unified `git status --porcelain` gate — untracked-only would have missed tracked edits (redteam Finding 1) |
| Clean-worktree close behavior unchanged | Complete | matrix rows 1 (sh+ps1) — merge, worktree removed, branch deleted |
| Unregistered-removal diagnosis (no `--force`) | Complete | matrix row 5 — "unregistered … plain directory remains … git worktree prune" |
| Registered-removal diagnosis (blocking content + retry) | Complete | matrix row 6 (lock simulation) — "Blocking content:" + retry line, no force, no fatal |
| Cleanup contract stated in specs | Complete | SKILL.md § Worktree Mode, execute-projex.md (init + step 7.5), close-projex.md (hygiene gate, corrected ordering, recovery note) |
| `projex-worktree.{sh,ps1}` cleanup hint | Complete | matrix row 9 — `# cleanup:` line printed |
| `.sh` ↔ `.ps1` parity | Complete | audit independently re-ran sh 13/13, ps1 10/10, confirmed same observable behavior modulo cosmetic output-style difference |

---

## Execution Detail

### Step 1: Cleanup contract in SKILL.md + execute-projex.md

**Planned:** Append cleanup-contract bullet to SKILL.md § Worktree Mode; add contract sentence at execute-projex.md worktree init + cleanup paragraph in step 7.5.

**Actual:** Matches plan verbatim. SKILL.md:274 gets the bullet (offset by +1 from plan's ln 273 anchor due to prior content). execute-projex.md ln 97 sentence + step-7.5 paragraph (now ln 216) both applied as specified.

**Deviation:** None.

**Files Changed (ACTUAL):**
| File | Change Type | Planned? | Details |
|------|-------------|----------|---------|
| `SKILL.md` | Modified | Yes | +1 line: cleanup-contract bullet after "No stashing needed" |
| `execute-projex.md` | Modified | Yes | +1 line at worktree-init sentence, +1 paragraph in step 7.5 (net +4 in diff incl. blank lines) |

**Verification:** Grep confirmed "cleanup contract" anchor in both files.

**Issues:** None.

---

### Step 2: close-projex.md — hygiene gate, stale fix, recovery guidance

**Planned:** Add worktree-mode leftover check after the base-repo status gate; replace the stale "removes worktree before merging" sentence; add registered/unregistered recovery note after the rebase-conflict note.

**Actual:** All three edits applied exactly as specified — verified via diff (`close-projex.md` +12/-2 lines).

**Deviation:** None.

**Files Changed (ACTUAL):**
| File | Change Type | Planned? | Details |
|------|-------------|----------|---------|
| `close-projex.md` | Modified | Yes | Worktree leftover check block, corrected ordering sentence, recovery note (3 edits) |

**Verification:** Re-read step 7 end-to-end; gate precedes all finalization options; recovery note names both registered/unregistered branches.

**Issues:** None.

---

### Step 3: Merge-type close scripts — pre-flight gate + removal diagnosis

**Planned:** Insert unified pre-flight gate (`git status --porcelain` → exit 1 on any dirty state) before first merge/rebase in all 6 files; replace blind `--force` retry with registered-vs-unregistered diagnosis (SIGPIPE-guarded in sh).

**Actual:** Applied to all 6 files (squash/merge/rebase-close × sh/ps1) as specified. Confirmed via diff inspection of `projex-squash-close.sh` (representative): gate block inserted before `merge --squash`; removal block replaced with suffix-match registration check + `{ git status … || true; } | head -n 10` SIGPIPE guard.

**Deviation:** rebase-close's gate was inlined into the pre-existing `if [ "$WORKTREE_MODE" = true ]` / `if ($Worktree)` block (replacing the old tracked-only clean-check in place) rather than wrapped in a second redundant `if WORKTREE_MODE` as the squash/merge insertion pattern does — since that region was already worktree-only. Strictly broader than the check it replaced; behavior verified identical to squash/merge via matrix row 7 (both families) and independently confirmed by the audit's code inspection.

**Files Changed (ACTUAL):**
| File | Change Type | Planned? | Details |
|------|-------------|----------|---------|
| `projex-squash-close.sh` | Modified | Yes | +25/-6: pre-flight gate + removal diagnosis |
| `projex-squash-close.ps1` | Modified | Yes | +25/-6 (equivalent) |
| `projex-merge-close.sh` | Modified | Yes | +25/-6 |
| `projex-merge-close.ps1` | Modified | Yes | +25/-6 |
| `projex-rebase-close.sh` | Modified | Yes | +24/-8 (replaces old tracked-only check — deviation above) |
| `projex-rebase-close.ps1` | Modified | Yes | +28/-9 |

**Verification:** `bash -n` clean on all 3 sh; PowerShell `Parser::ParseFile` 0 errors on all 3 ps1; grep confirms zero `worktree remove --force` across the 6 files. Behavior verification deferred to Step 6 matrix (per plan).

**Issues:** None. shellcheck unavailable on host — noted, not blocking (bash -n covers syntax).

---

### Step 4: projex-abandon — name destroyed files + failure diagnosis

**Planned:** Keep `--force`-first (abandon's discard contract); list untracked files before destruction; diagnose removal failure like Step 3(b).

**Actual:** Matches plan. `projex-abandon.{sh,ps1}` now echo "Note: discarding untracked files…" (first 10 via `head`) before the `--force` remove, and branch registered-vs-unregistered on failure instead of flat manual-retry advice.

**Deviation:** None.

**Files Changed (ACTUAL):**
| File | Change Type | Planned? | Details |
|------|-------------|----------|---------|
| `projex-abandon.sh` | Modified | Yes | +11/-1 |
| `projex-abandon.ps1` | Modified | Yes | +12/-1 |

**Verification:** `bash -n` clean; PowerShell parser 0 errors.

**Issues:** None.

---

### Step 5: projex-worktree — creation-side cleanup hint

**Planned:** Append `# cleanup:` hint line to `projex-worktree.{sh,ps1}` output after the existing `# next:` line.

**Actual:** Matches plan verbatim, +1 line each.

**Deviation:** None.

**Files Changed (ACTUAL):**
| File | Change Type | Planned? | Details |
|------|-------------|----------|---------|
| `projex-worktree.sh` | Modified | Yes | +1 line |
| `projex-worktree.ps1` | Modified | Yes | +1 line |

**Verification:** Matrix row 9 confirmed hint line printed on fresh worktree creation.

**Issues:** None.

---

### Step 6: Scratch-repo verification battery

**Planned:** 9-row matrix (clean close, untracked gate, tracked-dirty gate, ignored-content warning, unregistered diagnosis, registered/lock diagnosis, rebase/merge non-clean spot-check, abandon untracked note, worktree-creation hint) run for both sh and ps1.

**Actual:** Built throwaway harnesses (`scratchpad/harness_sh.sh`, `scratchpad/harness_ps.ps1`), exercised full matrix. **sh: 32/32 PASS. ps1: 31/31 PASS** (one fewer check — sh row 5 had an extra no-fatal assertion the ps1 harness omitted; behavior identical). All 9 rows passed both families, including row 6 (lock-simulated registered-removal diagnosis) and row 3 (Finding-1 tracked-dirty gate).

**Deviation:** None — matches plan's matrix exactly.

**Files Changed (ACTUAL):** None (throwaway scratch repos + harness files, all removed in Step 7 cleanup).

**Verification:** Each row's expected outcome observed and captured in the execution log (Step 6 entry).

**Issues:** None.

---

### Step 7: Complete execution (verification + review + cleanup)

**Planned:** Full verification pass, success-criteria validation, spec-compliance review, quality review, resource cleanup, plan status → Complete.

**Actual:** All checks re-run and passed: `bash -n` clean on all 5 touched `.sh`, PowerShell parser 0 errors on all 5 `.ps1`, matrix all rows both families, `--force` audit (0 in merge-type, 2 intentional in abandon). All 8 success criteria satisfied. Spec-compliance review re-read all three edited spec files in context — coherent. Quality review found no dead code, naming drift, or incomplete error paths (the rebase inlining was the only structural deviation, judged benign). Scratch repos and harness files removed; `git worktree list` confirmed no strays.

**Deviation:** None beyond the Step 3 rebase-inlining deviation already logged.

**Files Changed (ACTUAL):**
| File | Change Type | Planned? | Details |
|------|-------------|----------|---------|
| `.projex/2607150236-worktree-cleanup-contract-plan.md` | Modified | Yes | Status → Complete |

**Verification:** See Success Criteria Verification below.

**Issues:** Execution-log formatting glitch (stray markup + out-of-order Step 3 entry) caught and corrected before the Step 3 commit — no impact on committed content (logged under Issues Encountered).

---

## Complete Change Log

> **Derived from:** `git diff --stat main..projex/2607150236-worktree-cleanup-contract`

### Files Modified
| File | Changes | In Plan? |
|------|---------|----------|
| `SKILL.md` | +1 cleanup-contract bullet | Yes |
| `close-projex.md` | +12/-2: hygiene gate, corrected ordering sentence, recovery note | Yes |
| `execute-projex.md` | +4/-2: contract sentence + step-7.5 paragraph | Yes |
| `projex-abandon.ps1` | +12/-1: untracked-note + failure diagnosis | Yes |
| `projex-abandon.sh` | +11/-1: same | Yes |
| `projex-merge-close.ps1` | +25/-6: gate + diagnosis | Yes |
| `projex-merge-close.sh` | +25/-6: same | Yes |
| `projex-rebase-close.ps1` | +28/-9: gate (inlined) + diagnosis | Yes |
| `projex-rebase-close.sh` | +24/-8: same | Yes |
| `projex-squash-close.ps1` | +25/-6: gate + diagnosis | Yes |
| `projex-squash-close.sh` | +25/-6: same | Yes |
| `projex-worktree.ps1` | +1 cleanup hint line | Yes |
| `projex-worktree.sh` | +1 cleanup hint line | Yes |
| `.projex/2607150236-worktree-cleanup-contract-plan.md` | Status Draft/In Progress → Complete (2 status-line edits across execution) | Yes (workflow-mandated) |

### Files Created
| File | Purpose | Lines | In Plan? |
|------|---------|-------|----------|
| `.projex/2607150236-worktree-cleanup-contract-log.md` | Execution log | 89 | Yes (workflow-mandated) |

### Files Deleted
None.

### Planned But Not Changed
None — all 13 planned files changed as specified.

---

## Success Criteria Verification

### Criterion 1: No merge-type close script auto-invokes `worktree remove --force` under any path

**Verification Method:** `grep -c "worktree remove --force"` across squash/merge/rebase-close (sh+ps1)

**Evidence:** 0 matches in all 6 files; `projex-abandon.{sh,ps1}` retain their 2 intentional occurrences each (by contract).

**Result:** PASS

---

### Criterion 2: Worktree close with any non-clean state exits 1 before base-branch mutation, lists blocking entries

**Verification Method:** Matrix rows 2 (untracked), 3 (tracked-dirty), 7 (rebase/merge spot-check) — sh + ps1

**Evidence:** Row 2: exit 1 pre-merge, `scratch.txt` listed, base HEAD unchanged. Row 3: exit 1 pre-merge, `feat.txt` listed — confirms unified gate catches tracked-dirty state an untracked-only gate (redteam Finding 1) would have missed. Row 7: both rebase-close and merge-close exit 1 pre-mutation on non-clean state. Audit independently re-ran the Finding-1 scenario (tracked edit, no untracked) and reproduced it.

**Result:** PASS

---

### Criterion 3: Clean-worktree close succeeds end-to-end, unchanged behavior

**Verification Method:** Matrix row 1, sh + ps1

**Evidence:** exit 0, base HEAD advanced, worktree removed, branch deleted.

**Result:** PASS

---

### Criterion 4: Removal failure with already-unregistered worktree prints correct diagnosis, no `--force`

**Verification Method:** Matrix row 5 (simulated half-removal via admin-dir deletion)

**Evidence:** "unregistered but directory remains … git worktree prune" message, no `--force` attempt, no fatal.

**Result:** PASS

---

### Criterion 5: Removal failure with still-registered worktree prints blocking content + resolve instructions

**Verification Method:** Matrix row 6 (locked worktree simulation), sh + ps1; audit code inspection

**Evidence:** "Blocking content:" diagnosis + retry line printed; no `--force` retry; no fatal/exit 141 (SIGPIPE guard held); branch-delete emits its non-fatal "could not delete" warning; script exits 0. This branch was flagged untested by the plan's own redteam (Finding 2) — row 6 was added specifically to close that gap, and the post-execution audit confirms the code path is present and correctly guarded (did not independently re-run the lock scenario, relied on executor evidence + inspection).

**Result:** PASS

---

### Criterion 6: Cleanup contract stated in SKILL.md, execute-projex.md, close-projex.md

**Verification Method:** Grep + section re-read

**Evidence:** SKILL.md § Worktree Mode bullet, execute-projex.md worktree-init sentence + step-7.5 paragraph, close-projex.md hygiene gate + corrected ordering sentence + recovery note — all present, wording coherent in context.

**Result:** PASS

---

### Criterion 7: `projex-worktree.{sh,ps1}` print cleanup-contract hint line

**Verification Method:** Matrix row 9

**Evidence:** `# cleanup:` hint line printed on fresh worktree creation, both families.

**Result:** PASS

---

### Criterion 8: `.sh` ↔ `.ps1` behavioral parity for every touched script

**Verification Method:** Executor matrix (sh 32/32, ps1 31/31) + independent audit re-verification (sh 13/13, ps1 10/10) in fresh scratch repos

**Evidence:** All scenarios produce equivalent observable behavior (exit code, base-HEAD movement, worktree/branch state, required output substrings) across both families. One cosmetic difference: ps1 uses `Write-Error`/`Write-Warning` with newline-joined lists instead of sh's `echo | head` — same observable outcome, matches existing ps1 conventions.

**Result:** PASS

---

### Acceptance Criteria Summary

| Criterion | Method | Result | Evidence |
|-----------|--------|--------|----------|
| No auto `--force` | grep | Pass | 0 matches, merge-type scripts |
| Non-clean gate pre-mutation | matrix rows 2/3/7 | Pass | exit 1, base HEAD unchanged |
| Clean close unchanged | matrix row 1 | Pass | exit 0, merged, cleaned up |
| Unregistered diagnosis | matrix row 5 | Pass | correct message, no force |
| Registered diagnosis | matrix row 6 + audit inspection | Pass | blocking content + retry, no fatal |
| Specs carry contract | grep + re-read | Pass | all anchors present |
| Creation hint | matrix row 9 | Pass | hint line printed |
| sh/ps1 parity | matrix + independent audit re-run | Pass | equivalent behavior both families |

**Overall:** 8/8 criteria passed.

---

## Deviations from Plan

### Deviation 1: rebase-close gate inlined, not re-wrapped

- **Planned:** Insert the unified pre-flight gate as a new block, mirroring the squash/merge insertion pattern (which wraps in a fresh `if WORKTREE_MODE` block).
- **Actual:** Gate inlined into the pre-existing `if [ "$WORKTREE_MODE" = true ]` / `if ($Worktree)` block, replacing the old tracked-only clean-check in place, since that region was already worktree-only — a redundant nested wrapper would have added no value.
- **Reason:** Structural simplification discovered during implementation; the pre-existing block already scoped to worktree mode.
- **Impact:** None — strictly broader than the check it replaced, behavior verified identical to squash/merge (matrix row 7, both families; independently confirmed by audit code inspection).
- **Recommendation:** No plan update needed — logged as expected engineering judgment within Step 3's scope.

### Deviation 2: ps1 diagnostic output style

- **Planned:** Plan's sh-form code blocks implied a shared `echo … | head` pattern across families (with ps1 "mirroring" per file-by-file notes).
- **Actual:** ps1 scripts use `Write-Error`/`Write-Warning` with newline-joined lists instead of sh's `echo | head` to stderr, matching pre-existing ps1 file conventions.
- **Reason:** Idiomatic per-language output handling — same observable outcome (exit code + first-N blocking lines to the error/warning stream).
- **Impact:** None — parity verified via matrix substring assertions (S1/S2/S3 == P1/P2/P3) and independently re-confirmed by audit.
- **Recommendation:** No plan update needed.

---

## Issues Encountered

### Issue 1: Execution-log formatting glitch

- **Description:** Initial execution-log write left stray `</content>`/`</invoke>` markup at EOF, and the Step 3 entry was first inserted out of chronological order.
- **Severity:** Low
- **Resolution:** Corrected before the Step 3 commit.
- **Time Impact:** Negligible.
- **Prevention:** None needed — self-caught within the same step.

---

## Key Insights

### Lessons Learned

1. **Untracked-only gates miss tracked-dirty state**
   - Context: Redteam Finding 1 caught that a `^??`-only pre-flight gate would let a modified-but-uncommitted tracked file slip through squash/merge, silently dropping the edit from the merged result.
   - Insight: A cleanliness gate protecting "worktree returned with only tracked content" must check `git status --porcelain` broadly (untracked + modified + staged), not just untracked. rebase-close already had a narrower tracked-only check; the fix unified all three scripts on the broader gate.
   - Application: Any future worktree-cleanliness gate should default to full `git status --porcelain`, not a grep-filtered subset, unless there's a specific reason to narrow it.

2. **Untested code branches hide in a green matrix**
   - Context: Redteam Finding 2 — the plan's original matrix never exercised the "still-registered, removal fails" diagnosis branch (the most complex new code), yet all rows reported green.
   - Insight: A verification matrix can look complete while silently missing the state that triggers the newest/riskiest code path. Every new branch needs an explicit row that reaches it, not just rows adjacent to it.
   - Application: When designing a verification matrix for branching diagnosis code, enumerate the branches first, then derive matrix rows to hit each one — not the other way around.

### Pattern Discoveries

1. **SIGPIPE guard for external-command pipes under `set -euo pipefail`**
   - Observed in: `projex-squash-close.sh` / `projex-merge-close.sh` / `projex-rebase-close.sh` removal diagnosis (`{ git … || true; } | head -n 10`)
   - Description: A bare `external-command | head` under `set -euo pipefail` can abort the script with exit 141 if `head` closes early and the producer's next write hits SIGPIPE — silently skipping any trailing cleanup (branch delete, prune). Wrapping the producer in `{ … || true; }` absorbs the SIGPIPE without affecting `head`'s truncation behavior.
   - Reuse potential: Any future sh script piping unbounded `git`/external-command output through `head`/`tail` under strict mode.

### Gotchas / Pitfalls

1. **`git worktree list --porcelain` path separators**
   - Trap: Assuming Windows git might print backslash paths in `worktree list --porcelain` output, which would break a forward-slash suffix regex match.
   - How encountered: Explicitly tested in the redteam pass before execution (not discovered live) — confirmed forward slashes on Windows regardless of shell.
   - Avoidance: Always verify path-separator assumptions empirically per platform before writing a regex that depends on them; don't assume shell context (Git Bash vs PowerShell) changes what git itself prints.

### Technical Insights

- Registration checks via `worktree list --porcelain` suffix-match are more reliable than full-path equality across `.ps1` (backslash `Join-Path`) and `.sh` (forward-slash) — git's own output format is the stable anchor, not either script's internal path representation.
- A pre-flight gate placed before the first mutating operation makes "fix and re-run" free for the caller — no partial-state cleanup needed on the common failure path.

---

## Recommendations

### Immediate Follow-ups
- None — audit found no critical or significant issues; sign-off was unconditional.

### Future Considerations
- If a deps-leftover incident recurs from `debug-projex` or `simulate-projex` workflows, add a one-line cleanup-contract pointer to `debug-projex.md`'s close section (redteam Finding 3 / audit Top Issue 2 — deliberately deferred, SKILL.md contract is intended to cover all worktree consumers in one place).
- The empty-"Blocking content" case under a pure FS-lock (no git-visible dirty state) prints a generic retry line; if Windows-lock reports come back confusing in practice, add the alternative "likely a file lock" hint the redteam suggested (tracked as a monitor item, not a gap).

### Plan Improvements
- None — plan review found the plan unusually well-anchored (every cited line number and before/after block verified against the repo pre-execution) and the redteam pass caught the two success-criteria-level gaps (Findings 1 and 2) before execution started, so none surfaced live.

---

## Related Projex Updates

### Documents to Update
| Document | Update Needed |
|----------|---------------|
| `2607150236-worktree-cleanup-contract-plan.md` | Status → Complete, walkthrough link (this close) |
| `2607150236-worktree-cleanup-contract-log.md` | Move to `closed/` alongside plan (this close) |
| `2607150312-worktree-cleanup-contract-plan-redteam.md` | Resolved by this plan's Revision Log (all 5 findings folded in pre-execution) — move to `closed/` (this close) |
| `2607151620-worktree-cleanup-contract-audit.md` | Verdict Accept, addresses this plan's completion — move to `closed/` (this close) |
| `2607140251-close-scripts-per-branch-lock-plan.md` | Not touched — unrelated topic (per-branch locking, not worktree cleanup); does not reference this plan. Still `Ready`, pending its own execution. Note: its Constraints section still correctly flags anchor drift against *this* plan's now-landed script changes — the sibling plan's anchors will need a `/revise-projex` pass before it executes, since it line-pins the same finalization-script regions this plan just edited. |

### New Projex Suggested
| Type | Description |
|------|-------------|
| (None) | Optional [patch] chain step was evaluated by the audit and skipped — audit found nothing patch-sized (0 critical/significant findings, one cosmetic minor issue not worth a patch) |

---

## Appendix

### Execution Log

Full log: `2607150236-worktree-cleanup-contract-log.md` (moved to `closed/` alongside this walkthrough). Summary: 7 steps, all Success, sh 32/32 + ps1 31/31 verification matrix, 2 logged deviations (rebase inlining, ps1 output style), 1 minor logged issue (log-formatting glitch, self-corrected).

### Test Output

Executor matrix: sh 32/32 PASS, ps1 31/31 PASS (9-row matrix × both families, minus one cosmetic assertion-count difference on row 5).

Independent audit re-verification: sh 13/13, ps1 10/10 meaningful checks in fresh scratch repos (clean close, untracked gate, Finding-1 tracked-dirty gate, unregistered/half-removal diagnosis). Registered-worktree lock case (row 6) not independently re-run by audit — relied on executor evidence + code inspection.

### References

- Commits on `projex/2607150236-worktree-cleanup-contract` (base `main` @ `107844e`): `f9b4170` (step 1), `936e41d` (step 2), `36a7ed5` (step 3), `f2e4876` (steps 4-5), `57132dd` (step 6), `7af0a52` (complete)
- Red team: `2607150312-worktree-cleanup-contract-plan-redteam.md` — Verdict: Fix Issues → all 5 findings folded into plan pre-execution
- Audit: `2607151620-worktree-cleanup-contract-audit.md` — Verdict: Accept, sign-off Yes, no conditions
