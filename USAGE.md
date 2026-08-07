# Using Projex

The [README](README.md) explains what Projex is. This document is the driver's manual: how to set it up, invoke workflows, steer the agent, and keep a project healthy over months of use.

## Setup

1. Clone (or copy) this repo into your preferred agent tool's skills directory (e.g., `~/.claude/skills/` for Claude Code) — the workflow specs and scripts are read from there.
2. That's it. `SKILL.md`'s description lists every workflow name as a trigger, so typing an exact name (`plan-projex`, `execute-projex`, …) in a prompt makes the agent auto-load the skill plus that workflow's spec file — standard skill handling in most agent tools.
3. For tools without skill support, load `SKILL.md` plus the relevant `*-projex.md` into context manually — as commands, rules files, or plain attachments. The specs are self-contained markdown.

Nothing is installed into your target repos. The only footprint there is `.projex/` folders (documents) and, during executions, ephemeral `projex/*` branches.

## Invoking a workflow

Workflows are verbs. Type the workflow name plus a natural-language directive, a file reference, or both:

```
> propose-projex I want to add XXX feature
> eval-projex what can be improved in the current implementation?
> preplan-projex try one raw-SQL replacement and map the real migration surface
> redteam-projex @2607311430-auth-system-plan.md
> patch-projex fix the off-by-one in the parser loop
> patch-projex execute objective 2 of @2602011430-api-cleanup-plan.md
> revise-projex @2602011430-api-cleanup-plan.md step 2 assumed Redis, it's actually Memcached
> debug-projex login button does nothing on Safari iOS — works on Chrome/Firefox
> plan-projex @2608051730-raw-sql-migration-preplan.md
> execute-projex @2607311430-language-macro-syntax-change-plan.md
> close-projex
```

## Your first full cycle

The core loop is Plan → Execute → Close. Here is what actually happens at each step and where you come in:

**1. `plan-projex <directive or @proposal/@preplan>`** — The agent writes a plan: exact file changes, order, scope, acceptance criteria, risks. A referenced preplan contributes observed spike evidence while the planner converts its shortcuts into production requirements and verifies freshness. The workflow also decides whether execution should run in a worktree (`> **Worktree:** Yes`) based on dirty state, parallel executions, or change size — you can override that line in the draft.

**2. You review the plan.** This is the highest-leverage moment in the whole framework. Read it. Push back. Optionally harden it first:

```
> redteam-projex @<plan>.md      # attack it
> revise-projex @<plan>.md ...   # fix what the attack found
```

When you're satisfied: **commit the plan to the base branch.** Execution requires it — a committed plan survives an abandoned execution and stays independently reviewable.

**3. `execute-projex @<plan>.md`** — The agent creates an ephemeral branch `projex/{yymmddhhmm}-{name}` (or a worktree under `.projexwt/`), works through the objectives, and keeps an execution log as it goes. Your main branch is never touched.

**4. You review the results.** Diff the branch, run the app, ask questions. Not happy? Direct fixes on the branch, or abandon it — the base branch is untouched either way.

**5. `close-projex`** — The agent writes a walkthrough (what changed, criteria checklist with proof, lessons), commits it, then finalizes the branch: squash-merge by default, or full merge, rebase, or abandon. Branch deleted, documents moved to `.projex/closed/`.

For work too small to deserve this ceremony, skip it: `patch-projex <directive>` commits directly to the current branch and documents itself after the fact.

## Picking the right workflow

| You want to… | Use |
|---|---|
| Analyze a question or compare options | `eval-projex` |
| Understand what currently exists in the repo | `explore-projex` |
| Pitch a direction with trade-offs | `propose-projex` |
| Grow a vague idea into a detailed vision | `imagine-projex` |
| Have the agent interview *you* to extract knowledge | `interview-projex` |
| Jot down an idea/issue before it's lost | `memo-projex` |
| List every occurrence of something, `file:ln` precise | `scan-projex` |
| Get a reading path to learn a subsystem | `guide-projex` |
| Pin down what an entity *is* | `define-projex` (living doc) |
| Maintain a roadmap / decide what's next | `navigate-projex` (living doc) |
| Collapse implementation uncertainty with a fast dirty disposable spike | `preplan-projex` |
| Run a vetted plan | `execute-projex` |
| Wrap up an execution | `close-projex` |
| Make a small, well-understood code change | `patch-projex` |
| Fix a projex document whose claims went stale | `revise-projex` |
| Spec out a concrete change, optionally from preplan evidence | `plan-projex` |
| Hunt down one concrete bug until it's dead | `debug-projex` |
| Check documents against reality | `review-projex` |
| Attack a plan/proposal before trusting it | `redteam-projex` |
| Verify completed work claim-by-claim | `audit-projex` |
| Compress a bloated `closed/` folder | `archive-projex` |
| Delegate a whole chain to subagents | `orchestrate-projex` |

