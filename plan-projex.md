---
description: This workflow guides the creation of **Plan** projex documents — actionable task documents with clear objectives, rich context, and specific implementation details. (This is part of @projex-framework skill. It is a MUST to load the skill first.)
---

## PURPOSE

Plans capture WHAT and HOW — specific enough any LLM/dev follows without clarifying questions. Specific problem/gap/need | exact changes to exact files | closed-ended with measurable success criteria | granular scope with clear boundaries.

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

**Resolve target repo** — projex file referenced → its git repo; no reference → infer from context. Record output as `<repo-root>` (used by all scripts below).

```bash
cd <absolute-path-to-projex-file-directory> && git rev-parse --show-toplevel
```

**Determine worktree mode** for `Worktree` header:

```bash
git -C <repo-root> status --porcelain
git -C <repo-root> branch --list "projex/*"
```

**Worktree: Yes** if: dirty working dir | active `projex/*` branch | many files / large-scale changes. Else **No**. Auto-fills template; user can override.

**From Proposal:** read → verify `Accepted` → extract approach/scope/constraints.
**From Direct Request:** clarify objective → research current state → identify scope → check related projex.

### 2. PRELIMINARY SCOPE

Define initial boundaries — may shift after Step 3:

```
- Specific, bounded objective?
- Files/components in scope? Explicitly OUT?
- Dependencies (must happen before)? Blockers (must resolve first)?
- Which projex folder?
- Touches files governed by a different projex folder or repo?
```

