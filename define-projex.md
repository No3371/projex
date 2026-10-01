---
description: This workflow guides the creation and maintenance of **Definition** projex documents — living declarative specifications that exhaustively describe WHAT an entity is. (This is part of @projex-framework skill. It is a MUST to load the skill first.)
---

## PURPOSE

Definition documents answer "what is this thing, exactly?" They are declarative specifications of an entity — a product, component, feature, class, protocol, API surface, domain concept, or any other noun worth pinning down. Reader of the document should be able to understand every established facts about the subject: every property, boundary, relationship, constraint. 

**Key characteristics:**
- **Declarative, not procedural** — describes WHAT the entity is, not HOW, WHY, WHEN, WHERE. Information only matters when it supports the WHATs.
- **Exhaustive by intent, incremental by practice** — the document strives to leave nothing ambiguous or assumed, but it reaches that state over many rounds. Exhaustive means *no unknown is hidden*, not *every section is filled on the first pass*. Unknown areas are tracked explicitly until resolved
- Living document — revisited and deepened over time as understanding grows; never "closed"
- **Collaborative** — each invocation is a conversation: the agent explores the domain, surfaces questions, and works with the user to sharpen the definition
- Scope-flexible — can define anything from a single class to an entire product

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
- `/define-projex.md Our consulting engagement model`

**Subsequent invocations** (revisit and deepen):
- `/define-projex.md @2602151430-auth-subsystem-def.md`
- `/define-projex.md @2602151430-auth-subsystem-def.md session lifecycle edge cases`

---

## WORKFLOW STEPS

### CREATING A NEW DEFINITION

#### 1. EXPLORE THE DOMAIN

Before drafting, understand the entity from available sources:

1. **Classify the subject** — this decides where answers come from:
   - **Discovery** — the entity already exists (code, product, running process, written material). Facts are recoverable from evidence. Read first, then ask the user only what no artifact can settle
   - **Origination** — the entity is an idea. Nothing exists to read; every fact is a user decision. Ask; never supply the fact yourself
   - Mixed subjects are normal — an existing component with a planned extension. Track which mode each area belongs to. An Origination area must never inherit the confidence of a Discovery area
2. **Gather existing information** — read code, docs, specs, related projex, READMEs, comments, tests — anything that already describes or implies what this entity is
3. **Identify the entity's nature** — is it a runtime component, a data structure, a user-facing feature, an abstract concept, a protocol, a service boundary?
4. **Build the gap ledger** — before asking anything, list the entity's facets against the four layers in step 2 and mark each one:
   - **Established** — stated by the user, or grounded in evidence you can cite
   - **Assumed** — inferred by you; needs confirmation before it can enter the document
   - **Unknown** — no evidence, no user input

   The ledger drives the conversation: questions come from the Unknown and Assumed entries, shallowest layer first. A minimal objective produces a mostly-Unknown ledger. That is the expected starting state, not a deficiency for you to fill in alone.

> **Do not assume.** If information isn't available, mark it as an open question — don't fill gaps with plausible-sounding guesses.

#### 2. DISCUSS WITH USER — LAYER BY LAYER

This is the core of the workflow. Resolve the definition in layers, from directional to detailed. **Do not enter a layer until the layer above it is settled or the user defers it explicitly.**

| Layer | Asks | Feeds sections |
|-------|------|----------------|
| **L1 — Direction** | "In one sentence, what is [entity] and what is it responsible for?" "Who or what uses it?" "What makes it worth defining?" | Identity, Scope |
| **L2 — Boundaries** | "What is explicitly NOT part of it?" "What is adjacent but separate?" "How big is the subject — one class, one subsystem, the whole product?" | Boundaries |
| **L3 — Structure** | "What parts / properties / capabilities does it have?" "What does it depend on, and what depends on it?" "What states can it be in?" | Properties, Relationships, States |
| **L4 — Detail** | "What must ALWAYS be true? What must NEVER happen?" "What happens when [unusual condition]?" "Exact types, limits, valid transitions?" | Constraints & Invariants, Behaviors, edge cases |

**Protocol:**

- **One layer per round** — 3-5 questions per round, maximum. Ask, wait for answers, re-mark the gap ledger, then decide the next round
- **Restate before you descend** — at the end of a layer, give the settled statements of that layer back to the user in a few lines and get explicit agreement. A wrong L1 makes every L4 answer worthless
- **The user sets the floor** — when the user says "enough", names the scope as final, or stops answering a layer, stop there. The unentered layers become Open Questions, not agent-authored content
- **Depth is earned, not assumed** — a one-line objective authorizes L1 questions only. It does not authorize an L4 document
- **Adapt to the entity's nature** — a class definition needs different questions than a product definition. The layers stay; the questions change

**By mode:**

- **Discovery** — read first, then convert findings into confirmations instead of open questions: "The code shows X. Is X intended, or incidental?" Reserve real questions for what no artifact can answer — intent, boundary decisions, invariants that are honored but never written down. Never present an inference as an established fact
- **Origination** — the user owns every fact. Options are allowed to speed a decision ("A or B?"), but an option the user did not pick is an Open Question, never a default. A property the user never mentioned is an invention: put it in Open Questions or drop it

#### 3. DRAFT THE DEFINITION

