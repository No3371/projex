---
description: This workflow runs fast, disposable implementation spikes to collapse planning uncertainty, discards every experimental change, and preserves only concise evidence for plan-projex. (This is part of @projex-framework skill. It is a MUST to load the skill first.)
---

## PURPOSE

Preplans answer implementation questions cheaply before a real plan is written. Start a disposable worktree, make the smallest useful hacks, observe what matters, discard everything, then preserve a compact planning brief for `plan-projex`.

**Core rule: preplan code may be dirty; preplan evidence must be accurate.**

Preplan is optional. Use it when reading alone cannot settle approach, change surface, framework fit, or verification strategy. Skip it when the implementation path is already clear.

**Boundary:** Preplan discovers; Plan specifies. A preplan MUST NOT become a draft implementation plan or mergeable prototype.

---

## INVOCATION

```
/preplan-projex <idea, proposal, memo, or unclear objective>
```

**Examples:**
- `/preplan-projex Try the smallest raw-SQL replacement for one ORM query and see what the real migration surface looks like`
- `/preplan-projex @2602011430-plugin-system-proposal.md probe the proposed extension boundary`
- `/preplan-projex Find out whether esbuild fits the current asset pipeline before we plan a migration`
- `/preplan-projex Break one representative caller against the new parser API and learn what compatibility work is actually needed`

Inputs should precede a plan. A Ready plan is not a preplan input; revise the plan or abandon its execution instead of trial-running it here.

---

## FAST-AND-DIRTY CONTRACT

Optimize for **information gained per change**, not implementation quality. The worktree will be destroyed.

### REQUIRED DEFAULTS

- Make the smallest hack that answers the current question.
- Prefer hardcoded values, copied code, temporary instrumentation, partial implementations, and narrow representative paths.
- Ignore backward compatibility unless compatibility is itself a planning question.
- Run the narrowest check that can distinguish outcomes.
- Stop immediately when `plan-projex` can choose an approach and describe the real work.
- Record shortcuts and untested areas so prototype success is not mistaken for production readiness.

### DO NOT PRODUCTIONIZE

Unless required to answer the question, NEVER:

- preserve speculative backward compatibility
- design reusable abstractions or infrastructure
- complete adjacent behavior
- refactor unrelated code
- polish naming, errors, or user experience
- add documentation or migration machinery
- cover every edge case
- run a full test, build, or lint suite
- finish the feature because it is "almost done"

After every probe ask: **Can `plan-projex` now choose an approach and describe the real work?** Yes → stop. No → run the next cheapest discriminating probe.

---

## IRREVERSIBILITY GUARD

**CRITICAL: Every action must be undoable by discarding the preplan worktree. Fast and dirty does not relax safety.**

### ALLOWED

- Create, modify, or delete files inside the disposable worktree
- Run local builds, compilers, focused tests, or repository-local scripts
- Install worktree-local dependencies when a probe requires them
- Read files, documentation, and external resources through non-mutating requests

### FORBIDDEN

| Action | Why |
|--------|-----|
| `git push` | Exposes experimental changes |
| External API mutations | Remote state survives rollback |
| Persistent database writes or migrations | Worktree discard cannot undo them |
| Publishing packages or artifacts | Publication is externally visible |
| Notifications, webhooks, email, or chat messages | Cannot be unsent |
| Deployments | Affect running environments |
| Modifying files outside the worktree | Not isolated by branch discard |
| Destructive host commands | Affect state outside the experiment |
| Persistent external storage writes | Data outlives the preplan |

Uncertain reversibility → do not act. Record the skipped action and its speculative implication instead.

---

## WORKFLOW

### 1. FRAME PLANNING UNCERTAINTY

Resolve target repo from a referenced projex file or current context. Preplan requires a git-backed file corpus; without checkpoint + rollback guarantees, stop and recommend an analytical workflow.

Define only what the spike needs:

```
DECISION: [What plan-projex must be able to decide]
UNKNOWN:  [Specific uncertainty blocking that decision]
PROBE:    [Cheapest change or observation that discriminates options]
SIGNAL:   [Result that would support or reject each option]
```

Read enough current code to choose a representative path. Do not perform plan-grade exhaustive research first; the worktree exists to answer uncertainty quickly.

Record the base branch:

```bash
git -C <repo-root> branch --show-current
```

### 2. CREATE DISPOSABLE WORKTREE

Worktree mode is mandatory:

```bash
{projex-scripts}/projex-worktree.{sh|ps1} <repo-root> projex/preplan/{yymmddhhmm}-{preplan-name}
```

All changes and commands run from `{repo-name}/.projexwt/{yymmddhhmm}-{preplan-name}`. The main working directory and user changes remain untouched.

