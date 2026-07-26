# Red Team: Close Scripts Dirty Base Safety

> **Created:** 2026-07-26 | **Lead:** Claude (Opus 5)
> **Subject:** 2607261121-close-scripts-dirty-base-safety-plan.md
> **Related:** 2607132112-projex-rebase-close-scripts-redteam.md | 2607260233-worktree-squash-close-dirty-base-reset-memo.md
> **Disposition (2026-07-26):** All 8 findings absorbed into the plan via revise; see that document's Revision Log. Findings addressed in specification, then verified at execution — see 2607261121-close-scripts-dirty-base-safety-walkthrough.md. Top Vulnerability 1 (rebase pre-rewrite collision) verified fixed via the collision regression case; Top Vulnerability 2 (Step 2 policy-only rationale) confirmed as stated; Top Vulnerability 3 (tests/ integration) verified via `run-all.{sh,ps1}` registration. Closed alongside the plan.

---

## Bottom Line

**Verdict:** Fix Issues

Direction is right and the motivating bug is real — reproduced below. Three problems block execution as written: one correctness gap the plan's own acceptance criteria cannot detect, one step whose stated justification is consumed by the step before it, and a test strategy that lands outside the repo's existing suite and never runs it.

**Top Vulnerabilities:**
1. **rebase-close rewrites the ephemeral branch before it can discover the base-worktree collision the plan newly permits.** Verified: history rewritten, close fails, worktree stranded — and the acceptance criterion as worded *passes* on that outcome.
2. **Step 2's safety rationale is fully consumed by Step 1.** Once tracked dirt is gated, `reset --hard HEAD` destroys nothing. The remaining case for the change is policy, not data loss — and its new failure branch dead-ends at the very command the policy forbids.
3. **Plan ignores `tests/`.** Repo has a 188-assertion suite with runners, README coverage table, and a CLAUDE.md instruction to run both platforms after touching these scripts. Plan adds two root-level launchers, wires them to nothing, and never runs the existing suite.

---

## Evidence Base

All findings below are reproduced against the actual scripts in throwaway repos, not inferred.

| # | Experiment | Result |
|---|---|---|
| E1 | Conflicted `merge --squash` at base with unrelated uncommitted tracked edit + untracked bystander | Tracked edit **destroyed** (`PRECIOUS-UNCOMMITTED-WORK` → `unrelated-v0`); untracked survived. **Motivating bug confirmed.** |
| E2 | Non-conflicting close, all three types, unrelated tracked dirt at base | All succeed, dirt **survives** in every case. Loss is confined to the conflict-rollback path. |
| E3 | `git reset --merge HEAD` after conflicted `merge --squash` | Exit 0; index/worktree restored to HEAD; conflict markers cleared; untracked preserved. **Plan Assumption 5 holds.** |
| E4 | rebase-close `--worktree`, base advanced, untracked path colliding with incoming tracked path | Rebase **completed and rewrote** ephemeral (`1cd96ec` → `e2016c9`), then `merge --ff-only` refused. Exit 1. Base unmoved, worktree still registered, ephemeral rewritten. |
| E5 | Same collision under squash-close | Git refused before touching anything; script reset and reported cleanly. No rewrite. |
| E6 | `tests/run-all.sh` on current `main` | `PASS=116 FAIL=0` (30 + 52 + 34). With `.ps1` suites → the 188 CLAUDE.md cites. |

---

## Stakeholder Roles

| Role | Cares About | Pain Points | Critical Assumptions |
|------|-------------|-------------|---------------------|
| Closing agent | Close succeeds or fails cleanly; exit code is actionable | Half-finalized states it cannot diagnose from the message | Exit 1 ⇒ nothing changed |
| Repo owner (human) | Uncommitted work survives; close doesn't demand a clean desk | Busy repo blocked by unrelated dirt; silent loss | Only projex-scoped paths are touched |
| Script maintainer | `.sh`/`.ps1` parity; regressions caught by `tests/` | Two divergent test conventions; untested new failure branch | New tests run in CI-equivalent path |
| Orchestrator (stacked plans) | B closes into `projex/A`, never into `main` | Wrong-parent integration | `RepoRoot`+`Base` pairing is enforced |
| Careless caller (adversarial) | — | — | Exploits the gap between "gate passed" and "mutation safe" |

> The careless caller is the adversary this codebase already models — `resume.test.sh` (52 assertions) exists entirely to attack the exit-2 → re-run window. Findings below are framed the same way: not malice, but a hurried agent hitting the seam.

