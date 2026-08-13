---
name: projex-framework
description: When these mentioned:`close-projex``eval-projex``execute-projex``do-projex``verify-projex``plan-projex``preplan-projex``propose-projex``review-projex``explore-projex``redteam-projex``stress-projex``audit-projex``interview-projex``coach-projex``patch-projex``revise-projex``debug-projex``navigate-projex``guide-projex``imagine-projex``define-projex``conclude-projex``archive-projex``scan-projex``memo-projex``orchestrate-projex``sprint-projex`, load both this skill and a file with that exact name (located besides this SKILL.md).
---

Projex are self-contained unit markdown documents in folders named ".projex". Types:

- **Proposal** — Directional: "what if we go this way?" with trade-offs, approaches, and impact. Draft → Review → Accepted/Rejected. WORKFLOW -> @./propose-projex.md
- **Plan** — Actionable task spec: WHAT needs doing and HOW (exact file changes), with clear scope and acceptance criteria. WORKFLOW -> @./plan-projex.md | EXECUTION -> @./execute-projex.md
- **Evaluation** — Open-ended analysis of any question, idea, or solution. Broadest analytical tool — no fixed framing. Unlike Proposal (directional) or Exploration (status-quo-grounded). WORKFLOW -> @./eval-projex.md
- **Review** — Inspection of existing projex against current status quo: is it still valid, complete, accurate? Challenges the projex from a high-level, bigger-picture perspective. WORKFLOW -> @./review-projex.md
- **Red Team** — Adversarial analysis: challenges assumptions, finds weaknesses, exploits edge cases. Attacks from each stakeholder role's perspective. Assumes wrong until proven right. WORKFLOW -> @./redteam-projex.md
- **Stress** — Adversarial analysis by attack angle: applies a fixed angle inventory (assumption, edge case, scale, time, …) directly to the subject's claims. No stakeholder modeling — suits algorithms, configs, single scripts, document arguments. WORKFLOW -> @./stress-projex.md
- **Audit** — Rigorous validation of completed work: cross-references claims against actual artifacts/evidence. Discovers undocumented issues and gaps. WORKFLOW -> @./audit-projex.md
- **Interview** — Interactive Q&A in rounds (3-5 questions each), asked one-by-one. Full transcript logging. READ-ONLY: only the interview document is written. WORKFLOW -> @./interview-projex.md
- **Coach** — Interactive judgment on any judgeable subject: collects via Q&A, states positions, hears pushback, converges to consensus or documented dissent. Unlike Interview (collects without judging), Red Team (unilateral), or Eval (agent alone). READ-ONLY: only the coach document is written. WORKFLOW -> @./coach-projex.md
- **Walkthrough** — Post-execution record authored after every Plan execution. Detailed changes (file-level), criteria checklist with proof. WORKFLOW -> @./close-projex.md
- **Memo** — Lightweight capture of a raw source (user quote, idea, issue, deferred objective) with whatever context the agent already has. No research — just record. Active until consumed. WORKFLOW -> @./memo-projex.md
- **Patch** — Quick-action for small, well-understood changes. Skips Plan → Execute → Close — born closed. Can execute specific objectives from existing plans. Escalates if complexity exceeds threshold. WORKFLOW -> @./patch-projex.md
- **Revise** (no doc type — edits any existing projex document) — Quick-action fix to a projex document's own content (Plan, Proposal, Definition, Nav, etc.) when new context makes part of it stale. Edits in place, logs the trigger. Unlike Patch (fixes code/implementation), Revise fixes the document's claims. Escalates to that document's own authoring workflow if the core content itself is wrong. WORKFLOW -> @./revise-projex.md
- **Preplan** — Fast disposable planning spike: hacks a representative path in an isolated worktree, observes decision-relevant evidence, discards all changes, and leaves a compact brief for Plan. Born closed. No irreversible actions. WORKFLOW -> @./preplan-projex.md
- **Debug** — Issue-bound investigation: confirms a concrete bug, enumerates hypotheses, iterates fix attempts in an isolated worktree until Resolved (fix squash-merged) or Exhausted (all imaginable cases ruled out, document handed back). Unlike Patch (known fix) or Preplan (always discards and never productionizes). WORKFLOW -> @./debug-projex.md
- **Definition** — Declarative specification of WHAT an entity is: identity, boundaries, properties, constraints, relationships. Living document — revisited to deepen. Never closed. WORKFLOW -> @./define-projex.md
- **Navigation** — Living roadmap at any scale. Continuously revised each invocation. Nestable. Born open, revised across many invocations → Closed when its goal is reached or a new roadmap supersedes it. WORKFLOW -> @./navigate-projex.md
- **Scan** — Exhaustive inventory of everything connected to a subject — precise `file:ln` lists with full coverage. No analysis, no recommendations. Born closed. WORKFLOW -> @./scan-projex.md
- **Exploration** — Status-quo-grounded investigation: map what exists, how it works, and why. Unlike Eval (open-ended) or Proposal (directional). WORKFLOW -> @./explore-projex.md
- **Guide** — Curated reading path for human learners. Phased steps with focus cues and takeaways. Sources span code, docs, specs, external pages. Closed by default. WORKFLOW -> @./guide-projex.md
- **Imagination** — Generative: takes a seed (idea, essence, principle) and grows it into rich, detailed vision. Expands possibility space, fills in texture, surfaces creative challenges. Unlike Eval (analytical) or Proposal (directional). WORKFLOW -> @./imagine-projex.md
- **Conclude** — Verified supersession: given a successor that crystallizes prior work (Definition, Nav, Plan, …), checks each source projex claim-by-claim (Captured / Overruled / Residue), stamps fully-consumed sources superseded and removes them (recoverable via git history; the report keeps filename + verdicts), and rewrites the successor's prior-artifact references into a do-not-consult ledger. Sources may be active or closed. Residue blocks retirement — no silent drops. Unlike Archive (mechanical compression), Conclude is judgment. Born closed. WORKFLOW -> @./conclude-projex.md
- **Archive** — Compresses all files in `.projex/closed/` into a single index document (summary + keywords per file), then removes the originals. Born closed. Parallelizes summarization with sub-agents. WORKFLOW -> @./archive-projex.md
- **Orchestration** — Agent-driven lifecycle: an orchestrating agent acts as the projex user, manages subagents through full workflow (Plan → Execute → Close or selected path) on behalf of a human. No standalone projex document — delegated workflow specs produce their own artifacts. Nestable one level: an orchestrator may hand a sub-chain to a nested orchestrator, which does not nest again. WORKFLOW -> @./orchestrate-projex.md


