# Sprint-Projex

Sprint is orchestration in a loop: given a **goal**, the orchestrator repeatedly derives the next objective, runs it through a lightweight iteration body, verifies, absorbs the result, and goes again — until the goal is reached or a stop signal fires.

Second orchestration-type workflow. Everything in `orchestrate-projex.md` — subagent handoff, nesting depth, review-after-return, patch-vs-revise disambiguation, human escalation, completion report, chain notation — applies unless overridden here. Unlike orchestrate, sprint produces its own document: the **sprint nav** (§ Sprint Nav) — a sprint-flavored Navigation serving as the sprint's backbone: goal, branches, worktree, position, iteration outcomes. Committed to base at start, so an in-flight sprint stays visible from base and a later session can be handed back into it (§ Resume). Sub-workflows still produce their own artifacts.

## Core Contract

Two invariants define sprint — **loop** and **piecemeal**. Everything else is configurable:

1. **Loop until goal** — iterations continue while the goal is unmet and no stop signal has fired. No fixed iteration count.
2. **Piecemeal steps** — each iteration takes **one** objective, sized to the active step size (§ Step Size). An objective too big for the body is decomposed at derive, never escalated into heavier ceremony (no full execute → close cycle inside an iteration).

One objective per iteration and decompose-don't-escalate are the invariants; *how small* that objective is, is configuration.

**Loop skeleton.** Every iteration is `derive → body → absorb`. Derive and absorb are **structural** — present in every sprint, not body members, cannot be removed or retargeted by chain notation. Derive is dispatched to an independent subagent (§ Iteration Loop A); absorb is the orchestrator's own step. The body is the configurable middle: the work steps that turn one objective into verified change.

**Default body:**

```
plan → patch! → audit → [patch]
```

- **plan** — author a plan for that objective alone; commits to the sprint branch
- **patch!** — execute the plan via patch-projex plan-execution mode; required-success
- **audit** — validate the executed work against the plan's success criteria
- **[patch]** — optional fix for audit findings; orchestrator judges

The human may supply a different body via chain notation (`orchestrate-projex.md § Explicit Chain Notation`). The body is configuration, not structure: sprint hardwires no step sequence — the orchestrator interprets whatever body is active and orchestrates it toward the derived objective (§ Iteration Loop B). A `navigate` step inside a supplied body is an ordinary navigate-projex dispatch on whatever scope roadmap the objective concerns — it is **never** read as targeting the sprint nav (§ Sprint Nav). The loop skeleton, stop signals, and worktree requirement hold regardless of body.

## Step Size

`step` sets how much one objective may cover. Default `minimal`.

| `step` | Derive emits |
|---|---|
| `minimal` | the smallest objective with observable progress — one criterion flips, one file resolved, one test goes green |
| `standard` | one coherent unit of work that a single body run can plan, execute, and check without splitting |
| `extended` | several related changes as one objective; "too big" is judged against the body's actual capacity, not against minimality |

**A derive-time constraint, not a body one.** `step` bounds what the derive subagent may emit and is the yardstick the orchestrator reviews the returned objective against (§ Iteration Loop A). No body step reads it; it is not chain notation and carries no chain operators. `body:` and `step:` are orthogonal — one sets what an iteration does, the other how much it bites off.

Fixed at setup and recorded in the sprint nav header; a resumed sprint inherits it from there. Changing it mid-sprint is a human instruction, logged as a Revision Log entry.

## Sprint Nav

The sprint's document of record is a **sprint-flavored Navigation**: `{yymmddhhmm}-{sprint-name}-sprint.md`. Navigate-projex is its backbone — living while open, revised every iteration, closed only by its own closing step (here, sprint finalize) — with sprint deltas:

| | Plain nav | Sprint nav |
|---|---|---|
| Scope | a lasting scope's roadmap | one sprint's goal |
| Reviser | agent proposes, user disposes | derive subagent — no user in the loop |
| Roadmap | pre-planned phases/milestones | `## Iterations` table — steps emerge one at a time from derive, never batched ahead |
| Lifespan | many cycles | one sprint; born and closed with it |
| Closing | navigate-projex § CLOSING A NAVIGATION | sprint finalize only |

Writes are structural-only: derive (position + revision log), absorb (iteration row), finalize (closure). No body step, no chain notation, no other workflow touches the sprint nav — the Navigation rule that only a nav's own closing workflow moves it holds, with finalize playing that role. The `{yymmddhhmm}-{sprint-name}` stem is the **sprint uid** — branch, worktree, and nav all carry it, and every artifact produced inside the sprint references back to it.

