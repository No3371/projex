# Close Scripts: Dirty Base Safety

> **Status:** Complete
> **Created:** 2026-07-26
> **Author:** Codex
> **Source:** 2607260233-worktree-squash-close-dirty-base-reset-memo.md
> **Related Projex:** 2607132112-projex-rebase-close-scripts-redteam.md | 2607261157-close-scripts-dirty-base-safety-redteam.md | 2607261520-close-scripts-dirty-base-safety-audit.md | 2607261821-rollback-refusal-message-split-patch.md
> **Worktree:** Yes
> **Completed:** 2026-07-26
> **Walkthrough:** 2607261121-close-scripts-dirty-base-safety-walkthrough.md

---

## Summary

Make every branch-finalization script reject tracked changes in the checkout it will mutate, including the originating/base worktree passed as `RepoRoot` in worktree mode. `RepoRoot` may itself be any registered worktree; `Base` may be `main`, a utility branch, feature branch, or parent `projex/*` branch. Allow unrelated untracked/ignored content, add a rebase-close pre-check so permitted untracked content cannot strand a half-close, replace squash-close's automatic `reset --hard` for policy compliance, preserve shell/PowerShell parity, and extend the existing `tests/` suite with a dirty-base regression matrix.

**Demonstrated harm is narrower than the gate's reach.** Reproduced loss is confined to one path: squash + conflict + `reset --hard` rollback. Non-conflicting closes of all three types already preserve unrelated tracked edits intact — for merge and rebase this gate is defense-in-depth that converts a confusing late failure into a clear early one, not a fix for active loss.

**Scope:** Squash, merge, and rebase close scripts; close workflow contract; dirty-base regression matrix inside the existing `tests/` suite.
**Estimated Changes:** 13 files — 6 close scripts, 1 workflow spec, 2 test suites, 2 test runners, `tests/README.md`, `CLAUDE.md`.

---

## Objective

### Problem / Gap / Need

Worktree mode validates only the child execution worktree. All close scripts then mutate the originating/base worktree without verifying its tracked state or confirming it still has `Base` checked out. Observed effects:

- `squash-close`: conflict cleanup runs `reset --hard HEAD`, deleting unrelated tracked edits. **Reproduced** — an uncommitted tracked edit at the base worktree reverts to its committed content when a conflicting squash rolls back. A staged edit is also deleted when `merge --squash` refuses to start but cleanup still resets.
- `merge-close`: `merge --abort` preserved a simple unrelated edit in reproduction, but Git does not guarantee reconstruction when a merge begins with uncommitted changes.
- `rebase-close`: rebase occurs safely in the execution worktree, then the script fast-forwards and deletes the branch while the base checkout remains dirty.
- `rebase-close`, second and separate defect: the rebase **rewrites the ephemeral branch's commits before** the base worktree is consulted at all. When a permitted untracked path at `RepoRoot` collides with an incoming tracked path, `merge --ff-only` refuses *after* the rewrite. **Reproduced** — ephemeral tip rewritten, base ref unmoved, worktree still registered, exit `1`, message reads `fast-forward ... failed unexpectedly` and names no cause. Squash and merge refuse pre-mutation and roll back cleanly; only rebase has this ordering.
- All three close types accept nonconflicting tracked base edits and report success — and in that case the edits **survive intact** (reproduced for all three). The exposure is the conflict/rollback path, not the success path. Untracked content is a different class: it is not part of the index, survives safe rollback, and Git refuses integration when a tracked path would overwrite it.
- `Base` is validated only with `git rev-parse --verify`, which accepts tags, raw SHAs, and remote-tracking refs. No script requires it to be a local branch today.

`close-projex.md` already requires `git status --porcelain` before finalization, but safety exists only at the caller layer. Direct script use or a missed workflow gate can still lose work.

### Success Criteria