## Authoring

File naming: `{yymmddhhmm}-{projex-name}-{projex-type}.md`

- Cross-reference related projex in all involved documents
- Front-load key info for quick assessment at a glance
- **Reference by filename, not path** — Projex files move between folders (active → closed → archived), so absolute/relative paths break. Use the filename alone whenever you try to reference any projex in projex files: `2602081430-virtual-checkpoint-token-impl-doc-plan.md`, not `../../../impl/.projex/2602081430-virtual-checkpoint-token-impl-doc-plan.md`. Filenames are unique by date-prefix convention.
- **Note nav derivation** — Projex created from a nav must record `> **Nav:** {nav-filename}` near the top. This is the only signal close/patch uses to update the nav back.
- **Parent invariant** — every newly created projex has exactly one causal `> **Parent:**` header: `User`, `Orchestrator`, or a filename matching the projex naming grammar; legacy files may omit it. `new-projex` enforces creation.

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
- **Artifact, not transcript** — delete self-talk, template residue, and repeated claims.
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

## Lifecycle Status

Every projex document that carries a lifecycle Status field draws its value from ONE canonical vocabulary. Type-specific terminal meanings (Accepted, Rejected, Resolved, Stable, Concluded, Done, …) survive as an inline **outcome qualifier** on a canonical state — never as their own lifecycle stage.

### Canonical vocabulary

