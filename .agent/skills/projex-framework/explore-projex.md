---
description: This workflow guides the creation of **Exploration** projex documents — comprehensive investigation of status quo, subject domains, or specific questions to build deep understanding and inform decisions. (This is part of @projex-framework skill. Is is a MUST to load the skill first.)
---

## PURPOSE

Explorations provide thorough, grounded investigation into what exists, how it works, and why it matters. They build comprehensive understanding through systematic inquiry.

**Key characteristics:**
- Deep dive into existing systems, domains, or phenomena
- Comprehensive mapping of current reality
- Discovery-oriented investigation
- Foundation for informed decision-making

**Contrast with Evaluation:**
- **Exploration** investigates what is (status quo, domains, questions)
- **Evaluation** compares what is versus what could be (proposals, changes)

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

### 2. INVESTIGATE

**Map the Territory:**
- What exists? (components, concepts, entities)
- How do they interact? (relationships, dependencies)
- What patterns emerge? (conventions, abstractions)

**Trace the History:**
- How did this come to be?
- What key decisions shaped it?
- What was learned along the way?

**Understand the Why:**
- Why does this exist? (purpose, problems solved)
- Why designed this way? (rationale, trade-offs)
- What factors influenced this? (context, constraints)

### 3. DRAFT THE EXPLORATION

Create file: `{yyyymmdd}-{exploration-name}-explore.md`

Use the template structure below, adapting sections based on exploration type and depth needed.

**Template Structure:**

```markdown
# [Exploration Title]

> **Created:** YYYY-MM-DD | **Author:** [name or agent]
> **Type:** Domain | Architectural | Decision | Question | Historical
> **Related Projex:** [links]

---

## Summary

[what was explored, key discoveries, main insights]

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

## Investigation

### [Area 1: Component/Concept Name]

[Description: what it is, how it works, why it exists]

**Key Points:**
- [Important characteristic or finding]
- [Dependencies or relationships]

---

### [Area 2]

[Same structure]

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

### 4. VALIDATE & FINALIZE

**Check:**
- [ ] Core questions answered with evidence
- [ ] Major components and relationships mapped
- [ ] Facts verified, assumptions marked
- [ ] Mental model is coherent
- [ ] Useful for stakeholders

**Finalize:**
1. Front-load summary and key discoveries
2. Adjust detail to match scope
3. Link to related projex
4. Place in appropriate folder:
   - Active/referenced → `projex/`
   - Completed/reference → `projex/closed/`
   - Outdated → `projex/archived/`

---

## EXPLORATION PRINCIPLES

- **Curiosity-driven** — Follow interesting threads, ask "why" repeatedly
- **Grounded** — Verify against actual systems, test assumptions
- **Focused breadth** — Cover territory thoroughly within scope boundaries
- **Synthesis-oriented** — Connect pieces into coherent mental models
- **Neutral** — Understand before judging, describe without prescribing

---

## EXPLORATION VS EVALUATION

| Aspect | Exploration | Evaluation |
|--------|-------------|------------|
| **Focus** | What is | What is vs what could be |
| **Purpose** | Build understanding | Assess viability/merit |
| **Stance** | Neutral investigation | Critical analysis |
| **Output** | Knowledge and insights | Judgment and recommendation |
| **When** | Need to understand | Need to decide/compare |

**Use Exploration when:**
- You need to understand how something works
- You're researching to inform a decision
- You want to map existing territory
- Knowledge gaps prevent progress

**Use Evaluation when:**
- You have a specific proposal to assess
- You're comparing alternatives
- You need to judge compatibility
- You're analyzing gaps against goals

---

## OUTPUT

Produces exploration document at `projex/{yyyymmdd}-{name}-explore.md` with:
- Comprehensive understanding of subject
- Answers to guiding questions
- Foundation for informed decisions
- Links to related projex

---

## NOTES

- Explorations build understanding, not prescriptions
- Depth matches importance and complexity
- Use relative paths for repo files
- Can spawn Evaluations or Plans once understanding is built