- [x] Worktree-mode finalizers verify that recorded `RepoRoot` still has recorded `Base` checked out before mutation; arbitrary utility/feature/parent-Projex bases remain supported.
- [x] `Base` that does not resolve to a local branch (`refs/heads/*`) exits `1` before mutation with a message naming the resolved ref type — a deliberate narrowing of today's `rev-parse --verify` permissiveness.
- [x] All six close implementations exit `1` before mutation when the checkout they will mutate has staged or unstaged tracked changes, excluding dirty-submodule noise.
- [x] Unrelated untracked/ignored content does not block close and remains byte-for-byte intact; a colliding untracked path fails **before any mutation** — no overwrite, no base-ref movement, **and no ephemeral history rewrite**.
- [x] `rebase-close` in worktree mode detects an untracked collision at `RepoRoot` before rebasing, and exits `1` with the colliding paths named.
- [x] Worktree mode still separately rejects a dirty execution worktree.
- [x] Squash failure cleanup contains no automatic `git reset --hard`, satisfying the project rule against unapproved hard resets, and restores a clean pre-merge checkout with `git reset --merge HEAD`.
- [~] The `reset --merge` rollback-failure branch is reachable and exercised by a regression case — an untested error path is worse than no error path. **Resolved via this criterion's own escape clause** (Step 2 Verification: "If no such state can be constructed, record that finding and the branch's unreachability"). Five constructions probed against live git; none reachable through the scripts' entry points. Finding recorded in the execution log, `tests/README.md`, and inline in both new suites; the reachable neighbours are covered instead.
- [x] Clean success, anticipated-conflict exit `2`, rollback exit `1`, branch deletion, and best-effort worktree removal retain existing behavior.
- [x] Dirty-base cases live in `tests/` alongside the existing suites, run from both `tests/run-all.sh` and `tests/run-all.ps1`, and assert content, refs, status, and exit codes.
- [x] The existing suite still passes on both platforms (baseline: `PASS=116 FAIL=0` for `.sh`, 188 assertions across both), or any changed assertion is updated with recorded rationale.
- [x] Workflow docs distinguish the tracked-clean integration-worktree gate from the fully clean execution-worktree gate, describe both as pre-flight checks rather than enforcement, and state that scripts apply them independently.

### Out of Scope

- Automatic stash creation/restoration.
- Changing merge, squash, rebase, conflict allow-list, or cleanup semantics beyond dirty-base safety.
- `projex-abandon`: worktree mode does not merge/reset the originating/base worktree.
- Refactoring duplicated shell/PowerShell logic into shared helpers.
- Updating the source memo in its separate repository.

---

## Context

### Current State

`projex-squash-close.{sh,ps1}` and `projex-merge-close.{sh,ps1}` skip origin-worktree tracked-state validation in worktree mode, validate only `.projexwt/<branch-suffix>`, then merge at `RepoRoot`. `projex-rebase-close.{sh,ps1}` validates and rebases the child execution worktree, but later fast-forwards at `RepoRoot` without checking tracked changes there.

Checkout mode checks `git diff --quiet` plus `git diff --cached --quiet`; these correctly cover tracked staged/unstaged changes but are absent from worktree mode. Worktree-mode validation correctly uses `git status --porcelain` for the execution worktree, where untracked content must block because that worktree will be removed.

Dirty state belongs to a worktree filesystem + index, not a branch ref. In worktree mode, `RepoRoot` is the recorded origin worktree path where squash/merge/fast-forward runs; it is not necessarily Git's primary worktree. `Base` is the recorded parent branch and may itself be a utility, feature, or outer Projex branch. Current scripts document but do not enforce that `RepoRoot` still has `Base` checked out.

Nested example: utility worktree on `projex/outer` → child worktree on `projex/inner` → close `inner` into `outer` at the utility worktree; later close `outer` into its own parent. Finalizers must preserve this ancestry and never substitute `main`/`master` or another worktree discovered from shared repository metadata.

Squash merge does not create `MERGE_HEAD`; `git merge --abort` is unavailable. Current squash rollback therefore uses `git reset --hard HEAD` on every merge failure, including failures before a merge state exists.

`rebase-close` mutates in a different order from its siblings. Squash and merge run their integration command *at* `RepoRoot`, so Git's own overwrite refusal fires before anything changes. Rebase replays commits inside the child worktree first — rewriting ephemeral SHAs — and only then runs `merge --ff-only` at `RepoRoot`. Any `RepoRoot` condition that blocks the fast-forward is therefore discovered after the rewrite is already durable.

