# Projex

<img width="514" height="203" alt="image" src="https://github.com/user-attachments/assets/9e5dcaa0-3e34-4a1a-915e-1a9ab00c0583" />
<img width="620" height="191" alt="image" src="https://github.com/user-attachments/assets/e5e1bc12-cc67-4470-b38b-ff6c31a4ed18" />
<img width="562" height="213" alt="image" src="https://github.com/user-attachments/assets/92823ebc-8697-4d07-83b9-720e8a7d6232" />
<img width="1129" height="208" alt="image" src="https://github.com/user-attachments/assets/f9b5697f-b908-47a4-8e80-3ec0fab74997" />

A prompt framework that structures how LLM agents think, plan, execute, and document work — as self-contained markdown units. No build system, no runtime, no lock-in: just workflow specs you invoke by name.

This is not for vibe-coding or fire-and-forget autonomy. It optimizes **collaborative** agentic development: you supervise and decide, the agent does the legwork, and every step leaves a document behind.

## Thirty seconds of it

```
> eval-projex options to optimize the lookup     → evaluation document with trade-offs
> plan-projex option A                           → actionable plan (no need to re-explain; the eval is right there)
> execute-projex                                 → runs the plan on an ephemeral git branch
> close-projex                                   → walkthrough written, branch squash-merged, everything cleaned up
```

Each command is a context adjustment — it reloads the rules and best practices for that phase, so the agent stays on rails across a long session. And because every output is a file, starting a fresh session costs almost nothing: throw the projex document in and continue.

Or hand the whole loop to an orchestrator:

```
> orchestrate-projex: roadmap-nav.md — plan-projex with an Opus subagent, verify,
  execute-projex with a Sonnet subagent, verify, close-projex yourself — for Phase 1 M1.1–1.5
```

```
> "add rate limiting to the public API" orchestrate-projex plan, redteam, [revise], execute, audit, [patch], close
```

One line, full lifecycle: plan it, attack the plan, revise if the attack found something, execute, audit the result, patch if the audit found gaps, close. Bracketed steps run only when needed.

## Why it works

- You stay in the loop. Mistakes surface early because you review plans before they run.
- Work in meaningful steps. Every projex is a self-contained unit of work, so progress is naturally incremental.
- Documents are the memory. Workflow output markdown files — files are all you and your agents need.
- Traceability for free. Every change links to a plan; every plan links to a walkthrough. "Why was this done?" always has an answer.
- Git powered. Ephemeral branches, worktrees, and preplan spikes make experiments cleanly discardable.
- Streamlined guardrails. Templates force scope, risks, and rollback thinking *before* acting. Strict git discipline prevents the classic agent disasters.

## Not just for code

The workflows are thinking disciplines, not programming tools — evaluation lenses, adversarial stakeholder waves, claims-vs-evidence audits, living roadmaps. Anything file-based kept in a git repo (a manuscript, course material, legal drafts, research notes) gets the **full** framework, branches and all. Without git, every analytical workflow still runs — documents are created directly, commits skipped. For work that isn't files at all, the agent authors the plan, you execute it, and the record is kept the same way. Scope rules per substrate: `SKILL.md § Substrate`.

## The loop

The double line is the flow most work actually takes. Bracketed steps run only when they are needed — and the flow can be entered at any of them.

