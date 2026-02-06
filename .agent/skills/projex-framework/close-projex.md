---
description: This workflow guides the creation of **Walkthrough** projex documents — comprehensive records authored after every Plan execution. (This is part of @projex-framework skill. It is a MUST to load the skill first.)
---

## PURPOSE

Walkthroughs capture what actually happened during execution. They provide complete traceability, verify success criteria, and preserve insights for future reference.

**Key characteristics:**
- Complete record of execution outcomes
- Detailed file changes down to line numbers
- Success criteria verification with proof
- Lessons learned and pattern discoveries

---

## INVOCATION

```
/close-projex.md
```

**Timing:** Invoke after the user has reviewed the results of `/execute-projex.md` and confirmed execution is complete.

---

## PREREQUISITES

Before closing:

- [ ] Plan execution is complete
- [ ] User has reviewed the changes
- [ ] All success criteria are verifiable
- [ ] Execution log/notes are available
- [ ] Currently on ephemeral branch `projex/{yyyymmdd}-{plan-name}`
- [ ] All execution changes are committed

---

## WORKFLOW STEPS

### 1. GATHER EXECUTION DATA

Collect all information from the execution:

#### From the Plan
1. Original objectives
2. Success/acceptance criteria
3. Planned steps
4. Expected file changes

#### From Execution
1. What actually happened for each step
2. Any deviations from plan
3. Issues encountered and resolutions
4. Actual file changes made

#### From Verification
1. Test results
2. Verification outcomes
3. User feedback

### 2. DOCUMENT ACTUAL CHANGES

**IMPORTANT: Document what actually happened, not what was planned.** The walkthrough is a historical record of reality.

1. **Query git for actual changes:**

```bash
# List all commits in ephemeral branch
git log --oneline main..HEAD

# See all files changed
git diff --stat main..HEAD

# Get detailed diff
git diff main..HEAD
```

2. **For each file changed, record:**
   - File path
   - Change type (created/modified/deleted)  
   - Specific changes (line numbers, actual before/after)
   - Purpose of change
   - **Whether this matches or deviates from plan**

3. **Compare against plan:**
   - Files in plan but not changed → Document why (already done? not needed? blocked?)
   - Files changed but not in plan → Document why (discovered during execution? dependency?)
   - Changes different from plan → Document what and why

### 3. VERIFY SUCCESS CRITERIA

For each success criterion from the plan:

1. **State the criterion**
2. **Document verification method used**
3. **Record the evidence/proof**
4. **Mark pass/fail with notes**

### 4. CAPTURE INSIGHTS

Document learnings:

- **Lessons learned** — What would you do differently?
- **Pattern discoveries** — New patterns identified
- **Gotchas/pitfalls** — Traps encountered
- **Reusable knowledge** — Insights for future work

### 5. DRAFT THE WALKTHROUGH

Create a new file: `{yyyymmdd}-{plan-name}-walkthrough.md`

**Template Structure:**

