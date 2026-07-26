# Walkthrough: Close Scripts: Dirty Base Safety

> **Execution Date:** 2026-07-26
> **Completed By:** Claude (Opus 5, execution) + patch-projex subagent (Opus, post-audit correction) + Claude (Sonnet 5, close)
> **Source Plan:** 2607261121-close-scripts-dirty-base-safety-plan.md
> **Duration:** ~12:13–13:50 execution; patch and close same day
> **Result:** Success

---

## Summary

All six branch-finalization scripts (`projex-{squash,merge,rebase}-close.{sh,ps1}`) now reject tracked dirt in the checkout they're about to mutate — including the originating/base worktree in worktree mode, previously unvalidated. Squash-close's two unconditional `git reset --hard HEAD` rollbacks are replaced with checked `git reset --merge HEAD`, satisfying the project's no-unapproved-hard-reset rule. A 139-assertion-per-platform dirty-base regression suite lives in `tests/`, registered in both runners (`PASS=255 FAIL=0` sh, `PASS=211 FAIL=0` ps1). `close-projex.md` documents both pre-flight gates accurately. An independent audit found the work sound but caught one falsified claim in the execution log — the squash rollback-failure branch was declared "unreachable" when it is in fact reachable and, worse, its error message was actively wrong and pointed the user at the destructive command this whole plan exists to forbid. A same-day patch fixed the message and the record. 11 of 12 plan criteria hold as originally reasoned; the 12th holds in outcome but not in its original justification — recorded honestly rather than quietly patched over.

---

## Objectives Completion

| Objective | Status | Notes |
|-----------|--------|-------|
| Verify origin/base pairing + tracked cleanliness (Step 1) | Complete | All six finalizers gated; rebase gets an extra pre-rebase collision check |
| Remove destructive squash rollback (Step 2) | Complete | Policy-compliance step per plan's own framing; message accuracy later corrected by patch |
| Dirty-base regression suite in `tests/` (Step 3) | Complete | 139 assertions/platform, registered in both runners, negative control reproduces both motivating bugs |
| Align close workflow contract (Step 4) | Complete | `close-projex.md` §7 rewritten: two-gate table, pre-flight language, non-hard-reset language |
| Post-audit correction (patch, not a plan objective) | Complete | `safe_rollback` message split; "unreachable" wording corrected in 4 files; log count fixed 4→5 |

---

## Execution Detail

> Derived from `2607261121-close-scripts-dirty-base-safety-log.md` and git history on `projex/2607261121-close-scripts-dirty-base-safety`.

### Step 1: Verify Origin/Base Pairing and Tracked Cleanliness

**Planned:** Add a dirty-base gate to all six finalizers, before checkout/merge/rebase — `Base` resolved to a local branch, `RepoRoot`'s HEAD matched to it, tracked-dirt check via `status --porcelain --untracked-files=no --ignore-submodules=dirty`; `rebase-close` additionally gets a pre-rebase untracked-collision check since it's the only script that mutates (rewrites ephemeral history) before consulting `RepoRoot`.

**Actual:** Implemented exactly as planned. Shared helpers per script (`full_ref`/`Get-FullRef`, `tracked_dirt`/`Get-TrackedDirt`, `Assert-LocalBranch` on PS). Non-branch `Base` (tag, SHA, remote ref) exits `1` naming the resolved kind. Mismatched/detached `RepoRoot` exits `1` before mutation. `.sh` scripts additionally dropped the now-redundant checkout-mode `diff --quiet`/`diff --cached --quiet` pair in favor of the unified gate.

**Deviation:** None from plan intent. Steps 1 and 2 landed in one commit (`9ce9628`) — both rewrite overlapping regions of `projex-squash-close.{sh,ps1}`; a split would have left an intermediate commit with a half-migrated rollback path.