```
  the flow   ═══   everything else hangs off it
  something needs fixing        ──▶   patch      straight to code, current branch, no cycle
  ...it needs hunting first     ──▶   debug      one bug, own worktree, until resolved
  something needs working out   ──▶   interview  Q&A with you, in rounds, transcript kept

    eval       open-ended analysis of a question    ┐
    explore    grounded in what the repo has        │
    imagine    a seed idea grown into a vision      │
    coach      judgment, argued to consensus        │  any of these can seed the flow —
    memo       captured before it is lost           │  and any one can feed any other
    scan       exhaustive file:ln inventory         │
    guide      a reading path for a human           │
    define     what a thing IS, and is not          │
    navigate   the roadmap: what to do next         ┘
              ┌──────────────────┬──────────────────┘
              │                  ▼
              │     ╔═════════════════════════╗
              │     ║  [propose]              ║ a directional what-if: trade-offs,
              │     ║  if the way is unclear  ║ impact, no steps yet
              │     ╚════════════╤════════════╝
              │                  │              preplan  a dirty spike in a throwaway worktree,
              │                  │ ◀── evidence          kept only where it sharpens the plan
              │                  ▼
              │     ╔═════════════════════════╗
              └────▶║  plan                   ║ what changes, in which files, in what order
                    ║  the blueprint          ║ hand it the ask directly and propose is skipped
                    ╚════════════╤════════════╝
                                 ▼
                    ╔═════════════════════════╗             ┌───────────────────────────────────────┐
                    ║  redteam · stress       ║─ findings ─▶│ blueteam  screens findings with you,  │
                    ║  attack the plan        ║             │           defends or concedes         │
                    ╚════════════╤════════════╝             └───────────────────┬───────────────────┘
                                 │                                              │
                                 │ ◀────────────────────────────────────────────┘
                                 ▼
                    ╔═════════════════════════╗
                    ║  [revise]               ║ edits the plan in place and logs why —
                    ║  only if it is wrong    ║ it corrects ANY stale projex document
                    ╚════════════╤════════════╝
                                 ▼
                    ╔═════════════════════════╗             ┌─ inside the run ──────────────────────┐
                    ║  execute                ║─ spawns ───▶│ do      one objective, no ceremony    │
                    ║  on an ephemeral        ║             │ verify  an independent check, per step│
                    ║  branch or worktree     ║             └───────────────────────────────────────┘
                    ╚════════════╤════════════╝             ┌─ beside it ───────────────────────────┐
                                 │             ─ hands off ▶│ debug   one bug, its own worktree,    │
                                 │                          │         until resolved or exhausted   │
                                 │                          └───────────────────────────────────────┘
                                 ├── your call · execute stops and reports; nothing closes on its own
                                 ▼
                    ╔═════════════════════════╗             ┌───────────────────────────────────────┐
                    ║  audit                  ║─── gaps ───▶│ [patch]  a quick fix straight to code │
                    ║  claims vs artifacts    ║             │          no plan, execute or close    │
                    ╚════════════╤════════════╝             └───────────────────────────────────────┘
                                 ▼
                    ╔═════════════════════════╗
                    ║  close                  ║ a walkthrough of what actually happened,
                    ║  the record             ║ then squash-merge and clean up
                    ╚════════════╤════════════╝
                                 └──▶ next unit of work — back to navigate, and around again


    review     a document re-checked against the status quo   ·  any time
    conclude   sources verified as consumed, then retired     ·  any time
    archive    many closed documents, one searchable index    ·  any time

    orchestrate  plays the projex user: spawns subagents through whole workflows,
                 reviews every return, reports back
    sprint       orchestrate in a loop: next objective, verify, absorb,
                 again — until the goal is reached or a stop fires
```

## Workflows

Invoke any of these by name. Each produces (or acts on) a typed document with a defined lifecycle.

### Think

| Command | What you get |
| --- | --- |
| `eval-projex` | Open-ended analysis of any question or idea |
| `explore-projex` | Investigation grounded in what actually exists in the repo |
| `propose-projex` | A directional "what if" with trade-offs and impact |
| `imagine-projex` | A seed idea grown into a rich, detailed vision |
| `interview-projex` | Interactive Q&A with you, in rounds, full transcript kept |
| `coach-projex` | Interactive judgment on anything judgeable — collects, takes a position, discusses to consensus or documented dissent |
| `memo-projex` | Lightweight capture of an idea or issue before it's lost — no research, just record |
| `scan-projex` | Exhaustive `file:ln` inventory of everything connected to a subject |
| `guide-projex` | Curated reading path for a human learner |

### Orient

| Command | What you get |
| --- | --- |
| `define-projex` | Living spec of what an entity *is* — identity, boundaries, constraints |
| `navigate-projex` | Living roadmap — milestones, phases, what to work on next |

### Act

| Command | What you get |
| --- | --- |
| `plan-projex` | Actionable blueprint: what to change, in which files, in what order |
| `execute-projex` | Carries out a plan on an isolated ephemeral branch (optionally in a worktree) |
| `close-projex` | Walkthrough of what actually happened, then merge and cleanup |
| `patch-projex` | Quick fix to code — skips the full plan/execute/close cycle |
| `revise-projex` | Quick fix to a projex *document* whose claims went stale |
| `preplan-projex` | Fast dirty spike in a disposable worktree; keep only evidence that sharpens the real plan |
| `debug-projex` | Hypothesis→fix→verify iteration on one concrete bug, in an isolated worktree, until resolved or exhausted |
| `orchestrate-projex` | An orchestrator acts as the projex user: spawns subagents through whole workflows, reviews their output, reports back |

