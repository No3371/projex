# Execute Projex Workflow

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

- [ ] Plan status is `Ready`
- [ ] No unresolved open questions
- [ ] All dependencies are met
- [ ] No blockers present

### 2. ENVIRONMENT CHECK

- [ ] Correct branch/workspace
- [ ] Clean working state (no uncommitted changes that conflict)
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

1. **Update plan status** — Change to `In Progress`
2. **Create execution log** — Track progress mentally or in notes:

```markdown
# Execution Log: [Plan Name]
Started: [timestamp]

## Progress
- [ ] Step 1: [title]
- [ ] Step 2: [title]
...

## Deviations
[Track any changes from plan]

## Issues Encountered
[Document problems and resolutions]
```

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

Track for the walkthrough:
- What was actually done
- Any deviations from plan
- Issues encountered and resolutions
- Verification results

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
2. Commit if appropriate (logical atomic units)
3. Verify overall progress
4. Check if next step preconditions are met

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
- Implemented changes as specified in the plan
- Execution log/notes for walkthrough creation
- Updated plan status (`Complete` or `Blocked`)

---

## NEXT STEPS

After successful execution:
1. User reviews the changes
2. Run `/close-projex.md` to create walkthrough document

---

## NOTES

- Execution is about implementation, not design decisions
- If you find yourself making many deviations, the plan may need review
- Trust the plan but verify against reality
- Document thoroughly — the walkthrough depends on good execution notes
- Use relative paths when referencing repository files
