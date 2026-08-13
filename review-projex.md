---
description: This workflow guides the creation of **Review** projex documents — inspection of existing projex documents against the current status quo, verdicting whether each remains valid, needs revision, or should be retired. (This is part of @projex-framework skill. It is a MUST to load the skill first.)
---

## PURPOSE

Reviews combat projex decay. Codebases move; documents don't. A review inspects existing projex against today's reality and delivers a verdict: keep, fix, or retire.

**Key characteristics:**
- Inspects projex documents, not code — the subject is always one or more projex files
- Grounded in current status quo, established independently before reading the target
- Verdict-driven: every reviewed document gets exactly one verdict with follow-up actions
- Batch-capable: one review can cover many documents

**Contrast with Audit and Red Team:**
- **Review** — is this document still current and worth keeping? (currency check)
- **Audit** — was this completed work actually done correctly? (correctness check)
- **Red Team** — what is wrong with this idea/system? (adversarial attack)

Review judges currency, not quality. A well-written plan whose target code no longer exists fails review; a mediocre but accurate one passes.

---

## INVOCATION

```
/review-projex @<projex-file>
/review-projex <selector or context>
```

**Examples:**
- `/review-projex @2607311430-language-macro-syntax-change-proposal.md`
- `/review-projex all active plans`
- `/review-projex everything in .projex/ older than 30 days`
- `/review-projex the projex we made last week`
- `/review-projex @2607311430-course-outline-plan.md`

---

## REVIEW TRIGGERS

- **Time** — document >30 days old without activity
- **Event** — related codebase area changed significantly
- **Dependency** — related projex changed, closed, or was abandoned
- **Pre-execution** — before executing an older plan (strongly recommended)
- **Post-completion** — after related work completes, sibling documents may be stale
- **Request** — user or another workflow asks

---

## VERDICTS

One verdict per reviewed document. Canonical vocabulary — no other values:

| Verdict | Meaning | Follow-up |
|---------|---------|-----------|
| **Valid** | Current and accurate as-is | Record review note; nothing else |
| **Revise** | Core still sound; content drifted (stale refs, changed assumptions) | List required edits; `/revise-projex` or manual update |
| **Expand** | Accurate but status quo outgrew its scope | List coverage gaps; extend or spawn follow-up projex |
| **Archive** | Superseded or obsolete, but worth keeping as record | Move to `.projex/archived/` |
| **Abandon** | No longer relevant, not worth preserving | Move to `.projex/abandoned/` or delete |

Verdicts are **recommendations**. Record review notes in the reviewed documents, but perform folder moves (Archive/Abandon) only after the user confirms — use `move-n-stage` / `del-n-stage` when confirmed.

---

## DEPTH TIERS

Select during step 1. Depth per document, not per review — a batch may mix tiers.

| Tier | When | Work |
|------|------|------|
| **Spot Check** | Recently active docs, low stakes, or batch triage | Verify refs resolve, assumptions hold at a glance. Roster row only — no detail section. |
| **Standard** | Default — aging doc, pre-execution check | Full independent recon + examination + challenge. Detail section per doc. |
| **Deep** | High-stakes doc (accepted proposal, plan about to execute, load-bearing definition) | Standard + trace every file ref, re-derive key claims from source, challenge core assumptions individually. |

In batch mode, triage with Spot Check first; escalate any document that smells stale to Standard/Deep.

---

## WORKFLOW STEPS

### 1. RESOLVE TARGETS

**Resolve the target repo** — reviews run in the repo owning the projex:

```bash
cd <absolute-path-to-projex-file-directory> && git rev-parse --show-toplevel
```

Record output as `<repo-root>`. All script calls below use it.

**Build the target roster:**
- **Specific document** — locate file; note type, status, age
- **Context-based** ("the projex we made last week") — identify from recent history
- **Batch selector** ("all active plans") — query `.projex/` folders; list matches

For each target record: filename, type, `> **Status:**` value, created date (from filename prefix), last-modified date. Assign a depth tier per target.

**Skip-by-default:** closed analytical documents (eval, review, redteam, audit, walkthrough) are historical records — reviewing them is usually `/archive-projex` territory, not review. Include only if explicitly requested.

### 2. SCAFFOLD THE REVIEW DOCUMENT

Scaffold **before examining anything**:

```bash
Resolve `{parent}` from the primary reviewed subject filename; else supplied orchestrator Parent; else `User`.
{projex-scripts}/new-projex.sh --repo-root <repo-root> --type review --title "{target-name-or-batch-theme}" --parent {parent} --projex-dir <projex-folder>
```
```powershell
{projex-scripts}\new-projex.ps1 -RepoRoot <repo-root> -Type review -Title "{target-name-or-batch-theme}" -Parent {parent} -ProjexDir <projex-folder>
```

Fill in header and target roster. Verdicts stay blank — the roster is the worklist. The document is the working artifact: findings go into it as each target is processed, not into context alone. An interrupted review still carries every completed target's verdict.

### 3. INDEPENDENT RECON — PER TARGET

**Do NOT deep-read the target yet.** Anchoring to the document's own narrative is the main failure mode of reviews. First, establish reality independently:

1. **Explore the domain now** — read the current code/files the target concerns
2. **Check history since authoring** — commits, merges, related projex closed/created after the target's date
3. **Note observations** — what is true today, without the target's framing

Recon depth scales with tier: Spot Check = glance at refs; Deep = full domain walk.

### 4. EXAMINE THE TARGET

Now read the target critically. Run the check matrix:

| Check | Question |
|-------|----------|
| **Validity** | Stated problems still problems? Assumptions still hold? Approach still sensible? Prerequisites unchanged? |
| **Accuracy** | File refs resolve? `file:ln` cites still correct? Code samples match reality? Facts current? Non-code sources: cites resolve, quoted claims match source? |
| **Completeness** | Does status quo reveal gaps the doc should cover? Scope still right? |
| **Value** | Still worth doing/keeping? Effort still justified? Superseded by anything? |

**Type-aware focus** — weight checks by target type:

| Target type | Primary question |
|-------------|------------------|
| Proposal (open) | Direction still wanted? Trade-off landscape unchanged? |
| Plan (Draft/Ready) | Executable against today's code as written? |
| Navigation | Roadmap reflects reality? Dead entries? |
| Definition | Spec still matches the entity it defines? |
| Memo | Still unconsumed and worth consuming? |
| Exploration/Guide (open) | Findings/reading path still accurate? |

Record drift as findings: `[assumption/ref] [held/broke] [evidence]. [consequence].`

### 5. CHALLENGE

Standard/Deep tiers only. Two or three pointed challenges per target — not a full adversarial pass (that is `/redteam-projex`):

- What single change since authoring most threatens this document?
- What would make it obsolete tomorrow?
- If authored fresh today, what would differ?

A challenge that lands demotes the verdict; one that doesn't strengthens it. Record either way.

### 6. VERDICT

Per target, pick exactly one verdict from the table. Ground it in recorded findings — no verdict without evidence.

**Derivation rules** — check outcomes constrain the verdict. Severity order: Valid < Expand < Revise < Archive < Abandon. Apply every triggered rule; the most severe constraint wins. Judgment picks within the constraint, not around it.

| Condition (from recorded findings) | Constraint |
|------------------------------------|------------|
| All checks ✓, all challenges held | Valid |
| Accuracy ✗ only — refs/facts stale, core sound | ≥ Revise |
| Completeness ✗, all else ✓ | ≥ Expand |
| Any Major drift row | ≥ Revise |
| Validity ✗ — problem gone or approach invalidated | Archive or Abandon only |
| Value ✗ | Archive if worth keeping as record, else Abandon |
| Any challenge landed | Valid excluded |

Deviating from a triggered rule requires an inline note in the detail section: `**Override:** [rule skipped] — [why]`. No silent overrides.

Write the target's detail section (Standard/Deep) or roster row (Spot Check), then move to the next target.

**Write the Summary last**, after all targets are verdicted.

**Template Structure:**

