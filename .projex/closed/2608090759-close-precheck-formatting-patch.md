# Patch: Discard close-precheck Formatting Drift

> **Author:** terra (high), depth-1 patch delegate
> **Directive:** Correct the rejected formatting-patch characterization; restore intended source content without `git reset --hard`.
> **Source Plan:** 2608081953-close-precheck-script-plan.md
> **Audit:** 2608090754-close-precheck-script-resume-audit.md
> **Result:** Success (corrected)

---

## Summary

The prior patch incorrectly adopted a broad formatting rewrite as a bounded audit resolution. `ef8753e` changed 608 implementation and 156 test lines; the audit finding concerned only unattributed `close-precheck.sh` drift, and `tests/close-precheck.test.sh` was clean at `ffe3868` before audit.

This correction restores both files from `ffe3868` with targeted `git restore --source=ffe3868 --worktree -- close-precheck.sh tests/close-precheck.test.sh`, not `git reset --hard`. Commit: `50fb939` (`projex(patch): discard close precheck formatting drift`). The drift is discarded, not adopted.

Scope guard: qualifies — exact known files and reference commit, one restoration approach, immediate verification; no behavior/design work.

---

## Changes

### Discarded formatting rewrite

**Files:** `close-precheck.sh` | `tests/close-precheck.test.sh`
**Change Type:** Restored
**What Changed:**

- Restored both paths byte-for-byte to their `ffe3868` contents.
- Removed the net formatting rewrite introduced by `ef8753e`; no test formatting change is retained.

**Why:**

- The earlier adoption exceeded the audit finding and created unrelated whole-file diff noise.

---

## Verification

**Method:** reference-content comparison; whitespace check; Bash syntax; direct behavioral suite.

**Result:**

```text
git diff --quiet ffe3868 -- close-precheck.sh tests/close-precheck.test.sh: exit 0
git diff --check: clean
bash -n close-precheck.sh tests/close-precheck.test.sh: exit 0
bash tests/close-precheck.test.sh: PASS=62 FAIL=0
```

**Status:** PASS

---

## Impact on Related Projex

| Document | Relationship | Update Made |
| --- | --- | --- |
| 2608081953-close-precheck-script-plan.md | Source plan | Replaced inaccurate adopted-formatting relationship with discarded-drift correction. |
| 2608090541-close-precheck-script-plan-log.md | Execution log | Corrected the prior patch entry and recorded restoration commit/evidence. |
| 2608090754-close-precheck-script-resume-audit.md | Audit artifact | Left uncommitted and unchanged; its dirty-source finding is dispositioned by discarding drift. |
| 2608090614-close-precheck-script-plan-audit.md | Older audit artifact | Left uncommitted and unchanged. |

---

## Remaining Blockers

- `pwsh` unavailable: PowerShell parser, direct suite, and aggregate evidence remain `NOT RUN`.
- Full clean-mode Bash aggregation retains the human-waived shared executable-mode blocker; no mode change attempted.
- No close or merge is authorized.
