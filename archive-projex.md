---
description: This workflow compresses all files in `projex/closed/` into a single **Archive** index document — summarizing each with a short description and keywords — then clears the folder and places the archive inside it. (This is part of @projex-framework skill. It is a MUST to load the skill first.)
---

## PURPOSE

Archives shrink the `projex/closed/` folder from many files into one compact index. Each closed projex gets a one-line summary and a keyword set, making the history searchable without the clutter of full documents.

**Key characteristics:**
- Reads every file in `projex/closed/` and produces a short description + keywords per file
- Summarization can be parallelized across files using sub-agents
- Outputs a single archive index document
- Clears the individual files from `projex/closed/` after archiving
- Places the archive index into `projex/closed/` as its sole artifact

**Born closed** — the archive index lands directly in `projex/closed/`.

---

## INVOCATION

```
/archive-projex
/archive-projex projex/closed/          # explicit path (if multiple closed/ folders exist)
```

---

## WORKFLOW STEPS

### 1. IDENTIFY TARGET FOLDER

Determine which `projex/closed/` folder to archive:

- If invoked without arguments, default to `projex/closed/` relative to the current repo root
- If a path is given, use that folder
- Confirm the repo root first: `git rev-parse --show-toplevel`

### 2. SCAN CLOSED FOLDER

List all `.md` files in the target `closed/` folder, **excluding any that end in `-archive.md`**:

```bash
ls projex/closed/*.md
# then filter out *-archive.md files — these are never processed
```

**If the folder is empty or has no eligible `.md` files:** inform the user and stop — nothing to archive.

Collect the full list of non-archive files to process. Existing archive files are left untouched throughout. This list drives the next step.

### 3. SUMMARIZE EACH FILE

For each file in the list, extract:

- **Filename** — the file's name only (not path), e.g. `20260115-auth-session-timeout-walkthrough.md`
- **Summary** — 1–2 sentence description of what this document is about (inferred from its content)
- **Keywords** — 5–10 comma-separated terms covering the subject, affected components, and key concepts

**Parallelization:** When there are multiple files, summarize them in parallel using sub-agents — one sub-agent per file or in small batches. Each sub-agent reads the file and returns the fields above. Collect all results before proceeding.

> **Sub-agent prompt template:**
> "Read this projex file and return: filename, summary (1-2 sentences describing what this document is about and what it accomplished or found), keywords (5-10 comma-separated terms covering subject matter, affected areas, and key concepts). File: `{filepath}`"

### 4. DRAFT THE ARCHIVE DOCUMENT

Create: `{yyyymmdd}-{scope}-archive.md` directly in the target `projex/closed/` folder.

Use today's date for `{yyyymmdd}`. Use the folder's scope name for `{scope}` (e.g. `projex-closed` for root `projex/closed/`).

**Template:**

```markdown
# Archive: [Scope]

> **Created:** YYYY-MM-DD
> **Scope:** [which projex/closed/ this covers]
> **Files Archived:** [N]

---

## Summary

[1-2 sentences: what period/scope this archive covers and what kinds of work are represented.]

---

## Index

| Filename | Summary | Keywords |
|----------|---------|----------|
| `filename.md` | [1-2 sentence summary] | keyword1, keyword2, ... |
| ... | ... | ... |

---

## Notes

- [Any notable patterns across the archived documents]
- [Any documents that were unusual or worth flagging for future reference]
```

**Sorting:** Sort the index table by filename ascending (alphabetical, which is chronological by the date prefix).

### 5. COMMIT THE ARCHIVE

Stage and commit the archive document:

```bash
git add projex/closed/{yyyymmdd}-{scope}-archive.md
git commit -m "projex(archive): create archive index for {scope}"
```

Verify the commit succeeded before proceeding.

### 6. REMOVE ARCHIVED FILES

Delete each individual file that was archived (every `.md` file in the folder **except** the newly created archive):

```bash
git rm projex/closed/{filename1}.md
git rm projex/closed/{filename2}.md
# ... one per file
```

> **Never use `git rm projex/closed/*.md`** — always list files explicitly. Only remove files from the list collected in step 2. Existing `-archive.md` files are never removed.

Commit the deletions:

```bash
git commit -m "projex(archive): remove archived files from {scope}"
```

Verify the commit. The folder should now contain only the archive index file.

---

## OUTPUT

This workflow produces:
- A single archive index at `projex/closed/{yyyymmdd}-{scope}-archive.md`
- All previously individual closed files removed from `projex/closed/`

**Folder state after archiving:**
```
projex/
└── closed/
    └── {yyyymmdd}-{scope}-archive.md    ← only file remaining
```

---

## QUALITY CHECKLIST

- [ ] Every `.md` file in `closed/` is represented in the index (except the archive itself)
- [ ] Each row has a meaningful summary (not just the filename repeated)
- [ ] Keywords are specific — avoid generic terms like "projex" or "file"
- [ ] Archive file committed before individual files are removed
- [ ] No individual files remain except the archive

---

## NOTES

- Archive does not destroy information — it compresses it. The filename is preserved, so a full document can be recovered from git history if needed
- If multiple `projex/closed/` folders exist (e.g. `docs/projex/closed/` and `src/projex/closed/`), archive each independently with its own invocation
- Parallelization is optional but recommended for large `closed/` folders (>10 files)
- The archive itself is never archived — it stays as the permanent record for that `closed/` folder until manually superseded
- Use relative paths when referencing files
