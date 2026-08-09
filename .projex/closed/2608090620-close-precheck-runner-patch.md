# Patch: PowerShell close-precheck Runner Registration

> **Author:** luna (xhigh), depth-1 patch delegate
> **Directive:** Invoke `/patch-projex.md` against the audit findings; apply only bounded fixes that pass the patch scope guard.
> **Source Plan:** 2608081953-close-precheck-script-plan.md
> **Audit:** 2608090614-close-precheck-script-plan-audit.md
> **Result:** Success

---

## Summary

Validated the audit's concrete runner defect: `tests/run-all.ps1` omitted `close-precheck.test.ps1` although its exact-once guard already required it. Added the suite to the runner array; no broader verification gaps or platform evidence were represented as fixed.

Patch scope: one focused runner-line change, one clear approach, immediate static verification. Commit: `bdde857` (`projex(patch): register PowerShell close-precheck suite`).

## Changes

### PowerShell suite runner

**File:** `tests/run-all.ps1`
**Change Type:** Modified
**What Changed:**

- Added `close-precheck.test.ps1` to `$suites` exactly once at line 4.
- Preserved the existing exact-once execution counter and fail-closed summary/process-status checks.

**Why:** The audit finding was valid: the runner could never execute the new suite, so its existing exact-once guard failed on every PowerShell run.

## Verification

**Method:** Static source check; Bash close-precheck suite; Bash aggregate runner; runtime availability check.

**Result:**

```text
suite_array_occurrences=1
guard_present=True
summary_guard_present=True
bash tests/close-precheck.test.sh: PASS=38 FAIL=0
bash tests/run-all.sh: PASS=38 FAIL=56; exit=1
pwsh=NOT RUN
```

The aggregate failure is the tracked clean-checkout executable-mode issue documented by the audit; it is separate from the PowerShell runner fix and the later whitespace correction. PowerShell parser, direct suite, and aggregate evidence remain unavailable.

**Status:** PASS for the bounded runner correction; overall plan remains `Blocked`.

## Impact on Related Projex

| Document | Relationship | Update Made |
| ---------- | ------------- | ------------- |
| 2608081953-close-precheck-script-plan.md | Source plan | Step 4 marked `[PATCHED]`; status remains `Blocked` pending platform and verification evidence. |
| 2608090541-close-precheck-script-plan-log.md | Execution log | Added patch action, commit, verification, and remaining blockers. |
| 2608090614-close-precheck-script-plan-audit.md | Audit artifact | Left uncommitted and unchanged; its runner finding is resolved by this patch. |

## Remaining Blockers

- `pwsh` is unavailable; PowerShell parser/runtime/direct-suite/aggregate parity remains `NOT RUN`.
- Clean Bash aggregation still fails with status `126` for existing direct-invocation utilities unless executable modes are temporarily enabled; no fix was attempted under this patch.
- The audit's broader drift, symlink, encoding, stash, scale, output-budget, and expanded fail-closed matrix remains open.
- No close or merge is authorized.

## Notes

Correction: the prior return incorrectly described the unrelated `tests/run-all.sh` whitespace-only drift as preserved/pre-existing. That drift was introduced during patch dispatch, then removed with a targeted edit without `git reset --hard`. The audit document remains uncommitted and untracked; the valid PowerShell runner fix remains committed.