### Check

| Command | What you get |
| --- | --- |
| `review-projex` | Existing documents checked against the status quo for staleness and correctness |
| `redteam-projex` | Adversarial pass — challenged assumptions, weaknesses, exploited edge cases |
| `blueteam-projex` | Defensive counter to a red team report — screens findings, dispositions each with you, lands a defense plan |
| `stress-projex` | Adversarial pass by attack angle — no stakeholder modeling, for role-thin subjects |
| `audit-projex` | Completed work validated claim-by-claim against actual artifacts |
| `archive-projex` | Closed documents compressed into one searchable index |

Workflows chain freely — any output can feed any other. A roadmap objective becomes a plan; a red team finding becomes a patch; an interview becomes an evaluation; a preplan's evidence shapes the real plan. `SKILL.md` is the framework spec behind all of them.

## Where documents live

Projex documents live in `.projex/` folders inside the target repo, named `{yymmddhhmm}-{name}-{type}.md` and organized by state:

```
.projex/            # active
.projex/closed/     # completed
.projex/archived/   # superseded
.projex/abandoned/  # discarded (rare)
```

A repo can carry multiple `.projex/` folders scoped to different areas (`docs/.projex/`, `src/.projex/`), each managed independently.

## Git, done safely

Execution runs on ephemeral branches (`projex/{yymmddhhmm}-{name}`), preplans in mandatory disposable worktrees; patches and living documents commit to the current branch. Agents follow hard rules: sequential git operations verified one at a time, staging by explicit path only (never `git add .`), repo confirmation before any operation, and no `git reset --hard` without human sign-off.

Utility scripts (each in `.sh` and `.ps1`) make the risky parts atomic, with built-in rollback:

| Script | Does |
| --- | --- |
| `new-projex` | Strict named-parameter scaffold with repo-root, type, title, Parent, and optional projex directory |
| `projex-tree` | Read-only complete current-corpus Parent lineage tree; requires Python 3 |
| `stage-n-commit` | Stage explicit paths + commit as one atomic operation |
| `stage-by-pattern` | Regex-filtered selective staging |
| `move-n-stage` / `del-n-stage` | Batch `git mv` / `git rm` with rollback |
| `execute-precheck` | Validate a plan is ready to execute |
| `close-precheck` | Report-only, versioned close context (advisory; not authorization or a finalizer) |
| `projex-worktree` | Isolated worktree under `{repo}/.projexwt/` |
| `projex-squash-close` / `projex-merge-close` / `projex-rebase-close` | Finalize an ephemeral branch, three flavors |
| `projex-abandon` | Force-delete an ephemeral branch |

`new-projex.sh` accepts `--repo-root <repo-root> --type <type> --title <title> --parent <parent> [--projex-dir <projex-dir>]`; `new-projex.ps1` accepts `-RepoRoot <repo-root> -Type <type> -Title <title> -Parent <parent> [-ProjexDir <projex-dir>]`. Positional operands, unknown flags, and duplicates are rejected before any write.

## Setup

Drop this repo into your agent tool's skills directory. Done — `SKILL.md` triggers on every workflow name, so mentioning one in a prompt auto-loads the framework. Tools without skill support can load `SKILL.md` plus the relevant `*-projex.md` into context manually.

Any output can be handed to any LLM in any session — the documents are plain markdown and carry their own context.

Ready to drive it? See **[USAGE.md](USAGE.md)** — setup, invocation grammar, the full cycle step by step, and the habits that make it work long-term.

Editing or adding workflow specs? **[AUTHORING.md](AUTHORING.md)** — the writing rules for spec text.

---

*Origin: this started as an attempt to tame Gemini 3 Pro — smart, but very rushy. It ended up reshaping how I interact with LLM agents in general. Core principles are mine; LLMs filled in details and revised against my feedback. The framework itself is model-agnostic — no lock-in to any provider or tool.*
