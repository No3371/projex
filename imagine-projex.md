---
description: This workflow guides the creation of **Imagination** projex documents — generative expansion of seeds (ideas, essences, principles) into rich, detailed visions. (This is part of @projex-framework skill. It is a MUST to load the skill first.)
---

## PURPOSE

Imaginations take a seed — an idea, an essence, a principle, a vision fragment — and grow it into a full-bodied, textured vision. They expand possibility space first, then deepen the most promising directions into detailed, grounded descriptions.

**Key characteristics:**
- Generative over analytical — grows ideas rather than scrutinizing them
- Divergent first, convergent second — explore widely, then deepen
- Grounded imagination — creative but not detached from reality
- Texture over abstraction — fills in detail, feel, and friction
- Challenges are creative, not critical — surfaces tension to make the vision *more real*, not to judge viability

**Contrast with Evaluation, Proposal, and Exploration:**
- **Imagination** — generative: "what could this become?" — starts from a seed, expands into rich vision
- **Evaluation** — analytical: any question, idea, or solution; no fixed framing or direction
- **Proposal** — directional: explores a specific change with trade-offs and approaches
- **Exploration** — grounded: investigates what exists, how it works, and why

---

## INVOCATION

```
/imagine-projex.md <seed idea, essence, or principle>
```

**Examples:**
- `/imagine-projex.md What would a plugin system for this framework look like?`
- `/imagine-projex.md A language where errors are first-class values`
- `/imagine-projex.md Evolve our CLI into a conversational interface`
- `/imagine-projex.md @20260731-capability-model-proposal.md — take this further`

---

## IMAGINATION TYPES

### Concept
Grow a raw idea into a full-bodied concept. Starts from a spark — a phrase, an intuition, a "what if" — and fills in structure, behavior, identity, and texture until the concept feels real.