```markdown
# Walkthrough: [Plan Title]

> **Execution Date:** YYYY-MM-DD
> **Completed By:** [name or agent]
> **Source Plan:** [link to plan document]
> **Duration:** [how long execution took]
> **Result:** Success | Partial Success | Failed

---

## Summary

[2-3 sentences: What was accomplished and final outcome]

---

## Objectives Completion

| Objective | Status | Notes |
|-----------|--------|-------|
| [Objective 1 from plan] | Complete/Partial/Failed | [Details] |
| [Objective 2 from plan] | Complete/Partial/Failed | [Details] |

---

## Execution Detail

> **NOTE:** This section documents what ACTUALLY happened, derived from git history and execution notes. 
> Differences from the plan are explicitly called out.

### Step 1: [Step Title from Plan]

**Planned:** [What the plan specified]

**Actual:** [What was actually done — be specific, cite actual code/files]

**Deviation:** [None / Description of deviation and reasoning]
- If different from plan: WHY? (discovered issue, better approach, prerequisite missing, etc.)

**Files Changed (ACTUAL):**
| File | Change Type | Planned? | Details |
|------|-------------|----------|---------|
| `path/to/file.ext` | Modified | Yes | Lines 45-67: [actual changes made] |
| `path/to/new.ext` | Created | No | [why this was added] |

**Verification:** [How this step was verified — actual results]

**Issues:** [Any issues encountered and how resolved]

---

### Step 2: [Step Title]

[Same structure as Step 1]

---

### Step N: [Final Step]

[Same structure]

---

## Complete Change Log

> **Derived from:** `git diff --stat main..HEAD` — This is the authoritative record of what changed.

### Files Created
| File | Purpose | Lines | In Plan? |
|------|---------|-------|----------|
| `path/to/file.ext` | [What it does] | [line count] | Yes/No |

### Files Modified
| File | Changes | Lines Affected | In Plan? |
|------|---------|----------------|----------|
| `path/to/file.ext` | [Summary of changes] | [line ranges] | Yes/No |

### Files Deleted
| File | Reason | In Plan? |
|------|--------|----------|
| `path/to/file.ext` | [Why deleted] | Yes/No |

### Planned But Not Changed
| File | Planned Change | Why Not Done |
|------|----------------|--------------|
| `path/to/file.ext` | [What was planned] | [Reason: blocked, not needed, deferred, etc.] |

---

## Success Criteria Verification

### Criterion 1: [Criterion from Plan]

**Verification Method:** [How it was tested]

**Evidence:**
```
[Actual output, test results, or proof]
```

**Result:** PASS / FAIL

---

### Criterion 2: [Criterion]

[Same structure]

---

### Acceptance Criteria Summary

| Criterion | Method | Result | Evidence |
|-----------|--------|--------|----------|
| [Criterion 1] | [Method] | Pass/Fail | [Link or ref] |
| [Criterion 2] | [Method] | Pass/Fail | [Link or ref] |

**Overall:** [X/Y criteria passed]

---

## Deviations from Plan

### Deviation 1: [Title]
- **Planned:** [What was planned]
- **Actual:** [What was done instead]
- **Reason:** [Why the deviation occurred]
- **Impact:** [Effect on outcome]
- **Recommendation:** [Should plan be updated?]

---

## Issues Encountered

### Issue 1: [Title]
- **Description:** [What happened]
- **Severity:** Low/Medium/High
- **Resolution:** [How it was fixed]
- **Time Impact:** [How long it delayed]
- **Prevention:** [How to avoid in future]

---

## Key Insights

### Lessons Learned

1. **[Lesson Title]**
   - Context: [When/why this was learned]
   - Insight: [The actual lesson]
   - Application: [How to apply in future]

2. **[Lesson Title]**
   [Same structure]

### Pattern Discoveries

1. **[Pattern Name]**
   - Observed in: [Where it was found]
   - Description: [What the pattern is]
   - Reuse potential: [Where else it applies]

### Gotchas / Pitfalls

1. **[Gotcha Title]**
   - Trap: [What the pitfall is]
   - How encountered: [How you ran into it]
   - Avoidance: [How to prevent]

### Technical Insights

- [Insight about the codebase]
- [Insight about tools/frameworks]
- [Insight about process]

---

## Recommendations

### Immediate Follow-ups
- [ ] [Action that should happen soon]
- [ ] [Related task to consider]

### Future Considerations
- [Long-term improvement to consider]
- [Technical debt identified]

### Plan Improvements
If this plan were to be executed again:
- [What should change in the plan]
- [Missing information that would help]

---

## Related Projex Updates

### Documents to Update
| Document | Update Needed |
|----------|---------------|
| [Plan document] | Mark as Complete |
| [Proposal document] | Link to walkthrough |

### New Projex Suggested
| Type | Description |
|------|-------------|
| Plan | [Follow-up work identified] |
| Proposal | [New idea discovered] |

---

## Appendix

### Execution Log
```
[Raw execution notes/log if useful]
```

### Test Output
```
[Relevant test or verification output]
```

### References
- [Links to relevant commits, PRs, or documents]
```

### 6. FINALIZE DOCUMENTS

1. **Update the source plan:**
   - Change status to `Complete`
   - Add link to walkthrough

```markdown
> **Completed:** YYYY-MM-DD
> **Walkthrough:** [link to walkthrough document]
```

2. **Update related projex:**
   - Source proposal (if applicable)
   - Any dependent plans

3. **Move to closed folder:**
   - Move Plan document to `projex/closed/`
   - Place Walkthrough in `projex/closed/` alongside the Plan
   - If source Proposal exists and all derived Plans are closed, move Proposal to `projex/closed/` as well

4. **Commit walkthrough and file moves** — stage each moved/created file by explicit path:

```bash
git add projex/closed/{yyyymmdd}-{name}-walkthrough.md
git add projex/closed/{yyyymmdd}-{name}-plan.md
# If proposal also moved:
git add projex/closed/{yyyymmdd}-{name}-proposal.md
# Stage deletions from original locations (git tracks the move):
git add projex/{yyyymmdd}-{name}-plan.md
git commit -m "projex: close {plan-name} - add walkthrough"
```

