---
description: This workflow guides the creation of **Proposal** projex documents — exploratory documentation for new ideas, changes, or decisions. (This is part of @projex-framework skill. It is a MUST to load the skill first.)
---

## PURPOSE

Proposals capture early-stage thinking before committing to implementation. They explore possibilities, document trade-offs, and enable informed decision-making.

**Key characteristics:**
- Directional: explores a specific change or idea — "what if we go this way?"
- Captures reasoning, trade-offs, potential approaches and impact analysis
- Provides foundation for future Plan projex documents if accepted

**Contrast with Evaluation and Exploration:**
- **Proposal** — directional: proposes something specific, explores approaches and impact for that direction
- **Evaluation** — open-ended: any question, idea, or solution; no fixed framing or direction
- **Exploration** — anchored to the status quo: investigates what exists, how it works, and why

---

## INVOCATION

```
/propose-projex.md <idea or change description>
```

**Examples:**
- `/propose-projex.md I want to add a caching layer to the API`
- `/propose-projex.md Migrate from REST to GraphQL`
- `/propose-projex.md Consolidate authentication across microservices`

---

## WORKFLOW STEPS

### 1. CONTEXT GATHERING

Before drafting the proposal:

1. **Understand the idea** — Clarify the user's intent through questions if needed
2. **Explore status quo** — Research current implementation, architecture, patterns
3. **Identify scope** — Determine which projex folder(s) this proposal belongs to
4. **Find related projex** — Search for existing proposals, plans, or evaluations that relate

```
Questions to answer:
- What problem or opportunity does this idea address?
- What exists today that this idea would affect?
- Has this been proposed or attempted before?
- Who/what would be impacted by this change?
```

### 2. DRAFT THE PROPOSAL

```bash
{projex-scripts}/new-projex.{sh|ps1} <repo-root> propose "{proposal-name}" <projex-folder>
```

**Template Structure:**

```markdown
# [Proposal Title]

> **Status:** Draft | In Progress | Complete (Accepted) | Complete (Rejected)
> **Created:** YYYY-MM-DD
> **Author:** [name or agent]
> **Related Projex:** [links to related projex documents]

---

## Summary

[2-3 sentence high-level description of the proposal]

---

## Problem Statement

### Current State
[Describe the status quo — what exists today]

### Gap / Need / Opportunity
[What problem does this solve? What opportunity does it enable?]

### Why Now?
[What makes this timely? What changed that makes this relevant?]

---

## Proposed Change

### Overview
[High-level description of what is being proposed]

### Approach Options

#### Option A: [Name]
- **Description:** [How this approach works]
- **Pros:** [Benefits]
- **Cons:** [Drawbacks]
- **Effort:** [Relative complexity/effort]

#### Option B: [Name]
[Same structure as Option A]

### Recommended Approach
[Which option is recommended and why]

---

## Impact Analysis

### Affected Areas
- [Component/module 1]: [How it's affected]
- [Component/module 2]: [How it's affected]

### Dependencies
- [What this proposal depends on]
- [What might depend on this proposal]

### Risks
| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| [Risk 1] | Low/Med/High | Low/Med/High | [How to mitigate] |

### Breaking Changes
[Any backward compatibility concerns]

---

## Open Questions

- [ ] [Question 1 that needs resolution]
- [ ] [Question 2 that needs resolution]

---

## Next Steps

If accepted:
1. [First action item]
2. [Second action item]

---

## Appendix

### Research / References
[Links to relevant documentation, articles, prior art]

### Alternatives Considered
[Other approaches that were evaluated and rejected, with reasoning]
```

### 3. INITIAL PLACEMENT

Save the proposal in the appropriate `.projex/` folder based on scope:

- **Repo-wide changes** → Root `.projex/` folder
- **Module-specific changes** → That module's `.projex/` folder
- **Cross-cutting concerns** → Root `.projex/` with references in affected modules

**Folder by status:**
- **Pending** (Draft / In Progress) → `.projex/` (parent folder)
- **Complete (Accepted)** → Remains in `.projex/` until derived Plan is closed
- **Complete (Rejected)** → Move to `.projex/archived/` or delete

### 4. REFINEMENT

After initial draft:

1. **Front-load key information** — Move summary and recommendation to the top
2. **Add relationships** — Link to/from related projex documents
3. **Validate scope** — Ensure proposal doesn't cross projex folder boundaries inappropriately
4. **Set status** — Mark as `Draft` initially

### 5. REVIEW READINESS

Before moving to `In Progress` (under review) status:

- [ ] Summary clearly states the proposal in 2-3 sentences
- [ ] Problem statement explains why this matters
- [ ] At least 2 approach options are explored
- [ ] Impact analysis covers affected areas and risks
- [ ] Open questions are documented
- [ ] Related projex documents are linked

---

## STATUS TRANSITIONS

```
Draft → In Progress → Complete (Accepted)
                    → Complete (Rejected)
```

- **Draft**: Initial creation, still being refined
- **In Progress**: Under review — ready for stakeholder feedback
- **Complete (Accepted)**: Approved for implementation (derive Plan projex)
- **Complete (Rejected)**: Not moving forward (document reasoning)

---

## OUTPUT

This workflow produces:
- A proposal projex document at `.projex/{yymmddhhmm}-{name}-proposal.md`
- Updated relationships in any related projex documents

**Folder placement:** See SKILL.md § Organizing. `Complete (Accepted)` proposals stay in `.projex/` until their Plan is closed.

**Committing:** Present the proposal document to the user. Do not commit automatically — commit only when the user explicitly requests it.

---

## NOTES

- Proposals should explore, not prescribe — save detailed implementation for Plan projex
- Keep proposals focused; split into multiple if scope grows too large
- Use relative paths when referencing files in the repository
- Challenge assumptions and document alternative viewpoints
