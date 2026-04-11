---
name: projex-framework
description: When these mentioned:`close-projex``eval-projex``execute-projex``plan-projex``propose-projex``review-projex``explore-projex``redteam-projex``audit-projex``interview-projex``patch-projex``simulate-projex``navigate-projex``map-projex``guide-projex``imagine-projex``log-projex``define-projex``archive-projex``scan-projex``memo-projex`, load both this skill and a file with that exact name (located besides this SKILL.md).
---

Projex are self-contained unit markdown documents in folders named "projex". Types:

- **Proposal** — Directional: "what if we go this way?" with trade-offs, approaches, and impact. Draft → Review → Accepted/Rejected. WORKFLOW -> @./propose-projex.md
- **Plan** — Actionable task spec: WHAT needs doing and HOW (exact file changes), with clear scope and acceptance criteria. WORKFLOW -> @./plan-projex.md | EXECUTION -> @./execute-projex.md
- **Evaluation** — Open-ended analysis of any question, idea, or solution. Broadest analytical tool — no fixed framing. Unlike Proposal (directional) or Exploration (status-quo-grounded). WORKFLOW -> @./eval-projex.md
- **Review** — Inspection of existing projex against current status quo: is it still valid, complete, accurate? Challenges the projex from a high-level, bigger-picture perspective. WORKFLOW -> @./review-projex.md
- **Red Team** — Adversarial analysis: challenges assumptions, finds weaknesses, exploits edge cases. Attacks from each stakeholder role's perspective. Assumes wrong until proven right. WORKFLOW -> @./redteam-projex.md
- **Audit** — Rigorous validation of completed work: cross-references claims against actual artifacts/evidence. Discovers undocumented issues and gaps. WORKFLOW -> @./audit-projex.md
- **Interview** — Interactive Q&A in rounds (3-5 questions each), asked one-by-one. Full transcript logging. READ-ONLY: only the interview document is written. WORKFLOW -> @./interview-projex.md
- **Walkthrough** — Post-execution record authored after every Plan execution. Detailed changes (file-level), criteria checklist with proof. WORKFLOW -> @./close-projex.md
- **Log** — Standalone change record: observes staged changes or commits, documents what changed and why. Born closed. No plan or branch lifecycle required. WORKFLOW -> @./log-projex.md
- **Memo** — Lightweight capture of a raw source (user quote, idea, issue, deferred objective) with whatever context the agent already has. No research — just record. Active until consumed. WORKFLOW -> @./memo-projex.md
- **Patch** — Quick-action for small, well-understood changes. Skips Plan → Execute → Close — born closed. Can execute specific objectives from existing plans. Escalates if complexity exceeds threshold. WORKFLOW -> @./patch-projex.md
- **Simulation** — Disposable execution: makes changes, observes outcomes, rolls back everything. Only the report survives. No irreversible actions. Can trial-run plans or "what if" scenarios. WORKFLOW -> @./simulate-projex.md
- **Definition** — Declarative specification of WHAT an entity is: identity, boundaries, properties, constraints, relationships. Living document — revisited to deepen. Never closed. WORKFLOW -> @./define-projex.md
- **Navigation** — Living roadmap at any scale. Continuously revised each invocation. Nestable. Never closed. WORKFLOW -> @./navigate-projex.md
- **Map** — Living structural index of directories/key files. Incrementally built, scope-flexible. Never closed. WORKFLOW -> @./map-projex.md
- **Scan** — Exhaustive inventory of everything connected to a subject — precise `file:ln` lists with full coverage. No analysis, no recommendations. Born closed. WORKFLOW -> @./scan-projex.md
- **Exploration** — Status-quo-grounded investigation: map what exists, how it works, and why. Unlike Eval (open-ended) or Proposal (directional). WORKFLOW -> @./explore-projex.md
- **Guide** — Curated reading path for human learners. Phased steps with focus cues and takeaways. Sources span code, docs, specs, external pages. Closed by default. WORKFLOW -> @./guide-projex.md
- **Imagination** — Generative: takes a seed (idea, essence, principle) and grows it into rich, detailed vision. Expands possibility space, fills in texture, surfaces creative challenges. Unlike Eval (analytical) or Proposal (directional). WORKFLOW -> @./imagine-projex.md
- **Archive** — Compresses all files in `.projex/closed/` into a single index document (summary + keywords per file), then removes the originals. Born closed. Parallelizes summarization with sub-agents. WORKFLOW -> @./archive-projex.md

