# Audit: Close Scripts Dirty Base Safety — Execution

> **Audit Date:** 2026-07-26 | **Auditor:** audit-projex (independent subagent) | **Work Period:** 2026-07-26 12:40–13:50
> **Subject:** Execution of `2607261121-close-scripts-dirty-base-safety-plan.md` on branch `projex/2607261121-close-scripts-dirty-base-safety` (3 commits, unmerged, worktree live)
> **Related:** 2607261121-close-scripts-dirty-base-safety-plan.md | 2607261121-close-scripts-dirty-base-safety-log.md | 2607261157-close-scripts-dirty-base-safety-redteam.md | 2607132112-projex-rebase-close-scripts-redteam.md

---

## Audit Summary

**Claim:** Dirty-base safety gate added to all six close finalizers; destructive squash rollback removed; 139-assertion regression suite added per platform; close workflow contract realigned. 11/12 success criteria met, 12th resolved under an escape clause.

**Verdict:** Verified

**Assessment:** Completeness: High | Correctness: High | Quality: High | Value: High

Every material claim was re-derived independently — suites re-run, negative control rebuilt from scratch, gate ordering read from the shipped files, diffs taken against `main` rather than trusted. 11 of 12 executor claims verified exactly. The twelfth (criterion 8, rollback-failure branch) reaches the right *conclusion* by the wrong *reasoning*: the branch is not unreachable, and on the path that does reach it the error message is factually wrong and recommends a destructive command.

**Top Issues:**
1. Criterion-8 unreachability rationale is falsified — the `reset --merge HEAD` failure branch is reachable through the TOCTOU window the script's own comment documents. Reproduced deterministically.
2. On that reachable path the failure message asserts three things that are false, and directs the user to `git reset --hard HEAD` — which would destroy exactly the uncommitted third-party content this plan exists to protect.
3. Execution log internally inconsistent: "Four constructions were probed" heading over a five-row table; Issues section says "five".

---

## Claims vs Evidence

| # | Claim | Evidence | Status | Notes |
|---|---|---|---|---|
| 1 | 3 commits: `9ce9628`, `5448570`, `75725cc` | `git log main..<eph>` | ✓ | Exact match, in that order |
| 2 | `run-all.sh` → 255/0; `run-all.ps1` → 211/0; new suites 139 each | Both re-run by auditor in the live worktree | ✓ | sh: 30+52+34+139=255. ps1: 33+39+139=211 |
| 3 | No pre-existing assertion changed — "pure additions" | `git diff --name-status main..<eph> -- tests/` | ✓ | Only `run-all.{sh,ps1}` (1 registration line each), `README.md` (+8), 2 new files. **Zero** existing `*.test.*` bytes touched |
| 4 | Negative control 120/19, identical failure sets both platforms | Rebuilt: `git archive main` + new suites only | ✓ | sh 120/19, ps1 120/19, **failure labels line-for-line identical**. Reproduces both motivating bugs |
| 5 | All six finalizers gate on porcelain/`refs/heads`/`RepoRoot`-HEAD | Read all 6 shipped files | ✓ | All three checks present in squash/merge/rebase × sh/ps1 |
| 6 | Rebase does untracked-collision check at `RepoRoot` pre-rebase | Line numbers in shipped files | ✓ | `.sh` collision@236 < rebase@243; `.ps1` collision@201 < rebase@208. Checkout mode covered by `git checkout` refusing first (documented inline) |
| 7 | Both `reset --hard HEAD` calls gone → checked `reset --merge HEAD` | grep all 6 finalizers | ✓ | Zero executable `reset --hard` remains; 3 residual mentions are comments/guidance text only |
| 8 | `close-projex.md` §7 rewritten, two-gate table, pre-flight language | Diff read in full | ✓ | Exceeds claim — also adds repo-root/base pairing rules, local-branch requirement, rebase collision paragraph, stash-ownership note in §8 |
| 9 | 11/12 criteria met; 12th `[~]` under escape clause, branch unreachable | Independent construction against live git | ⚠ | Conclusion (no deterministic regression test possible) holds. **Justification falsified** — see Finding C1 |
| 10 | `CLAUDE.md` gitignored; `AGENTS.md` updated instead | `git ls-files`, `.gitignore:2` | ✓ | `CLAUDE.md` untracked; `AGENTS.md` tracked, count 466 = 255+211 correct |
| 11 | Steps 1–2 share a commit (overlapping regions) | Commit contents | ✓ | Documented as Deviation 2 |
| 12 | Execution worktree clean | `status --porcelain --ignored=matching` | ✓ | Empty |

