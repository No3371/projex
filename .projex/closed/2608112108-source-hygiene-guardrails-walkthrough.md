# Walkthrough: Source Hygiene Guardrails — Rules, Commit Composition, Audit Pass

> **Status:** Complete
> **Execution Date:** 2026-08-11
> **Completed By:** sonic execution, audit, consistency-patch, and close workflow
> **Source Plan:** 2608052327-source-hygiene-guardrails-plan.md
> **Execution Log:** 2608052327-source-hygiene-guardrails-log.md
> **Duration:** 32 minutes execution (20:38–21:10 UTC) + audit/patch/close
> **Result:** Success

---

## Summary

Added source-comment hygiene rules, durable commit-to-projex traceability guidance, matching workflow templates, and the audit enforcement pass across eight root Markdown specs. The independent audit found two documentation-consistency defects; `2608112102-source-hygiene-guardrails-consistency-patch.md` corrected both without rewriting execution history. This close uses a trailer-bearing `docs(framework)` squash landing, so the surviving base commit carries the required `Projex:` link.

---

## Objectives Completion

| Objective | Status | Notes |
|---|---|---|
| 1. Add canonical Source Hygiene rules | Complete | `SKILL.md:215-229`; six rules, definitions, promotion clause, no caps. |
| 2. Define commit composition | Complete | `execute-projex.md:191-195,279-305`; trailer boundary, classes, types, resolution, survival condition. |
| 3. Inline rules in do-projex | Complete | `do-projex.md:76,93-96,163-178`; trailer template and verbatim rules. |
| 4. Compose close landing messages | Complete | `close-projex.md:278-280,469-536`; Bash/PowerShell multiline forms, doc-only carve-out, rebase note. |
| 5. Update patch/revise convention | Complete | `patch-projex.md:102-107,241-244,278,297`; `revise-projex.md:171`. |
| 6. Update debug convention | Complete | `debug-projex.md:349,492-494`; surviving fix and squash templates carry trailers. |
| 7. Add audit Source Hygiene Pass | Complete | `audit-projex.md:63-108,211-233,340-350`; pass is step 4 and later steps are 5–9. |

---

## Execution Detail

### Step 1: Source Hygiene policy

**Planned:** Add one canonical `SKILL.md` section with six source-comment rules.

**Actual:** Added `SKILL.md:215-229`: source/comment boundary; prohibition on projex references and line-number anchors in source comments; present-tense/rationale/plan-shape rules; promotion of load-bearing rationale; no density or length caps.

**Deviation:** None.

**Verification:** Targeted heading/rule search and `git diff --check` passed; `do-projex.md` later compared verbatim against the rule payload.

### Step 2: Commit composition convention

**Planned:** Add step-commit trailer and replace the prefix-only convention.

**Actual:** `execute-projex.md:191-195` adds the source-touching step trailer and doc-only exception. `:279-305` adds commit classes, boundary rule across any `.projex/`, conventional-type selection, trailer syntax/resolution, GitHub survival condition, and rationale.

**Deviation:** None.

**Verification:** Targeted template/convention searches and `git diff --check` passed.

### Step 3: do-projex propagation

**Planned:** Mirror the source-touching trailer and inline the six rules for caller-supplied sub-workflow context.

**Actual:** `do-projex.md:76,93-96,163-178` adds the local rule reference, trailer template, log-only exception, and deliberate verbatim policy copy.

**Deviation:** None.

**Verification:** Targeted searches found one policy heading, six rules, no-caps text, and the log-only exception; payload comparison to `SKILL.md` passed.

### Step 4: Close-message forms

**Planned:** Make source-touching squash/merge landing messages typed and trailer-bearing while preserving doc-only behavior.

**Actual:** `close-projex.md:278-280,469-536` adds the rationale-promotion prompt, conventional-type guidance, multiline Bash checkout/worktree forms, PowerShell here-string form, doc-only carve-out, and rebase-trailer note.

**Deviation:** None.

**Verification:** A throwaway Git commit parsed a multiline subject/trailer as `test(scope): trailer smoke test|2608052327-source-hygiene-guardrails`; it was removed before execution completion. `git diff --check` passed.

### Step 5: Patch and revise templates

**Planned:** Convert source-changing patch templates to typed subjects plus trailers; remove stale source-prefix claims.

**Actual:** `patch-projex.md:102-107,241-244,278,297` updates code templates/checklist/notes and keeps doc-only patch commits in the `projex(patch)` family. `revise-projex.md:171` limits its prefix statement to document operations.

**Deviation:** None.

**Verification:** Targeted searches found two patch trailer templates and no stale bare code-prefix assertion; `git diff --check` passed.

