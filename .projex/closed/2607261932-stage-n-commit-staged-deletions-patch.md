# Patch: stage-n-commit — Handle Already-Staged Deletions

> **Date:** 2026-07-26
> **Author:** Claude (Fable 5)
> **Directive:** "stage-n-commit should be able to handle deleted file, right?"
> **Source Plan:** Direct
> **Result:** Success

---

## Summary

Verified deletion handling in `stage-n-commit.{sh,ps1}`. Unstaged deletions (file removed from disk): worked already — `git add <path>` stages removal since git 2.0. **Pre-staged deletions** (path already `git rm`'d, e.g. by `del-n-stage` or archive-projex step 5b): fatal — path absent from worktree AND index, `git add` dies with `fatal: pathspec '<f>' did not match any files`, script rolls back and exits 1. Fixed: staging step now skips paths absent from both worktree and index (their change is already fully staged).

---

## Changes

### Staging-step filter

**File:** `stage-n-commit.sh`
**Change Type:** Modified
**What Changed:**
- Lines 90-106: before `git add`, build `ADD_FILES` excluding paths where `-e`/`-L` fails AND `git ls-files -- <f>` is empty. Skip `git add` entirely when list empty.

**File:** `stage-n-commit.ps1`
**Change Type:** Modified
**What Changed:**
- Lines 96-115: same filter — `Test-Path -LiteralPath` OR `git ls-files -- $f` non-empty → include; else skip.

**Why:**
`git rm`'d path matches nothing for `git add` (gone from worktree + index) → fatal. Deletion already staged — nothing to add. Filter also covers old paths of staged renames. Validation gate unchanged: `git status --porcelain -- <f>` still shows staged deletions, so such files pass intake and land in the commit.

### Stale doc note

**File:** `archive-projex.md`
**Change Type:** Modified
**What Changed:**
- Step 5b Note: claimed `git add` on `git rm`'d files "is a no-op" — was actually fatal pre-patch. Reworded to describe the skip behavior.

---

## Verification

**Method:** Throwaway repos in scratchpad, both variants, 4 cases each: unstaged deletion | pre-staged (`git rm`) deletion | mixed (del + rm + modify, one call) | plain modification (regression).

**Result:**
```
# pre-patch (both variants):
fatal: pathspec 'g.txt' did not match any files
Error: git add failed — index rolled back        # exit 1, rollback correct

# post-patch .sh:
Committed: mixed: del a, rm b, mod c (7b62505)   # a.txt -, b.txt -, c.txt +-
Committed: plain mod d (fa616ec)                 # status clean after

# post-patch .ps1:
Committed: mixed: del a, rm b, mod c (cf14471)
Committed: plain mod d (1e88af3)                 # status clean after
```

Fix commit `b7256be` itself made with the patched script — live self-verification. `tests/` suites not run: no coverage of stage-n-commit (grep confirmed), close scripts untouched.

**Status:** PASS

---

## Impact on Related Projex

| Document | Relationship | Update Made |
|----------|-------------|-------------|
| `archive-projex.md` | Workflow spec relying on `git rm` → `stage-n-commit` chain | Step 5b Note corrected to match actual (fixed) behavior |

---

## Notes

- Answer to directive: unstaged deletions — always yes; pre-staged (`git rm`/`del-n-stage`) — no before this patch, yes now.
- archive-projex step 5b was broken end-to-end pre-patch: every `git rm` + `stage-n-commit` removal commit would have failed.
- Rollback path behaved correctly in the failing case — index restored, exit 1. Failure was loud, not corrupting.
