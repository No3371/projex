# Agent-Managed Close Lockfile (`.closing-to-<base>`)

> **Status:** Ready
> **Created:** 2026-07-15
> **Author:** Claude (opus) — orchestrate-projex subagent
> **Source:** Direct request (human spec: `.closing-to-[base-branch]` agent lock)
> **Related Projex:** `2607140251-close-scripts-per-branch-lock-plan.md` (script-level mkdir mutex — see § Relationship To The Script-Level Lock); `2607140239-active-projex-folder-proposal.md` (visibility — no interaction, this lock is intentionally git-invisible)
> **Worktree:** No

---

## Summary

Adds a **workflow-level advisory lock**, owned by the close-projex *agent*, so parallel closes onto the same base branch detect each other before touching git. The agent atomically claims `<repo-root>/.git/projex-locks/.closing-to-<sanitized-base>` (content: UTC timestamp + agent/close identity) once all pre-git ceremonies are done, and removes it once close-projex's git work is complete. On contention it fails fast and reports — it never blocks. Doc-only change to three framework specs; no runtime code.

**Scope:** Framework repo's own workflow specs — `close-projex.md`, `SKILL.md`, `orchestrate-projex.md`. Single `.projex/` scope (repo root).
**Estimated Changes:** 3 files, ~1 new subsection each (acquire/release ceremony + convention docs + orchestrator note). No script files edited.

---

## Objective

### Problem / Gap / Need

`orchestrate-projex` can dispatch multiple `close-projex` runs concurrently (parallel groups of independent plans that all target `base`, or an operator running several closes at once). Every finalization funnels through `git -C <repo-root> …` against the one shared working tree / index / HEAD — true in **both** checkout and worktree mode (worktree closes still merge into the shared repo HEAD). Two closes onto the *same* base can therefore interleave and corrupt each other's merge/checkout.

The sibling plan `2607140251-close-scripts-per-branch-lock-plan.md` guards the *narrow* window inside the four finalization shell scripts. This plan adds a *wider*, agent-owned advisory lock that wraps close-projex's **entire** git-touching region (the clean-tree gate, any straggler commit, the finalization script, and any post-finalize commit) and carries **human-readable holder info** (who is closing to which base, since when) that an empty mkdir mutex cannot.

### Success Criteria
- [ ] `close-projex.md` Step 7 instructs the agent to **acquire** the lock atomically before the first git operation of finalization, and **release** it after the last one, in both checkout and worktree mode.
- [ ] Lock path, filename, sanitization, and content format are specified once in `SKILL.md` and referenced (not re-specified) by `close-projex.md`.
- [ ] Lock lives under `.git/` so it is invisible to `git status --porcelain` and can never trip close-projex's own clean-tree gate or be accidentally committed.
- [ ] Sanitization and directory match the sibling plan exactly (`/` → `_`, `<repo-root>/.git/projex-locks/`) so both mechanisms are mutually legible.
- [ ] Contention behavior (fail-fast + report), staleness handling, and worktree/abandon carve-out are documented as explicit design decisions with rationale.
- [ ] `orchestrate-projex.md` tells the orchestrator how to react to a fail-fast (re-dispatch / serialize) and confirms stacked closes don't contend.

### Out of Scope
- Editing the finalization shell scripts (`projex-*-close`, `projex-abandon`) — that is the sibling plan's territory.
- A dedicated acquire/release helper script — proposed as a future consolidation (see Open Questions), not built here.
- Locking `execute-projex`'s base-branch plan-status commit — a separate, narrower race (see Impact → Downstream).
- Any global (cross-different-base) lock — same-base only, per the human's requirement.

---

## Context

### Current State

`close-projex.md` Step 7 (FINALIZE GIT BRANCH) opens with a read-only clean-tree gate (`git status --porcelain`), then a worktree leftover check, then presents Options A–D (squash / merge / rebase / abandon), each invoking a `projex-*` script via `git -C <repo-root>`. There is no mutual exclusion between two agents reaching Step 7 for the same base. `orchestrate-projex.md` already states that mutating parallel-group members must be serialized "unless each runs in its own worktree" — but worktree mode does **not** actually remove the shared-HEAD merge race, so serialization is the real protection and it currently rests on orchestrator discipline alone.

### Key Files

> Quick reference — detailed changes are in Implementation steps below.

