# Projex Framework

<img width="514" height="203" alt="image" src="https://github.com/user-attachments/assets/9e5dcaa0-3e34-4a1a-915e-1a9ab00c0583" />

Projex is a framework for efficiently prompting LLMs to think, plan, execute in form of self-contained unit files.

By prompting framework it means this is NOT for vibe-coding or autonomous agents, but to optimize collaborative agentic development, allow you to focus even more on supervising and making decisions.

It's kinda like spec-driven development but you actively engage in the process and constantly pilot the LLM, this has some inherent advantages:
- You understand the code/details better because you only delegate the execution part. You also observe agents' mistakes fairly early.
- Becuase "every projex is a self-contained unit of work", development naturally progress in small but meaningful steps.
- Because "everything is a projex document", there's always something to refer to, this greatly lowers the requirement of LLMs' memory/context retrieval capabilities.
- The projex documents are the plans, reports, and also the memory, the cost to start new sessions is very low because you can throw a projex into the new session and continue on.
- This works exceptionally with git.

These are workflows (not skills) we constantly call and chain, and the workflows cover basically all types of instructions we give out. So in practice it will be like `/plan-projex` followed by `/execute-projex` and then if everything goes well you say `/close-projex`. Every call to the workflows is like a context adjustment to guide LLMs to keep up with the rules and best practices.

Example1: 
```
> eval-projex potential solutions to optimize the lookup (this gives a evaluation projex document
> plan-projex plan for the option A (I don't need to reference the projex for the agent to understand
> execute-projex (It starts to execute on a ephemeral git branch
> close-projex (It concludes the task and cleans up everything
```

Example2:
```
> navigate-projex  (this creates a navigation projex document
> plan-projex 2601311430-v1-foundation-roadmap-nav.md#L108 (Ask the agent to plan for a objective
```

Example3:
```
> 2602071430-v1-foundation-roadmap-eval-review.md 2601311430-v1-foundation-roadmap-eval.md
plan-projex.md phase3
(asking the agent to make plan for phase 3 based on the eval and the review to the eval)
```

Example for orchestrating:
```
> orchestrate-projex: xxx-nav.md plan-projex with Opus subagent, verify, execute-projex with sonnet subagent, verify, then close-projex yourself - for each of Phase 1 M1.1-1.5
```

This started as an attempt to "tame" Gemini 3 Pro, a smart but very rushy LLM model. The framework has been proven useful and re-shaped how I interact with LLM agents in general.

Note1: Workflow is Antigravity's "command", and the `workflows` folder is made for AG for /slash usage. For Claude Code, simply mention the name of the workflows.

Note2: I proposed and designed the core principles for the workflows, Sonnet/Opus filled the details and revise them based on my requirements and feedback.

-- The following is authored by Opus --

## Why Not Just Prompt?

Agents forget what they did, skip steps, lose context between sessions, and leave no trace. Projex gives them:

- **Memory** — Decisions, rationale, and plans persist in files. Next session picks up where this one left off.
- **Traceability** — Every change links to a plan, every plan links to a walkthrough. "Why was this done?" always has an answer.
- **Guard rails** — Templates make agents think about scope, risks, and rollback before acting, not after.
- **Safe undo** — Ephemeral branches and simulations let agents try things that can be cleanly discarded.
- **Scalability** — Focused units chain together. One prompt can't manage a multi-step project; a folder of projex documents can.
- **Learning** — Walkthroughs capture what worked, what broke, and what to avoid. The project accumulates knowledge.

## How It Works

Self-contained markdown documents in `.projex/` folders. Each has a type, template, and lifecycle. Named `{yymmddhhmm}-{name}-{type}.md`, organized by state:

```
.projex/                    # Active/pending
.projex/closed/             # Completed
.projex/archived/           # Superseded or shelved
.projex/abandoned/          # Discarded (rare)
```

Repos can have multiple `.projex/` folders scoped to different areas (e.g., `docs/.projex/`, `src/.projex/`), managed independently.

## Document Types

### Ideation & Analysis

