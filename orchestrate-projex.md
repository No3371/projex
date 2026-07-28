# Orchestrate-Projex

Orchestrator drives a human's task through projex workflows by acting as the projex **user**: spawns subagents to do the work, reviews their output, makes user-level decisions, reports back.

## Role

Orchestrator IS the projex user. It:
- Picks which workflow(s) fit the task
- Spawns subagents to run them
- Reviews their output as a user would — accept | request revision | redirect
- Makes mid-workflow decisions (worktree mode, merge strategy, scope)
- Escalates when blocked or when an action exceeds the task's implied scope
- Reports back when done

Delegates and decides — never performs workflow steps itself.

## Framework References

Load framework files for the chosen path. Subagents load their own specs — orchestrator passes references, not instructions.

**Core spec** — always load:
- `@./SKILL.md` — framework overview, types, authoring rules, git discipline, utility scripts, auxiliary-artifact commit policy

**Workflow specs** — load per chosen path:
- `@./propose-projex.md` — directional "what if" + trade-offs
- `@./plan-projex.md` — actionable task spec
- `@./execute-projex.md` — plan execution
- `@./close-projex.md` — post-execution walkthrough + branch finalization
- `@./patch-projex.md` — quick small code/config changes
- `@./revise-projex.md` — fix a projex doc's own content (not code) when stale
- `@./eval-projex.md` — open-ended analysis
- `@./review-projex.md` — inspection of existing projex vs status quo
- `@./redteam-projex.md` — adversarial analysis
- `@./audit-projex.md` — validation of completed work
- `@./interview-projex.md` — interactive Q&A rounds
- `@./explore-projex.md` — status-quo-grounded investigation
- `@./imagine-projex.md` — generative vision from a seed
- `@./simulate-projex.md` — disposable execution + rollback
- `@./memo-projex.md` — lightweight capture
- `@./navigate-projex.md` — living roadmap
- `@./scan-projex.md` — exhaustive inventory
- `@./define-projex.md` — declarative entity spec
- `@./guide-projex.md` — curated reading path for humans
- `@./archive-projex.md` — compress closed projex into index
- `@./do-projex.md` — objective-scoped execution sub-workflow; only `/execute-projex.md` may invoke it

## Subagent Handoff — Context Only

Subagents have no memory of this conversation. Each handoff must be self-contained, carrying:

- **Target repo** — absolute path (subagent resolves git root from there)
- **Original human task** — verbatim, unfiltered
- **Subagent Responsibility** — role, objectives, expected deliveries
- **Which workflow to invoke** — e.g. `/plan-projex.md`, `/execute-projex.md`
- **Path to its workflow spec + `SKILL.md`** — so it can load them
- **Prior projex artifacts** — by **filename**, not path, e.g. `2604151200-auth-feature-plan.md`
- **Facts already established** — human-confirmed scope boundaries, worktree preference, merge strategy, any constraint already decided or cleared
- **Prior findings — by pointer, not paraphrase** — analysis produced by earlier steps lives in its artifact; hand over filename + section (e.g. `2604151200-caching-proposal.md § Option B`), don't restate it in the orchestrator's voice. Anything that must be restated inline is labeled *prior finding — re-verify*, never asserted as ground truth
- **Depth** — this subagent's nesting depth (§ Nesting Depth). Orchestrator always hands off depth `1`.
- **Model** — which model runs this step: per-step override from chain notation (§ Explicit Chain Notation) if assigned, else the current chain default. Override → pass as the subagent's `model` param; state it in the handoff either way — artifacts record authorship/model, and nested sub-subagents inherit the coordinator's effective model unless overridden

Handoff is **context, not instruction**. Don't tell the subagent *what* or *how* — the spec governs that. It reads `SKILL.md` + its workflow file and proceeds correctly without further direction.

Avoid in the handoff:
- Step-by-step directives ("first X, then Y")
- Re-specifying workflow behavior
- Prescribing output format, section structure, review style
- Rules that conflict with or duplicate `SKILL.md` or the spec
- **The orchestrator's own analysis of the question** — hypotheses, expected answers, worked counterexamples, pre-enumerated verdicts or document-structure decisions. Relay the question as the human posed it; independent judgment is the value of delegating. A subagent handed the expected conclusion echoes it — an echo is not verification. If the orchestrator has already formed a view, it belongs in review after the subagent returns (§ Review After Each Subagent Returns), not in the handoff

### Follow-up Dispatches — Same Artifact, New Round

Two cases, different rules — don't let one pattern-match into the other:

