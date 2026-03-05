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

**Guiding principle:** A finished plan should be followable by any LLM or developer without asking clarifying questions. If a reader must guess intent, the plan isn't ready.

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

**Resolve the target repo** — if a projex file is referenced, derive the repo from its path (see SKILL.md § Repo Resolution). Otherwise, infer from context.

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

### 2. PRELIMINARY SCOPE

Define initial boundaries — these may shift after research in Step 3:

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

Answer these questions by reading the actual code:

1. **Current behavior** — What does the code do today? Trace the actual call path, not what you assume it does
2. **Dependencies** — What calls into this code? What does it call? What breaks if it changes?
3. **Conventions** — What patterns does the surrounding code follow? (naming, error handling, structure)
4. **Edge cases** — What inputs, states, or timing conditions could cause problems?
5. **Prior art** — Have related changes been attempted before? Check walkthroughs and git history for lessons learned

**Refine scope.** Revisit the boundaries from Step 2 — research often reveals the scope was too broad, too narrow, or aimed at the wrong layer. Adjust before drafting.

**Checkpoint (complex plans).** Before drafting, briefly present to the user: key findings, the intended approach and why, any scope adjustments. This catches misalignment before effort is sunk into a full draft. Skip when the path is obvious.

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

> Quick reference — detailed changes are in Implementation steps below.

| File | Role | Change Summary |
|------|------|----------------|
| `path/to/file1.ext` | [What it does in the context of this plan] | [One-line summary] |
| `path/to/file2.ext` | [What it does in the context of this plan] | [One-line summary] |

### Dependencies
- **Requires:** [What must exist/happen before this]
- **Blocks:** [What is waiting on this]

### Constraints
- [Technical constraint 1]
- [Business rule constraint 2]

### Assumptions
- [What the plan takes for granted — verify these early during execution]
- [Assumption 2]

### Impact Analysis
- **Direct:** [Files/components being changed]
- **Adjacent:** [What interacts with changed code — could be affected indirectly]
- **Downstream:** [Consumers, dependents, or integrations that may need updates]

---

## Implementation

### Overview
[High-level description of the implementation approach]

### Step 1: [Step Title]

**Objective:** [What this step accomplishes]
**Confidence:** [High | Medium | Low — how certain is this approach?]
**Depends on:** [Previous step(s), or "None"]

**Files:**
- `path/to/file.ext`

**Changes:**

```[language]
// Before:
[existing code or state]

// After:
[new code or state]
```

**Rationale:** [Why this change, and why this way over alternatives]

**Verification:** [How to verify this step succeeded]

**If this fails:** [What to revert or how to recover — specific to this step]

---

### Step 2: [Step Title]

[Same structure as Step 1]

---

### Step N: [Final Step Title]

[Same structure as Step 1]

---

## Verification Plan

> Per-step verification (above) confirms each change in isolation. This section confirms the changes work together end-to-end.

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

Per-step rollback is noted in each implementation step above. If the overall implementation must be abandoned:

1. [Full rollback step 1]
2. [Full rollback step 2]

---

## Notes

### Risks
- [Risk 1]: [Mitigation]

### Open Questions
- [ ] [Any unresolved questions — should be empty before execution]
```

### 5. SECOND PASS — CHALLENGE THE PLAN

**Mandatory re-examination.** By the time the draft is complete, the agent understands the problem better than when it started step 1. Early steps were written with incomplete understanding — this pass catches what they got wrong.

**Re-read the relevant code.** Do not rely on memory from Step 3. Open the actual files referenced in the plan and verify:

1. **Assumptions** — What does the plan take for granted?
   - Does the "Current State" section match what the files actually show right now?
   - Are there implicit ordering assumptions (e.g., "X exists before Y runs") that aren't guaranteed?
   - Does the plan assume a function signature, return type, or data shape without verifying?

2. **Discrepancies** — Does the plan contradict itself?
   - Do different steps describe the same file differently?
   - Does a later step depend on something an earlier step doesn't actually produce?
   - Do the success criteria test something the implementation steps don't actually deliver?

3. **Misunderstandings** — Did the agent get the code wrong?
   - Trace the actual call path / data flow through the referenced files — does it work the way the plan says?
   - Are there side effects, validations, or intermediate transformations the plan doesn't account for?
   - Is the plan modifying the right layer? (e.g., changing a caller when the callee is the actual problem)

4. **Overengineering** — Is there a simpler way?
   - Could fewer steps achieve the same result?
   - Is the plan introducing abstractions, helpers, or indirection that aren't needed yet?
   - Would a more direct approach work just as well, even if it's less "elegant"?

**After this pass:**
- Fix anything caught — update steps, file references, before/after code, assumptions
- If the pass reveals the plan's approach is fundamentally wrong, stop and discuss with the user rather than patching a broken plan
- Document surviving assumptions in the Context → Assumptions section — making them visible so execution can verify them early

### 6. VALIDATION

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

### 7. FINALIZE

1. **Refine document** — Front-load key info (summary, scope, criteria)
2. **De-slop** (optional) — Re-read as a reader and strip agent self-talk, filler, redundant restatements, and unfilled template artifacts. See *De-slop* in SKILL.md.
3. **Update relationships** — Add links to/from related projex
4. **Set status** — Mark as `Ready` when complete
5. **Verify placement** — Confirm the file is in the correct `projex/` folder (it should already be there from step 4)
6. **Commit the plan** — Plan must be committed to base branch before execution

```bash
{projex-scripts}/projex-commit.{sh|ps1} <repo-root> "projex: add plan - {plan-name}" projex/{yyyymmdd}-{plan-name}-plan.md
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

**The plan workflow ends here.** Present the plan to the user. Do not suggest or initiate execution — the user decides what happens next.

The user may:
- **Execute** — `/execute-projex.md @{plan-file}`
- **Review or Red Team first** — `/review-projex.md` or `/redteam-projex.md` against the plan
- **Revise** — request changes to the plan before execution
- **Shelve** — leave the plan for later
- **Reject** — abandon the plan entirely

---

## NOTES

- Plans should be specific enough to execute without clarification
- Use relative paths when referencing repository files
- When in doubt, be more detailed rather than less
- If execution reveals the plan was wrong, update the plan for future reference
