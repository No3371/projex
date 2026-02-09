---
description: This workflow guides the creation of **Plan** projex documents — actionable task documents with clear objectives, rich context, and specific implementation details. (This is part of @projex-framework skill. It is a MUST to load the skill first.)
---

## PURPOSE

Plans are the bridge between ideas and execution. They capture WHAT needs to be done and HOW to implement it, with enough detail that any LLM can follow and execute them.

**Key characteristics:**
- Specific problem/gap/need with clear objectives
- Exact changes to exact files
- Closed-ended with clear acceptance/success criteria
- Granular scope with clear boundaries

---

## INVOCATION

```
/plan-projex.md <objective or proposal reference>
```

**Examples:**
- `/plan-projex.md Update current impl to keep up with latest specs`
- `/plan-projex.md @20260731-database-service-refactor-proposal.md`
- `/plan-projex.md Implement user session timeout feature`

---

## WORKFLOW STEPS

### 1. SOURCE ANALYSIS

Determine the source of the plan:

**From Proposal:**
1. Read the referenced proposal document
2. Verify status is `Accepted`
3. Extract recommended approach and scope
4. Note any constraints or decisions made

**From Direct Request:**
1. Clarify the objective with the user
2. Research current state and context
3. Identify scope and boundaries
4. Check for related existing projex

### 2. SCOPE DEFINITION

Before writing the plan:

```
Answer these questions:
- What is the specific, bounded objective?
- What files/components are in scope?
- What is explicitly OUT of scope?
- What are the dependencies (must happen before)?
- What are the blockers (must be resolved first)?
- Which projex folder does this plan belong to?
- Does this objective touch files governed by a different projex folder or repo?
```

