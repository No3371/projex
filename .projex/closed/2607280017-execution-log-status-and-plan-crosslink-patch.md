# Patch: Execution log status field + plan cross-link

> **Date:** 2026-07-28
> **Author:** agent (patch-projex)
> **Directive:** "Make the agent reference log and walkthrough when updating the plan status. Also add Status field to -log files."
> **Source Plan:** Direct
> **Result:** Success

---

## Summary

Execution logs (`{yymmddhhmm}-{plan-name}-log.md`) were structurally invisible to the close sweep: the plan carried no link to its log, and the log carried no `Status` field, so any status-based document scan skipped it silently. Plans were reaching `.projex/closed/` while their logs stayed behind in the active folder with no failure signal.

Two changes close the gap. The log now carries a `> **Status:**` field like every other projex document, and the plan now names its log in the same edit that sets the plan's status.

---

## Changes

### execute-projex.md — log header format + Status

**File:** `execute-projex.md`
**Change Type:** Modified
**What Changed:**
- Execution Log Template header converted from plain `Key: value` lines to the standard `> **Field:**` blockquote form, matching the debug log header at `debug-projex.md:144`.
- Added `> **Status:** In Progress` as the first field.
- INITIALIZE step 3: instructs setting `Status` on creation, plus a note that the log's status tracks the *execution* (`In Progress` → `Complete` | `Blocked`), that the log is not a workflow type, and that it lives and closes with its plan.

**Why:** The log had no status, so an agent enumerating documents by `> **Status:**` — the natural way to build a close sweep list — never saw the file. No missing-path error, just absence.

### execute-projex.md — POST-EXECUTION cross-link

**File:** `execute-projex.md`
**Change Type:** Modified
**What Changed:**
- Step 6 reworded to "Update plan status and cross-link the log": the edit that sets the plan to `Complete`/`Blocked` now also adds `> **Log:** {yymmddhhmm}-{plan-name}-log.md` to the plan header. Filename only, never a path.
- New step 7 sets the execution log's own `Status` to the same terminal value.
- Former step 7 (commit) renumbered to 8. Its existing `stage-n-commit` call already staged both plan and log, so no commit-shape change was needed.
- OUTPUT list updated: log now ships with a terminal `Status`; plan now ships with a `> **Log:**` field.

**Why:** POST-EXECUTION is the first point where both files exist and are being edited and committed together — the cheapest place to establish the plan → log link.

### close-projex.md — FINALIZE DOCUMENTS

**File:** `close-projex.md`
**Change Type:** Modified
**What Changed:**
- Step 1 now writes **both** `> **Walkthrough:**` and `> **Log:**` on the plan, with the rationale stated inline: nothing else links plan → log, so a plan closed without the field leaves its log unreachable by any later sweep or audit. Notes that `Log:` may already be present from execute-projex and must be verified rather than assumed.
- New step 2 reconciles the log's `Status` against the plan's — terminal (`Complete`/`Blocked`) and matching. Its load-bearing side effect is stated: it forces the closing agent to open the log and see its real filename immediately before the sweep.
- Steps 2–4 renumbered to 3–5; the two internal "from step 2" cross-references in the `move-n-stage` block updated to "step 3".

**Why:** Step 3's sweep procedure is a forward walk from the plan's `Source:` and `Related Projex:` fields. Neither field ever named the log, so the walk could not reach it — the log survived only if the agent recalled the prose "always" clause and hand-typed the path.

---

## Design Decisions

- **The log gets no `Closed` status.** Its lifecycle is `In Progress` → `Complete` | `Blocked`, mirroring the plan. Like the plan, the move into `.projex/closed/` is what marks it closed. Introducing a third terminal state only for the log would have made the pair inconsistent at exactly the moment they are supposed to move together.
- **Blockquote header, not a plain `Status:` line.** A plain line would have satisfied the letter of the request but not the purpose — status scans look for `> **Status:**`. `debug-projex.md` already used the blockquote form for its debug log, so this aligns the two rather than inventing a format.
- **`-log` remains a non-type.** It occupies the `{projex-type}` slot in the naming convention (`SKILL.md:32`) without being a type. This patch does not resolve that ambiguity; it makes the file scannable despite it.

---

## Verification

**Method:** Grepped all `.sh`/`.ps1` scripts (repo root and `.github/`) for `Base Branch`, `Plan File`, `Repo Root`, `Worktree Path`, `Started` before changing the header format. Re-read both edited sections after renumbering.

- No script parses the log header — zero hits. Format change is safe.
- `close-projex.md:54` reads "the `Base Branch:` field" format-agnostically; the substring survives the blockquote conversion, so old and new logs both resolve.
- `do-projex.md:136` explicitly excludes creating the log or populating its header from its scope — no change needed there.
- FINALIZE DOCUMENTS re-read end to end: steps 1–5 sequential, both "from step 3" references correct.

---

## Not Done

- **Existing logs not backfilled.** Roughly 128 `-log.md` files under `.projex/closed/` across repos still use the plain-text header and have no `Status`. Nothing parses those fields and `close-projex.md:54` handles both forms, so they are readable as-is. Backfilling is a separate change.
- **No fifth row added to the FINALIZE DOCUMENTS closing-rule table.** The execution log still fits none of the four rows (never-closed, born-closed, born-open→closed, dependent-plan). The new step 2 covers it procedurally instead. Worth revisiting if logs keep getting stranded.
- **Absolute path in log headers unaddressed.** The template populates `Repo Root:` from precheck's `REPO_ROOT` verbatim, which yields an absolute path (e.g. `S:/Repos/projex`) inside a projex document — contrary to the relative-paths-only rule in `SKILL.md`. Out of scope for this directive; flagged for a follow-up.

---

## References

- `execute-projex.md` — Execution Log Template, INITIALIZE step 3, POST-EXECUTION steps 6–8, OUTPUT
- `close-projex.md` — FINALIZE DOCUMENTS steps 1–5
- `debug-projex.md:144` — prior art for the blockquote log header
- `2607140320-drop-log-projex-type-patch.md` — removed the standalone Log *type*; explicitly left this execution-log mechanism untouched
