---
description: Independent, read-only verification of a single executed plan step. Spawned by execute-projex in self-execute mode, before the step's commit. Writes nothing, commits nothing — returns a verdict and findings to the executor. Invoked ONLY by execute-projex sub-subagents. (This is part of @projex-framework skill. It is a MUST to load the skill first.)
---

## PURPOSE

`verify-projex` checks **one plan step** that the execute-projex agent implemented itself, before that step is committed.

Self-verification is the weak link in self-execute mode. The executor holds every assumption it made while implementing the step — which files it judged in scope, what it believed an edit accomplished, why it skipped something. Those assumptions are what needs checking, and the agent holding them cannot check them. `verify-projex` arrives with none of that context.

Mirror of `do-projex`: that workflow delegates the **doing**, this one delegates the **checking**. Both are ceremony-stripped and return-only. `do-projex` writes and commits; `verify-projex` touches nothing.

**Use only via execute-projex delegation.** Standalone or human-direct invocation is not supported. For post-hoc validation as a durable document, use `/audit-projex.md`.

**Key characteristics:**

- Scoped by the plan step, not the diff
- Read-only: no edits, no staging, no commits, no branch operations
- Blocking: the executor waits for the verdict before logging and committing
- Ephemeral: no document; the executor folds the report into the execution log

---

## INVOCATION

```
/verify-projex.md plan=<plan-file> step=<id-or-title> repo=<repo-root> branch=<ephemeral-branch>
```

All four fields required — the executor supplies them.

- `plan` — plan filename (e.g. `2607311430-database-service-refactor-plan.md`)
- `step` — exact step identifier from the plan (step number or title)
- `repo` — repo root absolute path, used for all read commands
- `branch` — ephemeral branch currently checked out, or worktree path equivalent

**The handoff excludes the executor's account of its own work.** No summary of changes, no rationale, no file list, no self-assessed status. Receiving any of those defeats the purpose. If the caller supplies them, ignore them and derive everything from the plan and the repo.

Spawn on the **same model** as the executor. A verifier weaker than the implementer rubber-stamps.

---

## PRE-CONDITIONS (CALLER GUARANTEES)

Do not re-validate. If any look wrong, **stop and report back to the caller**; do not fix them yourself.

- [ ] Repo at `repo-root`, working on `branch` (checkout or worktree)
- [ ] The step's changes are in the working tree and **not yet committed** — this runs pre-commit
- [ ] The step has no execution-log entry yet; it is written after this verdict returns
- [ ] Caller blocks on the return — no concurrent execution during this run

---

## WORKFLOW STEPS

### 1. ANCHOR

1. Read `SKILL.md` and this file (`verify-projex.md`)
2. Read the plan file in full — step-level context is not enough to judge scope or side effects
3. Locate the named `step`. Note its stated targets, preconditions, rationale, and `**Verification:**` field
4. Read the execution log for what **prior** steps produced. The current step is deliberately absent

If the step cannot be located unambiguously → stop and report.

### 2. ESTABLISH EXPECTED STATE — BEFORE LOOKING AT THE WORK

From the plan step alone, state what must be true for the step to be done: which files must exist or change, what behaviour must hold, what the stated verification method should produce.

**Do this before inspecting the working tree.** Expectations derived after seeing the diff produce rationalization, not verification — whatever was done starts to look like what was intended. Committing to the expected state first is what makes the § 4 comparison mean anything.

### 3. OBSERVE ACTUAL STATE

Gather evidence. Never memory, never inference from the diff alone:

- Read the step's target files as they now stand
- Run the step's stated `**Verification:**` method
- Use `git diff` / `git status` as **evidence**, not as the definition of scope
- Check for collateral change: edits outside the step's stated targets

**Scope is the step, not the diff.** A diff-scoped check sees only what changed; it cannot catch a step that required four edits and produced three. Work backwards from what the step demanded. Treat anything the diff shows beyond that as a separate finding.