Status follows the Navigation exception (SKILL.md § Lifecycle Status): `In Progress` for the sprint's whole open life; terminal states `Complete (Goal Reached)` | `Complete (Exhausted)`, set only by finalize. A Stalled or human-halted sprint stays `In Progress` in `.projex/` — that is what keeps it discoverable for later adoption.

**Distinct from any scope roadmap.** A goal may derive from an ordinary nav (`@{nav}.md finish Phase 2`); that external nav is recorded via `> **Nav:** {nav-filename}` in the sprint nav header — the standard nav-derivation mark — and the sprint's outcome is reflected into it at finalize. The two are separate documents with separate lives: the external nav steers a scope, the sprint nav backbones one sprint. Sprint never creates a scope roadmap; that is navigate-projex's business.

## Invocation

```
/sprint-projex.md <goal>
/sprint-projex.md <goal> step: <minimal|standard|extended>
/sprint-projex.md <goal> body: <chain>
/sprint-projex.md @{yymmddhhmm}-{name}-sprint.md
```

**Examples:**
- `/sprint-projex.md All TODO comments in src/api resolved`
- `/sprint-projex.md Parser test suite green on CI`
- `/sprint-projex.md @2602011430-engine-roadmap-nav.md finish Phase 2`
- `/sprint-projex.md Migrate every config reader to the new schema body: plan, patch!, stress, [patch]`
- `/sprint-projex.md Retire the v1 event bus step: extended` — fewer, larger objectives (§ Step Size)
- `/sprint-projex.md @2608060448-vertical-axis-sprint.md` — adopt the in-flight sprint that nav records (§ Resume)

The goal must be verifiable — "improve the code" is not a goal; "all callers migrated off `LegacyClient`" is. A goal that cannot be checked cannot terminate the loop. Vague goal → sharpen with the human before setup.

## Setup

Setup always starts a **fresh** sprint. Adopting an in-flight one is the user's call, made at invocation by passing its sprint nav (§ Resume) — setup defines no discovery step. An orchestrator that nonetheless notices an active overlapping `projex/sprint/*` branch or `In Progress` sprint nav should surface it before branching rather than build beside it silently: a second sprint branch over the same scope squash-closes into base while the real history — tracked position, prior iterations — sits ignored on the original.

1. **Resolve repo root** — `git -C <goal-context-dir> rev-parse --show-toplevel` (SKILL.md § Repo Resolution). Record `{base-branch}` via `git -C <repo-root> branch --show-current` — finalization needs it.
2. **Create the sprint nav and commit it to base.** `{yymmddhhmm}-{sprint-name}-sprint.md` in the goal's `.projex/` folder. Commit on `{base-branch}` **before** the worktree exists — same principle as plan-before-execution: base must record the sprint while it runs.
Resolve `{sprint-parent}` from an explicit causal nav/subject; else supplied orchestrator Parent; else `User`.

```markdown
# Sprint: [Sprint Name]

> **Status:** In Progress
> **Goal:** [verifiable goal, verbatim]
> **Base Branch:** {base-branch}
> **Step:** {minimal | standard | extended}
> **Sprint Branch:** projex/sprint/{yymmddhhmm}-{sprint-name}
> **Worktree Path:** {repo-name}/.projexwt/{yymmddhhmm}-{sprint-name}
> **Nav:** {external nav filename — only when the goal derives from one; omit otherwise}
> **Parent:** {sprint-parent}
> **Started:** YYYY-MM-DD HH:MM

## Vision

[The goal expanded: what done looks like, how it is verified. Fixed at setup — derive revises position, never the goal or the step size.]

## Current Position

**As of YYYY-MM-DD (iteration N):**

[State vs goal — revised by every derive. The sprint's memory.]

## Iterations

| # | Objective | Result | Artifacts |
|---|-----------|--------|-----------|
| 1 | [objective] | Success \| Failure \| Nothing | [plan, patch, audit filenames] |

## Open Questions

- [ ] [Surfaced mid-sprint, needs human judgment — derive may add; human or finalize resolves]

## Revision Log

| Date | Iter | Summary |
|------|------|---------|
| YYYY-MM-DD | — | Sprint started |
```

```bash
{projex-scripts}/stage-n-commit.{sh|ps1} <repo-root> "projex(sprint): start {sprint-name}" .projex/{yymmddhhmm}-{sprint-name}-sprint.md
```

3. **Create the sprint worktree** — the whole sprint runs on one ephemeral branch inside a worktree; base is untouched until close:

```bash
{projex-scripts}/projex-worktree.{sh|ps1} <repo-root> projex/sprint/{yymmddhhmm}-{sprint-name}
```

