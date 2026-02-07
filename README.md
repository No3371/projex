# Projex Framework

A workflow framework for organizing objectives and tasks of any size, entirely through markdown files and folder structure in the filesystem. Designed for LLM agents and humans alike.

## How It Works

All project management happens through self-contained markdown documents stored in `projex/` folders. Each document follows a specific type with its own template, lifecycle, and workflow spec. Documents are named `{yyyymmdd}-{name}-{type}.md` and organized by state:

```
projex/                    # Active/pending documents
projex/closed/             # Completed work
projex/archived/           # Superseded or shelved
projex/abandoned/          # Discarded (rare)
```

A repository can have multiple `projex/` folders scoped to different areas (e.g., `docs/projex/`, `src/projex/`), each managed independently.

## Document Types

### Ideation & Analysis

| Type | Command | Purpose |
|------|---------|---------|
| **Proposal** | `/propose-projex` | Explore new ideas, capture trade-offs and approaches before committing to action |
| **Evaluation** | `/eval-projex` | Systematic analysis of status quo vs new ideas — rigor, clarity, intellectual honesty |
| **Exploration** | `/explore-projex` | Deep investigation against the codebase solely to answer questions |

### Planning & Execution

| Type | Command | Purpose |
|------|---------|---------|
| **Plan** | `/plan-projex` | Actionable task document — what to do, how to do it, exact file changes |
| **Execute** | `/execute-projex` | Carry out a plan in an isolated ephemeral git branch |
| **Walkthrough** | `/close-projex` | Post-execution record — what happened, success criteria verification, lessons learned |
| **Patch** | `/patch-projex` | Quick action for small changes — skips the full plan/execute/close cycle |
| **Simulation** | `/simulate-projex` | Disposable execution — make real changes, observe outcomes, then roll everything back |

### Quality & Validation

| Type | Command | Purpose |
|------|---------|---------|
| **Review** | `/review-projex` | Inspect existing projex documents for staleness, correctness, and completeness |
| **Red Team** | `/redteam-projex` | Adversarial analysis — challenge assumptions, find weaknesses, exploit edge cases |
| **Audit** | `/audit-projex` | Rigorous validation of completed work — cross-reference claims against actual artifacts |

### Knowledge Gathering

| Type | Command | Purpose |
|------|---------|---------|
| **Interview** | `/interview-projex` | Interactive Q&A session with the user — rounds of questions, full transcript logging |

## How Workflows Connect

Projex workflows are not a pipeline. They are building blocks that chain freely depending on what the situation calls for. Any workflow can lead to any other.

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
  │   │    └────────────────┬────────────────┘  └ ─ ─ ─ ─ ─ ─┘
  │   │                     │                   ┌ ─ ─ ─ ─ ─ ─┐
  │   │          decide what to do            <·  Interview
  │   │                     │                   └ ─ ─ ─ ─ ─ ─┘
  │   │          ┌──────────┴──────────┐      external inputs,
  │   │          ▼                     ▼      can inform any
  │   │    ┌───────────┐        ┌────────────┐   workflow
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

These are patterns, not rules. Mix and match as needed.

| Starting point | Leads to | When |
|---|---|---|
| Interview | Eval, Proposal, Plan | Gathered knowledge can inspire analysis, ideas, or action |
| Exploration | Proposal, Eval, Plan | Investigation reveals a gap or opportunity |
| Proposal | Eval, Plan, Simulation | Idea accepted — now analyze, plan, or trial-run it |
| Eval | Proposal, Plan | Analysis reveals what should change |
| Simulation | Plan, Patch, Proposal | Trial run informs whether/how to proceed for real |
| Plan | Review, Red Team, Simulation | Plan drafted — inspect it before committing to execution |
| Plan | Execute, Patch | Plan vetted — run it fully or cherry-pick objectives |
| Execute + Close | Review, Audit, new Plan | Completed work may need validation or follow-up |
| Review | Proposal, Plan, Patch | Stale or incomplete projex need updating |
| Red Team | Plan, Patch, Proposal | Weaknesses found need to be addressed |
| Audit | Plan, Patch, Proposal | Gaps or issues found in completed work |
| Patch | Review, Audit | Quick fix may warrant retrospective validation |

### Key Interactions

- **Plans are not just for execution** — a plan can be reviewed, red-teamed, or simulated before anyone commits to running it
- **Any quality workflow (Review, Red Team, Audit) can trigger any action workflow** — finding a problem naturally leads to fixing it
- **Simulation feeds back into planning** — trial results refine or replace the original plan
- **Patches can chip away at plans** — individual objectives can be patched out without executing the full plan
- **Walkthroughs inform future work** — lessons learned and follow-up recommendations seed new proposals or plans
- **Interview is a standalone tool, not a prerequisite** — use it any time to gather knowledge; its output can inspire evals, proposals, or plans

## Git Integration

- **Execute/Close** cycle uses an ephemeral branch (`projex/{yyyymmdd}-{name}`) for isolation. The branch is merged or abandoned at close.
- **Simulate** uses a throwaway branch (`projex/sim/{yyyymmdd}-{name}`) that is always discarded. Only the report survives.
- **Patch** commits directly to the current branch — no branch overhead for small changes.
- **All other workflows** (propose, plan, eval, review, etc.) operate on the current branch.

### Discipline

- Git commands run sequentially, one at a time, with verification between each
- Files are staged by explicit path (`git add path/to/file.md`) — never `git add .` or directories
- Multi-repo workspaces require confirming which repo you're operating in before any git command

## File Reference

| File | Role |
|------|------|
| `SKILL.md` | Framework specification — document types, authoring rules, organizing rules, git integration |
| `propose-projex.md` | Workflow spec for creating proposals |
| `eval-projex.md` | Workflow spec for evaluations |
| `explore-projex.md` | Workflow spec for explorations |
| `plan-projex.md` | Workflow spec for creating plans |
| `execute-projex.md` | Workflow spec for executing plans |
| `close-projex.md` | Workflow spec for creating walkthroughs and finalizing branches |
| `patch-projex.md` | Workflow spec for quick-action patches |
| `simulate-projex.md` | Workflow spec for disposable simulations |
| `review-projex.md` | Workflow spec for reviewing existing projex documents |
| `redteam-projex.md` | Workflow spec for adversarial analysis |
| `audit-projex.md` | Workflow spec for auditing completed work |
| `interview-projex.md` | Workflow spec for interactive Q&A sessions |
