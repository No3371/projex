# Patch: projex-tree Missing-Parent Root

> **Status:** Complete
> **Author:** Claude Opus 5.5 (patch-projex subagent)
> **Parent:** User
> **Related Projex:** 2610010506-projex-tree-native-port-plan.md (Behavior Contract origin of `E_PARENT_DANGLING`) | 2610010506-projex-tree-native-port-walkthrough.md (recorded the 2 real-doc exit-3 cases) | 2610012008-projex-tree-relative-repo-root-patch.md (prior patch, same scripts) | 2608120933-parent-lineage-header-and-projex-tree-utility-proposal.md (original "`[missing]` and fails" design, now superseded)
> **Directive:** "projex-tree exits 3 - that's an error? Projex tree should expect references could be missing" → "Two real docs point to Parent docs that don't exist anywhere: `2608121919-…-patch.md` and `2608130629-…-patch.md`, so `projex-tree` exits 3 on them."
> **Source Plan:** Direct
> **Result:** Success

---

## Summary

Dangling Parent no longer fails `projex-tree`. Contract (orchestrator decision, unobjected by human): Parent chain reaching a well-formed but undiscovered filename → that filename becomes tree root, printed `<filename> (missing)`; tree renders beneath as usual (other discovered docs naming same missing Parent = its children); exit 0, stderr empty. `E_PARENT_DANGLING` retired. `E_PARENT_MALFORMED` | `E_PARENT_SELF` | `E_CYCLE` | `E_PARENT_DUPLICATE` | `E_IDENTITY_DUPLICATE` unchanged.

Why: archive-projex and conclude-projex delete docs by design → dangling Parent = normal lifecycle, not corpus error. close-projex / conclude-projex consume tree as advisory context; hard failure only removed that context.

---

## Changes

### Engine — both ports

**Files:** `projex-tree.sh`, `projex-tree.ps1`
**Change Type:** Modified
**What Changed:**
- Header comment (sh:2-5, ps1:1-4): documents `(missing)` root rule.
- Chain walk (sh:150, ps1:158,170): undiscovered Parent → record `missing` / `$Missing`, break; no error.
- Tree build (sh:161-164, ps1:187-190): root = last chain doc; if missing set → add chain root as child of missing name, root = missing name, enqueue missing name first so BFS admits other docs naming it.
- Root print (sh:185, ps1:224): appends ` (missing)` when root is synthetic.

**Why:** Smallest change keeping existing member-set/tree invariant: synthetic root has no document, so it cannot be a member, cycle, or duplicate; BFS child admission and duplicate-Parent diagnostics apply to it unchanged. Output parity between ports preserved.

### Tests + fixture

**Files:** `tests/projex-tree.test.sh`, `tests/projex-tree.test.ps1`, `tests/fixtures/projex-tree/dangling-parent/` (Created: 4 docs, `expected.stdout`, `expected-stray.stdout`)
**Change Type:** Modified / Created
**What Changed:**
- Removed inline `E_PARENT_DANGLING` `run_error` / `RunError` case (4 checks each).
- Added `dangling-parent` fixture: `2609200000-orphan-plan.md` and `closed/2609200001-sibling-patch.md` → Parent `2609209999-gone-audit.md` (absent); `2609200002-orphan-log.md` → orphan plan; `2609200003-stray-patch.md` → different absent `2609209998-other-audit.md`.
- Added 3 `expect` / `Expect` cases (9 checks each): `dangling-chain` (grandchild target, multi-hop chain), `dangling-sibling` (sibling target, same tree), `dangling-other` (separate missing root excludes unrelated tree).

### Docs

**Files:** `README.md` (projex-tree row), `tests/README.md` (count 208 → 213, coverage note)
**Change Type:** Modified

---

## Verification

**Method:** Both suites before/after; real-corpus run on named docs (sh vs ps1 byte compare); sweep of every `.projex` doc in repo.

**Result:**
```
before: tests/projex-tree.test.sh  PASS=208 FAIL=0 | tests/projex-tree.test.ps1 PASS=208 FAIL=0
after:  tests/projex-tree.test.sh  PASS=213 FAIL=0 | tests/projex-tree.test.ps1 PASS=213 FAIL=0

$ projex-tree.sh . 2608121919-parent-lineage-audit-remediation-patch.md   # rc=0, ps1 byte-identical
2608121912-parent-lineage-and-projex-tree-addition-audit.md (missing)
└── 2608121919-parent-lineage-audit-remediation-patch.md

$ projex-tree.sh . 2608130629-new-projex-powershell-suite-exit-status-patch.md   # rc=0, ps1 byte-identical
2608130624-named-new-projex-parameter-migration-implementation-audit.md (missing)
└── 2608130629-new-projex-powershell-suite-exit-status-patch.md

corpus sweep: 130 docs, 6 nonzero — all deliberate error fixtures under tests/fixtures/projex-tree/ (header-quirks, error-order, basic/unrelated-malformed)
```

**Status:** PASS

---

## Impact on Related Projex

| Document | Relationship | Update Made |
|----------|-------------|-------------|
| 2608120933-parent-lineage-header-and-projex-tree-utility-proposal.md | Original design ("dangling prints `[missing]` and fails") | Related Projex entry noting supersession |
| 2610010506-projex-tree-native-port-plan.md | Behavior Contract source of `E_PARENT_DANGLING` | None — closed historical record |
| 2610010506-projex-tree-native-port-walkthrough.md | Recorded 2 real docs exiting 3 | None — closed historical record |

---

## Notes

- Real docs `2608121919-parent-lineage-audit-remediation-patch.md` and `2608130629-new-projex-powershell-suite-exit-status-patch.md` left unchanged: closed historical records; their Parents name audits that never landed in corpus, and `(missing)` root now states that fact accurately. Rewriting Parent to `User` would erase true causal lineage.
- Synthetic root never matches a discovered name by construction (`!(p in cnt)`), so collision with chain/member names impossible.