The repo already carries a behavioural suite at `tests/`: `run-all.sh`, `run-all.ps1`, three `.sh` suites and two `.ps1` suites, a `chk`/`Chk` assertion helper, throwaway-repo discipline, and a README coverage table. `CLAUDE.md` requires running both platforms after touching `projex-{squash,merge,rebase}-close.*`, on the stated grounds that `.sh` and `.ps1` duplicate logic so passing one proves nothing about the other. Current baseline: `PASS=116 FAIL=0` for the `.sh` runner; 188 assertions across both platforms.

### Key Files

| File | Role | Change Summary |
|------|------|----------------|
| `projex-squash-close.sh` | POSIX squash finalizer | Unified checkout gate; safe squash rollback |
| `projex-squash-close.ps1` | PowerShell squash finalizer | Parity change |
| `projex-merge-close.sh` | POSIX merge finalizer | Unified checkout gate |
| `projex-merge-close.ps1` | PowerShell merge finalizer | Parity change |
| `projex-rebase-close.sh` | POSIX rebase finalizer | Verify origin/base pairing; gate tracked changes; pre-rebase collision check |
| `projex-rebase-close.ps1` | PowerShell rebase finalizer | Parity change |
| `close-projex.md` | Finalization workflow | Clarify the dual pre-flight gate; drop "enforce" phrasing |
| `tests/dirty-base.test.sh` | POSIX regression suite | Disposable-repo safety matrix, `chk` convention |
| `tests/dirty-base.test.ps1` | PowerShell regression suite | Same matrix for PowerShell implementations |
| `tests/run-all.sh` | POSIX runner | Register the new suite |
| `tests/run-all.ps1` | PowerShell runner | Register the new suite |
| `tests/README.md` | Suite contract | Coverage-table row for the new suite |
| `CLAUDE.md` | Repo instructions | Update the assertion count |

### Dependencies

- **Requires:** Git with worktree support; existing close scripts and `--worktree` contract.
- **Blocks:** Safe direct close-script use; consumption/closure of the source memo.

### Constraints

- No destructive reset without explicit current-session human approval.
- No automatic stash: close scripts must not own unrelated user changes.
- Git operation types remain sequential; failure stops later mutation.
- Shell and PowerShell behavior/messages remain equivalent.
- Tests use Git + platform shell only; no framework or dependency.

### Assumptions

- `git status --porcelain --untracked-files=no --ignore-submodules=dirty` output means tracked staged/unstaged content exists and finalization must stop. Submodule dirt is excluded deliberately: a superproject whose recorded submodule commit is unchanged is not dirty for integration purposes, and gating on it would make close impossible in exactly the busy repos this plan targets.
- Paths flagged `assume-unchanged` / `skip-worktree` are **not** special-cased. Git omits them from status by design; the gate inherits that and does not attempt to second-guess it. Recorded as a known hole, not an oversight.
- In worktree mode, `RepoRoot` is the recorded originating/base worktree path, not a canonical repository root or base ref.
- `Base` is the recorded parent branch. Implementation adds the currently missing assertion that `RepoRoot` still has that exact branch checked out, and the currently missing requirement that `Base` be a local branch at all.
- Untracked/ignored origin-worktree content is allowed. This carve-out is load-bearing, not a convenience: `.projexwt/` itself surfaces as untracked at the base worktree whenever the `.git/info/exclude` registration is absent, so a full-`--porcelain` gate would self-block the framework's own worktree mechanism.
- Git rejects tracked-path collisions before overwrite **at the point it runs its integration command** — which for rebase-close is after the history rewrite. Squash and merge inherit the protection for free; rebase must ask the question earlier itself.
- `git reset --merge HEAD` clears failed squash index/worktree state without the destructive semantics of `--hard` — **verified** against a conflicted squash: exit `0`, index and worktree restored to `HEAD`, conflict markers cleared, untracked content preserved.
- The gate binds at pre-flight only. Nothing re-checks between the gate and the mutation, so a writer active during close (IDE autosave, watcher, parallel agent) can still dirty the tree inside the window. Git's own overwrite refusal remains the real backstop; the gate converts a confusing late failure into a clear early one.

### Impact Analysis

