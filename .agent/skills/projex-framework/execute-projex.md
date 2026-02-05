---
description: This workflow guides the execution of **Plan** projex documents — implementing the specified changes following the plan's instructions. (This is part of @projex-framework skill. It is a MUST to load the skill first.)
---

## PURPOSE

Execution transforms plans into reality. This workflow ensures faithful implementation while handling deviations intelligently and maintaining traceability.

**CRITICAL: Not all plans involve code changes.** Some plans are purely investigative (testing, analysis, documentation). Execution means "carry out the plan's objectives" — which may be running tests, gathering data, or creating documentation rather than editing code.

**Key characteristics:**
- Follow the plan precisely
- Execute plan objectives (may or may not involve code changes)
- Document EVERY action taken with aggressive detail
- Verify each step before proceeding
- Track complete execution history for walkthrough creation

---

## INVOCATION

```
/execute-projex.md @<plan-file>
```

**Examples:**
- `/execute-projex.md @20260731-database-service-refactor-plan.md` (code changes)
- `/execute-projex.md @20260115-auth-session-timeout-plan.md` (code changes)
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

### 1. INITIALIZE EXECUTION

1. **Create ephemeral branch** — Branch from current HEAD for isolated execution:

```bash
# Branch naming: projex/{yyyymmdd}-{plan-name}
git checkout -b projex/20260126-database-refactor
```

2. **Update plan status** — Change to `In Progress`

3. **Commit plan status change** — First commit in the ephemeral branch:

```bash
git add <plan-file>
git commit -m "projex: start execution of {plan-name}"
```

4. **Create execution log** — Track EVERY action taken:

```markdown
# Execution Log: [Plan Name]
Started: [timestamp]

## Progress
- [ ] Step 1: [title]
- [ ] Step 2: [title]
...

## Actions Taken (AGGRESSIVE LOGGING)
[Log EVERY action - commands run, files read, tests executed, analysis performed]

### [Timestamp] - Step 1: [Step Title]
**Action:** [Exactly what was done - command run, file edited, test executed, etc.]
**Output/Result:** [What happened - output, errors, observations]
**Files Affected:** [List any files read/modified/created]
**Verification:** [How verified - what was checked]
**Status:** Success/Failed/Partial

### [Timestamp] - Step 2: [Step Title]
[Same structure]

## Actual Changes (vs Plan)
[For implementation plans with code changes]
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
```

> **CRITICAL: Log EVERY action aggressively.** Not just code changes — commands executed, files inspected, tests run, data gathered, observations made. The walkthrough depends on knowing exactly what happened.

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
4. Add comments where the plan specifies

**For investigative steps (testing/analysis/documentation):**
1. Run the specified commands/tests
2. Gather the specified data/metrics
3. Make the specified observations
4. Document findings as they occur

**Log EVERY action immediately:**
- Command executed: exact command string
- Files read/inspected: which files, what was learned
- Tests run: which tests, what results
- Data gathered: what metrics, what values
- Observations made: what was noticed

#### C. VERIFY

1. Run the step's verification method
2. Confirm the step objective is achieved
3. Check for unintended side effects
4. For code changes: ensure code compiles/lints cleanly
5. For investigative work: verify data completeness

#### D. DOCUMENT

**Log the complete step execution:**
- What was actually done (exact actions)
- Results/output/findings
- How it differs from plan (if at all)
- Why it differs (if applicable)
- Issues encountered and resolutions
- Verification results
- Timestamp of completion

> **The walkthrough will be derived from git history + these action logs.** Be exhaustively specific about every action taken.

### 3. HANDLE DEVIATIONS

When the plan doesn't match reality:

**Minor Deviations** (proceed with adjustment):
- Slight code differences that don't affect approach
- File line numbers shifted
- Naming conventions evolved
- Commands produce slightly different output format

```
Document: "Deviated from plan: [what changed] because [why]"
```

**Moderate Deviations** (pause and assess):
- File structure changed
- Dependencies missing
- Approach needs minor adjustment
- Test results unexpected but interpretable

```
Action: Assess impact, adjust approach, document reasoning, continue
```

**Major Deviations** (stop execution):
- Plan assumptions fundamentally wrong
- Significant architectural changes since plan
- Blockers not anticipated in plan
- Cannot achieve plan objectives with current approach

```
Action: Stop, report to user, plan needs review/update
```

### 4. STEP-BY-STEP COMPLETION

After each step:

1. Mark step complete in tracking
2. **Commit changes if any were made** — Logical atomic units with descriptive messages:

```bash
git add <changed-files>
git commit -m "projex: step N - [brief description]"
```

**Note:** Only commit if files were actually changed. For investigative/testing steps with no code changes, no commits are needed — just log the actions taken.

3. Verify overall progress
4. Check if next step preconditions are met

**Commit message convention:**
- Prefix with `projex:` for traceability
- Reference step number when applicable
- Keep messages concise but descriptive

### 5. HANDLE FAILURES

If a step fails:

#### Diagnose
1. What specifically failed?
2. Is it a plan issue or execution issue?
3. Can it be fixed without changing plan scope?

#### Decide
- **Fixable within scope:** Fix and document
- **Requires scope change:** Stop, consult user
- **Plan is wrong:** Stop, mark plan for review

#### Document
Always document:
- What failed
- Root cause
- Resolution or blocker

### 6. COMPLETE EXECUTION

After all steps:

1. **Run full verification plan**
   - All automated checks
   - All manual verifications
   - All acceptance criteria

2. **Validate success criteria**
   - Check each criterion from the plan
   - Document proof of satisfaction

3. **Final review**
   - Review all actions taken
   - For code changes: check for any cleanup needed
   - For investigative work: verify all data collected
   - Ensure nothing was left incomplete

4. **Update plan status**
   - Mark as `Complete` if successful
   - Mark as `Blocked` if issues remain

**Note:** Do not move the plan file yet — file relocation to `projex/closed/` happens during `/close-projex.md`

---

## EXECUTION PRINCIPLES

### Faithful Implementation
- Follow the plan unless there's a clear reason not to
- Don't "improve" beyond plan scope during execution
- Save enhancement ideas for future proposals/plans

### Aggressive Logging
- Log EVERY action taken, not just changes
- Log commands, outputs, observations, findings
- Log immediately, not retrospectively
- Detail matters — exact commands, exact files, exact results

### Incremental Progress
- Verify after each step
- For code changes: commit logical units
- Maintain working state when possible

### Clear Documentation
- Track everything for the walkthrough
- Explain deviations with reasoning
- Note lessons learned in real-time

### Fail Fast
- Stop early if fundamental issues
- Don't compound problems
- Escalate blockers promptly

---

## PLAN TYPE GUIDANCE

### Implementation Plans (Code Changes)
- Create/modify/delete code files
- Commit changes after each step
- Verify compilation/linting
- Focus on matching plan's code specifications

### Investigative Plans (Testing/Analysis)
- Run tests/commands
- Gather data/metrics
- Make observations
- Document findings
- Usually NO code commits (unless documenting findings in files)

### Documentation Plans
- Create/update documentation files
- Commit documentation changes
- Verify accuracy and completeness
- May involve reading code but not changing it

### Hybrid Plans
- Some steps modify code, some investigate
- Commit code changes as made
- Log investigative actions thoroughly
- Treat each step according to its type

---

## DEVIATION DECISION TREE

```
Is the action different from the plan?
├── No → Continue as planned
└── Yes → Does it affect outcomes?
    ├── No → Document, continue
    └── Yes → Is it within scope to fix?
        ├── Yes → Fix, document, continue
        └── No → Is user available?
            ├── Yes → Consult, decide together
            └── No → Stop, document blocker
```

---

## OUTPUT

This workflow produces:
- Executed plan objectives (code changes, test results, gathered data, etc.)
- Exhaustive execution log documenting every action taken
- Updated plan status (`Complete` or `Blocked`)
- Ephemeral git branch `projex/{yyyymmdd}-{plan-name}` with all commits (if any)

**Git state after execution (if code changes were made):**
```
main (or base branch)
  └── projex/{yyyymmdd}-{plan-name}  ← you are here
        ├── commit: start execution
        ├── commit: step 1 - ...
        ├── commit: step 2 - ...
        └── commit: step N - ...
```

**If no code changes (investigative/testing plan):**
```
main (or base branch)
  └── projex/{yyyymmdd}-{plan-name}  ← you are here
        └── commit: start execution (plan status update only)
        
[All actions logged in execution log, no code commits]
```

---

## NEXT STEPS

After successful execution:
1. User reviews the results (changes/findings/data)
2. Run `/close-projex.md` to create walkthrough document

---

## GIT BRANCH MANAGEMENT

### Git Operation Discipline

**CRITICAL: Execute git commands one at a time. Wait for each command to complete and verify success before proceeding.**

```bash
# Step 1: Create branch - WAIT for completion
git checkout -b projex/20260126-plan-name
# Verify: Should see "Switched to a new branch 'projex/...'"

# Step 2: Stage files - WAIT for completion
git add <files>
# Verify: No error output

# Step 3: Commit - WAIT for completion
git commit -m "projex: ..."
# Verify: Should see commit summary with files changed
```

**Never:**
- Run multiple git commands in parallel
- Assume a git command succeeded without checking
- Proceed to the next git operation before the previous one completes
- Chain git commands with `&` or `&&` without verification between them

### Branch Naming
```
projex/{yyyymmdd}-{plan-name}
```

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

## NOTES

- Execution is about following the plan, not making design decisions
- Not all executions involve code changes — some are testing, analysis, documentation
- If you find yourself making many deviations, the plan may need review
- Trust the plan but verify against reality
- **Log aggressively** — every command, every file touched, every observation
- The walkthrough depends on exhaustive execution logs
- Use relative paths when referencing repository files
- All execution happens in ephemeral branch — base branch stays clean until close