| Type | Command | Purpose |
|------|---------|---------|
| **Proposal** | `/propose-projex` | Explore a specific direction — "what if we go this way?" with trade-offs, approaches, and impact |
| **Evaluation** | `/eval-projex` | Open-ended analysis, assessment, or research into any question, idea, or solution |
| **Exploration** | `/explore-projex` | Investigation grounded in the status quo — map what exists to inform decisions and answer questions |
| **Imagination** | `/imagine-projex` | Generative — takes a seed idea and grows it into rich, detailed vision with creative challenges |

### Specification & Orientation

| Type | Command | Purpose |
|------|---------|---------|
| **Definition** | `/define-projex` | Living declarative spec — exhaustively defines WHAT an entity is: identity, boundaries, properties, constraints |
| **Navigation** | `/navigate-projex` | Living high-level roadmap — milestones, phases, and "what to work on next" |
| **Map** | `/map-projex` | Living structural index of directories — orientation for where things live and why |

### Planning & Execution

| Type | Command | Purpose |
|------|---------|---------|
| **Plan** | `/plan-projex` | Actionable blueprint — what to change, in which files, in what order |
| **Execute** | `/execute-projex` | Carry out a plan in an isolated ephemeral branch |
| **Walkthrough** | `/close-projex` | Post-execution record — what actually happened, verification results, lessons learned |
| **Patch** | `/patch-projex` | Quick action for small changes — skip the full plan/execute/close cycle |
| **Revise** | `/revise-projex` | Quick fix to any projex document's own content (Plan, Proposal, Definition, Nav, Map, …) — new context makes it stale. Distinct from Patch: Patch fixes code, Revise fixes what a document *claims* |
| **Log** | `/log-projex` | Standalone change record — observe staged changes or commits and document what happened |
| **Simulation** | `/simulate-projex` | Disposable execution — make real changes, observe outcomes, roll everything back |

### Quality & Validation

| Type | Command | Purpose |
|------|---------|---------|
| **Review** | `/review-projex` | Check existing projex documents for staleness, correctness, completeness |
| **Red Team** | `/redteam-projex` | Adversarial analysis — challenge assumptions, find weaknesses, exploit edge cases |
| **Audit** | `/audit-projex` | Validate completed work — cross-reference claims against actual artifacts |

### Knowledge Gathering

| Type | Command | Purpose |
|------|---------|---------|
| **Interview** | `/interview-projex` | Interactive Q&A with the user — rounds of questions, full transcript |
| **Guide** | `/guide-projex` | Curated reading path for human learners — phased steps with focus cues and takeaways |

## How Workflows Connect

Not a pipeline. Building blocks that chain freely — any output can trigger any workflow.

```
           ┌─────────────┐
  ┌───────>│   Review    │───────┐
  │        └─────────────┘       │
  │        ┌─────────────┐       │  findings
  │   ┌───>│  Red Team   │───┐   │  feed back
  │   │    └─────────────┘   │   │
  │   │    ┌─────────────┐   │   │
  │   ├───>│   Audit     │───┤   │
  │   │    └─────────────┘   │   │
  │   │                      ▼   ▼
  │   │    ┌──────────────────────────────────────────┐
  │   │    │ Proposal / Eval / Explore / Imagination  │
  │   │    └──────┬───────────────────────────────────┘
  │   │           │                              ┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐
  │   │          ┌┴──────────────────┐            Define · Navigate · Map · Scan
  │   │          ▼                   ▼           │ Guide · Interview · Imagine · Memo │
  │   │    ┌───────────┐      ┌────────────┐       auxiliary — can inform or be
  │   │    │   Plan    │◄────>│   Patch    │     │  informed by any workflow above  │
  │   │    └─────┬─────┘  ╲   │ (act+doc)  │
  │   │          │         ╲  └────────────┘     └ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘
  │   │          │          ╲── Revise: any projex doc, edited in place, no new file
  │   │          │ ◄── review/redteam plan
  │   │          │     before execution
  │   │    ┌─────┴──────┐
  │   │    ▼            ▼
  │   │ ┌────────┐ ┌──────────┐
  │   │ │Execute │ │ Simulate │
  │   │ └───┬────┘ │(try+undo)│
  │   │     │      └──────────┘
  │   │     ▼
  │   │ ┌──────────┐
  │   │ │  Close   │
  │   │ │(walkthru)│
  │   │ └────┬─────┘
  │   │      │
  └───┴──────┘
    any output can trigger
    another workflow
```

