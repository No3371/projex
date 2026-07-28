# Plan: Generalize Projex Beyond Software Development

> **Status:** Complete
> **Created:** 2026-07-29
> **Author:** Claude (Fable 5)
> **Source:** 2607290435-generalize-beyond-software-proposal.md
> **Related Projex:** 2607290435-generalize-beyond-software-proposal.md | 2607290457-generalize-beyond-software-patch.md
> **Worktree:** Yes (not used — executed as patch on `main`)

> **Full Execution:** All 6 steps `[PATCHED]` 2026-07-29 via 2607290457-generalize-beyond-software-patch.md — commit `a91b9c8`. Nothing left open.

---

## Summary

Implement proposal Option A: additive generalization layer. SKILL.md gains a `## Substrate` section (contract + no-VCS mode + field mode + irreversibility principle); scan/review/audit get non-code locator/evidence clauses; 12 analytical specs get one non-dev invocation example each; README gets a short "Not just for code" section. All edits additive — no dev instruction reworded, no script/test/execution-family changes.

**Scope:** Repo-root markdown specs + README only, single `.projex` scope.
**Estimated Changes:** 15 files, ~70 added lines total, 3 lines reworded via declared before/after.

---

## Objective

### Problem / Gap / Need

Framework methods are domain-general but specs signal dev-only: all examples are code, locators hardcode `file:ln`, no stated behavior for non-git or non-file substrates. Per accepted proposal: admit generality in SKILL.md, seed examples, keep specs concrete.

### Success Criteria

- [x] SKILL.md `## Substrate` section exists: 4-guarantee contract, degradation table, No-VCS mode, Field Mode, substrate-neutral irreversibility principle
- [x] scan-projex format table covers non-code locators; review-projex Accuracy check and audit-projex evidence list cover non-code sources
- [x] 12 analytical specs each carry ≥1 non-dev invocation example (11 in step 5 + scan in step 2)
- [x] README has a "Not just for code" section
- [x] Zero modifications to existing dev-facing instruction text (additions only; grep-verifiable per step)
- [x] Scripts, tests, execute/close/debug/simulate/do/verify specs byte-identical

### Out of Scope

- USAGE.md changes
- Any script or test change
- Execution-family specs (execute, close, patch, simulate, debug, do, verify) — patch-projex also untouched (its dev examples stay; patch targets "code/config" by definition)
- Syncing the deployed skill copy in the user's skills directory (separate deployment step, user-owned)
- Deep field-mode tooling (log templates, debrief workflow) — ship the ~10-line SKILL.md paragraph only

---

## Context

### Current State

- SKILL.md (repo == deployed skill copy, verified byte-identical 2026-07-29): `## Git Integration` at line 207; general sections (Authoring, Organizing, Lifecycle) already substrate-neutral
- Analytical specs' only git touchpoints: `new-projex` scaffold call, "do not commit automatically" finalize lines, relative-path notes
- `new-projex.{sh|ps1}` verified working outside git repos (no git commands; tested 2026-07-29)
- Term-density survey (proposal § Current State) confirms eval/redteam/imagine/explore/guide/propose/scan at ≤3 git-term lines each

### Key Files

> Quick reference — detailed changes in steps below.

| File | Role | Change Summary |
|------|------|----------------|
| `SKILL.md` | Framework spec | +`## Substrate` section (~45 lines) before `## Git Integration` |
| `scan-projex.md` | Locator-precision workflow | +2 format-table rows, +locator clause in characteristics |
| `review-projex.md` | Currency-check workflow | +non-code clause in Accuracy check row |
| `audit-projex.md` | Evidence-validation workflow | +non-code artifacts in Evidence to inspect |
| `eval/redteam/propose/interview/define/navigate/guide/imagine/memo/explore/review-projex.md` | Analytical specs | +1 non-dev invocation example each |
| `README.md` | Human-facing overview | +`## Not just for code` section after `## Why it works` |

### Dependencies

- **Requires:** proposal accepted (done — `Complete (Accepted)`)
- **Blocks:** nothing

