---
description: This workflow guides the creation and maintenance of **Navigation** projex documents — living roadmaps that evolve throughout development and steer work forward at any scale. (This is part of @projex-framework skill. It is a MUST to load the skill first.)
---

## PURPOSE

Navigation documents are the steering mechanism for a scope of work — from an entire project down to a single module, subsystem, or feature area. They maintain a roadmap of where that scope is headed, track progress against milestones, and evolve as understanding deepens and circumstances change.

**Key characteristics:**
- Living document — continuously revised, never "closed"
- Appropriately abstract — milestones and phases relative to the navigation's scope, not implementation details one level below
- References child projex — plans, proposals, evals, explorations spawned from the roadmap
- Each invocation is a checkpoint — research status quo, assess progress, discuss with user, revise direction
- Drives or pivots development — the document that answers "what should we work on next?" for its scope

**Scale flexibility:**
- A **project-level** navigation in `projex/` steers the overall initiative — phases are major capability areas
- A **module-level** navigation in `src/parser/projex/` steers parser development — phases might be syntax coverage milestones
- A **feature-area** navigation in `docs/projex/` steers documentation — phases might be coverage or quality targets
- The abstraction level is always relative: a module navigation's milestones may be as concrete as a project navigation's phases, and that's correct

**Contrast with Plan:**
- **Navigation** — open-ended, evolving, directional; lives for the duration of its scope's active development
- **Plan** — bounded, executable, detailed; born and closed within a focused cycle

---

## INVOCATION

```
/navigate-projex.md <scope description>
/navigate-projex.md @{existing-navigation-document}
```

**First invocation** (create new roadmap):
- `/navigate-projex.md Game engine project roadmap` — project-level, lives in root `projex/`
- `/navigate-projex.md Parser module direction` — module-level, lives in `src/parser/projex/`
- `/navigate-projex.md API documentation coverage` — area-level, lives in `docs/api/projex/`

**Subsequent invocations** (revisit and revise):
- `/navigate-projex.md @20260201-engine-roadmap-nav.md`
- `/navigate-projex.md @20260201-engine-roadmap-nav.md We shipped the parser, what's next?`

---

## WORKFLOW STEPS

### CREATING A NEW NAVIGATION

#### 1. RESEARCH STATUS QUO

Before drafting any roadmap, build comprehensive understanding of the target scope:

1. **Survey the scope** — What exists within this area? What state is it in? What's working, what's not?
2. **Collect existing projex** — Scan the relevant `projex/` folder(s) for active proposals, plans, evals, explorations. For a module-level navigation, focus on that module's projex folder; for project-level, scan broadly
3. **Identify momentum** — What has been worked on recently? What's stalled? What's blocking progress?
4. **Understand goals** — What is this scope trying to achieve? What does success look like?
5. **Spot gaps** — What areas within this scope have no projex activity? What's neglected?
6. **Locate parent/sibling navigations** — Does a higher-level navigation exist that this one nests under? Are there peer navigations for adjacent scopes?

#### 2. DISCUSS WITH USER

Navigation documents represent shared understanding between agent and user. Before drafting:

- Present findings from research: "Here's what I see..."
- Ask about priorities: "Which of these matters most right now?"
- Clarify vision: "Where do you want this to be in [timeframe]?"
- Surface trade-offs: "Pursuing X means deferring Y — is that acceptable?"
- Confirm scope: "Should this roadmap cover [area] or is that separate?"

**Do not skip this step.** A roadmap the user doesn't recognize as their own is worthless.

#### 3. DRAFT THE ROADMAP

Create file in the appropriate `projex/` folder for the scope: `{yyyymmdd}-{roadmap-name}-nav.md`

- Project-level → root `projex/`
- Module-level → `src/{module}/projex/`
- Area-level → `{area}/projex/`

**Template Structure:**

