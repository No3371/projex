---
description: Quick, lightweight revision of an existing projex document (Plan, Proposal, Definition, Nav, Map, or any other type) when new context invalidates part of it. No new document type — edits the target in place and logs why. (Part of @projex-framework skill. MUST load the skill first.)
---

## PURPOSE

Projex documents go stale mid-life. Plan assumption turns out false, Proposal trade-off changes, Definition boundary shifts, Nav milestone reprioritized. Revise-projex fixes the **document itself** to match reality. Skips re-running that document's full authoring workflow.

**Revise vs Patch — the distinction that matters:**

`/patch-projex` and `/revise-projex` are both quick-action, no-ceremony, direct-commit workflows — but they act on different targets:

| | Patch | Revise |
|---|---|---|
| **Target** | Code, config, implementation — anything that isn't a projex document | A projex document itself (Plan, Proposal, Definition, Nav, Map, etc.) |
| **When** | The system needs to change | The record of intent/analysis needs to change |
| **Example directive** | "Fix the off-by-one in the parser loop" | "Step 2 of the plan assumed Redis, it's actually Memcached" |

**Agents conflate them — that's the reason for the split.** "Patch the plan" during `/orchestrate-projex` triggers the code-change reflex by default. Often the actual ask is to correct the *document*. Rule of thumb: directive about what a projex `.md` file *claims* → Revise. Directive about what the code/system *does* → Patch.

**Key characteristics:**
- Edits the target projex document in place — no new projex file
- Every revision leaves a `## Revision Log` entry: what changed, what triggered it
- Scope-guarded — escalates to that document's full authoring workflow if the core content is wrong, not just a detail
- Commits directly to whatever branch the document currently lives on

---

## INVOCATION

```
/revise-projex <projex file reference> <what changed / new context>
```

**Examples:**
- `/revise-projex @2607311430-auth-timeout-plan.md Step 2 assumed session store was Redis, it's actually Memcached`
- `/revise-projex @2607311430-api-cleanup-plan.md scope needs to exclude the billing endpoints, legal flagged them`
- `/revise-projex @2607311430-auth-subsystem-def.md session lifecycle boundary changed — tokens now rotate on refresh, not just expiry`
- `/revise-projex @2607311430-engine-roadmap-nav.md milestone 3 deprioritized, milestone 5 moved up`
- `/revise-projex @2607311430-payment-refactor-proposal.md trade-off analysis missed the PCI compliance constraint`

---

## SCOPE GUARD

**CRITICAL: Before any edit, confirm this is a revision, not a re-author.**

### Qualifies as Revise
- [ ] Target is an existing projex document (any type, any open/living status — not `Complete`/closed unless the type is meant to be reopened, e.g. Definition/Nav/Map)
- [ ] New context is concrete — a finding, a deviation, a stated requirement change, not speculation
- [ ] The document's core content (approach, direction, boundary) still holds — only specific sections need adjusting
- [ ] Expressible as edits to existing sections, not a rewrite of the document's reasoning

