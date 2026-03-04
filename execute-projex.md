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
- `/execute-projex.md @20260731-database-service-refactor-plan.md`
- `/execute-projex.md @20260120-load-testing-analysis-plan.md` (testing/analysis, no code changes)

---

## PRE-EXECUTION CHECKLIST

Before starting execution:

### 1. PLAN VALIDATION

- [ ] **Plan is committed to base branch** — Plan document must exist in git history
- [ ] Plan status is `Ready`
- [ ] No unresolved open questions
- [ ] All dependencies are met
- [ ] No blockers present

> **Why must the plan be committed?**
> Plans are documentation that should exist independently of execution. If execution is abandoned, the plan remains for future attempts. This also enables plan review before execution.

### 2. ENVIRONMENT CHECK

**Resolve the target repo from the plan file's path** (see SKILL.md § Repo Resolution), then verify:

```bash
git branch --show-current
```
```bash
git status
```

- [ ] **Correct base branch** — shows the expected branch (typically `main` or a feature branch)
- [ ] **Clean working state** — no uncommitted changes
- [ ] Required tools/dependencies available
- [ ] Access to all files listed in plan

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

**GATE: No implementation changes until the ephemeral branch is created and verified (step 1.2).**

### 1. INITIALIZE EXECUTION

1. **Record the base branch and update plan status** to `In Progress`:

```bash
git branch --show-current
```

Edit the plan file, then commit the status change on the base branch:

```bash
{projex-scripts}/projex-commit.{sh|ps1} <repo-root> "projex: start execution of {plan-name}" projex/{yyyymmdd}-{plan-name}-plan.md
```

2. **Create ephemeral branch and verify**

```bash
git checkout -b projex/{yyyymmdd}-{plan-name}
git branch --show-current
```

3. **Create execution log** — `{yyyymmdd}-{plan-name}-log.md` in the same `projex/` folder. See [Execution Log Template](#execution-log-template).

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

### 3. EXECUTE STEPS SEQUENTIALLY

For each step in the plan:

#### A. PREPARE

1. Mark the step's task as in-progress in your task list
2. Read the step completely — objective, rationale, referenced files
3. Verify preconditions are met

#### B. EXECUTE

1. Carry out the step (make changes / run commands / gather data)

#### C. LOG AND VERIFY

**GATE: The log entry for this step must be written before starting the next step. The execution log is a live record, not a retrospective summary. The walkthrough is derived from git history + these logs — gaps here become gaps there.**

1. **Log the action** — write the step header, **Action**, and **Files Affected** fields by referencing the tool outputs just produced
2. Produce reviewable evidence — `git diff`, read modified files, run tests, check command output
3. Confirm the step objective is achieved; check for side effects
4. **Log the results** — fill **Output/Result**, **Verification**, and **Status** by referencing the tool outputs just produced, not from memory
5. **Mark the objective complete** — update `- [ ] Step N: [title]` to `- [x] Step N: [title]` in the log's `## Progress` section
6. **Mark the task complete** in your task list — only after both the work and log entry are done

#### D. COMMIT (if applicable)

Commit file changes in logical atomic units. Investigative steps (running tests, gathering data) need no commits — just log findings.

```bash
{projex-scripts}/projex-commit.{sh|ps1} <repo-root> "projex: step N - [brief description]" path/to/changed-file1.ext path/to/changed-file2.ext
```

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
3. **Final review** — check for anything left incomplete
4. **Clean up resources** — tear down anything started during execution (containers, servers, temp files). Leave pre-existing resources alone. Log what was cleaned up.
5. **Update plan status** — `Complete` if successful, `Blocked` if issues remain

Do not move the plan file — relocation to `projex/closed/` happens during `/close-projex.md`

---

## EXECUTION PRINCIPLES

- **Faithful** — follow the plan; don't "improve" beyond scope; save enhancements for future proposals
- **Task-driven** — task list is the structural backbone; a task is not complete until both the work AND its log entry are written
- **Aggressively logged** — live document, not retrospective; log commands, inspections, tests, observations — not just code changes
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
projex/{yyyymmdd}-{plan-name}
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

---

## OUTPUT

This workflow produces:
- Executed plan objectives (code changes, test results, gathered data, etc.)
- Execution log (`{yyyymmdd}-{plan-name}-log.md`) documenting every action taken
- Updated plan status (`Complete` or `Blocked`)
- Ephemeral git branch `projex/{yyyymmdd}-{plan-name}` with all commits (if any)

---

## APPENDIX

### Execution Log Template

```markdown
# Execution Log: [Plan Name]
Started: [yyyymmdd hh:mm]
Base Branch: [branch name recorded at step 1.1 — e.g. main, develop, feature/auth]

## Progress
- [ ] Step 1: [title]
- [ ] Step 2: [title]
...

## Actions Taken

### [yyyymmdd hh:mm] - Step 1: [Step Title]
**Action:** [Exactly what was done - command run, file edited, test executed, etc.]
**Output/Result:** [What happened - output, errors, observations]
**Files Affected:** [List any files read/modified/created]
**Verification:** [How verified - what was checked]
**Status:** Success/Failed/Partial

### [yyyymmdd hh:mm] - Step 2: [Step Title]
[Same structure]

## Actual Changes (vs Plan)
- `file.ext`: [actual change] — matches plan / differs because [reason]

## Deviations
[Track any changes from plan — WHAT and WHY]

## Unplanned Actions
[Actions taken that weren't in the plan — WHY]

## Planned But Skipped
[Planned actions not taken — WHY]

## Issues Encountered
[Document problems and resolutions]

## Data Gathered
[For investigative/testing plans - record findings, metrics, observations]

## User Interventions
[User interruptions, corrections, redirections, and requests — at any point during execution]

### [yyyymmdd hh:mm] - [During Step N / Between Steps / Post-Plan]: [Description]
**Context:** [What was happening when the user intervened]
**User Direction:** [What the user said/requested]
**Action:** [Exactly what was done in response]
**Output/Result:** [What happened]
**Files Affected:** [List any files read/modified/created]
**Impact on Plan:** [None / Deviation from step N / New unplanned action / etc.]
```
