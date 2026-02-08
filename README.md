# Projex Framework

<img width="467" height="659" alt="image" src="https://github.com/user-attachments/assets/607e5f4e-295c-4d0e-8d94-b3963f1dca9d" />

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
/eval-projex potential solutions to optimize the lookup
/plan-projex plan for the option A
/execute-projex
/close-projex
```

This started as an attempt to "tame" Gemini 3 Pro, a smart but very rushy LLM model. The framework has been proven useful and re-shaped how I interact with LLM agents in general.

Note1: Workflow is Antigravity's "command", and the `workflows` folder is made for AG for /slash usage. For Claude Code, simply mentioning the name of the workflows should work even without making them commands in Claude Code.

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

Self-contained markdown documents in `projex/` folders. Each has a type, template, and lifecycle. Named `{yyyymmdd}-{name}-{type}.md`, organized by state:

```
projex/                    # Active/pending
projex/closed/             # Completed
projex/archived/           # Superseded or shelved
projex/abandoned/          # Discarded (rare)
```

Repos can have multiple `projex/` folders scoped to different areas (e.g., `docs/projex/`, `src/projex/`), managed independently.

## Document Types

### Ideation & Analysis

| Type | Command | Purpose |
|------|---------|---------|
| **Proposal** | `/propose-projex` | Explore a specific direction — "what if we go this way?" with trade-offs, approaches, and impact |
| **Evaluation** | `/eval-projex` | Open-ended analysis, assessment, or research into any question, idea, or solution |
| **Exploration** | `/explore-projex` | Investigation grounded in the status quo — map what exists to inform decisions and answer questions |

### Strategy & Direction

| Type | Command | Purpose |
|------|---------|---------|
| **Navigation** | `/navigate-projex` | Living high-level roadmap — milestones, phases, and "what to work on next" |

### Planning & Execution

| Type | Command | Purpose |
|------|---------|---------|
| **Plan** | `/plan-projex` | Actionable blueprint — what to change, in which files, in what order |
| **Execute** | `/execute-projex` | Carry out a plan in an isolated ephemeral branch |
| **Walkthrough** | `/close-projex` | Post-execution record — what actually happened, verification results, lessons learned |
| **Patch** | `/patch-projex` | Quick action for small changes — skip the full plan/execute/close cycle |
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
  │   │    ┌─────────────────────────────────┐  ┌ ─ ─ ─ ─ ─ ─┐
  │   │    │  Proposal  /  Eval  /  Explore  │<·  User Input
  │   │    └──────┬─────────┬────────────────┘  └ ─ ─ ─ ─ ─ ─┘
  │   │           │  ┌──────┴──────┐            ┌ ─ ─ ─ ─ ─ ─┐
  │   │           │  │  Navigate   │◄ ─ ─ ─ ─ ·  Interview
  │   │           │  │ (roadmap)   │            └ ─ ─ ─ ─ ─ ─┘
  │   │           │  └──────┬──────┘            external inputs,
  │   │           │    steers│direction          can inform any
  │   │          ┌┴─────────┴──────────┐           workflow
  │   │          ▼                     ▼
  │   │    ┌───────────┐        ┌────────────┐
  │   │    │   Plan    │──────> │   Patch    │
  │   │    └─────┬─────┘        │ (act+doc)  │
  │   │          │              └────────────┘
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
| Exploration | Proposal, Eval, Plan, Navigate | Investigation reveals a gap or opportunity |
| Proposal | Eval, Plan, Simulation | Direction chosen — analyze, plan, or trial-run it |
| Eval | Proposal, Plan, Explore | Findings raise questions, reveal directions, or clarify scope |
| Simulation | Plan, Patch, Proposal | Trial results inform how to proceed for real |
| Plan | Review, Red Team, Simulation | Inspect the plan before committing |
| Plan | Execute, Patch | Plan vetted — run it or cherry-pick objectives |
| Execute + Close | Review, Audit, Navigate | Completed work needs validation or roadmap update |
| Review | Proposal, Plan, Patch | Stale or incomplete documents need updating |
| Red Team | Plan, Patch, Proposal | Weaknesses found — address them |
| Audit | Plan, Patch, Proposal | Gaps in completed work — fix them |
| Patch | Review, Audit | Quick fix warrants retrospective validation |

## Git Integration

- **Execute/Close** — ephemeral branch (`projex/{yyyymmdd}-{name}`), merged or abandoned at close
- **Simulate** — throwaway branch (`projex/sim/{yyyymmdd}-{name}`), always discarded
- **Patch** — commits directly to current branch
- **Navigate** — operates on current branch, revised in-place
- **Everything else** — operates on current branch

### Discipline

- Sequential git commands, verified one at a time
- Stage files by explicit path — never `git add .` or directories
- Multi-repo workspaces: confirm which repo before any git operation

## File Reference

All workflow specs live in `.agent/skills/projex-framework/`.

| File | Role |
|------|------|
| `SKILL.md` | Framework spec — types, authoring, organizing, git rules |
| `propose-projex.md` | Proposals |
| `eval-projex.md` | Evaluations |
| `explore-projex.md` | Explorations |
| `plan-projex.md` | Plans |
| `execute-projex.md` | Plan execution |
| `close-projex.md` | Walkthroughs and branch finalization |
| `patch-projex.md` | Quick-action patches |
| `simulate-projex.md` | Disposable simulations |
| `review-projex.md` | Document reviews |
| `redteam-projex.md` | Adversarial analysis |
| `audit-projex.md` | Work audits |
| `navigate-projex.md` | Living roadmaps |
| `interview-projex.md` | Interactive Q&A |
