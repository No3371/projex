# Patch: Standardize Projex Status Fields

> **Status:** Complete
> **Date:** 2026-07-15
> **Author:** Claude (Opus 4.8)
> **Directive:** orchestrate-projex patch(opus) — standardize the Status fields across the projex framework, per the proposal drafted this session
> **Source Proposal:** 2607152114-standardize-status-fields-propose.md
> **Result:** Success

---

## Summary

Applied one canonical lifecycle vocabulary — `Draft | Ready | In Progress | Blocked | Escalated | Complete | Abandoned` — across every projex spec that carries a document Status field. Type-specific terminals (Accepted, Rejected, Stable, Concluded, Resolved, Done, Non-Repro, Exhausted) now survive as inline outcome qualifiers on a canonical state (e.g. `Complete (Accepted)`, `Escalated (Non-Repro)`). SKILL.md now holds the vocabulary + folder mapping + strict Status-blockquote grammar as the single source of truth. Documentation-only; no runtime code parses status.

---

## Changes

### Single source of truth

**File:** `SKILL.md`
**Change Type:** Modified
**What Changed:**
- Added a new `## Lifecycle Status` section (between `## Organizing` and `## Workflow`) defining: the canonical vocabulary table (7 states + folder mapping), the `Blocked` vs `Escalated` distinction, the strict `> **Status:**` blockquote grammar + parse regex `^> \*\*Status:\*\* ([\w ]+?)(?: \((.+)\))?\s*$`, and the exceptions (never-closed types may sit at `Complete` in `.projex/`; per-item statuses out of scope, use plain bold not the blockquote).

**Why:** Future type specs inherit one authoritative definition; no per-type drift.

---

### Lifecycle table reconciliation

**File:** `CLAUDE.md`
**Change Type:** Modified
**What Changed:**
- Proposal row lifecycle: `Draft → Accepted/Rejected` → `Draft → In Progress → Complete (Accepted/Rejected)`
- Plan row lifecycle: `Draft → Executed → Closed` → `Draft → Ready → In Progress → Complete`

**Why:** The two rows named non-canonical states, the exact divergence the proposal flagged. Other rows describe folder lifecycle (`Born open → Closed`, `Never closed`) consistent with the canonical folder mapping — left as-is.

> **Note:** `CLAUDE.md` is git-ignored in this repo (`.gitignore` line 2). The edit is applied to the working copy but is NOT part of any commit. It persists on disk only.

---

### Status-field specs

**File:** `propose-projex.md`
**Change Type:** Modified
**What Changed:**
- Template blockquote: `Draft | Review | Accepted | Rejected` → `Draft | In Progress | Complete (Accepted) | Complete (Rejected)`
- Folder-by-status list: `Pending (Draft/Review)` → `Pending (Draft / In Progress)`; `Accepted`/`Rejected` → `Complete (Accepted)`/`Complete (Rejected)`
- Readiness prose: "Before moving to `Review` status" → "Before moving to `In Progress` (under review) status"
- STATUS TRANSITIONS diagram + legend rewritten to canonical (`In Progress` = under review; `Complete (Accepted)`/`Complete (Rejected)`)
- Output folder note: "Accepted proposals stay in `.projex/`…" → "`Complete (Accepted)` proposals stay in `.projex/`…"

**File:** `define-projex.md`
**Change Type:** Modified
**What Changed:**
- Template blockquote: `Draft | Stabilizing | Stable` → `Draft | In Progress | Complete (Stable)`
- Revise-step prose: `Stabilizing`→`In Progress`, `Stable`→`Complete (Stable)`; added never-closed note (stays in `.projex/` at `Complete (Stable)`, drops to `In Progress` on revision)
- Notes bullet: `Draft → Stabilizing → Stable` → `Draft → In Progress → Complete (Stable)`

**File:** `interview-projex.md`
**Change Type:** Modified
**What Changed:**
- Template blockquote: `In Progress | Concluded` → `In Progress | Complete (Concluded)`
- Conclude step: update status to `Complete (Concluded)`
- Folder placement: `Concluded → .projex/closed/` → `Complete (Concluded) → .projex/closed/`