```bash
Resolve `{parent}` from an explicit causal subject/nav/source filename; else supplied orchestrator Parent; else `User`.
{projex-scripts}/new-projex.sh --repo-root <repo-root> --type define --title "{entity-name}" --parent {parent} --projex-dir <projex-folder>
```
```powershell
{projex-scripts}\new-projex.ps1 -RepoRoot <repo-root> -Type define -Title "{entity-name}" -Parent {parent} -ProjexDir <projex-folder>
```

**Template Structure:**

```markdown
# Definition: [Entity Name]

> **Created:** YYYY-MM-DD | **Last Revised:** YYYY-MM-DD
> **Author:** [Model(Role), or Model, or self identity, fallback: "Agent"]
> **Scope:** [what this definition covers]
> **Status:** Draft | In Progress | Complete (Stable)

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
- **Depth ceiling — the document stops where the conversation stopped** — write nothing below the deepest resolved layer. Name the unresolved layers in Open Questions instead. A definition produced after a single L1 round is an Identity paragraph plus a list of open questions. That is a correct output, not a thin one
- **Size follows the facts, not the template** — the template is a menu of what *could* be captured, never a form to complete. A minimal objective yields a minimal document
- **Sections are opt-in** — use what fits the entity. A class needs Properties, States, Behaviors. A product feature might only need Identity, Boundaries, and Constraints. Omit sections that don't apply rather than forcing empty content
- **Be precise, not verbose** — "Accepts UTF-8 strings up to 255 bytes" beats "Accepts strings of reasonable length"
- **State confidence levels** — if a property is inferred rather than confirmed, mark it: *(inferred from usage in X — confirm with user)*
- **Open Questions are first-class content** — a definition with 10 answered properties and 5 explicit open questions is more valuable than one with 15 properties where 5 are quietly guessed

#### 4. VALIDATE AND PRESENT

**Check** — the checks apply to the layers that were resolved; an unresolved layer is checked for being *declared open*, not for being filled:
- [ ] The document is clear enough for someone unfamiliar to understand the entity at the depth reached
- [ ] **Depth matches the conversation** — no section sits below the deepest resolved layer, and no layer stops short of what the user actually settled
- [ ] Boundaries: if L2 was resolved, "is not" is populated, not just "is". If L2 was not reached, the Boundaries section is absent and boundaries appear in Open Questions
- [ ] No properties are fabricated — everything stated is grounded in evidence or confirmed by user
- [ ] Open Questions captures everything still unresolved — the unentered layers included (not silently omitted)
- [ ] Status field reflects actual state (Draft if open questions remain)

Surface a summary of the entity's identity and open questions to the user. **Do not commit.** Wait — commit only when the user explicitly requests it.

When the user requests a commit:

```bash
{projex-scripts}/stage-n-commit.{sh|ps1} <repo-root> "projex(def): create definition - {entity-name}" .projex/{yymmddhhmm}-{entity-name}-def.md
```

---

### REVISITING AN EXISTING DEFINITION

#### 1. ASSESS CURRENT STATE

1. **Read the existing definition** — understand what's already captured
2. **Check Open Questions** — are any now answerable from new code, docs, or context?
3. **Check for drift** — has the entity evolved since last revision? New properties, changed constraints, shifted boundaries?
4. **Identify the focus** — if the user specified an area to expand, focus there; otherwise survey broadly

#### 2. DISCUSS WITH USER

Same layer protocol as a new definition: resume at the **shallowest unresolved layer**, one layer per round, 3-5 questions per round. A revision that answers L4 edge cases while L2 boundaries are still open is building on sand.

Revisit with targeted questions:

- "Last time we left [X] open — has that been decided?"
- "The codebase now shows [Y] — does this change the boundary we defined?"
- "I noticed [Z] isn't captured yet — should we add it?"

For user-directed expansions ("expand the lifecycle section"), the named area sets the focus; within it, still go direction → boundary → structure → detail.

#### 3. UPDATE THE DEFINITION

Update the document in-place:

1. **Update "Last Revised" date**
2. **Resolve open questions** — move answered questions into the appropriate sections
3. **Add new content** — new properties, relationships, constraints discovered
4. **Revise stale content** — update anything that no longer accurately describes the entity
5. **Add new open questions** — deeper exploration always surfaces new unknowns
6. **Update Status** — Draft → In Progress (open questions narrowing) → Complete (Stable) (open questions resolved or purely hypothetical). Never-closed type: stays in `.projex/` at `Complete (Stable)`; drops back to `In Progress` on revision
7. **Append to revision log**

#### 4. PRESENT REVISION

Surface the updated definition file path and a summary of what changed (resolved questions, new content, status change) to the user. **Do not commit.** Wait — commit only when the user explicitly requests it.

When the user requests a commit:

```bash
{projex-scripts}/stage-n-commit.{sh|ps1} <repo-root> "projex(def): revise definition - {entity-name}" .projex/{yymmddhhmm}-{entity-name}-def.md
```

---

## DEFINITION PRINCIPLES

- **WHAT, not HOW** — the definition describes the entity's nature, not its implementation, nor its history or origin. "Sessions expire after the configured TTL" belongs here; "We use a Redis TTL to expire sessions" belongs in a plan or exploration
- **Layered, not one-shot** — direction before boundaries, boundaries before structure, structure before detail. Each layer is a round of questions and an explicit agreement. The document may never be deeper than the layer the user has confirmed
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

- Definitions are excellent context for new sessions — hand an agent a definition and it knows what it's working with
- When a definition grows too large, split by facet into separate definitions with cross-references
- The Status field (Draft → In Progress → Complete (Stable)) helps other workflows gauge how much they can rely on this definition
