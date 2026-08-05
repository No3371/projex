# Sprint-Projex

Sprint is orchestration in a loop: given a **goal**, the orchestrator repeatedly derives the smallest next objective, runs it through a lightweight iteration body, verifies, absorbs the result, and goes again — until the goal is reached or a stop signal fires.

Second orchestration-type workflow. Everything in `orchestrate-projex.md` — subagent handoff, nesting depth, review-after-return, patch-vs-revise disambiguation, human escalation, completion report, chain notation — applies unless overridden here. Like orchestrate, sprint produces no standalone document; sub-workflows produce their own artifacts, and the nav's revision log is the sprint record.

## Core Contract

Two invariants define sprint. Everything else — including the iteration body — is configurable:

1. **Loop until goal** — iterations continue while the goal is unmet and no stop signal has fired. No fixed iteration count.
2. **Piecemeal minimal steps** — each iteration takes the smallest objective that observably advances the goal. An objective too big for the body is decomposed at the nav, never escalated into heavier ceremony (no full execute → close cycle inside an iteration).

**Default body:**

```
nav → plan → patch! → audit → [patch]
```

- **nav** — revise the sprint nav against current state; emit the single next objective (smallest useful step toward the goal)
- **plan** — author a plan for that objective alone; commits to the sprint branch
- **patch!** — execute the plan via patch-projex plan-execution mode; required-success
- **audit** — validate the executed work against the plan's success criteria
- **[patch]** — optional fix for audit findings; orchestrator judges

The human may supply a different body via chain notation (`orchestrate-projex.md § Explicit Chain Notation`). The loop contract, stop signals, and worktree requirement hold regardless of body.

## Invocation

```
/sprint-projex.md <goal>
/sprint-projex.md <goal> body: <chain>
```

**Examples:**
- `/sprint-projex.md All TODO comments in src/api resolved`
- `/sprint-projex.md Parser test suite green on CI`
- `/sprint-projex.md @2602011430-engine-roadmap-nav.md finish Phase 2`
- `/sprint-projex.md Migrate every config reader to the new schema body: nav, plan, patch!, stress, [patch]`

The goal must be verifiable — "improve the code" is not a goal; "all callers migrated off `LegacyClient`" is. A goal that cannot be checked cannot terminate the loop. Vague goal → sharpen with the human before setup.

## Setup

1. **Resolve repo root** — `git rev-parse --show-toplevel` from the goal's context (SKILL.md § Repo Resolution). Record `{base-branch}` via `git branch --show-current` — finalization needs it.
2. **Adopt or create the sprint nav** — an existing nav covering the goal's scope is adopted; otherwise dispatch navigate-projex to create one scoped to the goal. The nav is the sprint's memory: current position, objective history, one revision log entry per iteration.
3. **Create the sprint worktree** — the whole sprint runs on one ephemeral branch inside a worktree; base is untouched until close:

```bash
{projex-scripts}/projex-worktree.{sh|ps1} <repo-root> projex/sprint/{yymmddhhmm}-{sprint-name}
```

All iteration work — plans, patches, audit documents, nav revisions — commits to the sprint branch inside the worktree. Patch-projex's "commit to current branch" behavior lands on the sprint branch by construction.

**Auxiliary-artifact commits inside the sprint:** the worktree must be clean at close, so the orchestrator commits auxiliary artifacts (audit docs, nav revisions) to the sprint branch as part of each iteration. This is sanctioned here — the human reviews the whole sprint at close, and nothing reaches base before that.

## Iteration Loop

Each iteration, in order (default body; custom bodies map onto the same A–E skeleton):

**A. Derive** — dispatch nav revision: absorb the previous iteration's outcome, reassess position against the goal, emit exactly one next objective. Three possible returns: `objective` | `goal reached` (with evidence) | `nothing to do`.

**B. Spec** — dispatch plan-projex on the objective. The plan commits to the sprint branch (satisfies plan-before-execution with the sprint branch as base). Plan's split heuristics trip → the objective is too big: return to A with decomposition feedback.

**C. Execute** — dispatch patch-projex to execute the plan. Patch's scope guard trips → same rule: decompose at the nav, don't escalate to execute-projex.

**D. Verify** — dispatch audit-projex against the plan's claims:
- Verified → iteration **success**
- Fixable findings → optional `[patch]`, then re-audit once
- Rejected after the fix round → iteration **failure**

**E. Absorb** — patch-projex's epilogue has already closed the plan and checked off the nav milestone; the next iteration's nav revision does the deep absorb. Update counters, check stop signals, loop.

**Counters:** consecutive-failure count (resets on any success) and consecutive-nothing count (resets when any objective emerges). Both derivable from the nav revision log; the orchestrator tracks them explicitly.

## Stop Signals

| Signal | Condition | Action |
|--------|-----------|--------|
| **Goal reached** | Nav revision concludes the goal is met, with evidence | Finalize |
| **Exhausted** | 2 consecutive `nothing to do` returns while the goal is unmet | Finalize; report the gap between state and goal |
| **Stalled** | 3 consecutive iteration failures | Halt, escalate; leave the worktree intact for the human |
| **Human** | Human interrupts or redirects | Halt at the iteration boundary; log the intervention |

An optional iteration cap `N` may be supplied at invocation as a guard rail; hitting it escalates like Stalled. No cap by default — the loop's own signals terminate it.

## Finalize

On Goal reached or Exhausted:

1. **Final nav revision** on the sprint branch — goal status, sprint summary appended to the revision log
2. **Optional sprint-scope audit** — one audit across all iterations together; orchestrator judges whether per-iteration audits already suffice
3. **Close the branch** — squash by default:

```bash
{projex-scripts}/projex-squash-close.{sh|ps1} <repo-root> {base-branch} projex/sprint/{yymmddhhmm}-{sprint-name} "projex(sprint): {goal one-liner} - {N} iterations" --worktree
```

Merge-close is acceptable when per-iteration history matters. A Stalled sprint never self-closes: escalate first; abandon (`projex-abandon … --worktree`) only on human instruction.

4. **Completion report** (`orchestrate-projex.md § Completion Report`) plus an iteration table: objective | result | artifacts.

## Minimality Rules

- Nav emits **one** objective per iteration — never a batch
- Every "too big" signal — plan split heuristics, patch scope guard, audit blast-radius finding — means decompose at the nav, not upgrade the ceremony
- Prefer objectives with observable progress (a test passes, a criterion flips, a file is gone) over preparatory work; two consecutive purely-preparatory iterations is a smell — surface it in the nav
- Iteration artifacts stay per-objective: one plan, one patch doc (plus optional fix patch), one audit per iteration, all on the sprint branch, each closed per its own type's rules

## Inherited From Orchestrate

Subagent handoff contract, nesting depth (orchestrator depth 0, gate at 3), review after each return, patch-vs-revise disambiguation, human escalation triggers, completion report format, chain notation for custom bodies — all per `orchestrate-projex.md`, not re-specified here. Sprint adds only: the goal loop, the stop signals, the mandatory worktree, and the minimality rules.

## Output

- After close: the revised nav plus N × (plan, patch doc, audit) landed on base, each in `.projex/` or `.projex/closed/` per its type's rules
- Sprint branch squash-merged (or abandoned on human instruction); worktree removed
- No sprint document of its own — the nav's revision log and the completion report are the sprint record
