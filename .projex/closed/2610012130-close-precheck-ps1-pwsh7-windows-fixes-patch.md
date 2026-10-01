# Patch: close-precheck PowerShell port under pwsh 7 on Windows

> **Status:** Complete
> **Author:** Claude Opus 5.5 (patch subagent)
> **Parent:** User
> **Directive:** Make `tests/close-precheck.test.ps1` pass on `main` (pre-existing failure making `run-all.ps1` exit nonzero) by fixing the real cause.
> **Source Plan:** Direct
> **Result:** Success
> **Related Projex:** 2610012130-new-projex-creator-inventory-fixture-patch.md

---

## Summary

`close-precheck.test.ps1`: `PASS=17 FAIL=19`. Every successful-path fixture got `RESULT=ERROR`. Peeled five stacked defects one at a time (each masked the next): four in `close-precheck.ps1`, one in the test. Script never ran end-to-end on pwsh 7 / Windows since `d113f45`. No behavior/contract change — ps1 now matches sh semantics.

---

## Changes

### close-precheck.ps1

**File:** `close-precheck.ps1`
**Change Type:** Modified
**What Changed:**
1. Lines 210-211, 222: `Split-Path -LiteralPath $p -Parent|-Leaf` → `[IO.Path]::GetDirectoryName` / `GetFileName`. PS 7.6 rejects the combo: `Parameter set cannot be resolved using the specified named parameters.` — first error on every run.
2. Line 71 (`Canonical-Path`): `Get-Item` gains `-Force`. `--git-common-dir` resolves to `.git`, which Git for Windows marks hidden; `Get-Item` without `-Force` → `Could not find item ...\repo\.git.`
3. Lines 60-68 new `Scan-Relative`; used at line 173 (`Add-Inventory-Candidates`) and line 202 (no-arg inference). `/.git/` and `/.projexwt/` exclusions were regex-matched against the absolute path; when scan root is the child worktree (`<repo>/.projexwt/child`) every file was dropped → no `CHILD` records, no inference candidates. Now matched below scan root — same as sh `find -prune`.
4. Line 199: `$currentBranch.Substring(6)` → `Substring(7)` (`'projex/'` is 7 chars; left a leading `/` so the `^\d{10}-` strip never matched). Lines 201/206/207: `$matches` → `$candidates` — PS vars are case-insensitive, so `$matches` aliased automatic `$Matches` used inside the same `Where-Object` filter.

**Why:** ps1 port could not produce a report on Windows; sh twin semantics were the reference.

### close-precheck.test.ps1

**File:** `tests/close-precheck.test.ps1`
**Change Type:** Modified
**What Changed:**
- Line 162: `Add-Content ... '> **Base Branch:** refs/remotes/origin/main'` → replace `> **Base Branch:** main` value with `refs/remotes/origin/main`.

**Why:** `Write-Fixture` here-string has no trailing newline and `Add-Content` adds no leading separator → header glued onto last body line, never parsed → precheck passed (`got=0 want=1`). Substitution exercises the actual `refs/` rejection (`invalid Base Branch header`) rather than a duplicate-header path.

### Test README

**File:** `tests/README.md`
**Change Type:** Modified
**What Changed:**
- `close-precheck.test.ps1` assertions `14` → `36`

---

## Verification

**Method:** Per-defect repro fixture with `ScriptStackTrace` debug copy (temp, deleted); suite reruns after each fix; both runners at end.

**Result:**
```
before:            close-precheck.test.ps1 PASS=17 FAIL=19
after fix 1+2:     PASS=29 FAIL=7
after fix 3:       PASS=33 FAIL=3
after fix 4:       PASS=35 FAIL=1
after test fix:    PASS=36 FAIL=0

run-all.ps1 (exit 0):
  new-projex 193/0 | projex-tree 208/0 | projex-list 33/0 | resolve-conflicts 33/0
  worktree 39/0 | dirty-base 139/0 | close-precheck 36/0
  total: PASS=681 FAIL=0

run-all.sh (exit 1, Git Bash on Windows):
  new-projex 190/0 | projex-tree 208/0 | projex-list 34/0 | resolve-conflicts 30/0
  resume 52/0 | worktree 34/0 | dirty-base 139/0
  close-precheck.test.sh: no summary (suite aborts) — see Notes
  total: PASS=687 FAIL=0
```

**Status:** PASS (scope: ps1 suite + `run-all.ps1`)

---

## Impact on Related Projex

| Document | Relationship | Update Made |
|----------|-------------|-------------|
| 2610012130-new-projex-creator-inventory-fixture-patch.md | Sibling patch, same directive | none |

---

## Notes

- Code commit: `4c9a9e3` (`Projex: 2610012130-close-precheck-ps1-pwsh7-windows-fixes`).
- **Out of scope, unresolved:** `close-precheck.test.sh` fails under Git Bash on Windows (pre-existing, unchanged; `run-all.sh` exits 1). Causes seen: (a) Git for Windows prints `C:/...` from `rev-parse --git-common-dir`; `git_common_dir`'s `/*` case treats it as relative → `cannot resolve plan repository identity`; tests also expect POSIX `REPO_ROOT=%2F...`. (b) symlink fixtures: `ln: failed to create symbolic link ... Too many levels of symbolic links` aborts the suite before its summary. Design question (normalize Windows paths via `cygpath`? skip symlink cases on MSYS?) → not patched; needs plan/decision. On Linux the sh suite is presumably unaffected — not verified here.
- sh `remote base branch fails` case appends a second `Base Branch` header → fails on duplicate header, not on remote-ref rejection. Passes, but tests a different rule than its name; left unchanged.