> **Boundary Rule:** A plan must target exactly ONE projex scope. If the objective involves changes across multiple projex folders or repositories, split it into separate plans — one per scope. Use the `Dependencies` section to link them. See [Splitting Plans](#splitting-plans) for details.

**Scope validation:**
- [ ] Can be completed in a focused session
- [ ] All target files belong to a single projex folder's scope
- [ ] Does not modify files governed by a different projex folder or repo
- [ ] Has clear start and end points
- [ ] Success is objectively measurable

If scope is too large or crosses boundaries, split into multiple plans with clear dependencies.

### 3. CONTEXT RESEARCH

Gather comprehensive context:

1. **Read relevant files** — Understand current implementation
2. **Trace dependencies** — Map what depends on what
3. **Check patterns** — Identify existing conventions to follow
4. **Find edge cases** — Consider error handling, boundaries
5. **Review history** — Check related walkthroughs for lessons learned

### 4. DRAFT THE PLAN

Create the file **in the target projex folder** identified in step 2: `<projex-folder>/{yyyymmdd}-{plan-name}-plan.md`

> **The file must be created directly in the projex folder.** Do not place it in agent artifacts directories, temp paths, or any location outside the repo's `projex/` folders. The projex folder was determined in step 2 — use it.

**Template Structure:**

```markdown
# [Plan Title]

> **Status:** Draft | Ready | In Progress | Blocked | Complete
> **Created:** YYYY-MM-DD
> **Author:** [name or agent]
> **Source:** [link to proposal or "Direct request"]
> **Related Projex:** [links to related projex documents]

---

## Summary

[2-3 sentences: What this plan accomplishes and why it matters]

**Scope:** [One line defining boundaries]
**Estimated Changes:** [X files, Y functions/components]

---

## Objective

### Problem / Gap / Need
[Specific description of what needs to be addressed]

### Success Criteria
- [ ] [Measurable criterion 1]
- [ ] [Measurable criterion 2]
- [ ] [Measurable criterion 3]

### Out of Scope
- [Explicitly excluded item 1]
- [Explicitly excluded item 2]

---

## Context

### Current State
[Description of relevant current implementation]

### Key Files
| File | Purpose | Changes Needed |
|------|---------|----------------|
| `path/to/file1.ext` | [What it does] | [What changes] |
| `path/to/file2.ext` | [What it does] | [What changes] |

### Dependencies
- **Requires:** [What must exist/happen before this]
- **Blocks:** [What is waiting on this]

### Constraints
- [Technical constraint 1]
- [Business rule constraint 2]

---

## Implementation

### Overview
[High-level description of the implementation approach]

### Step 1: [Step Title]

**Objective:** [What this step accomplishes]

**Files:**
- `path/to/file.ext`

**Changes:**

```[language]
// Before:
[existing code or state]

// After:
[new code or state]
```

**Rationale:** [Why this change is made this way]

**Verification:** [How to verify this step succeeded]

---

### Step 2: [Step Title]

[Same structure as Step 1]

---

### Step N: [Final Step Title]

[Same structure as Step 1]

---

## Verification Plan

### Automated Checks
- [ ] [Test/lint/build check 1]
- [ ] [Test/lint/build check 2]

### Manual Verification
- [ ] [Manual check 1]
- [ ] [Manual check 2]

### Acceptance Criteria Validation
| Criterion | How to Verify | Expected Result |
|-----------|---------------|-----------------|
| [Criterion 1] | [Verification method] | [Expected outcome] |

---

## Rollback Plan

If implementation fails or causes issues:

1. [Rollback step 1]
2. [Rollback step 2]

---

## Notes

### Assumptions
- [Assumption 1]
- [Assumption 2]

### Risks
- [Risk 1]: [Mitigation]

### Open Questions
- [ ] [Any unresolved questions — should be empty before execution]
```

### 5. VALIDATION

Before marking Ready:

**Completeness Check:**
- [ ] Every step has specific file paths
- [ ] Code changes show before/after or exact additions
- [ ] Each step has verification method
- [ ] Success criteria are measurable and testable
- [ ] No open questions remain unresolved

**Executability Check:**
- [ ] Any LLM could follow this without asking questions
- [ ] Any developer could implement without clarification
- [ ] Dependencies are clearly stated
- [ ] Order of operations is unambiguous

**Scope Check:**
- [ ] Plan stays within declared scope
- [ ] No scope creep into out-of-scope areas
- [ ] All files in Key Files table belong to ONE projex scope — if not, split the plan
- [ ] Downstream/cascading changes are deferred to their own plans in their own scope
- [ ] Appropriately granular (not too broad, not too narrow)

### 6. FINALIZE

1. **Refine document** — Front-load key info (summary, scope, criteria)
2. **Update relationships** — Add links to/from related projex
3. **Set status** — Mark as `Ready` when complete
4. **Verify placement** — Confirm the file is in the correct `projex/` folder (it should already be there from step 4)
5. **Commit the plan** — Plan must be committed to base branch before execution

```bash
git add projex/{yyyymmdd}-{plan-name}-plan.md
git commit -m "projex: add plan - {plan-name}"
```

> **Important:** Plans must be committed before `/execute-projex.md` can be invoked. The ephemeral execution branch is created from the base branch, so the plan must exist in git history.

**Folder placement by status:**
| Status | Location |
|--------|----------|
| Draft / Ready / In Progress / Blocked | `projex/` |
| Complete (with Walkthrough) | `projex/closed/` |
| Abandoned | `projex/abandoned/` or deleted |

---

## STATUS TRANSITIONS

```
Draft → Ready → In Progress → Complete
                            → Blocked → Ready (when unblocked)
```

- **Draft**: Still being written
- **Ready**: Validated and ready for execution
- **In Progress**: Currently being executed
- **Blocked**: Cannot proceed (document blocker)
- **Complete**: Execution finished, Walkthrough authored

---

## SPLITTING PLANS

### When to split

Split is **required** when any of these apply:
- Plan touches files in more than one `projex/` scope (different projex folders)
- Plan touches files in more than one repository
- Plan mixes upstream changes (e.g. spec, schema, API contract) with downstream consumers (e.g. implementation, client code)

Split is **recommended** when:
- Scope is too large for a focused session
- Steps have no mutual dependency and can be executed independently

### How to split

**By projex boundary (mandatory):**
Each `projex/` folder represents an independent scope. A plan that would modify files across two scopes becomes two plans, each filed in its own scope's `projex/` folder.

> **Example — spec revision with downstream implementation:**
> A language spec change requires updating the C# runtime that implements it.
>
> - **Wrong:** One plan covering both the spec markdown files and the C# source files.
> - **Right:** Two plans:
>   1. `docs/projex/20260208-macro-syntax-revision-plan.md` — Changes to the spec only. Lists "Blocks: downstream implementation plan" in Dependencies.
>   2. `src/projex/20260208-macro-syntax-impl-plan.md` — Changes to C# source only. Lists "Requires: spec revision plan" in Dependencies.

> **Example — multi-repo workspace:**
> An API schema change in repo-a requires client updates in repo-b.
>
> - **Wrong:** One plan referencing files from both repos.
> - **Right:** Two plans, one per repo. The repo-a plan notes it blocks repo-b. The repo-b plan notes it requires repo-a.

**By slice (recommended when scope is large within one boundary):**
1. **Vertical slices** — End-to-end for one feature
2. **Horizontal layers** — One layer across features
3. **Dependencies** — Group by what must happen first

### Split plan rules

Each split plan must:
- Be independently executable
- Target exactly one projex scope (one `projex/` folder, one repo)
- Have clear relationship to sibling plans via `Dependencies` (Requires / Blocks)
- Not create circular dependencies
- Be filed in the correct `projex/` folder for its scope

---

## OUTPUT

This workflow produces:
- A plan projex document at `projex/{yyyymmdd}-{name}-plan.md` (pending in parent folder)
- Updated relationships in source proposal (if applicable)
- Updated relationships in any related projex documents

After execution and walkthrough creation, both Plan and Walkthrough move to `projex/closed/`.

---

## NEXT STEPS

After plan is `Ready`:
1. Execute using `/execute-projex.md @{plan-file}`
2. After execution, close using `/close-projex.md`

---

## NOTES

- Plans should be specific enough to execute without clarification
- Use relative paths when referencing repository files
- When in doubt, be more detailed rather than less
- If execution reveals the plan was wrong, update the plan for future reference