---

## Critical Findings

### Finding 1: rebase-close rewrites history before the permitted-untracked collision is detectable

**Severity:** High | **Likelihood:** Medium

**Affects Roles:** Closing agent, Repo owner, Orchestrator

**Attack Vector:** Base worktree holds an untracked file at a path the ephemeral branch adds as tracked — exactly the state Success Criterion 3 legalizes. Gate passes (untracked allowed). rebase-close then replays commits *inside the child worktree*, rewriting SHAs, and only afterwards attempts `merge --ff-only` at `RepoRoot`, where git refuses.

**Verified outcome (E4):** ephemeral rewritten `1cd96ec` → `e2016c9`; base unmoved; worktree still registered; exit 1; message reads `fast-forward of 'main' failed unexpectedly after rebase` and advises a manual command that fails identically until the untracked file is moved. Nothing explains *why*.

**Why the plan cannot catch this:** Acceptance criterion reads *"collision fails without overwrite or base-ref movement."* E4 satisfies it — no overwrite, base ref did not move. The criterion says nothing about the **ephemeral** ref, which is the one that moved, or about close atomicity. Step 3's matrix item 5 inherits the same blind spot.

**Blast Radius:** Any rebase-close in worktree mode against a base checkout with untracked content — which the plan now explicitly encourages ("busy repos may retain unrelated untracked/ignored files"). Not data loss; it is an unrecoverable-by-message half-close that the agent must diagnose by hand.

**Remediation:**
- In rebase-close worktree mode, pre-check collisions **before** rebasing: intersect `git -C <RepoRoot> diff --name-only <Base>...<Ephemeral>` against untracked paths at `RepoRoot`; non-empty ⇒ exit 1 pre-mutation with the colliding paths named.
- Reword the criterion to constrain **both** refs: *"collision fails with no overwrite, no base-ref movement, **and no ephemeral history rewrite**."*
- Failing that, at minimum replace `failed unexpectedly` with the actual cause and the actual fix.

---

### Finding 2: Step 2's stated rationale is consumed by Step 1

**Severity:** High | **Likelihood:** High (as a reasoning defect; the code change itself is low-risk)

**Affects Roles:** Script maintainer, Reviewer

**Attack Vector:** Trace when `reset --hard HEAD` can actually destroy anything. E1 shows the loss requires **tracked** dirt at base at merge time. Step 1 makes that state unreachable — exit 1 before `merge --squash` runs. `reset --hard` does not remove untracked files (E1, E5: untracked survived every reset). So at the moment Step 2's rollback fires, the tree is guaranteed tracked-clean and the only thing `--hard` can discard is the failed squash itself, which is precisely what should be discarded.

**Consequence:** Step 2 delivers **no incremental data safety**. Its real and legitimate justification is the project rule forbidding automatic `reset --hard` — a policy argument. The plan instead sells it under Success Criterion 5 and the Summary's data-loss framing, which means it will be reviewed against the wrong bar.

**Second-order cost:** Step 2 introduces a failure branch that does not exist today — *"failure → exit 1, report rollback failure and leave state for explicit recovery."* Leaving a conflicted squash in the base worktree means the next invocation trips `in_progress_op` (detected via unmerged entries, no `MERGE_HEAD` for squash) and exits 1; the script's own message then directs the user to `git reset --hard HEAD` "with your explicit approval" (`projex-squash-close.sh:122`). Net effect: a reliable automatic recovery is replaced by one that can dead-end at the forbidden command, now performed by hand.

**In its favour:** E3 confirms `reset --merge HEAD` does the job cleanly — Assumption 5 is sound, and the Medium confidence rating is if anything conservative.

**Remediation:**
- Re-justify Step 2 as policy compliance; drop the data-loss framing from Summary and Criterion 5, or Step 1 will look redundant to a reviewer instead of load-bearing.
- Add a criterion that the rollback-failure branch is **reachable and tested** — an untested error path is worse than no error path.
- Specify what the dead-end message says. If the honest answer is still `reset --hard` under approval, say so in the message rather than leaving the agent to rediscover it.

---

### Finding 3: The plan does not know the `tests/` directory exists

**Severity:** High | **Likelihood:** High

**Affects Roles:** Script maintainer, future maintainer