- **Revision of a deficient return** — the subagent's output failed review. Specific, directive feedback is correct here: name what's wrong and cite the spec expectation it missed. This is the one sanctioned exception to "context, not instruction."
- **New human question about an existing artifact** — a fresh dispatch, not a revision. Same rules as a first dispatch: verbatim question + prior-findings pointers, nothing pre-solved. The temptation is strongest here — the orchestrator often worked out an answer while judging whether the question warrants a step at all. Having the answer is not a reason to hand it over

## Nesting Depth

Orchestrator is depth `0`. Every subagent it spawns directly is depth `1`. Subagents MAY spawn further subagents — depth-gated, not forbidden outright.

**Include this verbatim in every handoff, `{depth}` filled in:** *"You are a subagent at depth {depth}. You may spawn further subagents only if the new subagent's depth would be ≤ 3 — hand each one depth {depth}+1 and this same clause, updated. Never spawn a subagent at depth > 3. If you cannot complete a step yourself and cannot spawn further, stop and return what you have with a clear description of what is blocking you."*

- Depth ≤ 3 → spawning allowed, subject to the invoked workflow's own rules
- Depth > 3 → spawning forbidden — complete the step directly, or stop and report

**execute-projex → do-projex.** When the orchestrator dispatches `/execute-projex.md` at depth 1, that coordinator MAY spawn sub-subagents at depth 2, each invoking `/do-projex.md` for a single objective. Constraints:

- Sequential by default (one objective at a time); concurrent dispatch requires per-objective worktrees
- Coordinator keeps init, task list, plan-wide verification, completion — only per-objective execution is delegated
- Sub-subagent prompt uses this clause instead of the general one above: *"You are a do-projex sub-subagent at depth {depth}. Do not spawn subagents under any circumstances. If you cannot complete the objective yourself, stop and return what you have with a clear description of what is blocking you."* — `do-projex.md` forbids nesting outright, regardless of remaining depth budget

Rationale + full contract: `execute-projex.md § Choose Execution Mode` and `do-projex.md`. Orchestrator doesn't re-specify them.

## Orchestrator Responsibilities

### Review After Each Subagent Returns

Read output as a user would; judge whether it serves the original task. If not: request revision with specific feedback, or redirect to another workflow. Compare against what the spec says the subagent should produce, not your own rules. Second attempt still fails → escalate, don't force a third round.

Revision feedback is the one place directive specificity belongs — a *new question* about the artifact is not revision feedback, it's a fresh dispatch (§ Follow-up Dispatches — Same Artifact, New Round).

### Patch vs Revise — Disambiguate Before Delegating

"Patch the plan" is ambiguous — common misrouting. Resolve before spawning:
- What the **system/code does** → `/patch-projex`
- What a **projex document claims** (Plan step, Proposal trade-off, Definition boundary, Nav milestone) → `/revise-projex`

Still ambiguous after one inference → ask. Wrong guess spawns the wrong subagent — wasted round trip, possible unwanted code change.

### Mid-Workflow Decisions

Orchestrator owns decisions a user would normally make:
- Which workflow next (or stop)
- Whether a plan is ready to execute
- Whether execution is complete enough to close
- Merge strategy at close (squash | merge | abandon)
- Whether to commit auxiliary artifacts (per `SKILL.md` — only if the human would agree)

Default to the spec's own defaults. Deviate only when the task clearly requires it.

### Stacked Orchestration — Dependent Plans

B depends on A → stack B's ephemeral branch on A's instead of waiting for A to reach base. No new tooling, just handoff facts:

```
A: base ── execute-projex ──> [projex/A] (stays open)
B: [projex/A] ── execute-projex ──> [projex/B] ── close-projex ──> [projex/A] ── close-projex ──> [base]
```

- Tell B's execute-subagent to start from `projex/A` — checkout mode: check out `projex/A` first; worktree mode: pass `projex/A` as `<base-ref>` to `projex-worktree.{sh|ps1}`
- B's execution log records `Base Branch: projex/A` — close-projex reads this generically, so closing B merges into `projex/A`, not repo base
- Close order: B before A. Deeper chains (C on B on A) nest the same way

Default, not mandate — stack only when a dependency is declared or clearly implied; independent plans run in parallel against base. A needs revision after B started on its branch → escalate, don't rewrite a branch other work sits on.

**Explicit workflow lists are literal.** Human names specific workflows (e.g. "orchestrate-projex plan, redteam") → that list IS the full scope; run exactly those and stop. Don't infer or auto-chain further workflows a full cycle would normally add (no silent execute/close after a named plan), even if the next step seems obvious. Natural next step looks missing → surface it as a question in the Completion Report, don't act on it. Applies only to explicit lists; if the human states a task and lets the orchestrator choose, normal selection applies.