### Step 6: Debug templates

**Planned:** Add trailers to the surviving debug fix and squash landing forms.

**Actual:** `debug-projex.md:349,492-494` adds trailer forms without changing attempt, repro, or document-only behavior.

**Deviation:** None.

**Verification:** Two debug trailer occurrences found; obsolete landing-subject suffix absent; `git diff --check` passed.

### Step 7: Audit enforcement pass

**Planned:** Insert Source Hygiene Pass between inspection and quality assessment, then add report and validation support.

**Actual:** `audit-projex.md:63-108` defines pass 4 with diff-only scope, nested `.projex/` exclusion, closed-squash fallback, opt-in retrofit, four hygiene directions, symbol locations, and trailer-survival sampling. `:211-233,340-350` adds report fields/validation and maintains contiguous steps 1–9.

**Deviation:** None.

**Verification:** Heading search found contiguous 1–9 numbering with pass 4; targeted searches found all four directions, glob exclusions, survival sample, report section, and validation item. `git diff --check` passed.

### Post-execution consistency patch

**Planned:** Not a plan step; audit-supported bounded patch before close.

**Actual:** `93a598b` corrected the audit pass so permitted ephemeral `projex: step …` / `projex(do): …` subjects are exempt from type checks but still require trailers. It also corrected the plan/log trailer-form evidence to five workflow specs, intentionally excluding `SKILL.md`; `2608112102-source-hygiene-guardrails-consistency-patch.md` records the patch.

**Deviation:** Intentional post-execution repair recommended by the independent audit.

**Verification:** Patch record reports `git diff --check` pass, exact five-file search, retained trailer boundary, no scripts/tests/historical-commit rewrites.

---

## Complete Change Log

> **Derived from:** `git diff --stat main..4ecfbf5` before this close commit. Execution diff: 11 files, 334 insertions, 25 deletions.

### Files Created

| File | Purpose | In Plan? |
|---|---|---|
| `.projex/2608052327-source-hygiene-guardrails-log.md` | Step-by-step execution evidence and terminal status. | Yes |
| `.projex/closed/2608112102-source-hygiene-guardrails-consistency-patch.md` | Bounded post-audit documentation correction. | No — audit-supported follow-up |

### Files Modified

| File | Changes | In Plan? |
|---|---|---|
| `SKILL.md` | Canonical six-rule Source Hygiene section. | Yes |
| `execute-projex.md` | Step trailer and canonical commit-composition convention. | Yes |
| `do-projex.md` | Trailer template, doc-only exception, local policy copy. | Yes |
| `close-projex.md` | Typed multiline landing messages and rationale-promotion prompt. | Yes |
| `patch-projex.md` | Typed/trailer code templates, checklist, corrected note. | Yes |
| `revise-projex.md` | Corrected document-only prefix note. | Yes |
| `debug-projex.md` | Fix/squash trailer forms. | Yes |
| `audit-projex.md` | Source Hygiene Pass, report template, validation, renumbering; consistency patch clarifies step-subject exception. | Yes |
| `.projex/2608052327-source-hygiene-guardrails-plan.md` | Terminal status/log and patch linkage; close adds completion/walkthrough fields. | Lifecycle |

### Files Deleted

None.

### Planned But Not Changed

None. Scripts, tests, `README.md`, `USAGE.md`, `AGENTS.md`, `review-projex.md`, historic comment/history retrofits, and hygiene-lint remained out of scope.

---

## Success Criteria Verification

| Criterion | Method | Result | Evidence |
|---|---|---|---|
| Canonical six-rule Source Hygiene policy | Targeted section/rule search | Pass | `SKILL.md:215-229`; execution log Step 1. |
| Commit table, types, trailer mechanics, close forms | Targeted template/convention search; multiline Git smoke test | Pass | `execute-projex.md:191-195,279-305`; `close-projex.md:469-536`; log Steps 2/4. |
| Boundary rule and doc-only carve-out | Cross-spec targeted inspection | Pass | Canonical rule in `execute-projex.md`; matching close forms. |
| All execution/patch/debug source templates match | Targeted template search | Pass | `execute`, `do`, `close`, `patch`, `debug` changed forms. |
| do-projex policy is verbatim | Programmatic payload comparison | Pass | Execution log Step 3. |
| Patch/revise no stale source-prefix claim | Targeted stale-prefix search | Pass | Execution log Step 5. |
| Audit pass occupies step 4 with contiguous numbering | Heading search | Pass | `audit-projex.md:63-108,340-350`. |
| Audit scope/directions/location requirements | Targeted pass inspection | Pass | Diff-only/glob exclusion, fallback, retrofit, four directions, symbols. |
| Nested `.projex/` exclusion and survival sample | Targeted pathspec/commit-check search | Pass | `:(exclude,glob)**/.projex/**` and trailer sample in pass. |
| Audit report Source Hygiene section | Template inspection | Pass | `audit-projex.md:211-233`. |
| Prefix searches contain only allowed forms | Targeted root-spec searches | Pass | Execution log final verification. |
| No bare source-commit convention remains | Targeted root-spec search | Pass | Execution log final verification. |

