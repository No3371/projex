# Execution Log: Close Scripts: Dirty Base Safety
Started: 20260726 12:13
Repo Root: S:/Repos/projex
Plan File: .projex/2607261121-close-scripts-dirty-base-safety-plan.md
Base Branch: main
Worktree Path: projex/.projexwt/2607261121-close-scripts-dirty-base-safety

## Pre-Check Results

```
REPO_ROOT=S:/Repos/projex
BRANCH=main
PLAN_REL=.projex/2607261121-close-scripts-dirty-base-safety-plan.md

PASS  Plan is committed (1ae7b25 projex(revise): absorb redteam findings into close-scripts dirty-base plan)
WARN  Working tree has 12 uncommitted change(s)

PRE-CHECK PASSED
```

WARN resolved by worktree mode (`> **Worktree:** Yes` in plan header): the 12 uncommitted changes in the
main checkout are unrelated pre-existing dirt (incl. an edit to `close-projex.md`, which Step 4 also
touches). Worktree isolates execution from them; the main checkout is never mutated. Only plan-scoped
paths are staged.

Bootstrap: none required — repo is markdown + shell/PowerShell scripts, no manifest, no gitignored deps.
Execution mode: self-execute (4 tightly-coupled steps over the same 6 scripts; delegation would fragment
parity work across contexts).

## Steps

### [20260726 12:40] - Step 1: Verify Origin/Base Pairing and Tracked Cleanliness

**Action:** Added the dirty-base gate to all six finalizers, placed after repo/branch/in-progress
validation and before any checkout, merge, rebase, or fast-forward.

- New shared helpers per script: `full_ref` / `Get-FullRef`, `tracked_dirt` / `Get-TrackedDirt`,
  `Assert-LocalBranch` (PS only — bash inlines the `case` on `$BASE_REF`).
- `Base` resolved via `rev-parse --symbolic-full-name`; anything not `refs/heads/*` exits `1` naming
  the resolved kind (tag / remote-tracking ref / raw commit / other).
- Worktree mode: `git -C <RepoRoot> symbolic-ref --quiet HEAD` must equal the resolved `BASE_REF`;
  empty (detached) or mismatched exits `1` before mutation.
- All modes: `git status --porcelain --untracked-files=no --ignore-submodules=dirty` at `RepoRoot`;
  non-empty prints first 10 entries and exits `1`. This replaces the checkout-mode
  `diff --quiet` + `diff --cached --quiet` pair in all six scripts (parity, same semantics for
  tracked content).
- `projex-rebase-close.{sh,ps1}` only, worktree mode: `untracked_collisions` /
  `Get-UntrackedCollisions` intersects `git diff --name-only <Base>...<Ephemeral>` with
  `git ls-files --others --exclude-standard` at `RepoRoot`, immediately before `git rebase`.
  Non-empty exits `1` naming the paths — the ephemeral branch is never rewritten.
- `.sh` scripts: removed the now-duplicate checkout-mode dirty checks; the unified gate covers them.

**Result:** Manual scenarios against throwaway repos (bash, worktree mode) — evidence:

| Scenario | Observed |
|---|---|
| Unstaged tracked edit at base, merge-close | exit `1`, `Error: '<repo>' has tracked changes …` + ` M a.txt`; base ref unmoved, edit intact |
| Untracked `new.txt` at base colliding with incoming tracked `new.txt`, rebase-close | exit `1`, message names `new.txt`; **ephemeral tip SHA unchanged**; squatter file byte-identical |
| `Base` = tag `v1` | exit `1`, `base 'v1' resolves to a tag (refs/tags/v1), not a local branch` |
| `RepoRoot` on `other`, `Base` = `main` | exit `1`, `has 'other' checked out, not 'main' … never substitute` |
| Unrelated untracked `keep.txt` at base, squash-close | exit `0`, close completed, `keep.txt` intact, `new.txt` on `main` |

Regression: `tests/run-all.sh` → `PASS=116 FAIL=0`; `pwsh tests/run-all.ps1` → `PASS=72 FAIL=0`
(188 total, matching the recorded baseline — no pre-existing assertion changed).