| State | Meaning | Folder |
| ------- | --------- | -------- |
| `Draft` | Authored, still changing, not yet reliable | `.projex/` |
| `Ready` | Finalized & actionable, not yet started (types with an execution phase only) | `.projex/` |
| `In Progress` | Actively being worked / executed | `.projex/` |
| `Blocked` | Stalled awaiting an external dependency; resumes when it clears | `.projex/` |
| `Escalated` | Agent exhausted its ability; handed back to a human to decide or take over | `.projex/` |
| `Complete` | Terminal — done | `.projex/closed/` |
| `Abandoned` | Terminal — dropped without completion | `.projex/abandoned/` |

`Blocked` waits on a *thing* (another task, a resource) and resumes automatically when it clears. `Escalated` waits on a *human judgment* the agent cannot make itself.

### Strict Status blockquote

Status is machine-readable via a single strict line — the `> **Status:**` blockquote. No YAML frontmatter; this blockquote is the one source of truth.

**Grammar:** `> **Status:** <state>` optionally followed by `(<outcome>)`, where `<state>` is exactly one canonical value.

```
> **Status:** In Progress
> **Status:** Complete (Accepted)
> **Status:** Escalated (Non-Repro)
```

One regex parses it: `^> \*\*Status:\*\* ([\w ]+?)(?: \((.+)\))?\s*$` → group 1 = state, group 2 = optional outcome.

### Exceptions

- **Never-closed type (Definition):** may sit at `Complete` while staying in `.projex/` rather than moving to `.projex/closed/`. `Complete` here means "current stable state"; it drops back to `In Progress` on revision.
- **Navigation:** holds `In Progress` for its entire open life — revisions are its work, and dormancy between revisions is not a state change. `Complete (Goal Reached)` / `Complete (Superseded)` are its only terminal states, set by its own closing workflow.
- **Per-item statuses are out of scope.** Objective status (`Success / Partial / Failed`) and per-target / per-question status (`Pending / In Progress / Done / Dropped`) are not document lifecycle. They use plain bold (not the `> **Status:**` blockquote) and are left untouched.

## Workflow

Workflow specs are actions invoked in verb sense:

- `/propose-projex.md I want to add XXX feature.`
- `/eval-projex.md Does current spec compatible with this proposal?` or `/eval-projex.md What can be improved in the current implementation?`
- `/plan-projex.md Update current impl to keep up with latest specs.` or `/plan-projex.md @2607311430-database-service-refactor-proposal.md`
- `/review-projex.md @2607311430-language-macro-syntax-change-proposal.md`
- `/redteam-projex.md @2607311430-auth-system-plan.md`
- `/stress-projex.md The retry logic in the sync script` or `/stress-projex.md @2607311430-parser-refactor-plan.md`
- `/audit-projex.md the database migration we just finished`
- `/interview-projex.md authentication system design`
- `/patch-projex.md Fix the off-by-one error in the parser loop` or `/patch-projex.md Execute objective 2 of @2602011430-api-cleanup-plan.md`
- `/revise-projex.md @2602011430-api-cleanup-plan.md Step 2 assumed Redis, it's actually Memcached` (Patch = fix code; Revise = fix what a projex document claims)
- `/preplan-projex.md Try the smallest raw-SQL replacement for one ORM query and map the real migration surface`
- `/debug-projex.md Login button does nothing on Safari iOS — works on Chrome/Firefox`
- `/navigate-projex.md Game engine project roadmap` or `/navigate-projex.md @2602011430-engine-roadmap-nav.md`
- `/define-projex.md The authentication subsystem` or `/define-projex.md @2602151430-auth-subsystem-def.md expand session lifecycle`
- `/guide-projex.md Understand our authentication system end-to-end`
- `/imagine-projex.md What would a plugin system for this framework look like?`
- `/execute-projex.md @2607311430-language-macro-syntax-change-plan.md`
- `/close-projex.md` after user reviewed execution results
- `/conclude-projex.md @2608041653-vertical-axis-model-def.md` or `/conclude-projex.md @{successor}.md @{source1}.md @{source2}.md`
- `/orchestrate-projex.md Add user authentication to the API` or `/orchestrate-projex.md Refactor the payment module per @2604031730-payment-cleanup-proposal.md`