## Authoring

File naming: `{yymmddhhmm}-{projex-name}-{projex-type}.md`

- Cross-reference related projex in all involved documents
- Front-load key info for quick assessment at a glance
- **Reference by filename, not path** — Projex files move between folders (active → closed → archived), so absolute/relative paths break. Use the filename alone whenever you try to reference any projex in projex files: `2602081430-virtual-checkpoint-token-impl-doc-plan.md`, not `../../../impl/.projex/2602081430-virtual-checkpoint-token-impl-doc-plan.md`. Filenames are unique by date-prefix convention.

### Dehydrate

All projex output uses the densest form that fully preserves semantic and technical content, while keeping text grammatically parseable. Fragments are fine; ungrammatical grunt-speak is not. This is not a mode — it is how projex documents are written.

**Techniques:**

- **Drop filler words** — remove articles, prepositions, connectives where meaning survives without them
  - `"The parser module is responsible for converting the input stream into an AST"` → `"Parser module: converts input stream → AST"`
- **Short synonyms** — prefer the shortest word that carries the same meaning
  - `"implement a solution for"` → `"fix"` | `"extensive"` → `"big"` | `"in order to"` → `"to"` | `"at this point in time"` → `"now"` | `"utilize"` → `"use"`
- **Key-value shorthand** — replace narrative with `key: value` structure
  - `"The migration is currently blocked because the schema validator has not been updated"` → `"Migration: blocked — schema validator not updated"`
- **Finding pattern** — for observations/steps, use `[thing] [action] [reason]. [next step].`
  - `"Auth middleware rejects valid tokens — expiry check uses < not <=. Fix: swap operator."`
- **Symbolic compression** — `→` (produces/becomes), `←` (sourced from), `✓/✗` (pass/fail), `|` (or/alternatives), `~` (approximately)
- **Inline lists** — for items under ~5 words each, use `|` separators instead of bullet lists
  - `"Affected: auth module | session store | token validator"`
- **No transitions** — omit "Moving on to..." / "Now that we've covered X..."
- **Compressed headers** — strip filler from section titles
  - `"## Analysis of the Current Authentication State"` → `"## Auth Current State"`
- **Abbreviate when unambiguous** — impl, config, auth, repo, fn, param, dep, req, res, spec, DB (define on first use if non-standard)

**Preserve exact — never dehydrate these:**

- Technical terms, identifiers, API names, file paths
- Code blocks (unchanged)
- Error messages (quote verbatim)
- Version numbers, commit SHAs, line numbers

**Clarity carve-outs — drop dehydration for:**

- Security warnings and irreversible-action confirmations
- Multi-step sequences where fragment order could be misread
- Sections aimed at a confused or first-time reader

Resume dehydration once the clarity-critical section ends.

**Relationship to De-slop:** Dehydrate governs how content is written. De-slop catches filler that slipped through anyway. Both apply — Dehydrate is the standing register, De-slop is the safety net.

### De-slop (optional final pass)

Before finalizing any generated projex document, re-read it as a reader — not as the agent that wrote it — and strip:

- **Agent self-talk** — "I'll now...", "Let me analyze...", "As I mentioned...", "This step will..."
- **Throat-clearing** — "Note that...", "It's worth mentioning...", "It's important to..."
- **Redundant restatements** — content that repeats what the previous sentence or section already said
- **Hollow hedging** — "may potentially", "could possibly", "in some cases might"
- **Unfilled template artifacts** — leftover placeholder text, example labels, or structural scaffolding that wasn't replaced with real content

