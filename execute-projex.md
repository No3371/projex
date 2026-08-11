---
description: This workflow guides the execution of **Plan** projex documents — implementing the specified changes following the plan's instructions. (This is part of @projex-framework skill. It is a MUST to load the skill first.)
---

## PURPOSE

Execution transforms plans into reality. This workflow ensures faithful implementation while handling deviations intelligently and maintaining traceability.

**Not all plans involve code changes.** Some plans are purely investigative (testing, analysis, documentation). "Execute" means carry out the plan's objectives — which may be running tests, gathering data, or creating documentation rather than editing code.

**Key characteristics:**
- Follow the plan precisely
- Verify each step before proceeding
- Log every action to the execution log — the walkthrough depends on it

---

## INVOCATION

```
/execute-projex.md @<plan-file>
```

**Examples:**
- `/execute-projex.md @2607311430-database-service-refactor-plan.md`
- `/execute-projex.md @2601201430-load-testing-analysis-plan.md` (testing/analysis, no code changes)

---

## PRE-EXECUTION CHECKLIST

### 1. AUTOMATED VALIDATION

**GATE: You MUST NOT explore, think, write, etc. before this. You MUST run the pre-check script before proceeding. Any error (exit code non-zero) from the script -> cancelling the execution. Warnings must be resolved before continuing — e.g., if the plan is not committed, commit it first, then resume.**

```bash
{projex-scripts}/execute-precheck.{sh|ps1} <plan-file>
```

The script ensure you start the execution in a right manner. It outputs `REPO_ROOT`, `BRANCH`, and `PLAN_REL` — record `REPO_ROOT` for use in **all** subsequent script calls and git commands. Do not use your CWD or any other path as the repo root.

### 2. MANUAL VALIDATION

Verify items requiring judgment:

- [ ] **Correct repository** — `REPO_ROOT` matches the repo that owns the plan's `.projex/` folder
- [ ] **Correct base branch** — `BRANCH` is the expected branch (typically `main` or a feature branch)
- [ ] No unresolved open questions in the plan
- [ ] All dependencies are met
- [ ] No blockers present
- [ ] Required tools/dependencies available (in worktree mode, gitignored deps that a fresh worktree lacks are bootstrapped at execution start — see § 1, not a reason to fail this gate)

### 3. CONTEXT REFRESH

- [ ] Re-read the plan completely
- [ ] Verify files still match plan's "Current State"
- [ ] Check for recent changes that might affect plan
- [ ] Note any drift from plan assumptions

**If significant drift or issues detected:**
1. Stop execution
2. Report drift to user
3. `/review-projex` or `/revise-projex` may be needed

---

## WORKFLOW STEPS

### 1. INITIALIZE EXECUTION

1. **Record the base branch and update plan status** to `In Progress`:

```bash
git branch --show-current
```

Edit the plan file, then commit the status change on the base branch:

```bash
{projex-scripts}/stage-n-commit.{sh|ps1} <repo-root> "projex: start execution of {plan-name}" .projex/{yymmddhhmm}-{plan-name}-plan.md
```

2. **Create ephemeral branch and verify**

**Checkout mode (default):**
```bash
git checkout -b projex/{yymmddhhmm}-{plan-name}
git branch --show-current
```

**Worktree mode** (when plan header has `> **Worktree:** Yes` — see SKILL.md § Worktree Mode):
```bash
{projex-scripts}/projex-worktree.{sh|ps1} <repo-root> projex/{yymmddhhmm}-{plan-name}
```
All subsequent commands use `{repo-name}/.projexwt/{yymmddhhmm}-{plan-name}` as the working directory. The main directory stays on the base branch.