## Auxiliary Artifact Commit Policy

**Auxiliary workflows** (all workflows except execute, close, patch, and preplan) produce artifacts — documents, reports, definitions, maps, logs, memos, scans — but **do not commit them automatically**. The workflow creates and presents the artifact; committing happens only when the user explicitly requests it.

Auxiliary workflows: propose, plan, eval, review, redteam, stress, audit, interview, guide, explore, imagine, scan, memo, map, navigate, define, conclude, archive.

Execute, close, patch, revise, and **preplan** are exempt — they commit as a structural requirement of their lifecycle. For preplan specifically: the disposable worktree is always discarded and the brief is the sole surviving artifact; committing it completes the preplan rather than being an incidental save.

**Pattern for auxiliary workflows:**

1. Create the artifact file
2. Present it to the user (surface path, summary, key content)
3. Wait — commit only if the user explicitly requests it (e.g., "commit this", "save it", "push it")

The commit commands shown in auxiliary workflow docs are **reference templates**, not automatic steps.

---

## Source Hygiene

**Subject.** *Source* = files a program or build consumes: code, config, schemas, scripts. *Comment* = a construct the language ignores at runtime. Prose files (`.md`, docs, specs) are shipped documentation — rule 1's promotion target — and are outside these rules unless a retrofit sweep names them. Bind every workflow that edits source (execute, do, patch, debug). Enforcement: `audit-projex.md` § Source Hygiene Pass.

1. **No projex references in sources** — no projex ID, filename, or section pointer in a comment. Projexs are authoring layer artifacts, and should be invisible in the product. **Promotion:** load-bearing rationale that exists only in a projex document belongs in a shipped doc (README, spec, ADR) — promotion is the only channel that survives archival compression. Referencing a *shipped* doc from a comment is fine; the ban is on workflow artifacts.
2. **Symbols, not line numbers** — name the function, const, or type; never `file:123` or bare `:123`. `file:ln` stays correct inside projex documents — they are point-in-time records.
3. **Present tense** — what the code does, not what it used to do. Live hazard: state the hazard, not the changelog.
4. **No plan shape in code** — no `// Step N:`, no `====` / `----` banners.
5. **Reassurance must warn** — "deliberate" / "by design" only with the rejected alternative and its consequence.
6. **Non-obvious decisions carry rationale** — a rejected alternative, surprising constraint, or don't-fix trap gets a self-contained comment. Naming none of the three is not compliance — a rationale comment that asserts without naming what it rejected is as much a violation as its absence.

**No density or length caps.** Long comment blocks are not a violation; thinning comments to reach zero findings is (rule 6).

---

## Substrate

Projex methods are domain-general; git is the **reference substrate**, not a requirement. The execution family needs four guarantees from whatever holds the work:

1. **Inspectable corpus** — the status quo can be read
2. **Edit mechanism** — the corpus can be changed
3. **Checkpoint + rollback** — changes can be isolated and discarded
4. **Provenance log** — what changed, when, why is recoverable

Git provides all four. Substrate determines available workflows:

| Substrate | Available |
| ----------- | ----------- |
| Files in a git repo (code, prose, any domain) | Full framework |
| Files, no git | All analytical workflows + revise/memo/define/nav. No execute/preplan/debug cycle — no rollback guarantee |
| Non-file domain (events, negotiations, physical work) | Analytical workflows + Field Mode cycle |

### No-VCS Mode

`.projex/` folder not inside a git repo: skip repo resolution and every commit/stage step; create and edit files directly (`new-projex` works without git — its printed commit hint does not apply). Naming, statuses, folder states (`closed/`, `archived/`, `abandoned/`) unchanged. Locators adapt to the medium — `doc § heading`, `page:para`, `URL#anchor` in place of `file:ln`.

### Field Mode

For plans whose actions the agent cannot perform (book the venue, file the application, run the negotiation): author the Plan normally → the human executes → the agent debriefs the human interview-style and writes the execution log from their account (entries marked human-reported) → Close records evidence from that log. Analytical workflows are unaffected — they never required the agent to act.

### Irreversibility Discipline

