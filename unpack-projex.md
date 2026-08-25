---
description: This workflow guides the creation of **Unpack** projex documents. A dense subject restated in sequential passes, two at a time, each layer thinner than the last, continuing only while the user asks for another batch. (This is part of @projex-framework skill. It is a MUST to load the skill first.)
---

## PURPOSE

Unpack takes one dense subject and produces **progressively thinner restatements of that same subject**. Each pass lowers the audience floor. What the previous layer assumed the reader knew, the next layer explains.

**Key characteristics:**
- Unpack rewrites the subject instead of pointing at it. The reader never leaves the document
- Passes run **two at a time**. The user decides whether another two are needed
- Every layer is a full restatement, readable on its own, not a diff against the layer above
- Each layer is longer than the one before. Thinning costs words
- A fixed category inventory finds the opacity, rather than the agent noticing when something feels unclear
- Residue always remains. The document ends by naming what it left closed, never by declaring the subject clear

Guide points a reader at sources to read themselves. Explore investigates the status quo. Define specifies what an entity is. Unpack changes only the reader's access to a subject already stated.

**Dehydrate carve-out.** `SKILL.md § Dehydrate` does not apply to layer bodies, because thinning is the deliverable. It applies in full to the document's scaffolding: headers, sweep tables, fidelity blocks, checkpoint records, residue lists.

---

## INVOCATION

```
/unpack-projex.md <dense subject>
/unpack-projex.md @{filename}-unpack.md          # resume: run the next batch on an existing unpack
```

**Examples:**
- `/unpack-projex.md @2607311430-token-budget-model-def.md`
- `/unpack-projex.md The Worktree Mode section of SKILL.md`
- `/unpack-projex.md "Migration: blocked, schema validator not updated"`
- `/unpack-projex.md How the ephemeral branch survives an abandoned execution`
- `/unpack-projex.md @2608120915-cache-invalidation-unpack.md`

---

## OPACITY INVENTORY

Every sweep walks this inventory in full against the layer above. Each hit becomes an item the next layer must resolve.

| Category | What it is | Signal |
|---|---|---|
| **Term** | Word, identifier, or acronym used without definition | Reader could not restate it in their own words |
| **Referent** | Pointer whose target is implicit | "this", "the above", a bare filename, an unqualified pronoun |
| **Leap** | Reasoning step skipped between two statements | B follows A only if the reader supplies a missing premise |
| **Compression** | Shorthand notation standing in for prose | `→`, `key: value`, fragments, tables read as sentences |
| **Assumed context** | Background the author held and did not state | History, prior decision, adjacent system, convention |
| **Mechanism** | A "what" stated without its "how" | Reader knows the outcome, cannot picture the operation |
| **Consequence** | A "how" stated without its "so what" | Reader follows the operation, cannot say why it matters |

---

## BATCHES

Passes run in **batches of two**. Write the batch, drift-check it, present it, then let the user decide whether two more are needed. The ladder has no declared end. It stops where the user stops it.

**Batch loop:** declare the batch's two floors → pass A → pass B → drift pass across all layers → present → ask for two more.

- **Never run a third pass inside a batch.** Two passes, then the checkpoint.
- **Never open the next batch without the user's answer.** Silence is not consent to continue.
- **Never declare the subject finished.** Report what residue remains and what another batch would resolve. Stopping is the user's call.
- **A batch may end early.** The user may stop after the first pass. The drift pass and checkpoint still run.

---

## THE FLOORS

Each pass lowers the floor by one rung. A batch covers two rungs. Rungs past the reference scale are derived, so declare the floor and its reader before the pass that uses it.

| Rung | Floor | Assumed knowledge | Swept from |
|---|---|---|---|
| **L0** | Anchor | Verbatim subject, unedited | n/a |
| **L1** | Peer | Knows the domain, has no context on this artifact | L0 |
| **L2** | Newcomer | General practitioner, lacks the domain vocabulary | L1 as written |
| **L3** | Outsider | Lacks the field entirely, needs grounding and analogy | L2 as written |
| **L4** | First principles | No technical background, every concept built from ordinary experience | L3 as written |
| **L5+** | Derived | Declared at the batch that reaches it | Previous layer as written |

Each pass sweeps the layer the previous pass **wrote**, not the original subject. Opacity at a rung is opacity of that rung's prose, which does not exist until that prose exists.

**Per-pass loop:** sweep the written layer above → resolve every item → write the new layer → check fidelity → append to the document → re-read what was appended → sweep it. Passes are sequential. Do not sweep L2 while L1 is unwritten, and do not draft two layers from one reading.

**An empty sweep is a failed sweep, not a finished subject.** If a sweep against a written layer returns nothing, it ran at the wrong floor. Re-run it one rung lower before concluding the pass.

---

## WORKFLOW STEPS

### 1. FRAME AND SCAFFOLD