**Files Changed (ACTUAL):**
| File | Change Type | Planned? | Details |
|------|-------------|----------|---------|
| `projex-squash-close.sh` | Modified | Yes | +74/-lines: dirty-base gate, ref-type check |
| `projex-squash-close.ps1` | Modified | Yes | +87/-lines: parity |
| `projex-merge-close.sh` | Modified | Yes | +56/-lines: same gate |
| `projex-merge-close.ps1` | Modified | Yes | +68/-lines: parity |
| `projex-rebase-close.sh` | Modified | Yes | +85/-lines: gate + pre-rebase collision check |
| `projex-rebase-close.ps1` | Modified | Yes | +92/-lines: parity |

**Verification:** Manual scenarios against throwaway repos (bash, worktree mode): unstaged tracked edit → exit 1, edit intact; untracked collision at rebase → exit 1, **ephemeral tip SHA unchanged**; tag as `Base` → exit 1 naming ref type; wrong branch checked out at `RepoRoot` → exit 1. Regression: `tests/run-all.sh` → `PASS=116 FAIL=0`; `pwsh tests/run-all.ps1` → `PASS=72 FAIL=0` (188 total, matching pre-existing baseline).

**Issues:** None at this step.

---

### Step 2: Remove Destructive Squash Rollback

**Planned:** Replace squash-close's unconditional `git reset --hard HEAD` with checked `git reset --merge HEAD`; on rollback failure exit `1` without escalating; exercise the rollback-failure branch in the regression suite or record its unreachability under the plan's own escape clause.

**Actual:** Both `reset --hard HEAD` calls replaced with `safe_rollback`/`Invoke-SafeRollback` behind a checked `git reset --merge HEAD`. Five constructions were probed to exercise the rollback-failure branch (see table in the execution log); the executor concluded the branch was **unreachable through the scripts' own entry points** and shipped it under the plan's escape clause (record the finding if unreachable).

**Deviation — significant, caught by audit, corrected by patch:** The executor's unreachability conclusion was **false**, and the falsity mattered. `2607261520-close-scripts-dirty-base-safety-audit.md` reproduced the branch deterministically: a tracked file at `index ≠ HEAD ≠ worktree` (achievable in the gate→merge window the code's own comment documents) makes `merge --squash` refuse *and* makes the subsequent `reset --merge HEAD` fail (exit 128). The executor's five constructions tested only the `index == HEAD` variant of "refusal" and generalized incorrectly to all refusals. Worse than the false conclusion: on that reachable path, the original rollback-failure message asserted three things that were all false (a conflicted squash present, unmerged entries present, script would refuse to restart) and told the user to run `git reset --hard HEAD` — which would have destroyed the exact concurrent-writer content this entire plan exists to protect.

Fixed same-day via `2607261821-rollback-refusal-message-split-patch.md` (commits `baf8d2a`, `4e39c28`, ridden on this branch, not a separate plan cycle): `safe_rollback`/`Invoke-SafeRollback` now branch on whether `unmerged_paths` is non-empty — non-empty keeps the original (now-accurate) message; empty emits new text stating nothing was changed, naming the `index != HEAD != worktree` cause, and explicitly instructing **do NOT run `git reset --hard`**. The "unreachable" wording was downgraded to "not constructible as a deterministic regression case; reachable only through the documented gate→merge window" in `tests/README.md`, both new suites' inline comments, and the execution log (which also gained a correction blockquote). No test assertion was added, removed, or changed — gate semantics are unaffected; this was a message-accuracy fix only.

**Files Changed (ACTUAL):**
| File | Change Type | Planned? | Details |
|------|-------------|----------|---------|
| `projex-squash-close.sh` | Modified | Yes | Checked rollback (Step 2) + message split (patch) |
| `projex-squash-close.ps1` | Modified | Yes | Same, PowerShell parity |

**Verification:** Regression suites green throughout (see Step 3). Patch verification independently reproduced the false-message reality: `merge --squash` refusal with zero unmerged entries, `reset --merge HEAD` failing with exit 128, both worktree and index copies of the file surviving intact — proving `reset --hard` would have destroyed both.

**Issues:** See Deviation above — this is the single most consequential finding of the whole execution/audit/patch cycle. Resolved.

---

