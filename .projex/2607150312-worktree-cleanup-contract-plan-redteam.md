# Red Team: Worktree Cleanup Contract + Close-Script Removal Diagnosis plan

> **Created:** 2026-07-15 | **Lead:** agent (Claude, opus)
> **Subject:** 2607150236-worktree-cleanup-contract-plan.md — spec cleanup contract + close-script removal diagnosis (no blind `--force`)
> **Related:** 2607132112-projex-rebase-close-scripts-redteam.md (Finding 2, plan input) | 2606270200-squash-close-worktree-remove-windows-memo.md (incident) | 2607140251-close-scripts-per-branch-lock-plan.md (anchor-conflict sibling)

---

## Bottom Line

**Verdict:** Fix Issues

Plan is architecturally sound and unusually well-anchored — every cited line number and before/after block verified against the repo, and the three load-bearing premises were empirically confirmed (see Tested Evidence). It does not, however, fully deliver its own success criteria. Two success-criteria-level gaps and a shipped-but-untested branch warrant a revise pass before execution.

**Top Vulnerabilities:**
1. **Squash/merge worktree closes have no tracked-dirty guard** — the new gate blocks only `??` untracked; a modified *tracked* file passes it, the squash merges from the stale last commit (silently dropping the edit), then removal refuses. rebase guards this; squash/merge don't, and the plan adds nothing. Undermines the "worktree returned with only tracked content" contract.
2. **The "still-registered" removal-diagnosis branch ships untested** — no verification-matrix row reaches it (row 3's removal *succeeds*; rows 2/5 exit pre-merge; row 4 hits the unregistered branch). The most complex new code — blocking-content listing — is claimed by a success criterion but never exercised.
3. **Prevention of the actual incident (ignored `node_modules`) rests on agent adoption, not a gate** — the untracked gate never blocks ignored content, git removes ignored content fine except on Windows FS-choke, so structural prevention = a spec sentence + a hint line. debug-projex (the most dep-install-prone consumer) is explicitly deferred from restating the contract.

> **Correction (2026-07-15, user):** this report's "Windows FS-choke" attribution is wrong — the triggering incident ran in a **Linux docker sandbox** (`/workspace`, symlinked `node_modules`); only the earlier memo 2606270200 was Windows. Half-removal failure is environment-dependent, not OS-specific, which *strengthens* Finding 3's core point (ignored-leftover risk is not a Windows corner case). Read later mentions of "Windows FS-lock/FS-choke" in this report as "environment-dependent removal failure". Plan corrected — see its Revision Log.

---

## Stakeholder Roles

| Role | Cares About | Pain Points | Critical Assumptions |
|------|-------------|-------------|---------------------|
| Executing agent (close) | Close completes; no data loss | Gate false-positives block a clean close; cryptic diagnosis | Reads SKILL.md § Worktree Mode at close time |
| Executing agent (debug/simulate) | Deps present to verify, then clean close | Installs `node_modules`; contract not restated in its own spec | SKILL.md contract in-context |
| Abandoning agent | Throwaway branch gone, fast | Abandon path aborts on messy scratch | `--force` still removes worktree |
| Script maintainer | `.sh`/`.ps1` parity; robustness | sh `set -euo pipefail` vs ps1 no-pipefail divergence | Injected pipes behave identically |
| External-repo user | Worktree mode keeps working | New pre-flight exit-1 breaks previously "succeeding" dirty closes | Breaking change is acceptable/intended |
| Plan author / reviewer | Risk analysis is trustworthy | Inverted false-negative reasoning misleads | Stated worst-case matches code branch |

---

## Attack Surface (Per Role)

**Close agent:** Claim — "close scripts refuse to proceed over untracked files, never `--force`." Assumption — worktree holds only tracked, committed content at finalize. Dependency — `git status --porcelain`, `worktree list --porcelain` output shape.

**Abandon agent:** Claim — untracked files named before destruction, then removed. Dependency — removal + branch-delete run *after* the untracked-note echo.

**Maintainer:** Claim — `.sh` ↔ `.ps1` behavioral parity (repo invariant). Dependency — identical control flow under different shell error semantics.

---

## Tested Evidence (scratch repos, Windows Git Bash 2.x)

| Claim under test | Result | Bearing |
|---|---|---|
| `git worktree list --porcelain` path separator | **forward slashes** (`C:/…/.projexwt/x`) | Plan Assumption 3 holds; registration regex `"/\.projexwt/${suf}$"` matches in sh and ps1 (git prints `/` regardless of shell) |
| non-force `worktree remove` over ignored-only (`node_modules/`) | **succeeds** (`REMOVE_OK`) | Plan premise "ignored content doesn't block non-force remove" confirmed; ignored deps are not a git-level blocker |
| non-force remove over modified *tracked* file | **refused** (`fatal: contains modified or untracked files`), worktree stays **registered** (count=1) | "still-registered" diagnosis branch is reachable *only* via modified-tracked / FS-lock — a state the matrix never sets up |
| `producer \| head -n N` under `set -euo pipefail`, output > pipe buffer | script **aborts, exit 141**, code after the pipe never runs | Step 3(b) `git status … \| head -n 10` is unguarded; ps1 (no pipefail) does not abort → parity divergence under the trigger |
| `echo "$VAR" \| head -n N` (builtin) under same | **safe**, continues, exit 0 | Pre-flight (a) and abandon (Step 4) echo-pipes are NOT at risk; only the external `git … \| head` is |

---

## Critical Findings

### Finding 1: Squash/merge worktree mode has no tracked-dirty guard; untracked-only gate lets modified tracked files through
**Severity:** Medium | **Likelihood:** Medium
**Affects Roles:** Close agent, reviewer

**Attack Vector:** Worktree has an uncommitted modification to a *tracked* file at close (e.g., agent edited a file, forgot to commit). Step 3(a) gate greps `^??` only → no match → passes. `merge --squash` (squash sh:70) merges from the last **commit**, silently omitting the edit. Removal (squash sh:94) then refuses (`fatal: contains modified…`, tested) → falls into the still-registered diagnosis.

**Result:** Base receives an incomplete squash; the real edit survives only in the lingering worktree. No data *loss*, but a silent correctness gap: the merged result differs from the worktree the agent was looking at. rebase-close guards this (rebase sh:64-67 tracked clean-check); squash/merge worktree branches (squash/merge sh:53-55) do only `WT_PATH=…`, no diff check — and the plan adds none.

**Blast Radius:** Any squash/merge worktree close with uncommitted tracked edits. Directly contradicts Success Criterion "Worktree returned with only tracked content" and the SKILL.md contract's intent.

**Remediation:** Add a tracked-dirty check to the squash/merge pre-flight gate (mirror rebase sh:64-67: `diff --quiet` + `diff --cached --quiet` on `$WT_PATH`), or extend the gate to fail on any non-clean status, not just `^??`.

---

### Finding 2: The "still-registered" removal-diagnosis branch is untested by the verification matrix
**Severity:** Medium | **Likelihood:** High (that it ships unverified)
**Affects Roles:** Maintainer, close agent

**Attack Vector:** Step 3(b)'s `then` branch (registered → list blocking content → retry instruction) is the most complex new code and backs the success criterion "Removal failure with still-registered worktree: prints blocking content + resolve instructions." Matrix coverage: row 1 clean; rows 2/5 exit pre-merge; row 3 (ignored) removal **succeeds** (tested — never fails); row 4 simulates `rm -rf .git/worktrees/<name>` → admin gone → **else/unregistered** branch. No row produces *removal-fails-while-registered*. Reaching it requires a modified tracked file or an FS lock (tested: modified tracked → refused + registered).

**Result:** A whole branch — including the SIGPIPE-prone pipe (Finding 4) and the "Blocking content" message — ships with zero behavioral evidence, while the matrix reports green.

**Remediation:** Add a matrix row: worktree with a modified tracked file → squash-close --worktree → expect close succeeds, "could not remove … Blocking content:" lists the file, exit reflects a clean end (not 141), branch deleted, prune run.

---

### Finding 3: Incident prevention relies on adoption, not a gate; contract wording overclaims
**Severity:** Medium | **Likelihood:** Medium
**Affects Roles:** debug/simulate agent, close agent

**Attack Vector:** The triggering incident was ignored `node_modules`. The untracked gate never blocks ignored content (only `^!!` warns), and git removes ignored content cleanly (tested `REMOVE_OK`) — the failure is Windows FS-choke, not a git refusal. So the *only* structural prevention is the cleanup contract as prose: SKILL.md bullet + execute-projex step 5 + the projex-worktree hint line. debug-projex.md / simulate-projex.md are explicitly out of scope ("SKILL.md contract covers all") — yet debug, the workflow most likely to `npm install`, loads debug-projex.md and need not re-read SKILL.md § Worktree Mode at close.

Compounding: the SKILL.md contract text (Step 1) reads "Untracked/ignored leftovers block worktree removal … close scripts refuse to proceed over untracked files." The first clause implies ignored is gated; the scripts only gate untracked and only warn on ignored. A skimming agent infers false protection.

**Remediation:** (a) Reword the SKILL.md bullet so "refuse" attaches only to untracked and ignored is described as "warn + may leave a directory to clean." (b) Reconsider a one-line cleanup pointer in debug-projex.md's close section — the deferral removes the contract from the exact workflow that most needs it.

---

### Finding 4: Injected `git … | head` diagnosis pipe is unguarded under `set -euo pipefail` (sh only) — robustness + parity break
**Severity:** Low-Medium | **Likelihood:** Low (needs > ~64 KB git output)
**Affects Roles:** Maintainer, close/abandon agent

**Attack Vector:** Step 3(b): `git -C "$WT_PATH" status --porcelain --ignored=matching 2>/dev/null | head -n 10 >&2` as a bare statement. `head` closes after 10 lines; if git's total output exceeds the OS pipe buffer, git's next write takes SIGPIPE (141), `pipefail` propagates it, `set -e` aborts (tested with `seq`). The abort skips the trailing `worktree prune` and `branch -D/-d` → a **successful** close exits 141 with the ephemeral branch undeleted. ps1 has no `pipefail`, so it never aborts → the two families diverge exactly when triggered, violating the parity invariant. (`--ignored=matching` collapses dirs, so 64 KB needs many distinct ignored entries — hence Low likelihood, but latent.) The pre-flight (a) and abandon (Step 4) `echo "$VAR" | head` pipes are **safe** (builtin single write — tested).

**Remediation:** Guard the external pipe: `{ git -C "$WT_PATH" status --porcelain --ignored=matching 2>/dev/null || true; } | head -n 10 >&2` — or capture then print — so a truncated read can't abort the tail of the script.

---

### Finding 5: Plan's own risk note inverts which branch a registration false-negative hits
**Severity:** Low | **Likelihood:** Low (forward-slash output confirmed)
**Affects Roles:** Reviewer

**Attack Vector:** Notes § Risks: "Registration-check false negative (suffix regex misses) … worst case falls into the 'still registered' branch → prints blocking content, no destructive action." Backwards: a grep *miss* means `grep -q` returns 1 → the `if … then` (registered) is skipped → the **else/unregistered** branch runs, advising the agent to "inspect and delete the plain directory manually" for a worktree git still tracks. Manual `rm -rf` then leaves a stale admin entry (needs `prune`). Not data loss, but the plan's stated safety fallback describes the opposite branch from the one that executes. Testing confirms the trigger is improbable (git prints `/`), which is why severity is Low — but the reasoning defect should not stand in a document used to justify removing `--force`.

**Remediation:** Correct the risk note to: false negative → unregistered/else branch → benign but slightly misleading "delete manually" advice; add `git worktree prune` to that message so a stale entry self-heals.

---

## Role-Based Assumption Challenges

### Maintainer: "`.sh` and `.ps1` are behaviorally identical"
**Challenge:** Only under non-triggering inputs. `set -euo pipefail` vs ps1's per-command `$LASTEXITCODE` give different failure semantics for the injected `git | head`.
**Counter-Evidence:** Tested SIGPIPE abort (sh) vs safe continuation model (ps1, no pipefail).
**If Wrong:** Divergent close outcomes on large-output worktrees; parity "verified" by diff-review (a static check) would miss it.
**Action:** Validate — add a runtime parity row, not just diff review.

### Close agent: "At finalize the worktree holds only tracked, committed content"
**Challenge:** Nothing enforces *committed*; the script gate enforces only *not-untracked*. Modified-tracked slips (Finding 1).
**Action:** Reject as stated for squash/merge until the tracked-dirty guard is added.

### Author: "Removing `--force` costs nothing given the gate"
**Challenge:** True — confirmed. `--force` only ever bypassed untracked/modified refusal; the gate blocks untracked, and modified-tracked *should* block. The one honest cost: a worktree with modified tracked files can no longer be force-removed by the script, so it lingers (correct, safer). Solid.
**Action:** Validate — this is the plan's strongest, and it holds.

---

## Role-Specific Edge Cases & Failures

### Abandon agent: worktree with > ~64 KB of untracked scratch listing
**Trigger:** Step 4's untracked note uses `echo "$UNTRACKED" | head` — **safe** (builtin, tested). No abort here. Recorded to preempt a false alarm: abandon's echo-pipe is fine; only external-command pipes (Finding 4) abort.
**Recovery:** N/A — not a defect.

### Close agent: removal fails on pure Windows FS-lock, status clean
**Trigger:** Editor holds a handle in `.projexwt/`; `worktree remove` fails though `git status` shows nothing untracked/ignored. Diagnosis prints "Blocking content:" followed by an **empty** list, then "Remove the files above" — there are none.
**Role Experience:** Misleading dead-end for the very Windows-lock mechanism the incident was about.
**Recovery:** Difficult without out-of-band knowledge.
**Mitigation:** When the status output is empty, print an alternative hint ("removal failed with no blocking git content — likely a file lock or long path; close an editor on the worktree and retry").

---

## What's Hidden (Per Role)

**Omissions:**
- **Close agent:** that "blocking content" may list ignored entries git would happily remove (tested) — the label overstates what actually blocks removal.
- **debug agent:** that the cleanup contract exists at all, unless it independently re-reads SKILL.md § Worktree Mode at close.
- **Reviewer:** that squash/merge worktree branches never had (and still won't have) a tracked-dirty guard — the plan's "identical treatment across the three merge-type pairs" framing hides that their *pre-existing* guards differ.

**Tradeoffs:**
- **External-repo user:** dirty-worktree closes that previously "succeeded" now exit 1 — acknowledged and intended.

---

## Scale & Stress (Role Impact)

**At 10x (many ignored entries / large monorepo worktree):**
- **Close agent:** Finding 4's SIGPIPE trigger becomes reachable (status output crosses the pipe buffer) → close exits 141, branch undeleted.

**At 100x (parallel worktree closes, sibling-plan co-execution):**
- **Maintainer:** anchor drift vs 2607140251 (both line-pin the same removal region) — acknowledged; residual risk that `/revise` fixes line numbers but the two inserted blocks still collide structurally in one removal block.

---

## Remediation

### Must Fix (Before Execution)
- **Tracked-dirty guard for squash/merge worktree gate** (Finding 1) → mirror rebase sh:64-67 → verify with a modified-tracked matrix row.
- **Matrix row for still-registered diagnosis** (Finding 2) → modified-tracked → removal-refused → assert message + clean exit + branch deleted.

### Should Fix (Before Execution)
- **Reword SKILL.md contract** so "refuse" scopes to untracked; ignored = warn (Finding 3).
- **Guard the `git … | head` diagnosis pipe** against SIGPIPE abort; confirm ps1 parity (Finding 4).
- **Correct the inverted false-negative risk note** + add `prune` to the unregistered message (Finding 5).

### Monitor
- **debug-projex adoption** of the cleanup contract (Finding 3) — revisit if a post-execution incident recurs from installed deps.
- **Empty "Blocking content" on FS-lock** (edge case) — add the alternative hint if Windows-lock reports come back confusing.

---

## Final Assessment

**Soundness:** Fixable
**Risk:** Medium
**Readiness:** Needs Work

**Per-Role Readiness:**
- **Close agent:** Not Ready — Finding 1 lets a squash silently omit uncommitted tracked edits.
- **Maintainer:** Needs Work — untested diagnosis branch + potential sh/ps1 SIGPIPE divergence.
- **Abandon agent:** Ready — its echo-pipe is safe; `--force` retained correctly.
- **External-repo user:** Ready with Fixes — breaking change is intended and documented.

**Conditions for Approval:**
- [ ] Squash/merge worktree gate rejects modified tracked files (Finding 1)
- [ ] Matrix exercises removal-fails-while-registered (Finding 2)
- [ ] SKILL.md contract wording no longer implies ignored content is gated (Finding 3)

**No-Go If:**
- [ ] Executed with the untracked-only gate unchanged while claiming Success Criterion "worktree returned with only tracked content"

---

## Solid (credit where due)

- Every cited anchor verified accurate: SKILL.md:273, close-projex.md:423, execute-projex.md:97/214, squash removal sh:93-100/ps1:93-102, merge sh:82-89, rebase sh:110-117, abandon sh:52-57, WT_PATH at squash/merge sh:55, rebase sh:58.
- All three load-bearing premises empirically confirmed (forward-slash output, ignored-remove-non-blocking, `--force`-removal-safe-given-gate).
- Removing blind `--force` from merge-type closes is correct and the two-branch registered/unregistered split is the right shape.
- close-projex commits walkthrough/plan/log *before* the finalize gate (ln 400-406), so the new untracked gate won't misfire on close's own artifacts — a false-positive risk that turns out not to bite.
- Rollback plan, sibling-plan conflict, and the intended-breaking-change are all called out.

## Open Questions
- Should the pre-flight gate fail on *any* non-clean worktree status (untracked + modified + staged), unifying squash/merge/rebase behavior, rather than untracked-only? That single change closes Finding 1 and simplifies the three scripts to one guard.