### Design
Given constraints and principles, imagine the design of something new. Not implementation planning (that's Plan) — this is the creative act of envisioning what something *is* before deciding how to build it.

### Domain
Explore and populate a not-yet-existing domain space. What lives here? What are the entities, relationships, rules, and dynamics? Build the world before building in it.

### Extension
Imagine the evolution or transformation of something existing. Where could this go? What does it become when pushed further, combined with something else, or freed from current constraints?

---

## WORKFLOW STEPS

### 1. RECEIVE THE SEED

Identify what the user is starting from:

```
What form does the seed take?
- A raw idea or "what if"
- A principle or value to embody
- An essence or quality to manifest
- A vision fragment or partial picture
- An existing thing to evolve
```

Capture the seed exactly as given. Don't reframe or refine it yet — hold the original impulse.

### 2. DISTILL THE ESSENCE

Before expanding, understand the core DNA:

- What makes this unique? What's the distinctive quality?
- What principle does it embody?
- What would be lost if we simplified it wrong?
- What's the irreducible core?

Write this down. The essence is the anchor — all expansion must stay connected to it. When directions diverge too far, return here.

### 3. MAP THE POSSIBILITY SPACE

Divergent thinking. Expand outward:

- **Dimensions** — What axes does this idea live along? What can vary?
- **Adjacent possibilities** — What's nearby? What does this naturally connect to?
- **Directions** — Where could this go? Multiple paths, not one.
- **Tensions** — What pulls in different directions? Where are the interesting trade-offs?
- **Analogies** — What is this *like*? What existing things share its DNA?

Cast wide. Don't evaluate yet. Quantity and range matter here — the interesting ideas often hide at the edges.

### 4. DEEPEN PROMISING DIRECTIONS

Shift from breadth to depth. For each direction worth exploring:

- **Fill in texture** — What does this actually look like in practice? Details, examples, scenarios.
- **Follow implications** — If this were true, what else would follow? Second-order effects.
- **Find the edges** — Where does this direction start to break down or get weird? That's often where the interesting design decisions live.
- **Name things** — Giving names to concepts, patterns, and roles makes the vision concrete and communicable.

Don't try to deepen everything. Prune directions that lost energy during mapping. Go deep on 2-4 threads that feel alive.

### 5. SURFACE CHALLENGES & TENSIONS

Not a critique — a way to make the vision *more real*:

- **Friction points** — Where does this resist smooth implementation or adoption? What's hard?
- **Internal tensions** — Where do the vision's own goals pull against each other?
- **Boundary questions** — Where does this end and something else begin? What's in, what's out?
- **Unknowns** — What can't be resolved by imagination alone and needs real-world input?

Frame challenges constructively: "This creates an interesting tension between X and Y" rather than "This won't work because."

### 6. DRAFT THE IMAGINATION DOCUMENT

Create file: `{yyyymmdd}-{imagination-name}-imagine.md`

**Template Structure:**

```markdown
# [Imagination Title]

> **Created:** YYYY-MM-DD
> **Author:** [name or agent]
> **Seed:** [the original seed, verbatim or lightly paraphrased]
> **Type:** Concept | Design | Domain | Extension
> **Related Projex:** [links to related projex documents]

---

## Essence

[The irreducible core — what makes this unique, what principle it embodies, what must survive any expansion]

---

## Vision

[The synthesized, coherent description of what this could become. This is the heart of the document — rich, textured, grounded. Not a list of features but a vivid picture.]

---

## Possibility Space

### Dimensions
[The axes this idea lives along — what can vary, what's fixed]

### Directions Explored
#### [Direction 1 Name]
[Detailed exploration — what this looks like, how it works, what follows from it]

#### [Direction 2 Name]
[Same structure]

### Directions Noted but Not Explored
- [Direction]: [Brief description and why it was deferred]

---

## Texture & Detail

### [Aspect 1]
[Concrete detail, examples, scenarios that make the vision tangible]

### [Aspect 2]
[Same structure]

---

## Challenges & Tensions

### [Challenge/Tension 1]
[Description — what resists, what pulls in different directions, what's hard]

### [Challenge/Tension 2]
[Same structure]

### Open Unknowns
- [What needs real-world input to resolve]

---

## Connections

### Feeds Into
- [What this imagination could spawn — proposals, plans, further imaginations]

### Draws From
- [What informed this — existing systems, prior work, related projex]

---

## Seeds for Further Imagination

- [Ideas that surfaced during this process but deserve their own exploration]
```

### 7. VALIDATE & FINALIZE

**Coherence check:**
- [ ] Vision holds together — no internal contradictions left unacknowledged
- [ ] Essence is preserved — expansion didn't lose the original DNA
- [ ] Texture is sufficient — vision is concrete enough to act on or react to
- [ ] Challenges are honest — friction and unknowns are surfaced, not hidden

**Finalize:**
1. Front-load the Essence and Vision sections — readers should grasp the core immediately
2. Calibrate depth to match the seed's maturity and the user's intent
3. Link to related projex
4. Place in appropriate folder

**Folder placement:**
- Active imaginations → `projex/`
- Completed / spawned downstream work → `projex/closed/`
- Superseded or outgrown → `projex/archived/`

---

## IMAGINATION PRINCIPLES

### Generative Over Analytical
The goal is to grow, not to judge. Evaluation comes later. Here, follow the energy of the idea.

### Divergent First, Convergent Second
Resist the urge to narrow too early. Map the space before choosing directions. The best ideas often emerge from unexpected combinations.

### Grounded Imagination
Creative but not detached. Imagined visions should feel like they *could* exist — with real constraints, real trade-offs, real texture. Fantasy is fun; grounded imagination is useful.

### Texture Over Abstraction
A list of properties is not a vision. Fill in what it feels like, how it behaves in edge cases, what surprises it holds. Concrete details make ideas communicable and criticizable.

### Honest About Unknowns
Some questions can't be answered by imagination alone. Flag them clearly rather than papering over them with plausible-sounding guesses.

---

## IMAGINATION VS EVALUATION VS PROPOSAL VS EXPLORATION

| Aspect | Imagination | Evaluation | Proposal | Exploration |
|--------|-------------|------------|----------|-------------|
| **Anchored to** | A seed | Any question/idea | A specific direction | Status quo |
| **Stance** | "What could this become?" | Open-ended analysis | "What if we go this way?" | "What is?" |
| **Focus** | Generative expansion | Analytical assessment | Approaches and trade-offs | What exists and why |
| **Output** | Rich vision with texture | Findings and recommendations | Options and impact analysis | Knowledge map and insights |
| **When** | Have a seed to grow | Need to think deeply about something | Have a direction to explore | Need to understand current reality |

**Use Imagination when:**
- You have a raw idea, principle, or vision fragment to expand
- You want to explore what something *could become* before deciding what it *should become*
- You need rich, textured vision to inspire or inform downstream work
- Analytical tools would kill the creative energy prematurely

**Use Evaluation when:**
- You want to deeply analyze an existing question, idea, or solution
- You're comparing alternatives or assessing viability

**Use Proposal when:**
- You have a specific change in mind and want to explore approaches and impact

**Use Exploration when:**
- You need to understand how something works today

---

## OUTPUT

This workflow produces:
- An imagination projex document at `projex/{yyyymmdd}-{name}-imagine.md`
- Updated relationships in related projex documents
- Seeds for further imagination, proposals, or plans

**Folder placement by lifecycle:**
| Stage | Location |
|-------|----------|
| Active / Being developed | `projex/` |
| Completed / Spawned downstream work | `projex/closed/` |
| Superseded / Outgrown | `projex/archived/` |

---

## NOTES

- Imaginations are not themselves actionable — they feed into Proposals and Plans
- The vision should be rich enough to *react to* — stakeholders should be able to say "yes, that" or "no, not that"
- Resist the urge to evaluate during imagination — that comes later
- Multiple imaginations can explore the same seed in different directions
- Use relative paths when referencing repository files
