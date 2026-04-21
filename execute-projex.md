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

**GATE: Do not explore the codebase, check git status, read source files, or make any assumptions about the target repository before running the pre-check script and completing workflow step1: INITIALIZE EXECUTION. Any error (exit code non-zero) from the script means cancelling the execution. Warnings must be resolved before continuing — e.g., if the plan is not committed, commit it first, then resume.**

### 1. AUTOMATED VALIDATION

Run the pre-check script — this is the **first action**, before anything else:

```bash
{projex-scripts}/execute-precheck.{sh|ps1} <plan-file>
```

The script makes sure you are starting execution in a right manner. It outputs `REPO_ROOT`, `BRANCH`, and `PLAN_REL` — record `REPO_ROOT` for use in **all** subsequent script calls and git commands. Do not use your CWD or any other path as the repo root.

### 2. MANUAL VALIDATION

Verify items requiring judgment (script output provides context for the first two):

- [ ] **Correct repository** — `REPO_ROOT` matches the repo that owns the plan's `.projex/` folder
- [ ] **Correct base branch** — `BRANCH` is the expected branch (typically `main` or a feature branch)
- [ ] No unresolved open questions in the plan
- [ ] All dependencies are met
- [ ] No blockers present
- [ ] Required tools/dependencies available

### 3. CONTEXT REFRESH

- [ ] Re-read the plan completely
- [ ] Verify files still match plan's "Current State"
- [ ] Check for recent changes that might affect plan
- [ ] Note any drift from plan assumptions

**If significant drift detected:**
1. Stop execution
2. Report drift to user
3. Plan may need `/review-projex.md` and updates

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
All subsequent commands use `{repo-name}.projexwt/{yymmddhhmm}-{plan-name}` as the working directory. The main directory stays on the base branch.

3. **Create execution log** — `{yymmddhhmm}-{plan-name}-log.md` in the same `.projex/` folder. See [Execution Log Template](#execution-log-template). Populate the header fields (`Repo Root`, `Plan File`, `Base Branch`) and the `Pre-Check Results` block directly from the precheck output produced in step 1 of PRE-EXECUTION CHECKLIST.

### 2. BUILD TASK LIST FROM PLAN

**Before touching any files, translate the plan into a task list using your environment's todo/task tool** (e.g., `TaskCreate` in Claude Code, or equivalent). This is not optional — the task list is the structural backbone that prevents skipped steps and forgotten log entries.

For each plan step, create a task that captures:
- The step's objective as the task subject
- Key details (files, commands, preconditions) in the description
- An active form for progress display (e.g., "Implementing auth middleware")

Also create explicit tasks for **every gate and sequential dependency**:
- Pre-execution gates (branch creation, log file creation)
- Per-step log entries ("Log step N results to execution log")
- Per-step commits ("Commit step N changes")
- Post-execution tasks (verification, status update, cleanup)

**Mark each task in-progress before starting it, and completed only after the work AND its log entry are both done.** The task list is the forcing function — if a task isn't marked complete, the step isn't done.

### RE-ANCHOR AFTER EXPLORATION

> After any codebase exploration or research (reading code, understanding architecture, investigating dependencies), **re-read this workflow and the plan document** before proceeding. Exploration causes context drift — re-anchoring to the plan prevents it.

### 3. EXECUTE STEPS SEQUENTIALLY

For each step in the plan:

#### A. PREPARE

1. Mark the step's task as in-progress in your task list
2. Read the step completely — objective, rationale, referenced files
3. Verify preconditions are met

#### B. EXECUTE

1. Carry out the step (make changes / run commands / gather data)

#### C. LOG, VERIFY, AND COMMIT

**GATE: The log entry for this step must be written before starting the next step. The execution log is a live record, not a retrospective summary. The walkthrough is derived from git history + these logs — gaps here become gaps there.**

1. Produce reviewable evidence — `git diff`, read modified files, run tests, check command output
2. Confirm the step objective is achieved; check for side effects
3. **Write the log entry** for this step using the inline template below, referencing tool outputs just produced — not from memory:

```
### [yyyymmdd hh:mm] - Step N: [Step Title]
**Action:** [What was done — command run, file edited, test executed, etc.]
**Result:** [What happened — output, errors, observations, verification evidence]
**Status:** Success / Failed / Partial
```

4. **Commit the log together with the step's file changes** in one atomic unit. Investigative steps (running tests, gathering data) commit only the log entry.

```bash
{projex-scripts}/stage-n-commit.{sh|ps1} <repo-root> "projex: step N - [brief description]" path/to/changed-file1.ext .projex/{yymmddhhmm}-{plan-name}-log.md
```

5. **Mark the task complete** in your task list — only after both the work and log entry are committed

**User interventions:** If the user interrupts, corrects, or redirects — whether mid-step, between steps, or after all steps — log the intervention (context, direction, action taken, impact on plan) with the same rigor as any planned step, then adjust execution accordingly.

### 4. HANDLE DEVIATIONS

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

### 5. HANDLE FAILURES

1. **Diagnose** — What failed? Plan issue or execution issue? Fixable within scope?
2. **Decide** — Fix within scope, consult user on scope change, or mark plan for review
3. **Clean up** — Tear down any resources started during execution before stopping
4. **Document** — What failed, root cause, resolution or blocker

### 6. COMPLETE EXECUTION

1. **Run full verification** — all automated checks and acceptance criteria from the plan
2. **Validate success criteria** — check each criterion, document proof
3. **Spec compliance review** — if any spec, definition, or reference document was linked in the plan, re-read it now and diff every requirement against what was delivered. Flag each as met, partially met, or unmet. Partially met and unmet items must be resolved or explicitly deferred with rationale before proceeding.
4. **Quality review** — review all changes made during execution for correctness, consistency, edge cases, readability, and adherence to project conventions. Check for regressions, dead code introduced, naming drift, and incomplete error paths. Log any issues found and fix them before proceeding.
5. **Clean up resources** — tear down anything started during execution (containers, servers, temp files). Leave pre-existing resources alone. Log what was cleaned up.
6. **Update plan status** — `Complete` if successful, `Blocked` if issues remain
7. **Commit the status update and final log entry** — the branch must be clean before close-projex runs:

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
- Prefix with `projex:` for traceability
- Reference step number when applicable
- Keep messages concise but descriptive

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
- Execution log (`{yymmddhhmm}-{plan-name}-log.md`) documenting every action taken
- Updated plan status (`Complete` or `Blocked`)
- Ephemeral git branch `projex/{yymmddhhmm}-{plan-name}` with all commits (if any)

---

## APPENDIX

### Execution Log Template

```markdown
# Execution Log: [Plan Name]
Started: [yyyymmdd hh:mm]
Repo Root: [REPO_ROOT from precheck]
Plan File: [PLAN_REL from precheck]
Base Branch: [BRANCH from precheck — e.g. main, develop, feature/auth]
Worktree Path: [{repo-name}.projexwt/{name} — omit line if checkout mode]

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