---

### 7. FINALIZE GIT BRANCH

**CRITICAL: Execute each git command one at a time. Wait for completion and verify success before proceeding to the next command.**

The ephemeral branch must be finalized. Present options to user:

#### Option A: Squash Merge (Default/Recommended)
Combines all execution commits into a single clean commit on base branch.

```bash
# Step 1 - WAIT for completion, verify "Switched to branch 'main'"
git checkout main

# Step 2 - WAIT for completion, verify squash summary
git merge --squash projex/{yyyymmdd}-{plan-name}

# Step 3 - WAIT for completion, verify commit created
git commit -m "projex: {plan-name} - [summary of changes]"

# Step 4 - WAIT for completion, verify branch deleted
git branch -D projex/{yyyymmdd}-{plan-name}
```

**Best for:** Clean history, routine executions

#### Option B: Merge with History
Preserves full commit history from execution.

```bash
git checkout main
git merge projex/{yyyymmdd}-{plan-name} --no-ff -m "projex: merge {plan-name}"
git branch -d projex/{yyyymmdd}-{plan-name}
```

**Best for:** Complex executions where step-by-step history is valuable

#### Option C: Rebase and Merge
Replays commits onto base branch for linear history.

```bash
git checkout projex/{yyyymmdd}-{plan-name}
git rebase main
git checkout main
git merge projex/{yyyymmdd}-{plan-name} --ff-only
git branch -d projex/{yyyymmdd}-{plan-name}
```

**Best for:** Linear history preference, collaborative workflows

#### Option D: Abandon (Failed Execution)
Discards the branch without merging.

```bash
git checkout main
git branch -D projex/{yyyymmdd}-{plan-name}
```

**Use when:** Execution failed, changes are not wanted

---

### Branch Finalization Decision Tree

```
Was execution successful?
├── Yes → Do you need step-by-step history?
│   ├── Yes → Option B (Merge with History)
│   └── No → Option A (Squash Merge) ← default
└── No → Are partial changes valuable?
    ├── Yes → Cherry-pick valuable commits, then Option D
    └── No → Option D (Abandon)
```

---

## WALKTHROUGH PRINCIPLES

### Completeness
- Document everything that happened
- Don't skip steps even if they went smoothly
- Include all file changes with specifics

### Traceability
- Link every change to a plan step
- Document deviations with reasoning
- Provide verifiable evidence

### Learning Capture
- Extract insights while fresh
- Document both failures and successes
- Make knowledge reusable

### Honesty
- Record actual outcomes, not desired ones
- Acknowledge what didn't work
- Document partial successes accurately

---

## OUTPUT

This workflow produces:
- A walkthrough projex document at `projex/closed/{yyyymmdd}-{name}-walkthrough.md`
- Source plan moved to `projex/closed/` with completion status and walkthrough link
- Source proposal moved to `projex/closed/` (if all derived plans are closed)
- Updated relationships in related projex documents
- **Ephemeral branch merged/deleted** — changes now on base branch

**Folder structure after close:**
```
projex/
├── [other pending projex...]
└── closed/
    ├── {yyyymmdd}-{name}-proposal.md   (if applicable)
    ├── {yyyymmdd}-{name}-plan.md
    └── {yyyymmdd}-{name}-walkthrough.md
```

**Git state after close:**
```
main (or base branch)  ← you are here, with all changes merged
  └── (ephemeral branch deleted)
```

---

## WALKTHROUGH QUALITY CHECKLIST

Before considering walkthrough complete:

- [ ] Every plan objective has outcome documented
- [ ] Every plan step has actual execution recorded
- [ ] All file changes listed with specifics
- [ ] All success criteria verified with evidence
- [ ] All deviations explained
- [ ] All issues documented with resolutions
- [ ] Key insights captured
- [ ] Source plan updated
- [ ] Related projex linked
- [ ] Plan and Walkthrough moved to `projex/closed/`
- [ ] Source proposal moved to `projex/closed/` (if all derived plans closed)
- [ ] **Ephemeral branch finalized** (merged or abandoned)
- [ ] **Back on base branch** with clean state

---

## NOTES

- Walkthroughs are historical records — don't edit them after completion
- Be thorough — you'll thank yourself when reviewing later
- Use relative paths when referencing repository files
- The value of projex compounds when walkthroughs are complete
- If execution was complex, write the walkthrough immediately while fresh
- **Squash merge is the default** — preserves clean history while capturing all changes
- Branch finalization is the final step — don't forget to delete the ephemeral branch
- The walkthrough commit should be the last commit before merge