**Status:** Success

### [20260726 12:40] - Step 2: Remove Destructive Squash Rollback

**Action:** Replaced both unconditional `git reset --hard HEAD` calls in
`projex-squash-close.{sh,ps1}` with a checked `git reset --merge HEAD` behind `safe_rollback` /
`Invoke-SafeRollback`. On rollback failure the script exits `1` without escalating, and the message
names the approval-gated recovery (`git reset --hard HEAD` "a destructive command this script will
not run for you, so it needs your explicit approval") plus the fact that the next invocation will
refuse to start until the conflicted state is cleared. Exit-`2` covered-conflict path untouched (no
rollback occurs there). Error text changed from "reset to clean state" to "rolled back to a clean
pre-merge state".

**Result:** No `reset --hard` remains as an executed command in any of the six finalizers — only
inside guidance strings. Both suites still green (see Step 1 result). Per the plan's own framing,
this step adds no incremental data safety over Step 1; it is policy compliance.

Also aligned the two remaining generic squash failure messages: "reset to clean state on '<base>'"
→ "rolled back to a clean pre-merge state on '<base>'", so no message claims a reset that no longer
happens.

**Rollback-failure branch — reachability finding.** The plan required this branch to be exercised or
its unreachability recorded. Five constructions were probed against live git before concluding:

| Construction | Outcome |
|---|---|
| Unstaged edit to an auto-merged (staged) file after a conflicted squash | `reset --merge HEAD` **does** abort (`error: Entry 'o.txt' not uptodate`, exit 128) — but the state cannot be produced from outside, because nothing runs between the script's `merge --squash` and its rollback |
| `assume-unchanged` dirt hidden from the gate | `merge --squash` refuses pre-mutation (`local changes would be overwritten`); rollback is a clean no-op |
| `skip-worktree` dirt hidden from the gate | Same refusal; local content preserved; rollback a clean no-op |
| Dirty submodule + conflicting squash | Squash conflicts, `reset --merge HEAD` succeeds (exit 0) — git treats submodule dirt leniently |
| Custom merge driver simulating a concurrent writer | Git rewrites the worktree after drivers run, so the tamper is undone before rollback |

**Conclusion (CORRECTED — see below):** not constructible as a deterministic regression case;
reachable only through the documented gate→merge window. Step 1's tracked-clean gate plus the
pre-existing in-progress gate leave the tree tracked-clean when `merge --squash` runs, but nothing
re-checks between the gate and the merge. The branch is still shipped — a checked rollback is
strictly better than the previous `|| true` — and `dirty-base.test.*` exercises the reachable
neighbours instead: the conflicted-squash rollback, and the `skip-worktree` gate hole where the merge
refuses pre-mutation and hidden local content survives.

> **Correction (2026-07-26, via `2607261821-rollback-refusal-message-split-patch.md`).** The original
> conclusion here read *"unreachable through the scripts' own entry points"*, reasoning that a squash
> either conflicts or "refuses before mutating anything (rollback is a no-op)". The second disjunct is
> **false** and `2607261520-close-scripts-dirty-base-safety-audit.md` falsified it: refusal does not
> imply the rollback is a no-op. With a tracked file at `index != HEAD != worktree` — establishable in
> the gate→merge window this code's own comment documents — `merge --squash` refuses (exit ≠ 0, no
> `MERGE_HEAD`, zero unmerged paths) and `git reset --merge HEAD` then fails with exit 128. Row 1 of
> the table above found exactly this failure mode but dismissed it on the wrong test: the state does
> not need to arise *between* merge and rollback, only to exist *before* the merge. The
> `assume-unchanged` / `skip-worktree` rows probed only the `index == HEAD` variant and generalised.
> The conclusion (ship the checked rollback, no deterministic test possible) stands; the reasoning did
> not. `safe_rollback` / `Invoke-SafeRollback` now split their message on whether unmerged paths
> actually exist, because the refusal path must not recommend a hard reset.

**Status:** Success

### [20260726 13:25] - Step 3: Add Dirty-Base Regression Suite to `tests/`