- **Direct:** Six finalizers verify the origin-worktree/base-branch pairing, reject tracked-dirty states they currently accept, and make squash rollback non-destructive. `rebase-close` additionally checks untracked collisions before rewriting history. Untracked/ignored origin-worktree content stays allowed.
- **Breaking:** `Base` values that are not local branches — tags, raw SHAs, `origin/main` — are accepted by every script today via `rev-parse --verify` and will begin exiting `1`. Narrow blast radius in the projex happy path, wider for anything scripted around current permissiveness. Called out here rather than buried in Step 1 because it is the only change that rejects input previously honoured.
- **Adjacent:** `close-projex.md` preflight matches script behaviour; conflict-resolution guidance/error text changes where it claims a hard reset occurred. `tests/README.md` coverage table and the `CLAUDE.md` assertion count both name suite contents, so both go stale on the same commit if not updated with it.
- **Downstream:** Agents invoking close scripts must commit or explicitly stash tracked changes in the integration checkout. Busy repos may retain unrelated untracked/ignored files. Callers relying on `exit 1 ⇒ nothing changed` keep that invariant only if Step 1's rebase pre-check lands — without it, `rebase-close` can exit `1` having already rewritten the ephemeral branch.

---

## Implementation

### Overview

Add the same early tracked-status guard to each finalizer, before checkout/merge/rebase. In worktree mode, resolve `Base` to its full branch ref, assert `RepoRoot`'s symbolic `HEAD` matches it, then inspect that origin worktree's index/filesystem; do not assume `main`/`master` or locate a different worktree. Give `rebase-close` one extra pre-check its siblings do not need, because it is the only script that mutates before consulting `RepoRoot`. Retain the stricter child execution-worktree guard. Replace only squash-close's two unconditional hard resets with checked `reset --merge` rollback. Lock behavior with disposable repositories inside the existing `tests/` suite; no new abstraction, dependency, or parallel test convention.

### Step 1: Verify Origin/Base Pairing and Tracked Cleanliness

**Objective:** Stop every finalizer before mutation when its integration worktree contains staged or unstaged tracked changes; allow unrelated untracked/ignored content.
**Confidence:** High
**Depends on:** None

**Files:**
- `projex-squash-close.sh`
- `projex-squash-close.ps1`
- `projex-merge-close.sh`
- `projex-merge-close.ps1`
- `projex-rebase-close.sh`
- `projex-rebase-close.ps1`

**Changes:**

