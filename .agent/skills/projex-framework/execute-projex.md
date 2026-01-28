# Execute Projex Workflow

(This is part of @projex-framework skill. Is is a MUST to load the skill first.)

This workflow guides the execution of **Plan** projex documents — implementing the specified changes following the plan's instructions.

---

## PURPOSE

Execution transforms plans into reality. This workflow ensures faithful implementation while handling deviations intelligently and maintaining traceability.

**Key characteristics:**
- Follow the plan precisely
- Document any deviations with reasoning
- Verify each step before proceeding
- Track progress for walkthrough creation

---

## INVOCATION

```
/execute-projex.md @<plan-file>
```

**Examples:**
- `/execute-projex.md @20260731-database-service-refactor-plan.md`
- `/execute-projex.md @20260115-auth-session-timeout-plan.md`

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

4. **Create execution log** — Track progress and ACTUAL changes:

```markdown
# Execution Log: [Plan Name]
Started: [timestamp]

## Progress
- [ ] Step 1: [title]
- [ ] Step 2: [title]
...

## Actual Changes (vs Plan)
[For each file/change, note if it matches plan or differs]
- `file.ext`: [actual change] — matches plan / differs because [reason]

## Deviations
[Track any changes from plan — WHAT and WHY]

## Unplanned Changes
[Files changed that weren't in the plan — WHY]

## Planned But Skipped
[Planned changes not made — WHY]

## Issues Encountered
[Document problems and resolutions]
```

> **Important:** This log feeds into the walkthrough. Track what ACTUALLY happens, not just what was planned.

### 2. EXECUTE STEPS SEQUENTIALLY

For each step in the plan:

#### A. PRE-STEP

1. Read the step completely
2. Understand the objective and rationale
3. Locate all referenced files
4. Verify preconditions are met

#### B. IMPLEMENT

1. Make the specified changes
2. Follow the plan's before/after code exactly
3. Match existing code style and conventions
4. Add comments where the plan specifies (or where clarity demands)

#### C. VERIFY

1. Run the step's verification method
2. Confirm the step objective is achieved
3. Check for unintended side effects
4. Ensure code compiles/lints cleanly

#### D. DOCUMENT

**Track ACTUAL changes for the walkthrough (not just what was planned):**
- What was actually done — specific files, specific changes
- How it differs from plan (if at all)
- Why it differs (if applicable)
- Issues encountered and resolutions
- Verification results

> The walkthrough will be derived from git history + these notes. Be specific about what actually changed.

### 3. HANDLE DEVIATIONS

When the plan doesn't match reality:

**Minor Deviations** (proceed with adjustment):
- Slight code differences that don't affect approach
- File line numbers shifted
- Naming conventions evolved

```
Document: "Deviated from plan: [what changed] because [why]"
```

**Moderate Deviations** (pause and assess):
- File structure changed
- Dependencies missing
- Approach needs minor adjustment

```
Action: Assess impact, adjust approach, document reasoning, continue
```

**Major Deviations** (stop execution):
- Plan assumptions fundamentally wrong
- Significant architectural changes since plan
- Blockers not anticipated in plan

```
Action: Stop, report to user, plan needs review/update
```

### 4. STEP-BY-STEP COMPLETION

After each step:

1. Mark step complete in tracking
2. **Commit changes** — Logical atomic units with descriptive messages:

```bash
git add <changed-files>
git commit -m "projex: step N - [brief description]"
```

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
2. Is it a plan issue or implementation issue?
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
   - Review all changes made
   - Check for any cleanup needed
   - Verify no debug code left behind

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

### Incremental Progress
- Verify after each step
- Commit logical units
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

## DEVIATION DECISION TREE

```
Is the deviation from the plan?
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
- Implemented changes as specified in the plan (in ephemeral branch)
- Execution log/notes for walkthrough creation
- Updated plan status (`Complete` or `Blocked`)
- Ephemeral git branch `projex/{yyyymmdd}-{plan-name}` with all changes

**Git state after execution:**
```
main (or base branch)
  └── projex/{yyyymmdd}-{plan-name}  ← you are here
        ├── commit: start execution
        ├── commit: step 1 - ...
        ├── commit: step 2 - ...
        └── commit: step N - ...
```

---

## NEXT STEPS

After successful execution:
1. User reviews the changes
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

- Execution is about implementation, not design decisions
- If you find yourself making many deviations, the plan may need review
- Trust the plan but verify against reality
- Document thoroughly — the walkthrough depends on good execution notes
- Use relative paths when referencing repository files
- All execution happens in ephemeral branch — base branch stays clean until close
