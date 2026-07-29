# Patch: Drop Derivable Date Header

> **Status:** Complete
> **Author:** agent (Claude, opus)
> **Directive:** "I'm thinking about dropping the Date header in projex docs." → `patch-projex`
> **Source Plan:** Direct
> **Result:** Success

---

## Summary

Removed the bare `Created:` / `Date:` header field from 15 workflow templates and both `new-projex` scaffolders. The field restated the `{yymmddhhmm}` filename prefix — pure redundancy, and an active drift source. Date fields carrying non-derivable information (`Last Revised`, `Work Period`, `Execution Date`, `Started`, `Completed`, revision histories) were left untouched.

---

## Rationale

Three grounds, in order of weight:

1. **Nothing consumes it.** `archive-projex.md:62` already builds its index by decoding the filename prefix and marks Date `— (always derivable)`. `review-projex.md:98` likewise records "created date (from filename prefix)". No script parses `**Created:**` — verified by grep across `*.sh` / `*.ps1`: the only two hits were the scaffolders' own writes.
2. **It caused drift.** `2607111806-agents-still-mint-date-prefix-explore.md:67` names this exact field: *"Templates everywhere: `> **Created:** YYYY-MM-DD` — looks unfilled even when script filled it; agents who skip/recreate template re-resolve date."* Line 111 records the placeholder being read as "fill me" rather than "already decided by script". A re-minted date can disagree with the prefix; a wrong date is worse than an absent one.
3. **Dehydrate.** SKILL.md § Dehydrate strips content recoverable from context. A field mechanically decodable from the filename is filler.

**Cost accepted:** `2607291433` is less legible to a human than `2026-07-29`. Judged acceptable — decoding is trivial, and the archive index (the surface actually read for dates) still spells dates out.

---

## Changes

### Scaffolders

**Files:** `new-projex.sh`, `new-projex.ps1`
**Change Type:** Modified
**What Changed:**
- Dropped the `> **Created:** ${today}` / `$Today` line from the emitted header block
- Dropped the now-unused `today=$(date +%Y-%m-%d)` (sh:78) and `$Today = Get-Date -Format "yyyy-MM-dd"` (ps1:76)
- `stamp` / `$Stamp` (the `yyMMddHHmm` filename prefix) is untouched — it remains the sole date carrier

**Why:** The scaffolders were the mechanism that filled the redundant field. Leaving them would keep minting it into every new document.

### Templates — bare derivable field removed

**Change Type:** Modified · 15 files

| File | Line was | Removed | Left in place |
|---|---|---|---|
| `propose-projex.md` | 66 | `> **Created:** YYYY-MM-DD` | — |
| `plan-projex.md` | 92 | `> **Created:** YYYY-MM-DD` | — |
| `imagine-projex.md` | 128 | `> **Created:** YYYY-MM-DD` | — |
| `guide-projex.md` | 102 | `**Created:** YYYY-MM-DD \|` | `**Author:**` |
| `explore-projex.md` | 86 | `**Created:** YYYY-MM-DD \|` | `**Author:**` |
| `review-projex.md` | 183 | `**Created:** YYYY-MM-DD \|` | `**Reviewer:**` |
| `redteam-projex.md` | 138 | `**Created:** YYYY-MM-DD \|` | `**Lead:**` |
| `interview-projex.md` | 61 | `**Date:** YYYY-MM-DD \|` | `**Scope:**` |
| `memo-projex.md` | 69 | `> **Date:** YYYY-MM-DD` | — |
| `scan-projex.md` | 86 | `> **Date:** YYYY-MM-DD` | — |
| `patch-projex.md` | 122 | `> **Date:** YYYY-MM-DD` | — |
| `simulate-projex.md` | 171 | `> **Date:** YYYY-MM-DD` | — |
| `archive-projex.md` | 114 | `> **Created:** YYYY-MM-DD` | — |
| `debug-projex.md` | 374 | `> **Date:** YYYY-MM-DD` | — |
| `eval-projex.md` | 149 | `Created, ` (frontmatter field list) | rest of list |

