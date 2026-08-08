---
description: Quick, lightweight actions — skip the full Plan → Execute → Close cycle for small, well-understood changes. Output is one Patch document that doubles as its own walkthrough. (Part of @projex-framework skill. MUST load the skill first.)
---

## PURPOSE

Patches are the fast path for small, well-understood changes. When Plan → Execute → Close overhead exceeds the work itself, a patch lets you act directly while keeping traceability and documentation.

**Key characteristics:**
- Immediate action — no plan document, no ephemeral branch
- Single output doc is both record and walkthrough
- Scope-guarded — escalates to plan-execute if complexity warrants
- Still updates related projex/docs to post-patch status
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
- `/patch-projex Execute objective 2 of @2602011430-api-cleanup-plan.md`
- `/patch-projex Update config to use new endpoint URL`
- `/patch-projex Add missing null check in handleSubmit`

The directive can be:
- **A direct instruction** — what to do
- **A reference to a plan objective** — execute a specific part of an existing plan without the full ceremony

---

## SCOPE GUARD

**CRITICAL: Before any action, assess whether this truly qualifies as a patch.**

### Qualifies as Patch
- [ ] Change is well-understood — no exploration or design needed
- [ ] Scope is bounded and focused (file count is a signal, not a rule — a 4-file rename can be a patch, a 1-file architectural change shouldn't be)
- [ ] No branching decisions — single clear approach
- [ ] Verifiable immediately — can confirm correctness on the spot

### Escalate to Plan-Execute If
- Change requires exploring multiple approaches
- Architectural or design decisions are involved
- Change has wide blast radius or cross-cutting concerns
- Multiple stakeholders need to review the approach first
- You find yourself writing a plan in your head

**If scope exceeds patch threshold:** Stop, inform the user, recommend `/plan-projex` instead. Do not proceed with a patch that should be a plan.

---

## WORKFLOW STEPS

### 1. CONTEXT ASSESSMENT

Before acting:

1. **Resolve the target repo** — If the directive references a projex file, find the exact git repo it belongs to. If no file is referenced, infer from context.
```bash
cd <absolute-path-to-projex-file-directory> && git rev-parse --show-toplevel
```
Record the `--show-toplevel` output as `<repo-root>`. All script calls below use this value.
2. **Understand the directive** — What exactly needs to happen?
3. **Locate relevant files** — Read them, understand current state
4. **Check for related projex** — Part of an existing plan or proposal?
5. **Verify scope** — Run the scope guard checklist above
6. **Identify what else needs updating** — Related docs, specs, projex files

If the directive references an existing plan:
- Read the plan
- Identify the specific objective(s) being patched
- Note remaining objectives NOT being patched
- The plan's context/constraints still apply

### 2. EXECUTE THE CHANGE

Act directly:

1. **Make the changes** — Edit files, run commands, do the work
2. **Log actions as you go** — Track work for the patch document
3. **Verify immediately** — Run relevant tests, lint, build, or manual checks
4. **Fix issues** — If verification reveals problems, fix before proceeding

**Commit convention:**

```bash
{projex-scripts}/stage-n-commit.{sh|ps1} <repo-root> "projex(patch): [concise description of change]" path/to/changed-file1.ext path/to/changed-file2.ext
```

- Prefix: `projex(patch):` for traceability
- Single commit for the patch (group related changes)
- Distinct logical parts → multiple commits acceptable

### 3. WRITE THE PATCH DOCUMENT

```bash
{projex-scripts}/new-projex.{sh|ps1} <repo-root> patch "{patch-name}" <projex-folder>
```

The patch document IS the walkthrough. One self-contained record.

**Template:**

```markdown
# Patch: [Title]

> **Author:** [Model(Role), or Model, or self identity, fallback: "Agent"]
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

**Placement:** `.projex/closed/` — Patches are born closed. They document a completed action.

### 4. UPDATE RELATED DOCUMENTS

After the patch is written:

1. **If patching a plan:**
   - Mark the patched work with `[PATCHED]` and link to the patch doc
   - Note what remains open, if anything
   - Add to the plan's Related Projex section: `> Partial Execution: [description] completed via [patch doc link]`
   - If the patch leaves nothing more to do within the plan, set plan status to `Complete` and move the plan to `.projex/closed/`

2. **If related to a proposal:**
   - Reference the patch in the proposal's related projex
   - Note what the patch addressed

3. **If the patch changes behavior documented elsewhere:**
   - Update affected specs, docs, or other projex to reflect the new state
   - Leave no stale information

4. **Update nav (if noted):** If the patch notes `> **Nav:** {nav-filename}`, update that nav only: check off the milestone, link the patch under it, append a Revision Log entry. Do not search for navs not referenced by the patch.

5. **Update any other relevant projex documents**

6. **Commit document updates:**

```bash
{projex-scripts}/stage-n-commit.{sh|ps1} <repo-root> "projex(patch): add patch doc - {patch-name}" \
  .projex/closed/{yymmddhhmm}-{patch-name}-patch.md \
  .projex/{yymmddhhmm}-{related-plan-name}-plan.md \
  .projex/{yymmddhhmm}-{nav-name}-nav.md \
  path/to/any-other-updated-doc.md
```

---

## PATCH vs OTHER WORKFLOWS — DECISION AID

```
Small, obvious, and bounded? ─── No → /plan-projex
 └─ Yes → Needs exploration first? ─── Yes → /eval-projex or /explore-projex
     └─ No → Part of an existing plan needing full execution? ─── Yes → /execute-projex
         └─ No → /patch-projex
```

---

## GIT INTEGRATION

### No Ephemeral Branch

Patches commit directly to the current branch. Intentional — branch creation, merge, and cleanup overhead is disproportionate to the change size.

### Commit Sequence

```bash
# Step 1: Make changes and commit
{projex-scripts}/stage-n-commit.{sh|ps1} <repo-root> "projex(patch): [description]" path/to/changed-file1.ext path/to/changed-file2.ext

# Step 2: Write patch doc, update related documents, commit
{projex-scripts}/stage-n-commit.{sh|ps1} <repo-root> "projex(patch): add patch doc - {patch-name}" \
  .projex/closed/{yymmddhhmm}-{patch-name}-patch.md \
  .projex/{yymmddhhmm}-{related-plan-name}-plan.md
```

### Git Operation Discipline

See SKILL.md § Git Operation Discipline.

---

## OUTPUT

This workflow produces:
- The implemented change (committed to current branch)
- A patch document at `.projex/closed/{yymmddhhmm}-{patch-name}-patch.md`
- Updated related projex documents (if any)

**Folder structure:**
```
.projex/
├── [pending projex...]
├── [source plan with patched objectives marked, if applicable]
└── closed/
    └── {yymmddhhmm}-{patch-name}-patch.md
```

---

## QUALITY CHECKLIST

Before considering the patch complete:

- [ ] Change implemented and committed
- [ ] Verification passed (tests, build, manual check)
- [ ] Patch document written with all changes detailed
- [ ] Related projex documents updated
- [ ] Patch document placed in `.projex/closed/`
- [ ] Nav updated if patch noted one
- [ ] All document updates committed
- [ ] No stale information left in related documents

---

## NOTES

- Patches are born closed — go directly to `.projex/closed/`
- The patch document is the walkthrough. No separate walkthrough
- If a patch fails verification, fix it or abandon it — don't leave broken state
- If the patch grows bigger than expected mid-execution, stop and escalate to `/plan-projex`
- Patches are still first-class projex documents — searchable, linkable, referenceable
- Use relative paths when referencing repository files
- The `projex(patch):` commit prefix distinguishes patches from full executions in git history