### Step 3: Add Dirty-Base Regression Suite to `tests/`

**Planned:** Extend the existing `tests/` suite (not a parallel one) with a 10-scenario matrix — tracked dirt, submodule noise, untracked bystanders/collisions, conflicted-squash rollback, happy paths, non-branch `Base`, mismatched/detached origin, nested topology — registered in both runners, README + `CLAUDE.md` (later: `AGENTS.md`) updated.

**Actual:** `tests/dirty-base.test.sh` and `.ps1` added, 139 assertions each, following existing `chk`/`Chk` conventions and throwaway-repo discipline. Registered in `tests/run-all.{sh,ps1}`. `tests/run-all.sh` → `PASS=255 FAIL=0` (116 pre-existing + 139 new); `pwsh tests/run-all.ps1` → `PASS=211 FAIL=0` (72 + 139). Zero pre-existing assertion changed. **Negative control** (new suites run against pre-change scripts extracted from `main`) → `PASS=120 FAIL=19` both platforms, identical failure sets, directly reproducing both motivating bugs (`squash unstaged edit survives`, `rebase collision ephemeral tip unmoved`).

**Deviation:** `CLAUDE.md` is gitignored in this repo (`.gitignore:2`) and only exists in the main checkout — unreachable from the worktree. The plan named it as the file to update; the tracked repo-instructions file is actually `AGENTS.md`, which had no `tests/` content at all. Applied the count update there instead (466 = 255+211). Flagged as a handoff: the main checkout's untracked `CLAUDE.md` still reads a stale figure and was deliberately left alone as user-owned content (later becomes audit finding C3, deliberately not actioned).

Collision-test fixture was strengthened mid-step: the first version didn't advance the base, so the rebase was a no-op and the test passed against the *pre-change* script too. Caught by the negative control, not the suite itself.

**Files Changed (ACTUAL):**
| File | Change Type | Planned? | Details |
|------|-------------|----------|---------|
| `tests/dirty-base.test.sh` | Created | Yes | 232→234 lines (patch added 14 more) |
| `tests/dirty-base.test.ps1` | Created | Yes | 261→263 lines (patch added 14 more) |
| `tests/run-all.sh` | Modified | Yes | +2 registration line |
| `tests/run-all.ps1` | Modified | Yes | +2 registration line |
| `tests/README.md` | Modified | Yes | +8, later +12/-5 via patch |
| `AGENTS.md` | Modified | No (plan said `CLAUDE.md`) | +8: tests/ structure entry, count |

**Verification:** Both runners green with exact expected deltas; negative control reproduces both motivating bugs and nothing else (19 failures, identical labels both platforms).

**Issues:** None beyond the fixture bug caught and fixed within the same step.

---

### Step 4: Align Close Workflow Contract

**Planned:** Rewrite `close-projex.md`'s finalization gate section to match actual script behavior — two named gates (tracked-clean integration checkout vs fully-clean execution worktree), pre-flight (not "enforce") language, `RepoRoot`↔`Base` pairing documented, non-branch `Base` rejection documented, no claim of automatic hard-reset.

**Actual:** `close-projex.md` §7 rewritten as planned: gate table, "pre-flight checks, not enforcement" paragraph, `<repo-root>`↔`{base-branch}` pairing rule (including the stacked-parent case), local-branch requirement for `{base-branch}`, rebase's extra pre-rebase collision check documented with rationale, "main working directory" language replaced with "originating/base worktree" language, §8 note that stashing is caller-owned.

**Deviation:** None from plan text. Sequencing note in the plan ("do not ship this doc relaxation ahead of Step 1's rebase fix") was honored — verified by commit order (`75725cc` after `5448570`/`9ce9628`).

**Files Changed (ACTUAL):**
| File | Change Type | Planned? | Details |
|------|-------------|----------|---------|
| `close-projex.md` | Modified | Yes | +27/-lines: §7 gate rewrite, §8 stash note |