**File:** `debug-projex.md`
**Change Type:** Modified
**What Changed:**
- Debug-doc template blockquote: `Resolved | Exhausted (handed back)` → `Complete (Resolved) | Escalated (Exhausted)`
- Non-repro prose: `Status: Non-Repro` → `Status: Escalated (Non-Repro)`
- Finalize prose: `Status: Resolved` (or `Exhausted`) → `Status: Complete (Resolved)` (or `Escalated (Exhausted)`)
- Debug-*log* template blockquote (`In Progress`) already canonical — unchanged. Prose section headers ("If Exhausted", "Option B: Exhausted", "Two terminal states") retain Resolved/Exhausted as outcome-concept words per the inline-qualifier design.

**File:** `explore-projex.md`
**Change Type:** Modified
**What Changed:**
- Added a doc-level `> **Status:** In Progress | Complete (Done)` blockquote to the header template. The per-target `**Status:** Pending | In Progress | Done | Dropped` (plain bold, not a blockquote) is a per-item status — left untouched per the exception.

**Why (all specs):** Each type's Status field now draws only from the canonical set; terminal nuance preserved via inline outcome qualifier.

---

### Reference-only

**File:** `plan-projex.md` — No change. Its `Draft | Ready | In Progress | Blocked | Complete` blockquote is already canonical and serves as the reference type.

**Files:** `close-projex.md`, `execute-projex.md`, `revise-projex.md` — No change. Status-transition prose already uses only canonical values (`Complete`, `Blocked`, `Ready`, `In Progress`); per-objective `Success/Partial/Failed` is a per-item status, out of scope.

---

## Verification

**Method:** Grep all `*-projex.md` for the `^> \*\*Status:\*\*` blockquote and for stale vocabulary (`Stabilizing`, `Concluded`, `Review`, `Non-Repro`, `Resolved | Exhausted`).

**Result:**
```
plan-projex.md:      Draft | Ready | In Progress | Blocked | Complete
propose-projex.md:   Draft | In Progress | Complete (Accepted) | Complete (Rejected)
define-projex.md:    Draft | In Progress | Complete (Stable)
interview-projex.md: In Progress | Complete (Concluded)
debug-projex.md:     In Progress   (log)  /  Complete (Resolved) | Escalated (Exhausted)  (doc)
explore-projex.md:   In Progress | Complete (Done)
```
All 6 status-field blockquotes conform to the strict grammar. Remaining old-vocab hits are confined to: the source proposal's own problem statement (historical, intended) and README's "Review" workflow-type name (not a status value).

**Status:** PASS

---

## Impact on Related Projex

| Document | Relationship | Update Made |
|----------|-------------|-------------|
| 2607152114-standardize-status-fields-propose.md | Source proposal (implemented) | Status → `Complete (Accepted)`; Related Projex → this patch; moved to `.projex/closed/` |

---

## Notes

- **Escalated is new** to the framework (no prior type used it). It maps Debug's "Exhausted (handed back)" and "Non-Repro" — states awaiting human judgment, distinct from `Blocked` (awaits a thing). Stays in `.projex/` (no dedicated folder).
- **explore-projex.md reconciliation:** the proposal's migration mapping lists Exploration as having a doc-level `In Progress / Complete (Done)` status, but the actual template had only a per-target status (plain bold). Added a canonical doc-level `> **Status:**` blockquote to satisfy the mapping while leaving the per-item status untouched. The plain-bold vs blockquote distinction cleanly separates per-item status from doc lifecycle — the parse regex only matches the blockquote.
- **Patch vs Plan (scope guard):** the proposal's own Next Steps suggested a Plan, but the human overrode with `patch(opus)` this session. Design was fully resolved in the proposal; this was a mechanical, bounded application (8 files, no branching decisions, immediately verifiable) — a patch is the correct vehicle.
- No target-repo migration needed: old Status values in existing docs are self-explanatory; new docs use the canonical set going forward.
- **CLAUDE.md is git-ignored** (`.gitignore` line 2). Its reconciliation was applied to the working copy but could not be committed. If CLAUDE.md should be version-controlled with this change, that is a separate decision for the maintainer (un-ignore + commit).
