---
description: This workflow guides the creation and maintenance of **Definition** projex documents — living declarative specifications that exhaustively describe WHAT an entity is. (This is part of @projex-framework skill. It is a MUST to load the skill first.)
---

## PURPOSE

Definition documents answer "what is this thing, exactly?" They are declarative specifications of an entity — a product, component, feature, class, protocol, API surface, domain concept, or any other noun worth pinning down. The goal is to eliminate vagueness: every property, boundary, relationship, constraint, and open question is surfaced and made explicit.

**Key characteristics:**
- **Declarative, not procedural** — describes WHAT the entity is, not HOW to build or change it. Implementation plans, execution steps, and roadmaps belong in other projex types
- **Exhaustive by intent** — the document strives to leave nothing ambiguous or assumed. Unknown areas are tracked explicitly until resolved
- Living document — revisited and deepened over time as understanding grows; never "closed"
- **Collaborative** — each invocation is a conversation: the agent explores the domain, surfaces questions, and works with the user to sharpen the definition
- Scope-flexible — can define anything from a single class to an entire product

**Contrast with other types:**
- **Definition** — WHAT something is: identity, properties, boundaries, constraints, relationships
- **Exploration** — HOW something currently works: investigation of existing code/systems, then closed
- **Evaluation** — WHETHER something is good: open-ended analysis and judgment
- **Proposal** — WHAT IF we go this way: directional with trade-offs
- **Map** — WHERE things live: structural index of directories, not conceptual specification

---

## INVOCATION

```
/define-projex.md <entity description>
/define-projex.md @{existing-definition-document}
/define-projex.md @{existing-definition-document} <area to expand>
```

**First invocation** (create new definition):
- `/define-projex.md The authentication subsystem`
- `/define-projex.md Token class and its variants`
- `/define-projex.md Our pricing model`

**Subsequent invocations** (revisit and deepen):
- `/define-projex.md @20260215-auth-subsystem-def.md`
- `/define-projex.md @20260215-auth-subsystem-def.md session lifecycle edge cases`

---

## WORKFLOW STEPS

### CREATING A NEW DEFINITION

#### 1. EXPLORE THE DOMAIN

Before drafting, understand the entity from available sources:

1. **Gather existing knowledge** — read code, docs, specs, related projex, READMEs, comments, tests — anything that already describes or implies what this entity is
2. **Identify the entity's nature** — is it a runtime component, a data structure, a user-facing feature, an abstract concept, a protocol, a service boundary?
3. **Note what's clear vs. what's vague** — separate what you can state with confidence from what needs user input

> **Do not assume.** If information isn't available, mark it as an open question — don't fill gaps with plausible-sounding guesses.

#### 2. DISCUSS WITH USER

This is the core of the workflow. Surface what you've found and probe for clarity:

- **Identity:** "In one sentence, what is [entity] responsible for?"
- **Boundaries:** "What is explicitly NOT part of [entity]? What's adjacent but separate?"
- **Properties:** "What attributes/fields/capabilities does it have? Are any optional?"
- **Constraints:** "What must always be true about [entity]? What invariants does it maintain?"
- **Relationships:** "What does it depend on? What depends on it?"
- **States:** "What states can it be in? What transitions are valid?"
- **Edge cases:** "What happens when [unusual condition]?"

Adapt questions to the entity's nature. A class definition needs different questions than a product definition.

Don't rush to document — keep discussing until you and the user feel the major facets are surfaced. It's fine to draft incrementally: capture what's clear, mark what isn't, revisit.

#### 3. DRAFT THE DEFINITION

Create file in the appropriate `.projex/` folder: `{yyyymmdd}-{entity-name}-def.md`

**Template Structure:**

```markdown
# Definition: [Entity Name]

> **Created:** YYYY-MM-DD | **Last Revised:** YYYY-MM-DD
> **Author:** [name or agent]
> **Scope:** [what this definition covers]
> **Status:** Draft | Stabilizing | Stable

---

## Identity

[What this entity IS — its core purpose and reason for existing. 2-5 sentences that someone unfamiliar could read and understand what they're looking at.]

---

## Boundaries

**Is:**
- [What the entity includes / is responsible for]

**Is not:**
- [What is explicitly excluded — adjacent concerns, common misconceptions, out-of-scope areas]

---

## Properties

| Property | Type / Shape | Required | Description |
|----------|-------------|----------|-------------|
| [name] | [type, format, or shape] | Yes/No | [What it represents and any constraints] |

[For entities where a table doesn't fit (features, products, abstract concepts), use a descriptive list instead:]

### [Property or Facet Name]
[Description — what it is, what values/states it can take, why it matters.]

---

## Relationships

| Related Entity | Relationship | Description |
|---------------|-------------|-------------|
| [Entity] | depends on / depended on by / contains / part of / uses / used by | [Nature of the relationship] |

[Narrative explanation of key relationships if the table alone doesn't capture the dynamics.]

---

## Constraints & Invariants

- [Something that must ALWAYS be true — e.g., "A session always has exactly one owner"]
- [Something that must NEVER happen — e.g., "Token must never be persisted to disk unencrypted"]
- [Ordering, uniqueness, cardinality, or consistency rules]

---

## States & Lifecycle

> Omit this section if the entity is stateless or the concept doesn't apply.

| State | Description | Transitions To |
|-------|-------------|---------------|
| [State] | [What it means to be in this state] | [Valid next states] |

[Narrative about the lifecycle if it's non-trivial — entry conditions, exit conditions, error states.]

---

## Behaviors

> Omit this section if the entity is purely data / has no behaviors.

### [Behavior Name]
- **Trigger:** [What causes this behavior]
- **Effect:** [What happens]
- **Constraints:** [Rules that apply during this behavior]

---

## Open Questions

- [ ] [Something unresolved — e.g., "Should expired tokens be soft-deleted or hard-deleted?"]
- [ ] [Something not yet explored — e.g., "Concurrency semantics under parallel writes"]
- [ ] [Something the user needs to decide — e.g., "Maximum session duration — 24h or configurable?"]

---

## Revision Log

| Date | Summary |
|------|---------|
| YYYY-MM-DD | Initial definition created |
```