The Critical Git Rules generalize to every substrate: one state-changing operation at a time, read the outcome before the next; explicit scope per change — name what you touch, no wildcards; human confirmation before any destruction or unrecoverable step.

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

Scripts live next to this file as `.{sh|ps1}`. All workflow examples use `{projex-scripts}/` as a placeholder — substitute the absolute path to the directory containing this `SKILL.md` (e.g., if loaded from `/home/user/projex/SKILL.md`, then `{projex-scripts}/stage-n-commit.{sh|ps1}`).

#### Prechecks

`execute-precheck.{sh,ps1}` — execution validation: resolves the plan repository, current branch, and plan-relative path; reports committed/dirty warnings before an execution begins.

`close-precheck.{sh,ps1}` — report-only close-context discovery: resolves the plan and exactly one execution log, requires the recorded local base branch, emits schema v1 UTF-8 percent-encoded context/snapshot/commit/diff/inventory/stash/gate records, scans originating and recorded child `.projex` roots, and reports `PASS`, `PASS_WITH_WARNINGS`, `STALE`, or `ERROR`. It never authorizes close or mutates refs, index, worktrees, files, or stash state; consumers rerun on `STALE` and finalizers remain the enforcement backstop.

#### Committing

`stage-n-commit` — stages explicit files and commits atomically with rollback on failure.

