---
description: This workflow compresses all files in `.projex/closed/` into a single **Archive** index document — describing each with a structured entry (type, date, outcome, touched areas, keywords, related docs) — then clears the folder and places the archive inside it. (This is part of @projex-framework skill. It is a MUST to load the skill first.)
---

## PURPOSE

Archives shrink the `.projex/closed/` folder from many files into one compact index. Each closed projex gets a structured entry — summary, type, date, outcome, touched areas, keywords, related documents — making the history searchable without the clutter of full documents.

Entries are deliberately field-rich: an agent scanning the archive should be able to answer "was anything ever done to X?" or "which document decided Y?" from the index alone, without pulling documents back out of git history.

**Key characteristics:**
- Reads every file in `.projex/closed/` and produces a multi-field entry per file
- Summarization can be parallelized across files using sub-agents
- Outputs a single archive index document
- Clears the individual files from `.projex/closed/` after archiving
- Places the archive index into `.projex/closed/` as its sole artifact

**Born closed** — the archive index lands directly in `.projex/closed/`.

---

## INVOCATION

```
/archive-projex
/archive-projex .projex/closed/          # explicit path (if multiple closed/ folders exist)
```

---

## WORKFLOW STEPS

### 1. IDENTIFY TARGET FOLDER

Determine which `.projex/closed/` folder to archive:

- If invoked without arguments, default to `.projex/closed/` relative to the current repo root
- If a path is given, use that folder
- Confirm the repo root first: `git rev-parse --show-toplevel`

### 2. SCAN CLOSED FOLDER

List all `.md` files in the target `closed/` folder, **excluding any that end in `-archive.md`**:

```bash
ls .projex/closed/*.md
# then filter out *-archive.md files — these are never processed
```

**If the folder is empty or has no eligible `.md` files:** inform the user and stop — nothing to archive.

Collect the full list of non-archive files to process. Existing archive files are left untouched throughout. This list drives the next step.

### 3. SUMMARIZE EACH FILE

For each file in the list, extract the full field set. Be generous — every field is a search handle for a future agent.

| Field | Content | If unavailable |
|-------|---------|----------------|
| **Filename** | The file's name only (not path), e.g. `2601151430-auth-session-timeout-walkthrough.md` | — (always present) |
| **Title** | The document's `# ` heading, trimmed of the type prefix | Derive from the filename slug |
| **Date** | `YYYY-MM-DD` decoded from the `{yymmddhhmm}` prefix | — (always derivable) |
| **Type** | Workflow type from the filename suffix, capitalized (Plan, Walkthrough, Patch, Evaluation, …) | `Unknown` |
| **Outcome** | What the document concluded or landed: `Complete`, `Accepted`, `Rejected`, `Superseded`, `Abandoned`, `No action`, plus a short clause (e.g. `Accepted — adopted for all new endpoints`) | `Unclear` |
| **Summary** | 1–2 sentences on what the document is about and what it accomplished or found | — (always required) |
| **Touched** | Repo-relative paths, modules, or components the work concerned, comma-separated (max ~6). Relative paths only — redact anything external | `—` |
| **Keywords** | 10–20 comma-separated terms. Cast wide — see below | — (always required) |
| **Related** | Filenames of other projex this one references, supersedes, or was spawned from | `—` |

**Keywords are the primary search surface — be liberal.** A term that goes unused costs one comma; a term left out costs a future agent the whole document. Aim for 10–20 and sweep these dimensions:

- **Subject** — what the work was about (`session expiry`, `rate limiting`)
- **Components** — modules, services, scripts, files by name (`stage-n-commit`, `auth middleware`)
- **Technology** — languages, tools, libraries, protocols involved (`powershell`, `git rebase`, `oauth`)
- **Symptom / trigger** — how the problem would be described by someone hitting it again, including verbatim error text (`stale branch pointer`, `detached HEAD`)
- **Synonyms and variants** — the terms a searcher might use instead of yours (`timeout` alongside `expiry`; `ci` alongside `pipeline`; both spellings and both the abbreviation and the expansion)
- **Concepts and decisions** — the durable ideas (`idempotency`, `rollback safety`, `opt-in default`)

