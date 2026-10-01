# Patch: new-projex creator inventory fixture

> **Status:** Complete
> **Author:** Claude Opus 5.5 (patch subagent)
> **Parent:** User
> **Directive:** Make `tests/new-projex.test.ps1` pass on `main` (pre-existing failure making `run-all.ps1` exit nonzero) by fixing the real cause.
> **Source Plan:** Direct
> **Result:** Success
> **Related Projex:** 2610012130-close-precheck-ps1-pwsh7-windows-fixes-patch.md | 2610012116-new-projex-born-closed-complete-status-patch.md

---

## Summary

`creator inventory` check failed in both `new-projex.test.sh` and `new-projex.test.ps1`. Check greps every `*-projex.md` at repo root for `new-projex.sh` and compares against `tests/fixtures/projex-creators.txt`. Two scaffolding workflows were never registered: `blueteam-projex.md` and `unpack-projex.md` (both call `new-projex` with `--type blueteam` / `--type unpack`). Prior report named only unpack — blueteam also missing. Fix: register both in fixture. Specs correct; fixture stale.

---

## Changes

### Creator fixture

**File:** `tests/fixtures/projex-creators.txt`
**Change Type:** Modified
**What Changed:**
- Added `scaffold:blueteam-projex.md` (line 3) and `scaffold:unpack-projex.md` (line 22) → 22 scaffold + 4 manual creators

**Why:** Fixture is the closed creator inventory; it lagged commits `cd8aae4` (blueteam) and `05c3727` (unpack).

### Test README

**File:** `tests/README.md`
**Change Type:** Modified
**What Changed:**
- `new-projex.test.sh` / `.ps1` row: assertions `178 / 181` → `190 / 193`; `20-scaffold` → `22-scaffold`

**Why:** Stale counts/inventory size.

---

## Verification

**Method:** Ran both suites before/after; then both runners.

**Result:**
```
before: new-projex.test.sh  PASS=189 FAIL=1 (FAIL: creator inventory)
        new-projex.test.ps1 PASS=192 FAIL=1 (FAIL: creator inventory)
after:  new-projex.test.sh  PASS=190 FAIL=0
        new-projex.test.ps1 PASS=193 FAIL=0
run-all.ps1: total PASS=681 FAIL=0, exit 0
```

**Status:** PASS

---

## Impact on Related Projex

| Document | Relationship | Update Made |
|----------|-------------|-------------|
| 2610012130-close-precheck-ps1-pwsh7-windows-fixes-patch.md | Sibling patch, same directive | none |
| 2610012116-new-projex-born-closed-complete-status-patch.md | Prior patch that surfaced this failure | none |

---

## Notes

- Code commit: `249fe1a` (`Projex: 2610012130-new-projex-creator-inventory-fixture`).
- Any new scaffolding workflow must add its line to `tests/fixtures/projex-creators.txt`.