```
{projex-scripts}/stage-n-commit.{sh|ps1} <repo-root> "commit message" ["--flag [value]" ...] file1 [file2 ...]
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

`projex-worktree` — creates a worktree in `{repo-name}/.projexwt/` inside the repo, and registers `.projexwt/` in the repo's `.git/info/exclude` so the parent's git status stays clean.

```
{projex-scripts}/projex-worktree.{sh|ps1} <repo-root> <branch-name> [<base-ref>]
```

The worktree is created at `{repo-name}/.projexwt/<branch-suffix>/` (inside the repo, so it stays in the editor workspace) where `<branch-suffix>` is the last path segment of `<branch-name>`.

#### Branch Finalization

- `projex-squash-close` — Squash-merge ephemeral → base, delete ephemeral. Usage: `{projex-scripts}/projex-squash-close.{sh|ps1} <repo-root> <base> <ephemeral> "msg" [--worktree] [--resolve-conflicts <paths>]`
- `projex-merge-close` — Merge with full history → base, delete ephemeral. Usage: `{projex-scripts}/projex-merge-close.{sh|ps1} <repo-root> <base> <ephemeral> "msg" [--worktree] [--resolve-conflicts <paths>]`
- `projex-rebase-close` — Rebase ephemeral onto base, fast-forward base, delete ephemeral. Usage: `{projex-scripts}/projex-rebase-close.{sh|ps1} <repo-root> <base> <ephemeral> [--worktree] [--resolve-conflicts <paths>]`
- `projex-abandon` — Checkout base and force-delete ephemeral. Usage: `{projex-scripts}/projex-abandon.{sh|ps1} <repo-root> <base> <ephemeral> [--worktree]`

Each validates inputs, reports failure with state context, and rolls back on error.

`--resolve-conflicts` (PowerShell: `-ResolveConflicts`) takes comma-separated repo-relative files or directory prefixes where conflicts are *anticipated*. If every conflicted path is covered, the operation is left in progress for the caller to resolve (exit 2) instead of being aborted; a conflict in any undeclared path still aborts and rolls back (exit 1). All three refuse to start on top of an unfinished merge or rebase rather than discarding a half-done resolution. See `close-projex.md` for the resume rules — merge and rebase close are re-runnable after resolution, squash close is not.

When `--worktree` is passed, the script removes the worktree at `{repo-name}/.projexwt/<branch-suffix>` instead of checking out base. The `<repo-root>` you pass must itself already have base checked out — it may be the main working directory or any other registered worktree, and the scripts now assert this rather than assuming it.

### Git Operation Discipline

For operations not covered by the scripts above (read-only queries, `git checkout -b`, `git stash`), use raw git commands with these rules:

**CRITICAL: Different git operation types (add, commit, checkout, branch, merge, rebase, stash) must be separate tool calls. Never combine them — not with `&&`, not with `;`, not as parallel calls.**

- **One operation type per call** — `git add` in one call, read its output, then `git commit` in the next call. A single `git add` with multiple file arguments is fine, but add and commit must never share a call.
- **Read output before proceeding** — After each call, actually read its output and confirm it succeeded. Do not fire-and-forget.
- **Stop on failure** — If any git operation fails, address it before continuing
- **Stage by explicit path** — `git add <file> ...` by exact path. Never `git add .`, `git add -A`, `git add -u`, directories, or wildcards
- **Never mix scripts with raw git** — When a utility script covers an operation (`stage-n-commit`, `move-n-stage`, `del-n-stage`, `stage-by-pattern`), use the script exclusively. Do not combine script calls with raw `git add`, `git mv`, `git rm`, `git reset`, etc. in the same logical operation — the scripts manage their own rollback, but raw commands outside them are unmanaged and break atomicity
- **Stash discipline** — If you `git stash` to get a clean working state, **log it** in the execution log so it is not forgotten. Stashed changes are restored during `/close-projex` after branch finalization

### Worktree Mode (Optional)

Worktree mode creates ephemeral branches as separate working directories in `{repo-name}/.projexwt/` (inside the repo) instead of switching the main working directory via `git checkout`. The main directory stays on the base branch throughout.

**Auto-determined by plan-projex:** The planning workflow checks for uncommitted changes, active `projex/*` execution branches, and scope of changes, setting `> **Worktree:** Yes` when dirty state, parallel execution, or large/many-file changes are detected. The user can override the auto-determined value in the plan draft. Preplans require worktree mode.

**How it works:**

- `projex-worktree` creates the worktree in `.projexwt/` inside the repo
- All execution happens in the worktree directory (`{repo-name}/.projexwt/<name>/`)
- `stage-n-commit` works unchanged (`-C` accepts worktree paths)
- Finalization scripts receive `--worktree` flag to remove the worktree instead of checking out base
- No stashing needed — the base branch working directory is never touched
- **Bootstrap contract:** a fresh worktree shares `.git` but starts with only git-tracked files — gitignored artifacts (`node_modules`, `.env`, `venv/`, build output) are absent by design. Their absence is **expected, not a blocked precondition**: bootstrap them (run the project's install/build command) before execution rather than treating missing deps as a stop condition. What gets installed here is exactly what the Cleanup contract removes before close.
- **Cleanup contract:** anything created in the worktree that git does not track — symlinked/installed deps (`node_modules`), build output, scratch files — must be removed before close, and any tracked edits committed. Close scripts refuse to finalize over a non-clean worktree (untracked files or uncommitted tracked changes). Ignored content (deps/build output) does **not** block git-level removal, but can make removal fail mid-way in environment-dependent ways (seen with symlinked deps in a Linux docker sandbox, and with file locks/CWD-in-worktree on Windows) and leave a stray directory to clean up — so remove agent-created ignored tooling too.

**Benefits over checkout mode:**

- No clean-state requirement at execution start
- No working directory disruption (editors/IDEs unaffected)
- Parallel executions possible (multiple worktrees)
- Crash-safe — main directory always on base branch

**Worktrees live inside the repo** at `{repo-name}/.projexwt/`, so they stay in the editor workspace. `projex-worktree` registers `.projexwt/` in the repo's `.git/info/exclude` (local, uncommitted) so the checkout never shows up in the parent's git status — no tracked `.gitignore` entry is added.

### Notes

- Execute/Walkthrough and Preplan use ephemeral branches
- Preplan branches (`projex/preplan/`) always discarded — only the concise planning brief is committed to base
- Other workflows operate on current branch, committed normally
- Walkthrough committed as final commit before merge

---

## NOTES

### AVOID ABSOLUTE PATHS

Use file paths RELATIVE to project root. REDACT external paths.

### NO PARALLEL EXPLORATION WITH WORKFLOWS

Workflow files (ex: execute-projex) may have requirements before starting, fully comply before reading stuff into context.
