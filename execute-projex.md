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

- [ ] **In the correct repository** — Run `git rev-parse --show-toplevel` to see which repo root git is currently operating against (it returns the nearest repo root to cwd, not the outermost). Confirm the result matches the repo that owns the plan's `projex/` folder. In nested repo setups (submodules, subtrees, repos-inside-repos), git silently operates on whichever `.git` is closest to the cwd — always verify before creating branches or committing.
- [ ] On correct base branch (typically `main` or feature branch)
- [ ] Clean working state (no uncommitted changes)
- [ ] Git repository is in good state
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

**GATE: No file changes, no edits, no code modifications until the ephemeral branch is created and verified (step 1.2). Any change made on the base branch contaminates it and defeats isolation.**

### 1. INITIALIZE EXECUTION

1. **Record the base branch** — Before branching, record the current branch name. Close-projex needs this to merge back to the correct target.

```bash
git branch --show-current
# e.g. "main", "develop", "feature/auth" — this is the base branch
```

2. **Create ephemeral branch and verify** — Branch from current HEAD. Confirm the switch before proceeding.

```bash
git checkout -b projex/{yyyymmdd}-{plan-name}
# verify output: "Switched to a new branch 'projex/...'"
git branch --show-current
# verify output matches the ephemeral branch name — ONLY THEN proceed
```

3. **Update plan status** — Change to `In Progress`

4. **Commit plan status change** — First commit in the ephemeral branch:

```bash
git add projex/{yyyymmdd}-{plan-name}-plan.md
git commit -m "projex: start execution of {plan-name}"
```

5. **Create execution log** — File named `{yyyymmdd}-{plan-name}-log.md`, placed next to the plan file in the same `projex/` folder. See [Execution Log Template](#execution-log-template) for the format.

### 2. EXECUTE STEPS SEQUENTIALLY

For each step in the plan:

#### A. PRE-STEP

1. Read the step completely
2. Understand the objective and rationale
3. Locate all referenced files/resources
4. Verify preconditions are met

#### B. EXECUTE

**For implementation steps (code changes):**
1. Make the specified changes
2. Follow the plan's before/after code exactly
3. Match existing code style and conventions

**For investigative steps (testing/analysis/documentation):**
1. Run the specified commands/tests
2. Gather the specified data/metrics
3. Document findings as they occur

#### C. VERIFY

1. Run the step's verification method
2. Confirm the step objective is achieved
3. Check for unintended side effects

#### D. COMMIT (if applicable)

After each step that produces file changes, commit in logical atomic units:

```bash
# Stage each changed file by explicit path — never use `git add .`, `git add -A`, `git add -u`, or directories
git add path/to/changed-file1.ext
git add path/to/changed-file2.ext
git commit -m "projex: step N - [brief description]"
```

Steps that are purely investigative (running tests, gathering data) need no commits — just log the actions and findings.

#### E. LOG

Update the execution log with what was done, what happened, any deviations from the plan, and verification results. Do this for every step — implementation or investigative.

#### F. USER INTERVENTION (when applicable)

If the user interrupts, corrects, or redirects during step execution:

1. **Log the intervention immediately** — Record what the user said, which step was active, and the context
2. **Adjust execution accordingly** — Follow the user's direction
3. **Log the adjusted action and outcome** — Document what changed vs. the original step plan
4. **Note the deviation** — If the intervention changes the plan's approach, record it as a deviation

User interventions are first-class execution events. They are decisions that shaped the outcome and must appear in the walkthrough.

### 3. HANDLE DEVIATIONS

When the plan doesn't match reality:

```
Is the action different from the plan?
├── No → Continue as planned
└── Yes → Does it affect outcomes?
    ├── No (line numbers shifted, minor naming differences, output format differences)
    │   → Document the deviation, continue
    ├── Yes, but fixable within scope (file structure changed, dependencies missing, approach needs adjustment)
    │   → Assess impact, adjust approach, document reasoning, continue
    └── Yes, and outside scope (plan assumptions fundamentally wrong, significant architectural changes, unanticipated blockers)
        → Stop, report to user, plan needs review/update
```

### 4. HANDLE FAILURES

If a step fails:

1. **Diagnose** — What specifically failed? Plan issue or execution issue? Fixable within scope?
2. **Decide:**
   - **Fixable within scope:** Fix and document
   - **Requires scope change:** Stop, consult user
   - **Plan is wrong:** Stop, mark plan for review
3. **Clean up resources** — Before stopping or consulting the user, tear down any services/processes started during execution (Docker containers, dev servers, etc.). Don't leave resources running while waiting for decisions.
4. **Document** — What failed, root cause, resolution or blocker

### 5. COMPLETE EXECUTION

After all steps:

1. **Run full verification plan** — All automated checks, manual verifications, and acceptance criteria from the plan

2. **Validate success criteria** — Check each criterion, document proof of satisfaction

3. **Final review** — Review all actions taken, check for anything left incomplete

4. **Clean up resources** — Tear down anything started during execution: stop Docker containers/compose stacks, kill dev servers, close database connections, remove temporary files/directories, etc. If a resource was running before execution began (pre-existing), leave it alone. Log what was cleaned up.

5. **Update plan status** — Mark as `Complete` if successful, `Blocked` if issues remain

**Note:** Do not move the plan file yet — file relocation to `projex/closed/` happens during `/close-projex.md`

---

## EXECUTION PRINCIPLES

### Faithful Implementation
- Follow the plan unless there's a clear reason not to
- Don't "improve" beyond plan scope during execution
- Save enhancement ideas for future proposals/plans

### Aggressive Logging
- Log every action to the execution log — not just code changes, but commands executed, files inspected, tests run, data gathered, observations made
- Log immediately after each step, not retrospectively — delayed logging loses detail
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
Started: [timestamp]
Base Branch: [branch name recorded at step 1.1 — e.g. main, develop, feature/auth]

## Progress
- [ ] Step 1: [title]
- [ ] Step 2: [title]
...

## Actions Taken

### [Timestamp] - Step 1: [Step Title]
**Action:** [Exactly what was done - command run, file edited, test executed, etc.]
**Output/Result:** [What happened - output, errors, observations]
**Files Affected:** [List any files read/modified/created]
**Verification:** [How verified - what was checked]
**Status:** Success/Failed/Partial

### [Timestamp] - Step 2: [Step Title]
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

### [Timestamp] - [During Step N / Between Steps / Post-Plan]: [Description]
**Context:** [What was happening when the user intervened]
**User Direction:** [What the user said/requested]
**Action:** [Exactly what was done in response]
**Output/Result:** [What happened]
**Files Affected:** [List any files read/modified/created]
**Impact on Plan:** [None / Deviation from step N / New unplanned action / etc.]
```
