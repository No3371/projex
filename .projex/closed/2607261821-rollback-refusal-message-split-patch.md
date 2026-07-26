# Patch: Split `safe_rollback` Message on Refusal vs Conflict

> **Status:** Complete
> **Date:** 2026-07-26
> **Author:** patch-projex (subagent, opus)
> **Directive:** Address audit conditions C1–C4 from `2607261520-close-scripts-dirty-base-safety-audit.md` — correct the false rollback-failure message, the falsified "unreachable" wording, the log's four/five inconsistency, and `SKILL.md` § Branch Finalization.
> **Source Plan:** `2607261121-close-scripts-dirty-base-safety-plan.md` (post-execution correction, not a plan objective)
> **Result:** Success
> **Branch:** `projex/2607261121-close-scripts-dirty-base-safety` (unmerged; patch commits ride on the ephemeral branch)
> **Related:** 2607261520-close-scripts-dirty-base-safety-audit.md | 2607261121-close-scripts-dirty-base-safety-log.md | 2607261157-close-scripts-dirty-base-safety-redteam.md

---

## Summary

`safe_rollback` / `Invoke-SafeRollback` in `projex-squash-close.{sh,ps1}` fired on **any** non-zero
`merge --squash` exit and emitted one message for two semantically opposite states. On the refusal
path — git declined before mutating anything — that message was false on three counts and directed
the user to `git reset --hard HEAD`, which would destroy the concurrent writer's staged *and*
worktree content that this whole branch exists to protect. Message now splits on whether unmerged
paths actually exist. Three accuracy corrections ride along: the falsified "unreachable" wording, the
log's four/five construction count, and one imprecise `SKILL.md` sentence.

Gate semantics are **unchanged**. No test assertion was added, removed, or altered.

---

## Changes

### `safe_rollback` message split — the substantive fix

**Files:** `projex-squash-close.sh` (`safe_rollback`), `projex-squash-close.ps1` (`Invoke-SafeRollback`)
**Change Type:** Modified

**What Changed:**
- Failure branch now tests `unmerged_paths` / `Get-UnmergedPaths` and emits one of two messages:
  - **non-empty** → the original text, unchanged. A real conflicted squash is present, the
    approval-gated `reset --hard` remains a legitimate last resort.
  - **empty** → new text stating that git refused *before* starting a merge, that there are no
    unmerged entries and no merge in progress, that **nothing** was changed, naming the
    `index != HEAD != worktree` cause and the gate→merge window, and instructing the reader to
    inspect via `git status` and have the content's owner commit or stash it. Explicitly says
    **do NOT run `git reset --hard`** — it would destroy both the staged and the worktree copy.
- Added a header comment on both functions naming the two states and why they need opposite advice.

**Why:**
On the refusal path all three of the original message's assertions are false — verified against live
git, not taken on description:

| Original claim | Reality on the refusal path |
|---|---|
| "the conflicted squash is STILL in `$REPO_ROOT`" | No squash. `merge --squash` exited non-zero having mutated nothing; `MERGE_HEAD` absent |
| "it detects the unmerged entries" / script will refuse to restart | Zero unmerged paths → `in_progress_op` returns nothing → the script **will** start again (and is then correctly stopped by the dirty-base gate) |
| "discard it with `git reset --hard HEAD`" | Destroys the concurrent writer's staged **and** worktree content — the exact loss this branch prevents |

The script itself never lost data (it exits 1 having changed nothing); the harm was misdirecting a
human at the sharpest possible moment.

---

### "Unreachable" wording — falsified claim

**Files:** `tests/README.md`, `tests/dirty-base.test.sh`, `tests/dirty-base.test.ps1`,
`.projex/2607261121-close-scripts-dirty-base-safety-log.md`
**Change Type:** Modified

**What Changed:** "unreachable through the scripts' own entry points" → **"not constructible as a
deterministic regression case; reachable only through the documented gate→merge window"**, with the
mechanism spelled out in each location (gate leaves the tree tracked-clean, nothing re-checks before
the merge, a concurrent writer at `index != HEAD != worktree` defeats both the merge and the reset;
a test cannot pre-seed the state because the gate rejects it up front).

The log additionally carries a **Correction blockquote** recording precisely which half of the
original disjunction was false and why the executor's row-1 dismissal used the wrong test — the state
need not arise *between* merge and rollback, only *before* the merge.

**Why:** `tests/README.md` stated the claim as a coverage justification a future maintainer would
rely on to not revisit the branch. The audit rated that risk "Likelihood: High if left as-is".

---

### Log construction count

**File:** `.projex/2607261121-close-scripts-dirty-base-safety-log.md`
**Change Type:** Modified

