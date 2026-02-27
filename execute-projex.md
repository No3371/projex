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
- `/execute-projex.md @20260115-auth-session-timeout-plan.md`
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

Run all three git checks in a **single parallel call** — they are independent reads with no dependencies:

```bash
git rev-parse --show-toplevel && git branch --show-current && git status
```

Then verify:
- [ ] **Correct repository** — `rev-parse --show-toplevel` matches the repo that owns the plan's `projex/` folder. In nested repo setups (submodules, subtrees, repos-inside-repos), git silently operates on whichever `.git` is closest to the cwd — always verify before creating branches or committing.
- [ ] **Correct base branch** — `branch --show-current` shows the expected branch (typically `main` or a feature branch)
- [ ] **Clean working state** — `git status` shows no uncommitted changes
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
git add projex/{yyyymmdd}-{plan-name}-plan.md
git commit -m "projex: start execution of {plan-name}"
```

2. **Create ephemeral branch and verify**

```bash
git checkout -b projex/{yyyymmdd}-{plan-name}
git branch --show-current
```

3. **Create execution log** — `{yyyymmdd}-{plan-name}-log.md` in the same `projex/` folder. See [Execution Log Template](#execution-log-template).

### 2. EXECUTE STEPS SEQUENTIALLY

For each step in the plan:

#### A. PREPARE

1. Read the step completely — objective, rationale, referenced files
2. Verify preconditions are met

#### B. EXECUTE AND LOG ACTION

1. Carry out the step (make changes / run commands / gather data)
2. **Log immediately** — write the step header, **Action**, and **Files Affected** fields while the action is fresh

#### C. VERIFY AND LOG RESULTS

1. Produce reviewable evidence — `git diff`, read modified files, run tests, check command output
2. Confirm the step objective is achieved; check for side effects
3. **Log from actual output** — fill **Output/Result**, **Verification**, and **Status** by referencing the tool outputs just produced, not from memory
4. **Mark the objective complete** — update `- [ ] Step N: [title]` to `- [x] Step N: [title]` in the log's `## Progress` section. This must happen before moving to the next step.

#### D. COMMIT (if applicable)

Commit file changes in logical atomic units. Investigative steps (running tests, gathering data) need no commits — just log findings.

```bash
git add path/to/changed-file1.ext
git add path/to/changed-file2.ext
git commit -m "projex: step N - [brief description]"
```

**User interventions:** If the user interrupts, corrects, or redirects — log the intervention (context, direction, action taken, impact on plan) with the same rigor as any planned step, then adjust execution accordingly.

### 3. HANDLE DEVIATIONS

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

### 4. HANDLE FAILURES

1. **Diagnose** — What failed? Plan issue or execution issue? Fixable within scope?
2. **Decide** — Fix within scope, consult user on scope change, or mark plan for review
3. **Clean up** — Tear down any resources started during execution before stopping
4. **Document** — What failed, root cause, resolution or blocker

### 5. COMPLETE EXECUTION

1. **Run full verification** — all automated checks and acceptance criteria from the plan
2. **Validate success criteria** — check each criterion, document proof
3. **Final review** — check for anything left incomplete
4. **Clean up resources** — tear down anything started during execution (containers, servers, temp files). Leave pre-existing resources alone. Log what was cleaned up.
5. **Update plan status** — `Complete` if successful, `Blocked` if issues remain

Do not move the plan file — relocation to `projex/closed/` happens during `/close-projex.md`

---

## EXECUTION PRINCIPLES

### Faithful Implementation
- Follow the plan unless there's a clear reason not to
- Don't "improve" beyond plan scope during execution
- Save enhancement ideas for future proposals/plans

### Aggressive Logging
- Log every action to the execution log — not just code changes, but commands executed, files inspected, tests run, data gathered, observations made
- Log immediately after each step, not retrospectively — delayed logging loses detail
- **Mark each objective complete** — after verifying a step succeeded, update its `## Progress` checkbox to `[x]` before starting the next step. An unchecked box means the step is not done.
- **Log all user interventions** — interruptions, corrections, redirections, and post-plan requests are execution events, not afterthoughts. Whether the user intervenes mid-step, between steps, or after all steps are done, log it with the same rigor as any planned action
- The walkthrough will be derived from git history + these logs; gaps in the log become gaps in the walkthrough

### Incremental Progress
- Verify after each step
- Commit logical units for code changes
- Maintain working state when possible

### Fail Fast
- Stop early if fundamental issues arise
- Don't compound problems
- Escalate blockers promptly

### Clean Up After Yourself
- Any process/service started during execution must be stopped before execution ends — whether it succeeds, fails, or is abandoned
- Docker containers, compose stacks, dev servers, database instances, background processes, temporary files — all must be torn down
- If unsure whether something was pre-existing, check before killing it
- Log all cleanup actions in the execution log

---

## CLOSING

### Ready to Close

A projex is **ready to close** when BOTH conditions are met:
1. **All criteria satisfied** — success/acceptance criteria are met (or execution is conclusively blocked/failed)
2. **Allowed to close** — user has explicitly instructed to close, OR the projex is marked as auto-close

### Default: User-Initiated Close

By default, closing requires explicit user instruction. After execution completes:

1. Report execution results to the user
2. User reviews the results (changes/findings/data)
3. **User may request further actions** — adjustments, fixes, additional changes. These are still part of this execution and must be logged in the execution log just like any mid-execution user intervention
4. When the user is satisfied, they instruct to close
5. Run `/close-projex.md` to create walkthrough document

**Do not close without user instruction.** The agent reports readiness; the user decides when to close.

### Auto-Close (Opt-In)

If the user explicitly instructs the agent to auto-close upon completion, the agent must mark this in the plan document's header before proceeding:

```markdown
> **Auto-Close:** Yes
```

When auto-close is marked, the agent may proceed directly to `/close-projex.md` after all criteria are satisfied, without waiting for user instruction. **The only valid signal for auto-close is this mark in the projex document** — verbal instruction alone is not sufficient; it must be recorded in the document.

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

### Branch Lifetime
- Created at execution start
- Exists throughout execution (may span sessions)
- Finalized (merged/abandoned) during `/close-projex.md`

---

## OUTPUT

This workflow produces:
- Executed plan objectives (code changes, test results, gathered data, etc.)
- Execution log (`{yyyymmdd}-{plan-name}-log.md`) documenting every action taken
- Updated plan status (`Complete` or `Blocked`)
- Ephemeral git branch `projex/{yyyymmdd}-{plan-name}` with all commits (if any)

**Git state after execution:**
```
{base-branch}
  └── projex/{yyyymmdd}-{plan-name}  ← you are here
        ├── commit: start execution
        ├── commit: step 1 - ...
        ├── commit: step 2 - ...
        └── commit: step N - ...
```

---

## NOTES

- Execution is about following the plan, not making design decisions
- If you find yourself making many deviations, the plan may need review
- Trust the plan but verify against reality
- Use relative paths when referencing repository files
- All execution happens in ephemeral branch — base branch stays clean until close

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