```text
Before:
- checkout mode: git diff + git diff --cached checks tracked content
- worktree mode: only execution worktree checked
- Base validated only by `rev-parse --verify` (accepts tags, SHAs, remote refs)
- rebase-close: rebases (rewriting ephemeral SHAs) before RepoRoot is consulted at all

After:
- all modes: resolve `Base` via `rev-parse --symbolic-full-name`; not `refs/heads/*` -> exit 1
  naming the resolved ref type. Deliberate narrowing; see Impact Analysis > Breaking.
- checkout mode: check current checkout via
  `status --porcelain --untracked-files=no --ignore-submodules=dirty`, then switch to `Base`
- worktree mode: resolve `RepoRoot`'s symbolic `HEAD` to canonical `refs/heads/*` and compare to
  `Base`; mismatch/detached state exits `1` before mutation
- worktree mode: after identity match, check that origin/base worktree via the same status command
- tracked output: print first 10 entries, explain tracked changes must be committed/stashed, exit 1
- untracked/ignored-only state: continue; Git rejects path collisions for squash and merge
- rebase-close ONLY, worktree mode: before rebasing, intersect
  `git -C <RepoRoot> diff --name-only <Base>...<Ephemeral>` with untracked paths at `RepoRoot`;
  non-empty -> exit 1 pre-mutation, naming the colliding paths
- worktree mode: run existing strict execution-worktree gate after the base-worktree gate
```

Place ref-type validation, branch/worktree identity validation, and the guard after repository/branch/in-progress validation and before any checkout, rebase, or merge. Ordering after the in-progress check is required, not incidental: it preserves today's exit-2 → resume messages, which `tests/resume.test.sh` asserts on. Replace the checkout-only `diff`/`diff --cached` blocks with the same tracked-status expression for parity. Do not auto-stash or search for another worktree when the recorded origin no longer matches.

**Rationale:** The risk comes from tracked index/worktree content that merge/reset may consume or discard. Blocking unrelated untracked files would make worktree mode needlessly hostile in busy repos — and would self-block `.projexwt/` itself where the exclude registration is missing. Identity needs both coordinates: `RepoRoot` selects the originating worktree state; `Base` selects its intended parent branch. Neither implies a primary checkout or `main`/`master`.

The rebase pre-check is not symmetry for its own sake. Squash and merge get collision protection free from Git because their integration command runs at `RepoRoot`; rebase rewrites history first, so by the time Git objects the damage is durable. Reproduced: ephemeral tip rewritten, base unmoved, worktree stranded, exit `1` with a message naming no cause. Cheapest correct fix is to ask `RepoRoot` the question before touching the ephemeral branch.

**Verification:** For every implementation, utility-branch and parent-Projex origins close back into their recorded `Base` while unrelated branches/worktrees remain unchanged. Mismatched or detached `RepoRoot` exits `1`. Non-branch `Base` exits `1`. Staged/unstaged tracked scenarios exit `1` with unchanged state; a dirty submodule alone does **not** block. Unrelated untracked/ignored scenarios complete and preserve bytes. A colliding untracked path fails with no overwrite, no base-ref movement, and — asserted explicitly for rebase — **the ephemeral tip SHA unchanged from before the invocation**.

**If this fails:** Revert only the new guard/removal of old checks; no repository state should have changed because the guard precedes mutations.

---

### Step 2: Remove Destructive Squash Rollback

**Objective:** Bring squash rollback into compliance with the project rule against unapproved `git reset --hard`, without weakening cleanup.
**Confidence:** Medium
**Depends on:** Step 1

> **Read this step's value honestly.** Step 1 makes tracked dirt at merge time unreachable, and `reset --hard` never removes untracked files. At the moment this rollback fires, the tree is guaranteed tracked-clean and the only thing `--hard` can discard is the failed squash itself — exactly what should be discarded. **This step therefore adds no incremental data safety.** Its justification is policy compliance, which is sufficient on its own; the plan states it plainly so the step is reviewed against the right bar rather than looking like Step 1 duplicated.

**Files:**
- `projex-squash-close.sh`
- `projex-squash-close.ps1`

**Changes:**

```text
Before:
merge --squash failure -> unconditional `git reset --hard HEAD` -> report clean rollback

After:
merge --squash failure -> checked `git reset --merge HEAD`
  success -> report rollback to clean pre-merge state
  failure -> exit 1, report rollback failure and leave state for explicit recovery
```

Apply to uncovered anticipated conflicts and generic merge failures. Preserve exit `2` behavior for fully covered conflicts; no rollback occurs there. Keep manual hard-reset guidance explicitly approval-gated.

**Rollback-failure message must not dead-end.** If `reset --merge` fails, the conflicted squash stays in the base worktree — which trips `in_progress_op` on the next invocation (detected via unmerged entries; squash leaves no `MERGE_HEAD`) and exits `1`. The script's existing in-progress message already routes there to `git reset --hard HEAD` "with your explicit approval" (`projex-squash-close.sh:122`). Say so directly in the rollback-failure message rather than leaving the caller to rediscover it two invocations later. Net honesty: this step converts an automatic recovery into a manual one that can still terminate at the same command, now under human approval — which is the point of the policy.

**Rationale:** `--merge` avoids the project-forbidden automatic hard reset. Clean preflight from Step 1 makes it predictable — verified against a conflicted squash: exit `0`, index and worktree restored to `HEAD`, conflict markers cleared, untracked content preserved. Failure must preserve evidence/state rather than escalating destructiveness.

**Verification:** Clean conflict returns `1`, retains base `HEAD`, restores clean index/worktree, preserves ephemeral branch, and contains no `reset --hard` invocation. Covered conflict still returns `2` with resolution state intact. **The rollback-failure branch is exercised** — construct a state where `reset --merge` refuses, assert exit `1`, assert the conflicted state is preserved rather than silently escalated, and assert the message names the approval-gated recovery. If no such state can be constructed, record that finding and the branch's unreachability rather than shipping an unexercised path.

**If this fails:** Leave failed squash state untouched and print manual recovery commands; never fall back automatically to `reset --hard`.

---

### Step 3: Add Dirty-Base Regression Suite to `tests/`

**Objective:** Extend the existing suite — not shadow it — so the dirty-base matrix runs wherever the current suites run.
**Confidence:** High
**Depends on:** Steps 1-2

**Files:**
- `tests/dirty-base.test.sh`
- `tests/dirty-base.test.ps1`
- `tests/run-all.sh`
- `tests/run-all.ps1`
- `tests/README.md`
- `CLAUDE.md`

**Changes:**

Follow the conventions the existing suites already establish: `chk`/`Chk` as the only assertion helper, throwaway repos under the system temp dir removed on success, assertions against observable git state (exit codes, `MERGE_HEAD`, rebase dirs, unmerged index entries, branch existence, committed content) and never script internals, and a final `PASS=<n> FAIL=<n>` line the runners parse. Register both files in the matching runner, add a coverage-table row to `tests/README.md`, and update the assertion count in `CLAUDE.md`.

For squash, merge, and rebase close:

1. Create a repository with primary, utility-worktree, and parent-Projex origins; create each child execution worktree from the origin's `HEAD`.
2. Dirty the integration checkout separately with unstaged tracked, staged tracked, dirty-submodule-only, unrelated untracked, and colliding untracked content.
3. Invoke matching close script with worktree mode.
4. For tracked dirt, assert exit `1`, unchanged file bytes/status/refs, registered execution worktree, and no merge/rebase state. For dirty-submodule-only, assert close **succeeds**.
5. For unrelated untracked/ignored content, assert close succeeds and content survives. For a colliding untracked path, assert failure with no overwrite, no base-ref movement, and — for rebase specifically — **the ephemeral tip SHA identical to its pre-invocation value**. Capture that SHA before invoking; a test that only checks the base ref passes on the broken behaviour.
6. Run clean conflicting squash; assert exit `1`, clean rollback, unchanged base `HEAD`, surviving ephemeral branch, and no `reset --hard` in the script's own output. Add the Step 2 rollback-failure case.
7. Run clean happy path for each close type; assert exit `0`, expected base result, deleted ephemeral branch, and removed worktree registration.
8. Run utility-branch and nested-Projex cases; assert each child integrates only into its recorded parent branch/worktree. Run mismatched-origin, detached-origin, and non-branch-`Base` cases; assert exit `1` before mutation.

**Rationale:** The bug crosses modes and failure paths; disposable repos prove non-mutation directly without touching developer repositories. Landing outside `tests/` would leave the one guard against reintroducing the loss invisible to `run-all.*` and to the `CLAUDE.md` instruction that governs changes to these scripts — green suite, unexecuted matrix. It would also create a second test convention alongside the one that already exists, a larger drift axis than the `.sh`/`.ps1` drift this plan's Risks section already worries about.

**Verification:** `tests/run-all.sh` and `pwsh tests/run-all.ps1` both pass and both report the new suite's assertions in their totals. An intentionally removed gate makes dirty-base cases fail. `tests/README.md` and `CLAUDE.md` counts match actual output.

**If this fails:** Preserve the failing temp repository, report scenario + assertion, and stop. Fix implementation or test setup before proceeding.

---

### Step 4: Align Close Workflow Contract

**Objective:** Make documented guarantees match script behavior and explain worktree-mode close requirements.
**Confidence:** High
**Depends on:** Steps 1-3

> **Sequencing is load-bearing.** `close-projex.md:418` currently instructs a blanket `git status --porcelain` check with "if output is non-empty, commit or discard." That blanket instruction incidentally prevents the rebase collision state. Relaxing it to permit untracked content **before** Step 1's rebase pre-check lands would actively steer agents into the stranded half-close. Do not ship this step ahead of Step 1; if Step 1's rebase pre-check is descoped, carve rebase-close out of the relaxation.

**Files:**
- `close-projex.md`

**Changes:**

- State that execution may begin while the originating worktree is dirty, but finalization requires no tracked changes in the originating/base worktree; unrelated untracked/ignored content may remain.
- Name both gates: tracked-clean originating/base worktree and fully clean child execution worktree.
- Replace “main working directory/checkout” with “originating/base worktree.” Clarify `RepoRoot` may be any worktree and `Base` must be a local branch — any local branch, including a utility or outer Projex branch, but not a tag, SHA, or remote-tracking ref.
- Document the required exact pairing: `RepoRoot` must still have `Base` checked out; finalizers fail rather than guess/substitute another worktree or `main`/`master`.
- State finalizers apply the integration-worktree gate independently, as a **pre-flight check**. Do not write "enforce" — nothing re-checks between the gate and the mutation, and a caller who reads the gate as a guarantee will stop committing before close. Git's own overwrite refusal remains the real backstop.
- Remove/adjust claims that squash failure cleanup uses or completed `reset --hard`; document safe rollback failure handling, including that a failed rollback leaves conflicted state whose recovery is approval-gated.
- Keep stash restoration caller-owned and explicitly logged.

**Rationale:** The workflow already asks for cleanliness; matching the doc to actual script behaviour prevents the prior caller/script contract split — in both directions. Overclaiming enforcement would swap a permissive doc for a misleading one.

**Verification:** Every finalization instruction matches actual exit codes and recovery messages; repository-wide search finds no claim that close scripts automatically hard-reset failed squash state, and none that they enforce rather than pre-check.

**If this fails:** Revert doc edits independently; implementation and regression suite remain valid.

---

## Verification Plan

### Automated Checks

- [x] Run `tests/run-all.sh` — gating. Existing suites plus the new one; baseline before this plan is `PASS=116 FAIL=0`.
- [x] Run `pwsh tests/run-all.ps1` — gating. Both platforms required; `.sh` and `.ps1` duplicate logic, so one passing proves nothing about the other.
- [x] Confirm no pre-existing assertion regressed. Any deliberately changed assertion is recorded with rationale in the walkthrough.
- [x] Search six finalizers for `reset --hard`; only explicit manual approval guidance may remain.
- [x] Compare shell/PowerShell scenario results and exit codes.

### Manual Verification

- [x] Review each mutation path: gate precedes checkout/merge/rebase — and for rebase, precedes the rebase itself, not just the fast-forward.
- [x] Confirm ignored execution-worktree content remains warning-only.
- [x] Confirm no test or script stashes, deletes, or overwrites pre-existing integration-worktree content.
- [x] Confirm utility-worktree and nested-Projex cases integrate into their immediate recorded parent, not `main`/`master`.
- [x] Confirm every exit-`1` path leaves no durable mutation, or says plainly in its message what it did change.
- [x] Confirm unrelated current worktree changes are absent from implementation diff.

### Acceptance Criteria Validation

| Criterion | How to Verify | Expected Result |
|-----------|---------------|-----------------|
| Arbitrary parent topology preserved | utility + nested Projex origins × 3 close types × 2 shells | Child integrates into recorded parent only |
| Origin/base mismatch rejected | wrong branch + detached origin × 3 close types × 2 shells | Exit `1`; zero state mutation |
| Non-branch `Base` rejected | tag + raw SHA + `origin/<b>` × 3 close types × 2 shells | Exit `1` naming the ref type; zero state mutation |
| Tracked-dirty integration checkout rejected | staged + unstaged × 3 close types × 2 shells | Exit `1`; zero state mutation |
| Submodule dirt does not block | dirty submodule, superproject clean × 3 close types × 2 shells | Exit `0`; close completes |
| Untracked busy-repo content preserved | unrelated + colliding paths × 3 close types × 2 shells | Unrelated survives successful close; collision fails with no overwrite, no base-ref move, **and ephemeral tip SHA unchanged** |
| Rebase mutates nothing before its gate | colliding untracked at `RepoRoot`, rebase worktree mode × 2 shells | Ephemeral tip SHA identical to pre-invocation value; worktree registered; exit `1` names the colliding path |
| Squash rollback safe | Clean conflict scenario | Clean checkout; same `HEAD`; ephemeral survives |
| Squash rollback-failure branch exercised | Constructed `reset --merge` refusal | Exit `1`; conflicted state preserved; message names approval-gated recovery — or unreachability recorded |
| Conflict contract retained | Covered/uncovered conflict scenarios | Covered `2`; uncovered `1` + rollback |
| Happy paths retained | Clean success per close type | Exit `0`; base updated; branch/worktree removed |
| Existing coverage intact | `tests/run-all.sh` + `pwsh tests/run-all.ps1` | No pre-existing assertion regressed; new suite counted in totals |
| Docs aligned | Review + search | Dual pre-flight gate and non-hard rollback documented; no "enforce" claim |

---

## Rollback Plan

If implementation must be abandoned:

1. Revert only plan-scoped script, test, and workflow changes on the ephemeral branch.
2. Do not run close scripts against any reproduction repository with dirty state.
3. Delete disposable successful test repositories; retain only a failing case needed for diagnosis.
4. Leave user-owned base changes, stashes, branches, and unrelated worktree content untouched.

---

## Revision Log

- **2026-07-26:** Absorbed all eight findings from 2607261157-close-scripts-dirty-base-safety-redteam.md — trigger: adversarial review with reproductions against the live scripts. Specifically: (1) added a pre-rebase untracked-collision check to Step 1 and tightened the criterion to constrain ephemeral-ref stability, after the redteam reproduced `rebase-close` rewriting ephemeral SHAs before the fast-forward is refused, an outcome the prior criterion certified as correct; (2) re-justified Step 2 on policy-compliance grounds and required its rollback-failure branch to be exercised, after Step 1 was shown to consume Step 2's data-loss rationale entirely; (3) relocated the regression matrix from root-level launchers into the pre-existing `tests/` suite with runner registration, README row, and `CLAUDE.md` count, and corrected Estimated Changes 9 → 13; (4) made `tests/run-all.{sh,ps1}` gating Automated Checks against a recorded `PASS=116 FAIL=0` baseline; (5) defined non-branch `Base` behaviour and recorded it as a breaking change; (6) excluded dirty submodules from the gate and recorded the `assume-unchanged`/`skip-worktree` hole; (7) reframed the gate as pre-flight rather than enforcement in Step 4 and Assumptions; (8) sequenced Step 4's doc relaxation behind Step 1's rebase fix. Also corrected the Objective's framing: reproduced loss is confined to the squash-conflict rollback path, and non-conflicting closes were verified to preserve unrelated tracked edits in all three close types.
- **2026-07-26:** Narrowed main/integration checkout gate from all porcelain output to tracked staged/unstaged content; allowed unrelated untracked/ignored files; clarified `RepoRoot` as base worktree path and `Base` as ref — trigger: “I'm not sure if this is viable in a busy repo” and “also why repo root? not base ref?”
- **2026-07-26:** Replaced primary-main topology assumption with recorded origin-worktree/parent-branch model; added missing exact `RepoRoot`→`Base` assertion and utility/nested-Projex regression cases — trigger: “not every projex work tree branch of main/master; it could originate from a utility work tree or a projex branch”

## Notes

### Risks

- `reset --merge HEAD` may fail for an unusual partial squash state: fail closed and preserve state; never auto-escalate to `--hard`. Recovery from that state is approval-gated and may still end at `reset --hard` by hand — say so in the message.
- New gate changes tracked-dirty behavior only: users must commit/stash tracked edits; unrelated untracked/ignored busy-repo content remains allowed.
- Non-branch `Base` becomes an error. Low likelihood in the projex happy path, higher for anything scripted around today's `rev-parse --verify` permissiveness. Mitigation: name the resolved ref type in the message so the cause is obvious.
- The gate cannot bind across the mutation window. A writer active during close can dirty the tree after the check passes; Git's overwrite refusal is the backstop. Do not document the gate as a guarantee.
- Test duplication may drift: keep scenarios/data names mechanically parallel; no shared cross-language framework. Reusing `tests/` conventions bounds this to the drift axis that already exists rather than adding a second one.
- User currently has unrelated changes in this repository: execute in a worktree and stage only explicit plan-scoped paths.

### Open Questions

None.

### Split Decision

No split — single utility-script/workflow scope; four tightly coupled steps within size budget.