Two constraints only: no workflow type names (that is the `Type` field), and every keyword must be grounded in the document — do not invent plausible-sounding terms the work never involved. Within those, more is better.

**Parallelization:** When there are multiple files, summarize them in parallel using sub-agents — one sub-agent per file or in small batches. Each sub-agent reads the file and returns the fields above. Collect all results before proceeding.

**Model tier:** Use the cheapest available tier for these sub-agents (Haiku or equivalent), at least one tier below the coordinator. Field extraction against an explicit template is a bounded task — the prompt below names every field and every keyword dimension, so there is little left to infer. The saving is real: the sub-agents read the entire `closed/` folder, so this step is almost pure input tokens.

**Escalation:** Re-run a single file at the coordinator's tier when the cheap pass returns `Outcome: Unclear`, fewer than 10 keywords, or a summary that only restates the title — `Outcome` is the one field requiring genuine inference and the first to degrade. Escalate that file alone, not the whole batch.

> **Sub-agent prompt template:**
> "Read this projex file and return these fields, one per line:
> - filename (name only, no path)
> - title (the document's `# ` heading)
> - date (YYYY-MM-DD, decoded from the `{yymmddhhmm}` filename prefix)
> - type (workflow type from the filename suffix, capitalized)
> - outcome (what it concluded or landed — Complete / Accepted / Rejected / Superseded / Abandoned / No action / Unclear — plus a short clause saying what that meant)
> - summary (1-2 sentences describing what this document is about and what it accomplished or found)
> - touched (repo-relative paths, modules, or components the work concerned, comma-separated, max 6; use `—` if the document touched no code. Never emit absolute paths)
> - keywords (10-20 comma-separated terms — be generous, this is how future agents find this document. Sweep all of: subject matter; components/modules/scripts by name; technologies, tools and libraries involved; symptoms or error text someone hitting this again would search for; synonyms and variants of your own terms, including abbreviation and expansion; durable concepts and decisions. Every term must be grounded in the document — do not invent terms the work never involved. Do NOT use workflow type names like plan, walkthrough, patch, evaluation, review, audit, log, memo, scan, etc.; the type is its own field)
> - related (filenames of other projex this document references, supersedes, or was spawned from; `—` if none)
>
> Use `—` for any field the document does not support. Do not guess beyond what the document states. File: `{filepath}`"

### 4. DRAFT THE ARCHIVE DOCUMENT

```bash
Resolve `{parent}` from an explicit causal source/nav/subject; else supplied orchestrator Parent; else `User`.
{projex-scripts}/new-projex.sh --repo-root <repo-root> --type archive --title "{scope}" --parent {parent} --projex-dir <projex-folder>
```
```powershell
{projex-scripts}\new-projex.ps1 -RepoRoot <repo-root> -Type archive -Title "{scope}" -Parent {parent} -ProjexDir <projex-folder>
```

Use today's date for `{yymmddhhmm}`. Use the folder's scope name for `{scope}` (e.g. `projex-closed` for root `.projex/closed/`).

**Template:**

```markdown
# Archive: [Scope]

> **Scope:** [which .projex/closed/ this covers]
> **Files Archived:** [N]
> **Date Range:** [earliest date] → [latest date]
> **Types:** [Walkthrough ×4, Patch ×3, Evaluation ×1, ...]

---

## Summary

[1-2 sentences: what period/scope this archive covers and what kinds of work are represented.]

---

## Index

### `{filename}.md`

- **Title:** [document heading]
- **Date:** YYYY-MM-DD
- **Type:** [Walkthrough | Plan | Patch | ...]
- **Outcome:** [Complete | Accepted | Rejected | Superseded | Abandoned | No action | Unclear] — [short clause]
- **Summary:** [1-2 sentences]
- **Touched:** `path/one`, `path/two` (or `—`)
- **Keywords:** [10-20 terms: subject, components, technology, symptoms, synonyms, concepts]
- **Related:** `other-projex-filename.md` (or `—`)

### `{next-filename}.md`

- ...

---

## Notes

- [Any notable patterns across the archived documents]
- [Any documents that were unusual or worth flagging for future reference]
```

**Sorting:** Sort the index entries by filename ascending (alphabetical, which is chronological by the date prefix).

**Why blocks, not a table:** each entry is a self-contained searchable unit — a grep or semantic hit on any single field returns the whole entry with its filename attached. A nine-column table would not survive rendering or reading.

### 5. PRESENT THE ARCHIVE INDEX

Surface the archive index file path, the number of files summarized, and a brief summary to the user. **Do not commit or remove files yet.** Wait — proceed with committing and file removal only when the user explicitly requests it.

**This step requires user confirmation before continuing** — file removal is irreversible outside of git.

When the user requests to proceed:

**Step 5a — commit the archive index:**

```bash
{projex-scripts}/stage-n-commit.{sh|ps1} <repo-root> "projex(archive): create archive index for {scope}" .projex/closed/{yymmddhhmm}-{scope}-archive.md
```

Verify the commit succeeded before proceeding to file removal.

**Step 5b — remove the archived files:**

Delete each individual file that was archived (every `.md` file in the folder **except** the newly created archive):

```bash
git rm .projex/closed/{filename1}.md
git rm .projex/closed/{filename2}.md
# ... one per file
```

> **Never use `git rm .projex/closed/*.md`** — always list files explicitly. Only remove files from the list collected in step 2. Existing `-archive.md` files are never removed.

Commit the deletions:

```bash
{projex-scripts}/stage-n-commit.{sh|ps1} <repo-root> "projex(archive): remove archived files from {scope}" .projex/closed/{filename1}.md .projex/closed/{filename2}.md
```

> **Note:** `stage-n-commit` stages the listed files before committing. Files already `git rm`'d (absent from working tree and index) are skipped at the staging step — their deletions are already staged and are included in the commit. The script provides atomic rollback if the commit fails.

Verify the commit. The folder should now contain only the archive index file.

---

## OUTPUT

This workflow produces:
- A single archive index at `.projex/closed/{yymmddhhmm}-{scope}-archive.md`
- All previously individual closed files removed from `.projex/closed/`

**Folder state after archiving:**
```
.projex/
└── closed/
    └── {yymmddhhmm}-{scope}-archive.md    ← only file remaining
```

---

## QUALITY CHECKLIST

- [ ] Every `.md` file in `closed/` is represented in the index (except the archive itself)
- [ ] Every entry carries all nine fields — unavailable ones marked `—`, never silently dropped
- [ ] Each entry has a meaningful summary (not just the filename or title repeated)
- [ ] Outcome states what actually happened, not just the lifecycle word
- [ ] `Touched` uses repo-relative paths only — no absolute or external paths
- [ ] `Related` filenames actually exist (in this archive, elsewhere in `.projex/`, or in git history)
- [ ] Every entry carries at least 10 keywords, spanning subject, components, technology, symptoms, synonyms, and concepts — a 5-term entry is under-populated, redo it
- [ ] Keywords are specific and grounded — avoid generic terms like "projex" or "file", avoid terms the document does not support, and avoid workflow type names (plan, walkthrough, patch, evaluation, review, audit, log, memo, scan, exploration, guide, etc.) — the type is its own field
- [ ] Archive file committed before individual files are removed
- [ ] No individual files remain except the archive

---

## NOTES

- Archive does not destroy information — it compresses it. The filename is preserved, so a full document can be recovered from git history if needed
- Err on the side of more detail per entry. An archive is written once and read many times; a thin entry costs a future agent a git-history excavation, while a verbose one costs a few lines of the index
- If multiple `.projex/closed/` folders exist (e.g. `docs/.projex/closed/` and `src/.projex/closed/`), archive each independently with its own invocation
- Parallelization is optional but recommended for large `closed/` folders (>10 files). At the cheap tier the marginal cost of an extra sub-agent is small, so prefer one per file over batching — batching mainly trades quality for a saving that is not worth much here
- The archive itself is never archived — it stays as the permanent record for that `closed/` folder until manually superseded
- Use relative paths when referencing files