- **Capture the subject exactly.** Quote the source verbatim as L0. Resolve a file reference and quote the relevant span. Preserve a user quote character-for-character. L0 is the fidelity anchor for every later pass.
- **Establish the claim set.** Enumerate what the subject asserts. Every rung checks fidelity against this list.
- **Declare batch 1's two floors.** The first batch only. Declare later floors at the batch that reaches them.

```bash
Resolve `{parent}` from an explicit causal subject/nav/source filename; else supplied orchestrator Parent; else `User`.
{projex-scripts}/new-projex.sh --repo-root <repo-root> --type unpack --title "{subject-name}" --parent {parent} --projex-dir <projex-folder>
```
```powershell
{projex-scripts}\new-projex.ps1 -RepoRoot <repo-root> -Type unpack -Title "{subject-name}" -Parent {parent} -ProjexDir <projex-folder>
```

**Scaffold the file before pass 1, not after the last batch.** The document is the working artifact. Write L0 and the claim set first, then append each pass's own sweep, layer, and fidelity block as that pass closes. **The next sweep reads the layer from the file, not from memory. A layer that never reached the document cannot be swept.**

### 2. SWEEP FOR OPACITY

Walk the `OPACITY INVENTORY` against the layer above **as written in the document**, or against L0 on the first pass. Record every hit as a row: category, the exact span it attaches to, and what the reader at the next floor is missing.

> **Sweep the text as written, not as intended.** A term the author finds obvious is a Term hit if the floor's reader cannot restate it. Familiarity is not a defense.

### 3. RESOLVE THE UNKNOWNS

Every sweep item needs an answer before it can be written thin. Answers come from three places, in order:

1. **The subject itself.** The explanation is present elsewhere in the source
2. **Investigation.** Read the code, doc, or spec that grounds the item
3. **Neither.** The item is unresolvable

> **Do NOT invent an explanation for an unresolvable item.** Mark it `Unverified` inline in the layer and carry it to Residual Opacity. An invented explanation reads exactly like a resolved one, and no later pass can tell them apart.

### 4. WRITE THE LAYER

Restate the whole subject at the new floor. Resolve every sweep item from this pass in place, inside the prose, not in an appended glossary. The layer stands alone. A reader who starts here needs nothing from the layer above.

**Per-layer rules:**
- Write from the claim set, not by editing the layer above. A patched previous layer is not a new layer
- Preserve every claim from the claim set. Thinning adds access, and never adds, drops, or softens a claim
- Preserve exact: identifiers, file paths, code blocks, error messages, version numbers
- Expand compression into sentences, and keep the underlying structure where it carries meaning
- Add worked examples and concrete instances. They do most of the thinning
- Analogies are permitted from the Outsider floor down, and each is followed by where it breaks down

### 5. FIDELITY CHECK

Compare the new layer against L0 and the claim set:

- [ ] Every claim in the claim set appears in the layer
- [ ] No claim appears that is absent from L0 and not marked `Unverified`
- [ ] No claim's strength changed. Hedges neither added nor removed
- [ ] Preserve-exact content is byte-identical to L0
- [ ] Every sweep item from this pass is resolved in the prose or marked `Unverified`

Fix a failed check in the layer before the pass closes.

### 6. CLOSE THE PASS

Append the pass to the document: sweep table, layer, fidelity block. Update `Layers Written`. Re-read what was appended.

First pass of the batch → return to step 2 for the second. Second pass of the batch → continue to step 7.

### 7. CLOSE THE BATCH WITH A DRIFT PASS

Run at the end of every batch, across every layer written so far. Per-pass fidelity compares each layer to L0 in isolation, so it cannot see erosion that accumulates down the ladder.

- Track each claim in the claim set through every layer. Does the newest layer still carry the same force as L0?
- Identify claims that softened one degree per rung, passing individually but changed collectively
- Identify explanations introduced at one rung and treated as source fact at the next
- Identify examples that replaced the claim they were illustrating

Corrections land in the affected layer, noted in that layer's fidelity block. Update Residual Opacity with everything the newest layer still leaves closed.

### 8. CHECKPOINT

Present to the user:

1. **The newest layer.** The current terminal reading
2. **Residual Opacity.** What is still closed, and at which floor each item would open
3. **What another two passes would cover.** The two floors the next batch would use and the residue items they would resolve

Then ask whether two more passes are needed.

- **Yes** → declare the next batch's two floors, return to step 2
- **No** → continue to step 9
- **A span the user flags as still dense** → it enters the next batch's sweep as a pre-seeded item. User-reported opacity outranks the agent's own sweep.

Record the checkpoint in the document: batch number, what was presented, the user's answer. **The last checkpoint is the document's state.** It says whether another batch is expected. The document carries no Status field, and it sits in `.projex/` while checkpoints remain open.

> **Do NOT recommend stopping because the subject reads clear to the agent.** The agent's floor is not the reader's floor. Report the residue and let the user decide.

### 9. VALIDATION

Run when the user stops.