`debug-projex` and `eval-projex` were not in the original 13 surfaced to the user — both were found during execution to carry the same derivable field (debug's born-closed *document* header, distinct from its log's `Started:`; eval's field list is prose rather than a template line, so it missed the first grep). Same population, included for consistency.

### Deliberately not changed

| File:line | Field | Why kept |
|---|---|---|
| `define-projex.md:85`, `navigate-projex.md:89` | `Created \| Last Revised` | `Last Revised` is not derivable. See Notes — the `Created` half is a follow-up |
| `define-projex.md:174`, `navigate-projex.md:175`, `revise-projex.md:90` | Revision-log dates | Multiple dates per doc; none is the creation date |
| `navigate-projex.md:105` | `As of YYYY-MM-DD` | Snapshot date of a living doc, re-stamped each revision |
| `audit-projex.md:90` | `Audit Date \| Work Period` | `Work Period` is a span the filename cannot encode |
| `close-projex.md:135` | `Execution Date` | Observed as a range in practice (`2605051200-dehydrate-plan-projex-walkthrough.md:3` records `2026-05-05 → 2026-05-07`) |
| `close-projex.md:366` | `Completed` | Differs from walkthrough creation |
| `debug-projex.md:148`, `execute-projex.md:326` | `Started: … HH:MM` | Minute precision on a live log |
| `review-projex.md:267` | `Reviewed: YYYY-MM-DD` | Stamped into the *reviewed* doc; its prefix is a different date |
| `archive-projex.md:62`, `:91`, `:133` | Index-entry `Date` | The archive removes the originals and is the search surface — a spelled-out date is a grep handle the prefix is not |

---

## Verification

**Method:** grep sweep for surviving date headers across `*-projex.md`; live run of both scaffolders into throwaway directories.

**Result:**

```
$ grep -nE '^> \*\*(Created|Date|Audit Date|Execution Date|Started|Last Revised|Completed):' *-projex.md
define-projex.md:85:   > **Created:** YYYY-MM-DD | **Last Revised:** YYYY-MM-DD
debug-projex.md:148:   > **Started:** YYYY-MM-DD HH:MM
audit-projex.md:90:    > **Audit Date:** YYYY-MM-DD | **Auditor:** [name] | **Work Period:** [timeframe]
close-projex.md:135:   > **Execution Date:** YYYY-MM-DD
close-projex.md:366:   > **Completed:** YYYY-MM-DD
execute-projex.md:326: > **Started:** [yyyymmdd hh:mm]
navigate-projex.md:89: > **Created:** YYYY-MM-DD | **Last Revised:** YYYY-MM-DD
```

Exactly the intended keep-set survives; every bare derivable field is gone.

Scaffolder output, both variants (`new-projex.sh` → `plan`, `new-projex.ps1` → `memo`):

```
# date header test

> **Status:** Draft
> **Author:** [name or agent]
> **Related Projex:** [none yet]

---
```

Filename prefix still minted correctly in both (`2607291432-date-header-test-plan.md`, `2607291432-date-header-test-memo.md`). Born-closed routing, slugify, and the `# next` / `# commit` hint lines all unaffected.

**Not run:** `tests/run-all.{sh,ps1}` — they cover `projex-{squash,merge,rebase}-close` only, none of which this patch touches. `new-projex` has no test coverage; verification was the live runs above.

**Status:** PASS

---

## Impact on Related Projex

| Document | Relationship | Update Made |
|---|---|---|
| `2607111806-agents-still-mint-date-prefix-explore.md` | Diagnosed this field as a drift source (lines 67, 111, 122) | None — exploration is still open on the broader date-minting problem, of which this patch closes one item. Left active |

---

## Notes

- **Follow-up — uniform application.** `define-projex.md:85` and `navigate-projex.md:89` still carry `Created:` beside `Last Revised:`. The `Created` half is as derivable as the ones dropped here; only `Last Revised` justifies the line. Left deliberately because both were presented to the user in the keep-column — worth a one-line revision to `> **Last Revised:** YYYY-MM-DD` if the principle is to apply uniformly.
- **Found in passing, out of scope.** `new-projex.{sh,ps1}` stamp `> **Status:** Closed` for born-closed types. `Closed` is not in SKILL.md § Lifecycle Status canonical vocabulary (`Draft | Ready | In Progress | Blocked | Escalated | Complete | Abandoned`) and does not parse as an outcome qualifier. This document was scaffolded with it and hand-corrected to `Complete`. Unrelated to the date change; not fixed here.
- Existing projex documents keep their `Created:` / `Date:` lines. No backfill or strip pass was run — they are historical records, and the field is harmless where already filled. Only newly scaffolded documents change.
- Commit `8635eae` carries the code change; this document lands separately per the patch two-commit convention.
