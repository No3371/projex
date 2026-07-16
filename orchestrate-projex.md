# Orchestrate-Projex

The orchestrating agent receives a task from a human and drives it through projex workflows by acting as the projex **user** — spawning subagents to perform the workflow work, reviewing their output, making user-level decisions, and reporting back.

---

## Role

The orchestrator IS the projex user. It:
- Decides which projex workflow(s) fit the human's task
- Spawns subagents to run those workflows
- Reviews subagent output as a human user would — accepts, requests revision, or redirects
- Makes mid-workflow decisions (worktree mode, merge strategy, scope adjustments)
- Escalates to the human when genuinely blocked or when an action exceeds the task's implied scope
- Reports back to the human when done

It does **not** perform the workflow steps itself. It delegates and decides.

---

## Framework References

The orchestrator must load relevant framework files for the path it chooses. Subagents will load their own workflow specs — the orchestrator passes references, not instructions.

**Core spec** — always load:
- `@./SKILL.md` — framework overview, types, authoring rules, git discipline, utility scripts, auxiliary-artifact commit policy

**Workflow specs** — load per chosen path:
- `@./propose-projex.md` — directional "what if" with trade-offs
- `@./plan-projex.md` — actionable task spec
- `@./execute-projex.md` — plan execution
- `@./close-projex.md` — post-execution walkthrough + branch finalization
- `@./patch-projex.md` — quick-action for small, well-understood changes to code/config
- `@./revise-projex.md` — quick-action to fix a projex document's own content (not code) when new context makes it stale
- `@./eval-projex.md` — open-ended analysis
- `@./review-projex.md` — inspection of existing projex against status quo
- `@./redteam-projex.md` — adversarial analysis
- `@./audit-projex.md` — validation of completed work
- `@./interview-projex.md` — interactive Q&A rounds
- `@./explore-projex.md` — status-quo-grounded investigation
- `@./imagine-projex.md` — generative vision from a seed
- `@./simulate-projex.md` — disposable execution with rollback
- `@./memo-projex.md` — lightweight capture
- `@./navigate-projex.md` — living roadmap
- `@./scan-projex.md` — exhaustive inventory
- `@./define-projex.md` — declarative entity spec
- `@./guide-projex.md` — curated reading path for humans
- `@./archive-projex.md` — compresses closed projex into index
- `@./do-projex.md` — objective-scoped execution sub-workflow; only `/execute-projex.md` may invoke it (single-nesting exception)

---

## Subagent Handoff — Context Only

Subagents have no memory of the orchestrating conversation. Each handoff must be self-contained and must carry:

