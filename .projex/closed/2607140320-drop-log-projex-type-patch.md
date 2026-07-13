# Patch: Drop Log projex type

> **Date:** 2026-07-14
> **Author:** agent (patch-projex)
> **Directive:** "drop log-projex" — remove the Log projex type entirely
> **Source Plan:** Direct
> **Result:** Success

---

## Summary

Removed the standalone **Log** projex type from the framework. Deleted `log-projex.md` and stripped every current reference to the Log type / `/log-projex` workflow from the framework docs. The framework now offers 19 types (was 20). The unrelated per-plan **execution log** mechanism (`{yymmddhhmm}-{plan-name}-log.md`, authored by execute-projex) is untouched — it shares the `-log.md` suffix but is a different thing.

---

## Changes

### Deleted workflow spec

**File:** `log-projex.md`
**Change Type:** Deleted
**What Changed:** Removed the entire 216-line Log workflow spec.

### SKILL.md

**File:** `SKILL.md`
**Change Type:** Modified
**What Changed:**
- Frontmatter `description`: removed `` `log-projex` `` from the invocation backtick list.
- Types list: removed the `- **Log** — Standalone change record...` bullet.
- Workflow examples: removed the `/log-projex.md HEAD~3..HEAD` example line.
- Auxiliary Artifact Commit Policy: removed `log` from the auxiliary workflows enumeration.

**Why:** SKILL.md is the framework spec; Log must no longer appear as an offered type or invocable workflow.

### CLAUDE.md (on-disk only — gitignored)

**File:** `CLAUDE.md`
**Change Type:** Modified (not committed — file is in `.gitignore`)
**What Changed:** Workflow Types header `(20)` → `(19)`; removed the Log table row.

**Why:** Keeps the local project-instructions file consistent. Not version-controlled, so the edit lives on disk only.

### AGENTS.md

**File:** `AGENTS.md`
**Change Type:** Modified
**What Changed:** Workflow Types header `(20)` → `(19)`; removed the Log table row.

### README.md

**File:** `README.md`
**Change Type:** Modified
**What Changed:**
- Document Types table (Planning & Execution): removed the `**Log** | /log-projex` row.
- Common Chains table: removed the standalone `Log | —` row; dropped `Log` from the `Patch | Review, Audit, Log` row (now `Patch | Review, Audit`, purpose trimmed to "Quick fix warrants retrospective validation").
- Git Integration list: removed the `- **Log** — observes existing changes...` bullet.
- File Reference table: removed the `log-projex.md` row.

### orchestrate-projex.md

**File:** `orchestrate-projex.md`
**Change Type:** Modified
**What Changed:** Framework References list: removed the `@./log-projex.md — standalone change record` bullet.

### revise-projex.md

**File:** `revise-projex.md`
**Change Type:** Modified
**What Changed:**
- Escalation criteria: dropped "a Log" from the born-closed example and "or a Log entry" from the guidance (now: write a new document instead).
- Decision aid: the closed-document branch previously pointed to `/log-projex`; reworded to "don't reopen — write a new document to record history".

**Why:** Both were cross-references directing users to the now-removed Log type.

---

## Verification

**Method:** Repo-wide grep for `log-projex` and `**Log**` across `*.md` after edits; inspection of the removal commit's file stat.

**Result:**
```
Grep log-projex|\*\*Log\*\* over *.md → No matches found
git show --stat dafdb1d → log-projex.md deleted (216 lines); AGENTS/README/SKILL/orchestrate/revise edited; close-projex.md not included
```

**Status:** PASS

---

## Impact on Related Projex

| Document | Relationship | Update Made |
|----------|-------------|-------------|
| — | No active plan/proposal/nav referenced the Log type | None |

Historical projex under `.projex/closed/` and `.projex/` (walkthroughs, imaginations, proposals) mention "Log" only as past record or as the unrelated Evidence/Execution/Revision/Change Log constructs — left untouched.

---

## Notes

- **Scope boundary honored:** Only the standalone Log *type* was removed. The per-plan execution log (`-log.md`) referenced in execute-projex.md, debug-projex.md, and close-projex.md is a separate mechanism and was not touched.
- **close-projex.md:** Its step-2 sweep table already omitted Log (edited earlier in the session), so no Log-type reference remained to remove. Its execution-log wording was left as-is per instruction.
- **CLAUDE.md is gitignored** in this repo, so its edit could not be committed — the on-disk change removes the Log row locally but is not tracked.
