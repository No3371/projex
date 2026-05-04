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
- `@./patch-projex.md` — quick-action for small, well-understood changes
- `@./eval-projex.md` — open-ended analysis
- `@./review-projex.md` — inspection of existing projex against status quo
- `@./redteam-projex.md` — adversarial analysis
- `@./audit-projex.md` — validation of completed work
- `@./interview-projex.md` — interactive Q&A rounds
- `@./explore-projex.md` — status-quo-grounded investigation
- `@./imagine-projex.md` — generative vision from a seed
- `@./simulate-projex.md` — disposable execution with rollback
- `@./log-projex.md` — standalone change record
- `@./memo-projex.md` — lightweight capture
- `@./navigate-projex.md` — living roadmap
- `@./map-projex.md` — living structural index
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
- **Which workflow to invoke** — e.g. `/plan-projex.md`, `/execute-projex.md`
- **Path to the relevant workflow spec and `SKILL.md`** — so the subagent can load them
- **Prior projex artifacts** — by **filename** (not path), e.g. `2604151200-auth-feature-plan.md`
- **Facts already established** — human-confirmed scope boundaries, worktree preference, merge strategy, any constraint the orchestrator has already decided or cleared with the human

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

### Mid-Workflow Decisions

The orchestrator owns decisions a human user would normally make:
- Which workflow to invoke next (or whether to stop)
- Whether a plan is ready to execute
- Whether execution is complete enough to close
- Merge strategy at close (squash / merge / abandon)
- Whether to commit auxiliary artifacts (per `SKILL.md` policy — only if the human would agree)

Default to the workflow spec's own defaults. Deviate only when the human's task clearly requires it.

### Human Escalation

Escalate (pause and ask the human) when:
- Task intent is genuinely ambiguous after one inference attempt
- A review gate fails twice on the same workflow step
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