- **Target repo** — absolute path (subagent resolves git root from there)
- **Original human task** — verbatim, unfiltered
- **Subagent Responsibility** — the role, the objectives, and the expected deliveries
- **Which workflow to invoke** — e.g. `/plan-projex.md`, `/execute-projex.md`
- **Path to the relevant workflow spec and `SKILL.md`** — so the subagent can load them
- **Prior projex artifacts** — by **filename** (not path), e.g. `2604151200-auth-feature-plan.md`
- **Facts already established** — human-confirmed scope boundaries, worktree preference, merge strategy, any constraint the orchestrator has already decided or cleared with the human
- **Model override** — if the human's chain notation (see § Explicit Chain Notation) assigned this step a specific model, pass that as the subagent's `model` parameter; otherwise omit it and let the step run under whatever default is in effect
- **Current Default Model / Your Model** — state which model is actually running this step (the per-step override if one applies, else the orchestrator's current default per § Explicit Chain Notation). Subagent should know what it's running as — matters for artifacts that record authorship/model, and for execute-projex → do-projex nesting where sub-subagents inherit the coordinator's effective model unless overridden

The handoff is **context**, not instruction. Do not tell the subagent *what to do* or *how to do it* — the workflow spec governs that. The subagent will read `SKILL.md` and its workflow file and proceed correctly without further direction.

What to avoid in the handoff:
- Step-by-step directives ("first do X, then Y")
- Re-specifying the workflow's behavior
- Prescribing output format, section structure, or review style
- Adding rules that conflict with or duplicate `SKILL.md` or the workflow spec

**Subagents must not spawn subagents.** Include this constraint verbatim in every handoff: *"You are a subagent. Do not spawn subagents or delegate to other agents. If you cannot complete a step yourself, stop and return what you have with a clear description of what is blocking you."* The orchestrator handles all delegation decisions.

**Single nesting exception — execute-projex → do-projex.** When the orchestrator dispatches `/execute-projex.md`, that subagent (acting as the execute coordinator) MAY spawn one further layer of sub-subagents that each invoke `/do-projex.md` for a single objective. This is the only sanctioned nesting in the framework. Constraints:

- Only `/execute-projex.md` may nest, and only into `/do-projex.md` — no other workflow may spawn sub-subagents
- Sub-subagents must not nest further; the verbatim no-nesting clause above still applies to them
- Dispatching is sequential by default (one objective at a time); concurrent dispatch requires per-objective worktrees
- The execute coordinator retains responsibility for init, task list, plan-wide verification, and completion — only per-objective execution is delegated

The exception's rationale and full contract live in `execute-projex.md § Choose Execution Mode` and `do-projex.md`. The orchestrator does not re-specify them.

---

## Orchestrator Responsibilities

### Review After Each Subagent Returns

Read the subagent's output as a human user would. Judge whether it serves the human's original task. If not, request revision with specific feedback, or redirect to a different workflow. The workflow spec already defines what the subagent should have produced — compare against that, not against your own rules.

If a second attempt still fails, escalate to the human rather than forcing a third round.

### Patch vs Revise — Disambiguate Before Delegating

"Patch the plan" is ambiguous. Common source of misrouted delegation. Means *fix the code the plan describes* (`/patch-projex`) or *fix what the plan document itself says* (`/revise-projex`). Resolve which one the human means before spawning either subagent:
- What the **system/code does** → `/patch-projex`
- What a **projex document claims** (Plan step, Proposal trade-off, Definition boundary, Nav milestone) → `/revise-projex`

Still ambiguous after one inference attempt? Ask the human. Guessing wrong spawns the wrong subagent — wastes a round trip, can produce an unwanted code change.

### Mid-Workflow Decisions

The orchestrator owns decisions a human user would normally make:
- Which workflow to invoke next (or whether to stop)
- Whether a plan is ready to execute
- Whether execution is complete enough to close
- Merge strategy at close (squash / merge / abandon)
- Whether to commit auxiliary artifacts (per `SKILL.md` policy — only if the human would agree)

Default to the workflow spec's own defaults. Deviate only when the human's task clearly requires it.

### Stacked Orchestration — Dependent Plans

B depends on A → stack B's ephemeral branch on A's instead of waiting for A to reach base. No new tooling, just handoff facts:

```
A: base ── execute-projex ──> [projex/A] (stays open)
B: [projex/A] ── execute-projex ──> [projex/B] ── close-projex ──> [projex/A] ── close-projex ──> [base]
```

- Tell B's execute-subagent to start from `projex/A` — checkout mode: check out `projex/A` first; worktree mode: pass `projex/A` as `<base-ref>` to `projex-worktree.{sh|ps1}`
- B's execution log records `Base Branch: projex/A` — close-projex already reads this field generically, so closing B merges into `projex/A`, not the repo base
- Close order: B before A. Deeper chains (C on B on A) nest the same way

Default, not a mandate — stack only when a dependency is declared or clearly implied; independent plans run in parallel against base as usual. A needing revision after B has started on its branch → escalate, don't rewrite a branch other work sits on.

**Explicit workflow lists are literal.** If the human names specific workflows (e.g. "orchestrate-projex plan, redteam"), that list IS the full scope — run exactly those and stop. Do not infer or auto-chain further workflows that would normally follow in a full cycle (e.g. no silent execute/close after a named plan), even if the next step seems obvious. If a natural next step looks missing once the named workflows finish, surface it in the completion report as a question — do not act on it.

This only applies when the human gives an explicit list. If the human instead states a task and lets the orchestrator choose the path, normal workflow selection above applies.

### Explicit Chain Notation

An explicit list may annotate each step using this notation:

```
step, step!, step(model), stepA+stepB, stepA & stepB, | group |*N, <model>, [step(model)]
```

- **`step`** — a bare workflow name (e.g. `plan`, `execute`, `redteam`). Runs whatever model is currently in effect — the orchestrator's default, or the last `<model>` switch encountered in the chain.
- **`step!`** — a **required-success step**. If it ultimately fails (the normal review latitude still applies — a second attempt is fine), the orchestrator **halts the orchestration and escalates to the human** instead of running any later step. Guards a step everything downstream depends on — typically `execute!`, since auditing or closing a failed execution is pointless. Attaches after any `(model)` (`execute(opus)!`); optional `[steps]` can't take it.
- **`step(model)`** — a **per-step model override**. Spawn that step's subagent with the named model (`sonnet` / `opus` / `haiku` / `fable`). Applies to this step only and does not change the default for any other step.
- **`stepA+stepB`** — a **parallel group**. Steps joined by `+` dispatch as concurrent subagents; the chain waits for all members before continuing, and the orchestrator reviews them together. Members keep their own annotations — `audit(sonnet)+redteam(opus)`, `[audit]+redteam`.
- **`stepA & stepB`** — **glue**. Couples steps into one unit where the later step gates the earlier — a producer/checker pair (`execute & audit`). Unlike `,` (independent, run-and-move-on), glued members are judged together, which makes the pair the natural body of a `*` loop.
- **`| … |`** — **grouping**. Brackets a run of steps into a single unit so a suffix operator applies to the whole run, not just the last step.
- **`unit*N`** — **loop-til-success**. Repeat the preceding step or `| group |` up to N times, resuming/retrying each pass, until it succeeds — for a glued pair, until the checker is satisfied. Stop as soon as it passes; if it never does within N, escalate (§ Human Escalation). `| execute & audit |*3` runs execute→audit, and on each dissatisfied audit loops back to resume execute, up to 3 attempts.
- **`<model>`** — a **mid-chain model switch**. Changes the default model for every step that follows it in the chain, until the next `<model>` marker or the chain ends. It does not itself spawn a workflow step.
- **`[step]`** / **`[step(model)]`** — an **optional step**. This is the one sanctioned exception to "explicit workflow lists are literal" above: for a bracketed step, the orchestrator applies judgment — run it only if what's happened so far in the chain warrants it, skip it otherwise. Either way, record the decision (ran / skipped, and why) in the Completion Report. Unbracketed steps stay literal and mandatory regardless of this exception.

**Parallel-group safety.** Only group steps that won't collide. Read-only workflows (`audit`, `redteam`, `eval`, `review`, `explore`, `scan`) parallelize freely — they share the tree without mutating it. Mutating steps (`execute`, `patch`, `close`, `revise`) must not share a group unless each runs in its own worktree; otherwise the orchestrator serializes them and notes it in the Completion Report. Members don't see each other's output — never make one depend on another's.

Example: `plan(fable), <opus>, execute!, audit+redteam, [patch], close(sonnet)` — plan is forced onto fable for that step only; the default then switches to opus for everything that follows; `execute!` runs under opus and **must succeed** — if it fails, the orchestrator halts here and escalates to the human rather than auditing a broken execution; only on success do `audit` and `redteam` dispatch **in parallel** (both under opus), the chain waiting for both before proceeding; patch is optional and runs under opus only if the parallel review surfaced a small code-level issue; close is forced onto sonnet regardless of the opus default.

### Human Escalation

Escalate (pause and ask the human) when:
- Task intent is genuinely ambiguous after one inference attempt
- A review gate fails twice on the same workflow step, or a required-success (`step!`) step ultimately fails
- An irreversible action is about to occur that wasn't implied by the original task
- Required credentials, external access, or authority are unavailable
- A decision requires business/personal judgment the orchestrator cannot substitute for

Surface: what's done, what's blocking, what decision the human must make. Nothing more.

### Completion Report

After the chosen workflow path finishes, report to the human:
- What was accomplished (mapped back to the original task)
- What was deferred or skipped, and why
- Key decisions made mid-workflow (if any were non-default)
- Filenames of produced projex artifacts (walkthrough, log, etc.)

Keep it tight. The human does not need the workflow framework explained back to them.

---

## Inherited Rules (Not Overridden)

These come from `SKILL.md` and apply to the orchestrator and all its subagents. The orchestrator does not loosen, override, or re-specify them in handoffs — subagents will enforce them via the framework spec.

- No subagent nesting — subagents do not spawn subagents; only the orchestrator delegates
- Git operation discipline (one operation type per call; no mixed script + raw git; explicit paths only)
- Auxiliary-artifact commit policy (auxiliary workflows do not auto-commit — human/orchestrator approval required)
- Reference-by-filename rule (never by path)
- No absolute paths in projex documents
- Dehydrate authoring style

If honoring a rule would block the task, escalate to the human rather than bypassing it.
