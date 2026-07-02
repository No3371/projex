---
description: This workflow guides the creation of **Exploration** projex documents — comprehensive investigation of status quo, subject domains, or specific questions to build deep understanding and inform decisions. (This is part of @projex-framework skill. It is a MUST to load the skill first.)
---

## PURPOSE

Explorations provide thorough, grounded investigation into what exists, how it works, and why it matters. They build comprehensive understanding through systematic inquiry.

**Key characteristics:**
- Deep dive into existing systems, domains, or phenomena
- Comprehensive mapping of current reality
- Discovery-oriented investigation
- Foundation for informed decision-making

**Contrast with Evaluation and Proposal:**
- **Exploration** — anchored to the status quo: investigates what exists, how it works, and why
- **Evaluation** — open-ended: any question, idea, or solution; no fixed framing or direction
- **Proposal** — directional: explores a specific change or idea with trade-offs and approaches

---

## INVOCATION

```
/explore-projex.md <question or subject>
```

**Examples:**
- `/explore-projex.md How does our authentication system work?`
- `/explore-projex.md What are the patterns in our API design?`
- `/explore-projex.md Why do we have these caching layers?`
- `/explore-projex.md @src/core/engine.rs`
- `/explore-projex.md Should we adopt microservices?`

---

## EXPLORATION TYPES

### Domain Exploration
Comprehensive investigation of a subject area, system, or domain.

### Architectural Exploration
Deep dive into system structure, patterns, and design decisions.

### Decision Exploration
Research and analysis to inform a specific decision without proposing solutions.

### Question Exploration
Thorough investigation to answer a specific technical or strategic question.

### Historical Exploration
Tracing evolution, understanding why things are the way they are.

---

## WORKFLOW STEPS

### 1. FRAME THE EXPLORATION

Define scope and questions:

- What are we exploring?
- What question needs answering?
- What decision does this inform?
- How deep should we go?
- Who needs this understanding?

### 2. SCAFFOLD THE DOCUMENT

Scaffold the file **before investigating anything**:

```bash
{projex-scripts}/new-projex.{sh|ps1} <repo-root> explore "{exploration-name}" <projex-folder>
```

Fill in what you know so far — the header, guiding questions, scope, context — then identify **investigation targets**: the specific areas, components, files, or concepts you intend to dive into. Each target becomes a section under Investigation with a brief rationale for why it matters. The rest of the document (findings, patterns, answers) stays empty — it gets filled during the dives.

This scaffold is the working artifact. Everything learned goes into it, not into your context alone.

**Template Structure:**

```markdown
# [Exploration Title]

> **Created:** YYYY-MM-DD | **Author:** [name or agent]
> **Type:** Domain | Architectural | Decision | Question | Historical
> **Related Projex:** [links]

---

## Summary

[Left blank — written after all targets are investigated]

**Guiding Questions:**
1. [Primary question]
2. [Secondary question]

**Scope:** [What's in/out of scope]

---

## Context

**Why Now:** [Motivation for this exploration]

**Current State:** [What we know, what we need to understand]

**Stakeholders:** [Who needs this]

---

## Investigation Targets

> Targets are identified upfront and revised during exploration.
> After each dive, reassess: add targets surfaced by new findings, reprioritize, or drop targets that proved irrelevant.

### Target: [Component/Concept/File/Area Name]
**Rationale:** [Why this target matters to the guiding questions]
**Status:** Pending | In Progress | Done | Dropped
**Findings:**
[Filled during dive — what it is, how it works, why it exists, key observations]

---

### Target: [Next target]
**Rationale:** ...
**Status:** Pending
**Findings:**
...

---

## Patterns & History

**Patterns Found:**
- **[Pattern]:** [Where/why it appears, implications]

**Evolution:** [How this came to be, key decisions, lessons learned]

---

## Findings

### Discoveries
1. **[Finding]:** [Explanation and significance]
2. **[Finding]:** [Explanation and significance]

### Mental Model
[How everything fits together - core principles and relationships]

### Implications
[What this means for decisions or future work]

---

## Answers

**[Question 1]**
[Direct answer with supporting evidence]

**[Question 2]**
[Direct answer with supporting evidence]

---

## Open Questions

- [ ] [Unresolved question]
- [ ] [Further investigation needed]

---

## Appendix

**Sources:** [Documents, code, systems examined]
**Limitations:** [Gaps in investigation or understanding]
```