The document is an artifact for humans and future agents to act on — not a transcript of the writing process. If a sentence adds no information a reader couldn't infer, cut it.

This pass is **optional**: apply it when the draft reads like it was narrated rather than written, or when sections are padded. Skip it when the draft is already tight.

## Organizing

Files live in `.projex/` folders in one or more paths (each dedicated to a individual domain/module/components/area/scope, etc.). Location in projex folders reflects state:
- Active → `.projex/`
- Closed → `.projex/closed/`
- Archived → `.projex/archived/`
- Abandoned → `.projex/abandoned/` (or deleted)

A repo may have multiple `.projex/` folders scoped to different areas (e.g., `docs/.projex/`, `src/.projex/`). Each is independently managed. New projex should not cross area boundaries or violate dependencies, for example a language spec update projex should not touch runtime implementation, and vice versa.

```
your-repo/
├── .projex/              # Master projexs
│   ├── closed/
│   └── ...
├── docs/.projex/         # Doc-scoped projexs
├── src/.projex/          # Src-scoped projexs
└── ...
```

## Workflow

Workflow specs are actions invoked in verb sense:

- `/propose-projex.md I want to add XXX feature.`
- `/eval-projex.md Does current spec compatible with this proposal?` or `/eval-projex.md What can be improved in the current implementation?`
- `/plan-projex.md Update current impl to keep up with latest specs.` or `/plan-projex.md @2607311430-database-service-refactor-proposal.md`
- `/review-projex.md @2607311430-language-macro-syntax-change-proposal.md`
- `/redteam-projex.md @2607311430-auth-system-plan.md`
- `/audit-projex.md the database migration we just finished`
- `/interview-projex.md authentication system design`
- `/patch-projex.md Fix the off-by-one error in the parser loop` or `/patch-projex.md Execute objective 2 of @2602011430-api-cleanup-plan.md`
- `/simulate-projex.md What happens if we remove the legacy compatibility layer?`
- `/navigate-projex.md Game engine project roadmap` or `/navigate-projex.md @2602011430-engine-roadmap-nav.md`
- `/define-projex.md The authentication subsystem` or `/define-projex.md @2602151430-auth-subsystem-def.md expand session lifecycle`
- `/log-projex.md HEAD~3..HEAD` or `/log-projex.md` (staged changes)
- `/map-projex.md Whole project structure`
- `/guide-projex.md Understand our authentication system end-to-end`
- `/imagine-projex.md What would a plugin system for this framework look like?`
- `/execute-projex.md @2607311430-language-macro-syntax-change-plan.md`
- `/close-projex.md` after user reviewed execution results

## Auxiliary Artifact Commit Policy

**Auxiliary workflows** (all workflows except execute, close, patch, and simulate) produce artifacts — documents, reports, definitions, maps, logs, memos, scans — but **do not commit them automatically**. The workflow creates and presents the artifact; committing happens only when the user explicitly requests it.

Auxiliary workflows: propose, plan, eval, review, redteam, audit, interview, guide, explore, imagine, scan, log, memo, map, navigate, define, archive.

Execute, close, patch, and **simulate** are exempt — they commit as a structural requirement of their lifecycle. For simulate specifically: the ephemeral branch is always discarded and the report is the sole surviving artifact; committing it completes the simulation rather than being an incidental save.

**Pattern for auxiliary workflows:**
1. Create the artifact file
2. Present it to the user (surface path, summary, key content)
3. Wait — commit only if the user explicitly requests it (e.g., "commit this", "save it", "push it")

The commit commands shown in auxiliary workflow docs are **reference templates**, not automatic steps.

---

## Git Integration

The **Execute → Walkthrough** cycle uses an ephemeral branch for isolation and clean rollback.

```
[base branch] ── execute-projex ──> [projex/{yymmddhhmm}-{plan-name}] ── close-projex ──> [merge back]
```

1. `/execute-projex.md` creates ephemeral branch from current HEAD
2. All implementation happens in the ephemeral branch
3. `/close-projex.md` finalizes: squash merge (default), merge, rebase, or abandon

