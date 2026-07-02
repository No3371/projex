---
description: This workflow guides the creation of **Log** projex documents — detailed records of file changes already made (staged or in given commits), authored by observing diffs and concluding what happened. (This is part of @projex-framework skill. It is a MUST to load the skill first.)
---

## PURPOSE

Log documents capture what changed and why, derived from actual diffs. Unlike Walkthroughs (which close a Plan execution and finalize a branch), Logs are standalone — they observe changes that already exist and produce a detailed record. No plan, no branch lifecycle, no criteria verification required.

**Key characteristics:**
- **Observation-first** — reads diffs to understand what happened, rather than narrating a plan's execution
- Standalone — no source plan or ephemeral branch required
- Born closed — the log is the final artifact, placed directly in `.projex/closed/`
- Works on staged changes, commit ranges, or individual commits

**Contrast with Walkthrough (close-projex):**
- **Walkthrough** — authored after Plan execution; cross-references plan steps, verifies criteria, finalizes branch
- **Log** — standalone change record; observes diffs as-is, draws conclusions, no plan or branch lifecycle involved

**When to use:**
- Changes were made outside the Plan→Execute→Close cycle (ad-hoc work, hotfixes, external contributions)
- You want a record of what a set of commits accomplished before moving on
- Onboarding to unfamiliar recent changes — "what happened here?"
- Documenting staged changes before committing, to capture intent alongside the diff

---

## INVOCATION

```
/log-projex.md                              # log currently staged changes
/log-projex.md HEAD~3..HEAD                 # log a commit range
/log-projex.md abc1234                      # log a single commit
/log-projex.md abc1234..def5678             # log a commit range
/log-projex.md --branch feature/foo         # log all commits on branch since divergence from current
```

---

## WORKFLOW STEPS

### 1. RESOLVE THE CHANGE SET

Determine what to diff based on invocation:

| Input | Diff command |
|-------|-------------|
| *(none — staged changes)* | `git diff --cached` |
| Single commit `abc1234` | `git show abc1234` |
| Commit range `A..B` | `git diff A..B` and `git log --oneline A..B` |
| Branch `--branch X` | Find merge-base: `git merge-base HEAD X`, then `git diff {base}..X` and `git log --oneline {base}..X` |

**Verify the change set is non-empty.** If there are no changes, inform the user and stop.

```bash
# Example: staged changes
git diff --cached --stat
git diff --cached

# Example: commit range
git log --oneline A..B
git diff --stat A..B
git diff A..B
```

### 2. SURVEY THE CHANGES

Read the full diff carefully. For each file changed, determine:

1. **What changed** — created, modified, deleted, renamed
2. **What the change does** — read the diff hunks; understand the before/after
3. **Why it was likely done** — infer purpose from context (commit messages, surrounding code, naming)
4. **How it connects** — which changes are related, what's the thread tying them together

> **Do not fabricate intent.** If the reason for a change is unclear, say so. Use commit messages and code context as evidence, not speculation.

### 3. DISCUSS WITH USER (if needed)

For ambiguous changes:

- "These 3 files seem related to [X] but `path/to/other.ext` doesn't fit the pattern — do you know the context?"
- "The commit messages are sparse — should I infer intent from the code, or do you want to annotate?"

For clear change sets, proceed directly to drafting.

### 4. DRAFT THE LOG

```bash
{projex-scripts}/new-projex.{sh|ps1} <repo-root> log "{log-name}" <projex-folder>
```

**Template Structure:**

```markdown
# Log: [Descriptive Title]

> **Date:** YYYY-MM-DD
> **Author:** [name or agent]
> **Source:** [staged changes / commit range `A..B` / branch `X`]
> **Scope:** [which repo or area these changes affect]

---

## Summary

[2-4 sentences: What these changes accomplish as a whole. The "so what" — not just a list of files, but what the collective change means.]

---

## Change Detail

### [Group Title — e.g., "Parser error recovery" or "API endpoint cleanup"]

[1-2 sentences: What this group of changes does and why.]

| File | Type | Lines | Description |
|------|------|-------|-------------|
| `path/to/file.ext` | Modified | 45-67, 120-135 | [What changed and why] |
| `path/to/new.ext` | Created | — | [What this file is for] |

[If a change warrants more detail than a table row, expand below:]

**`path/to/file.ext`** — [Detailed explanation of a non-obvious change, referencing specific hunks or logic shifts.]

---

### [Next Group Title]

[Same structure — group related changes together.]

---

## Observations

### Patterns

- [Patterns noticed across the changes — e.g., "All modified files follow the same error-handling refactor"]

### Risks / Concerns

- [Anything that looks risky, incomplete, or worth revisiting — e.g., "Migration added but no rollback path"]
- [Or: "None observed."]

### Open Questions

- [Anything the diff alone can't answer — e.g., "Why was `legacy_handler` deleted — is it still referenced elsewhere?"]
- [Or: "None."]

---

## Commit History

> Only included when logging commits (not staged changes).

| Hash | Message | Files |
|------|---------|-------|
| `abc1234` | [commit message] | [file count] |
| `def5678` | [commit message] | [file count] |

---

## Raw Stats

> Derived from `git diff --stat`

​```
[paste git diff --stat output here]
​```
```

**Drafting guidelines:**
- **Group changes by purpose, not by file path** — readers care about "what was accomplished," not alphabetical file order
- **Lead with the summary** — the first thing a reader sees should answer "what did these changes do?"
- **Be specific in descriptions** — "Updated error handling" is useless; "Replaced panic-on-invalid-input with Result return + caller-site match" is useful
- **Distinguish observation from inference** — if you're guessing at intent, say "likely" or "appears to"
- **Include line ranges** for modified files so readers can jump to the relevant code
- **Keep Observations honest** — risks and open questions are valuable, not signs of failure

### 5. PRESENT THE LOG

Surface the log file path and summary to the user. **Do not commit.** Wait — commit only when the user explicitly requests it.

When the user requests a commit:

```bash
{projex-scripts}/stage-n-commit.{sh|ps1} <repo-root> "projex(log): {log-name}" .projex/closed/{yymmddhhmm}-{log-name}-log.md
```

---

## LOG PRINCIPLES

- **Observation, not narration** — the log records what the diffs show, not what someone planned to do. If a plan exists, reference it, but the log stands on its own
- **Group by purpose** — related changes across files belong together; a file-by-file listing buries the story
- **Honest about uncertainty** — if intent is unclear from the diff, say so rather than inventing a rationale
- **Born closed** — logs are final artifacts; they document a point-in-time snapshot of changes and are not revised
- **Lightweight when changes are small** — a 2-file change doesn't need the full template; scale the document to the change set. Omit empty sections

---

## FOLDER PLACEMENT

| State | Location |
|-------|----------|
| Complete (always) | `.projex/closed/` matching the change set's scope |

Logs are born closed — they go directly to `.projex/closed/`. They are never active or pending.

---

## NOTES

- Logs pair well with Patch — after a `/patch-projex` you can `/log-projex` to create a richer record than the patch's built-in summary
- For changes made during a Plan execution, prefer `/close-projex` instead — it provides the full walkthrough with criteria verification
- When logging a branch, the log does not merge or delete the branch — it only documents what's there
- Scale to the change set: a single-commit typo fix needs a few lines, not a multi-section document
- Use relative paths from the repo root when referencing files
