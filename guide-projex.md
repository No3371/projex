---
description: This workflow guides the creation of **Guide** projex documents — curated, ordered reading paths that enable a person to efficiently get up to speed on a topic, codebase area, document, or concept. (This is part of @projex-framework skill. It is a MUST to load the skill first.)
---

## PURPOSE

Guides produce **human-facing study material** — an indexed, phased reading path with focus cues and takeaways. The agent does the exploration work; the output is structured so a human reader can efficiently build understanding.

**Key characteristics:**
- Audience is a human reader, not a project or agent
- Output is an ordered reading path, not raw findings
- Each step tells the reader *what* to read, *what to focus on*, and *what to take away*
- Sources can span codebase, docs, articles, specs, and external pages

**Contrast with Exploration:**
- **Exploration** — agent-facing: investigates status quo, produces knowledge maps and findings
- **Guide** — human-facing: curates investigated material into a progressive learning path

---

## INVOCATION

```
/guide-projex.md <learning objective or subject>
```

**Examples:**
- `/guide-projex.md Understand our authentication system end-to-end`
- `/guide-projex.md Get up to speed on the projex framework`
- `/guide-projex.md Navigate the WebSocket spec (RFC 6455)`
- `/guide-projex.md Onboard a new contributor to the compiler pipeline`

---

## GUIDE TYPES

### Codebase
Navigate source code to understand a system, module, or feature area.

### Document
Navigate specs, docs, articles, or external pages to absorb written material.

### Concept
Build understanding of an abstract topic through varied sources.

### Onboarding
Get someone up to speed on a project or area — combines codebase, docs, and context.

---

## WORKFLOW STEPS

### 1. FRAME THE GUIDE

Define the learning objective, audience, and source strategy:

- **What should the reader understand after completing this guide?** — Write a concrete learning objective.
- **Who is the target audience?** — What can they be assumed to know already? What's new to them?
- **What material exists?** — Code files, internal docs, external URLs, specs, articles.
- **External sources:** Ask the user whether external URLs should be fetched and analyzed by the agent, or just listed as references.
- **Estimated time:** Rough reading time to set expectations.

### 2. INVESTIGATE THE MATERIAL

The agent explores the ground truths — this is where the real work happens:

- Read and understand the relevant code, docs, specs, and articles
- If the user opted in, fetch and analyze external URLs
- Identify the core concepts the reader must grasp
- Map dependencies between concepts (what must be understood before what)
- Note common pitfalls and easy-to-miss details
- Identify what's essential vs. supplementary

> **Do NOT invent conceptual abstractions.** Every step must point to a concrete, readable source. If a concept has no citable source, flag it as a gap in Open Questions — don't write an explanation in its place.

### 3. DESIGN THE READING PATH

Order material into progressive phases:

- **Phase sequencing:** Earlier phases build foundations; later phases build on them
- **Step granularity:** Each step is one focused reading unit (a file, a section, an article)
- **Focus cues:** For each step, identify what the reader should pay attention to
- **Takeaways:** For each step, state what the reader should come away understanding
- **Pruning:** Omit material that doesn't serve the learning objective — less is more

> **Do NOT include steps the reader won't act on.** If a step exists only for completeness, cut it. Every step must earn its place by advancing the learning objective.

### 4. DRAFT THE GUIDE

Create file: `{yyyymmdd}-{guide-name}-guide.md`

Use the template structure below, adapting sections based on guide type and depth needed.

**Template Structure:**