**Prerequisite:** Plan must be committed to base branch before execution — ensures plans survive abandoned executions and are reviewable independently.

### Repo Resolution

When a projex file is referenced (`@<file>`), **derive the target repo from that file's path** — `cd` to its directory and `git rev-parse --show-toplevel` from there. This is the first action, before any other git commands or file reads. The projex file's location is the source of truth; never rely on the session's initial cwd. **All git commands for the rest of the workflow must run from this repo root.**

When no file reference is given, infer the target repo from context (cwd, recent mentions, project structure).

### Utility Scripts

Scripts live next to this file as `.{sh|ps1}`. All workflow examples use `{projex-scripts}/` as a placeholder — substitute the absolute path to the directory containing this `SKILL.md` (e.g., if loaded from `/home/user/projex/SKILL.md`, then `{projex-scripts}/projex-commit.{sh|ps1}`).

#### Committing

`projex-commit` — stages explicit files and commits atomically with rollback on failure.

```
{projex-scripts}/projex-commit.{sh|ps1} <repo-root> "commit message" ["--flag [value]" ...] file1 [file2 ...]
```

Any argument starting with `--` is passed to `git commit` as an extra flag. A flag+value pair can be supplied as one quoted string (e.g. `"--trailer Co-authored-by: Claude"`). File paths never start with `--`, so no separator is needed.

#### Selective Staging

`stage-by-pattern` — filters unstaged diff through a regex and stages only matching +/- lines. Useful for structured changes (renames, signature updates) where the diff is highly regular.

```
{projex-scripts}/stage-by-pattern.{sh|ps1} <repo-root> <pattern> [-v] [-n] [-- file1 file2 ...]
```

`-v` inverts (stage everything except matches). `-n` dry-runs (prints filtered diff). For replacement pairs (`-old`/`+new`), the pattern should match both sides — e.g. `'getFoo|getBar'` not just `'getBar'`.

#### Moving

`move-n-stage` — batch `git mv` with rollback on failure. Stages the moves but does not commit.

```
{projex-scripts}/move-n-stage.{sh|ps1} <repo-root> src1 dst1 [src2 dst2 ...]
```

Arguments are src/dst pairs. On any failure, all completed moves are rolled back in reverse order.

#### Deleting

`del-n-stage` — batch `git rm` with rollback on failure. Stages the deletions but does not commit.

```
{projex-scripts}/del-n-stage.{sh|ps1} <repo-root> file1 [file2 ...]
```

On any failure, all completed deletions are rolled back in reverse order from temp backups. Untracked files are removed from disk only (no staging effect).

#### Reading Files

`read_file` — line-numbered file reader util, ONLY use this when you don't have any tool to read file besides raw shell commands.

```
{projex-scripts}/read_file.ps1 -Path <file> [-From <n>] [-To <n>] [-Pattern <p1>,<p2>,...] [-Context <n>]
```

- **No flags**: dumps entire file with zero-padded line numbers (`01  using System;`)
- **`-From` / `-To`**: restricts output (and search) to a line range. Only reads up to `-To` lines from disk — safe for large files
- **`-Pattern`**: searches for regex patterns within the range (or whole file). Outputs matching lines plus `-Context` surrounding lines (default 3). Non-contiguous groups separated by `---`
- **Combined**: `-From 50 -To 200 -Pattern "TODO","FIXME" -Context 5` searches lines 50–200, shows matches with 5 lines of context

#### Worktree Creation

`projex-worktree` — creates a worktree in a sibling directory `{repo-name}.projexwt/` next to the repo.

```
{projex-scripts}/projex-worktree.{sh|ps1} <repo-root> <branch-name> [<base-ref>]
```

The worktree is created at `{repo-name}.projexwt/<branch-suffix>/` (a sibling directory next to the repo) where `<branch-suffix>` is the last path segment of `<branch-name>`.

#### Branch Finalization