**Verification:** Repository-wide search for `reset --hard` finds no claim of automatic execution — only the `AGENTS.md` project rule, `debug-projex.md`'s unrelated per-attempt worktree rollback, plan/redteam prose, and approval-gated guidance strings. Search for "enforce" in `close-projex.md` returns only the sentence denying it.

**Issues:** None.

---

## Complete Change Log

> **Derived from:** `git diff --stat main..projex/2607261121-close-scripts-dirty-base-safety` — 18 files changed, 1565 insertions(+), 91 deletions(-).

### Files Created
| File | Purpose | Lines | In Plan? |
|------|---------|-------|----------|
| `tests/dirty-base.test.sh` | Dirty-base regression matrix (POSIX) | 234 | Yes |
| `tests/dirty-base.test.ps1` | Dirty-base regression matrix (PowerShell) | 263 | Yes |
| `.projex/closed/2607261821-rollback-refusal-message-split-patch.md` | Post-audit correction record | 187 | No (audit-triggered) |

### Files Modified
| File | Changes | In Plan? |
|------|---------|----------|
| `projex-squash-close.sh` | Dirty-base gate, safe rollback, message split | Yes |
| `projex-squash-close.ps1` | Same, parity | Yes |
| `projex-merge-close.sh` | Dirty-base gate | Yes |
| `projex-merge-close.ps1` | Same, parity | Yes |
| `projex-rebase-close.sh` | Dirty-base gate + pre-rebase collision check | Yes |
| `projex-rebase-close.ps1` | Same, parity | Yes |
| `close-projex.md` | §7 gate rewrite, §8 stash note | Yes |
| `SKILL.md` | §Branch Finalization: "originating worktree" precision (patch) | No (audit-triggered) |
| `tests/run-all.sh` / `tests/run-all.ps1` | Register `dirty-base` suite | Yes |
| `tests/README.md` | Coverage rows + non-deterministic-branch note | Yes |
| `AGENTS.md` | tests/ structure entry, assertion count | Yes (file substituted for planned `CLAUDE.md`) |