The recurring confusions: **Patch fixes code, Revise fixes documents.** **Eval is open-ended, Explore is read-only status-quo research, Propose chooses direction, Preplan hacks just enough code to sharpen a future Plan.** **Preplan always discards, Debug merges when it wins, Patch is for when you already know the fix.**

## Document lifecycle

Every document carries a machine-readable status line:

```
> **Status:** In Progress
> **Status:** Complete (Accepted)
> **Status:** Escalated (Non-Repro)
```

States: `Draft` → `Ready` → `In Progress` → `Complete`, with `Blocked` / `Escalated` as wait states and `Abandoned` as the other terminal. State maps to folder: active documents in `.projex/`, `Complete` in `.projex/closed/`, superseded in `.projex/archived/`, dropped in `.projex/abandoned/`. Definitions stay in `.projex/` permanently and cycle between `Complete` (stable) and `In Progress` (being revised). Navigations hold `In Progress` across all revisions and close (`Complete (Goal Reached)` / `Complete (Superseded)`) only when their goal is reached or a new roadmap supersedes them.

Scoping: a repo can carry several `.projex/` folders (`docs/.projex/`, `src/.projex/`), each independently managed. Keep projex inside their area — a spec-update plan shouldn't touch runtime code.

When `closed/` grows noisy, run `archive-projex`: every closed document gets compressed into a one-line summary + keywords in a single index file, and the originals are removed.

## Worktree mode

By default execution switches your working directory to the ephemeral branch. Worktree mode instead creates an isolated checkout under `{repo}/.projexwt/` — your main directory never leaves the base branch, editors are undisturbed, several executions can run in parallel, and no clean-state is required to start.

`plan-projex` auto-selects worktree mode when it detects dirty state, parallel executions, or large changes; override its `> **Worktree:**` line. Preplans require worktrees; debug sessions default to them. A fresh worktree has only tracked files, so bootstrap only what the probe or execution needs and clean agent-created ignored tooling before removal.

## Orchestration

`orchestrate-projex` puts an agent in your seat: it spawns subagents to run whole workflows, reviews their output as you would, and reports back. Give it a directive and a chain:

```
> "add rate limiting to the public API" orchestrate-projex plan, redteam, [revise], execute, audit, [patch], close
```

Chain notation:

| Notation | Meaning |
|---|---|
| `step` | Run this workflow via a subagent |
| `[step]` | Optional — orchestrator decides from results so far whether it's needed |
| `step!` | Must succeed, or the whole orchestration halts and escalates |
| `step<model>` | Model override for this step (`sonnet` \| `opus` \| `haiku` \| `fable`) |
| `<<model>>` | Switch the default model for all following steps |
| `step<<model>>` | Override this step *and* switch the default for all following steps |
| `stepA+stepB` | Run in parallel (safe for read-only workflows) |
| `stepA & stepB` | Glue — producer/checker judged as one unit (`execute & audit`) |
| `\| … \|*N` | Loop the group up to N times until the checker passes |

Example: `plan<opus>, execute!, audit+redteam, [patch], close` — plan on Opus, execution must succeed, audit and red team run in parallel, patch only if they found something, then close. The chain you give is literal: the orchestrator runs exactly those workflows, with `[...]` as the only judgment call.

## Habits that pay off

- **Start sessions cheap.** New session, paste one filename, continue. The documents are the memory — don't re-explain.
- **Memo instead of derailing.** Mid-workflow idea? `memo-projex` captures it in seconds without breaking the current task; it stays visible in `.projex/` until consumed.
- **Navigate for anything multi-week.** A living roadmap gives every future session a "what's next" anchor, and plans derived from it record their origin (`> **Nav:**`) so closes update the roadmap automatically.
- **Preplan only when uncertainty is expensive.** Hack the smallest representative path, run the narrowest discriminating check, record the production implications, then stop and discard. Compatibility, polish, and completeness belong in Plan and Execute.
- **Audit what matters.** After significant executions, `audit-projex` cross-checks the walkthrough's claims against the actual code. Agents' self-reports are optimistic; audits aren't.