### Constraints

- Additive only — existing lines may not be reworded or deleted (success criterion 5); in-line appends allowed only where a step explicitly shows before/after
- Dehydrated register for SKILL.md additions; example lines match each spec's existing example style
- Non-dev examples must be realistic invocations, not toy strings — an agent should pattern-match applicability from them

### Assumptions

- Repo SKILL.md remains identical to deployed copy at execution start (re-verify: `fc.exe /b`)
- Anchors below verified by heading text at execution, not line number (drift-safe)

### Impact Analysis

- **Direct:** 15 markdown files listed above
- **Adjacent:** agents loading SKILL.md see ~45 lines more context per session
- **Downstream:** none — nothing parses these files programmatically except the status regex (no status blockquotes touched)

---

## Implementation

### Overview

Six steps, each one file-cluster, each independently verifiable by grep + read-back. Order: SKILL.md first (the layer the rest leans on), then surgical clause edits, then examples, then README.

### Step 1: SKILL.md — add `## Substrate` section `[PATCHED]`

**Objective:** Name the substrate contract; define behavior off-git and off-file.
**Confidence:** High
**Depends on:** None
**Verify-Projex:** Encouraged

**Files:**
- `SKILL.md`

**Changes:**

Insert immediately before the `## Git Integration` heading (anchor by heading text):

```markdown
## Substrate

Projex methods are domain-general; git is the **reference substrate**, not a requirement. The execution family needs four guarantees from whatever holds the work:

1. **Inspectable corpus** — the status quo can be read
2. **Edit mechanism** — the corpus can be changed
3. **Checkpoint + rollback** — changes can be isolated and discarded
4. **Provenance log** — what changed, when, why is recoverable

Git provides all four. Substrate determines available workflows:

| Substrate | Available |
|-----------|-----------|
| Files in a git repo (code, prose, any domain) | Full framework |
| Files, no git | All analytical workflows + revise/memo/define/nav. No execute/simulate/debug cycle — no rollback guarantee |
| Non-file domain (events, negotiations, physical work) | Analytical workflows + Field Mode cycle |

### No-VCS Mode

`.projex/` folder not inside a git repo: skip repo resolution and every commit/stage step; create and edit files directly (`new-projex` works without git — its printed commit hint does not apply). Naming, statuses, folder states (`closed/`, `archived/`, `abandoned/`) unchanged. Locators adapt to the medium — `doc § heading`, `page:para`, `URL#anchor` in place of `file:ln`.

### Field Mode

For plans whose actions the agent cannot perform (book the venue, file the application, run the negotiation): author the Plan normally → the human executes → the agent debriefs the human interview-style and writes the execution log from their account (entries marked human-reported) → Close records evidence from that log. Analytical workflows are unaffected — they never required the agent to act.

### Irreversibility Discipline

The Critical Git Rules generalize to every substrate: one state-changing operation at a time, read the outcome before the next; explicit scope per change — name what you touch, no wildcards; human confirmation before any destruction or unrecoverable step.
```

**Rationale:** One `##` section keeps the ToC flat; placement directly above `## Git Integration` makes "git = reference implementation" read in sequence. Degradation table prevents over-applying the full cycle to checkpoint-less substrates (proposal risk 2).

**Verification:** `grep -n "^## Substrate" SKILL.md` → 1 hit, line number < `## Git Integration`'s; diff shows pure insertion; read section in place for flow and non-contradiction with Git Integration + Auxiliary Commit Policy.

**If this fails:** `git checkout -- SKILL.md` in worktree; structural disagreement → escalate, don't improvise.

---

### Step 2: scan-projex.md — non-code locators `[PATCHED]`

**Objective:** Extend locator formats beyond `file:ln`.
**Confidence:** High
**Depends on:** None
**Do-Projex:** Encouraged

**Files:**
- `scan-projex.md`

**Changes:**

1. Format-adaptation table (§ 3 WRITE THE SCAN DOCUMENT, "Format adaptation:") — append rows:

```markdown
| Document/manuscript content | `doc § heading` or `page:para` — what the match is |
| Web/external sources | `URL#anchor` — what the match is |
```

2. Key characteristics bullet:

```markdown
// Before:
- **Precision matters** — every entry must be real and accurately located (`file:ln`)

// After:
- **Precision matters** — every entry must be real and accurately located (`file:ln`, or the medium-appropriate locator — see Format adaptation)
```

3. INVOCATION Examples list — append (scan's non-dev example, kept here with its sibling locator edits rather than in step 5):

```markdown
- `/scan-projex Every unresolved citation across the manuscript`
```

**Rationale:** Spec already declares "Adaptive format"; rows make non-code concrete. Bullet change is a parenthetical append, dev text intact.

**Verification:** grep `page:para`, `URL#anchor`, `unresolved citation` → 1 hit each; table renders.

**If this fails:** `git checkout -- scan-projex.md` in worktree.

---

### Step 3: review-projex.md — non-code Accuracy clause `[PATCHED]`

**Objective:** Accuracy check covers non-code sources.
**Confidence:** High
**Depends on:** None
**Do-Projex:** Encouraged

**Files:**
- `review-projex.md`

**Changes:**

Check-matrix row (§ 4 EXAMINE THE TARGET):

```markdown
// Before:
| **Accuracy** | File refs resolve? `file:ln` cites still correct? Code samples match reality? Facts current? |

// After:
| **Accuracy** | File refs resolve? `file:ln` cites still correct? Code samples match reality? Facts current? Non-code sources: cites resolve, quoted claims match source? |
```

**Rationale:** Append-only within the row; dev questions untouched.

**Verification:** grep `Non-code sources` → 1 hit, inside the Accuracy row.

**If this fails:** `git checkout -- review-projex.md` in worktree.

---

### Step 4: audit-projex.md — non-code evidence `[PATCHED]`

**Objective:** Evidence list covers non-code artifacts.
**Confidence:** High
**Depends on:** None
**Do-Projex:** Encouraged

**Files:**
- `audit-projex.md`

**Changes:**

§ 2 IDENTIFY VALIDATION CHECKPOINTS, "Evidence to inspect:" paragraph:

```markdown
// Before:
Git commits, code files, tests (existence, pass, coverage), documentation (accurate, complete), logs, metrics

// After:
Git commits, code files, tests (existence, pass, coverage), documentation (accurate, complete), logs, metrics. Non-code work: deliverables, records, correspondence, published/filed artifacts
```

**Rationale:** Appended sentence; existing enumeration intact.

**Verification:** grep `Non-code work` → 1 hit.

**If this fails:** `git checkout -- audit-projex.md` in worktree.

---

### Step 5: 11 specs — one non-dev invocation example each `[PATCHED]`

**Objective:** Seed applicability signal where agents read it — the Examples lists.
**Confidence:** High
**Depends on:** None
**Do-Projex:** Encouraged

**Files:** `eval-projex.md`, `redteam-projex.md`, `propose-projex.md`, `interview-projex.md`, `define-projex.md`, `navigate-projex.md`, `guide-projex.md`, `imagine-projex.md`, `memo-projex.md`, `explore-projex.md`, `review-projex.md`

**Changes:** Append one line to each spec's INVOCATION Examples list (redteam has no Examples list — append to its invocation code block), matching that file's existing example format and `.md`-suffix convention:

| Spec | Added example |
|------|---------------|
| eval | `/eval-projex Comparative vs longitudinal design for the thesis study` |
| redteam | `/redteam-projex.md The contingency plan for the outdoor launch event` |
| propose | `/propose-projex.md Restructure the onboarding curriculum around case studies` |
| interview | `/interview-projex book chapter outline and argument structure` |
| define | `/define-projex.md Our consulting engagement model` (first-invocation list) |
| navigate | `/navigate-projex.md Thesis completion roadmap` (first-invocation list) |
| guide | `/guide-projex.md Get up to speed on GDPR obligations for the newsletter` |
| imagine | `/imagine-projex.md A field guide that adapts its depth to the reader's location and season` |
| memo | `/memo-projex User said "the intro chapter buries the thesis statement"` |
| explore | `/explore-projex.md How does the current grant application process work?` |
| review | `/review-projex @2607311430-course-outline-plan.md` |