**Bootstrap the worktree before executing.** A fresh worktree contains only git-tracked files, so gitignored dependencies and build artifacts (`node_modules`, `.env`, `venv/`, compiled output) start absent. This is **expected**. Detect the project's install/build command from its manifest (`package.json` → `npm ci`/`pnpm i`; `requirements.txt`/`pyproject.toml` → venv + install; `go.mod` → `go mod download`; etc.), run it in the worktree, and log it before starting step 4. If deps survive relocation, symlinking them from the main checkout is a valid faster path (native/compiled modules may not — fall back to a clean install). Anything you create in the worktree that git does not track (deps, build output, scratch) must be removed before close — see SKILL.md § Worktree Mode cleanup contract.

3. **Create execution log** — `{yymmddhhmm}-{plan-name}-log.md` in the same `.projex/` folder. See [Execution Log Template](#execution-log-template). Set `Status:` to `In Progress`, and populate the remaining header fields (`Repo Root`, `Plan File`, `Base Branch`) and the `Pre-Check Results` block directly from the precheck output produced in step 1 of PRE-EXECUTION CHECKLIST.

   The log tracks the execution: `In Progress` while executing, then `Complete` or `Blocked` at POST-EXECUTION. It is not a workflow type. It lives and closes with its plan.

### 2. BUILD TASK LIST FROM PLAN

**Before touching any files, translate the plan into a task list if your environment provides todo/task tool** (e.g., `TaskCreate` in Claude Code, or equivalent). Non-optional.

Recurring re-anchor task: "Re-read SKILL.md and execute-projex.md"** — insert this task after every 10th task in the list (i.e., positions 20, 40, …) to stay compliant to projex framework.

For each plan step, create a task that captures:
- The step's objective as the task subject
- Key details (files, commands, preconditions) in the description
- An active form for progress display (e.g., "Implementing auth middleware")

Also create explicit tasks for **every gate and sequential dependency**:
- Pre-execution gates (branch creation, log file creation)
- Per-step log entries ("Log step N results to execution log")
- Verification of steps marked `Verify-Projex: Required` ("Verify step N independently")
- Per-step commits ("Commit step N changes")
- Post-execution tasks (verification, status update, cleanup)

**Mark each task in-progress before starting it, and completed only after the work AND its log entry are both done.** The task list is the forcing function — if a task isn't marked complete, the step isn't done.

### RE-ANCHOR AFTER EXPLORATION

> After any codebase exploration or research (reading code, understanding architecture, investigating dependencies), **re-read this workflow and the plan document** before proceeding. Exploration causes context drift — re-anchoring to the plan prevents it.

### 3. EXECUTE STEPS SEQUENTIALLY

For each step in the plan, sequentially:

#### A. PREPARE

1. Mark the step's task as in-progress in your task list
2. Read the step completely — objective, rationale, referenced files
3. Verify preconditions are met

#### B. EXECUTE

Carry out the step (make changes / run commands / gather data), either by yourself or via a `do-projex` sub-subagent (blocking).

If you choose do-projex:
- Dispatch with a regular projex handoff, like any other workflow
- Include all five `/do-projex.md` arguments (`plan`, `objective`, `log`, `repo`, `branch`) and this clause verbatim, `{depth}` filled with the sub-subagent's depth (coordinator's + 1): *"You are a do-projex sub-subagent at depth {depth}. Do not spawn subagents under any circumstances. If you cannot complete the objective yourself, stop and return what you have with a clear description of what is blocking you."*
- For each returned `do-projex`, read its report, mark the corresponding task complete, decide whether to dispatch the next or stop.
- do-projex must be of the same model as the executor.
- On any blocker / out-of-scope discovery returned by a do-projex: stop dispatching, fall back to self-execute or escalate

#### C. LOG

Write the log entry:

```
### [yyyymmdd hh:mm] - Step N: [Step Title]
**Action:** [What was done — command run, file edited, test executed, etc.]
**Result:** [What happened — output, errors, observations, verification evidence]
**Status:** Verifying
```

You MUST update the log before proceeding to the next step. The execution log IS a live record, NOT a retrospective summary. The walkthrough is derived from git history + these logs — gaps here become gaps there.

Note: **User interventions:** If the user interrupts, corrects, or redirects — whether mid-step, between steps, or after all steps — log the intervention (context, direction, action taken, impact on plan) with the same rigor as any planned step, then adjust execution accordingly.