**Attack Vector:** Repo already carries `tests/` — `run-all.sh`, `run-all.ps1`, three `.sh` suites, two `.ps1` suites, a README coverage table, a `chk` assertion convention, throwaway-repo discipline, and an explicit rule that `.sh`/`.ps1` are tested independently because parity is not assumed. `CLAUDE.md` instructs running **both** after touching `projex-{squash,merge,rebase}-close.*`.

Step 3 creates `test-close-dirty-base.sh` / `.ps1` at repo root, registered nowhere.

**Consequences, all concrete:**
- New regression check never runs in the documented workflow — `tests/run-all.sh` will not invoke it. The one guard against reintroducing E1 is invisible.
- Key Files omits `tests/run-all.sh`, `tests/run-all.ps1`, `tests/README.md` (coverage table is a documented contract), and CLAUDE.md's assertion count. Estimated Changes "9 files" is short by ~4.
- Two parallel conventions for the same concern, guaranteed to drift — the plan's own Risks section worries about `.sh`/`.ps1` drift while creating a larger drift axis.

**Remediation:** Place as `tests/dirty-base.test.sh` / `tests/dirty-base.test.ps1`; register in both runners; add a coverage-table row; update the CLAUDE.md count. Reuse `chk`/`Chk` rather than inventing assertions.

---

### Finding 4: Verification Plan never runs the existing suite

**Severity:** Medium | **Likelihood:** High

**Affects Roles:** Script maintainer

**Attack Vector:** Automated Checks lists only the two new launchers, a `reset --hard` grep, and a cross-shell comparison. Yet Step 1 rewrites the checkout-mode gate expression in all six scripts and Step 2 rewrites squash rollback — both sit directly under existing coverage. `resume.test.sh` (52 assertions) models exactly the careless-caller paths these edits touch; `worktree.test.sh` (34) covers the gate-target behaviour Step 1 modifies.

Baseline established here: `PASS=116 FAIL=0` on `main` (E6). Nothing in the plan requires that to still hold.

**Note on likelihood:** I checked whether Step 1 would break the suite outright. The `mkwt` helper commits its base-side changes (`tests/worktree.test.sh:20-21`), so the base worktree is clean at close time and the new gate should not fire. The exit-2 → resume paths also commit before re-running, and the plan correctly orders the new gate *after* in-progress validation, preserving those messages. So breakage is not predicted — but it is also not checked, and Step 2 changes state that `resume.test.sh` asserts on.

**Remediation:** Add `tests/run-all.sh` and `pwsh tests/run-all.ps1` as gating Automated Checks. Add a criterion: *"existing 188 assertions pass, or any changed assertion is updated with recorded rationale."*

---

### Finding 5: `Base` is assumed to be a branch; the scripts accept any rev

**Severity:** Medium | **Likelihood:** Medium

**Affects Roles:** Closing agent, Orchestrator

**Attack Vector:** Every script validates `Base` with `git rev-parse --verify "$BASE"` — which accepts tags, raw SHAs, and `origin/main`. Step 1 introduces *"resolve `Base` and `RepoRoot`'s symbolic `HEAD` to canonical `refs/heads/*`"* with **no stated behaviour when `Base` does not resolve to a local branch**.

Two failure shapes, neither addressed:
- Silent conversion of currently-accepted input into exit 1 — a breaking change absent from Out of Scope and from the Impact Analysis.
- Or a comparison against an unresolved value, which is worse than no check.

**Blast Radius:** Small in the projex happy path (`Base` is normally a branch name), larger for stacked orchestration where `Base` is passed programmatically, and for anyone who has scripted around today's permissiveness.

**Remediation:** State the behaviour explicitly. Preferred: non-branch `Base` ⇒ exit 1 pre-mutation, named as an intentional breaking change in Impact Analysis, with a regression case. Acceptable: skip the identity assertion and fall back to current behaviour, documented as a known hole.

---

### Finding 6: Tracked-only gate catches dirty submodules and index-flag noise

**Severity:** Medium | **Likelihood:** Medium

**Affects Roles:** Repo owner (busy repo)

**Attack Vector:** `git status --porcelain --untracked-files=no` reports a dirty submodule as ` M <path>` even when the superproject's recorded commit is unchanged. In worktree mode the base worktree has **no gate today**, so a repo with a permanently-dirty submodule moves from "always closes" to "never closes" — the exact busy-repo hostility that motivated the untracked carve-out, reintroduced through a different door. `assume-unchanged` / `skip-worktree` entries are similarly unconsidered.