- `projex-squash-close` — Squash-merge ephemeral → base, delete ephemeral. Usage: `{projex-scripts}/projex-squash-close.{sh|ps1} <repo-root> <base> <ephemeral> "msg" [--worktree]`
- `projex-merge-close` — Merge with full history → base, delete ephemeral. Usage: `{projex-scripts}/projex-merge-close.{sh|ps1} <repo-root> <base> <ephemeral> "msg" [--worktree]`
- `projex-abandon` — Checkout base and force-delete ephemeral. Usage: `{projex-scripts}/projex-abandon.{sh|ps1} <repo-root> <base> <ephemeral> [--worktree]`

Each validates inputs, reports failure with state context, and rolls back on error.

When `--worktree` is passed, the script removes the worktree at `{repo-name}.projexwt/<branch-suffix>` instead of checking out base. The main working directory must already be on the base branch (which it is — worktree mode never leaves it).

### Git Operation Discipline

For operations not covered by the scripts above (read-only queries, `git checkout -b`, `git stash`), use raw git commands with these rules:

**CRITICAL: Different git operation types (add, commit, checkout, branch, merge, rebase, stash) must be separate tool calls. Never combine them — not with `&&`, not with `;`, not as parallel calls.**

- **One operation type per call** — `git add` in one call, read its output, then `git commit` in the next call. A single `git add` with multiple file arguments is fine, but add and commit must never share a call.
- **Read output before proceeding** — After each call, actually read its output and confirm it succeeded. Do not fire-and-forget.
- **Stop on failure** — If any git operation fails, address it before continuing
- **Stage by explicit path** — `git add <file> ...` by exact path. Never `git add .`, `git add -A`, `git add -u`, directories, or wildcards
- **Never mix scripts with raw git** — When a utility script covers an operation (`projex-commit`, `move-n-stage`, `del-n-stage`, `stage-by-pattern`), use the script exclusively. Do not combine script calls with raw `git add`, `git mv`, `git rm`, `git reset`, etc. in the same logical operation — the scripts manage their own rollback, but raw commands outside them are unmanaged and break atomicity
- **Stash discipline** — If you `git stash` to get a clean working state, **log it** in the execution log so it is not forgotten. Stashed changes are restored during `/close-projex` after branch finalization

### Worktree Mode (Optional)

Worktree mode creates ephemeral branches as separate working directories in `{repo-name}.projexwt/` (sibling to repo) instead of switching the main working directory via `git checkout`. The main directory stays on the base branch throughout.

**Auto-determined by plan-projex:** The planning workflow checks for uncommitted changes, active `projex/*` execution branches, and scope of changes, setting `> **Worktree:** Yes` when dirty state, parallel execution, or large/many-file changes are detected. The user can override the auto-determined value in the plan draft. Simulations default to worktree mode.

**How it works:**
- `projex-worktree` creates the worktree in a sibling directory
- All execution happens in the worktree directory (`{repo-name}.projexwt/<name>/`)
- `projex-commit` works unchanged (`-C` accepts worktree paths)
- Finalization scripts receive `--worktree` flag to remove the worktree instead of checking out base
- No stashing needed — the base branch working directory is never touched

**Benefits over checkout mode:**
- No clean-state requirement at execution start
- No working directory disruption (editors/IDEs unaffected)
- Parallel executions possible (multiple worktrees)
- Crash-safe — main directory always on base branch

**Worktrees live outside the repo** in a sibling directory `{repo-name}.projexwt/`, so no gitignore entry is needed.

### Notes

- Execute/Walkthrough and Simulation use ephemeral branches
- Simulation branches (`.projex/sim/`) always discarded — only report committed to base
- Other workflows operate on current branch, committed normally
- Walkthrough committed as final commit before merge

---

## NOTES

### AVOID ABSOLUTE PATHS
Use file paths RELATIVE to project root. REDACT external paths.

### NO PARALLEL EXPLORATION WITH WORKFLOWS
Workflow files (ex: execute-projex) may have requirements before starting, fully comply before reading stuff into context.