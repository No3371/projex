---
description: Objective-scoped execution within an active plan execution. Ceremony-stripped (no branch creation, no plan status updates, no pre-check, no completion gate) — execution-log discipline and git guardrails preserved. Invoked ONLY by execute-projex sub-subagents. (This is part of @projex-framework skill. It is a MUST to load the skill first.)
---

## PURPOSE

`do-projex` carries out a **single objective** from a plan whose execution is already in flight. The parent `/execute-projex.md` has already:

- Run pre-check, created the ephemeral branch / worktree
- Created the execution log with populated header
- Built the task list

`do-projex` is the worker contract for one objective — designed to be invoked from sub-subagents spawned by the execute-projex coordinator so each objective starts with fresh, undrifted context.

**Use only via execute-projex delegation.** Standalone or human-direct invocation is not supported. For one-off small changes use `/patch-projex.md`; for whole-plan execution use `/execute-projex.md`.

**Key characteristics:**

- Scoped: one objective, named explicitly by the caller
- No ceremony: no branch creation, no plan status changes, no pre-check, no completion gate
- Log-strict: every sub-step writes a log entry, atomically committed with its file changes
- Guardrail-strict: full git discipline + framework rules apply unchanged

---

## INVOCATION

```
/do-projex.md plan=<plan-file> objective=<id-or-title> log=<log-file> repo=<repo-root> branch=<ephemeral-branch>
```

All five fields required — caller (the execute-projex coordinator) supplies them.

- `plan` — plan filename (e.g. `2607311430-database-service-refactor-plan.md`)
- `objective` — exact objective identifier from the plan (step number, milestone heading, or objective title)
- `log` — execution log filename to append to
- `repo` — repo root absolute path (used for all script + git calls)
- `branch` — ephemeral branch (already checked out, or worktree path equivalent)

Caller must have already created branch, log file, and committed the plan's `In Progress` status.

---

## PRE-CONDITIONS (CALLER GUARANTEES)

Do not re-validate. If any look wrong, **stop and report back to the caller**; do not "fix" them yourself.

- [ ] Repo at `repo-root`, working on `branch` (checkout or worktree)
- [ ] Plan committed on base branch
- [ ] Execution log file exists with header populated
- [ ] Caller serializes do-projex sub-subagents — no concurrent writers on this log/branch

---

## WORKFLOW STEPS

### 1. ANCHOR

1. Read `SKILL.md` and this file (`do-projex.md`)
2. Read the plan file in full — even though only one objective is in scope, plan-level context, constraints, and cross-objective dependencies still apply
3. Locate the named `objective` in the plan. Note its sub-steps, target files, preconditions, success criteria
4. Read the existing execution log to understand what prior objectives produced

If the objective cannot be located unambiguously → stop and report.

### 2. EXECUTE SUB-STEPS

For each sub-step inside the objective:

#### A. PREPARE
- Verify preconditions (files, branch state, outputs from prior objectives)
- Missing precondition → stop and report; do not improvise

#### B. EXECUTE
- Carry out the sub-step (edit / run / gather)
- Comments written into source obey § SOURCE HYGIENE below — a deliberate second copy of `SKILL.md § Source Hygiene`, kept here so the rules survive any context loss on the sub-subagent boundary

#### C. LOG, VERIFY, COMMIT
- Evidence: `git -C {repo} diff`, command output, test result, file re-read — not memory
- Confirm sub-step intent achieved; check side effects within the objective's scope
- **Append a log entry** under the log's existing `## Steps` section:

```
### [yyyymmdd hh:mm] - Objective {id}, Step {n}: [Title]
**Action:** [What was done]
**Result:** [What happened]
**Status:** Success / Failed / Partial
```

- **Atomic commit** — sub-step file changes + log entry, one call:

```bash
{projex-scripts}/stage-n-commit.{sh|ps1} <repo-root> "projex(do): obj {id} step {n} - [brief]" "--trailer Projex: {yymmddhhmm}-{plan-name}" path/to/changed.ext .projex/{log-filename}
```

Investigative sub-steps commit the log entry alone. Log-only commits drop the trailer.

### 3. OBJECTIVE COMPLETION

When all sub-steps for this objective are done:

1. Append a closing entry to the log:

```
### [yyyymmdd hh:mm] - Objective {id} Complete
**Sub-steps:** {n} / {total}
**Status:** Success / Partial / Failed
**Notes:** [deviations, follow-ups, anything the parent coordinator should know]
```

2. Commit it:

```bash
{projex-scripts}/stage-n-commit.{sh|ps1} <repo-root> "projex(do): obj {id} complete" .projex/{log-filename}
```

3. **Stop.** Do not advance to adjacent objectives. Do not update plan status. Do not run plan-wide verification or cleanup. Return control to the caller.

---

## DEVIATIONS / FAILURES

Same decision frame as `execute-projex`, narrowed by one rule:

> **Any deviation outside this objective's scope → stop and report to the caller.** Do not self-extend into adjacent objectives even if they look related. The coordinator decides whether to dispatch a follow-up `do-projex` or escalate.

In-scope failures:
1. Diagnose
2. Fixable within scope → fix; log the fix as its own sub-step
3. Not fixable → log the failure with root cause; do not clean up cross-objective state; return blocked to caller

---

## OUT OF SCOPE — LEAVE TO PARENT execute-projex

- Creating / removing ephemeral branches or worktrees
- Creating the execution log or populating its header
- Building task lists / re-anchor scheduling
- Updating plan status (`In Progress` / `Complete` / `Blocked`)
- Plan-wide verification, acceptance criteria, spec compliance review
- Cleanup of plan-wide resources (containers, servers, temp files)
- Triggering `/close-projex.md`
- Stash, branch finalization, merge, rebase

If any of these seem necessary → stop and report.

---

## RETURN CONTRACT

On exit (success, partial, or blocked), report to the parent coordinator:

- Objective id + final status (Success / Partial / Failed / Blocked)
- Sub-steps completed: `{n} / {total}`
- Commit SHAs produced
- Any deviation noted in the log
- Any out-of-scope discovery the coordinator should act on

Keep it tight — the log holds the full detail.

---

## SOURCE HYGIENE

Deliberate copy of `SKILL.md § Source Hygiene` — do-projex is the highest-comment-volume path in the framework and this spec is what its agent is guaranteed to have. Redundant by design: edit either copy and update the other.

**Subject.** *Source* = files a program or build consumes: code, config, schemas, scripts. *Comment* = a construct the language ignores at runtime. Prose files (`.md`, docs, specs) are shipped documentation — rule 1's promotion target — and are outside these rules unless a retrofit sweep names them. Bind every workflow that edits source (execute, do, patch, debug). Enforcement: `audit-projex.md` § Source Hygiene Pass.

1. **No projex references in sources** — no projex ID, filename, or section pointer in a comment. Projexs are authoring layer artifacts, and should be invisible in the product. **Promotion:** load-bearing rationale that exists only in a projex document belongs in a shipped doc (README, spec, ADR) — promotion is the only channel that survives archival compression. Referencing a *shipped* doc from a comment is fine; the ban is on workflow artifacts.
2. **Symbols, not line numbers** — name the function, const, or type; never `file:123` or bare `:123`. `file:ln` stays correct inside projex documents — they are point-in-time records.
3. **Present tense** — what the code does, not what it used to do. Live hazard: state the hazard, not the changelog.
4. **No plan shape in code** — no `// Step N:`, no `====` / `----` banners.
5. **Reassurance must warn** — "deliberate" / "by design" only with the rejected alternative and its consequence.
6. **Non-obvious decisions carry rationale** — a rejected alternative, surprising constraint, or don't-fix trap gets a self-contained comment. Naming none of the three is not compliance — a rationale comment that asserts without naming what it rejected is as much a violation as its absence.

**No density or length caps.** Long comment blocks are not a violation; thinning comments to reach zero findings is (rule 6).


## GIT DISCIPLINE

All rules from `SKILL.md § Git Operation Discipline` apply unchanged. Most relevant here:

- One operation type per call
- Stage by explicit path only
- Use `stage-n-commit` — never raw `git add` + `git commit`
- `git reset --hard` requires explicit human confirmation in the current session

`do-projex` does not branch, merge, rebase, or stash. If any of those seem necessary → stop and report.

---

## OUTPUT

No standalone document. `do-projex` produces:

- Commits on the existing ephemeral branch (objective changes + log entries)
- Appended entries in the existing execution log
- A completion report returned to the parent execute-projex coordinator