A fresh worktree contains only tracked files. Bootstrap only what the selected probe needs; missing ignored dependencies are expected, not a blocker.

### 3. RUN MINIMUM PROBES

For each probe:

1. State the assumption being tested.
2. Apply the cheapest representative hack.
3. Run one focused observation or check.
4. Record result, shortcut used, and planning implication.
5. Stop or choose the next cheapest discriminating probe.

Multiple approaches MAY be tried. Revert or overwrite experimental code freely. Do not clean it up. Do not broaden validation after the decision is supported.

Useful evidence: compile result for one target | focused test | runtime trace | representative caller breakage | dependency spread | API ergonomics | file churn | framework friction | failure shape.

**Evidence discipline:** Separate observed facts from inference. Mark unexecuted expectations as `[INFERENCE]`. A successful shortcut proves only the tested property, not production readiness.

### 4. CAPTURE AND DISCARD

Before discard, retain only decision-relevant facts:

- exact probe and shortcut
- focused command or scenario and result
- approach implication
- likely production change surface
- risks and untested areas

Full diffs, broad logs, and baseline matrices are unnecessary unless they directly support the decision.

Remove agent-created ignored tooling when needed, then abandon the worktree and branch:

```bash
{projex-scripts}/projex-abandon.{sh|ps1} <repo-root> {base-branch} projex/preplan/{yymmddhhmm}-{preplan-name} --worktree
```

Verify the worktree is removed, branch is deleted, and the base working directory was not changed. **Do not write the preplan artifact until rollback succeeds.**

### 5. WRITE COMPACT PREPLAN

Create the sole surviving artifact on the base branch:

```bash
Resolve `{parent}` from the explicit probe subject/source filename; else supplied orchestrator Parent; else `User`.
{projex-scripts}/new-projex.sh --repo-root <repo-root> --type preplan --title "{preplan-name}" --parent {parent} --projex-dir <projex-folder>
```
```powershell
{projex-scripts}\new-projex.ps1 -RepoRoot <repo-root> -Type preplan -Title "{preplan-name}" -Parent {parent} -ProjexDir <projex-folder>
```

```markdown
# Preplan: [Title]

> **Status:** Complete
> **Author:** [Model(Role), or Model, or self identity, fallback: "Agent"]
> **Source:** [proposal/memo filename or "Direct request"]
> **Related Projex:** [filenames or "None"]

---

## Decision Needed

[What the future plan needed to determine]

## Baseline

[Only current-state facts needed to interpret probes]

## Probes

| Assumption | Shortcut / Probe | Observed Result | Planning Implication |
|------------|------------------|-----------------|----------------------|
| [assumption] | [deliberately rough change] | [evidence] | [decision impact] |

## Recommended Direction

[Approach supported by evidence and why]

## Rejected Directions

- [Approach]: [observed reason]

## Likely Change Surface

- `path/to/file`: [probable production change]

## Production Risks

- [Risk hidden or accepted by the shortcut]

## Not Tested

- [Compatibility, edge case, integration, or broad validation deferred to planning/execution]

## Input for Plan

- **Objective:** [bounded real outcome]
- **Constraints:** [verified constraints]
- **Verification:** [checks the real implementation needs]
- **Open decisions:** None | [decision still requiring user input]
```

Keep it short. Omit empty sections except `Not Tested`; explicit omissions prevent dirty-spike evidence from being overread.

### 6. COMMIT AND LINK

Committing is structural: the worktree is gone and this artifact is the only surviving result.

```bash
{projex-scripts}/stage-n-commit.{sh|ps1} <repo-root> "projex(preplan): capture {preplan-name}" .projex/closed/{yymmddhhmm}-{preplan-name}-preplan.md
```

If sourced from another projex, add reciprocal filename-only relationships and commit those explicit paths. Do not edit a future Plan because none exists yet.

---

## QUALITY GATE

- [ ] Planning uncertainty was explicit
- [ ] Each probe was the cheapest useful discriminator
- [ ] Prototype shortcuts were deliberate, not hidden
- [ ] No production polish or speculative compatibility work slipped in
- [ ] Observations and inferences are distinguishable
- [ ] Untested production concerns are explicit
- [ ] Worktree and branch were discarded
- [ ] Base working directory was not changed
- [ ] Preplan artifact is concise and sufficient for `plan-projex`
- [ ] No irreversible action occurred

---

## OUTPUT

Closed preplan at `.projex/closed/{yymmddhhmm}-{name}-preplan.md`. Natural next step: `/plan-projex @{preplan-file}`. Preplan ends after presenting the artifact; it never starts planning or execution automatically.