**Drafting guidelines:**
- **Sections are opt-in** — use what fits the entity. A class needs Properties, States, Behaviors. A product feature might only need Identity, Boundaries, and Constraints. Omit sections that don't apply rather than forcing empty content
- **Be precise, not verbose** — "Accepts UTF-8 strings up to 255 bytes" beats "Accepts strings of reasonable length"
- **State confidence levels** — if a property is inferred rather than confirmed, mark it: *(inferred from usage in X — confirm with user)*
- **Open Questions are first-class content** — a definition with 10 answered properties and 5 explicit open questions is more valuable than one with 15 properties where 5 are quietly guessed

#### 4. VALIDATE AND COMMIT

**Check:**
- [ ] Identity section is clear enough for someone unfamiliar to understand the entity
- [ ] Boundaries are explicit — "is not" is populated, not just "is"
- [ ] No properties are fabricated — everything stated is grounded in evidence or confirmed by user
- [ ] Open Questions captures everything still unresolved (not silently omitted)
- [ ] Status field reflects actual state (Draft if open questions remain)

```bash
{projex-scripts}/projex-commit.{sh|ps1} <repo-root> "projex(def): create definition - {entity-name}" .projex/{yyyymmdd}-{entity-name}-def.md
```

---

### REVISITING AN EXISTING DEFINITION

This is the expected primary mode — definitions deepen over time.

#### 1. ASSESS CURRENT STATE

1. **Read the existing definition** — understand what's already captured
2. **Check Open Questions** — are any now answerable from new code, docs, or context?
3. **Check for drift** — has the entity evolved since last revision? New properties, changed constraints, shifted boundaries?
4. **Identify the focus** — if the user specified an area to expand, focus there; otherwise survey broadly

#### 2. DISCUSS WITH USER

Revisit with targeted questions:

- "Last time we left [X] open — has that been decided?"
- "The codebase now shows [Y] — does this change the boundary we defined?"
- "I noticed [Z] isn't captured yet — should we add it?"

For user-directed expansions ("expand the lifecycle section"), dive deep into that area with domain-specific questions.

#### 3. UPDATE THE DEFINITION

Update the document in-place:

1. **Update "Last Revised" date**
2. **Resolve open questions** — move answered questions into the appropriate sections
3. **Add new content** — new properties, relationships, constraints discovered
4. **Revise stale content** — update anything that no longer accurately describes the entity
5. **Add new open questions** — deeper exploration always surfaces new unknowns
6. **Update Status** — Draft → Stabilizing (when open questions are narrowing) → Stable (when open questions are resolved or purely hypothetical)
7. **Append to revision log**

#### 4. COMMIT REVISION

```bash
{projex-scripts}/projex-commit.{sh|ps1} <repo-root> "projex(def): revise definition - {entity-name}" .projex/{yyyymmdd}-{entity-name}-def.md
```

---

## DEFINITION PRINCIPLES

- **WHAT, not HOW** — the definition describes the entity's nature, not its implementation. "Sessions expire after the configured TTL" belongs here; "We use a Redis TTL to expire sessions" belongs in a plan or exploration
- **Exhaust the vagueness** — the ultimate goal is zero unacknowledged unknowns. Every open question is tracked. Every "it depends" is followed up with "on what, exactly?"
- **Honest about gaps** — a definition with explicit open questions is trustworthy. One that looks complete but hides assumptions is dangerous. Mark uncertainty visibly
- **Living, not archived** — definitions stay in `.projex/` for their active lifetime. They move to `.projex/archived/` only when the entity itself is deprecated or superseded
- **Precision over completeness** — ten precise statements beat twenty vague ones. If you can't be specific yet, write an open question instead
- **Scope-appropriate** — a class definition captures fields, methods, invariants. A product definition captures value prop, user segments, capabilities. Use the sections that fit; omit the rest

---

## FOLDER PLACEMENT

| State | Location |
|-------|----------|
| Active (default) | `.projex/` matching the entity's scope |
| Superseded | `.projex/archived/` within the same scope |

Definition documents are **never** placed in `.projex/closed/` — they are living documents that persist until the entity they describe is deprecated or replaced.

---

## NOTES

- Definitions pair naturally with Plans — define WHAT first, then plan HOW
- A Definition can be spawned from an Exploration ("we investigated X, now let's pin down exactly what it is")
- Definitions are excellent context for new sessions — hand an agent a definition and it knows what it's working with
- When a definition grows too large, split by facet into separate definitions with cross-references
- The Status field (Draft → Stabilizing → Stable) helps other workflows gauge how much they can rely on this definition
