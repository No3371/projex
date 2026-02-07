# Projex Framework

Organize objectives and tasks of any size through markdown files and folder structure. Works with LLM agents and humans.

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

### Key Interactions

- **Plans aren't just for execution** — review, red-team, or simulate them first
- **Quality workflows trigger action** — finding a problem leads to fixing it
- **Simulation feeds planning** — trial results refine or replace the plan
- **Patches chip away at plans** — execute individual objectives without the full cycle
- **Walkthroughs seed future work** — lessons learned become new proposals or plans
- **Navigation steers everything** — the roadmap decides what to explore, propose, or plan next; progress feeds back into revision
- **Interview is standalone** — use any time; output can inspire evals, proposals, or plans

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
