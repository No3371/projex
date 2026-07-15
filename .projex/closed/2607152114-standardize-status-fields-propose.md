# Standardize Projex Status Fields

> **Status:** Complete (Accepted)
> **Created:** 2026-07-15
> **Author:** Claude (Opus 4.8)
> **Related Projex:** 2607152207-standardize-status-fields-patch.md (implements this proposal)

---

## Summary

Projex workflow types each define their own Status vocabulary, and those vocabularies disagree with each other and with the lifecycle table in `CLAUDE.md`. This proposal defines a single canonical lifecycle vocabulary — **Draft / Ready / In Progress / Blocked / Complete / Abandoned / Escalated** — that every type draws from, maps each type's current field onto it, and aligns the field values with the `.projex/` folder states.

---

## Problem Statement

### Current State

Only **6 of 19 types** carry an in-document lifecycle Status field; the rest track lifecycle purely by folder location (`.projex/` → `.projex/closed/`). Where a field exists, the vocabularies diverge:

| Type | Current Status field |
|------|----------------------|
| **Plan** | Draft / Ready / In Progress / Blocked / Complete |
| **Proposal** | Draft / Review / Accepted / Rejected |
| **Definition** | Draft / Stabilizing / Stable |
| **Interview** | In Progress / Concluded |
| **Debug** | In Progress → Resolved / Exhausted / Non-Repro |
| **Exploration** | In Progress / Done *(doc-level)* |

Three different words mean "just started" (`Draft`, `In Progress`, `Pending`) and five mean "done" (`Complete`, `Concluded`, `Resolved`, `Stable`, `Done`). The `CLAUDE.md` lifecycle table further disagrees with the specs (e.g. Plan table says `Draft → Executed → Closed`; the spec field says `Draft | Ready | In Progress | Blocked | Complete`).

### Gap / Need / Opportunity

An agent (or human) reading a projex document cannot reliably infer state from the Status field, because the value space depends on the type. A single vocabulary makes state machine-readable across all types, and lets the folder location and the field value be kept in lockstep.

### Why Now?

The folder scaffolding already anticipates the full lifecycle — `.projex/`, `.projex/closed/`, `.projex/abandoned/`, `.projex/archived/` all exist — but no field vocabulary maps onto `abandoned`, and there is no state for work an agent hands back to a human. Standardizing now closes that gap before more type specs are authored.

---

## Proposed Change

### Overview

One ordered, canonical lifecycle vocabulary. Every type's Status field draws **only** from it. Type-specific terminal meanings (Accepted, Rejected, Resolved, Stable, …) survive as an inline **outcome qualifier** on a canonical state — e.g. `Complete (Accepted)` — never as their own lifecycle stage.

### Canonical vocabulary

| Canonical | Meaning | Folder |
|-----------|---------|--------|
| `Draft` | Authored, still changing, not yet reliable | `.projex/` |
| `Ready` | Finalized & actionable, not yet started *(types with an execution phase only)* | `.projex/` |
| `In Progress` | Actively being worked / executed | `.projex/` |
| `Blocked` | Stalled awaiting an external dependency; resumable when it clears | `.projex/` |
| `Escalated` | Agent has exhausted its ability; handed back to a human to decide or take over | `.projex/` |
| `Complete` | Terminal — done | `.projex/closed/` |
| `Abandoned` | Terminal — dropped without completion | `.projex/abandoned/` |

**`Blocked` vs `Escalated`:** `Blocked` waits on a *thing* (another task, a resource) and resumes automatically when it clears. `Escalated` waits on a *human judgment* because the agent cannot proceed on its own — Debug's "Exhausted (handed back)" and "Non-Repro" are the canonical examples.

### Migration mapping

| Type | Current → Canonical |
|------|---------------------|
| **Plan** | ✅ already canonical — serves as the reference |
| **Proposal** | Draft · **In Progress** *(=Review)* · **Complete (Accepted)** · **Complete (Rejected)** |
| **Definition** | Draft · **In Progress** *(=Stabilizing)* · **Complete (Stable)** — never-closed type, stays in `.projex/` (see exception) |
| **Interview** | **In Progress** · **Complete (Concluded)** |
| **Debug** | **In Progress** · **Complete (Resolved)** · **Escalated (Exhausted)** · **Escalated (Non-Repro)** |
| **Exploration** | **In Progress** · **Complete (Done)** |

### Exceptions