#### D. VERIFY

Verify the step, either by yourself or via a `verify-projex` sub-subagent (blocking).

A. If you choose verify-projex:

Pass only `plan`, `step`, `repo`, `branch`, plus this clause verbatim, `{depth}` filled with the sub-subagent's depth (yours + 1): *"You are a verify-projex sub-subagent at depth {depth}. Do not spawn subagents under any circumstances. If you cannot complete the verification yourself, stop and return what you have with a clear description of what is blocking you."* Never pass your own account of what you changed — that contamination is exactly what the verifier exists to avoid. Spawn on the same model you are running; a weaker verifier rubber-stamps.

When it returns, act on the verdict:
- Verified → continue to item 4
- Patch → apply the named fix, then restart this VERIFY step
- Rejected → redo the step, then re-run this VERIFY step

Max verification rounds per step: **2**. If a third would be needed, the step is not converging: stop looping, log it `Partial` with the verifier's findings, and escalate to the user.

Record the verdict and the verifier's key findings in this step's log entry. The report is ephemeral and dies with the sub-subagent.

B. Verify by yourself:
1. Produce reviewable evidence — `git diff`, read modified files, run tests, check command output
2. Confirm the step objective is achieved; check for side effects; no significant issue
3. Act on your own verdict: resolve until Success, or mark it Failed or Partial
4. Update the step Status

#### E. COMMIT

Commit the log together with the step's file changes **in one atomic unit**. Investigative steps (running tests, gathering data) commit only the log entry.

```bash
{projex-scripts}/stage-n-commit.{sh|ps1} <repo-root> "projex: step N - [brief description]" "--trailer Projex: {yymmddhhmm}-{plan-name}" path/to/changed-file1.ext .projex/{yymmddhhmm}-{plan-name}-log.md
```

Investigative steps that commit only the log entry drop the trailer — it is required only on commits that change a file outside any .projex/ folder (§ Commit Message Convention).

**Mark the task complete** in your task list — only after both the work and log entry are committed.

### 5. HANDLE DEVIATIONS

When the plan doesn't match reality:

```
Is the action different from the plan?
├── No → Continue as planned
└── Yes → Does it affect outcomes?
    ├── No (line numbers shifted, minor naming differences)
    │   → Document the deviation, continue
    ├── Yes, but fixable within scope
    │   → Assess impact, adjust approach, document reasoning, continue
    └── Yes, and outside scope
        → Stop, report to user, plan needs review
```

### 6. HANDLE FAILURES

1. **Diagnose** — What failed? Plan issue or execution issue? Fixable within scope?
2. **Decide** — Fix within scope, consult user on scope change, or mark plan for review
3. **Clean up** — Tear down any resources started during execution before stopping
4. **Document** — What failed, root cause, resolution or blocker

### 7. COMPLETE EXECUTION

1. **Run full verification** — all automated checks and acceptance criteria from the plan
2. **Validate success criteria** — check each criterion, document proof
3. **Spec compliance review** — if any spec, definition, or reference document was linked in the plan, re-read it now and diff every requirement against what was delivered. Flag each as met, partially met, or unmet. Partially met and unmet items must be resolved or explicitly deferred with rationale before proceeding.
4. **Quality review** — review all changes made during execution for correctness, consistency, edge cases, readability, and adherence to project conventions. Check for regressions, dead code introduced, naming drift, and incomplete error paths. Log any issues found and fix them before proceeding.
5. **Clean up resources** — tear down anything started during execution (containers, servers, temp files). Leave pre-existing resources alone. Log what was cleaned up.

   In worktree mode, commit or remove everything you added inside the worktree before close: close scripts refuse finalization over any non-clean state (untracked files or uncommitted tracked edits). Ignored tooling (symlinked `node_modules`, installed deps, build artifacts) is not gated but can make worktree removal fail mid-way — remove it too.