**Overall:** 12/12 plan criteria passed after the consistency patch. No broad test suite or formatter applied: scope is Markdown specifications only.

---

## Deviations and Issues

### Audit findings corrected before close

- **Finding:** Audit wording would type-check permitted ephemeral step subjects; plan trailer-form expectation incorrectly included `SKILL.md`.
- **Resolution:** `93a598b`/`2608112102-source-hygiene-guardrails-consistency-patch.md` corrected both. Existing seven step commits remain untrailed by design of the no-history-rewrite policy.
- **Impact:** Squash close is required for a single correct base landing; merge/rebase would preserve the historical trailer gap.

### Close metadata normalization

- **Finding:** Execution log originally recorded the child worktree as both Repo Root and Worktree Path, causing `close-precheck.sh` to reject the tuple.
- **Resolution:** Close corrected `Repo Root` to `/workspace`; Worktree Path remains the child path.
- **Impact:** `close-precheck.sh` resolved `main`, branch, base SHA, child worktree, and no stash; only then-pending lifecycle edits were warned.

### Script invocation

- **Finding:** Utility scripts use CRLF shebangs in this environment.
- **Resolution:** Invoked through Bash with CRLF removed in-process; scripts themselves were not modified.
- **Impact:** No source or test surface change.

---

## Key Insights

- **Rule and traceability are coupled:** Removing projex references from source comments needs a trailer-bearing landing commit or traceability is lost.
- **Close mode matters:** A correct squash landing repairs branch-level trailer history without rewriting individual execution commits; merge/rebase would not.
- **Policy duplication is deliberate:** `do-projex.md` keeps a verbatim local policy copy to survive sub-workflow context boundaries; future changes must update both copies.
- **Audit scope must use nested exclusion:** `:(exclude,glob)**/.projex/**` prevents point-in-time projex records from being inspected as source comments.

---

## Related Projex Updates

| Document | Action |
|---|---|
| `2608052327-source-hygiene-guardrails-plan.md` | Status retained Complete; completion, log, and walkthrough linkage recorded; moved closed. |
| `2608052327-source-hygiene-guardrails-log.md` | Terminal status verified; moved closed. |
| `2608052346-source-hygiene-guardrails-plan-redteam.md` | Findings were dispositioned and resolved by the plan; moved closed. |
| `2608111922-source-hygiene-guardrails-plan-review.md` | Required revisions were applied; moved closed. |
| `2608112102-source-hygiene-guardrails-consistency-patch.md` | Born closed; remains closed. |
| `2608112054-source-hygiene-guardrails-audit.md` | Preserved uncommitted and active under auxiliary-artifact policy; not moved or staged. |
| `2608051553-source-hygiene-guardrails-proposal.md` | Origin-worktree untracked auxiliary artifact; untouched. |

No Nav is referenced by the plan. No new follow-up projex is created here.

---

## Appendix

### Execution commits before close

```text
9959014 projex: step 1 - add source hygiene rules
8bb5c52 projex: step 2 - define commit composition
4feafde projex: step 3 - inline source hygiene in do workflow
d0dcc47 projex: step 4 - compose close landing messages
eda34fe projex: step 5 - update patch commit convention
9286fc4 projex: step 6 - add debug commit trailers
2013f91 projex: step 7 - add audit source hygiene pass
ccc0ab2 projex: complete source-hygiene-guardrails
93a598b docs(framework): clarify source hygiene commit checks
4ecfbf5 projex(patch): add patch doc - source-hygiene-guardrails-consistency
```

### Verification evidence

```text
Execution: git diff --check passed per every step and final verification.
Execution: SKILL.md and do-projex.md rule payload comparison passed.
Execution: audit headings contiguous 1–9; Source Hygiene Pass is step 4.
Execution: multiline Git trailer smoke test parsed subject and Projex trailer, then throwaway commit removed.
Patch: git diff --check passed; exact trailer-form scope is five workflow specs, SKILL.md intentionally absent.
Close precheck: base main, ephemeral projex/2608052327-source-hygiene-guardrails, base e1f0825, tip 4ecfbf5, no stash; origin tracked gate passed.
```