### Files Deleted
None (`read_file.ps1`'s presence in the branch diff is stale content from before the branch point — `main` deleted it separately in `45c11d4`; the branch never touched it, so it merges as a clean deletion, not a branch-authored change).

### Planned But Not Changed
None — every file in the plan's Key Files table was touched, modulo the `CLAUDE.md`→`AGENTS.md` substitution recorded above.

---

## Success Criteria Verification

### Acceptance Criteria Summary

| # | Criterion | Result | Evidence |
|---|-----------|--------|----------|
| 1 | Worktree-mode finalizers verify `RepoRoot`↔`Base` pairing; arbitrary parent topology preserved | PASS | Nested `projex/outer`→`projex/inner` case; dirty-parent-worktree case |
| 2 | Non-branch `Base` exits 1 naming resolved ref type | PASS | Tag/SHA/remote-ref × 3 types × 2 shells |
| 3 | All six exit 1 pre-mutation on tracked dirt, submodule noise excluded | PASS | Unstaged+staged × 3 × 2; submodule-dirty asserted to succeed |
| 4 | Unrelated untracked/ignored content preserved; collision fails pre-mutation, no ephemeral rewrite | PASS | Bystander + collision cases; ephemeral tip SHA asserted unchanged |
| 5 | `rebase-close` detects collision before rebasing | PASS | Reproduces E4 against pre-change script (fails there, passes here) |
| 6 | Dirty execution worktree still separately rejected | PASS | Pre-existing `worktree.test.*` assertions unchanged, green |
| 7 | No automatic `reset --hard`; `reset --merge HEAD` restores clean state | PASS | grep finds none executable; conflicted-squash case asserts no hard-reset in output |
| 8 | Rollback-failure branch reachable and exercised | **PARTIAL — see below** | Escape clause used; outcome stands, original reasoning was wrong |
| 9 | Existing exit-code contract retained | PASS | Clean success, exit 2, exit 1, branch deletion, worktree removal all unchanged |
| 10 | Dirty-base cases live in `tests/`, run from both runners | PASS | Registered, counted in totals |
| 11 | Existing suite still passes both platforms | PASS | `PASS=255 FAIL=0` sh, `PASS=211 FAIL=0` ps1; deltas exactly +139 each |
| 12 | Docs distinguish the two gates as pre-flight | PASS | `close-projex.md` §7 table + explicit non-enforcement paragraph |

**Overall:** 11/12 PASS, 1/12 PASS-with-corrected-justification. No FAIL.

### Criterion 8 — the honest account

**Verification Method:** Independent construction of the `reset --merge HEAD` rollback-failure branch, first by the executor (five constructions), then by the auditor (six constructions, one novel).

**Evidence:**
```
Executor's conclusion: "unreachable through the scripts' own entry points... a squash either
conflicts... or refuses before mutating anything (rollback is a no-op)."

Audit's reproduction: tracked file at index ≠ HEAD ≠ worktree (achievable in the gate→merge
window) makes `merge --squash` refuse (exit≠0, no MERGE_HEAD, zero unmerged paths) AND makes
`git reset --merge HEAD` subsequently fail (exit 128, "Entry 'b.txt' not uptodate").
```

**Result:** The plan's own escape clause ("if no such state can be constructed, record that finding and the branch's unreachability") was invoked — but on a false premise. The executor's five constructions tested only the `index == HEAD` variant of "refusal" and over-generalized to all refusals; the audit's sixth construction is the counterexample. The branch is real, reachable, and — critically — its handling was wrong in a way that mattered: the message it printed on that path recommended the exact destructive command (`git reset --hard HEAD`) this plan exists to forbid, on false pretenses (claiming a conflicted squash and unmerged entries that don't exist there).

**Disposition:** The criterion's outcome — "no deterministic regression test is possible for this branch" — still holds; audit and patch both confirm no test can pre-seed the concurrent-writer race a gate rejects up front. What was wrong was the *reasoning offered for* that outcome, and — more importantly — the *code shipped believing it*. Both were corrected same-day by `2607261821-rollback-refusal-message-split-patch.md`, verified against the shipped functions on both platforms, with zero change to gate semantics or test assertions. Marked `[~]` in the plan, not `[x]` — the criterion was met in letter, missed in spirit until the audit caught it.

---

## Deviations from Plan

### Deviation 1: `CLAUDE.md` → `AGENTS.md`
- **Planned:** Update `CLAUDE.md`'s assertion count.
- **Actual:** Updated `AGENTS.md` instead.
- **Reason:** `CLAUDE.md` is gitignored in this repo, exists only in the main checkout, unreachable from the worktree. `AGENTS.md` is the tracked repo-instructions file and had no `tests/` content at all — added it.
- **Impact:** Estimated Changes stayed at 13 files; only the identity of the 13th changed. The main checkout's `CLAUDE.md` still carries a stale count (audit finding C3) — deliberately left, user-owned.
- **Recommendation:** No plan update needed; correctly logged as a deviation at execution time.

### Deviation 2: Rollback-failure "unreachable" claim was false
- **Planned (implicitly):** The escape-clause finding, once recorded, would stand as accurate.
- **Actual:** Falsified by independent audit; corrected by same-day patch.
- **Reason:** Executor's constructions tested an incomplete state space.
- **Impact:** No code defect shipped to users beyond a misleading error message on a narrow, hard-to-trigger path — but that message actively pointed at data loss. Highest-severity finding of the whole cycle.
- **Recommendation:** See Key Insights below — this is the execution's central lesson.

---

## Issues Encountered

### Issue 1: Rollback-failure branch reachability misjudged
- **Description:** See Deviation 2 and Criterion 8 above.
- **Severity:** High (message correctness on a data-loss-adjacent path), though the underlying gate logic was never wrong.
- **Resolution:** `2607261821-rollback-refusal-message-split-patch.md`, commits `baf8d2a` + `4e39c28`.
- **Time Impact:** Same-day; no delay to close.
- **Prevention:** See Key Insights.

### Issue 2: Collision-test fixture initially a no-op
- **Description:** First version of the rebase-collision test didn't advance the base branch, so the replayed rebase had nothing to do and the test passed against both the fixed and the pre-change script.
- **Severity:** Medium — would have shipped a green assertion proving nothing.
- **Resolution:** Added fixture mode 2 (unrelated base advance) so the rebase genuinely replays.
- **Time Impact:** Caught within Step 3, no delay.
- **Prevention:** The negative control (run new suite against pre-change scripts) is exactly the mechanism that caught this — audit explicitly recommends promoting it from ad-hoc to documented practice in `tests/README.md`.

---

## Key Insights

### Lessons Learned

1. **"Refusal" is not one state — a test suite that tests only the state it can construct will silently generalize past what it proved.**
   - Context: Step 2's five reachability constructions all happened to test `index == HEAD` refusals; none tested `index ≠ HEAD ≠ worktree`.
   - Insight: An unreachability claim is only as strong as the enumeration behind it. Five constructions felt thorough; a sixth (independently found by the audit) broke the conclusion.
   - Application: When declaring a branch "unreachable" under an escape clause, enumerate the *dimensions* of the state space (here: relationship between index/HEAD/worktree, not just "conflict vs. no-conflict") before concluding, not just a list of attempts.

2. **An error message is part of the safety surface, not documentation of it.**
   - Context: The gate itself (Step 1) was correct throughout. The bug was entirely in what the script *said* on one narrow path.
   - Insight: A script that changes nothing but tells the user to run a destructive command is not neutral — it is actively worse than silence, because it's trusted precisely at the moment things went wrong.
   - Application: Error messages on failure/rollback paths need the same verification rigor as the mutating logic itself — audit explicitly, "the gate protects the tree; the message protects the human."

3. **Negative controls (new tests × old code) catch what positive tests can't.**
   - Context: The collision-fixture no-op bug (Issue 2) passed the new suite even before the fix existed, because the fixture didn't actually exercise the bug.
   - Insight: A green suite proves the code satisfies the suite, not that the suite tests the right thing. Running the new suite against the pre-change baseline is a cheap, high-value check that the suite would actually have failed before the fix.
   - Application: Audit recommends promoting this from an ad-hoc step here to a documented `tests/README.md` practice — not yet done, flagged as a Recommendation below.

### Pattern Discoveries

1. **Origin-worktree/base-branch pairing as an explicit, asserted contract.**
   - Observed in: All six finalizers now assert `RepoRoot`'s HEAD literally equals the resolved `Base`, rather than assuming it or falling back to `main`.
   - Description: Worktree-mode scripts previously trusted the caller's bookkeeping; now they verify it and refuse to guess.
   - Reuse potential: Any future script accepting a worktree path + expected branch pairing should assert, not assume, per this pattern.

2. **Pre-flight, not enforcement — documented explicitly as a limitation, not a guarantee.**
   - Observed in: `close-projex.md` §7's new paragraph stating the gate doesn't re-check between validation and mutation.
   - Description: Rather than overclaim safety, the workflow doc now names the TOCTOU window directly and says Git's own overwrite refusal is the real backstop.
   - Reuse potential: Any pre-flight check in this framework should be documented with the same honesty about its binding window.

### Gotchas / Pitfalls

1. **A file untouched since branch point still shows as "added" in `diff main..branch` if the base deleted it after divergence.**
   - Trap: `read_file.ps1` appears in `git diff --stat main..<ephemeral>` as a full addition (90 lines), which could be misread as branch-authored work.
   - How encountered: Reviewing the branch diff during close; cross-checked `git diff <merge-base>..<ephemeral> -- read_file.ps1` (empty) against `main`'s own `45c11d4` deletion commit.
   - Avoidance: When a stat diff shows unexpected file churn, diff against the merge-base, not just one side, before attributing the change.

### Technical Insights

- `git reset --merge HEAD` genuinely differs from `--hard` in exactly the case that matters: it fails loudly (exit 128) rather than silently discarding when the index doesn't match `HEAD` cleanly — verified independently by both the executor and the audit.
- Squash merges create no `MERGE_HEAD`, which is why `git merge --abort` is unavailable to squash-close and why the rollback path needed its own design rather than reusing merge/rebase's abort mechanisms.
- `assume-unchanged`/`skip-worktree` paths are invisible to `git status --porcelain` by Git's own design; the gate inherits that blind spot deliberately rather than trying to special-case it (recorded as a known hole in the plan's Assumptions, not rediscovered as a surprise).

