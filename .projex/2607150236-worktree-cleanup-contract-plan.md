# Worktree Cleanup Contract + Close-Script Removal Diagnosis

> **Status:** In Progress
> **Created:** 2026-07-15
> **Author:** agent (Claude)
> **Source:** Direct request — incident: squash-close worktree removal failed on leftover gitignored `node_modules/`, `--force` retry hit "not a working tree"
> **Related Projex:** 2606270200-squash-close-worktree-remove-windows-memo.md | 2607132112-projex-rebase-close-scripts-redteam.md (Finding 2: auto `--force` deletes untracked files) | 2607090215-util-script-output-hints-next-step-proposal.md (executed — hint line pattern this plan extends) | 2607140251-close-scripts-per-branch-lock-plan.md (pending — touches same script regions, see Constraints) | 2607150312-worktree-cleanup-contract-plan-redteam.md (Fix Issues — this plan's Revision Log resolves its 5 findings)
> **Worktree:** Yes

---

## Summary

Agents leave untracked/ignored tooling (symlinked `node_modules`, build output, scratch) in worktrees; at close, `git worktree remove` half-fails, the scripts' blind `--force` retry is either useless (worktree already unregistered → "not a working tree") or destructive (deletes untracked files — redteam-verified data loss). Fix on two fronts: specs establish a **cleanup contract** (worktree returned with only tracked content) + close scripts **stop auto-forcing** and instead diagnose (pre-flight cleanliness gate before merge — rejects any non-clean worktree, tracked edits or untracked files; accurate registered-vs-unregistered message on removal failure).

**Scope:** Framework specs (SKILL.md, execute-projex.md, close-projex.md) + 10 scripts (squash/merge/rebase-close, abandon, projex-worktree × sh/ps1). Root `.projex/` scope only.
**Estimated Changes:** 13 files — 3 spec edits, 8 close/abandon script edits, 2 worktree-script hint lines.

---

## Objective

### Problem / Gap / Need

- No spec anywhere tells agents that untracked/ignored content they create in a worktree must be removed before close → leftovers guaranteed at finalization
- Merge-type close scripts (squash sh:93-100/ps1:93-102, merge sh:82-89/ps1:81-90, rebase sh:110-117/ps1:114-123): on remove failure, retry `worktree remove --force` blindly. Two failure modes, both mishandled:
  - First remove half-succeeded (ignored content doesn't block non-force remove; deletion choked mid-way, admin entry already gone) → `--force` retry: "fatal: not a working tree", misleading noise
  - First remove refused (untracked files present) → `--force` retry silently **deletes untracked files** — unrecoverable (redteam 2607132112 Finding 2, tested)
- `projex-abandon` goes straight to `--force` (sh:55/ps1:44) — correct for abandon semantics, but destroys untracked scratch without naming it
- close-projex.md:423 stale: claims "The script removes the worktree **before** merging/abandoning" — squash/merge/rebase all merge first, remove after (memo 2606270200's suggested fix was applied to scripts, doc never updated)
- No recovery guidance for the "could not remove worktree" warning — agents don't know the leftover is a plain unregistered directory, safe to inspect + delete

### Success Criteria

- [ ] No merge-type close script auto-invokes `worktree remove --force` under any path
- [ ] Worktree close with any non-clean state (untracked file **or** uncommitted tracked edit): exits 1 **before** any base-branch mutation, lists blocking entries, instructs — verified in scratch repo (sh + ps1)
- [ ] Clean-worktree close: succeeds end-to-end, worktree removed, branch deleted — behavior unchanged (sh + ps1)
- [ ] Removal failure with already-unregistered worktree: prints "unregistered; plain directory remains at {path} — delete manually, then git worktree prune" (no `--force` attempt) — verified via simulated breakage
- [ ] Removal failure with still-registered worktree: prints blocking content (`status --porcelain --ignored=matching`, first 10 lines, SIGPIPE-guarded) + resolve instructions — since the unified gate catches dirty content pre-flight, this branch fires only on a lock/open handle, so the content list is empty and the retry line names that case
- [ ] Cleanup contract stated in SKILL.md § Worktree Mode and execute-projex.md (worktree init + cleanup step); close-projex.md has pre-finalization hygiene check, corrected removal-ordering sentence, and leftover-recovery guidance
- [ ] `projex-worktree.{sh,ps1}` print cleanup-contract hint line
- [ ] `.sh` ↔ `.ps1` behavioral parity for every touched script

### Out of Scope

- Redteam Finding 1 (worktree-mode ff onto wrong branch — no base-HEAD verification) — separate remediation
- 2607140251 per-branch-lock changes — separate pending plan
- Auto-deleting leftover directories on the agent's behalf — deliberately manual
- debug-projex.md / simulate-projex.md spec edits — SKILL.md contract covers all worktree users; per-spec restatement deferred
- `projex-worktree` "use this path" hint — already shipped (sh:62/ps1:66)

---

## Context

### Current State

Removal block identical across the three merge-type pairs (squash sh shown; others differ only in line numbers):

```bash
if [ "$WORKTREE_MODE" = true ]; then
  if ! git -C "$REPO_ROOT" worktree remove "$WT_PATH" 2>&1; then
    echo "Warning: normal worktree remove failed, retrying with --force..." >&2
    if ! git -C "$REPO_ROOT" worktree remove --force "$WT_PATH" 2>&1; then
      echo "Warning: could not remove worktree '$WT_PATH' — close succeeded; clean up manually, then run: git worktree prune" >&2
    fi
  fi
fi
```

`git worktree prune` follows in all (squash sh:102/ps1:104, merge sh:91/ps1:92, rebase sh:119/ps1:125) — keep unchanged.

### Key Files

| File | Role | Change Summary |
|------|------|----------------|
| `SKILL.md` | Framework spec § Worktree Mode | +1 cleanup-contract bullet |
| `execute-projex.md` | Execution workflow | Contract sentence at worktree init (ln 97) + cleanup step 7.5 (ln 214) |
| `close-projex.md` | Close workflow | Hygiene gate (ln 413-419), fix stale ln 423, recovery note (~ln 470) |
| `projex-squash-close.{sh,ps1}` | Finalization | Pre-flight gate + removal diagnosis |
| `projex-merge-close.{sh,ps1}` | Finalization | Same |
| `projex-rebase-close.{sh,ps1}` | Finalization | Same |
| `projex-abandon.{sh,ps1}` | Finalization | Untracked-discard notice + failure diagnosis |
| `projex-worktree.{sh,ps1}` | Creation | +1 hint line |

### Dependencies

- **Requires:** nothing pending
- **Blocks:** nothing declared

### Constraints

- 2607140251-close-scripts-per-branch-lock-plan.md (Draft) edits the same finalization scripts and pins anchors by line number — whichever plan executes second needs a `/revise-projex` pass on the other's anchors. Do not execute both concurrently.
- Framework rule: leftover deletion stays manual — scripts/specs may instruct, never `rm -rf` on the agent's behalf.
- `.sh`/`.ps1` parity is a repo invariant.

### Assumptions

- Installed skill copy (`~/.claude/skills/projex/`) mirrors repo SKILL.md — verify § Worktree Mode anchor text against repo file before editing (verified at draft time via grep, re-verify at execution)
- `git status --porcelain --ignored=matching` available (git ≥ 2.16) — worktree hosts all run modern git
- `git worktree list --porcelain` prints `worktree {abs-path}` lines with forward slashes on all platforms → registration check matches on `/.projexwt/{suffix}` end-of-line, not full path equality (avoids Windows backslash/drive-case mismatch)

### Impact Analysis

- **Direct:** 13 files above
- **Adjacent:** debug-projex.md / simulate-projex.md close via same scripts — they gain the gate behavior automatically; debug's dep-install habit (lockfile tracked, `node_modules` ignored) now warned pre-merge instead of failing post-commit
- **Downstream:** orchestrate-projex subagents closing worktrees get exit-1 + instructions instead of half-failed cleanup; any external repo using projex worktree mode sees new pre-flight failure on dirty-worktree close (intended breaking behavior — surfaces silent data-loss path)

---

## Implementation

### Step 1: Cleanup contract in SKILL.md + execute-projex.md

**Objective:** Establish the contract where agents read it: worktree comes back holding only tracked content.
**Confidence:** High
**Depends on:** None

**Files:** `SKILL.md`, `execute-projex.md`

**Changes:**

SKILL.md § Worktree Mode, "How it works" list — append bullet after "No stashing needed — the base branch working directory is never touched" (ln 273):

```markdown
- **Cleanup contract:** anything created in the worktree that git does not track — symlinked/installed deps (`node_modules`), build output, scratch files — must be removed before close, and any tracked edits committed. Close scripts refuse to finalize over a non-clean worktree (untracked files or uncommitted tracked changes). Ignored content (deps/build output) does **not** block git-level removal, but can make removal fail mid-way in environment-dependent ways (seen with symlinked deps in a Linux docker sandbox, and with file locks/CWD-in-worktree on Windows) and leave a stray directory to clean up — so remove agent-created ignored tooling too.
```

execute-projex.md ln 97 — after "The main directory stays on the base branch." append:

```markdown
Anything you create in the worktree that git does not track (deps, build output, scratch) must be removed before close — see SKILL.md § Worktree Mode cleanup contract.
```

execute-projex.md step 7.5 (ln 214) — after "Leave pre-existing resources alone." insert:

```markdown
In worktree mode, commit or remove everything you added inside the worktree before close: close scripts refuse finalization over any non-clean state (untracked files or uncommitted tracked edits). Ignored tooling (symlinked `node_modules`, installed deps, build artifacts) is not gated but can make worktree removal fail mid-way — remove it too.
```

**Rationale:** Prevention beats handling; SKILL.md covers every worktree consumer (execute, debug, simulate, orchestrate) in one place.

**Verification:** Grep both files for "cleanup contract" / "untracked"; re-read sections for coherent flow.

**If this fails:** Revert the two files (`git checkout -- SKILL.md execute-projex.md` on the ephemeral branch).

---

### Step 2: close-projex.md — hygiene gate, stale fix, recovery guidance

**Objective:** Close workflow checks the worktree before finalization, describes script behavior accurately, and tells agents how to recover from a failed removal.
**Confidence:** High
**Depends on:** None

**Files:** `close-projex.md`

**Changes:**

1. Step 7 GATE (ln 413-419) — after the existing `git -C <repo-root> status --porcelain` block, add worktree-mode check:

```markdown
**Worktree mode — also check the worktree for leftovers:**

​```bash
git -C <worktree-path> status --porcelain --ignored=matching
​```

Untracked (`??`) or modified/staged tracked (`M`/`A`) entries: commit them or remove agent-created tooling — the finalization scripts exit (before any merge) rather than merge from a stale commit or risk deleting untracked files. Ignored (`!!`) entries (deps, build output): remove agent-created ones now; they don't block git-level removal but can make it fail half-way on some filesystems.
```

2. Ln 423 stale sentence — replace:

```markdown
// Before:
The script removes the worktree before merging/abandoning. The main working directory is already on the base branch — no checkout needed.

// After:
The script merges first, then removes the worktree as best-effort cleanup (abandon removes it directly). A removal failure never undoes the close — the script reports what remains. The main working directory is already on the base branch — no checkout needed.
```

3. After the rebase-conflict note (~ln 470), add recovery note:

```markdown
> **If a script warns it could not remove the worktree:** the close itself succeeded. Run `git -C <repo-root> worktree list` — if the worktree path is no longer listed, only a plain untracked directory remains; inspect it for anything user-created, then delete it manually (`rm -rf` / `Remove-Item -Recurse -Force`) and run `git worktree prune`. If it is still listed, remove the blocking files it reported, then `git -C <repo-root> worktree remove <path>`.
```

**Rationale:** Gate catches leftovers while nothing is committed; accurate ordering claim stops agents reasoning from a false model; recovery note turns the incident's dead-end warning into a two-branch procedure.

**Verification:** Re-read step 7 end-to-end; confirm gate precedes all finalization options and recovery note names both registered/unregistered branches.

**If this fails:** `git checkout -- close-projex.md` on the ephemeral branch.

---

### Step 3: Merge-type close scripts — pre-flight gate + removal diagnosis

**Objective:** Squash/merge/rebase-close (6 files): refuse pre-merge on any non-clean worktree (untracked **or** uncommitted tracked changes); on removal failure, diagnose instead of blind `--force`. One identical gate block across all three closes Finding 1 (untracked-only gate let modified tracked files slip → squash merged from the stale commit).
**Confidence:** High (anchors verified: `WT_PATH`/`$WtPath` computed before first merge/rebase in all six — squash/merge sh:55, rebase sh:58, ps1:42/45). Rebase's pre-existing tracked-only clean-check (sh:64-67 / ps1 analog) is **replaced** by the unified gate below — it caught tracked edits but not untracked, so the unified block is strictly broader and unifies all three scripts.
**Depends on:** None (semantics defined here; Step 1/2 reference it)

**Files:** `projex-squash-close.sh|.ps1`, `projex-merge-close.sh|.ps1`, `projex-rebase-close.sh|.ps1`

**Changes:**

**(a) Pre-flight gate** — worktree mode only, one identical block per script, inserted before the first merge/rebase operation. Placement: squash/merge sh — after `WT_PATH` (sh:55), before `merge` (sh:70), where no clean-check currently exists; rebase sh — **replacing** the existing tracked-only clean-check (sh:64-67), before `rebase` (sh:68); ps1 analogous after the `$WtPath` blocks (ln 42/45). The gate keys off `git status --porcelain` (no `--ignored`), which reports untracked **and** modified/staged tracked entries but not ignored — so a single check covers the whole non-clean surface:

```bash
if [ "$WORKTREE_MODE" = true ]; then
  DIRTY=$(git -C "$WT_PATH" status --porcelain 2>/dev/null || true)
  if [ -n "$DIRTY" ]; then
    echo "Error: worktree '$WT_PATH' is not clean — commit tracked edits, and commit or remove untracked tooling, then re-run:" >&2
    echo "$DIRTY" | head -n 10 >&2
    exit 1
  fi
  IGNORED=$(git -C "$WT_PATH" status --porcelain --ignored=matching 2>/dev/null | grep '^!!' || true)
  if [ -n "$IGNORED" ]; then
    echo "Warning: worktree contains ignored content (deps/build output) — removal may leave a directory to clean manually:" >&2
    echo "$IGNORED" | head -n 5 >&2
  fi
fi
```

Exit 1 fires before any base mutation → re-run after cleanup is free. `echo "$DIRTY" | head` is a builtin single-write pipe (SIGPIPE-safe); the `IGNORED` grep consumes its whole stream (no early close). Ignored content warns only (doesn't block non-force removal by itself).

**(b) Removal diagnosis** — replace the remove/`--force`-retry block in each file:

```bash
// Before (sh form):
if [ "$WORKTREE_MODE" = true ]; then
  if ! git -C "$REPO_ROOT" worktree remove "$WT_PATH" 2>&1; then
    echo "Warning: normal worktree remove failed, retrying with --force..." >&2
    if ! git -C "$REPO_ROOT" worktree remove --force "$WT_PATH" 2>&1; then
      echo "Warning: could not remove worktree '$WT_PATH' — close succeeded; clean up manually, then run: git worktree prune" >&2
    fi
  fi
fi

// After (sh form):
if [ "$WORKTREE_MODE" = true ]; then
  if ! git -C "$REPO_ROOT" worktree remove "$WT_PATH" 2>&1; then
    WT_SUFFIX="${EPHEMERAL##*/}"
    if git -C "$REPO_ROOT" worktree list --porcelain | grep -q "/\.projexwt/${WT_SUFFIX}\$"; then
      echo "Warning: could not remove worktree '$WT_PATH' — close succeeded. Blocking content:" >&2
      { git -C "$WT_PATH" status --porcelain --ignored=matching 2>/dev/null || true; } | head -n 10 >&2
      echo "Remove the files above (or release any lock/open handle on the worktree — an empty list above means the block is a lock, not dirty content), then: git -C $REPO_ROOT worktree remove $WT_PATH" >&2
    else
      echo "Warning: worktree unregistered but directory remains at '$WT_PATH' — close succeeded; inspect and delete the plain directory manually, then run: git -C $REPO_ROOT worktree prune" >&2
    fi
  fi
fi
```

No `--force` anywhere. **Finding 4 (SIGPIPE):** the blocking-content read is wrapped `{ git … || true; } | head` so a truncated read (`head` closes after 10 lines, git's next write takes SIGPIPE) can't abort the script tail under `set -euo pipefail` and skip the trailing `prune` / `branch -d`. ps1 has no `pipefail` and never aborts here → wrapping keeps the two families' outcomes identical. Existing `git worktree prune` line after the block stays. `.ps1` mirrors: registration check via `git -C $RepoRoot worktree list --porcelain | Where-Object { $_ -match ('/\.projexwt/' + [regex]::Escape($WtSuffix) + '$') }` (suffix match — git prints forward-slash paths, `$WtPath` is backslashed via Join-Path; never compare full paths).

**Rationale:** The two failure modes need opposite handling; blind `--force` picks wrong in both (redteam-verified data loss / incident-verified dead fatal). Registered → blocking content is real, agent must decide; unregistered → git is done, only a dead directory remains. With the unified pre-flight gate (a), dirty content is caught before merge, so the registered removal-failure branch now fires only on a lock or open file handle — its `status` listing is empty in that case, which the retry line calls out. (The triggering incident — Linux docker sandbox, symlinked `node_modules` — hit the *unregistered* branch, not this one: removal half-succeeded, choking mid-delete after the admin entry was gone.)

**Verification:** Per file: shellcheck / `pwsh -NoProfile` parse check; scratch-repo behavior tests deferred to Step 6.

**If this fails:** Per-file revert on the ephemeral branch; scripts are independent of Steps 1-2.

---

### Step 4: projex-abandon — name what gets destroyed + failure diagnosis

**Objective:** Abandon keeps `--force`-first (discard is its contract) but lists untracked files it is about to destroy and diagnoses failure like Step 3(b).
**Confidence:** High
**Depends on:** Step 3 (reuses diagnosis block shape)

**Files:** `projex-abandon.sh` (ln 52-57), `projex-abandon.ps1` (ln 39-47)

**Changes (sh form; ps1 mirrors):**

```bash
// Before:
if [ "$WORKTREE_MODE" = true ]; then
  # Worktree mode: remove worktree (already on base branch)
  WT_PATH="${REPO_ROOT%/}/.projexwt/${EPHEMERAL##*/}"
  if ! git -C "$REPO_ROOT" worktree remove "$WT_PATH" --force 2>&1; then
    echo "Warning: could not remove worktree '$WT_PATH' — remove manually: git worktree remove $WT_PATH --force"
  fi
fi

// After:
if [ "$WORKTREE_MODE" = true ]; then
  # Worktree mode: remove worktree (already on base branch)
  WT_PATH="${REPO_ROOT%/}/.projexwt/${EPHEMERAL##*/}"
  UNTRACKED=$(git -C "$WT_PATH" status --porcelain 2>/dev/null | grep '^??' || true)
  if [ -n "$UNTRACKED" ]; then
    echo "Note: discarding untracked files with the worktree:" >&2
    echo "$UNTRACKED" | head -n 10 >&2
  fi
  if ! git -C "$REPO_ROOT" worktree remove "$WT_PATH" --force 2>&1; then
    if git -C "$REPO_ROOT" worktree list --porcelain | grep -q "/\.projexwt/${EPHEMERAL##*/}\$"; then
      echo "Warning: could not remove worktree '$WT_PATH' — remove manually: git worktree remove $WT_PATH --force" >&2
    else
      echo "Warning: worktree unregistered but directory remains at '$WT_PATH' — inspect and delete the plain directory manually, then run: git worktree prune" >&2
    fi
  fi
fi
```

**Rationale:** Abandon's destruction is intentional but shouldn't be silent; the incident's "not a working tree" dead-end applies to abandon's manual-retry advice too.

**Verification:** Parse checks; behavior in Step 6.

**If this fails:** Revert the pair; independent of other steps.

---

### Step 5: projex-worktree — creation-side cleanup hint

**Objective:** Contract stated at the moment the worktree is handed to the agent.
**Confidence:** High
**Depends on:** None

**Files:** `projex-worktree.sh` (after ln 62), `projex-worktree.ps1` (after ln 66)

**Changes:** Append one output line to each:

```bash
echo "# cleanup: anything created here that git does not track (deps, build output, scratch) must be removed before close — untracked leftovers block worktree removal."
```

(ps1: same text via `Write-Host`.)

**Rationale:** Matches the shipped `# next:` hint pattern (2607090215) — contract rides the tool output agents actually read.

**Verification:** Run script against scratch repo, confirm both hint lines print.

**If this fails:** Revert the pair.

---

### Step 6: Scratch-repo verification battery

**Objective:** Prove all behavior claims from Success Criteria on both script families.
**Confidence:** High
**Depends on:** Steps 3-5

**Files:** none (throwaway scratch repos under scratchpad dir; nothing committed)

**Changes:** none — test execution only. Matrix, run for sh (Git Bash) and ps1:

| # | Setup | Script | Expect |
|---|-------|--------|--------|
| 1 | worktree, clean, 1 commit | squash-close --worktree | exit 0, merged, worktree gone, branch deleted |
| 2 | worktree + untracked file | squash-close --worktree | exit 1 pre-merge, file listed, base HEAD unchanged, worktree intact |
| 3 | worktree + uncommitted tracked edit (modified tracked file, no untracked) | squash-close --worktree | exit 1 pre-merge, file listed, base HEAD unchanged, worktree intact (**Finding 1** — unified gate; untracked-only would have let this through) |
| 4 | worktree + ignored file (`.gitignore`d) | squash-close --worktree | warning printed, gate passes, close succeeds, removal outcome reported honestly |
| 5 | worktree, then `rm -rf .git/worktrees/<name>` (simulate half-removal) | squash-close --worktree | close succeeds, "unregistered … plain directory remains … git worktree prune" message, no `--force`, no fatal |
| 6 | worktree, clean, then `git worktree lock <path>` (simulate a removal-blocking lock/handle) | squash-close --worktree | close succeeds; **still-registered** diagnosis "could not remove … Blocking content:" prints (list empty under a lock trigger — dirty content is caught pre-flight), retry line printed; **no** `--force`, **no** fatal/exit 141; branch-delete emits its non-fatal "could not delete" warning (branch still checked out in the lingering worktree); script exits 0. Cleanup: `git worktree unlock <path>` then remove. (**Finding 2** — exercises the registered branch; also confirms the **Finding 4** SIGPIPE guard leaves the tail — prune/branch-delete — reachable) |
| 7 | same as 2 or 3 (any non-clean) | rebase-close / merge-close --worktree | exit 1 pre-mutation (spot-check one non-clean scenario per script) |
| 8 | worktree + untracked file | abandon --worktree | "discarding untracked files" note, removal succeeds |
| 9 | fresh create | projex-worktree | `# cleanup:` hint line present |

**Verification:** Each row's expectation observed verbatim; capture outputs in execution log.

**If this fails:** Failing row → fix the owning step's script on the ephemeral branch, re-run the full matrix.

---

## Verification Plan

### Automated Checks
- [ ] `bash -n` (+ `shellcheck` if available) on all 5 touched `.sh`
- [ ] `pwsh -NoProfile` parse check on all 5 touched `.ps1`
- [ ] Step 6 matrix — all rows pass, both families

### Manual Verification
- [ ] Grep confirms zero `worktree remove --force` occurrences in squash/merge/rebase-close (abandon keeps its intentional one)
- [ ] Re-read SKILL.md / execute-projex.md / close-projex.md edited sections in context
- [ ] `.sh` ↔ `.ps1` diff review per pair for behavior parity

### Acceptance Criteria Validation

| Criterion | How to Verify | Expected Result |
|-----------|---------------|-----------------|
| No auto `--force` in merge-type closes | grep + matrix rows 2-6 | zero matches; no force ever runs |
| Non-clean gate pre-merge (untracked or tracked-dirty) | matrix rows 2, 3, 7 | exit 1, base HEAD unchanged |
| Registered removal diagnosis | matrix row 6 | still-registered message, no force, no fatal/141, branch-delete warns, exit 0 |
| Unregistered diagnosis | matrix row 5 | correct message (+ prune hint), no fatal |
| Specs carry contract + recovery | grep + section re-read | all anchors present |
| Creation hint | matrix row 9 | hint line printed |

---

## Rollback Plan

Per-step rollback noted above. Full abandon:

1. `projex-abandon.{sh|ps1} <repo-root> main projex/2607150236-worktree-cleanup-contract --worktree`
2. Plan doc stays on base (committed pre-execution) — mark Status back to Draft with a note

---

## Revision Log

- **2026-07-15:** Folded in 5 findings from red team `2607150312-worktree-cleanup-contract-plan-redteam.md` (Verdict: Fix Issues). Core approach unchanged — Status stays Ready.
  - **Finding 1 (gate too narrow):** Step 3(a) pre-flight gate now rejects **any** non-clean worktree via `git status --porcelain` (untracked + uncommitted tracked) instead of `^??`-only; rebase's pre-existing tracked-only clean-check (sh:64-67) is **replaced** by the same block so all three merge-type scripts share one guard. Propagated to Summary, Success Criteria, close-projex.md hygiene-gate wording (Step 2), matrix (new row 3), acceptance table.
  - **Finding 2 (untested branch):** added matrix row 6 — clean worktree + `git worktree lock` reaches the "still-registered" removal-diagnosis branch (verified in scratch repo: lock ⇒ non-force remove refused `exit 128`, worktree stays registered, branch-delete warns). Added a registered-diagnosis acceptance-criteria row.
  - **Finding 3 (contract overclaims):** Step 1 SKILL.md bullet + execute-projex.md sentence reworded — "refuse" scopes to non-clean (untracked/tracked); ignored content does **not** block git-level removal, it warns and may leave a stray directory. *(This entry originally misattributed the incident to a Windows FS-choke — corrected in the next entry.)*
  - **Finding 4 (SIGPIPE):** Step 3(b) `git status … | head` wrapped `{ …; } | head` so a truncated read can't abort the script tail (prune/branch-delete) under `set -euo pipefail`; ps1 unaffected → parity preserved.
  - **Finding 5 (inverted risk note):** corrected the false-negative analysis (a grep miss lands in the **unregistered/else** branch, not "still registered"); added `git worktree prune` to the unregistered messages (Step 3(b), Step 4) for self-heal.
- **2026-07-15:** Corrected incident-environment attribution — trigger: user correction. The triggering incident ran in a **Linux docker sandbox** (`/workspace`, symlinked `node_modules`), not Windows; only the earlier memo 2606270200 was Windows. Half-removal failure is environment-dependent, not OS-specific — and the incident hit the **unregistered** diagnosis branch (removal half-succeeded), not the still-registered one. Reworded: Step 1 SKILL.md bullet example, Step 3(b) rationale, prior Finding-3 entry parenthetical. No behavioral change to any proposed script block; matrix unchanged (row 4 already models the incident's half-removal via admin-entry deletion, which is OS-neutral).

## Notes

### Risks
- **Anchor drift vs 2607140251 (per-branch-lock plan):** both plans edit the same finalization-script regions with line-pinned anchors. Mitigation: execute sequentially; second plan gets `/revise-projex` for anchors before execution.
- **Behavior break for external repos:** dirty-worktree closes that previously "succeeded" (with silent untracked deletion or half-cleanup) now exit 1. Intended — converts silent data loss into an actionable stop. Called out in close-projex.md gate text.
- **Registration-check false negative** (suffix regex misses due to unexpected path shape): a `grep -q` miss returns non-zero → the **else / unregistered** branch runs (not the "still registered" one) → it advises "inspect and delete the plain directory manually" for a worktree git still tracks. Non-destructive, but the advice is slightly off; the `git worktree prune` now appended to that message self-heals the stale admin entry after manual deletion. Trigger is improbable — `git worktree list --porcelain` prints forward-slash paths (tested), so the suffix regex matches. (Corrects the earlier note, which had this inverted — claimed the miss lands in the "still registered" branch.)
- **Still-registered diagnosis is lock/FS-only after the unified gate:** with pre-flight (a) catching all dirty content (untracked + tracked), the removal-failure "still registered" branch fires only on a lock or open file handle. Its `status --ignored=matching` listing is then empty; the retry line names that case. A dedicated empty-status fallback message is left out of this plan (out of scope — tracked as a follow-up).

### Open Questions
- (none)
