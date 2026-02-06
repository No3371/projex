---
description: This workflow enables quick, lightweight actions — skipping the full Plan → Execute → Close cycle for small, well-understood changes. The output is a single Patch document that doubles as its own walkthrough. (This is part of @projex-framework skill. It is a MUST to load the skill first.)
---

## PURPOSE

Patches are the fast path for small, well-understood changes. When the overhead of Plan → Execute → Close exceeds the work itself, a patch lets you act directly while still maintaining traceability and documentation.

**Key characteristics:**
- Immediate action — no plan document, no ephemeral branch
- Single output document serves as both record and walkthrough
- Scope-guarded — escalates to full plan-execute if complexity warrants
- Still updates related projex and documents to match post-patch status
- Commits directly to current branch

**When to use Patch vs Plan-Execute:**
| Use Patch | Use Plan-Execute |
|-----------|------------------|
| Fix is obvious and well-understood | Problem needs investigation first |
| Scope is 1-3 files, focused change | Scope spans many files or components |
| No architectural decisions needed | Trade-offs or approach options exist |
| Can verify immediately | Requires multi-step verification plan |
| Partial execution of existing plan | Full plan execution |
| Quick bug fix, typo, config tweak | New feature, refactor, migration |

---

## INVOCATION

```
/patch-projex <directive>
```

**Examples:**
- `/patch-projex Fix the off-by-one error in the parser loop`
- `/patch-projex Execute objective 2 of @20260201-api-cleanup-plan.md`
- `/patch-projex Update config to use new endpoint URL`
- `/patch-projex Add missing null check in handleSubmit`

The directive can be:
- **A direct instruction** — Describe what to do
- **A reference to a plan objective** — Execute a specific part of an existing plan without the full ceremony

---

## SCOPE GUARD

**CRITICAL: Before taking any action, assess whether this truly qualifies as a patch.**

### Qualifies as Patch
- [ ] Change is well-understood — no exploration or design needed
- [ ] Scope is bounded — 1-3 files, focused modifications
- [ ] No branching decisions — single clear approach
- [ ] Verifiable immediately — can confirm correctness on the spot
- [ ] Low risk — unlikely to break unrelated functionality

### Escalate to Plan-Execute If
- Change requires exploring multiple approaches
- More than ~3 files need modification
- Architectural or design decisions are involved
- Change has wide blast radius or cross-cutting concerns
- Multiple stakeholders need to review the approach first
- You find yourself writing a plan in your head

**If scope exceeds patch threshold:** Stop, inform the user, and recommend `/plan-projex` instead. Do not proceed with a patch that should be a plan.

---

## WORKFLOW STEPS

### 1. CONTEXT ASSESSMENT

Before acting:

1. **Understand the directive** — What exactly needs to happen?
2. **Locate relevant files** — Read them, understand current state
3. **Check for related projex** — Is this part of an existing plan or proposal?
4. **Verify scope** — Run the scope guard checklist above
5. **Identify what else needs updating** — Related docs, specs, projex files

If the directive references an existing plan:
- Read the plan
- Identify the specific objective(s) being patched
- Note remaining objectives that are NOT being patched
- The plan's context/constraints still apply

### 2. EXECUTE THE CHANGE

Act directly:

1. **Make the changes** — Edit files, run commands, do the work
2. **Log actions as you go** — Track what you're doing for the patch document
3. **Verify immediately** — Run relevant tests, lint, build, or manual checks
4. **Fix issues** — If verification reveals problems, fix them before proceeding

**Commit convention:**

```bash
# Stage each changed file by explicit path — never use `git add .` or directories
git add path/to/changed-file1.ext
git add path/to/changed-file2.ext
git commit -m "projex(patch): [concise description of change]"
```

- Prefix: `projex(patch):` for traceability
- Single commit for the patch (group related changes)
- If the patch has distinct logical parts, multiple commits are acceptable

### 3. WRITE THE PATCH DOCUMENT

Create: `{yyyymmdd}-{patch-name}-patch.md`

The patch document IS the walkthrough. It is a single, self-contained record.

**Template:**

```markdown
# Patch: [Title]

> **Date:** YYYY-MM-DD
> **Author:** [name or agent]
> **Directive:** [The original instruction/request]
> **Source Plan:** [link to plan if patching a plan objective, otherwise "Direct"]
> **Result:** Success | Partial Success | Failed

---

## Summary

[2-3 sentences: What was done and why]

---

## Changes

### [File or Logical Group]

**File:** `path/to/file.ext`
**Change Type:** Modified | Created | Deleted
**What Changed:**
- [Specific change 1 — cite line numbers]
- [Specific change 2]

**Why:**
[Rationale for this change]

---

### [Next File or Group]

[Same structure]

---

## Verification

**Method:** [How correctness was verified — tests run, manual check, build, etc.]

**Result:**
```
[Actual output or evidence]
```

**Status:** PASS / FAIL

---

## Impact on Related Projex

| Document | Relationship | Update Made |
|----------|-------------|-------------|
| [projex doc] | [Source plan / Related proposal / etc.] | [What was updated] |

---

## Notes

[Optional: Gotchas encountered, insights, follow-up needed, anything worth recording]
```

