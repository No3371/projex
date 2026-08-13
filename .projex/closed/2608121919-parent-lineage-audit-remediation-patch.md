# Patch: Parent Lineage Audit Remediation

> **Status:** Complete (Success)
> **Author:** OpenAI Codex (Patch agent)
> **Directive:** Remediate actionable findings in 2608121912-parent-lineage-and-projex-tree-addition-audit.md.
> **Source Plan:** 2608121756-parent-lineage-and-projex-tree-addition-plan.md
> **Parent:** 2608121912-parent-lineage-and-projex-tree-addition-audit.md
> **Result:** Success

---

## Summary

Audit findings were bounded, prescriptive, and immediately verifiable: no design choice or broad lifecycle change remained. This patch completes Parent creator cutover, makes tree corruption/read failures safe, documents Python 3, and records corrected verification evidence.

---

## Changes

### Tree engine and regressions

**Files:** `.projex-tree.py`; `tests/projex-tree.test.sh`; `tests/projex-tree.test.ps1`; `tests/fixtures/projex-tree/duplicate-parent/`; `tests/fixtures/projex-tree/invalid-utf8/`
**Change Type:** Modified | Created

**What Changed:**
- `.projex-tree.py:32-43` translates invalid UTF-8 into normalized `E_IO` detail `invalid UTF-8`; main returns exit 4 without a traceback.
- `.projex-tree.py:138-160` records `E_PARENT_DUPLICATE` when any duplicate Parent candidate points into the reached component before child eligibility can omit it; failure keeps stdout empty.
- Both tree suites add byte-exact shared-golden checks for a reachable duplicate Parent child and invalid UTF-8 discovery; each now has 46 assertions.

**Why:** A successful partial tree is unsafe lifecycle context; malformed bytes must use the documented failure API.

### Creator and inventory cutover

**Files:** `conclude-projex.md`; `close-projex.md`; `README.md`; `tests/README.md`
**Change Type:** Modified

**What Changed:**
- `conclude-projex.md:95-99` selects the successor as `{parent}` and passes it to `new-projex`.
- `close-projex.md:139` gives walkthrough templates a deterministic Parent from the plan filename.
- `README.md:120` states that `projex-tree` requires Python 3; `tests/README.md:32` records the expanded shared-golden coverage and assertion count.

**Why:** Every new creator must satisfy the mandatory Parent operand/template contract, and wrapper runtime requirements must be visible in the public utility inventory.

### Execution record

**File:** `.projex/2608121844-parent-lineage-and-projex-tree-addition-log.md`
**Change Type:** Modified

**What Changed:** Added the patch cross-reference and audit-remediation record at lines 10 and 61-67, including corrected four-suite evidence.

**Why:** The original log reported creator suites green despite the audited cutover failures; the record now links the remediation and its reproducible evidence.

---

## Verification

**Method:** Focused shell and PowerShell suites against shared fixture/golden corpus.

**Result:**
```
PASS=46 FAIL=0 CASES=46
PASS=46 FAIL=0 CASES=46
PASS=46 FAIL=0 CASES=46
PASS=46 FAIL=0 CASES=46
```

Commands: `bash tests/new-projex.test.sh`; `bash tests/projex-tree.test.sh`; `pwsh -NoProfile -File tests/new-projex.test.ps1`; `pwsh -NoProfile -File tests/projex-tree.test.ps1`.

**Status:** PASS

---

## Impact on Related Projex

| Document | Relationship | Update Made |
|---|---|---|
| `2608121912-parent-lineage-and-projex-tree-addition-audit.md` | Parent audit | Remediated its three Significant findings and Python-runtime documentation finding; preserved uncommitted. |
| `2608121756-parent-lineage-and-projex-tree-addition-plan.md` | Source plan | No plan edit: patch repairs already-specified contracts without changing scope or objectives. |
| `2608121844-parent-lineage-and-projex-tree-addition-log.md` | Execution evidence | Linked patch and appended corrected remediation/verification evidence. |

## Notes

The audit's informational commit-trailer finding is intentionally unchanged: no existing history was rewritten. This patch commits directly to the open execution branch; it does not close or merge it.
