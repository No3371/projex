---
description: This workflow guides the creation of **Plan** projex documents — actionable task documents with clear objectives, rich context, and specific implementation details. (This is part of @projex-framework skill. It is a MUST to load the skill first.)
---

## PURPOSE

Plans capture WHAT needs doing and HOW — specific enough that any LLM or developer can follow without clarifying questions.

- Specific problem/gap/need with clear objectives
- Exact changes to exact files
- Closed-ended with measurable success criteria
- Granular scope with clear boundaries

---

## INVOCATION

```
/plan-projex.md <objective or proposal reference>
```

**Examples:**
- `/plan-projex.md Update current impl to keep up with latest specs`
- `/plan-projex.md @2607311430-database-service-refactor-proposal.md`
- `/plan-projex.md Implement user session timeout feature`

---

## WORKFLOW STEPS

### 1. SOURCE ANALYSIS

**Resolve the target repo** — if a projex file is referenced, `cd` to its directory and run `git rev-parse --show-toplevel`. The projex file's location is the source of truth; never rely on the session's initial cwd. **All git commands for the rest of this workflow must run from this repo root.** If no file is referenced, infer from context.

**From Proposal:** Read the proposal → verify `Accepted` status → extract approach, scope, constraints.

**From Direct Request:** Clarify objective with user → research current state → identify scope → check for related projex.

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

> **Boundary Rule:** A plan targets exactly ONE projex scope. Changes across multiple scopes or repos → split into separate plans linked via `Dependencies`. See [Splitting Plans](#splitting-plans).

**Scope validation:**
- [ ] Completable in a focused session
- [ ] All target files belong to a single projex scope
- [ ] Has clear start and end points
- [ ] Success is objectively measurable

### 3. CONTEXT RESEARCH

Answer these questions by reading the actual code:

1. **Current behavior** — What does the code do today? Trace the actual call path, not what you assume it does
2. **Dependencies** — What calls into this code? What does it call? What breaks if it changes?
3. **Conventions** — What patterns does the surrounding code follow? (naming, error handling, structure)
4. **Edge cases** — What inputs, states, or timing conditions could cause problems?
5. **Prior art** — Have related changes been attempted before? Check walkthroughs and git history for lessons learned

**Refine scope.** Revisit the boundaries from Step 2 — research often reveals the scope was too broad, too narrow, or aimed at the wrong layer. Adjust before drafting.

**Checkpoint (complex plans).** Before drafting, briefly present to the user: key findings, the intended approach and why, any scope adjustments. This catches misalignment before effort is sunk into a full draft. Skip when the path is obvious.

### 4. DRAFT THE PLAN

Create `<projex-folder>/{yymmddhhmm}-{plan-name}-plan.md` directly in the target projex folder from Step 2 — not in agent artifacts, temp paths, or anywhere outside the repo's `.projex/` folders.

**Template Structure:**

```markdown
# [Plan Title]

> **Status:** Draft | Ready | In Progress | Blocked | Complete
> **Created:** YYYY-MM-DD
> **Author:** [name or agent]
> **Source:** [link to proposal or "Direct request"]
> **Related Projex:** [links to related projex documents]
> **Worktree:** Yes | No

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

**Mandatory re-examination.** Early steps were written with incomplete understanding — this pass catches what they got wrong.

**Re-read the relevant code** — do not rely on memory from Step 3:

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

**Completeness:**
- [ ] Every step has specific file paths and before/after changes
- [ ] Each step has verification method
- [ ] Success criteria are measurable and testable
- [ ] No open questions remain

**Executability:**
- [ ] Any LLM or developer could follow without clarifying questions
- [ ] Dependencies and order of operations are unambiguous

**Scope:**
- [ ] Plan stays within declared scope
- [ ] All files belong to ONE projex scope — if not, split
- [ ] Appropriately granular (not too broad, not too narrow)

### 7. FINALIZE

1. **Refine document** — Front-load key info (summary, scope, criteria)
2. **De-slop** (optional) — Re-read as a reader and strip agent self-talk, filler, redundant restatements, and unfilled template artifacts. See *De-slop* in SKILL.md.
3. **Update relationships** — Add links to/from related projex
4. **Set status** — Mark as `Ready` when complete
5. **Verify placement** — Confirm the file is in the correct `.projex/` folder (it should already be there from step 4)
6. **Commit the plan** — Plan must be committed to base branch before execution

```bash
{projex-scripts}/projex-commit.{sh|ps1} <repo-root> "projex: add plan - {plan-name}" .projex/{yymmddhhmm}-{plan-name}-plan.md
```

> **Important:** Plans must be committed before `/execute-projex.md` can be invoked. The ephemeral execution branch is created from the base branch, so the plan must exist in git history.

**Folder placement:** See SKILL.md § Organizing. Plans move to `.projex/closed/` only after Walkthrough is authored.

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
- Plan touches files in more than one `.projex/` scope (different projex folders)
- Plan touches files in more than one repository
- Plan mixes upstream changes (e.g. spec, schema, API contract) with downstream consumers (e.g. implementation, client code)

Split is **recommended** when:
- Scope is too large for a focused session
- Steps have no mutual dependency and can be executed independently

### How to split

**By projex boundary (mandatory):**

> **Example — spec + implementation:**
> A language spec change requires updating the C# runtime.
> - **Wrong:** One plan covering both spec markdown and C# source.
> - **Right:** Two plans:
>   1. `docs/.projex/2602081430-macro-syntax-revision-plan.md` — Spec only. Dependencies: "Blocks: impl plan."
>   2. `src/.projex/2602081430-macro-syntax-impl-plan.md` — C# only. Dependencies: "Requires: spec plan."

**By slice (recommended when scope is large within one boundary):**
1. **Vertical slices** — End-to-end for one feature
2. **Horizontal layers** — One layer across features
3. **Dependencies** — Group by what must happen first

### Split plan rules

Each split plan must:
- Be independently executable
- Target exactly one projex scope
- Link to sibling plans via `Dependencies` (Requires / Blocks)
- Not create circular dependencies

---

## OUTPUT

This workflow produces:
- A plan projex document at `.projex/{yymmddhhmm}-{name}-plan.md` (pending in parent folder)
- Updated relationships in source proposal (if applicable)
- Updated relationships in any related projex documents

After execution and walkthrough creation, both Plan and Walkthrough move to `.projex/closed/`.

---

## NEXT STEPS

**The plan workflow ends here.** Present the plan — do not suggest or initiate execution.

- `/execute-projex.md @{plan-file}` — execute
- `/review-projex.md` or `/redteam-projex.md` — challenge first
- Revise, shelve, or reject

---

## NOTES

- When in doubt, be more detailed rather than less
- If execution reveals the plan was wrong, update the plan for future reference
