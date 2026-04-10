# Add Dehydrate as Always-On Authoring Principle

> **Status:** In Progress
> **Created:** 2026-04-11
> **Author:** Claude (agent)
> **Source:** 2604110126-dehydrate-authoring-mode-proposal.md (accepted with modification: always-on, not opt-in)
> **Related Projex:** 2604110126-dehydrate-authoring-mode-proposal.md
> **Worktree:** No

---

## Summary

Add a "Dehydrate" subsection to SKILL.md § Authoring that defines maximally compressed writing as the default authoring register for all projex documents. Not a mode to activate — a standing principle that governs how projex prose is written.

**Scope:** SKILL.md lines 29-49 (Authoring section)
**Estimated Changes:** 1 file, 1 new section insertion

---

## Objective

### Problem / Gap / Need

Projex documents are consumed by humans and agents. The framework has De-slop (strip filler from finished prose) but nothing that says "write dense from the start." Without this, agents default to verbose prose — full sentences, narrative transitions, articles/prepositions — that wastes tokens for agent consumers and scan-time for human consumers.

### Success Criteria

- [ ] SKILL.md § Authoring contains a "Dehydrate" subsection before De-slop
- [ ] Section defines concrete compression techniques with before/after examples
- [ ] Framed as always-applied principle, not opt-in mode — no activation mechanism, no header flags
- [ ] De-slop remains as a complementary cleanup pass (unchanged)
- [ ] Relationship between Dehydrate and De-slop is stated clearly

### Out of Scope

- Changes to individual workflow specs
- Per-type default overrides
- Activation mechanisms or header flags

---

## Context

### Current State

SKILL.md § Authoring (lines 29-49):
- Line 29: `## Authoring` header
- Lines 31-35: File naming, cross-referencing, front-loading, reference-by-filename rules
- Lines 37-49: `### De-slop (optional final pass)` — post-hoc cleanup of agent filler

De-slop is positioned correctly as a post-processing step. Dehydrate is a different concern — it governs the output register during writing, not cleanup after.

### Key Files

| File | Role | Change Summary |
|------|------|----------------|
| `SKILL.md` | Framework spec | Insert Dehydrate subsection before De-slop |

### Dependencies

- **Requires:** None
- **Blocks:** None

### Constraints

- Must not alter De-slop content or semantics
- Must be concise itself (practice what it preaches)
- Techniques must be concrete enough for consistent application across agents/sessions

### Assumptions

- The Authoring section's subsection ordering (Dehydrate before De-slop) correctly reflects the logical sequence: write dense first, then clean up if needed
- The proposal's technique catalog (Option A) is the right format, adapted to always-on framing

### Impact Analysis

- **Direct:** SKILL.md — new subsection added
- **Adjacent:** De-slop — unchanged but repositioned as complementary (cleanup after dehydrated writing)
- **Downstream:** All future projex documents — agents will write in dehydrated register by default

---

## Implementation

### Overview

Insert a `### Dehydrate` subsection into SKILL.md § Authoring, positioned between the existing authoring bullets (line 35) and the De-slop subsection (line 37). The section defines compression techniques as standing principles, not a mode.

### Step 1: Insert Dehydrate Section into SKILL.md

**Objective:** Add the Dehydrate subsection with technique definitions and examples.

**Confidence:** High

**Depends on:** None

**Files:**
- `SKILL.md`

**Changes:**

Insert the following after line 35 (after the "Reference by filename" bullet) and before line 37 (the De-slop header):