### Common Chains

Patterns, not rules.

| From | To | When |
|---|---|---|
| Navigate | Explore, Eval, Proposal, Plan | Roadmap identifies what to investigate or build next |
| Interview | Eval, Proposal, Plan, Navigate | Gathered knowledge inspires analysis, action, or roadmap revision |
| Scan | Plan, Red Team, Review, Eval | Inventory reveals issues, informs planning or validation |
| Memo | Eval, Plan | Captured idea feeds into analysis or planning |
| Definition | Proposal, Plan, Explore, Review | Entity pinned down — propose a direction, plan implementation, explore deeper, or review the definition |
| Exploration | Proposal, Eval, Plan, Navigate, Definition | Investigation reveals a gap or opportunity, or an entity worth defining |
| Proposal | Eval, Plan, Simulation | Direction chosen — analyze, plan, or trial-run it |
| Eval | Proposal, Plan, Explore | Findings raise questions, reveal directions, or clarify scope |
| Simulation | Plan, Patch, Proposal | Trial results inform how to proceed for real |
| Plan | Review, Red Team, Simulation | Inspect the plan before committing |
| Plan | Execute, Patch | Plan vetted — run it or cherry-pick objectives |
| Any document | Revise | New context makes what it claims stale — fixes the document, not the code |
| Execute + Close | Review, Audit, Navigate | Completed work needs validation or roadmap update |
| Review | Proposal, Plan, Patch | Stale or incomplete documents need updating |
| Red Team | Plan, Patch, Proposal | Weaknesses found — address them |
| Audit | Plan, Patch, Proposal | Gaps in completed work — fix them |
| Patch | Review, Audit, Log | Quick fix warrants retrospective validation or richer record |
| Log | — | Standalone — documents changes already made; doesn't chain forward |
| Imagination | Proposal, Eval, Plan | Vision crystallized — evaluate feasibility or plan it |
| Map | Explore, Plan | Structure surveyed — investigate areas or plan changes |
| Guide | Explore, Eval | Learning path reveals gaps worth investigating |

## Git Integration

- **Execute/Close** — ephemeral branch (`projex/{yymmddhhmm}-{name}`), merged or abandoned at close
- **Simulate** — throwaway branch (`projex/sim/{yymmddhhmm}-{name}`), always discarded
- **Patch** — commits directly to current branch
- **Revise** — edits the target projex document in place, commits to whatever branch it currently lives on; no new file
- **Log** — observes existing changes (staged or committed); commits only the log document itself
- **Definition / Navigate / Map** — operates on current branch, revised in-place (living documents)
- **Everything else** — operates on current branch

### Discipline

- Sequential git commands, verified one at a time
- Stage files by explicit path — never `git add .`, `git add -A`, `git add -u`, or directories
- Multi-repo workspaces: confirm which repo before any git operation

## File Reference

All workflow specs live in the repository root.

| File | Role |
|------|------|
| `SKILL.md` | Framework spec — types, authoring, organizing, git rules |
| `propose-projex.md` | Proposals |
| `eval-projex.md` | Evaluations |
| `explore-projex.md` | Explorations |
| `plan-projex.md` | Plans |
| `execute-projex.md` | Plan execution |
| `close-projex.md` | Walkthroughs and branch finalization |
| `log-projex.md` | Standalone change logs |
| `patch-projex.md` | Quick-action patches |
| `revise-projex.md` | In-place revisions to any projex document |
| `simulate-projex.md` | Disposable simulations |
| `review-projex.md` | Document reviews |
| `redteam-projex.md` | Adversarial analysis |
| `audit-projex.md` | Work audits |
| `define-projex.md` | Entity definitions |
| `navigate-projex.md` | Living roadmaps |
| `map-projex.md` | Structural maps |
| `interview-projex.md` | Interactive Q&A |
| `guide-projex.md` | Learning guides |
| `imagine-projex.md` | Generative imagination |