**Remediation:** `--ignore-submodules=dirty` on the gate expression, and an explicit decision (either way) on index-flagged paths, recorded in Assumptions.

---

### Finding 7: The gate is a pre-flight check, not enforcement

**Severity:** Low-Medium | **Likelihood:** Low per-run, High cumulatively

**Affects Roles:** Repo owner, Closing agent

**Attack Vector:** Gate runs, then merge/ff runs. The base worktree stays writable throughout — IDE autosave, a watcher, or a parallel agent can dirty it inside that window. Nothing re-checks.

The real backstop is git's own overwrite refusal, which E2 shows already protects the non-conflicting cases across all three close types. That reframes the whole plan: the gate is a **usability guardrail that converts a confusing late failure into a clear early one**, not a safety guarantee.

**Remediation:** Say that in `close-projex.md`. Step 4 currently plans to state that *"finalizers independently enforce the integration-worktree gate"* — "enforce" overclaims. A caller that reads it as a guarantee will stop committing before close.

---

### Finding 8: Doc relaxation compounds Finding 1

**Severity:** Low | **Likelihood:** Medium

**Affects Roles:** Closing agent

**Attack Vector:** `close-projex.md:418` currently instructs `git status --porcelain` with *"if output is non-empty, commit or discard."* That blanket instruction incidentally prevents the E4 state. Step 4 relaxes it to permit untracked content. If Finding 1 is not fixed first, the relaxation actively steers agents into the rebase-rewrite-then-fail path.

**Remediation:** Sequence Step 4 after Finding 1's fix, or carve rebase-close out of the relaxation until then.

---

## Role-Based Assumption Challenges

### Repo owner: "Untracked content is safe to allow through"

**Challenge:** True for squash and merge (E5 — git refuses pre-mutation, script rolls back cleanly). False for rebase, where the mutation that matters happens before the check point (E4).
**If Wrong:** Success Criterion 3 is satisfied while one of three close types is left half-done.
**Action:** Relax — qualify the criterion per close type, or fix rebase ordering.

### Script maintainer: "Untracked must be allowed because busy repos"

**Challenge:** Stronger than the plan claims, and worth recording. `.projexwt/` itself surfaces as untracked at base whenever the `.git/info/exclude` registration is absent (observed in E4/E5 setup). A full-`--porcelain` gate would self-block the framework's own worktree mechanism, not merely inconvenience busy repos.
**Action:** Validate — promote this to the Rationale; it is the load-bearing argument, not the busy-repo convenience.

### Reviewer: "All three close types accept nonconflicting tracked base edits and report success" (Objective, bullet 4)

**Challenge:** Accurate, but E2 shows the edits **survive intact** in that scenario. Read alongside a Summary framed on data loss, this bullet implies harm it does not cause. Actual demonstrated loss is one path: squash + conflict + `reset --hard` (E1).
**If Wrong:** Reviewers approve a six-file change believing the blast radius is wider than it is; genuine narrowing opportunities go unexamined.
**Action:** Validate — state plainly that the gate is defense-in-depth for two of three types and a real fix for one.

### Orchestrator: "`RepoRoot` still has `Base` checked out"

**Challenge:** Not currently enforced anywhere — today squash/merge worktree mode merges into whatever `RepoRoot` happens to have checked out. This is a **genuine hole the plan closes**, and the nested utility-worktree case in Current State is the realistic trigger (stacked plans per `orchestrate-projex.md`).
**Action:** Validate — keep as-is; this is the strongest part of Step 1.

---

## Role-Specific Edge Cases & Failures

### Closing agent: exit 1 no longer means "nothing changed"

**Trigger:** Finding 1 (rebase rewritten, then ff refused) or Finding 2's new rollback-failure branch.
**Role Experience:** Exit 1 with a message implying clean rollback; actual state is rewritten history or a conflicted index.
**Recovery:** Difficult — requires reading git state directly.
**Mitigation:** Distinguish the codes, or make every exit-1 message state what *did* change.

### Repo owner: submodule-dirty repo becomes permanently unclosable

**Trigger:** Finding 6.
**Recovery:** Possible but non-obvious — nothing tells them the submodule is the blocker beyond a bare ` M <path>` line.
**Mitigation:** `--ignore-submodules=dirty`; annotate the first-10-entries output.

### Script maintainer: silent test bit-rot

**Trigger:** Finding 3 — root-level launchers never invoked by `run-all.*`.
**Role Experience:** Suite reports green; the dirty-base matrix has not executed in months.
**Recovery:** Possible, once someone notices.
**Mitigation:** Register in the runners; the coverage table is the tripwire.

