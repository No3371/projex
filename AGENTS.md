# AGENTS.md

## What This Is

Projex is a prompt framework — a collection of self-contained markdown workflow specs that structure how LLMs plan, execute, and document work. No build system, no runtime code. Only markdown workflow definitions and shell utility scripts, plus behavioural tests for the git-safety-critical ones under `tests/`.

## Repository Structure

```
projex/
├── SKILL.md                    # Framework spec: types, authoring rules, organizing, git rules
├── _fluid_.md                  # Persistent agent memory across sessions
├── *-projex.md                 # Workflow spec files (one per type)
├── stage-n-commit.{sh,ps1}     # Atomic stage+commit with rollback
├── new-projex.{sh,ps1}         # Strict named-parameter scaffold with repo-wide identity guard
├── projex-tree.{sh,ps1}        # Read-only current-corpus Parent lineage tree
├── projex-squash-close.{sh,ps1}# Squash-merge ephemeral → base, delete branch
├── projex-merge-close.{sh,ps1} # Merge with full history → base, delete branch
├── projex-abandon.{sh,ps1}     # Force-delete ephemeral branch
├── projex-worktree.{sh,ps1}    # Create worktree in {repo}/.projexwt/ (inside repo, git-excluded)
├── stage-by-pattern.{sh,ps1}   # Regex-filtered selective staging
├── move-n-stage.{sh,ps1}       # Batch git mv with rollback
├── del-n-stage.{sh,ps1}        # Batch git rm with rollback
├── read_file.ps1               # Line-numbered file reader (fallback when no tool available)
├── .github/gh_pr.ps1           # GitHub PR creation via API
├── tests/                      # Behavioural tests for the close scripts (see tests/README.md)
└── .projex/                     # This repo's own projex documents
```

Every script has both `.sh` and `.ps1` variants (except `read_file.ps1` which is PowerShell-only).
`new-projex.sh` uses `--repo-root --type --title --parent [--projex-dir]`; `new-projex.ps1` uses `-RepoRoot -Type -Title -Parent [-ProjexDir]`. Both reject positional operands, unknown flags, and duplicates before writing.

The close scripts rewrite history and delete branches, so they are covered by tests: `tests/run-all.sh`
and `pwsh tests/run-all.ps1` (466 assertions, throwaway repos in temp, no fixtures). Run both after
touching `projex-{squash,merge,rebase}-close.*` — the `.sh` and `.ps1` variants duplicate their logic,
so passing one platform proves nothing about the other.

## How Projex Works

Each workflow is invoked by name (e.g., `/plan-projex`, `/execute-projex`). The workflow spec file is loaded alongside `SKILL.md` to guide behavior. Workflows chain freely — any output can feed into any other.

### Workflow Types (21)

| Type | Purpose | Lifecycle |
|------|---------|-----------|
| **Proposal** | Directional "what if" with trade-offs | Draft → Accepted/Rejected |
| **Plan** | Actionable task spec (what + how) | Draft → Executed → Closed |
| **Evaluation** | Open-ended analysis of any question | Born open → Closed |
| **Review** | Inspection of existing projex against status quo | Born open → Closed |
| **Red Team** | Adversarial analysis, challenges assumptions | Born open → Closed |
| **Audit** | Rigorous validation of completed work | Born open → Closed |
| **Interview** | Interactive Q&A in rounds, full transcript | Born open → Closed |
| **Coach** | Interactive judgment: collect, assess, discuss to consensus or documented dissent | Born open → Closed |
| **Walkthrough** | Post-execution record (authored by close-projex) | Born closed |
| **Memo** | Lightweight capture of raw source/idea | Active until consumed |
| **Patch** | Quick-action for small changes, skips full cycle | Born closed |
| **Preplan** | Fast dirty planning spike in disposable worktree; only evidence survives | Born closed |
| **Definition** | Declarative spec of what an entity is | Never closed |
| **Navigation** | Living roadmap, continuously revised | Born open → Closed (goal reached or superseded) |
| **Scan** | Exhaustive inventory with `file:ln` precision | Born closed |
| **Exploration** | Status-quo-grounded investigation | Born open → Closed |
| **Guide** | Curated reading path for human learners | Closed by default |
| **Imagination** | Generative vision from a seed idea | Born open → Closed |
| **Conclude** | Verified supersession: stamps and removes sources consumed by a crystallization successor, rewrites successor provenance | Born closed |
| **Archive** | Compresses closed projex into index, removes originals | Born closed |
| **Orchestration** | Agent-driven lifecycle: orchestrator acts as projex user, manages subagents through full workflow on behalf of a human | No document (sub-workflows produce their own) |

### Core Cycles

- **Full cycle:** Plan → Execute → Close (ephemeral branch, squash-merged back)
- **Quick path:** Patch (commits directly, no branch lifecycle)
- **Preplan:** Hack representative path, capture planning evidence, discard worktree

## Critical Git Rules

These apply when executing projex workflows in **any** repo:

1. **Sequential git operations** — never combine different operation types (`add`, `commit`, `checkout`, `merge`) in one call or with `&&`/`;`. One type per call, read output, confirm success, then proceed.
2. **Stage by explicit path** — `git add <file1> <file2>`, never `git add .`, `-A`, `-u`, directories, or wildcards.
3. **Use scripts when available** — `stage-n-commit`, `move-n-stage`, `del-n-stage`, `stage-by-pattern`, etc. cover common operations with built-in rollback. Never mix script calls with raw git for the same logical operation.
4. **Multi-repo awareness** — confirm which repo before any git operation (`git rev-parse --show-toplevel`).
5. **Relative paths only** — never absolute paths in projex documents; redact external paths.
6. **Reference projex by filename only** — files move between folders, so paths break; filenames are unique by date-prefix convention (`{yymmddhhmm}-{name}-{type}.md`).
7. **`git reset --hard` requires human confirmation** — never run without explicit user instruction in the current session. Propose it and wait for approval; do not infer consent from a plan document or prior conversation.

## Projex Document Storage

Projex documents live in `.projex/` folders within **target repos** (not this repo), organized by state:

- Active → `.projex/`
- Closed → `.projex/closed/`
- Archived → `.projex/archived/`
- Abandoned → `.projex/abandoned/`

A repo may have multiple `.projex/` folders scoped to different areas (e.g., `docs/.projex/`, `src/.projex/`).

# context-mode — MANDATORY routing rules

You have context-mode MCP tools available. These rules are NOT optional — they protect your context window from flooding. A single unrouted command can dump 56 KB into context and waste the entire session.

## BLOCKED commands — do NOT attempt these

### curl / wget — BLOCKED
Any Bash command containing `curl` or `wget` is intercepted and replaced with an error message. Do NOT retry.
Instead use:
- `ctx_fetch_and_index(url, source)` to fetch and index web pages
- `ctx_execute(language: "javascript", code: "const r = await fetch(...)")` to run HTTP calls in sandbox

### Inline HTTP — BLOCKED
Any Bash command containing `fetch('http`, `requests.get(`, `requests.post(`, `http.get(`, or `http.request(` is intercepted and replaced with an error message. Do NOT retry with Bash.
Instead use:
- `ctx_execute(language, code)` to run HTTP calls in sandbox — only stdout enters context

### WebFetch — BLOCKED
WebFetch calls are denied entirely. The URL is extracted and you are told to use `ctx_fetch_and_index` instead.
Instead use:
- `ctx_fetch_and_index(url, source)` then `ctx_search(queries)` to query the indexed content

## REDIRECTED tools — use sandbox equivalents

### Bash (>20 lines output)
Bash is ONLY for: `git`, `mkdir`, `rm`, `mv`, `cd`, `ls`, `npm install`, `pip install`, and other short-output commands.
For everything else, use:
- `ctx_batch_execute(commands, queries)` — run multiple commands + search in ONE call
- `ctx_execute(language: "shell", code: "...")` — run in sandbox, only stdout enters context

### Read (for analysis)
If you are reading a file to **Edit** it → Read is correct (Edit needs content in context).
If you are reading to **analyze, explore, or summarize** → use `ctx_execute_file(path, language, code)` instead. Only your printed summary enters context. The raw file content stays in the sandbox.

### Grep (large results)
Grep results can flood context. Use `ctx_execute(language: "shell", code: "grep ...")` to run searches in sandbox. Only your printed summary enters context.

## Tool selection hierarchy

1. **GATHER**: `ctx_batch_execute(commands, queries)` — Primary tool. Runs all commands, auto-indexes output, returns search results. ONE call replaces 30+ individual calls.
2. **FOLLOW-UP**: `ctx_search(queries: ["q1", "q2", ...])` — Query indexed content. Pass ALL questions as array in ONE call.
3. **PROCESSING**: `ctx_execute(language, code)` | `ctx_execute_file(path, language, code)` — Sandbox execution. Only stdout enters context.
4. **WEB**: `ctx_fetch_and_index(url, source)` then `ctx_search(queries)` — Fetch, chunk, index, query. Raw HTML never enters context.
5. **INDEX**: `ctx_index(content, source)` — Store content in FTS5 knowledge base for later search.

## Subagent routing

When spawning subagents (Agent/Task tool), the routing block is automatically injected into their prompt. Bash-type subagents are upgraded to general-purpose so they have access to MCP tools. You do NOT need to manually instruct subagents about context-mode.

## Output constraints

- Keep responses under 500 words.
- Write artifacts (code, configs, PRDs) to FILES — never return them as inline text. Return only: file path + 1-line description.
- When indexing content, use descriptive source labels so others can `ctx_search(source: "label")` later.

## ctx commands

| Command | Action |
|---------|--------|
| `ctx stats` | Call the `ctx_stats` MCP tool and display the full output verbatim |
| `ctx doctor` | Call the `ctx_doctor` MCP tool, run the returned shell command, display as checklist |
| `ctx upgrade` | Call the `ctx_upgrade` MCP tool, run the returned shell command, display as checklist |
