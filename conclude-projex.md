---
description: This workflow performs **verified supersession** — given a successor document that crystallizes prior work (a Definition, Navigation, Plan, …), it verifies each source projex is fully consumed by the successor, then retires the sources: stamps them superseded, rewrites the successor's provenance into a warning ledger, and moves them to `.projex/closed/`. (This is part of @projex-framework skill. It is a MUST to load the skill first.)
---

## PURPOSE

Work flows through many projex — explorations, evals, redteams, memos, interviews — before crystallizing into one successor document. Left in place, the consumed sources keep feeding agents claims the successor already settles or overrules.

Conclude retires them safely: it verifies the successor carries or knowingly overrules every substantive claim in each source, then stamps the sources superseded and removes them as files — the stamped version stays recoverable from git history, and the Conclude report keeps each filename and verdict in-tree. Content the successor never engaged with blocks retirement.

**Key characteristics:**
- Sources may sit anywhere in the projex scope — active (`.projex/`) or already closed (`.projex/closed/`)
- Per-source residue check: every substantive claim classified Captured / Overruled / Residue
- Residue **blocks retirement** — no silent drops
- Rewrites the successor's prior-artifact references into a do-not-consult provenance ledger
- Produces a Conclude report recording all verdicts
- Judgment workflow — unlike Archive (mechanical compression of already-closed files). Like Archive, retired originals are removed; the report is the surviving in-tree record

**Born closed** — the report lands directly in `.projex/closed/`.

---

## INVOCATION

```
/conclude-projex @{successor-filename}                                # sources derived from successor's references + active folder
/conclude-projex @{successor-filename} @{source1} @{source2} ...      # explicit source list
```

The successor is any document claimed to crystallize prior work — typically a Definition or Navigation, but a Plan or Proposal qualifies when it absorbs earlier analysis.

---

## WORKFLOW STEPS

### 1. IDENTIFY SUCCESSOR AND SOURCES

- Confirm repo root first: `git -C <successor-file-directory> rev-parse --show-toplevel`. Every raw git command below passes it as `git -C <repo-root> …`
- Resolve the successor file. Locate its projex folder — conclude operates within **one** `.projex/` scope; a source from a different scope is flagged and excluded
- Build the source candidate list:
  - Explicit arguments, if given — this list is **literal**: examine exactly these, add none
  - Otherwise: every projex the successor references by filename, plus documents the user names when asked
Before eligibility or residue analysis, run the host-matched `{projex-scripts}/projex-tree.{sh|ps1}` for the successor and each selected source. Treat successful tree context as advisory and not guaranteed exhaustive; use it as additional context while retaining existing source, residue, and impact judgment.

### 2. ELIGIBILITY GATES

The successor must **dominate** its sources. Verify before any analysis:

| Gate | Rule | On failure |
|------|------|------------|
| Successor status | Not `Draft` — never conclude into unratified content | Stop; suggest finalizing the successor first |
| Successor location | Active (`.projex/`), not itself closed/archived | Stop |
| Successor recency | Date prefix newer than every source | Flag older-than-source anomalies to the user |
| Source location | Within the successor's projex scope — `.projex/` and `.projex/closed/` both eligible. Sources already compressed into an archive index are out of reach | Exclude with a note |
| Source type | Not Definition (never-closed; retires via define revision, not conclude). A Navigation **is** eligible when the successor is a newer roadmap for the same scope — conclude is the verified route for roadmap supersession | Exclude Definitions; point to define revision |
| Source ≠ successor | A document cannot conclude itself | Exclude |

### 3. RESIDUE CHECK

For each source, extract its **substantive claims** — decisions, findings, constraints, open questions, documented dissent — and classify each against the successor:

| Verdict | Meaning | Effect |
|---------|---------|--------|
| **Captured** | Successor carries this claim (possibly reworded/generalized) | Safe to retire |
| **Overruled** | Successor *knowingly decided against* it — the decision is visible in the successor | Safe to retire |
| **Residue** | Still-relevant claim the successor **never engaged with** | Blocks retirement of that source until dispositioned |

Overruled requires a visible decision in the successor — a claim the successor never mentions is Residue, not Overruled. Documented dissent in interview/coach transcripts counts as claims: carried forward or visibly overruled, never dropped.

**Parallelization:** with multiple sources, run the check in parallel using sub-agents — one per source. Each reads its source plus the successor and returns the verdict list.

**Model tier:** coordinator tier, NOT the cheap tier. Unlike Archive's field extraction, residue classification is genuine inference — a wrong `Captured` silently destroys information.

> **Sub-agent prompt template:**
> "Read source projex `{source-filepath}` and successor `{successor-filepath}`. Extract every substantive claim from the source — decisions, findings, constraints, open questions, documented dissent (skip narrative/process text). For each claim return one line: `[verdict] claim — evidence`, where verdict is:
> - `Captured` — successor carries it; cite the successor section
> - `Overruled` — successor visibly decided against it; cite where
> - `Residue` — still-relevant, successor never engaged with it
> Default to `Residue` when uncertain — a false Captured destroys information; a false Residue only costs a review. Do not invent claims the source does not make."

### 4. DISPOSITION

Per source, from its verdicts:

- **All Captured/Overruled → Retire**
- **Any Residue → Blocked.** Present the residue to the user with disposition options:
  1. **Fold into successor** — add the missing content to the successor (its own revision path — `/revise-projex` for small fixes, the successor's authoring workflow for core changes), then the claim becomes Captured and the source retires
  2. **Spin a memo** — `/memo-projex` captures the residue as a fresh active document; source retires
  3. **Keep active** — source stays in `.projex/`, recorded as `Kept` in the report

Every claim ends with exactly one verdict and every Residue with exactly one disposition — visible in the report. No silent drops.

### 5. DRAFT THE CONCLUDE REPORT

Set `{parent}` to `{successor-filename}`: the successor is the report's causal artifact; sources remain listed as sources.

```bash
{projex-scripts}/new-projex.sh --repo-root <repo-root> --type conclude --title "{successor-scope}" --parent {parent} --projex-dir <projex-folder>
# born-closed: the script places the file in <projex-folder>/closed/ itself
```
```powershell
{projex-scripts}\new-projex.ps1 -RepoRoot <repo-root> -Type conclude -Title "{successor-scope}" -Parent {parent} -ProjexDir <projex-folder>
```

**Template:**

```markdown
# Conclude: [Successor Title]

> **Status:** Complete
> **Successor:** {successor-filename}
> **Date:** YYYY-MM-DD
> **Sources:** [N] examined — [X] retired | [Y] kept | [Z] excluded

## Summary

[1-2 sentences: what crystallized into what, and what was retired.]

## Verdicts

### `{source-filename}` — Retired

- **Captured:** [claim] → [successor section] | [claim] → [successor section]
- **Overruled:** [claim] — [where the successor decides against it]

### `{next-source-filename}` — Kept (residue) | Kept (user) | Excluded (archived | cross-scope)

- **Residue:** [claim] → [disposition: folded into successor §X | spun into {memo-filename} | kept active]

## Notes

- [Anomalies: excluded sources, cross-scope references, older-than-source successor content]
```

### 6. PRESENT AND CONFIRM

Surface the report path, per-source dispositions, and any residue to the user. **Do not stamp, move, or commit anything yet.**

**This step requires explicit user confirmation** — retirement is a judgment call, and moving documents out of `.projex/` changes what every future agent sees.

### 7. EXECUTE RETIREMENT (on confirmation)

**Step 7a — stamp each retired source.** Insert directly under the title:

```markdown
> **Concluded:** superseded by {successor-filename}, YYYY-MM-DD — do not consult for current state
```

If the source carries a `> **Status:**` line, set it to `Complete (Superseded)` (memos: `Complete (Consumed)`). The stamp survives git-history excavation — a retired doc self-identifies as stale wherever it is found.

**Step 7b — rewrite the successor's provenance.** Replace any "prior artifacts" listing with a closed ledger:

```markdown
## Provenance (concluded)

> Consumed and retired {YYYY-MM-DD} — historical record only. This document supersedes them; do NOT consult for current state.

- `{source-filename}` — [Captured | partially Overruled: one-line]
```

Sources kept active stay listed as live references, clearly separated from the ledger.

**Step 7c — commit the content edits:**

```bash
{projex-scripts}/stage-n-commit.{sh|ps1} <repo-root> "projex(conclude): retire {N} sources into {successor-name}" <report> <successor> <stamped-source-1> <stamped-source-2> ...
```

Verify success before moving anything.

**Step 7d — remove the retired sources:**

Each source at its current location (`.projex/` or `.projex/closed/`):

```bash
{projex-scripts}/del-n-stage.{sh|ps1} <repo-root> <source1-path> <source2-path> ...
```

Then commit the staged deletions:

```bash
{projex-scripts}/stage-n-commit.{sh|ps1} <repo-root> "projex(conclude): remove retired sources" <source1-path> <source2-path> ...
```

> `stage-n-commit` skips already-deleted files at the staging step — their deletions are already staged by `del-n-stage` and are included in the commit.

> **Never remove with wildcards** — only the files retired in this run, listed explicitly. The successor itself is **never removed**. The stamp commit (7c) must land first so the last version of each source in git history self-identifies as superseded.

---

## OUTPUT

- A Conclude report at `<projex-folder>/closed/{yymmddhhmm}-{successor-scope}-conclude.md`
- Retired sources stamped (committed), then removed — recoverable from git history by filename
- Successor's prior-artifact references rewritten into a warning ledger
- Residue folded into the successor, spun into memos, or kept active — each recorded

**Folder state after conclude:**
```
.projex/
├── {successor}.md                    ← active, provenance ledger rewritten
├── {kept-source}.md                  ← only sources with user-kept residue remain
└── closed/
    └── {yymmddhhmm}-{scope}-conclude.md    ← sole record of the retired sources
```

---

## QUALITY CHECKLIST

- [ ] Successor passed every eligibility gate (not Draft, active, dominates sources)
- [ ] Explicit source list treated as literal — nothing added, nothing skipped silently
- [ ] Every substantive source claim carries exactly one verdict in the report
- [ ] Overruled verdicts cite where the successor makes the decision — "not mentioned" is Residue, not Overruled
- [ ] Documented dissent classified as claims, never dropped as process text
- [ ] Every Residue has exactly one recorded disposition
- [ ] No stamp, removal, or commit before explicit user confirmation
- [ ] Stamp commit verified before removals; removals by explicit path only
- [ ] Successor never removed; Definitions never taken as sources; Navigation sources only under a same-scope successor roadmap
- [ ] Report references all documents by filename only, never path

---

## NOTES

- Conclude does not destroy information — it compresses it, like Archive. The report preserves each filename and verdict; the stamped full document is recoverable from git history. The report itself is later compressible by `/archive-projex`
- A successor can be concluded into repeatedly as more priors get absorbed — each run appends to its provenance ledger
- If the residue check reveals the successor is substantially incomplete (many Residue verdicts across sources), stop and say so — the right move is deepening the successor via its own workflow, not partial retirement
- Use relative paths when referencing files; projex by filename only