```markdown
# [Roadmap Title]

> **Created:** YYYY-MM-DD | **Last Revised:** YYYY-MM-DD
> **Author:** [name or agent]
> **Scope:** [what this roadmap covers — be specific about boundaries]
> **Parent Navigation:** [link to higher-level nav, if any]
> **Related Projex:** [links]

---

## Vision

[2-4 sentences: Where is this project/initiative headed? What does the end state look like?]

---

## Current Position

**As of YYYY-MM-DD:**

[Brief assessment of where things stand right now — what's done, what's in flight, what's blocked]

### Recent Progress
- [Completed milestone or significant event] — [date or reference]
- [Completed milestone or significant event] — [date or reference]

### Active Work
- [In-progress item] — [status, reference to projex document]

### Known Blockers
- [Blocker] — [what it's blocking, what would unblock it]

---

## Roadmap

### Phase 1: [Phase Name] — [Status: Current / Next / Future / Done]

**Goal:** [What this phase achieves]

**Milestones:**
- [ ] [Milestone 1] — [brief description]
  - Ideation: [links to proposals, evals, explorations]
  - Execution: [links to plans, walkthroughs, patches]
- [ ] [Milestone 2] — [brief description]
  - Ideation: [links]
  - Execution: [links]
- [x] [Completed Milestone] — [brief description]
  - Ideation: [links]
  - Execution: [links to walkthrough or patch that completed this]

**Exit Criteria:** [How we know this phase is done]

---

### Phase 2: [Phase Name] — [Status]

[Same structure as Phase 1]

---

### Phase N: [Phase Name] — [Status]

[Same structure]

---

## Priorities

**Current focus:** [What should be worked on right now and why]

**Next up:** [What comes after current focus]

**Deferred:** [What's deliberately postponed and why]

---

## Open Questions

- [ ] [Strategic question that affects roadmap direction]
- [ ] [Decision that needs to be made before proceeding]

---

## Revision Log

| Date | Summary of Changes |
|------|--------------------|
| YYYY-MM-DD | Initial roadmap created |
```

#### 4. VALIDATE AND COMMIT

**Check:**
- [ ] Vision is clear and agreed upon with user
- [ ] Phases are meaningful groupings, not arbitrary
- [ ] Milestones are concrete enough to know when they're done
- [ ] Current position accurately reflects reality
- [ ] References to existing projex are correct
- [ ] Priorities reflect user's stated goals

```bash
git add projex/{yyyymmdd}-{roadmap-name}-nav.md
git commit -m "projex(nav): create roadmap - {roadmap-name}"
```

---

### REVISITING AN EXISTING NAVIGATION

This is the primary mode — navigation documents are revisited repeatedly.

#### 1. RESEARCH CURRENT STATE

1. **Read the navigation document** — Understand the existing roadmap
2. **Check referenced projex** — What's been completed, abandoned, or changed since last revision?
3. **Scan for new projex** — Were any plans, proposals, evals, walkthroughs, or patches created since the last revision that aren't referenced? Specifically:
   - Check `projex/` for new active documents
   - Check `projex/closed/` for completed walkthroughs and patches that may correspond to roadmap milestones
   - Match discovered execution artifacts (walkthroughs, patches, completed plans) to existing milestones
4. **Assess the codebase** — Has the project changed in ways the roadmap doesn't reflect?
5. **Check revision log** — When was this last updated? What's happened since?

#### 2. ASSESS PROGRESS

For each phase and milestone:

- **Done?** Mark completed milestones, link to walkthroughs/patches
- **Still valid?** Does this milestone still make sense given what's changed?
- **Blocked?** What's preventing progress?
- **Scope changed?** Should milestones be split, merged, or reworded?

For overall roadmap:
- **Phases still right?** Should phases be reordered, added, or removed?
- **Priorities shifted?** Has something become more/less urgent?
- **Vision still holds?** Or has the project's direction changed?

#### 3. DISCUSS WITH USER

Present findings and proposed changes:

- "Since last revision, [X] was completed and [Y] was abandoned. Here's what I think should change..."
- "Milestone [Z] seems blocked by [issue]. Should we deprioritize it or address the blocker?"
- "I notice [new area] has no coverage in the roadmap. Should we add it?"
- "Based on recent work, I'd suggest pivoting Phase 2 to focus on [alternative]..."

**Gather input before modifying.** The agent proposes, the user disposes.

#### 4. REVISE THE DOCUMENT

Update the navigation document in-place:

1. **Update "Last Revised" date**
2. **Update "Current Position"** — Refresh the status snapshot
3. **Update milestones** — Check off completed, add new, remove obsolete
4. **Link all relevant projex** — For each milestone, ensure both ideation (proposals, evals, explorations) and execution (plans, walkthroughs, patches) references are present. If a walkthrough or patch clearly delivers on a milestone, link it and mark the milestone done
5. **Revise phases** — Adjust ordering, scope, or add/remove phases as needed
6. **Update priorities** — Reflect current focus
7. **Resolve or add open questions**
8. **Append to revision log** — Summarize what changed and why

#### 5. SPAWN WORK (OPTIONAL)

If the revision reveals actionable next steps, suggest or create follow-up projex:

- Gap identified → suggest `/explore-projex` or `/eval-projex`
- Direction decided → suggest `/propose-projex`
- Milestone ready for implementation → suggest `/plan-projex`
- Small immediate fix → suggest `/patch-projex`

The navigation document itself doesn't execute — it informs what to execute next.

#### 6. COMMIT REVISION

```bash
git add projex/{yyyymmdd}-{roadmap-name}-nav.md
git commit -m "projex(nav): revise roadmap - {roadmap-name}"
```

If other projex documents were updated with references back to this navigation:
```bash
git add projex/{other-projex-file}.md    # each file explicitly
git commit -m "projex: update references to {roadmap-name} nav"
```

---

## NAVIGATION PRINCIPLES

- **Relatively abstract** — Milestones describe outcomes at one level above the navigation's scope. A project nav says "Parser handles all expression types"; a parser module nav says "Binary, unary, and ternary expressions supported" — but neither says "Add binary expression parsing to parser.rs line 142"
- **Living, not archived** — Navigation documents stay in their `projex/` folder for their entire active lifetime. They are never moved to `closed/`
- **User-aligned** — Every revision involves the user. The agent researches and proposes; the user confirms direction
- **Honest assessment** — Don't paper over stalled milestones or ignored phases. If something isn't progressing, say so
- **Reference-rich** — The roadmap should be a map of maps — linking to the detailed projex that flesh out each milestone
- **One per scope** — Each scope (project, module, area) should have at most one active navigation document in its `projex/` folder. If scope grows too large, split into separate navigations at the appropriate level with cross-references
- **Nestable** — A project-level navigation may reference module-level navigations as its "detail layer", and a module-level navigation may reference its parent project navigation for broader context. This nesting follows the same folder structure as all other projex types

---

## FOLDER PLACEMENT

| State | Location |
|-------|----------|
| Active (always) | The `projex/` folder matching the navigation's scope |
| Superseded by new roadmap | `projex/archived/` within the same scope |

Navigation documents are **never** placed in `projex/closed/` — they are living documents that persist until their scope's active development concludes or a new roadmap supersedes them.

**Examples:**
- Project-level: `projex/20260201-engine-roadmap-nav.md`
- Module-level: `src/parser/projex/20260201-parser-direction-nav.md`
- Area-level: `docs/projex/20260201-docs-coverage-nav.md`

---

## NOTES

- Navigation is the only projex type designed to be revised indefinitely
- Each revision should be a meaningful checkpoint, not a trivial tweak — if only one milestone changed, a revision log entry may suffice without full agent discussion
- When a navigation document grows unwieldy, consider splitting by domain or phase into separate navigations at the appropriate folder level
- A sub-area navigation does not need to repeat context already captured in a parent navigation — link to it instead
- Use relative paths when referencing repository files and other projex documents
