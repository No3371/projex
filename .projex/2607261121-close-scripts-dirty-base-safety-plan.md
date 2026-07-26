# Close Scripts: Dirty Base Safety

> **Status:** Ready
> **Created:** 2026-07-26
> **Author:** Codex
> **Source:** 2607260233-worktree-squash-close-dirty-base-reset-memo.md
> **Related Projex:** 2607132112-projex-rebase-close-scripts-redteam.md
> **Worktree:** Yes

---

## Summary

Make every branch-finalization script reject tracked changes in the checkout it will mutate, including the originating/base worktree passed as `RepoRoot` in worktree mode. `RepoRoot` may itself be any registered worktree; `Base` may be `main`, a utility branch, feature branch, or parent `projex/*` branch. Allow unrelated untracked/ignored content, remove squash-close's automatic `reset --hard`, preserve shell/PowerShell parity, and retain a disposable-repo regression check for the data-loss class.

**Scope:** Squash, merge, and rebase close scripts; close workflow contract; dirty-base regression checks.
**Estimated Changes:** 9 files — 6 close scripts, 1 workflow spec, 2 test launchers.

---

## Objective

### Problem / Gap / Need

Worktree mode validates only the child execution worktree. All close scripts then mutate the originating/base worktree without verifying its tracked state or confirming it still has `Base` checked out. Observed effects:

- `squash-close`: conflict cleanup runs `reset --hard HEAD`, deleting unrelated tracked edits. A staged edit is also deleted when `merge --squash` refuses to start but cleanup still resets.
- `merge-close`: `merge --abort` preserved a simple unrelated edit in reproduction, but Git does not guarantee reconstruction when a merge begins with uncommitted changes.
- `rebase-close`: rebase occurs safely in the execution worktree, then the script fast-forwards and deletes the branch while the base checkout remains dirty.
- All three close types accept nonconflicting tracked base edits and report success. Untracked content is a different class: it is not part of the index, survives safe rollback, and Git refuses integration when a tracked path would overwrite it.

`close-projex.md` already requires `git status --porcelain` before finalization, but safety exists only at the caller layer. Direct script use or a missed workflow gate can still lose work.

### Success Criteria

- [ ] Worktree-mode finalizers verify that recorded `RepoRoot` still has recorded `Base` checked out before mutation; arbitrary utility/feature/parent-Projex bases remain supported.
- [ ] All six close implementations exit `1` before mutation when the checkout they will mutate has staged or unstaged tracked changes.
- [ ] Unrelated untracked/ignored content does not block close and remains byte-for-byte intact; a colliding untracked path makes Git fail without overwriting it.
- [ ] Worktree mode still separately rejects a dirty execution worktree.
- [ ] Squash failure cleanup contains no automatic `git reset --hard` and restores a clean pre-merge checkout with `git reset --merge HEAD`.
- [ ] Clean success, anticipated-conflict exit `2`, rollback exit `1`, branch deletion, and best-effort worktree removal retain existing behavior.
- [ ] Shell and PowerShell regression launchers reproduce dirty-base cases in temporary repositories and assert content, refs, status, and exit codes.
- [ ] Workflow docs distinguish the tracked-clean integration-worktree gate from the fully clean execution-worktree gate and state that scripts enforce both independently.

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

### Key Files

| File | Role | Change Summary |
|------|------|----------------|
| `projex-squash-close.sh` | POSIX squash finalizer | Unified checkout gate; safe squash rollback |
| `projex-squash-close.ps1` | PowerShell squash finalizer | Parity change |
| `projex-merge-close.sh` | POSIX merge finalizer | Unified checkout gate |
| `projex-merge-close.ps1` | PowerShell merge finalizer | Parity change |
| `projex-rebase-close.sh` | POSIX rebase finalizer | Verify origin/base pairing; gate tracked changes |
| `projex-rebase-close.ps1` | PowerShell rebase finalizer | Parity change |
| `close-projex.md` | Finalization workflow | Clarify script-enforced dual cleanliness gate |
| `test-close-dirty-base.sh` | POSIX regression launcher | Disposable-repo safety matrix |
| `test-close-dirty-base.ps1` | PowerShell regression launcher | Same matrix for PowerShell implementations |

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

- `git status --porcelain --untracked-files=no` output means tracked staged/unstaged content exists and finalization must stop.
- In worktree mode, `RepoRoot` is the recorded originating/base worktree path, not a canonical repository root or base ref.
- `Base` is the recorded parent branch. Implementation adds the currently missing assertion that `RepoRoot` still has that exact branch checked out.
- Untracked/ignored origin-worktree content is allowed. Git must reject tracked-path collisions before overwrite; regression checks preserve this contract.
- With a clean preflight, `git reset --merge HEAD` can clear failed squash index/worktree state without the destructive semantics of `--hard`.

### Impact Analysis

