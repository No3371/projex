# Patch: Generalize Projex Beyond Software Development

> **Status:** Complete
> **Date:** 2026-07-29
> **Author:** Claude (Opus 5)
> **Directive:** Execute 2607290443-generalize-beyond-software-plan.md as a patch (human chose patch over plan-execute-close)
> **Source Plan:** 2607290443-generalize-beyond-software-plan.md (all 6 steps — full execution)
> **Related Projex:** 2607290435-generalize-beyond-software-proposal.md
> **Result:** Success

---

## Summary

Additive generalization layer per accepted proposal Option A. SKILL.md gains `## Substrate` (4-guarantee contract, degradation table, No-VCS Mode, Field Mode, Irreversibility Discipline); scan/review/audit extend locators + evidence beyond code; 12 analytical specs each gain one non-dev invocation example; README gains "Not just for code". 15 files, +52/−3 — the 3 deletions are exactly the plan's declared before/after rewrites.

Patched rather than plan-executed at human direction: work fully specified by the plan (verbatim content blocks, exact anchors, per-step greps), mechanical, additive-only, immediately verifiable.

---

## Changes

### SKILL.md — `## Substrate` section

**File:** `SKILL.md`
**Change Type:** Modified (+31 lines, pure insertion)
**What Changed:**
- New `## Substrate` at line 207, immediately before `## Git Integration` (now 238)
- Four substrate guarantees: inspectable corpus | edit mechanism | checkpoint+rollback | provenance log
- Degradation table: git repo → full framework | files-no-git → analytical + revise/memo/define/nav | non-file → analytical + Field Mode
- `### No-VCS Mode` — skip repo resolution and commit/stage; naming/statuses/folder states unchanged; medium-appropriate locators
- `### Field Mode` — agent authors Plan → human executes → agent debriefs interview-style → Close records human-reported evidence
- `### Irreversibility Discipline` — Critical Git Rules restated substrate-neutrally

**Why:** Names git as reference substrate, not requirement. Degradation table prevents over-applying the full cycle to checkpoint-less substrates (proposal risk 2). Placed directly above Git Integration so "git = reference implementation" reads in sequence.

---

### scan-projex.md — non-code locators

**File:** `scan-projex.md`
**Change Type:** Modified (+5/−1)
**What Changed:**
- Format-adaptation table (:129-130) — 2 rows appended: `Document/manuscript content` → `doc § heading` or `page:para`; `Web/external sources` → `URL#anchor`
- Key characteristics (:11) — declared rewrite: "Precision matters" gains parenthetical `, or the medium-appropriate locator — see Format adaptation`
- INVOCATION examples (:45) — `/scan-projex Every unresolved citation across the manuscript`

**Why:** Spec already declared "Adaptive format"; rows make non-code concrete rather than implied.

---

### review-projex.md — non-code Accuracy clause + example

**File:** `review-projex.md`
**Change Type:** Modified (+3/−1)
**What Changed:**
- Check-matrix Accuracy row (:128) — declared rewrite: appended `Non-code sources: cites resolve, quoted claims match source?`; dev questions intact
- INVOCATION examples (:36) — `/review-projex @2607311430-course-outline-plan.md`

**Why:** Reviewed projex may themselves be non-dev; the example doubles as that reminder.

---

### audit-projex.md — non-code evidence

**File:** `audit-projex.md`
**Change Type:** Modified (+1/−1)
**What Changed:**
- "Evidence to inspect" (:44) — declared rewrite: appended `. Non-code work: deliverables, records, correspondence, published/filed artifacts`; existing enumeration intact

---

### 11 specs — one non-dev invocation example each

**Files:** `eval-projex.md` `redteam-projex.md` `propose-projex.md` `interview-projex.md` `define-projex.md` `navigate-projex.md` `guide-projex.md` `imagine-projex.md` `memo-projex.md` `explore-projex.md` `review-projex.md`
**Change Type:** Modified (+1 line each)
**What Changed:** One example appended per spec, matching that file's existing register, punctuation, and `.md`-suffix convention:

| Spec | Added example |
|------|---------------|
| eval | `/eval-projex Comparative vs longitudinal design for the thesis study` |
| redteam | `/redteam-projex.md The contingency plan for the outdoor launch event` |
| propose | `/propose-projex.md Restructure the onboarding curriculum around case studies` |
| interview | `/interview-projex book chapter outline and argument structure` |
| define | `/define-projex.md Our consulting engagement model` |
| navigate | `/navigate-projex.md Thesis completion roadmap` — project-level, lives in root `.projex/` |
| guide | `/guide-projex.md Get up to speed on GDPR obligations for the newsletter` |
| imagine | `/imagine-projex.md A field guide that adapts its depth to the reader's location and season` |
| memo | `/memo-projex User said "the intro chapter buries the thesis statement"` |
| explore | `/explore-projex.md How does the current grant application process work?` |
| review | `/review-projex @2607311430-course-outline-plan.md` |

