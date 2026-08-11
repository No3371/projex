# Patch: Source Hygiene Guardrails Documentation Consistency

> **Status:** Complete
> **Author:** sonic (depth-1 patch delegate)
> **Directive:** `orchestrate-projex <<sonic>> execute, audit, [patch], close<think> @.projex/2608052327-source-hygiene-guardrails-plan.md`; apply only the two audit-supported documentation consistency fixes before close
> **Source Plan:** 2608052327-source-hygiene-guardrails-plan.md
> **Related Projex:** 2608112054-source-hygiene-guardrails-audit.md | 2608052327-source-hygiene-guardrails-log.md
> **Result:** Success

---

## Summary

Corrected the two documentation inconsistencies identified by the independent audit without rewriting the seven historical execution commits. The audit pass now distinguishes permitted ephemeral step subjects from typed landing/patch/debug subjects while retaining the trailer requirement; the plan and execution log now record the intentional five-file trailer-form check, excluding `SKILL.md`.

Scope guard: bounded documentation-only patch; no design choice, script/test change, formatter, broad test suite, or close operation.

---

## Changes

### Audit commit-composition check

**File:** `audit-projex.md`
**Change Type:** Modified
**What Changed:**
- Clarified that conventional-type subject and type-vs-diff checks apply to landing, merge, patch, and debug-fix commits.
- Explicitly permitted `projex: step …` and `projex(do): …` subjects on ephemeral step commits while requiring `Projex:` trailers for every commit changing a file outside any `.projex/` folder.
- Updated the report-template counters to say “where required,” matching the exception.

**Why:**
`execute-projex.md` already defines ephemeral step subjects as intentional; the audit check must not report those subjects as false positives while still enforcing the boundary rule and trailer.

### Trailer-form verification expectation and evidence

**Files:** `.projex/2608052327-source-hygiene-guardrails-plan.md` | `.projex/2608052327-source-hygiene-guardrails-log.md`
**Change Type:** Modified
**What Changed:**
- Corrected the plan's automated check to expect exactly `close-projex.md`, `debug-projex.md`, `do-projex.md`, `execute-projex.md`, and `patch-projex.md`; `SKILL.md` is intentionally absent because the commit convention is canonical in `execute-projex.md`.
- Recorded the corrected five-file result in the execution log's Deviations section.
- Marked the plan follow-up `[PATCHED]` and linked this patch document; no execution objectives remain open.

**Why:**
The implementation deliberately keeps commit composition out of `SKILL.md`; the verification expectation, not the implementation, was stale.

---

## Verification

**Method:** targeted documentation checks and Git metadata inspection; no broad tests or formatter.

**Result:**

```text
git diff --check -- audit-projex.md .projex/2608052327-source-hygiene-guardrails-plan.md .projex/2608052327-source-hygiene-guardrails-log.md: PASS
Targeted trailer-form search: exactly close-projex.md, debug-projex.md, do-projex.md, execute-projex.md, patch-projex.md; SKILL.md absent by design
Audit commit check: step-subject exception present; trailer boundary retained; report counters say “where required”
Implementation commit: 93a598b docs(framework): clarify source hygiene commit checks
Implementation commit trailer: Projex: 2608112102-source-hygiene-guardrails-consistency
No scripts, tests, or historical execution commits changed
```

**Status:** PASS

---

## Impact on Related Projex

| Document | Relationship | Update Made |
|----------|-------------|-------------|
| `2608052327-source-hygiene-guardrails-plan.md` | Source plan | Corrected verification expectation; marked follow-up patched and linked this document |
| `2608052327-source-hygiene-guardrails-log.md` | Execution log | Recorded the five-file result and intentional `SKILL.md` exclusion |
| `2608112054-source-hygiene-guardrails-audit.md` | Audit input | Read for re-verification only; left unmodified and uncommitted under auxiliary-artifact policy |

---

## Notes

- Existing source-touching execution commits remain unchanged and unrewritten; their missing trailers are fix-forward history findings.
- The execution branch remains open. This patch does not run close.