**Rationale:** One line per file; examples drive agents' applicability pattern-matching (proposal change 5). Review's example doubles as a reminder that reviewed projex may themselves be non-dev.

**Verification:** Per file: grep the added string → 1 hit inside INVOCATION section. `git diff --stat` in worktree: exactly +1 line for each of these files (review-projex: +1 here on top of step 3's edit).

**If this fails:** `git checkout -- <file>` per failing file.

---

### Step 6: README.md — "Not just for code" section `[PATCHED]`

**Objective:** Human-facing generality statement.
**Confidence:** High
**Depends on:** Step 1 (references SKILL.md § Substrate)
**Do-Projex:** Encouraged

**Files:**
- `README.md`

**Changes:**

Insert after the `## Why it works` bullet list, before `## Workflows`:

```markdown
## Not just for code

The workflows are thinking disciplines, not programming tools — evaluation lenses, adversarial stakeholder waves, claims-vs-evidence audits, living roadmaps. Anything file-based kept in a git repo (a manuscript, course material, legal drafts, research notes) gets the **full** framework, branches and all. Without git, every analytical workflow still runs — documents are created directly, commits skipped. For work that isn't files at all, the agent authors the plan, you execute it, and the record is kept the same way. Scope rules per substrate: `SKILL.md § Substrate`.
```

**Rationale:** Placed where a human evaluating the framework has just read the value props; one paragraph, no new table to maintain.

**Verification:** grep `Not just for code` → 1 hit between `## Why it works` and `## Workflows`.

**If this fails:** `git checkout -- README.md` in worktree.

---

## Verification Plan

> Per-step verification confirms each edit in isolation. This confirms the whole.

### Automated Checks

- [ ] `git diff --stat {base}..HEAD` — exactly the 15 planned files (+ plan/log projex docs), nothing from the execution family
- [ ] `git diff {base}..HEAD` — deletions only on the three lines explicitly reworded via before/after (steps 2.2, 3, 4); everything else pure addition
- [ ] `grep -c '> \*\*Status:\*\*'` unchanged per touched spec — no status blockquotes affected

### Manual Verification

- [ ] Read SKILL.md top-to-bottom once — Substrate section flows; no contradiction with Git Integration or Auxiliary Commit Policy
- [ ] Each of the 11 examples reads native in its list (register, punctuation, suffix convention)
- [ ] README section reads for a human, not an agent

### Acceptance Criteria Validation

| Criterion | How to Verify | Expected Result |
|-----------|---------------|-----------------|
| Substrate section complete | Read SKILL.md § Substrate | Contract (4 guarantees) + table + 3 subsections |
| Locator/evidence coverage | grep step 2-4 markers | 1 hit each in scan/review/audit |
| 11 non-dev examples | grep per step-5 table | 1 hit per file in INVOCATION |
| README section | grep + read | Present between Why-it-works and Workflows |
| Additive-only | full diff review | No dev instruction lines removed beyond the 3 declared before/after rewrites |
| Family untouched | diff --stat file list | Only planned files |

---

## Rollback Plan

Per-step rollback in each step (worktree `git checkout -- <file>`). Full abandonment: `projex-abandon --worktree` on the ephemeral branch — base never touched (worktree mode).

---

## Notes

### Risks

- **SKILL.md wording drifts agents on dev tasks:** Low — additions live in one self-contained section; post-merge smoke check: run one dev-flavored analytical workflow (proposal next-step 2)
- **Example line breaks a spec's list formatting:** Low — per-file read-back in step 5 verification

### Split Verdict

No split — single scope, within size budget (6 steps, but plan < 500 lines / < 50 KB; size heuristic not tripped; no cross-scope or cross-repo files).

### Open Questions

*(none — proposal OQs resolved 2026-07-29 pre-plan)*