### 4. COMPARE AND ISSUE A VERDICT

Compare § 3 against § 2. One of three:

- **Verified** — expected state fully realized, stated verification passes, nothing changed outside scope
- **Patch** — intent achieved, but a small well-defined defect remains that the executor can fix in place without redoing the step. Name the exact change
- **Rejected** — intent not achieved, verification fails, the approach is wrong, or required work is missing. Name the root cause and what a correct approach looks like

**When a step cannot be verified** — no runnable check, criteria too vague to test, tooling absent — say so plainly and pick the verdict the gathered evidence supports. Never return **Verified** on a claim you could not test. An untested step is an open question, and the executor needs to know which parts of the verdict rest on evidence and which on its absence.

The verdict judges **conformance to the step**, not the quality of the plan. A misconceived step is a finding to report, not grounds for Rejected.

### 5. REPORT

The report is the only artifact this workflow produces. The executor reads it and folds it into the execution log, so **substance beats brevity** — unlike `do-projex`, no log holds the detail behind you. An unexplained verdict is worthless. The analysis is the deliverable.

Return:

- **Verdict** — Verified / Patch / Rejected
- **What the step required** — the expected state from § 2
- **What was found** — evidence: files read, command and test output, diff observations. Quote real output; never paraphrase results you did not see
- **Where they diverge** — specific, with `file:ln` references
- **For Patch** — exactly what to change, and where
- **For Rejected** — root cause, and what a correct approach looks like
- **Unverifiable aspects** — what you could not test, and why
- **Out-of-scope observations** — collateral edits, side effects, plan-quality concerns. Flagged, never acted on

---

## READ-ONLY CONTRACT

No writes of any kind:

- No file edits or creations
- No `git add`, `git commit`, or any staging
- No branch, merge, rebase, stash, or checkout operations
- No execution-log entries — the executor owns the log
- No `stage-n-commit` or any other projex write script

Running the step's stated verification (tests, builds, linters) is expected, even when it writes to build or test output directories. Nothing under version control may change. If a verification method requires mutating tracked state, **do not run it** — report the step as unverifiable by that method and say why.

All rules from `SKILL.md § Git Operation Discipline` apply; only read commands are available here. If any write seems necessary → stop and report.

---

## OUT OF SCOPE — LEAVE TO THE EXECUTOR

- Fixing anything, however trivial
- Verifying adjacent steps, even when the defect appears to originate there
- Plan-wide verification, acceptance criteria, spec compliance review (`execute-projex.md` § 7)
- Writing log entries, committing, updating plan status
- Branch, worktree, or resource cleanup
- Deciding whether execution continues

If any of these seem necessary → report it and let the executor act.

---

## CALLER-SIDE LOOP (FOR REFERENCE)

Owned by `execute-projex`, documented here so the contract reads whole:

- **Verified** → executor writes its log entry and commits the step
- **Patch** → executor applies the named fix, then re-spawns verification on the same step
- **Rejected** → executor redoes the step, then re-spawns verification

Bounded at **two verification rounds per step**. A third round means the step is not converging: the executor logs it `Partial` with the verifier's findings attached and escalates to the user.

---

## BOUNDARY vs `audit-projex`

Adjacent, not interchangeable:

| | `verify-projex` | `audit-projex` |
|---|---|---|
| Trigger | Machine — spawned mid-execution | Human — requested after the fact |
| Scope | One plan step | Whole body of completed work |
| Timing | Before the step's commit | Post-hoc |
| Output | Ephemeral report to the executor | Durable `.projex/` document |
| Effect | Gates the commit | Informs the user |

Adversarial posture is shared. Everything else differs.

---

## OUTPUT

No document. No commits. No file changes.

`verify-projex` produces one verdict-plus-findings report returned to the parent execute-projex agent. Ephemeral by design — if any of it must persist, the executor carries it into the step's execution-log entry.