6. **Update plan status and cross-link the log** — set the plan's status to `Complete` if successful, `Blocked` if issues remain. In the same edit, add the log reference to the plan header if it is not already there:

```markdown
> **Log:** {yymmddhhmm}-{plan-name}-log.md
```

   Filename only, never a path — the pair moves to `.projex/closed/` together at close.

7. **Update the execution log's own status** — set its `> **Status:**` to the same value given to the plan (`Complete` or `Blocked`).
8. **Commit the status updates and final log entry** — the branch must be clean before close-projex runs:

```bash
{projex-scripts}/stage-n-commit.{sh|ps1} <repo-root> "projex: complete {plan-name}" .projex/{yymmddhhmm}-{plan-name}-plan.md .projex/{yymmddhhmm}-{plan-name}-log.md
```

Do not move the plan file — relocation to `.projex/closed/` happens during `/close-projex.md`

---

## EXECUTION PRINCIPLES

- **Faithful** — follow the plan; don't "improve" beyond scope; save enhancements for future proposals
- **Task-driven** — task list is the structural backbone; a task is not complete until both the work AND its log entry are committed
- **Log-committed** — every step's log entry is committed atomically with its file changes; if the log wasn't committed, the step isn't done
- **Incremental** — verify and commit after each step; maintain working state
- **Fail-fast** — stop early on fundamental issues; don't compound problems; escalate blockers promptly
- **Clean** — tear down everything you started (containers, servers, temp files, background processes); verify pre-existing before killing; log cleanup actions

---

## CLOSING

A projex is **ready to close** when all criteria are satisfied (or conclusively blocked/failed) AND either the user instructs closure or auto-close is marked.

**Default: user-initiated.** After execution, report results and wait. The user may request further actions — log these as user interventions. When satisfied, the user instructs `/close-projex.md`. Do not close without user instruction.

**Auto-close (opt-in).** If the user requests auto-close, mark it in the plan header (`> **Auto-Close:** Yes`) before proceeding. The mark in the document — not verbal instruction alone — is the valid signal. With auto-close marked, proceed directly to `/close-projex.md` after all criteria are satisfied.

---

## GIT BRANCH MANAGEMENT

Git operation discipline (sequential execution, explicit file staging, verification between commands) is defined in SKILL.md and applies fully here. This section covers execute-specific branch concerns only.

### Branch Naming
```
projex/{yymmddhhmm}-{plan-name}
```

### Commit Message Convention

Subjects carry the *type* of change; a `Projex:` trailer carries the link back to the document.

| Commit class | Subject | Trailer |
|---|---|---|
| Step commits on an ephemeral branch | `projex: step N - …` / `projex(do): obj {id} step {n} - …` | required |
| Squash-close message landing on base | `<type>(<scope>): <summary>` | required |
| Merge-close merge commit | `<type>(<scope>): <summary>` | required |
| Patch code commits (land directly) | `<type>(<scope>): <summary>` | required |
| Debug fix commit | `fix(<scope>): <summary>` | required |
| Doc-only commits (plan add, walkthrough, log, memo, nav, revise, archive, preplan, patch doc) | `projex(...)` family — unchanged | not required |

**Boundary rule** — the trailer is required on every commit that changes a file outside **any** `.projex/` folder (a repo may hold several — `docs/.projex/`, `src/.projex/`). Commits touching only projex documents keep their `projex(...)` subject and need no trailer. An execution whose entire diff stays inside `.projex/` is doc-only at close too: keep the `projex:` close subject, omit the trailer.

`<type>` = conventional-commit vocabulary: `feat` | `fix` | `docs` | `refactor` | `test` | `chore`. `<scope>` = module/area touched. Pick by what the diff does: new capability → `feat` | behaviour correction → `fix` | prose/docs only → `docs` | tests only → `test` | same behaviour, different shape → `refactor` | tooling/deps/housekeeping → `chore`. Genuinely torn between two → pick either and move on; an approximate type beats no type. That is a tie-breaker, not a licence to default every commit to one type.