- **Direct:** Six finalizers verify the origin-worktree/base-branch pairing, reject tracked-dirty states they currently accept, and make squash rollback non-destructive. Untracked/ignored origin-worktree content stays allowed.
- **Adjacent:** `close-projex.md` preflight matches executable enforcement; conflict-resolution guidance/error text changes where it claims a hard reset occurred.
- **Downstream:** Agents invoking close scripts must commit or explicitly stash tracked changes in the integration checkout. Busy repos may retain unrelated untracked/ignored files.

---

## Implementation

### Overview

Add the same early tracked-status guard to each finalizer, before checkout/merge/rebase. In worktree mode, resolve `Base` to its full branch ref, assert `RepoRoot`'s symbolic `HEAD` matches it, then inspect that origin worktree's index/filesystem; do not assume `main`/`master` or locate a different worktree. Retain the stricter child execution-worktree guard. Replace only squash-close's two unconditional hard resets with checked `reset --merge` rollback. Lock behavior with disposable repositories; no new abstraction or dependency.

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

After:
- checkout mode: check current checkout via `status --porcelain --untracked-files=no`, then switch to `Base`
- worktree mode: resolve `Base` and `RepoRoot`'s symbolic `HEAD` to canonical `refs/heads/*`; mismatch/detached state exits `1` before mutation
- worktree mode: after identity match, check that origin/base worktree via the same tracked-only status command
- tracked output: print first 10 entries, explain tracked changes must be committed/stashed, exit 1
- untracked/ignored-only state: continue; Git remains responsible for rejecting path collisions
- worktree mode: run existing strict execution-worktree gate after the base-worktree gate
```

Place branch/worktree identity validation and the guard after repository/branch/in-progress validation and before any checkout, rebase, or merge. Replace the checkout-only `diff`/`diff --cached` blocks with the same tracked-status expression for parity. Do not auto-stash or search for another worktree when the recorded origin no longer matches.

**Rationale:** The risk comes from tracked index/worktree content that merge/reset may consume or discard. Blocking unrelated untracked files would make worktree mode needlessly hostile in busy repos. Identity needs both coordinates: `RepoRoot` selects the originating worktree state; `Base` selects its intended parent branch. Neither implies a primary checkout or `main`/`master`.

**Verification:** For every implementation, utility-branch and parent-Projex origins close back into their recorded `Base` while unrelated branches/worktrees remain unchanged. Mismatched or detached `RepoRoot` exits `1`. Staged/unstaged tracked scenarios exit `1` with unchanged state. Unrelated untracked/ignored scenarios complete and preserve bytes; a colliding untracked path fails without overwrite or ref movement.

**If this fails:** Revert only the new guard/removal of old checks; no repository state should have changed because the guard precedes mutations.

---

### Step 2: Remove Destructive Squash Rollback

**Objective:** Clear failed squash state without deleting unrelated tracked content.
**Confidence:** Medium
**Depends on:** Step 1

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

**Rationale:** Clean preflight makes normal rollback predictable; `--merge` avoids the project-forbidden automatic hard reset. Failure must preserve evidence/state rather than escalating destructiveness.

**Verification:** Clean conflict returns `1`, retains base `HEAD`, restores clean index/worktree, preserves ephemeral branch, and contains no `reset --hard` invocation. Covered conflict still returns `2` with resolution state intact.

**If this fails:** Leave failed squash state untouched and print manual recovery commands; never fall back automatically to `reset --hard`.

---

### Step 3: Add Dirty-Base Regression Check

**Objective:** Leave one runnable safety suite, expressed in both repository-supported shells.
**Confidence:** High
**Depends on:** Steps 1-2

**Files:**
- `test-close-dirty-base.sh`
- `test-close-dirty-base.ps1`

**Changes:**

Each launcher creates temporary Git repositories and deletes them on completion. For squash, merge, and rebase close:

1. Create a repository with primary, utility-worktree, and parent-Projex origins; create each child execution worktree from the origin's `HEAD`.
2. Dirty the integration checkout separately with unstaged tracked, staged tracked, unrelated untracked, and colliding untracked content.
3. Invoke matching close script with worktree mode.
4. For tracked dirt, assert exit `1`, unchanged file bytes/status/refs, registered execution worktree, and no merge/rebase state.
5. For unrelated untracked/ignored content, assert close succeeds and content survives. For a colliding untracked path, assert failure without overwrite or base-ref movement.
6. Run clean conflicting squash; assert exit `1`, clean rollback, unchanged base `HEAD`, surviving ephemeral branch.
7. Run clean happy path for each close type; assert exit `0`, expected base result, deleted ephemeral branch, and removed worktree registration.
8. Run utility-branch and nested-Projex cases; assert each child integrates only into its recorded parent branch/worktree. Run mismatched/detached-origin cases; assert exit `1` before mutation.

Use shell-native assertions and Git only. Print one concise pass/fail summary; preserve failed temp repo path for diagnosis, remove successful cases.

**Rationale:** The bug crosses modes and failure paths; disposable repos prove non-mutation directly without touching developer repositories.

**Verification:** `./test-close-dirty-base.sh` and `./test-close-dirty-base.ps1` pass on their supported platforms; an intentionally removed gate makes dirty-base cases fail.

**If this fails:** Preserve the failing temp repository, report scenario + assertion, and stop. Fix implementation or test setup before proceeding.

---

### Step 4: Align Close Workflow Contract

**Objective:** Make documented guarantees match script behavior and explain worktree-mode close requirements.
**Confidence:** High
**Depends on:** Steps 1-3

**Files:**
- `close-projex.md`

**Changes:**

- State that execution may begin while the originating worktree is dirty, but finalization requires no tracked changes in the originating/base worktree; unrelated untracked/ignored content may remain.
- Name both gates: tracked-clean originating/base worktree and fully clean child execution worktree.
- Replace “main working directory/checkout” with “originating/base worktree.” Clarify `RepoRoot` may be any worktree and `Base` may be any branch, including a utility or outer Projex branch.
- Document the required exact pairing: `RepoRoot` must still have `Base` checked out; finalizers fail rather than guess/substitute another worktree or `main`/`master`.
- State finalizers independently enforce the integration-worktree gate.
- Remove/adjust claims that squash failure cleanup uses or completed `reset --hard`; document safe rollback failure handling.
- Keep stash restoration caller-owned and explicitly logged.

**Rationale:** The workflow already asks for cleanliness; explicit script enforcement prevents the prior caller/script contract split.

**Verification:** Every finalization instruction matches actual exit codes and recovery messages; repository-wide search finds no claim that close scripts automatically hard-reset failed squash state.

**If this fails:** Revert doc edits independently; implementation and regression suite remain valid.

---

## Verification Plan

### Automated Checks

- [ ] Run `test-close-dirty-base.ps1` against PowerShell finalizers.
- [ ] Run `test-close-dirty-base.sh` against POSIX finalizers.
- [ ] Search six finalizers for `reset --hard`; only explicit manual approval guidance may remain.
- [ ] Compare shell/PowerShell scenario results and exit codes.

### Manual Verification

- [ ] Review each mutation path: gate precedes checkout/merge/rebase.
- [ ] Confirm ignored execution-worktree content remains warning-only.
- [ ] Confirm no test or script stashes, deletes, or overwrites pre-existing integration-worktree content.
- [ ] Confirm utility-worktree and nested-Projex cases integrate into their immediate recorded parent, not `main`/`master`.
- [ ] Confirm unrelated current worktree changes are absent from implementation diff.

### Acceptance Criteria Validation

| Criterion | How to Verify | Expected Result |
|-----------|---------------|-----------------|
| Arbitrary parent topology preserved | utility + nested Projex origins × 3 close types × 2 shells | Child integrates into recorded parent only |
| Origin/base mismatch rejected | wrong branch + detached origin × 3 close types × 2 shells | Exit `1`; zero state mutation |
| Tracked-dirty integration checkout rejected | staged + unstaged × 3 close types × 2 shells | Exit `1`; zero state mutation |
| Untracked busy-repo content preserved | unrelated + colliding paths × 3 close types × 2 shells | Unrelated survives successful close; collision fails without overwrite/ref move |
| Squash rollback safe | Clean conflict scenario | Clean checkout; same `HEAD`; ephemeral survives |
| Conflict contract retained | Covered/uncovered conflict scenarios | Covered `2`; uncovered `1` + rollback |
| Happy paths retained | Clean success per close type | Exit `0`; base updated; branch/worktree removed |
| Docs aligned | Review + search | Dual gate and non-hard rollback documented |

---

## Rollback Plan

If implementation must be abandoned:

1. Revert only plan-scoped script, test, and workflow changes on the ephemeral branch.
2. Do not run close scripts against any reproduction repository with dirty state.
3. Delete disposable successful test repositories; retain only a failing case needed for diagnosis.
4. Leave user-owned base changes, stashes, branches, and unrelated worktree content untouched.

---

## Revision Log

- **2026-07-26:** Narrowed main/integration checkout gate from all porcelain output to tracked staged/unstaged content; allowed unrelated untracked/ignored files; clarified `RepoRoot` as base worktree path and `Base` as ref — trigger: “I'm not sure if this is viable in a busy repo” and “also why repo root? not base ref?”
- **2026-07-26:** Replaced primary-main topology assumption with recorded origin-worktree/parent-branch model; added missing exact `RepoRoot`→`Base` assertion and utility/nested-Projex regression cases — trigger: “not every projex work tree branch of main/master; it could originate from a utility work tree or a projex branch”

## Notes

### Risks

- `reset --merge HEAD` may fail for an unusual partial squash state: fail closed and preserve state; never auto-escalate to `--hard`.
- New gate changes tracked-dirty behavior only: users must commit/stash tracked edits; unrelated untracked/ignored busy-repo content remains allowed.
- Test duplication may drift: keep scenarios/data names mechanically parallel; no shared cross-language framework.
- User currently has unrelated changes in this repository: execute in a worktree and stage only explicit plan-scoped paths.

### Open Questions

None.

### Split Decision

No split — single utility-script/workflow scope; four tightly coupled steps within size budget.
