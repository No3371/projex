# Patch: new-projex rejects an absolute projex dir

> **Status:** Complete
> **Author:** Opus 5.5 (patch subagent)
> **Parent:** 2610010531-new-projex-absolute-projex-dir-joined-to-repo-root-memo.md
> **Related Projex:** 2610010531-new-projex-absolute-projex-dir-joined-to-repo-root-memo.md
> **Directive:** `patch<opus>` — reject an absolute `--projex-dir` (exit 2, clear error) in `new-projex.sh` and `new-projex.ps1`; add one SKILL.md § No-VCS Mode line defining `--repo-root` without git.
> **Source Plan:** Direct
> **Result:** Success

---

## Summary

`new-projex` stripped leading slashes from the projex dir and joined it onto the repo root, so `--projex-dir /s/Repos/projex/.projex` silently wrote to `<repo>/s/Repos/projex/.projex/` with exit 0. Every workflow spec already passes `--repo-root`, so a repo-relative projex dir is always expressible; absolute values are now rejected before any write. SKILL.md § No-VCS Mode now states what `<repo-root>` means when there is no git repo.

---

## Changes

### Scaffold scripts

**File:** `new-projex.sh`
**Change Type:** Modified
**What Changed:**
- Header usage comment: `<projex-dir>` relative to repo-root, absolute rejected (line 7).
- New `case` guard before normalization (lines 72-75): `/*`, `\*`, `[A-Za-z]:*` → `Absolute projex-dir not supported: <value> (pass a path relative to repo-root, e.g. .projex)`, exit 2.
- Normalization no longer strips leading slashes (now unreachable); comment updated (lines 77-79).

**File:** `new-projex.ps1`
**Change Type:** Modified
**What Changed:**
- Header usage comment updated (line 4).
- Guard `^([/\\]|[A-Za-z]:)` → same message via `Fail`, exit 2 (lines 60-61), placed before normalization.
- `.Trim('/')` → `.TrimEnd('/')` (line 65).

**Why:** The check must run on the raw value — normalization erased the leading slash that marks a path absolute. Drive-relative `C:x` is rejected too; it cannot be joined meaningfully onto a repo root.

### Tests

**Files:** `tests/new-projex.test.sh`, `tests/new-projex.test.ps1`
**Change Type:** Modified
**What Changed:**
- `assert_absolute_reject` / `AssertAbsoluteReject`: per case asserts exit 2, stderr names the value, empty stdout, unchanged full filesystem snapshot of the fixture repo.
- Cases: POSIX (`$repo/.projex` in sh; `/abs/.projex` in ps1), native Windows absolute (`Join-Path $Repo .projex`, ps1 only), root-backslash `\abs\.projex`, UNC `\\host\share\.projex`, `C:\abs\.projex`, `C:/abs/.projex`, drive-relative `c:abs`.

### Docs

- `README.md` — new-projex parameter paragraph states the projex directory is repo-root-relative and absolute values exit 2.
- `tests/README.md` — counts 190/193 → 214/221; scope lists absolute projex-dir rejection.
- `SKILL.md` § No-VCS Mode — added: `- **`<repo-root>` without git** — the folder that contains `.projex/`; `new-projex --projex-dir` stays relative to it.`

---

## Verification

**Method:** Both suites before and after; checked no stray `s/` or `C:` directory at repo root.

**Result:**
```
before: tests/new-projex.test.sh  PASS=190 FAIL=0
        tests/new-projex.test.ps1 PASS=193 FAIL=0
after:  tests/new-projex.test.sh  PASS=214 FAIL=0
        tests/new-projex.test.ps1 PASS=221 FAIL=0
```

**Status:** PASS

---

## Impact on Related Projex

| Document | Relationship | Update Made |
|----------|-------------|-------------|
| 2610010531-new-projex-absolute-projex-dir-joined-to-repo-root-memo.md | Parent memo (issue) | Consumed: Status `Complete (Resolved)`, moved to `.projex/closed/` |

---

## Notes

- Code commit trailer order is `Co-Authored-By` then `Projex:` (stage-n-commit appends `--trailer` after the message body); amend was blocked by the git safety hook, so it stays as committed. `git log --grep 'Projex: '` still finds it.
- `..` segments escaping the repo root are not checked; out of this patch's scope.