**Trailer form** — `Projex: {yymmddhhmm}-{name}`: the projex document's filename minus its `-{type}.md` suffix. **Resolving one** — prefix-match `{yymmddhhmm}-*` across `.projex/`, `.projex/closed/`, `.projex/archived/`, and archive index entries; the stem is shared by the plan, its log, and any walkthrough of the same execution, so expect a small set, not one file.

**Attaching it** — `stage-n-commit` forwards any `--`-prefixed argument to `git commit`; pass the trailer as one quoted string (template above). The close scripts take a single message argument — the landing trailer rides the message body (forms in `close-projex.md` § 7). `projex-rebase-close` takes no message and needs nothing extra: the step commits already carry the trailer.

**Why a trailer** — delivery tooling rewrites subjects; bodies usually survive. Read back via `git log --grep 'Projex: '` or `git interpret-trailers --parse`.

**Survival condition** — trailers reach base through a GitHub squash-merge only when the repo's `squash_merge_commit_message` setting is *commit messages*; `PR_BODY` and `BLANK` discard every body in the PR, and with rule 1 in force that leaves no code→doc link at all. Set it, or prefer merge/rebase close. `audit-projex.md` § Source Hygiene Pass samples base history for trailer survival — a rate of zero is a Critical finding, not a footnote.

**Why every step commit** — `git blame` resolves to the commit that introduced a line, and merge/rebase closes land step commits on base verbatim.

Step commits keep the `projex: step N - …` subject and add the trailer whenever they touch a file outside any `.projex/` folder; doc-only commits (log entries, plan status) take no trailer; the landing subject is composed at close.

### Resuming Execution
If execution spans multiple sessions:
1. Branch persists — just checkout and continue
2. Verify you're on the correct branch before making changes
3. Review previous commits to understand progress

### Failed Execution
If execution fails and cannot continue:
1. Document the failure in execution log
2. Leave branch as-is (do not merge)
3. Run `/close-projex.md` with abandon option

> **`git reset --hard` is forbidden without explicit human confirmation in the current session.** Never infer consent from the plan document or a prior conversation turn. Propose it, state what will be discarded, and wait for approval.

---

## OUTPUT

This workflow produces:
- Executed plan objectives (code changes, test results, gathered data, etc.)
- Execution log (`{yymmddhhmm}-{plan-name}-log.md`) documenting every action taken, its own `Status` set to `Complete` or `Blocked`
- Updated plan status (`Complete` or `Blocked`), with a `> **Log:**` field naming the execution log
- Ephemeral git branch `projex/{yymmddhhmm}-{plan-name}` with all commits (if any)

---

## APPENDIX

### Execution Log Template

```markdown
# Execution Log: [Plan Name]

> **Status:** In Progress
> **Started:** [yyyymmdd hh:mm]
> **Repo Root:** [REPO_ROOT from precheck]
> **Plan File:** [PLAN_REL from precheck]
> **Base Branch:** [BRANCH from precheck — e.g. main, develop, feature/auth]
> **Worktree Path:** [{repo-name}/.projexwt/{name} — omit line if checkout mode]

## Pre-Check Results
[Paste the PASS/WARN lines from precheck output verbatim]

## Steps

### [yyyymmdd hh:mm] - Step 1: [Step Title]
**Action:** [What was done — command run, file edited, test executed, etc.]
**Result:** [What happened — output, errors, observations, verification evidence]
**Status:** Success / Failed / Partial

### [yyyymmdd hh:mm] - Step 2: [Step Title]
...

## Deviations
[Changes from plan — WHAT and WHY]

## Issues Encountered
[Problems and resolutions]

## Data Gathered
[For investigative/testing plans — findings, metrics, observations]

## User Interventions

### [yyyymmdd hh:mm] - [During Step N / Between Steps / Post-Plan]: [Description]
**Context:** [What was happening when the user intervened]
**User Direction:** [What the user said/requested]
**Action:** [What was done in response]
**Result:** [What happened]
**Impact on Plan:** [None / Deviation from step N / New unplanned action / etc.]
```