**Checks:**
- [ ] Every batch ran exactly two passes, or fewer because the user stopped it, never three
- [ ] Every batch closed with a checkpoint recorded in the document
- [ ] No batch opened without the user's answer at the previous checkpoint
- [ ] Each pass's sweep read the previous layer *as written in the document*, not L0 and not memory
- [ ] No layer written before the previous pass's layer was appended
- [ ] Empty sweep, if any, re-run one rung lower rather than accepted as a finished subject
- [ ] Every sweep item traces to an exact span in the layer above
- [ ] Every sweep ran the full opacity inventory, not a subset
- [ ] Each layer is a fresh restatement, not the previous layer edited
- [ ] Each layer stands alone, with no dependency on the layers above it
- [ ] Every layer carries its own fidelity block
- [ ] Drift pass run at the close of every batch
- [ ] Residual Opacity is non-empty
- [ ] Unverified claims listed separately, none silently promoted to fact

### 10. FINALIZE

1. Front-load the source, floor reached, batch count, and layer count
2. Cross-reference the source projex and any projex the investigation touched
3. Move to `.projex/closed/`. Re-invocation pulls the document back to `.projex/` and opens the next batch
4. Offer `/guide-projex` when the user wants sources to read rather than a thinner restatement

---

## TEMPLATE

```markdown
# Unpack: [Subject]

> **Author:** [Model(Role), or Model, or self identity, fallback: "Agent"]
> **Parent:** [User | Orchestrator | {filename}]
> **Source:** [filename, doc § heading, or "user quote"]
> **Floor Reached:** [rung + name of the newest layer]
> **Batches:** [n] | **Layers Written:** [n]
> **Related Projex:** [filenames]

---

## L0: Anchor

> [The subject, verbatim. Unedited.]

**Claim set:**

1. [claim]
2. [claim]

---

## Batch 1: L1 Peer, L2 Newcomer

### Pass 1 → L1 Peer

**Swept:** L0

#### Sweep

| # | Category | Span | Missing at this floor |
|---|---|---|---|
| 1.1 | Term | `[exact span]` | [what the reader cannot restate] |
| 1.2 | Leap | `[exact span]` | [the unstated premise] |

#### Layer

[Full restatement of the subject at the Peer floor. Every pass-1 sweep item resolved in the prose.]

#### Fidelity

[Claims preserved: n/n. Deviations, `Unverified` marks, and drift corrections, or "clean".]

---

### Pass 2 → L2 Newcomer

**Swept:** L1 as written

#### Sweep

| # | Category | Span | Missing at this floor |
|---|---|---|---|
| 2.1 | [category] | `[exact span in L1]` | [gap] |

#### Layer

[Full restatement at the Newcomer floor, written from the claim set.]

#### Fidelity

[...]

---

### Drift after Batch 1

| Claim | L1 | L2 | Verdict |
|---|---|---|---|
| [claim] | [force as stated] | [force as stated] | held \| softened \| replaced by example |

[Corrections applied and where.]

---

### Checkpoint after Batch 1

- **Presented:** L2 layer | residue: [n items]
- **Next batch would cover:** [two floors] → resolves [which residue items]
- **User:** [two more \| stop \| stop + flagged spans: `[span]`]

---

## Batch 2: [floors declared at this batch]

[...same structure, passes 3 and 4...]

---

## Residual Opacity

Everything the newest layer still leaves closed. Never empty.

| Item | Why it stayed | Floor that would open it |
|---|---|---|
| [term / leap / mechanism] | out of scope \| unresolvable \| below the current floor | [rung, source, workflow, or person] |

---

## Unverified Claims

- [Statement written into a layer that L0 does not support and investigation could not ground]

---

## Open Questions

- [Anything the author could not settle about the subject itself]
```

---

## UNPACK PRINCIPLES

- **Two, then ask.** A batch is two passes and a question. The user sets the ladder's length, never the agent
- **Rungs, not a rewrite.** Each pass sweeps the prose the last pass produced. Two layers drafted in one sitting are not independent, because the second one was never swept
- **Residue always remains.** The subject is never declared clear. The document names what it left closed
- **Fidelity over accessibility.** A thinner layer that bends a claim is a failed layer
- **Layers stand alone.** Each is a complete restatement, readable without the ones above
- **Opacity is found by category.** Walk the inventory in full rather than consulting it when something feels unclear
- **Unresolvable is a valid answer.** Mark it, carry it, list it. Never fill it with invention

---

## OUTPUT

Produces unpack document at `.projex/{yymmddhhmm}-{name}-unpack.md`, moving to `.projex/closed/` when the user stops, containing:
- Verbatim anchor and its claim set
- One sweep, layer, and fidelity block per pass, appended as each pass closes
- Drift pass and checkpoint record per batch
- Residual Opacity, never empty
- Unverified claims listed separately

**Committing:** Present the unpack document to the user. Do not commit automatically. Commit only when the user explicitly requests it.

---

## NOTES

- Re-invocation on an existing unpack opens the next batch. It never rewrites a layer already written. Fix a wrong layer with `/revise-projex`.
- Scope subjects longer than a section down before framing. Unpacking a whole document produces layers no one reads.
- A projex document written under Dehydrate is a common subject. Unpacking it does not alter the source.
