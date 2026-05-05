# Dehydrate plan-projex.md

> **Status:** In Progress
> **Created:** 2026-05-05
> **Author:** agent
> **Source:** Direct request — user-confirmed dehydration proposal in prior conversation
> **Related Projex:** —
> **Worktree:** No

---

## Summary

Reduce `plan-projex.md` from 425 lines / ~15 KB to ~230 lines / ~7-8 KB by aggressive dehydration while preserving every rule, gate, status, split criterion, and at least one worked example per non-obvious rule. Single file, single scope.

**Scope:** `S:\Repos\projex\plan-projex.md` only.
**Estimated Changes:** 1 file, in-place rewrite of 8 sections.

---

## Objective

### Problem / Gap / Need

`plan-projex.md` is loaded into agent context every time the workflow runs but is read by humans rarely. Current text is verbose: prose where bullets work, three places duplicate split logic, a spec+impl example takes 6 lines, status transitions appear as both diagram and glossary, validation checklists are split into three sub-headings, ceremonial markdown (`> **Important:**`, `**bold:**` lead-ins) inflates length without adding semantics.

### Success Criteria

- [ ] File ≤ 250 lines and ≤ 8 KB
- [ ] Every original rule, gate, status, split criterion, and lifecycle phase still present (no semantic loss)
- [ ] At least one worked example retained per non-obvious rule (split-by-boundary keeps spec+impl example in compressed form)
- [ ] Step numbering preserved (1-8) — including SPLIT DECISION (7) and FINALIZE (8) added in prior turn
- [ ] Frontmatter `description` field unchanged
- [ ] All anchor links inside the file still resolve (`[Splitting Plans](#splitting-plans)`)
- [ ] Markdown still parseable; tables/code-fences still render

### Out of Scope

- Other `*-projex.md` files (each gets its own dehydration plan if desired)
- `SKILL.md` changes
- New rules, new gates, new sections
- Reordering of the 8 workflow steps
- Template structure inside the DRAFT THE PLAN code-fence (output template — readers consume it; do not compress)

---

## Context

### Current State

`plan-projex.md` — 425 lines, 15201 bytes. 8 numbered workflow steps, status transitions section, splitting plans section, output section, next steps, notes. Recently amended: step 7 SPLIT DECISION added (lines 303-320), step 8 FINALIZE renumbered, size heuristic added under SPLITTING PLANS (lines 369-373).

### Key Files

| File | Role | Change Summary |
|------|------|----------------|
| `plan-projex.md` | Workflow spec for /plan-projex | Rewrite in dehydrated form, preserve semantics |

### Dependencies

- **Requires:** SKILL.md § Dehydrate (the standing register the rewrite must follow)
- **Blocks:** No active downstream — other workflows reference plan-projex by filename only

### Constraints

- Must not break the inline anchor `[Splitting Plans](#splitting-plans)` — header text "SPLITTING PLANS" must remain
- Code-fence content (template, bash commands) is preserved verbatim — readers consume it
- Filename and frontmatter `description` unchanged
- Step numbers 1-8 preserved verbatim

### Assumptions

- The DRAFT-THE-PLAN template (lines 102-251) is the output spec readers consume; compressing its inline guidance would degrade utility. Verify early.
- Anchor `#splitting-plans` is generated from `## SPLITTING PLANS` heading; lowercase-with-hyphens. Verify GitHub/standard markdown anchor rule still produces same target after edits.
- No external project links to specific line numbers in this file (filename-only references per SKILL.md).

### Impact Analysis

- **Direct:** `plan-projex.md`
- **Adjacent:** Agent context budget (every /plan-projex invocation loads this file) — net positive
- **Downstream:** None — workflow behavior unchanged, only expression changes

---

## Implementation

### Overview

Six edit passes against `plan-projex.md`, each scoped to one technique. Verify line/byte count between major passes to track progress against the 250-line / 8 KB budget. Final pass is a coherence + anchor + de-slop sweep.

### Step 1: Dehydrate steps 1-7 prose

