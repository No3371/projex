# Patch: New-projex PowerShell suite exit status

> **Status:** Complete (Success)
> **Author:** PatchNewProjexPsExit
> **Parent:** 2608130624-named-new-projex-parameter-migration-implementation-audit.md
> **Directive:** Fix `tests/new-projex.test.ps1` successful-process exit state so it participates correctly in `tests/run-all.ps1`.
> **Source Plan:** Direct audit finding
> **Result:** Success

---

## Scope

Qualifies: known stale `$LASTEXITCODE`; one focused suite; one clear repair; immediate focused and aggregate verification. No parser, workflow, API, audit, close, or merge change.

## Summary

`tests/new-projex.test.ps1` now cleans its fixture before deciding the suite process result. Zero failed assertions explicitly exit `0`; failed assertions still exit `1`.

## Changes

### Focused PowerShell suite

**File:** `tests/new-projex.test.ps1`  
**Change Type:** Modified  
**What Changed:**
- Moved the failure exit after the `finally` cleanup block.
- Added explicit `exit 0` for the zero-failure path.

**Why:** The final expected collision invocation returns `2`; without an explicit successful exit, that native-command status leaks to the in-process aggregate runner.

## Verification

**Method:** Focused suite, in-process exit reproduction, isolated failed-assertion control, aggregate runner.

**Result:**
```text
pwsh -NoProfile -File tests/new-projex.test.ps1
PASS=181 FAIL=0
exit 0

pwsh -NoProfile -Command '& ./tests/new-projex.test.ps1; "SUITE_LASTEXITCODE=$LASTEXITCODE"'
PASS=181 FAIL=0
SUITE_LASTEXITCODE=0

isolated test-copy with $Fail initialized to 1
PASS=181 FAIL=1
exit 1

pwsh -NoProfile -File tests/run-all.ps1
=== new-projex.test.ps1
PASS=181 FAIL=0
```

**Status:** PASS — suite reaches the aggregate runner without a suite-failed marker; its `181` passes contribute to aggregate total. The failed-assertion control exits `1` after cleanup.

## Aggregate Attribution

`tests/run-all.ps1` still exits `1` for unrelated baseline failures: `projex-tree.test.ps1` summary has `CASES=46`; `resolve-conflicts.test.ps1`, `worktree.test.ps1`, and `dirty-base.test.ps1` do not produce accepted summaries; `close-precheck.test.ps1` reports `PASS=17 FAIL=19`. The patched `new-projex.test.ps1` reports `PASS=181 FAIL=0` and is accepted.

## Related Projex

| Document | Relationship | Update |
|---|---|---|
| 2608130624-named-new-projex-parameter-migration-implementation-audit.md | Parent audit finding | Unchanged by directive |