---

## What's Hidden

**Omissions:**
- **Reviewer:** that E2's outcome (dirt survives non-conflicting closes) narrows the real bug to one path. Summary reads as though all three types lose work.
- **Maintainer:** that `tests/` exists at all. A reader of this plan alone would conclude the repo has no test suite.
- **Agent:** that `Base` is currently permissive about ref type (Finding 5).
- **Everyone:** that the gate cannot bind across the mutation window (Finding 7).

**Tradeoffs:**
- **Repo owner:** gains dirt-safety, loses the ability to close from a submodule-dirty or index-flagged tree.
- **Agent:** gains earlier failure, loses "exit 1 ⇒ nothing changed" as an invariant.
- **Maintainer:** gains a dirty-base matrix, inherits a second test convention and an untested error branch.

---

## Scale & Stress

**At 10x (nested/stacked closes, several `projex/*` in flight):**
- Orchestrator: the `RepoRoot`→`Base` assertion becomes the main defence against integrating into the wrong parent — good.
- Agent: Finding 1's stranded worktrees accumulate; `worktree prune` is never reached on the exit-1 path.

**At 100x (long-lived busy monorepo):**
- Repo owner: Findings 6 and 7 dominate. A tree that is never simultaneously clean and stable for the duration of a close makes worktree mode effectively unusable — the opposite of worktree mode's stated benefit ("no clean-state requirement at execution start"). The plan reintroduces a clean-state requirement at close time; that trade is defensible but should be named.

---

## Remediation

### Must Fix (Before Proceeding)

- **Finding 1** (affects: agent, owner, orchestrator) → pre-check untracked collisions at `RepoRoot` before rebasing, or reorder rebase-close → verify ephemeral SHA is unchanged on the collision path
- **Finding 3** (maintainer) → move new tests into `tests/`, register in `run-all.{sh,ps1}`, update README table + CLAUDE.md count, correct the file estimate
- **Finding 4** (maintainer) → add both existing runners to Automated Checks with a "188 still pass" criterion
- **Finding 5** (agent, orchestrator) → define non-branch `Base` behaviour explicitly

### Should Fix (Before Production)

- **Finding 2** (maintainer, reviewer) → re-justify Step 2 on policy grounds; require the rollback-failure branch to be reachable and tested
- **Finding 6** (owner) → `--ignore-submodules=dirty`; decide on index-flagged paths
- **Finding 8** (agent) → sequence Step 4 after Finding 1, or carve out rebase

### Monitor

- **Finding 7** (owner, agent) → soften "enforce" to "pre-flight check" in `close-projex.md`; revisit if a TOCTOU incident is ever observed
- `projex-abandon` is correctly out of scope (it never merges into the base worktree), but it shares the "`RepoRoot` identity unverified" property — revisit if worktree-mode abandon ever grows a base-side mutation

---

## Final Assessment

**Soundness:** Fixable
**Risk:** Medium
**Readiness:** Needs Work

**Per-Role Readiness:**
- **Repo owner:** Not Ready — Finding 6 can make close impossible in exactly the repos this plan targets
- **Closing agent:** Not Ready — Finding 1 produces a half-closed state the plan's criteria certify as correct
- **Script maintainer:** Not Ready — Findings 3, 4 leave the change unverified against existing coverage
- **Orchestrator:** Ready with Fixes — the `RepoRoot`→`Base` assertion is the plan's strongest contribution; Finding 5 is the only gap

**Conditions for Approval:**
- [ ] Rebase-close cannot rewrite ephemeral history before the base-worktree collision check (agent, owner, orchestrator)
- [ ] Acceptance criterion constrains ephemeral-ref stability, not only base-ref movement (reviewer)
- [ ] New tests live in `tests/`, run from both runners, coverage table + CLAUDE.md count updated (maintainer)
- [ ] `tests/run-all.sh` and `pwsh tests/run-all.ps1` are gating Automated Checks (maintainer)
- [ ] Non-branch `Base` behaviour stated (agent, orchestrator)
- [ ] Step 2 re-justified as policy; rollback-failure branch reachable and tested (maintainer)

**No-Go If:**
- [ ] Finding 1 is deferred **and** Step 4's doc relaxation ships — the two together actively steer agents into the broken path (agent, owner)
- [ ] The plan ships without ever running the existing suite (maintainer)