---

## Objective Verification

### Criterion 8: rollback-failure branch reachable and exercised — `[~]`

**Evidence:** Six constructions probed against live git in throwaway repos (auditor's own, independent of the executor's five).

**Findings:**

Executor's stated conclusion: *"unreachable through the scripts' own entry points. Step 1's tracked-clean gate plus the pre-existing in-progress gate guarantee the tree is tracked-clean when `merge --squash` runs; from there a squash either conflicts (index and worktree agree → `reset --merge` succeeds) or refuses before mutating anything (rollback is a no-op)."*

The second half of that disjunction is **false**. Refusal does not imply the rollback is a no-op. Reproduced:

```
tracked file b.txt: index = "S", worktree = "W"   (index ≠ HEAD ≠ worktree)
git merge --squash eph
  → error: Your local changes to the following files would be overwritten by merge: b.txt
  → exit 2, no MERGE_HEAD, no unmerged paths — nothing mutated
git reset --merge HEAD
  → error: Entry 'b.txt' not uptodate. Cannot merge.
  → fatal: Could not reset index file to revision 'HEAD'.   exit 128
```

`safe_rollback` fires on **any** non-zero `merge --squash` exit (`if ! git ... merge --squash`), not only on conflict, so this reaches the branch.

The executor did find this failure mode (table row 1) but dismissed it as *"the state cannot be produced from outside, because nothing runs between the script's `merge --squash` and its rollback."* That is the wrong test. The state does not need to arise between the merge and the rollback — it needs to exist **before the merge**, i.e. inside the gate→merge window. The executor's `assume-unchanged` / `skip-worktree` rows probed only the `index == HEAD` variant (rollback correctly a no-op) and generalised from it; the `index ≠ HEAD ≠ worktree` variant was never combined with the refusal path.

That window is not hypothetical — the shipped code names it:

> `# Pre-flight (not a guarantee): ... Nothing re-checks between here and the merge, so a concurrent writer can still dirty it`

**Verification:** ⚠ Partial — outcome right, reasoning wrong.