```markdown
### Dehydrate

All projex output uses the densest form that fully preserves semantic and technical content. This is not a mode — it is how projex documents are written.

**Techniques:**

- **Drop filler words** — remove articles, prepositions, connectives where meaning survives without them
  - `"The parser module is responsible for converting the input stream into an AST"` → `"Parser module: converts input stream → AST"`
- **Key-value shorthand** — replace narrative with `key: value` structure
  - `"The migration is currently blocked because the schema validator has not been updated"` → `"Migration: blocked — schema validator not updated"`
- **Symbolic compression** — `→` (produces/becomes), `←` (sourced from), `✓/✗` (pass/fail), `|` (or/alternatives), `~` (approximately)
- **Inline lists** — for items under ~5 words each, use `|` separators instead of bullet lists
  - `"Affected: auth module | session store | token validator"`
- **No transitions** — omit "Moving on to..." / "Now that we've covered X..."
- **Compressed headers** — strip filler from section titles
  - `"## Analysis of the Current Authentication State"` → `"## Auth Current State"`
- **Abbreviate when unambiguous** — impl, config, auth, repo, fn, param, dep, req, spec (define on first use if non-standard)

**Relationship to De-slop:** Dehydrate governs how content is written. De-slop catches filler that slipped through anyway. Both apply — Dehydrate is the standing register, De-slop is the safety net.
```

**Rationale:** Positioned before De-slop to reflect logical sequence (write dense → clean up residual). Framed as "how projex documents are written" — no activation language. Techniques are concrete with inline examples to anchor behavior.

**Verification:** Read SKILL.md § Authoring after edit. Confirm:
1. Dehydrate section appears between authoring bullets and De-slop
2. No activation/mode language present
3. De-slop section unchanged
4. Examples demonstrate real compression

**If this fails:** Revert the SKILL.md edit via `git checkout -- SKILL.md`.

---

### Step 2: Update Proposal Status

**Objective:** Mark the source proposal as Accepted with the always-on modification noted.

**Confidence:** High

**Depends on:** Step 1

**Files:**
- `.projex/2604110126-dehydrate-authoring-mode-proposal.md`

**Changes:**

```markdown
// Before:
> **Status:** Draft

// After:
> **Status:** Accepted
```

Add note in the Summary section indicating the accepted direction:

```markdown
// Before:
Add a "Dehydrate" section to SKILL.md's Authoring block — a directive that instructs agents to produce maximally compressed output while fully preserving semantic and technical content. Unlike De-slop (which strips filler from normal prose), Dehydrate is a fundamentally different output register: dense shorthand from the start, not cleaned-up prose.

// After:
Add a "Dehydrate" section to SKILL.md's Authoring block — a standing principle (not opt-in mode) that all projex output uses maximally compressed form while fully preserving semantic and technical content. Unlike De-slop (which strips filler from normal prose), Dehydrate is a fundamentally different output register: dense shorthand from the start, not cleaned-up prose.

> **Accepted with modification (2026-04-11):** Dehydrate is always-on — no activation mechanism, no header flags, no per-document opt-in. It is how projex documents are written.
```

Remove the "Activation Mechanism" subsection from Impact Analysis and the related open question.

**Rationale:** Keeps the proposal honest about what was accepted vs. what was proposed.

**Verification:** Read proposal header — Status should be `Accepted`.

**If this fails:** Non-critical — proposal update is traceability, not functional.

---

## Verification Plan

### Manual Verification

- [ ] Read SKILL.md § Authoring top-to-bottom — Dehydrate → De-slop ordering is logical
- [ ] Dehydrate section contains zero activation/mode/opt-in language
- [ ] All 7 techniques have concrete examples or definitions
- [ ] De-slop section content is byte-identical to before
- [ ] Proposal status updated to Accepted

### Acceptance Criteria Validation

| Criterion | How to Verify | Expected Result |
|-----------|---------------|-----------------|
| Dehydrate subsection exists before De-slop | Read SKILL.md | Section present at correct position |
| Concrete techniques with examples | Read section | 7 techniques, 4 with inline before/after |
| Always-on framing | Grep for "mode", "opt-in", "activate" | Zero matches in Dehydrate section |
| De-slop unchanged | Diff De-slop section | No changes |

---

## Rollback Plan

1. `git checkout -- SKILL.md` to revert framework spec
2. `git checkout -- .projex/2604110126-dehydrate-authoring-mode-proposal.md` to revert proposal status

---

## Notes

### Risks

- Agents may over-compress and lose nuance in human-facing types (Guide, Interview): Mitigation — the principle says "fully preserves semantic and technical content"; compression targets form, not substance. Guide and Interview workflows can note exceptions if needed later.

### Open Questions

- (none — all resolved by the always-on decision)