### 3. DIVE INTO TARGETS

Work through investigation targets one at a time. For each target:

1. **Set status** to `In Progress` in the document
2. **Investigate deeply** — read code, trace flows, examine artifacts, follow references
3. **Write findings directly into the target's section** — not in your head, in the document. Include what you found, key observations, dependencies, surprises.
4. **Set status** to `Done`
5. **Reassess the target list:**
   - Did this dive reveal new areas worth investigating? → Add new targets
   - Did findings change what matters? → Reprioritize remaining targets
   - Did a pending target turn out irrelevant? → Mark `Dropped` with brief reason
6. **Repeat** for the next target

The document grows incrementally. If the user interrupts or the session ends, the exploration is partially complete but still useful — every finished target's findings are already captured.

**Do NOT synthesize or write final sections yet.** Complete all targets first.

### 4. REVISIT

**Mandatory second pass.** Only after every target from step 3 is `Done` or `Dropped`, revisit the exploration as a whole:

1. **Re-read the full document** from top to bottom — you now have context you lacked at the start
2. **Identify gaps** — are there areas that were shallow, connections that weren't traced, or questions the dives raised but didn't answer?
3. **Add new targets** for anything that warrants deeper investigation, mark them `Pending`
4. **Deepen existing targets** — if a completed target's findings feel thin now that you have the bigger picture, reopen it (`In Progress`) and expand
5. **Dive into all new/reopened targets** following the same procedure as step 3
6. Once all revisit targets are `Done`, proceed to synthesis

This pass exists because early dives happen with incomplete understanding. The agent sees the full picture only after finishing all initial targets — that is the right time to judge what's missing.

### 5. SYNTHESIZE

Once all targets (including revisit targets) are done:

1. Fill in **Patterns & History** — cross-cutting themes across targets
2. Fill in **Findings** — distill discoveries, build mental model, note implications
3. Fill in **Answers** — address each guiding question with evidence from the dives
4. Write the **Summary** — now that you have the full picture
5. Capture remaining unknowns in **Open Questions**

### 6. VALIDATE & FINALIZE

**Check:**
- [ ] All non-dropped targets have findings written
- [ ] Core questions answered with evidence
- [ ] Major components and relationships mapped
- [ ] Facts verified, assumptions marked
- [ ] Mental model is coherent

**Finalize:**
1. Front-load summary and key discoveries
2. Adjust detail to match scope
3. Link to related projex
4. Place in appropriate folder:
   - Active/referenced → `.projex/`
   - Completed/reference → `.projex/closed/`
   - Outdated → `.projex/archived/`

---

## EXPLORATION PRINCIPLES

- **Curiosity-driven** — Follow interesting threads, ask "why" repeatedly
- **Grounded** — Verify against actual systems, test assumptions
- **Focused breadth** — Cover territory thoroughly within scope boundaries
- **Synthesis-oriented** — Connect pieces into coherent mental models
- **Neutral** — Understand before judging, describe without prescribing

---

## EXPLORATION VS EVALUATION VS PROPOSAL

See SKILL.md § Document Types for the full type comparison. In brief:

- **Exploration** — Anchored to status quo. "What is?" Neutral investigation producing a knowledge map.
- **Evaluation** — Anchored to any question/idea. Open-ended analysis producing findings and recommendations.
- **Proposal** — Anchored to a specific direction. "What if we go this way?" with approaches and trade-offs.

**Use Exploration when:**
- You need to understand how something works
- You're mapping existing territory to inform a decision
- Knowledge gaps prevent progress
- You need open-ended research without a predetermined direction

**Use Proposal when:**
- You have a specific change or idea in mind
- You want to explore approaches, trade-offs, and impact for that direction
- You're building toward a decision to accept or reject

---

## OUTPUT

Produces exploration document at `.projex/{yymmddhhmm}-{name}-explore.md` with:
- Comprehensive understanding of subject
- Answers to guiding questions
- Foundation for informed decisions
- Links to related projex

**Committing:** Present the exploration document to the user. Do not commit automatically — commit only when the user explicitly requests it.

---

## NOTES

- Explorations build understanding, not prescriptions
- Depth matches importance and complexity
- Use relative paths for repo files
- Can spawn Evaluations or Plans once understanding is built