**Why:** Examples are where agents pattern-match applicability (proposal change 5).

**Deviation:** Plan said "redteam has no Examples list — append to its invocation code block". `interview-projex.md` is also code-block-only (no bulleted Examples list); same treatment applied. Navigate's list carries a trailing scope annotation per line — matched it.

---

### README.md — "Not just for code"

**File:** `README.md`
**Change Type:** Modified (+4 lines, pure insertion)
**What Changed:** New `## Not just for code` between `## Why it works` and `## Workflows` — one paragraph, human-facing, points to `SKILL.md § Substrate` for scope rules.

---

## Verification

**Method:** Plan's Verification Plan — automated diff checks + per-step greps + manual read-back.

**Result:**

```
$ git diff --stat                          # 15 files, exactly the planned set
 README.md  | 4 ++++      SKILL.md   | 31 +++++      audit-projex.md   | 2 +-
 define     | 1 +         eval       | 1 +           explore           | 1 +
 guide      | 1 +         imagine    | 1 +           interview         | 1 +
 memo       | 1 +         navigate   | 1 +           propose           | 1 +
 redteam    | 1 +         review     | 3 ++-         scan              | 5 ++++-
 15 files changed, 52 insertions(+), 3 deletions(-)

$ git diff -U0 | grep '^-' | grep -v '^---'   # exactly the 3 declared rewrites
-Git commits, code files, tests (...), documentation (...), logs, metrics
-| **Accuracy** | File refs resolve? ... Facts current? |
-- **Precision matters** — every entry must be real and accurately located (`file:ln`)

$ per-step markers                          # 1 hit each
page:para(scan) 1 | URL#anchor(scan) 1 | unresolved citation 1
Non-code sources 1 | Non-code work 1 | Not just for code 1

$ 11 step-5 examples                        # 1 hit each — all 11 confirmed

$ grep -n "^## Substrate\|^## Git Integration" SKILL.md
207:## Substrate    238:## Git Integration     # Substrate precedes Git Integration

$ git diff | grep 'Status:\*\*'              # empty — no status blockquotes touched
$ git diff --name-only | grep -E 'execute|close|patch|simulate|debug|do-projex|verify|\.(sh|ps1)$|^tests/'
                                             # empty — execution family + scripts + tests byte-identical
```

Manual: SKILL.md read in place — Substrate flows from Auxiliary Commit Policy into Git Integration, no contradiction with either. Each of the 12 examples reads native in its list. README paragraph reads for a human.

**Status:** PASS — all 6 acceptance criteria met.

---

## Impact on Related Projex

| Document | Relationship | Update Made |
|----------|-------------|-------------|
| 2607290443-generalize-beyond-software-plan.md | Source plan — fully executed | Status → `Complete`; all 6 success criteria checked; `[PATCHED]` markers + Related Projex full-execution note; moved to `.projex/closed/` |
| 2607290435-generalize-beyond-software-proposal.md | Source proposal — `Complete (Accepted)` | Patch cross-referenced in Related Projex; moved to `.projex/closed/` |

No nav noted on either document — no nav updated.

---

## Notes

- **Worktree not used.** Plan set `> **Worktree:** Yes` for execute-projex; patch commits directly to the current branch by definition. Per-step rollback was `git checkout -- <file>` on `main` instead — never needed, no step failed.
- **Scope-guard note.** 15 files exceeds patch's usual 1–3 signal. Human explicitly chose patch knowing the file count; qualified on the substantive criteria — fully specified (verbatim blocks, exact anchors), no design decisions, additive-only, greppable verification. File count is a signal, not a rule (patch-projex § Scope Guard).
- **`new-projex.ps1` folder arg.** Passing `.projex/closed` yields `.projex/closed/closed/` — the script appends `closed/` for born-closed types. Correct arg is the projex root (`.projex`). Stray directory removed before rescaffolding.
- **Follow-up (from plan § Risks, unchanged):** deployed skill copy in the user's skills directory is out of scope and now diverges from repo `SKILL.md` — sync is a user-owned deployment step. Post-merge smoke check (run one dev-flavored analytical workflow to confirm no drift on dev tasks) remains open.