**Objective:** Convert step bodies from explanatory prose to imperative bullets / key:value form. Leave step headings, sub-headings, and code-fence blocks untouched.
**Confidence:** High
**Depends on:** None

**Files:**
- `plan-projex.md`

**Changes:**

Apply per-step. Examples (representative, not exhaustive):

```markdown
// Before (step 1 SOURCE ANALYSIS, line 33):
**Resolve the target repo**: if a projex file is referenced, we find the exact git repo the projex belongs to. If no file is referenced, infer from context.

// After:
**Resolve target repo** — projex file referenced → find its git repo. No reference → infer from context.
```

```markdown
// Before (step 1, line 48-51):
Set **Worktree: Yes** if any of:
- Working directory has uncommitted changes (dirty state — avoids stashing during execution)
- An active `projex/*` execution branch already exists (worktree enables parallel execution)
- The plan involves many files or large-scale changes (worktree isolates disruption from editors/IDEs)

// After:
**Worktree: Yes** if: dirty working dir | active `projex/*` branch | many files / large changes.
```

```markdown
// Before (step 5 SECOND PASS, lines 259-272 — four numbered sub-sections each with 3-4 bullets):
1. **Assumptions** — What does the plan take for granted?
   - Does the "Current State" section match what the files actually show right now?
   - Are there implicit ordering assumptions (e.g., "X exists before Y runs") that aren't guaranteed?
   ...

// After:
1. **Assumptions** — Current State matches files? Implicit ordering? Unverified signatures/shapes?
2. **Discrepancies** — Steps describe same file differently? Later step needs what earlier doesn't produce? Criteria test what steps don't deliver?
3. **Misunderstandings** — Trace actual call/data flow vs plan. Side effects, validations, transformations missed? Wrong layer?
4. **Overengineering** — Fewer steps possible? Unneeded abstractions/helpers? More direct approach equally valid?
```

**Rationale:** Steps 1-7 are agent-consumed instructions; bullets and `key — value` survive comprehension better than narrative for non-human readers. Code-fences and template blocks stay verbatim.

**Verification:** `wc -l plan-projex.md` decreases ~80-120 lines after this pass. Open file, scan each step's heading and ensure all original sub-points still present in compressed form.

**If this fails:** `git checkout -- plan-projex.md` (file not yet committed at start of step).

---

### Step 2: Deduplicate split logic

**Objective:** Split logic currently appears in three places. Keep step 7 SPLIT DECISION as the active gate, keep SPLITTING PLANS as the canonical reference, replace the duplicate-checkbox in step 6 VALIDATION with a one-line cross-reference.
**Confidence:** High
**Depends on:** Step 1

**Files:**
- `plan-projex.md`

**Changes:**

```markdown
// Before (step 6 VALIDATION, lines 298-301):
**Scope:**
- [ ] Plan stays within declared scope
- [ ] All files belong to ONE projex scope — if not, split
- [ ] Appropriately granular (not too broad, not too narrow)

// After:
**Scope:** stays within declared scope | granular (not too broad/narrow) | (split decision deferred to step 7)
```

```markdown
// Before (line 74, Boundary Rule callout):
> **Boundary Rule:** A plan targets exactly ONE projex scope. Changes across multiple scopes or repos → split into separate plans linked via `Dependencies`. See [Splitting Plans](#splitting-plans).

// After (inline, no callout):
**Boundary Rule:** plan targets exactly ONE projex scope. Cross-scope/repo → split → see [Splitting Plans](#splitting-plans).
```

**Rationale:** The mandatory cross-scope/repo rule lives canonically in SPLITTING PLANS and step 7 references it. Step 6 only needs to flag scope/granularity validation.

**Verification:** Search file for "split" — confirm three locations: step 7 (active gate), SPLITTING PLANS (canonical), Boundary Rule + step 6 cross-ref (pointers). No duplication of the cross-scope/repo trio.

**If this fails:** Revert this hunk only via `git checkout -p plan-projex.md`.

---

### Step 3: Collapse worked example (spec+impl)

**Objective:** Compress the 6-line spec+impl example (lines 379-384) to 1-2 lines while preserving the Wrong/Right contrast and the Dependencies pattern.
**Confidence:** High
**Depends on:** Step 1

**Files:**
- `plan-projex.md`

**Changes:**

```markdown
// Before:
> **Example — spec + implementation:**
> A language spec change requires updating the C# runtime.
> - **Wrong:** One plan covering both spec markdown and C# source.
> - **Right:** Two plans:
>   1. `docs/.projex/2602081430-macro-syntax-revision-plan.md` — Spec only. Dependencies: "Blocks: impl plan."
>   2. `src/.projex/2602081430-macro-syntax-impl-plan.md` — C# only. Dependencies: "Requires: spec plan."

// After:
> **Example:** spec change + C# runtime impl → 2 plans: `docs/.projex/...-spec-plan.md` (Blocks: impl) + `src/.projex/...-impl-plan.md` (Requires: spec). Wrong: one plan spanning both.
```

**Rationale:** Pattern is the value (cross-scope split + Requires/Blocks linking); the framing is fluff. One concrete-enough sentence preserves it.

**Verification:** Example still shows: cross-scope boundary, two filenames in different `.projex/`, Dependencies field with Requires + Blocks.

**If this fails:** Revert hunk.

---

### Step 4: Pick one — status transitions diagram OR glossary

**Objective:** Lines 343-352 show the same info twice: ASCII diagram + bullet glossary. Keep only the diagram, with inline labels for the four states.
**Confidence:** Medium — verify the bullet glossary doesn't add anything the diagram lacks (tooltip-style "what does Blocked mean?" detail).
**Depends on:** Step 1

**Files:**
- `plan-projex.md`

**Changes:**

```markdown
// Before:
```
Draft → Ready → In Progress → Complete
                            → Blocked → Ready (when unblocked)
```

- **Draft**: Still being written
- **Ready**: Validated and ready for execution
- **In Progress**: Currently being executed
- **Blocked**: Cannot proceed (document blocker)
- **Complete**: Execution finished, Walkthrough authored

// After:
```
Draft (writing) → Ready (validated) → In Progress (executing) → Complete (walkthrough authored)
                                                              → Blocked (document blocker) → Ready (unblocked)
```
```

**Rationale:** Inline labels preserve glossary semantics inside the diagram; saves ~6 lines.

**Verification:** All five states still labelled with original meaning. No state lost.

**If this fails:** Revert and keep both representations.

---

### Step 5: Flatten validation checklists

**Objective:** Step 6 VALIDATION currently has three sub-headings (Completeness / Executability / Scope) with 9 checkboxes total. Flatten to a single 8-item list (the 9th moves to step 7 per Step 2).
**Confidence:** High
**Depends on:** Steps 1, 2

**Files:**
- `plan-projex.md`

**Changes:**

```markdown
// Before (lines 286-301): three sub-headings with 9 boxes

// After:
### 6. VALIDATION

Before marking Ready (split decision deferred to step 7):
- [ ] Every step has specific file paths and before/after changes
- [ ] Each step has verification method
- [ ] Success criteria measurable and testable
- [ ] No open questions remain
- [ ] Any LLM/dev could follow without clarifying questions
- [ ] Dependencies and order unambiguous
- [ ] Plan stays within declared scope
- [ ] Granularity appropriate (not too broad, not too narrow)
```

**Rationale:** Sub-headings added vertical space without changing semantics. Flat list reads faster.

**Verification:** All 8 original criteria still present (the 9th — "All files belong to ONE projex scope — if not, split" — was migrated to step 7's purview in Step 2).

**If this fails:** Revert hunk.

---

### Step 6: Strip ceremonial markdown + final coherence pass

**Objective:** Remove `> **Important:**` callouts, redundant `**bold:**` lead-ins, "See SKILL.md § X" repetitions when already cross-referenced elsewhere, agent self-talk that survived Steps 1-5. Final read-through for coherence and anchor integrity.
**Confidence:** Medium — judgment call per occurrence; some callouts are clarity carve-outs (SKILL.md says don't dehydrate security warnings / irreversible actions) — keep those.
**Depends on:** Steps 1-5

**Files:**
- `plan-projex.md`

**Changes:**

Targets:
- `> **Important:** Plans must be committed before...` (line 335) — keep as inline note (irreversible-action-adjacent: execution branch creation depends on committed plan)
- "Folder placement: See SKILL.md § Organizing." appears multiple times → keep one, drop duplicates
- `**Mandatory re-examination.**` opening of step 5 → drop, content carries the imperative
- `**After this pass:**` (line 279) → drop, structure makes it obvious

**De-slop sweep:** SKILL.md § De-slop — re-read whole doc as a reader, strip surviving filler.

**Verify anchors:** Open `plan-projex.md`, find `[Splitting Plans](#splitting-plans)` references, confirm `## SPLITTING PLANS` heading still exists.

**Verify line/byte targets:**
```bash
wc -l plan-projex.md   # expect ≤ 250
wc -c plan-projex.md   # expect ≤ 8192
```

**Rationale:** Ceremonial markdown is the residue dehydration is meant to remove. Final pass also catches what Steps 1-5 missed.

**Verification:** Targets met. `git diff plan-projex.md` shows only intended changes. Open file in editor — reads coherently start to finish, no orphaned references.

**If this fails:** Stop and stage what's good; the 250/8KB target is aspirational, not blocking. If file is at 280 lines / 9KB but every Success Criterion bullet is met, that's success.

---

## Verification Plan

### Automated Checks

- [ ] `wc -l plan-projex.md` ≤ 250
- [ ] `wc -c plan-projex.md` ≤ 8192
- [ ] No markdown lint errors introduced (if linter configured — none currently)
- [ ] Anchor `#splitting-plans` still resolves (heading text unchanged)

### Manual Verification

- [ ] Read final file top-to-bottom as a first-time reader. Workflow steps 1-8 still understandable, gates clear, template intact.
- [ ] Diff old vs new with eye on completeness — no rule, gate, status, or split criterion silently dropped.
- [ ] Confirm spec+impl example still conveys cross-scope split + Requires/Blocks pattern.

### Acceptance Criteria Validation

| Criterion | How to Verify | Expected Result |
|-----------|---------------|-----------------|
| ≤ 250 lines, ≤ 8 KB | `wc -l && wc -c` | Pass |
| Semantic preservation | Manual diff review | Every original rule findable in new doc |
| Worked example retained | Read SPLITTING PLANS § | Spec+impl pattern survives in compressed form |
| Step numbering 1-8 preserved | Grep `^### \d\.` | Eight matches, in order |
| Anchor still resolves | Click/follow `[Splitting Plans](#splitting-plans)` | Lands at SPLITTING PLANS heading |

---

## Rollback Plan

Single-file edit, not yet committed. If the dehydration goes wrong:

1. `git checkout -- plan-projex.md` — full revert to pre-dehydration state.
2. If partial commits were made, `git log --oneline plan-projex.md` to find the pre-edit SHA, `git checkout <sha> -- plan-projex.md`.

No branch, no merge, no downstream coordination needed.

---

## Notes

### Risks

- **Over-compression:** dehydration past clarity threshold makes the spec harder for the agent to follow correctly. Mitigation: Step 6's de-slop pass + final read-through, and the byte target is aspirational not absolute.
- **Anchor breakage:** if `## SPLITTING PLANS` is renamed during edits, the inline `[Splitting Plans](#splitting-plans)` link breaks. Mitigation: Step 6 verification step explicitly checks this.
- **Lost worked example:** if Step 3's compression drops a load-bearing detail (e.g., the `Dependencies` field semantics), agents may misapply the split rule. Mitigation: Step 3 verification enumerates what must survive.

### Open Questions

- [ ] (none — pre-flight clear)