**Placement:** `projex/closed/` — Patches are born closed. They document a completed action.

### 4. UPDATE RELATED DOCUMENTS

After the patch is written:

1. **If patching a plan objective:**
   - Update the plan: mark the patched objective as complete
   - Add a reference to the patch document
   - Note which objectives remain open
   - If ALL objectives are now complete (via patches or execution), update plan status to `Complete`

2. **If related to a proposal:**
   - Add a reference to the patch in the proposal's related projex
   - Note what the patch addressed

3. **If the patch changes behavior documented elsewhere:**
   - Update affected specs, docs, or other projex to reflect the new state
   - Ensure no document now contains stale information

4. **Commit document updates:**

```bash
# Stage each file by explicit path
git add projex/closed/{yyyymmdd}-{patch-name}-patch.md
git add projex/{yyyymmdd}-{related-plan-name}-plan.md
git add path/to/any-other-updated-doc.md
git commit -m "projex(patch): add patch doc - {patch-name}"
```

---

## HANDLING PARTIAL PLAN EXECUTION

When using patch to execute specific objectives from an existing plan:

### Referencing the Plan

The patch document MUST clearly state:
- Which plan it derives from
- Which specific objective(s) / step(s) were executed
- Which objectives remain pending

### Updating the Plan

In the source plan document:
- Mark completed objectives/steps with `[PATCHED]` and link to patch doc
- Do NOT change plan status unless all objectives are resolved
- Add to the plan's Related Projex section:

```markdown
> **Partial Execution:** Objective N completed via [patch doc link]
```

### Multiple Patches Against One Plan

If a plan is being completed piecemeal via patches:
- Each patch is an independent document in `projex/closed/`
- The plan tracks which objectives are patched vs pending
- When the last objective is patched, update plan status to `Complete` and move it to `projex/closed/`

---

## PATCH vs OTHER WORKFLOWS — DECISION AID

```
Is the task small, obvious, and bounded?
├── No → /plan-projex (needs planning)
└── Yes → Is it part of an existing plan?
    ├── Yes → Is it a single, isolated objective?
    │   ├── Yes → /patch-projex @plan objective N
    │   └── No → /execute-projex @plan (execute the full plan)
    └── No → Does it need exploration or evaluation first?
        ├── Yes → /eval-projex or /explore-projex first, then decide
        └── No → /patch-projex [directive]
```

---

## GIT INTEGRATION

### No Ephemeral Branch

Patches commit directly to the current branch. This is intentional — the overhead of branch creation, merge, and cleanup is disproportionate to the change size.

### Commit Sequence

```bash
# Step 1: Make changes and commit — stage each file by explicit path
git add path/to/changed-file1.ext
git add path/to/changed-file2.ext
git commit -m "projex(patch): [description]"

# Step 2: Write patch doc, update related documents, commit — stage each by explicit path
git add projex/closed/{yyyymmdd}-{patch-name}-patch.md
git add projex/{yyyymmdd}-{related-plan-name}-plan.md
git commit -m "projex(patch): add patch doc - {patch-name}"
```

### Git Operation Discipline

Same discipline applies as all projex workflows:
- Execute git commands one at a time
- Wait for completion and verify success before proceeding
- Never parallelize git operations

---

## OUTPUT

This workflow produces:
- The implemented change (committed to current branch)
- A patch document at `projex/closed/{yyyymmdd}-{patch-name}-patch.md`
- Updated related projex documents (if any)

**Folder structure:**
```
projex/
├── [pending projex...]
├── [source plan with patched objectives marked, if applicable]
└── closed/
    └── {yyyymmdd}-{patch-name}-patch.md
```

---

## QUALITY CHECKLIST

Before considering the patch complete:

- [ ] Change is implemented and committed
- [ ] Verification passed (tests, build, manual check)
- [ ] Patch document written with all changes detailed
- [ ] Related projex documents updated
- [ ] Patch document placed in `projex/closed/`
- [ ] All document updates committed
- [ ] No stale information left in related documents

---

## NOTES

- Patches are born closed — they go directly to `projex/closed/`
- The patch document is the walkthrough. There is no separate walkthrough
- If a patch fails verification, fix it or abandon it — don't leave broken state
- If you discover the patch is bigger than expected mid-execution, stop and escalate to `/plan-projex`
- Patches are still first-class projex documents — searchable, linkable, referenceable
- Use relative paths when referencing repository files
- The `projex(patch):` commit prefix distinguishes patches from full executions in git history