- **Never-closed types (Definition, Navigation):** may sit at `Complete` while remaining in `.projex/` rather than moving to `.projex/closed/`. `Complete` for these means "current stable state," and they can drop back to `In Progress` on revision.
- **Per-item statuses are out of scope.** Objective status (`Success / Partial / Failed`) and per-question status (`Pending / In Progress / Done / Dropped`) are not document lifecycle and are left untouched.

### Machine-readable via a strict blockquote

Status stays a single line — the existing `> **Status:**` blockquote — but it becomes a **strict, canonical contract** so it is parseable without adding a second field. No YAML frontmatter.

**Grammar:** `> **Status:** <state>` optionally followed by ` (<outcome>)`, where `<state>` is exactly one of the 7 canonical values.

```
> **Status:** In Progress
> **Status:** Complete (Accepted)
> **Status:** Escalated (Non-Repro)
```

A single regex parses it: `^> \*\*Status:\*\* ([\w ]+?)(?: \((.+)\))?\s*$` → group 1 = `state`, group 2 = optional `outcome`.

Rationale: agents already know the blockquote format, and the framework has no runtime code or scripts that parse document status today. A strict blockquote gives a deterministic line for any future tooling with **one** source of truth and **no** drift — the cost of separate frontmatter (a second place to sync, ceremony on every doc, expansion to all 19 types) buys nothing a consumer needs yet.

### Resolved decisions

1. **`Ready` retained**, Plan-only — the one type with a genuine "finalized but not started" gap.
2. **Outcome qualifier is inline** — `Complete (Accepted)` — in the single Status blockquote; no separate field.
3. **`Escalated` stays in `.projex/`** — no dedicated folder; it is an active state awaiting human judgment, alongside `Blocked`.
4. **`Rejected` → `Complete (Rejected)`** — a rejected proposal ran its course; it is not `Abandoned`.
5. **Machine-readability via a strict canonical blockquote**, not YAML frontmatter — one greppable line, one source of truth.

---

## Impact Analysis

### Affected Areas

- **Status-field spec files (6):** `plan-projex.md` (reference only), `propose-projex.md`, `define-projex.md`, `interview-projex.md`, `debug-projex.md`, `explore-projex.md` — update the Status blockquote in each template to the strict canonical grammar and fix any prose naming old values.
- **`SKILL.md`:** document the canonical vocabulary, folder mapping, and the strict Status-blockquote grammar as the single source of truth so future type specs inherit it.
- **`CLAUDE.md`:** reconcile the lifecycle table with the canonical vocabulary.
- **`close-projex.md` / `execute-projex.md` / `revise-projex.md`:** verify status-transition prose uses canonical values (Plan already canonical, so likely minimal).

### Dependencies

- None external. This is a documentation-only change within the framework.

### Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Existing projex docs in target repos carry old Status values | High | Low | Old values are self-explanatory; no automated migration needed — new docs use canonical set going forward |
| Outcome nuance lost when collapsing to `Complete (X)` | Low | Low | Inline qualifier preserves the outcome word |
| `Escalated` folder placement debated | Low | Low | Resolved: stays in `.projex/` (active) |

### Breaking Changes

None for tooling (no code parses Status today). Prose-level only; the strict blockquote is backward-compatible with how agents already read status.

---

## Open Questions

_All resolved (see Resolved decisions). None outstanding._

---

## Next Steps

If accepted:
1. Add the canonical vocabulary, folder mapping, and strict Status-blockquote grammar to `SKILL.md` as the single source of truth.
2. Update the Status blockquote + fix prose in the 6 status-field specs per the migration mapping.
3. Reconcile the `CLAUDE.md` lifecycle table.
4. Verify finalize steps in `close`/`execute`/`revise` use canonical values.
5. Author a Plan to execute steps 1–4 (multi-file coordinated edit — worth the full cycle).

---

## Appendix

### Alternatives Considered

- **Separate the three kinds of status** (document / per-item / verdict) into named field concepts — rejected: heavier, and the user wanted one lifecycle vocabulary, not a taxonomy.
- **Reconcile the CLAUDE.md table to specs with minimal churn** — rejected: leaves the cross-type vocabulary divergence in place.
- **YAML frontmatter (`state:`/`outcome:`) for machine-readability** — rejected: adds a second source of truth (drift risk), ceremony on every doc, and scope across all 19 types, to serve a parser that does not exist. A strict canonical blockquote gives deterministic parsing with one source of truth.