**What Changed:** "Four constructions were probed" → "Five", matching the five-row table beneath it
and the Issues section's "five". Both suites' inline comments say "five constructions" too. (The
unrelated "the plan's four steps" in Deviations 5 is a different four and was left alone.)

---

### `SKILL.md` § Branch Finalization

**File:** `SKILL.md`
**Change Type:** Modified

**What Changed:** "The main working directory must already be on the base branch (which it is —
worktree mode never leaves it)." → the `<repo-root>` you pass must itself already have base checked
out; it may be the main working directory **or any other registered worktree**, and the scripts now
assert this rather than assuming it.

**Why:** Imprecise on both counts since the arbitrary-parent-worktree support landed — it is the
*originating* worktree, not necessarily the main one, and the pairing is now enforced, not assumed.

---

## Verification

**Method:** Independent reproduction of the audit's Finding C1 against live git in throwaway repos;
direct exercise of both message branches by extracting the **shipped** functions (via `awk` range on
`.sh`, via AST `FunctionDefinitionAst` lookup on `.ps1`) and running them against real repo state;
both full test runners on both platforms.

**Result:**

Reproduction of the reachable state — tracked `b.txt` at `index=S`, `HEAD=H`, `worktree=W`:

```
git merge --squash eph
  → error: Your local changes to the following files would be overwritten by merge: b.txt
  → merge exit=1 | MERGE_HEAD present: NO | unmerged count = 0
git reset --merge HEAD
  → error: Entry 'b.txt' not uptodate. Cannot merge.
  → fatal: Could not reset index file to revision 'HEAD'.   exit 128
worktree b.txt: W    index b.txt: S      ← both survive; reset --hard would destroy both
```

Branch selection, shipped functions, both platforms:

```
CASE A  refusal, 0 unmerged   → .sh rc=1 / .ps1 False, NEW message, "do NOT run 'git reset --hard'"
                                content intact: worktree=W index=S   (both platforms)
CASE B  conflict, rollback OK → .sh rc=0 / .ps1 True, no message emitted
CASE C  conflict + rollback fails → .sh rc=1, ORIGINAL message, "conflicted squash is STILL" present
```

Full runners:

```
bash tests/run-all.sh
  resolve-conflicts 30 | resume 52 | worktree 34 | dirty-base 139
  === total: PASS=255 FAIL=0

pwsh -File tests/run-all.ps1
  resolve-conflicts 33 | worktree 39 | dirty-base 139
  === total: PASS=211 FAIL=0
```

Both match the pre-patch baselines exactly (255/0, 211/0) — no assertion changed, none added.
`bash -n` clean on both shell files; `[Parser]::ParseFile` clean on both PowerShell files.

**Status:** PASS

---

## Impact on Related Projex

| Document | Relationship | Update Made |
|----------|-------------|-------------|
| `2607261520-close-scripts-dirty-base-safety-audit.md` | Source of directive | Conditions C1, C2, C4 discharged; C3 deliberately not actioned (see Notes) |
| `2607261121-close-scripts-dirty-base-safety-log.md` | Execution log being corrected | Count fixed 4→5; conclusion re-worded; Correction blockquote added; Issues + criterion-8 rows realigned |
| `2607261121-close-scripts-dirty-base-safety-plan.md` | Executed plan | Untouched — criterion 8's escape-clause *outcome* still stands; only its justification was wrong |

---

## Notes

**Deliberately out of scope, confirmed not attempted:**

- **Re-checking `tracked_dirt` immediately before `merge --squash`.** The audit's "would make
  excellent" recommendation, which would close the window entirely and make the original
  unreachability claim true. It changes gate semantics across 3 close types × 2 platforms and needs
  its own plan and tests. Noted and left; the message split is the correct patch-sized response to a
  window that still exists.
- **`AGENTS.md` broad staleness** (19 workflow types with outdated lifecycles) — plan-sized.
- **`CLAUDE.md`** (audit condition C3, still reads `188 assertions` vs the true 466) — gitignored and
  user-owned; surfaced to the user separately rather than edited here.
- **Branch not closed, merged, or abandoned.** Both patch commits sit on
  `projex/2607261121-close-scripts-dirty-base-safety`; `main` untouched.

**Pre-existing, not introduced and not fixed:** `resume.test.sh` (52 assertions) has no `.ps1`
counterpart — the platform totals differ for this reason alone.

**Observation worth keeping:** the refusal path is the one place where the script's own error text
could cause the data loss the script was written to prevent. The gate protects the tree; the message
protects the human. Both are part of the safety surface, and only the first had tests.