### Escalate to the Document's Own Authoring Workflow If
- The core content itself is now wrong, not just a detail (e.g. a Plan's approach, a Proposal's direction, a Definition's identity)
- The objective/scope changed materially — this is a different thing than what was originally authored
- The document's type is normally born-closed and already closed (e.g. a completed Plan, a finished Walkthrough) — don't reopen it, write a new document instead
- Fixing this requires redoing that workflow's research/analysis step from scratch

**If scope exceeds revise threshold:** stop, inform the user, recommend the document's own workflow (`/plan-projex`, `/propose-projex`, `/define-projex`, etc. — new version or supersede). Do not force a rewrite through revise.

---

## WORKFLOW STEPS

### 1. CONTEXT ASSESSMENT

1. **Resolve the target repo** — from the projex file's location:
```bash
git -C <absolute-path-to-projex-file-directory> rev-parse --show-toplevel
```
Record as `<repo-root>`. Every raw git command below passes it as `git -C <repo-root> …`.
2. **Read the target document** in full — its current claims, structure, status.
3. **Understand the trigger** — what new fact/finding/requirement conflicts with what the document currently says? Cite it precisely (file:line if code-derived, quote if stakeholder-stated).
4. **Locate every section the trigger touches** — a changed assumption often affects more than the one section named in the directive (e.g. in a Plan: Scope, one Step, and Success Criteria at once). Don't patch only what the directive names.
5. **Run the scope guard** above.

### 2. REVISE THE DOCUMENT

Edit the target file directly:

- Update affected section(s) to reflect new context. Keep that document type's existing structure — don't restructure. A Plan Step keeps Objective/Confidence/Files/Changes/Rationale/Verification/If-this-fails shape; a Definition keeps identity/boundaries/properties shape.
- New context invalidates part of the document outright? Mark it superseded in place, don't silently delete. Future reader needs to know it was tried/claimed and replaced.
- Adjust `Status` if the revision changes it (e.g. a Plan's `Blocked` → `Ready` once the blocker context is resolved into the plan)
- Append to `## Revision Log` (create the section, just above `## Notes`, if this is the document's first revision):

```markdown
## Revision Log

- **YYYY-MM-DD:** [What changed] — trigger: [concrete finding/requirement, cited]
```

- Keep dehydrated style consistent with the rest of the document (see SKILL.md § Dehydrate)

### 3. COMMIT

```bash
{projex-scripts}/stage-n-commit.{sh|ps1} <repo-root> "projex(revise): [concise description of what changed]" path/to/{yymmddhhmm}-{name}-{type}.md
```

- Single commit per revision (group edits from the same trigger)
- Distinct, unrelated triggers arriving together → separate revisions, separate commits

### 4. UPDATE RELATED DOCUMENTS

1. **Documents that reference or depend on the revised one** (source proposal, sibling split plans, definitions it links to) — flag if their claims about it are now stale
2. **Nav** (if noted `> **Nav:** {nav-filename}`) — update only that nav: note the revision under the relevant milestone
3. **Commit these together** if touched:

```bash
{projex-scripts}/stage-n-commit.{sh|ps1} <repo-root> "projex(revise): update related docs for {name} revision" \
  .projex/{yymmddhhmm}-{related-doc-name}-{type}.md \
  .projex/{yymmddhhmm}-{nav-name}-nav.md
```

---

## REVISE vs OTHER WORKFLOWS — DECISION AID

```
Is a projex document's own content wrong/stale? ─── No → /patch-projex (code/config) or nothing
 └─ Yes → Core content invalidated (approach/direction/identity), not just a detail? ─── Yes → that document's own authoring workflow (new/superseding)
     └─ No → Document already Complete/closed (and not meant to be reopened)? ─── Yes → don't reopen — write a new document to record history
         └─ No → /revise-projex
```

---

## GIT INTEGRATION

### No New Branch, No New File

Revisions commit directly wherever the target document currently lives. Base branch for most types, ephemeral `projex/*` branch (or worktree) if revising a Plan mid-execution. Document's own git history is the revision trail. `close-projex` picks up the final state when an execution branch merges.

### Git Operation Discipline

See SKILL.md § Git Operation Discipline.

---

## OUTPUT

This workflow produces:
- The target projex document, edited in place, with a `## Revision Log` entry
- Updated related documents (dependents/nav), if any
- No new projex file, no new branch

---

## QUALITY CHECKLIST

Before considering the revision complete:

- [ ] Confirmed the target is a document, not code/implementation (if it's code, this should have been `/patch-projex`)
- [ ] Trigger cited precisely (file:line or verbatim requirement)
- [ ] Every section the trigger affects was checked, not just the one named in the directive
- [ ] Revision Log entry added
- [ ] Status adjusted if the revision changes it
- [ ] Related documents updated (dependents, nav)
- [ ] Commit(s) made with `projex(revise):` prefix
- [ ] No stale information left contradicting the new context

---

## NOTES

- Revise-projex has no document type of its own — it operates on any existing projex document
- Document needs revising again next pass, same underlying reason? Core content is wrong. Escalate to that document's own authoring workflow — don't revise a third time
- During `/orchestrate-projex`: directive says "patch"/"fix", target ambiguous (code vs document)? Resolve against this distinction before delegating. Wrong target spawns the wrong subagent
- Use relative paths when referencing repository files
- The `projex(revise):` prefix marks document revisions in git history. It belongs to the `projex(...)` doc-op family alongside `projex:` (plan and log additions) and `projex(patch): add patch doc`. Commits that change source instead carry a conventional-type subject plus a `Projex:` trailer — `execute-projex.md` § Commit Message Convention
