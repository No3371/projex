# Patch: new-projex Born-Closed Complete Status

> **Status:** Complete
> **Author:** Opus 5.5 (patch subagent, orchestrated)
> **Parent:** User
> **Related Projex:** 2610012008-projex-tree-relative-repo-root-patch.md
> **Directive:** `new-projex.sh` writes `Status: Closed` for born-closed types. `Closed` isn't in the canonical status list, which uses `Complete`. The patch doc was corrected by hand, but the script still does it.
> **Source Plan:** Direct
> **Result:** Success

---

## Summary

Both scaffolders (`new-projex.sh` and `new-projex.ps1`) stamped born-closed types (`log`, `archive`, `patch`, `preplan`, `scan`, `guide`, `conclude`) with `> **Status:** Closed`. `Closed` is not a canonical state; SKILL.md § Lifecycle Status defines `Complete` as the terminal state for `.projex/closed/`. Both scripts now write `Complete`. Both test suites gained assertions pinning the scaffolded Status line for a non-born-closed type (`Draft`) and a born-closed type (`Complete`, placed under `closed/`).

---

## Changes

### Scaffolders

**File:** `new-projex.sh`
**Change Type:** Modified
**What Changed:**
- Line 125: born-closed branch sets `status="Complete"` (was `"Closed"`).

**File:** `new-projex.ps1`
**Change Type:** Modified
**What Changed:**
- Line 112: `$Status = if ($IsBornClosed) { 'Complete' } else { 'Draft' }` (was `'Closed'`).

**Why:**
The PowerShell port had the same defect as the bash script. The Status blockquote grammar requires exactly one canonical value; every born-closed scaffold was emitting a non-canonical one that had to be hand-corrected (as in `2610012008-projex-tree-relative-repo-root-patch.md`).

---

### Test suites

**File:** `tests/new-projex.test.sh`
**Change Type:** Modified
**What Changed:**
- After the default-directory `memo` case: asserts exactly one `> **Status:** Draft` line.
- New born-closed case: scaffolds a `patch` with `--projex-dir .projex`, asserts the path is under `.projex/closed/`, the file exists, and exactly one `> **Status:** Complete` line.

**File:** `tests/new-projex.test.ps1`
**Change Type:** Modified
**What Changed:**
- Same three assertions mirrored (`Draft` on the default memo; born-closed patch under `.projex/closed`, created, exactly one `> **Status:** Complete` line).

**Why:**
Neither suite previously checked the Status line, so the defect was invisible to tests.

---

## Verification

**Method:** Ran both suites on `main` before the change, after the change, and with the scripts temporarily reverted to `Closed` (new tests kept) to confirm the new assertions detect the defect.

**Result:**
```
Before (main):            sh  PASS=185 FAIL=1   ps1 PASS=188 FAIL=1
After fix:                sh  PASS=189 FAIL=1   ps1 PASS=192 FAIL=1
Scripts reverted to Closed: sh  PASS=188 FAIL=2   ps1 PASS=191 FAIL=2
```
The single remaining failure in each suite is the pre-existing creator-inventory check (`unpack-projex.md` scaffolds but is missing from `tests/fixtures/projex-creators.txt`), unchanged by this patch. This patch document was itself scaffolded by the fixed `new-projex.sh` and came out with `> **Status:** Complete`.

**Status:** PASS

---

## Impact on Related Projex

| Document | Relationship | Update Made |
|----------|-------------|-------------|
| 2610012008-projex-tree-relative-repo-root-patch.md | Patch whose scaffolded `Closed` status was hand-corrected | None needed — already `Complete` |

---

## Notes

- The creator-inventory failure is present in both `tests/new-projex.test.sh` and `tests/new-projex.test.ps1` on `main`, not only the PowerShell suite.
- Existing docs carrying `Status: Closed` were not swept; only the scaffolders were in scope.