**Action:** Added `tests/dirty-base.test.sh` and `tests/dirty-base.test.ps1` following the existing
conventions (`chk`/`Chk` only, throwaway repos under the system temp dir removed on success,
assertions against observable git state, trailing `PASS=<n> FAIL=<n>`). Registered both in
`tests/run-all.sh` / `tests/run-all.ps1`, added two coverage-table rows plus a note on the
non-deterministically-reachable rollback branch to `tests/README.md`, and updated the assertion count
in the repo instructions.

Matrix, identical on both platforms (139 assertions each):

1. Tracked dirt (unstaged + staged) × 3 close types → exit `1`, edit byte-intact, base ref unmoved,
   ephemeral ref unmoved, worktree still registered, no merge/rebase state started.
2. Dirty submodule only × 3 close types → invisible to the gate expression, close **succeeds**,
   submodule content preserved.
3. Unrelated untracked bystander × 3 close types → close succeeds, bystander byte-intact.
4. Colliding untracked path × 3 close types → exit `1`, no overwrite, base ref unmoved, and
   **ephemeral tip SHA unmoved**. Fixture mode 2 advances the base with an unrelated commit so the
   rebase genuinely replays — without that the rebase is a no-op and the case cannot reproduce the
   bug (found and fixed during the negative control below).
5. Conflicted squash → exit `1`, base `HEAD` unmoved, checkout clean, ephemeral + worktree survive,
   message reports a safe rollback and never mentions `reset --hard`.
6. `skip-worktree` gate hole → merge refuses pre-mutation, hidden local content survives.
7. Happy path × 3 close types → exit `0`, base updated, branch deleted, worktree unregistered.
8. Non-branch `Base` (tag, `origin/main`, raw SHA) × 3 close types → exit `1`, both refs unmoved.
9. Mismatched origin branch and detached origin × 3 close types → exit `1`, both refs unmoved,
   worktree kept.
10. Nested topology (primary → `projex/outer` utility worktree → `projex/inner` child): child closes
    into its recorded parent only, `main` untouched; and with the recorded parent worktree dirty, the
    gate fires against **that** worktree rather than the primary and never falls back to `main`.

**Result:**