---

## Recommendations

### Immediate Follow-ups
- [ ] Promote the negative-control technique (new tests × pre-change code) from an ad-hoc verification step to a documented practice in `tests/README.md` (audit's "Process" recommendation, not yet actioned).

### Future Considerations
- Re-check `tracked_dirt` immediately before `merge --squash` to close the gate→merge TOCTOU window entirely — would make the original "unreachable" claim retroactively true. Explicitly out of scope here (plan-sized, changes gate semantics across 3 close types × 2 platforms).
- `AGENTS.md` is broadly stale beyond this plan's touched sections (lists outdated workflow lifecycles, omits `projex-rebase-close`) — separate concern, not attempted here.
- `SKILL.md` § Branch Finalization's "originating worktree" wording was corrected by the patch; a broader pass for similar "main working directory" assumptions elsewhere in the framework docs was not attempted.
- Main checkout's gitignored `CLAUDE.md` still reads a stale `188 assertions` figure (true count is 466) — user-owned, flagged, not corrected.

### Plan Improvements
If this plan were executed again: the escape-clause language for "record unreachability" should require enumerating the state-space dimensions considered, not just listing constructions tried — would likely have surfaced the `index ≠ HEAD ≠ worktree` gap during execution rather than at audit.

---

## Related Projex Updates

### Documents to Update
| Document | Update Needed |
|----------|---------------|
| `2607261121-close-scripts-dirty-base-safety-plan.md` | Marked Complete, walkthrough linked — done |
| `2607261157-close-scripts-dirty-base-safety-redteam.md` | Disposition updated to closed, findings mapped to verification — done |
| `2607261520-close-scripts-dirty-base-safety-audit.md` | Closed alongside plan — its conditions (C1, C2, C4) are discharged by the patch; C3 explicitly deferred (user-owned `CLAUDE.md`) |
| `2607261821-rollback-refusal-message-split-patch.md` | Already born closed on the branch — nothing to move |

### New Projex Suggested
| Type | Description |
|------|-------------|
| Patch or small Plan | Promote negative-control technique into `tests/README.md` as documented practice |
| Plan | Close the gate→merge TOCTOU window with an immediate-pre-merge re-check (would retroactively validate the original unreachability claim) |

---

## Appendix

### Test Output

```
tests/run-all.sh (final, post-patch)
  resolve-conflicts 30 | resume 52 | worktree 34 | dirty-base 139
  === total: PASS=255 FAIL=0

pwsh tests/run-all.ps1 (final, post-patch)
  resolve-conflicts 33 | worktree 39 | dirty-base 139
  === total: PASS=211 FAIL=0

Negative control (new suites × pre-change scripts extracted from main):
  PASS=120 FAIL=19 both platforms, identical failure labels — reproduces:
    "squash unstaged edit survives (want 'PRECIOUS' got 'v0')"  (the motivating memo's data loss)
    "rebase collision ephemeral tip unmoved"                     (redteam's E4 history rewrite)
```

### References
- Commits on `projex/2607261121-close-scripts-dirty-base-safety`: `9ce9628`, `5448570`, `75725cc`, `baf8d2a`, `4e39c28`
- `2607261121-close-scripts-dirty-base-safety-log.md` — full execution log with per-step evidence
- `2607261157-close-scripts-dirty-base-safety-redteam.md` — pre-execution adversarial review, 8 findings absorbed
- `2607261520-close-scripts-dirty-base-safety-audit.md` — post-execution independent audit, falsified criterion 8's reasoning
- `2607261821-rollback-refusal-message-split-patch.md` — same-day correction of the audit's findings