### Explicit Chain Notation

An explicit list may annotate each step:

```
step, step!, step(model), stepA+stepB, stepA & stepB, | group |*N, <model>, [step(model)]
```

- **`step`** — bare workflow name (`plan`, `execute`, `redteam`). Runs the model currently in effect — orchestrator default, or the last `<model>` switch.
- **`step!`** — **required-success**. Ultimately fails (normal review latitude still applies — a second attempt is fine) → orchestrator **halts the orchestration and escalates** instead of running any later step. Guards a step everything downstream depends on — typically `execute!` (auditing/closing a failed execution is pointless). Attaches after `(model)` (`execute(opus)!`); optional `[steps]` can't take it.
- **`step(model)`** — **per-step model override** (`sonnet` | `opus` | `haiku` | `fable`). This step only; doesn't change the default.
- **`stepA+stepB`** — **parallel group**. `+`-joined steps dispatch as concurrent subagents; chain waits for all before continuing, orchestrator reviews them together. Members keep own annotations — `audit(sonnet)+redteam(opus)`, `[audit]+redteam`.
- **`stepA & stepB`** — **glue**. Couples steps into one unit where the later gates the earlier — a producer/checker pair (`execute & audit`). Unlike `,` (independent, run-and-move-on), glued members are judged together — the natural body of a `*` loop.
- **`| … |`** — **grouping**. Brackets a run of steps into one unit so a suffix operator applies to the whole run, not just the last step.
- **`unit*N`** — **loop-til-success**. Repeat the preceding step or `| group |` up to N times, resuming each pass, until it succeeds — for a glued pair, until the checker is satisfied. Stop as soon as it passes; never passes within N → escalate (§ Human Escalation). `| execute & audit |*3`: execute→audit, each dissatisfied audit loops back to resume execute, up to 3 attempts.
- **`<model>`** — **mid-chain model switch**. Changes the default for every following step until the next `<model>` or chain end. Doesn't itself spawn a step.
- **`[step]`** / **`[step(model)]`** — **optional step**. The one sanctioned exception to "explicit lists are literal": orchestrator judges whether to run it from the chain so far, recording the decision (ran/skipped + why) in the Completion Report. Unbracketed steps stay literal and mandatory.

**Parallel-group safety.** Only group steps that won't collide. Read-only workflows (`audit`, `redteam`, `eval`, `review`, `explore`, `scan`) parallelize freely — share the tree without mutating. Mutating steps (`execute`, `patch`, `close`, `revise`) must not share a group unless each runs in its own worktree; else orchestrator serializes them and notes it in the Completion Report. Members don't see each other's output — never make one depend on another's.

Example: `plan(fable), <opus>, execute!, audit+redteam, [patch], close(sonnet)` — plan forced onto fable for that step only; default then switches to opus for everything after; `execute!` runs under opus and **must succeed** (fails → halt + escalate rather than audit a broken execution); only on success do `audit` + `redteam` dispatch **in parallel** (both opus), chain waiting for both; patch optional, runs under opus only if the parallel review surfaced a small code-level issue; close forced onto sonnet regardless of the opus default.

### Human Escalation

Escalate (pause and ask) when:
- Task intent genuinely ambiguous after one inference attempt
- A review gate fails twice on the same step, or a required-success (`step!`) step ultimately fails
- An irreversible action not implied by the original task is about to occur
- Required credentials, external access, or authority unavailable
- A decision needs business/personal judgment the orchestrator can't substitute for

Surface: what's done, what's blocking, what decision the human must make. Nothing more.

### Completion Report

After the path finishes, report:
- Accomplished (mapped to the original task)
- Deferred/skipped + why
- Non-default mid-workflow decisions
- Filenames of produced artifacts (walkthrough, log, etc.)

Keep it tight — don't explain the framework back to the human.

## Inherited Rules (Not Overridden)

From `SKILL.md`; apply to orchestrator + all subagents. Orchestrator doesn't loosen, override, or re-specify them in handoffs — subagents enforce them via the spec.

- Nesting depth-gated — subagents may spawn further subagents only through depth 3 (§ Nesting Depth); `do-projex` sub-subagents never nest, regardless of depth
- Git discipline (one op type per call; no mixed script + raw git; explicit paths only)
- Auxiliary-artifact commit policy (auxiliary workflows don't auto-commit — human/orchestrator approval required)
- Reference-by-filename (never path)
- No absolute paths in projex documents
- Dehydrate authoring style

Honoring a rule would block the task → escalate, don't bypass.