- `tests/run-all.sh` → `=== total: PASS=255 FAIL=0` (116 pre-existing + 139 new).
- `pwsh tests/run-all.ps1` → `=== total: PASS=211 FAIL=0` (72 pre-existing + 139 new).
- No pre-existing assertion changed or regressed; totals are pure additions to the 116/72 baseline.
- **Negative control** — new suites run against the pre-change scripts extracted from `main`:
  `PASS=120 FAIL=19` on both platforms, identical failure sets. Notably it reproduces the two
  motivating bugs directly: `squash unstaged edit survives (want 'PRECIOUS' got 'v0')` (the memo's
  data loss) and `rebase collision ephemeral tip unmoved` (the redteam's E4 history rewrite).

**Status:** Success

### [20260726 13:50] - Step 4: Align Close Workflow Contract

**Action:** Rewrote `close-projex.md` § 7 FINALIZE GIT BRANCH's gate section and added a note to § 8.

- Replaced the blanket `git status --porcelain` "commit or discard" instruction with a two-row table
  naming both gates and why they differ: originating/base worktree → tracked-clean
  (`--untracked-files=no --ignore-submodules=dirty`, untracked/ignored allowed, submodule dirt does
  not count); child execution worktree → fully clean, because it is about to be deleted.
- Added an explicit **"These are pre-flight checks, not enforcement"** paragraph: the finalizers apply
  both gates independently, but nothing re-checks between gate and mutation, so a concurrent writer
  can still dirty the tree; git's own overwrite refusal is the real backstop. The word "enforce" is
  used only to deny it.
- Documented the required `<repo-root>` ↔ `{base-branch}` pairing: `<repo-root>` is the recorded
  originating worktree (not necessarily the primary checkout), finalizers assert it still has
  `{base-branch}` checked out and exit `1` rather than guessing or falling back to `main`/`master`.
  Worked the stacked case in explicitly (a child of `projex/outer` closes into `projex/outer`).
- Documented that `{base-branch}` must be a local branch — not a tag, raw SHA, or remote-tracking
  ref — and that the error names what the value resolved to.
- Documented rebase-close's extra pre-rebase untracked-collision refusal, including *why* only rebase
  needs it (it rewrites history before reaching the fast-forward).
- Replaced "The main working directory is already on the base branch" with "The originating/base
  worktree …".
- § 8: stated that stashing is caller-owned and the scripts never stash or pop on the caller's behalf,
  so a stash must be recorded in the execution log.

Sequencing honoured: this step landed after Step 1's rebase pre-check, per the plan's load-bearing
sequencing note — the doc now permits untracked content at the base worktree only because the
collision path it used to prevent incidentally is now refused by the script itself.

**Result:** Repository-wide search for `reset --hard` finds no claim that the close scripts perform
one automatically — remaining hits are the project rule in `AGENTS.md`, `debug-projex.md`'s own
per-attempt worktree rollback (different workflow, out of scope), the plan/redteam documents, and
approval-gated guidance strings inside `projex-squash-close.*`. Search for "enforce" in
`close-projex.md` returns only the sentence that denies enforcement.

**Status:** Success

---

## Deviations

1. **`CLAUDE.md` → `AGENTS.md`.** Plan Key Files names `CLAUDE.md` as the repo-instructions file whose
   assertion count must be updated. In this repo `CLAUDE.md` is **gitignored** (`.gitignore:2`) and
   exists only in the main checkout; the tracked instructions file is `AGENTS.md`. Applied the scoped
   fix to `AGENTS.md` instead — it had no `tests/` content at all ("No build system, no tests, no
   runtime code"), so the edit adds the `tests/` structure entry, the run-both-platforms instruction,
   and the count (466 = 255 `.sh` + 211 `.ps1`). Estimated Changes stays at 13 files; only the
   identity of the 13th changed. **Handoff:** the main checkout's gitignored `CLAUDE.md` carries the
   stale `188 assertions` figure and cannot be reached from the worktree — it is user-owned untracked
   content and was deliberately not touched.
2. **Steps 1 and 2 committed together** (`9ce9628`). Both rewrite overlapping regions of
   `projex-squash-close.{sh,ps1}`; splitting would have produced an intermediate commit whose squash
   rollback path was half-migrated. Separate log entries retained.
3. **Two extra squash messages updated beyond the literal Step 2 change list.** The generic
   `merge --squash failed — reset to clean state on '<base>'` strings were left behind by the plan's
   text but assert a reset that no longer happens; reworded for accuracy. Within Step 4's mandate to
   remove claims that cleanup uses `reset --hard`.
4. **Collision-test fixture strengthened mid-step.** The first version of the rebase collision case
   did not advance the base, so the rebase was a no-op and the case passed against the *pre-change*
   script. Added fixture mode 2 (unrelated advance) so it genuinely reproduces the redteam's E4.
   Caught by the negative control, not by the suite itself — worth noting as the reason the negative
   control is part of this plan's verification rather than an optional extra.
5. **No task-tool task list.** Step 2 of the workflow requires translating the plan into a todo/task
   list "if your environment provides todo/task tool". This execution environment exposes none, so
   the plan's four steps were tracked through the log's per-step entries and commits instead.

## Issues Encountered

- **`reset --merge` rollback-failure branch not deterministically testable** — see the Step 2 entry
  for the five constructions probed and the conclusion, plus the correction note: the branch is
  reachable through the gate→merge window, just not pre-seedable by a test. Resolved under the
  criterion's own escape clause; branch shipped, finding recorded in three places.
- **`AGENTS.md` is broadly stale beyond this plan's scope** — it still lists 19 workflow types with
  outdated lifecycles, omits `projex-rebase-close`, and describes lifecycles the framework has since
  revised. Only the tests-contract statements were corrected; a full re-sync against `CLAUDE.md` is a
  separate concern and was deliberately not attempted here.
- **`SKILL.md` § Branch Finalization** still says "The main working directory must already be on the
  base branch (which it is — worktree mode never leaves it)". Now imprecise — it is the *originating*
  worktree, and the scripts assert it rather than assuming it. Left untouched: Step 4's Files list is
  `close-projex.md` only, and the plan's stated doc-verification bar (no automatic-hard-reset claim,
  no "enforce" claim) is satisfied without it. Flagged for a follow-up revise.

## Criteria Validation

| # | Criterion | Evidence |
|---|---|---|
| 1 | Origin/base pairing verified; arbitrary parent topology preserved | `dirty-base.test.*` mismatched-origin (3 types), detached-origin (3 types), nested `projex/outer` → `projex/inner` close into recorded parent with `main` untouched, plus dirty-parent-worktree case |
| 2 | Non-branch `Base` exits `1` naming the ref type | tag / `origin/main` / raw SHA × 3 types × 2 shells; both refs asserted unmoved |
| 3 | All six exit `1` pre-mutation on tracked dirt, submodule noise excluded | unstaged + staged × 3 types × 2 shells (42 assertions each shell); submodule-dirty cases assert the gate expression is empty *and* close succeeds |
| 4 | Untracked/ignored allowed and byte-intact; collision fails pre-mutation with no ephemeral rewrite | bystander cases (exit `0`, bytes intact) and collision cases (exit `1`, no overwrite, base ref unmoved, **ephemeral tip unmoved**) × 3 types × 2 shells |
| 5 | `rebase-close` detects the collision before rebasing | collision case reproduces E4 against pre-change scripts (`rebase collision ephemeral tip unmoved` fails there, passes here) on both shells |
| 6 | Dirty execution worktree still separately rejected | pre-existing `worktree.test.sh` / `.ps1` dirty-worktree assertions unchanged and green |
| 7 | No automatic `reset --hard` in squash cleanup; `reset --merge HEAD` restores clean state | grep over the six finalizers finds only comments and approval-gated guidance; conflicted-squash case asserts clean checkout, base `HEAD` unmoved, surviving branch, and that the output never mentions a hard reset |
| 8 | Rollback-failure branch exercised | **Escape clause used** — see Deviations / Step 2 and its correction note. Not constructible as a deterministic regression case (reachable only via the gate→merge window); recorded, not silently skipped |
| 9 | Existing exit-code contract retained | 116 `.sh` + 72 `.ps1` pre-existing assertions unchanged and green; happy-path cases assert exit `0`, base updated, branch deleted, worktree unregistered |
| 10 | Dirty-base cases live in `tests/`, run from both runners | registered in `run-all.sh` / `run-all.ps1`; both report the new suite in their totals |
| 11 | Existing suite still passes on both platforms | `tests/run-all.sh` → `PASS=255 FAIL=0`; `pwsh tests/run-all.ps1` → `PASS=211 FAIL=0`; deltas are exactly +139 each against the 116/72 baseline |
| 12 | Docs distinguish the two gates, describe them as pre-flight | `close-projex.md` § 7 gate table + "These are pre-flight checks, not enforcement" paragraph |

### Manual Verification

- Gate precedes every mutation in all six scripts — for rebase it precedes the *rebase*, not only the
  fast-forward (source read back after edit; collision test proves it observationally).
- Ignored execution-worktree content remains warning-only — that code path was not touched.
- No test or script stashes, deletes, or overwrites pre-existing integration-worktree content; every
  refusal case asserts the planted file byte-for-byte.
- Utility/nested cases integrate into the immediate recorded parent, never `main` (asserted directly).
- Every exit-`1` path asserted to leave base ref and ephemeral ref unmoved. The one exit-`1` that can
  still follow a durable change — rebase's post-rewrite fast-forward failure — keeps its message
  stating `'<ephemeral>' is rebased`.
- Implementation diff contains only plan-scoped paths; the main checkout's unrelated dirt (including
  its own uncommitted `close-projex.md`) was never read or touched, per worktree isolation.

## Cleanup

Nothing to tear down: no deps installed, no servers or containers started, no scratch files left in
the worktree. Every test suite builds and removes its own throwaway repositories under the system
temp dir; the two negative-control trees were removed in the same commands that created them.
`git status --porcelain --ignored=matching` in the worktree shows only the plan-scoped edits about to
be committed.

## User Interventions

None.