```markdown
# [Guide Title]

> **Created:** YYYY-MM-DD | **Author:** [name or agent]
> **Type:** Codebase | Document | Concept | Onboarding
> **Target Audience:** [who this is for, what they're assumed to know]
> **Estimated Time:** [rough reading time]
> **Prerequisites:** [what the reader should know/have before starting]
> **Related Projex:** [links]

---

## Objective

[What the reader will understand after completing this guide — concrete and specific]

---

## Quick Introduction

[2–4 sentences giving the reader immediate orientation: what this thing is, why it exists, and one grounding detail. A reader who stops here should still walk away with a usable mental anchor.]

---

## Reading Path

### Phase 1: [Foundation / Overview / ...]

**Goal:** [What the reader gains from this phase]

#### Step 1.1: [Descriptive title]

- **Read:** [source — file path, doc section, URL, etc.]
- **Focus on:** [what to pay attention to — specific functions, paragraphs, patterns]
- **Key takeaway:** [the one thing to walk away understanding]

#### Step 1.2: [Descriptive title]

- **Read:** [source]
- **Focus on:** [guidance]
- **Key takeaway:** [insight]

---

### Phase 2: [Core Mechanics / Deep Dive / ...]

**Goal:** [What the reader gains from this phase]

#### Step 2.1: [Descriptive title]

- **Read:** [source]
- **Focus on:** [guidance]
- **Key takeaway:** [insight]

[...continue as needed...]

---

## Key Concepts Index

| Concept | Where | Why It Matters |
|---------|-------|----------------|
| [concept] | [source/location] | [significance] |
| [concept] | [source/location] | [significance] |

---

## Common Pitfalls

- **[Pitfall]:** [What's easy to misunderstand and the correct understanding]
- **[Pitfall]:** [What's easy to misunderstand and the correct understanding]

---

## Open Questions

- [Things the author couldn't resolve — missing docs, unclear behavior, unverified assumptions, source gaps]

---

## Further Reading

- [Optional deeper material, tangential topics, advanced references]
```

### 5. SECOND PASS (MANDATORY)

Re-read the full guide as a reader — not as the agent that wrote it. This is a separate pass, not a continuation of drafting.

**Check each step:**
- Does this step point to a real, readable source — or did I fabricate an abstraction?
- Would the reader actually do this step, or is it filler?
- Does the Focus on give specific enough guidance, or is it vague?
- Does the Key takeaway state something concrete the reader didn't know before?

**Check the whole path:**
- [ ] Quick Introduction gives usable orientation without requiring the reading path
- [ ] Learning objective is concrete and the reading path delivers on it
- [ ] Phases build progressively — no forward references to unread material
- [ ] Every step has Read, Focus on, and Key takeaway
- [ ] Key Concepts Index covers the essential terms and ideas
- [ ] Common Pitfalls addresses genuine misunderstanding risks
- [ ] Open Questions captures anything unresolved — no gaps silently ignored
- [ ] Sources are accurate (file paths exist, URLs are reachable)
- [ ] Appropriate for the stated target audience

**Cut ruthlessly:** If a step survived drafting but fails the second pass, remove it. A shorter guide that earns every step beats a thorough one padded with filler.

### 6. FINALIZE AND COMMIT

1. Front-load the objective and key concepts
2. Link to related projex
3. Place in `.projex/closed/` — guides are point-in-time artifacts

---

## GUIDE PRINCIPLES

- **Reader-first** — Every structural decision serves the human reader's comprehension
- **Progressive** — Build understanding in layers; never assume knowledge not yet covered
- **Curated** — Include only what matters; density over exhaustiveness
- **Actionable** — Each step tells the reader exactly what to do and what to look for
- **Honest** — Flag what's confusing, warn about pitfalls, acknowledge gaps

---

## OUTPUT

Produces guide document at `.projex/closed/{yyyymmdd}-{name}-guide.md` with:
- Concrete learning objective
- Phased reading path with focus cues and takeaways
- Key concepts index for quick reference
- Common pitfalls to avoid misunderstanding
- Links to related projex

---

## NOTES

- Guides are **closed by default** — they capture a point-in-time reading path. If material changes significantly, author a new guide rather than revising the old one.
- During framing, always ask the user about external URL handling (fetch vs. reference-only).
- Use relative paths for repo files.
- A guide can be spawned from an Exploration — the exploration provides the investigation, the guide reshapes it for a human reader.
