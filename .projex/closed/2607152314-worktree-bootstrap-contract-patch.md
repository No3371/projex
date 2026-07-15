# Patch: Worktree Bootstrap Contract

> **Date:** 2026-07-15
> **Author:** agent
> **Directive:** Rigorous agents refuse to continue execution in a worktree because of missing `node_modules` (etc.). Suggestions 1+2: name the expectation in the spec, add a bootstrap step to the worktree lifecycle.
> **Source Plan:** Direct
> **Result:** Success

---

## Summary

Fresh worktrees share `.git` but start with only git-tracked files, so gitignored artifacts (`node_modules`, `.env`, `venv/`, build output) are absent by design. The framework covered the **exit** (cleanup contract) but never the **entry** — nothing told agents that missing deps in a fresh worktree are expected. Rigorous agents read it as a failed precondition and halt. This patch names the expectation (SKILL.md) and adds a bootstrap step to the execution lifecycle (execute-projex.md), converting "halt on missing deps" into "bootstrap, then proceed."

---

## Changes

### SKILL.md § Worktree Mode

**File:** `SKILL.md`
**Change Type:** Modified
**What Changed:**
- Added **Bootstrap contract** bullet to "How it works" list (SKILL.md:311), directly before the existing Cleanup contract. States that a fresh worktree's absent gitignored artifacts are expected, not a blocked precondition — bootstrap them before execution. Pairs symmetrically with the Cleanup contract (what bootstrap installs = what cleanup removes).

**Why:**
The section already listed "No clean-state requirement at execution start" as a benefit, but that concerns *git* cleanliness, not *environment* readiness. The missing counterpart is what agents tripped on.

---

### execute-projex.md — INITIALIZE EXECUTION + pre-exec checklist

**File:** `execute-projex.md`
**Change Type:** Modified
**What Changed:**
- Added a **"Bootstrap the worktree before executing"** step in § 1 INITIALIZE EXECUTION, worktree mode (execute-projex.md:97): detect the project's install/build command from its manifest (`npm ci`, venv+install, `go mod download`, …), run it in the worktree, log it before step 4. Notes missing deps are not a failed precondition, and that symlinking relocatable deps from the main checkout is a valid faster path (with native-module caveat).
- Added a worktree carve-out to the PRE-EXECUTION manual-validation item "Required tools/dependencies available" (execute-projex.md:53) so it no longer contradicts the new bootstrap step — the exact gate a rigorous agent halts on.

**Why:**
Gives the rigor somewhere productive to go: satisfied by *doing the bootstrap*, not by aborting. Second edit prevents a stale/conflicting checklist item.

---

## Verification

**Method:** Grep for `Bootstrap|bootstrap` across repo `.md` files; visual read of both edited sections for coherence with surrounding text (cleanup contract pairing, checklist consistency).

**Result:**
```
execute-projex.md:53 — checklist carve-out present
execute-projex.md:99 — bootstrap step present (worktree block)
SKILL.md:311        — Bootstrap contract bullet present, precedes Cleanup contract
```

**Status:** PASS

---

## Impact on Related Projex

| Document | Relationship | Update Made |
|----------|-------------|-------------|
| — | No active projex references worktree entry preconditions | None needed |

---

## Notes

- Scope held to agreed suggestions 1+2. Deliberately **not** done: reusing/symlinking deps as a `projex-worktree` script feature (suggestion 3), and routing env-heavy small changes away from worktree mode in plan-projex (suggestion 4). Either is a reasonable follow-up patch/plan.
- Addresses the long-standing known issue "execute-projex.md clean-state check not excepted for worktree mode" from the 2026-03-07 review — the entry-side gap is now closed.