Record `{repo-name}/.projexwt/{yymmddhhmm}-{sprint-name}` as `<work-root>` in the sprint nav; `<repo-root>` stays the base checkout (SKILL.md § Worktree Mode → *Two paths, two names*). Dispatched sub-workflows receive `<work-root>` as their repo argument — a sub-workflow handed `<repo-root>` would commit the sprint's work to base.

All iteration work — plans, patches, audit documents, sprint nav revisions — commits to the sprint branch inside the worktree. Patch-projex's "commit to current branch" behavior lands on the sprint branch by construction.

**Auxiliary-artifact commits inside the sprint:** the worktree must be clean at close, so auxiliary artifacts (audit docs, sprint nav revisions) are committed to the sprint branch as part of each iteration. This is sanctioned here — the human reviews the whole sprint at close, and nothing reaches base before that.

## Resume

Invoked with a sprint nav reference (`/sprint-projex.md @{yymmddhhmm}-{name}-sprint.md`), the orchestrator adopts the sprint that nav records instead of running Setup:

1. **Read the sprint nav** — branch, base, step size, worktree, position, iteration history are all recorded there. Never re-derive from memory or conversation.
2. **Verify the pieces** — branch exists, `git -C <repo-root> worktree list` shows the worktree. Worktree missing but branch alive → re-attach with raw git (`projex-worktree` refuses existing branches): `git -C <repo-root> worktree add {repo-name}/.projexwt/{yymmddhhmm}-{sprint-name} projex/sprint/{yymmddhhmm}-{sprint-name}`
3. **Reconcile the nav** — the sprint-branch copy is authoritative; it carries position revisions and iteration rows the base copy lacks. Read counters and next iteration number from it.
4. **Re-enter the loop at derive** — position is reassessed there; no setup step repeats.

## Iteration Loop

Each iteration is numbered; its uid is `{sprint-uid}#N` (e.g. `2608071530-vertical-axis#3`). Every subagent handoff inside the iteration carries this uid as an established fact, and every artifact the iteration produces records its parent near the top:

```markdown
> **Sprint:** {yymmddhhmm}-{sprint-name}-sprint.md — iteration N
```

Parentage is recoverable from either end: artifact → sprint via the stamp, sprint → artifacts via the nav's iteration table.

Each iteration, in order:

**A. Derive** *(structural, dispatched)* — the orchestrator spawns one **derive subagent** per iteration; it never derives the objective itself. Independence is the point: the orchestrator that just reviewed the body carries that iteration's assumptions and its subagents' framing; the derive subagent judges position from the repo and the sprint nav alone — the same isolation rationale as verify-projex.

Derive subagent contract:

- Reads the sprint nav, then the repo's current state on the sprint branch (iteration artifacts as needed)
- Revises `## Current Position` and appends a Revision Log row — a sprint-flavored nav revision, minus user discussion (the orchestrator stands in as user at review)
- Returns exactly one outcome: `objective` — one step toward the goal, sized to the sprint's `step` (§ Step Size) — | `goal reached` (with evidence) | `nothing to do`
- Commits the nav revision to the sprint branch: `projex(sprint): derive iteration N`

Handoff carries: worktree path (as target repo), sprint nav filename, goal verbatim, step size with its § Step Size definition, iteration number and uid, and the depth clause (depth 1; derive spawns nothing further). It **never** carries the orchestrator's account of the previous iteration — the nav and the repo are the record; restating them is exactly the contamination the dispatch exists to avoid.

The orchestrator reviews the return like any subagent output: an objective oversized for the active `step`, not goal-relevant, or a disguised batch → revision round with specific feedback.

**B. Body** *(configurable)* — the orchestrator runs the active body — default or supplied chain — against the objective. The body is a chain to interpret, not a pipeline to replay: apply `orchestrate-projex.md § Explicit Chain Notation` in full (`!`, `+`, `&`, `| … |*N`, `[optional]`, model annotations) and orchestrate as best serves the derived objective — sequencing dispatches, judging optional steps, reviewing each return against the objective, looping glued pairs. Sprint assumes nothing about which steps the body contains.

Body-wide rules, whatever the chain:

- **Everything lands on the sprint branch** — code, documents, commits. A plan-authoring step satisfies plan-before-execution with the sprint branch as base.
- **"Too big" aborts to derive** — any step signaling the objective exceeds it (split heuristics, scope guards, blast-radius findings, a step's own escalation) ends the body; return to A with decomposition feedback. Never upgrade ceremony mid-iteration — no full execute → close cycle appears because a step balked.
- **Outcome is the orchestrator's judgment** from the whole body run:
  - **success** — the objective is achieved and verified: the body's checker steps are satisfied, or, in a checkerless body, the orchestrator's own review confirms observable progress
  - **failure** — a required-success (`!`) step ultimately fails, a checker stays dissatisfied after its allowed rounds, or the body completes without advancing the goal

Default body walk-through: plan specs the objective → `patch!` executes it (ultimate failure here fails the iteration) → audit checks the result — verified → success; fixable findings → run `[patch]`, re-audit once; still rejected → failure.

**C. Absorb** *(structural)* — the body's own epilogues have closed its artifacts. The orchestrator appends the iteration's row to the sprint nav's `## Iterations` table and commits it to the sprint branch — the deep reassessment belongs to the next derive. Update counters, check stop signals, loop.

**Counters:** consecutive-failure count (resets on any success) and consecutive-nothing count (resets when any objective emerges). Both derivable from the sprint nav's iteration table; the orchestrator tracks them explicitly.

## Stop Signals

| Signal | Condition | Action |
|--------|-----------|--------|
| **Goal reached** | Derive concludes the goal is met, with evidence | Finalize |
| **Exhausted** | 2 consecutive `nothing to do` derives while the goal is unmet | Finalize; report the gap between state and goal |
| **Stalled** | 3 consecutive iteration failures | Halt, escalate; leave the worktree intact for the human |
| **Human** | Human interrupts or redirects | Halt at the iteration boundary; log the intervention |

An optional iteration cap `N` may be supplied at invocation as a guard rail; hitting it escalates like Stalled. No cap by default — the loop's own signals terminate it.

## Finalize

On Goal reached or Exhausted:

1. **Closing position** — the final derive already revised `## Current Position`; append the closing assessment and sprint summary
2. **Optional sprint-scope audit** — one audit across all iterations together; orchestrator judges whether the body's own per-iteration checks already suffice
3. **Reflect into the external nav** — only when the sprint nav header names one: dispatch a nav revision on the sprint branch to check off the milestone and reference the sprint nav
4. **Close the sprint nav** — final iteration row, Revision Log closure entry, `Status:` → `Complete (Goal Reached)` or `Complete (Exhausted)`, move to `.projex/closed/` (`move-n-stage`), commit on the sprint branch. A Stalled or human-halted sprint leaves the nav `In Progress` in `.projex/` — discoverable for later adoption.
5. **Close the branch** — squash by default:

```bash
{projex-scripts}/projex-squash-close.{sh|ps1} <repo-root> {base-branch} projex/sprint/{yymmddhhmm}-{sprint-name} "projex(sprint): {goal one-liner} - {N} iterations" --worktree
```

Merge-close is acceptable when per-iteration history matters. A Stalled sprint never self-closes: escalate first; abandon (`projex-abandon … --worktree`) only on human instruction.

6. **Completion report** (`orchestrate-projex.md § Completion Report`) plus the sprint nav's iteration table: objective | result | artifacts.

## Step Rules

- Derive emits **one** objective per iteration — never a batch, at any step size
- Every "too big" signal from any body step — split heuristics, scope guards, blast-radius findings — means decompose at derive, not upgrade the ceremony
- `step` is a ceiling, not a quota: derive emits the smallest objective that advances the goal and stays coherent, up to that ceiling. A `minimal` objective under `extended` is fine; padding one to fill the ceiling is not
- Prefer objectives with observable progress (a test passes, a criterion flips, a file is gone) over preparatory work; two consecutive purely-preparatory iterations is a smell — surface it in `## Current Position`
- Iteration artifacts stay per-objective: one artifact per body step (plus sanctioned fix rounds), all on the sprint branch, each closed per its own type's rules

## Inherited From Orchestrate

Subagent handoff contract, nesting depth (orchestrator depth 0, gate at 3), review after each return, patch-vs-revise disambiguation, human escalation triggers, completion report format, chain notation for custom bodies — all per `orchestrate-projex.md`, not re-specified here. Sprint adds only: the goal loop with its derive/absorb skeleton, the dispatched derive subagent, the body-wide rules (sprint-branch commits, too-big abort, outcome judgment), the stop signals, the mandatory worktree, the sprint nav and its uid, the step size, and the step rules.

## Output

- After close: the sprint nav (in `.projex/closed/`) plus each iteration's body artifacts landed on base, each in `.projex/` or `.projex/closed/` per its type's rules — every artifact stamped with its parent sprint and iteration; plus a revised external nav when one was bound
- Sprint branch squash-merged (or abandoned on human instruction); worktree removed
- The sprint nav is the sprint's document of record — identity, position, iteration outcomes; the completion report carries the summary