**Boundary Rule:** plan targets exactly ONE projex scope. Cross-scope/repo → split → see [Splitting Plans](#splitting-plans).

**Scope validation:**
- [ ] Completable in a focused session
- [ ] All target files in a single projex scope
- [ ] Clear start and end points
- [ ] Success objectively measurable

### 3. CONTEXT RESEARCH

Answer by reading actual code:

1. **Current behavior** — trace actual call path; not assumptions
2. **Dependencies** — callers, callees, what breaks on change
3. **Conventions** — surrounding patterns (naming, error handling, structure)
4. **Edge cases** — inputs, states, timing that could break things
5. **Prior art** — related attempts? walkthroughs + git history for lessons

**Refine scope.** Research often reveals Step 2 boundaries too broad/narrow/wrong-layer. Adjust before drafting.

**Checkpoint (complex plans).** Before drafting, present briefly: findings, intended approach + why, scope adjustments. Catches misalignment early. Skip when path obvious.

### 4. DRAFT THE PLAN

```bash
{projex-scripts}/new-projex.{sh|ps1} <repo-root> plan "{plan-name}" <projex-folder>
```

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

Early steps used incomplete understanding. Re-read relevant code (don't rely on Step 3 memory):

1. **Assumptions** — Current State matches files now? Implicit ordering guaranteed? Signatures/return types/data shapes verified?
2. **Discrepancies** — Steps describe same file differently? Later step needs what earlier doesn't produce? Criteria test what steps don't deliver?
3. **Misunderstandings** — Actual call path / data flow vs plan? Side effects / validations / transformations missed? Modifying right layer (caller vs callee)?
4. **Overengineering** — Fewer steps possible? Unneeded abstractions/helpers? More direct approach equally valid?
5. **Principles**  — SOLID, YAGNI, DRY, KISS, etc.

After: fix anything caught. Approach fundamentally wrong → stop, discuss with user, don't patch broken plan. Surviving assumptions → Context → Assumptions so execution verifies early.

### 6. VALIDATION

Before marking Ready (cross-scope split decision deferred to step 7):

- [ ] Every step has specific file paths and before/after changes
- [ ] Each step has verification method
- [ ] Success criteria measurable and testable
- [ ] No open questions remain
- [ ] Any LLM/dev could follow without clarifying questions
- [ ] Dependencies and order unambiguous
- [ ] Plan stays within declared scope
- [ ] Granularity appropriate (not too broad, not too narrow)

### 7. SPLIT DECISION

Final gate before finalize. State the verdict explicitly.

**Auto-suggest split** when ALL: > 500 lines OR > 50 KB | > 5 steps.
**Always-required split** (see [Splitting Plans](#splitting-plans)): cross-scope | cross-repo | upstream/downstream mixing.

**Verdict — pick one:**
- `No split — single scope, within size budget`
- `No split — heuristic tripped but steps tightly coupled (rationale: …)`
- `Split required — proposing N child plans: …`
- `Split recommended — proposing N child plans: …`

If splitting: stop, generate child plans (each with own filename + `Dependencies`), discard/archive parent draft. Do not FINALIZE a plan being split.

### 8. ASSUME STEP STRATEGIES

Review each planned step:
- If a step is self-contained, needs little context, barely depends on prior execution details, or is mostly mechanical, add a `Do-Projex: Encouraged` header to it.
- If a step carries a testable `**Verification:**` method **and** is risky, wide-reaching, or easy to get subtly wrong, add a `Verify-Projex: Encouraged` line to it. Steps whose verification is trivial or whose failure is self-evident do not need it. User can override. Applies to self-execute mode — see `execute-projex.md` § 4.C.

### 9. FINALIZE

1. **Refine** — front-load key info (summary, scope, criteria)
2. **De-slop** (optional) — strip agent self-talk, filler, redundant restatements, unfilled template artifacts (see SKILL.md § De-slop)
3. **Update relationships** — links to/from related projex
4. **Set status** — `Ready` when complete
5. **Verify placement** — file in correct `.projex/` (already there from step 4)
6. **Commit** — must land on base branch before execution

```bash
{projex-scripts}/stage-n-commit.{sh|ps1} <repo-root> "projex: add plan - {plan-name}" .projex/{yymmddhhmm}-{plan-name}-plan.md
```

**Folder placement:** Plans move to `.projex/closed/` only after Walkthrough is authored. See SKILL.md § Organizing.

---

## STATUS TRANSITIONS

```
Draft (writing) → Ready (validated) → In Progress (executing) → Complete (Walkthrough authored)
                                                              → Blocked (document blocker) → Ready (when unblocked)
```

---

## SPLITTING PLANS

### When to split

**Required** (any apply): files cross > 1 `.projex/` scope | files cross > 1 repo | mixes upstream (spec/schema/API contract) + downstream (impl/client code).
**Recommended:** scope too large for a focused session | steps have no mutual dependency, can run independently.
**Size heuristic** (all apply → suggest split): > 500 lines OR > 50 KB | > 5 steps. On trip → propose split (vertical slice / horizontal layer / dependency group) before finalize. User declines or steps tightly coupled → proceed, note rationale in `Notes`.

### How to split

**By projex boundary (mandatory):**

> **Example:** spec change + C# runtime impl → two plans: `docs/.projex/...-macro-syntax-revision-plan.md` (Blocks: impl) + `src/.projex/...-macro-syntax-impl-plan.md` (Requires: spec). Wrong: one plan spanning both.

**By slice** (large scope within one boundary): vertical slices (end-to-end per feature) | horizontal layers (one layer across features) | dependencies (group by what must happen first).

### Split plan rules

Each split plan: independently executable | targets exactly one projex scope | links siblings via `Dependencies` (Requires/Blocks) | no circular deps.

---

## OUTPUT

Plan doc at `.projex/{yymmddhhmm}-{name}-plan.md` (pending) | updated relationships in source proposal + related projex. After exec + walkthrough → both move to `.projex/closed/`.

---

## NEXT STEPS

Workflow ends here. Present the plan; do not suggest or initiate execution. User chooses: `/execute-projex.md @{plan-file}` (execute) | `/review-projex.md` or `/redteam-projex.md` (challenge first) | revise, shelve, or reject.

---

## NOTES

- When in doubt, be more detailed rather than less
- If execution reveals the plan was wrong, update the plan for future reference