| File | Role | Change Summary |
|------|------|----------------|
| `close-projex.md` | Defines Step 7 finalization | Add acquire (top of Step 7) + release (after last git op) ceremony |
| `SKILL.md` | Framework spec | Add "Close Lock" convention subsection (path, naming, content, staleness) |
| `orchestrate-projex.md` | Orchestrator rules | Add fail-fast handling + confirm stacked closes don't contend |

### Dependencies
- **Requires:** Nothing hard. Shares directory + sanitization with the sibling plan; either can land first.
- **Blocks:** Nothing.

### Constraints
- No absolute paths in the spec text; reference the sibling by filename only.
- Acquire must be **atomic** (single filesystem create that fails if the target exists) — a read-then-write by an LLM agent is racy (TOCTOU) and unacceptable as a mutex.
- Lock must not appear in `git status` (would break close-projex's own clean-tree gate and risk being committed) → it lives inside `.git/`.

### Assumptions
- `<repo-root>/.git/` exists and is writable for every close (true for any non-bare repo; worktrees resolve `.git` to the shared common dir, so all worktrees of one repo see the same lock — correct, since they share the base being merged into).
- Base-branch names collide only rarely after `/` → `_` sanitization (e.g. `feature/x` vs `feature_x`); accepted, matching the sibling plan's identical trade-off.

### Impact Analysis
- **Direct:** `close-projex.md`, `SKILL.md`, `orchestrate-projex.md`.
- **Adjacent:** Sibling plan `2607140251-…` — same lock directory; the two locks coexist (different names/primitives). Must stay naming-consistent.
- **Downstream:** `execute-projex.md` performs a base-branch plan-status commit at INITIALIZE; parallel executes onto the same base race on that commit too. Not fixed here — flagged as an Open Question.

---

## Implementation

### Overview

Define the lock convention once in `SKILL.md`; wire the acquire/release ceremony into `close-projex.md` Step 7; add an orchestrator-facing note. The lock is **advisory and coarse**; it is *not* a replacement for the sibling script-level mutex (see § Relationship). Design decisions (fail-fast, staleness, worktree carve-out) are baked into the SKILL text so all readers share one definition.

### Lock specification (the shared definition)

- **Directory:** `<repo-root>/.git/projex-locks/` (created if absent). Inside `.git` → never in the working tree, never committed, never seen by `git status`.
- **Filename:** `.closing-to-<sanitized-base>` where `<sanitized-base>` = base branch with `/` replaced by `_` (identical to the sibling plan). Example: base `main` → `.closing-to-main`; base `projex/2607…-x` → `.closing-to-projex_2607…-x`.
- **Content (single line):** `<utc-iso8601-timestamp> | <agent/close identity>` — e.g. `2026-07-15T20:43:07Z | close-projex plan=2607…-x branch=projex/2607…-x`. The timestamp is *last-updated*: written at acquire; a long multi-phase close MAY re-write it (heartbeat) though v1 writes once.
- **Atomic acquire (fails if held):**
  - bash: `( set -o noclobber; printf '%s | %s\n' "$TS" "$ID" > "$LOCK" ) 2>/dev/null` — non-zero exit ⇒ already held.
  - PowerShell: open with `CreateNew` (`[System.IO.File]::Open($Lock,'CreateNew','Write')`) then write + close — throws if held.
- **Release:** delete the file (`rm -f` / `Remove-Item -Force`) after the final git operation. Idempotent.

### Step 1: Document the convention in `SKILL.md`

**Objective:** One authoritative definition of the close lock all workflows reference.
**Confidence:** High
**Depends on:** None

**Files:**
- `SKILL.md`

**Changes:** Add a short subsection (near § Git Integration / Utility Scripts) titled "Close Lock (`.closing-to-<base>`)" containing the Lock specification above verbatim, plus the three design decisions:

```markdown
// After (new subsection):
#### Close Lock (`.closing-to-<base>`)

A close-projex agent claims a per-base advisory lock before finalizing, so
parallel closes onto the same base detect each other. Lives at
`<repo-root>/.git/projex-locks/.closing-to-<sanitized-base>` (`/`→`_`,
matching the finalization-script mutex). Content: `<utc-iso8601> | <identity>`.
Acquire atomically (noclobber / CreateNew); release after the last git op.

- Contention → FAIL FAST + report the holder line; never block. The
  orchestrator (or human) re-dispatches once the holder releases.
- Stale lock (holder crashed — an agent has no finally/trap): compare `now`
  vs the timestamp; past the staleness threshold (default 30 min) the report
  flags it as stale and asks a human before reclaiming. Never auto-steal.
- Worktree AND checkout mode both acquire (both merge into shared HEAD).
  Exception: worktree-mode abandon touches no shared state → no lock, mirroring
  the finalization-script mutex.
```

**Rationale:** SKILL is the single source of truth; defining it here keeps `close-projex.md` terse and guarantees the sibling script mutex and this lock stay naming-consistent.

**Verification:** `grep -n "Close Lock" SKILL.md` returns the new subsection; path/sanitization match `2607140251-…`.

**If this fails:** `git checkout -- SKILL.md`.

### Step 2: Wire acquire/release into `close-projex.md` Step 7

**Objective:** Agent acquires at the top of Step 7 (before the clean-tree gate — that gate + any straggler commit already touch the shared index) and releases after the finalization script (and any post-finalize commit) returns.
**Confidence:** High
**Depends on:** Step 1 (references the SKILL definition)

**Files:**
- `close-projex.md`

**Changes:**

```markdown
// Before (top of Step 7):
### 7. FINALIZE GIT BRANCH

**GATE: Verify clean working tree before proceeding.** …

// After:
### 7. FINALIZE GIT BRANCH

**ACQUIRE THE CLOSE LOCK (both modes; skip only for worktree-mode abandon).**
Before any git operation below, atomically claim
`<repo-root>/.git/projex-locks/.closing-to-<sanitized-base>` — see SKILL.md
§ Close Lock for path, content, and the atomic acquire one-liners. If the lock
is already held, STOP: do not run the gate, straggler commit, or finalization
script. Report the holder line (and whether it is past the staleness
threshold) to the orchestrator/human; the ephemeral branch is untouched, so a
later retry loses nothing.

**GATE: Verify clean working tree before proceeding.** …
```

And after the finalization options block:

```markdown
// After (end of Step 7, after the script returns):
**RELEASE THE CLOSE LOCK.** Once the finalization script has returned and any
post-finalize commit on the base is done, delete the lock file (`rm -f` /
`Remove-Item -Force`). Release even on a failed/aborted finalization — the
scripts restore prior state, so holding the lock past that point only blocks
retries.
```

**Rationale:** Acquiring *above* the clean-tree gate makes the critical section cover every shared-state touch in the close, not just the script's internals — the whole point of an agent-level (vs script-level) lock. Releasing on failure prevents self-deadlock on retry.

**Verification:** Read Step 7 — acquire precedes the gate, release follows the script, both cross-reference SKILL § Close Lock and name the worktree-abandon carve-out.

**If this fails:** `git checkout -- close-projex.md`.

### Step 3: Orchestrator handling in `orchestrate-projex.md`

**Objective:** Tell the orchestrator what a close fail-fast means and confirm stacked closes don't contend.
**Confidence:** High
**Depends on:** Steps 1–2

**Files:**
- `orchestrate-projex.md`

**Changes:** In the Parallel-group safety / Stacked Orchestration area, add:

```markdown
// After (appended note):
**Same-base close contention.** Independent plans closing onto the same base in
one parallel group are guarded by the close lock (SKILL.md § Close Lock). A
subagent that reports "close lock held by …" has done no git damage — re-dispatch
that close after the holder releases (this is the concrete mechanism behind the
"serialize mutating members" rule). Stacked closes do NOT contend: B closes into
`projex/A`, then A closes into base — different bases, different lock files.
```

**Rationale:** Closes the loop — the lock's fail-fast is only useful if the orchestrator knows to re-dispatch rather than treat it as a hard failure.

**Verification:** Read the note; it names the fail-fast → re-dispatch loop and the stacked-close non-contention.

**If this fails:** `git checkout -- orchestrate-projex.md`.

---

## Relationship To The Script-Level Lock (`2607140251-…`) — Reconciliation Verdict

**Verdict: COMPLEMENTARY — keep both, layered. If the human wants only one, keep the sibling (script-level) plan; this agent-level lock is the weaker-as-mutex layer and is justified by coverage + observability, not by correctness.**

Two mechanisms, two layers:

| | Sibling `2607140251-…` (script-level) | This plan (agent-level) |
|---|---|---|
| Primitive | `mkdir` mutex — atomic syscall, self-releasing via `finally`/`trap` | `.closing-to-<base>` file, agent-owned, atomic create (noclobber/CreateNew) |
| Window | Only inside each finalization script's git region | Whole close: clean-tree gate → straggler commit → script → post-commit |
| Robustness | Strong — atomic + auto-release even on normal script exit | Weaker — no `finally`/`trap` if the *agent* dies; relies on agent discipline |
| Observability | Opaque empty dir | Human-readable holder line (who / which base / since when) + staleness |
| Home | `<repo-root>/.git/projex-locks/<base>.lock` | `<repo-root>/.git/projex-locks/.closing-to-<base>` |

They share the same directory and sanitization, use different names/primitives, and **do not conflict**. Layered value:

- **Correctness backstop = the sibling.** Its mutex sits on the exact git-mutating lines and self-releases; it holds even if this advisory lock is skipped, buggy, or stale. That is the guarantee you actually want.
- **This lock adds earlier + wider detection and observability.** It catches a second agent *before* it burns work reaching the script, wraps the pre-script and post-script commits the sibling never sees, and answers "who is closing to `main` right now?" — which the mkdir mutex cannot.

**Honest caveat (the finding the human needs):** as a *mutex* this agent-level lock is strictly weaker than the sibling's — an agent that dies leaves a stale file with no auto-release, and its safety depends on using the atomic-create one-liner rather than a naive read-then-write. Its unique benefits (wider window, holder info) could alternatively be folded into the sibling plan (have the scripts print holder info; recommend worktree mode for parallel closes). **So if minimal surface area is the goal, ship the sibling alone and drop this. If defense-in-depth + operator visibility are wanted, ship both.** They are not redundant in the harmful sense and never race each other.

---

## Verification Plan

### Automated Checks
- [ ] `grep -n "Close Lock" SKILL.md close-projex.md orchestrate-projex.md` shows the convention defined once and referenced twice.
- [ ] Path + `/`→`_` sanitization strings match `2607140251-close-scripts-per-branch-lock-plan.md`.

### Manual Verification
- [ ] Step 7 acquire precedes the clean-tree gate; release follows the finalization script.
- [ ] Worktree-abandon carve-out stated in both SKILL and close-projex.
- [ ] Fail-fast (never block) + staleness (never auto-steal) are explicit.

### Acceptance Criteria Validation
| Criterion | How to Verify | Expected Result |
|-----------|---------------|-----------------|
| Lock invisible to git | Reason about `.git/` path | Never in `git status`, never committed, never trips the clean-tree gate |
| Atomic acquire | Inspect one-liners | noclobber / CreateNew fail when held — no TOCTOU |
| Both modes covered | Read Step 7 | Acquire in checkout + worktree; only worktree-abandon exempt |
| Orchestrator loop closed | Read orchestrate note | Fail-fast → re-dispatch documented |

---

## Rollback Plan

Per-step rollback reverts each file independently. To abandon entirely:

1. `git checkout -- SKILL.md close-projex.md orchestrate-projex.md`
2. Confirm `git status --porcelain` shows no changes to those three files.
3. No runtime state persists — the lock convention is documentation only; no lock directories are created by this plan.

---

## Notes

### Risks
- **Stale lock after agent crash:** No `finally`/`trap` at the agent layer. Mitigation: timestamp-based staleness threshold (30 min default) surfaced in the contention report; never auto-steal — escalate to a human. The sibling script mutex remains the real backstop.
- **Sanitization collision** (`feature/x` vs `feature_x`): rare; accepted to stay consistent with the sibling. Mitigation: note it; a stronger encoding could be a future joint change to both mechanisms.
- **Agent forgets to release:** Mitigation: release step is mandatory in Step 7 and idempotent; staleness detection recovers an orphaned lock.

### Open Questions
- [ ] **Contention policy — confirm fail-fast.** This plan chooses fail-fast + report (matches the sibling and dovetails with the orchestrator's existing serialize-and-re-dispatch role). A bounded wait/retry is the alternative but fits LLM agents poorly. Confirm fail-fast is the desired behavior, or specify a wait budget.
- [ ] **Should `execute-projex`'s base-branch plan-status commit get the same lock?** Parallel executes onto one base race on that small commit too. Out of scope here; flag whether it warrants a follow-up.
- [ ] **Consolidate into a helper script?** An optional `projex-close-lock.{sh,ps1}` (acquire/release subcommands) would guarantee atomicity cross-platform and cut agent-discipline risk, while keeping lifecycle agent-owned. Deferred; confirm whether wanted.