```markdown
# Review: [Target Name or Batch Theme]

> **Reviewer:** [name or agent]
> **Status:** In Progress
> **Targets:** [count] | **Related Projex:** [links]

---

## Summary

> **PLACEHOLDER — write last, after all targets verdicted.**

[2-4 sentences: what was reviewed, overall health, actions needed]

**Verdict counts:** Valid: n | Revise: n | Expand: n | Archive: n | Abandon: n
**Ripple:** [n referrers flagged | contained — no referrers]

---

## Targets

| # | Document | Type | Age | Tier | Verdict | Note |
|---|----------|------|-----|------|---------|------|
| 1 | [filename] | [type] | [days] | Spot/Std/Deep | [verdict] | [one-liner] |

---

## [Target 1 filename]

> **Verdict:** Valid | Revise | Expand | Archive | Abandon

**Recon (independent):** [what is true today — established before reading target]

**Drift:**
| Assumption/Ref | Then | Now | Impact |
|----------------|------|-----|--------|
| [item] | [as authored] | [current reality] | None/Minor/Major |

**Checks:** Validity: ✓/✗ [note] | Accuracy: ✓/✗ [note] | Completeness: ✓/✗ [note] | Value: ✓/✗ [note]

**Challenges:**
- [Challenge] → [held/landed] — [evidence]

**Actions:**
- [ ] [Specific edit, move, or follow-up projex]

---

## Ripple

> Referrers of non-Valid targets, found by filename search. Depth 1.

| Referrer | References | Its verdict | Disposition |
|----------|------------|-------------|-------------|
| [filename] | [target filename] | [non-Valid verdict of target] | Rostered / Review candidate / Informational (closed) |

---

## Open Questions

- [ ] [Unresolved — needs user decision or further work]
```

Spot Check targets get roster rows only; add a detail section only if the check found something.

### 7. RIPPLE CHECK

A stale document is rarely stale alone. For **every non-Valid verdict**, find who references the target — projex reference by filename (SKILL.md § Authoring), so one search suffices:

```bash
grep -rl "{target-filename}" <repo-root> --include="*.md"
```

For each referrer found (excluding the review doc itself):

- **Already on the roster** — note the link in its detail section; its own verdict covers it
- **Active projex** (`.projex/`, not closed/archived/abandoned) — add to the Ripple table; escalate onto the roster this session if the batch allows, else log as a review candidate
- **Closed/archived projex** — log in the Ripple table as informational; historical records don't get re-verdicted

Ripple depth is 1: referrers-of-referrers are checked only if a referrer joins the roster and itself goes non-Valid. An empty ripple result is worth recording — it says the decay is contained.

### 8. UPDATE ORIGINALS

For each reviewed document, add a review note near the top:

```markdown
> **Reviewed:** YYYY-MM-DD — {review-filename} — Verdict: [verdict]
```

Reference by filename only, both directions. Do not change the target's `> **Status:**` line — verdicts are recommendations; status changes belong to the follow-up actions the user approves.

### 9. VALIDATE & FINALIZE

**Checks:**
- [ ] Every roster target has a verdict from the canonical table
- [ ] Recon done before deep-read for every Standard/Deep target
- [ ] Every verdict traceable to recorded findings — no vibes-based verdicts
- [ ] Verdicts conform to the derivation rules; any override noted inline with reason
- [ ] Ripple scan run for every non-Valid verdict; referrers rostered or logged
- [ ] Every non-Valid verdict has concrete actions listed
- [ ] Review notes added to all reviewed documents
- [ ] Summary written last, matches roster counts
- [ ] No folder moves performed without user confirmation

**De-slop pass:** strip agent self-narration, hollow hedging, restated findings, unfilled template artifacts.

Set `> **Status:** Complete` on the review document. Present it with the verdict roster and proposed moves. Do not commit automatically — commit only when the user explicitly requests it.

---

## REVIEW PRINCIPLES

- **Fresh eyes first** — status quo before target content; independence is the whole point
- **Currency, not quality** — a review is not a critique; it asks "still true?" not "well made?"
- **Evidence over impression** — every verdict traces to a recorded finding
- **Retirement is success** — Archive/Abandon verdicts are the system working, not failure
- **Decay spreads** — a stale document's referrers are suspects, not bystanders; every non-Valid verdict gets a ripple scan
- **Constructive** — every non-Valid verdict ships with actions, not just judgment

---

## OUTPUT

Produces `.projex/{yymmddhhmm}-{name}-review.md` with per-target verdicts and actions, plus review notes in each reviewed document.

**Folder placement:** See SKILL.md § Organizing. Review doc: active → `.projex/`, done → `.projex/closed/`.

**Committing:** Present the review document to the user. Do not commit automatically — commit only when the user explicitly requests it.

---

## NOTES

- Reviews can chain: Revise → `/revise-projex`, Expand → new projex, deep concerns → `/redteam-projex` or `/audit-projex`
- Batch reviews of large rosters may span sessions — the roster tracks progress
- Consider periodic review schedules for load-bearing projex (navs, definitions, accepted proposals)
- Use relative paths for repo files; filenames only for projex references