**Issues:** The stronger claim ("unreachable") is now recorded in three places (`tests/README.md`, both new suites' inline comments, the execution log) and one of them, `tests/README.md`, states it as a coverage justification a future maintainer will rely on.

---

## Code/Implementation Inspection

### `projex-squash-close.{sh,ps1}` — `safe_rollback` / `Invoke-SafeRollback`

**Claimed:** No automatic `reset --hard`; checked `reset --merge HEAD`; failure branch reports approval-gated recovery.
**Actual:** As claimed — Quality: High for the reachable path, **Low for the failure branch's message**.

**Issues Found:**

- **The failure message is false on the reachable path** — Severity: Medium.
  On the construction above it says:
  1. *"the conflicted squash is STILL in '$REPO_ROOT'"* — there is no squash; git refused before mutating.
  2. *"This script will refuse to start again until that state is cleared (it detects the unmerged entries)"* — there are no unmerged entries and no `MERGE_HEAD`, so `in_progress_op` returns nothing and the script **will** start again.
  3. *"discard it with 'git -C $REPO_ROOT reset --hard HEAD'"* — that command discards the concurrent writer's staged **and** worktree content. The plan's entire purpose is preventing loss of exactly that content. Directing a human to it under a false premise is the sharpest edge in the delivery.

  No data is lost by the script itself (it exits 1 having changed nothing); the harm is misdirection.

**Undocumented:** None material. Deviations 1–5 in the log cover the `CLAUDE.md`→`AGENTS.md` substitution, the combined 1–2 commit, two extra message rewrites, a mid-step fixture strengthening, and the absent task tool. All were confirmed against the diff and all are accurate.

### Gate placement — all six finalizers

Gate marker vs first mutation, read from shipped files:

| File | Gate | First mutation |
|---|---|---|
| `projex-squash-close.sh` | 152 | checkout/merge below dirt check @178 |
| `projex-squash-close.ps1` | 128 | 161 |
| `projex-merge-close.sh` | 138 | 178 |
| `projex-merge-close.ps1` | 113 | 146 |
| `projex-rebase-close.sh` | 177 | rebase @243, collision check @236 |
| `projex-rebase-close.ps1` | 148 | rebase @208, collision check @201 |

Ordering is correct everywhere. The rebase case — the one the original defect turned on — puts the collision check before the *rebase*, not merely before the fast-forward. Checkout mode is argued (correctly) to get the refusal free from `git checkout`, which runs before its rebase.

---

## Testing Validation

**Coverage:** 139 new assertions per platform across 10 scenario sections; identical section headers in both suites; the negative control produced **identical failure label sets** on both platforms, which is behavioural parity evidence rather than count parity.

**Execution:** All pass, both platforms, re-run by the auditor. No flakiness observed across 4 full runs (2 delivered + 2 negative control).

**Quality — high marks:**
- Every refusal case asserts non-mutation *directly* (base ref, ephemeral ref, file bytes, worktree registration), not just `exit 1`. This is what makes the negative control able to catch a half-done close.
- Fixture mode 2 (base advanced by an unrelated commit) is what makes the rebase-collision case genuinely reproduce the pre-fix bug. The log records that the first version of this fixture passed against the *pre-change* script and was caught by the negative control, not the suite — an honest and unusually valuable disclosure.
- A known gap (`skip-worktree` dirt invisible to the gate) is asserted as a test rather than hidden.

**Missing:** The reachable rollback-failure path (Finding C1). A test cannot easily pre-seed it — the gate rejects the state deterministically — but the *message* can be corrected without a test, and the branch can be made to describe what it actually knows.

**Pre-existing parity gap (not introduced here):** `resume.test.sh` (52 assertions) has no `.ps1` counterpart. Baselines are `.sh` 116 vs `.ps1` 72. The new suite is a rare 139/139 exact-parity addition, so the delivery improves the ratio rather than worsening it.

---

## Documentation Audit

**Completeness:** `close-projex.md` §7 — Complete, exceeds claim. `AGENTS.md` — scoped fix Complete and arithmetically correct (466). `tests/README.md` — Complete, but carries the overstated unreachability claim.

**Accuracy:** Matches implementation, with one exception — the `tests/README.md` "knowingly unexercised / unreachable through the scripts' own entry points" paragraph asserts more than is true.

**Quality:** High. The two-gate table and the "pre-flight checks, not enforcement" paragraph are the clearest statement of the TOCTOU boundary anywhere in the framework — and ironically, that paragraph is the evidence that falsifies criterion 8's rationale.

---

## Gap Analysis

### Promised But Not Delivered

| Promise | Status | Impact |
|---|---|---|
| Criterion 8 — rollback-failure branch exercised | Not delivered; escape clause invoked with a falsified rationale | Medium |
| Plan Key Files: update `CLAUDE.md` assertion count | Substituted with `AGENTS.md`; local `CLAUDE.md` still reads `188 assertions` | Low — file is gitignored and user-owned; substitution disclosed in Deviations 1 with an explicit handoff note |

Nothing else in the plan's scope quietly failed to land. `projex-abandon` is explicitly Out of Scope, so its absence from the six is correct, not a gap.

### Undocumented Issues

| Issue | Severity | Affects |
|---|---|---|
| Rollback-failure message false on its reachable path; recommends `reset --hard` | Medium | Human operator hitting a gate→merge race |
| `safe_rollback` fires on refusal-without-mutation, where a rollback is semantically meaningless | Low | Same |
| Log: "Four constructions were probed" over a five-row table; Issues section says "five" | Low | Reader of the log |

### Already-Documented Issues (credit where due)

The log itself discloses, unprompted: `AGENTS.md` is broadly stale beyond scope; `SKILL.md` § Branch Finalization is now imprecise about "the main working directory"; the local `CLAUDE.md` handoff. None of these are audit discoveries — they were surfaced by the executor first.

---

## Quality Assessment

### Completeness: High
**Strengths:** All 12 plan files touched as specified; both platforms; both runners; docs realigned; deviations enumerated with reasons.
**Gaps:** Criterion 8 only.

### Correctness: High
**Works:** Gate ordering — Yes, all six. Negative control reproduces both motivating bugs — Yes. Existing coverage intact — Yes, verified by diff, not by assertion count alone.
**Bugs:** Rollback-failure message content — Severity: Medium. No correctness defect found in any gate, any ordering, or any assertion.

### Code Quality: High
**Positive:** Comments explain *why* a check exists and what it deliberately does not count (untracked, ignored, submodule dirt) — the `.projexwt/`-self-block rationale is the kind of thing that prevents a future "simplification" from reintroducing the bug. Error messages name the resolved ref type rather than saying "invalid".
**Concerns:** `.sh`/`.ps1` duplication persists (explicitly Out of Scope). One `safe_rollback` message doing double duty for two semantically different failures.
**Tech Debt:** Low, and net-reduced — 278 lines of new test code guarding history-rewriting scripts.

### Value Delivered: High
**Intended:** Stop the close scripts from destroying uncommitted work in the integration checkout.
**Actual:** Achieved. The negative control is the proof: 19 assertions that fail against `main` and pass against the branch, including `squash unstaged edit survives` and `rebase collision ephemeral tip unmoved` — the two motivating bugs, dead.
**Impact:** User: Positive. The class of silent data loss this addressed was real and had already been observed.

---

## Open Findings

### Undocumented Discoveries
- The reachable rollback-failure construction (Finding C1) — index ≠ HEAD ≠ worktree on any tracked file at merge time.
- `safe_rollback` is invoked for `merge --squash` refusals as well as conflicts; the two states want different handling and different messages.

### Impact Analysis
- **Downstream:** `close-projex.md` §7 is now the framework's reference statement on pre-flight-vs-enforcement. Other workflows that copy its gate language should be checked for the old blanket `git status --porcelain` instruction.
- **Future enabled:** The negative-control technique (new suite × old scripts) is reusable and arguably belongs in `tests/README.md` as a standing practice — it caught a fixture bug the suite itself could not.
- **Risks:** A maintainer trusting `tests/README.md`'s "unreachable" claim will not revisit the branch. Likelihood: High if the message is left as-is.

### Improvements
- **Could be better:** Split `safe_rollback`'s message by state — `unmerged_paths` non-empty → the current text; empty → "the merge refused before mutating; nothing was changed; your uncommitted content is intact — do NOT hard-reset."
- **Would make excellent:** Re-check `tracked_dirt` immediately before `merge --squash` and abort rather than roll back. Closes the window that makes this branch reachable at all, and makes the original unreachability claim true.

---

## Findings

### Critical (Must Address)
None. No delivered artifact loses data, misreports a passing test, or ships a broken gate.

### Significant (Should Address)
- **C1 — Rollback-failure branch is reachable; message is false there and recommends a destructive command** — the three assertions in the message (conflicted squash present, unmerged entries present, script will refuse to restart) are all false on that path, and `git reset --hard HEAD` would destroy the uncommitted content the plan exists to protect → split the message on `unmerged_paths` emptiness; correct the "unreachable" wording in `tests/README.md`, both suites' inline comments, and the log.

### Minor (Nice to Fix)
- **C2 — Log says "Four constructions" over five rows; Issues section says "five"** → make it five.
- **C3 — Local gitignored `CLAUDE.md` still reads `188 assertions`** → user-owned; correct or leave, but the figure is now wrong by 278.
- **C4 — `SKILL.md` § Branch Finalization** still says "The main working directory must already be on the base branch" → it is the *originating* worktree, and the scripts now assert it. Already flagged by the executor.

### Positive
- The negative control was not asked for by the plan as a gating check yet was built, run on both platforms, and used to catch a fixture that would otherwise have shipped as a false-positive test. That single act is worth more than most of the assertion count.
- Every refusal assertion checks non-mutation of refs and bytes, not exit codes. This is the difference between a suite that proves safety and one that proves an error was printed.
- The execution log's Deviations section volunteers five deviations with reasons, including one (the `CLAUDE.md` substitution) that could easily have gone unmentioned.

---

## Recommendations

**Immediate:** Fix C1's message split and the three "unreachable" wordings. Patch-sized.
**Future:** Re-check tracked cleanliness immediately before `merge --squash`, closing the window. Plan-sized — it changes gate semantics and needs its own tests across all three close types × 2 platforms.
**Process:** Promote the negative control (new suite × pre-change scripts) from an ad-hoc step to a documented practice in `tests/README.md`. It is the only thing in this execution that caught a test which passed for the wrong reason.

---

## Final Verdict

**Status:** Accept with Conditions

**Overall Assessment:**
- Completeness: High
- Correctness: High
- Quality: High
- Value: High

**Conditions:**
- [ ] Correct the `safe_rollback` failure message so it does not claim a conflicted squash, does not claim the script will refuse to restart, and does not recommend `reset --hard` on the refusal path.
- [ ] Downgrade "unreachable through the scripts' own entry points" to "not constructible as a deterministic regression case; reachable only through the documented gate→merge window" in `tests/README.md`, both new suites, and the execution log.
- [ ] Fix the four/five construction-count inconsistency in the log.

**Sign-off:** Yes — conditions are message-and-wording corrections, not rework. The gates, the ordering, the suites, and the negative control all hold under independent re-derivation. The one falsified claim is a claim *about* the work, not a defect *in* the shipped gate.
