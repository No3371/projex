---
name: projex-framework
description: A workflow framework to organize objectives all by file management in filesystem. Load this skill and another document with the called name when the user mentions `close-projex`, `eval-projex`, `execute-projex`, `plan-projex`, `propose-projex`, `review-projex`, `explore-projex`, `redteam-projex`, `audit-projex`, `interview-projex`, `patch-projex`, `simulate-projex`, `navigate-projex`.
---

Implementing Projex revolves around authoring/maintenance/executing self-contained unit markdown documents in folders named "projex". There are several types of unit documents: 

- Proposal
    - Explores a specific direction — "what if we go this way?" — with trade-offs, approaches, and impact analysis
    - Captures reasoning and options for a concrete change or idea before committing
    - Directional: proposes something specific vs open-ended analysis (see Evaluation) or status quo investigation (see Exploration)
    - Progresses from Draft → Review → Accepted/Rejected
    - WORKFLOW SPECIFICATION -> @./propose-projex.md 
- Plan
    - Actionable task documents capturing a specifc problem/gap/need, with clear objectives backed by rich context and rationale
    - WHAT needs to be done, and HOW to implement it, exact what changes to what files
    - Easy to parse, understood, followed and executed by any LLM or human
    - Granular split and derivation with clear scopes and boundaries
    - Closed ended with clear acceptance/success criteria or actionable outcomes
    - WORKFLOW SPECIFICATION -> @./plan-projex.md
    - EXECUTION WORKFLOW -> @./execute-projex.md
- Evaluation
    - Open-ended analysis, assessment, or research into any question, idea, or solution
    - The broadest analytical tool — can be systematic scrutiny, open exploration of an idea, comparative research, or deep-dive into a solution
    - Research essence, paradigm, value and scope; explore underlying principles, assumptions, and prior work
    - Adapt depth and focus based on context. Emphasize rigor, clarity, and intellectual honesty
    - Unlike Proposal (directional) or Exploration (status-quo-grounded), Eval has no fixed framing
    - WORKFLOW SPECIFICATION -> @./eval-projex.md 
- Review
    - Inspection report against prior made projex documents, ensuring they are up-to-date, comaptible with status quo, still valid, complete, accurate and valuable
    - As projex unit documents can be created, read, or executed in any order and any time, they can become outdated or invalid over time or after new changes. Review projex answers these important questions:
        - When was the projex authored? What happened after that? What is the status quo?
        - Does the idea or the plan still stands? Is it still compliant to latest spec or design?
        - Should we expand the projex, for status quo now has additions that should be covered by the projex? Or should we modify the projex, for it's no longer correct, complete or accurate?
    - Examine the projex from high level, bigger picture without being misled by the original content/entities/subjects, explore status quo and ask open quesiton
    - Challenge the idea. Challenge the projex. Ask extra challenge questions against the projex in question.
    - WORKFLOW SPECIFICATION -> @./review-projex.md
- Red Team
    - Adversarial analysis that challenges assumptions, finds weaknesses, exploits edge cases, and identifies imperfections
    - Identifies all stakeholder roles and attacks from each role's perspective
    - Assumes everything is wrong until proven otherwise through evidence
    - Discovers failure modes, edge cases, and security vulnerabilities before production
    - Provides actionable remediation for found issues
    - WORKFLOW SPECIFICATION -> @./redteam-projex.md
- Audit
    - Suspicious, rigorous validation of completed work through inspection of docs/reports/logs/code
    - Cross-references claims against actual artifacts and evidence
    - Assesses completeness, correctness, quality, and value delivered beyond just completion status
    - Discovers undocumented issues, gaps, and technical debt through open exploration
    - Verifies stakeholder impact and produces evidence-based findings
    - WORKFLOW SPECIFICATION -> @./audit-projex.md
- Interview
    - Interactive Q&A session between LLM and user scoped to specific topics/subjects/files
    - Conducted in rounds with 3-5 questions per round, asked sequentially one-by-one
    - Full transcript logging: questions, raw answers, and agent interpretations
    - Extracts requirements, clarifies designs, gathers knowledge, or validates understanding
    - User controls continuation or conclusion after each round
    - READ-ONLY: No actions taken during interview, only the interview document is written
    - WORKFLOW SPECIFICATION -> @./interview-projex.md
- Walkthrough
    - Followup projex authored after EVERY Plan execution
    - Complete list of whatever happened for each objectives of the Plan projex, each with extremely details down to file changes and line numbers
    - Acceptance/Success criteria checklist and proof of verification measure taken
    - Additional key insights for future references, such as lessions learned, pattern discoveries, gotchas/pitfalls encounters
    - WORKFLOW SPECIFICATION -> @./close-projex.md 
- Patch
    - Quick-action projex that skips the full Plan → Execute → Close cycle for small, well-understood changes
    - Immediately takes action, commits directly to current branch (no ephemeral branch)
    - Single output document serves as both record and walkthrough — patches are born closed
    - Scope-guarded: escalates to full plan-execute if complexity exceeds patch threshold
    - Can execute specific objectives from existing plans without running the full plan
    - Related projex and documents are still updated to match post-patch status
    - WORKFLOW SPECIFICATION -> @./patch-projex.md
- Simulation
    - Disposable execution that freely makes file changes, observes outcomes and side-effects, then rolls back everything
    - Only the simulation document survives — all code changes are discarded
    - Uses ephemeral git branch for isolation and guaranteed clean rollback
    - Strictly forbidden from performing any irreversible actions (no push, no external API mutations, no publishing, no deploys)
    - Produces a feasibility assessment, side-effect analysis, and actionable recommendations
    - Can trial-run existing plans or explore "what if" scenarios with real changes
    - WORKFLOW SPECIFICATION -> @./simulate-projex.md
- Navigation
    - Living roadmap that evolves throughout development and steers work forward at any scale — from entire project down to a single module or feature area
    - Milestones and phases at the appropriate abstraction for the scope, not implementation details one level below — the document that answers "what should we work on next?" for its scope
    - Continuously revised — each invocation researches status quo, assesses progress, discusses with user, and revises direction
    - References child projex (plans, proposals, evals) as they are spawned from the roadmap
    - Nestable — project-level navigations can reference module-level ones, and vice versa
    - Never closed — stays active in its scope's `projex/` folder until superseded
    - WORKFLOW SPECIFICATION -> @./navigate-projex.md
- Exploration
    - Investigation grounded in the status quo — map what exists, how it works, and why, to inform decisions and answer questions
    - Unlike Eval (open-ended, any framing) or Proposal (directional), Exploration is anchored to current reality
    - WORKFLOW SPECIFICATION -> @./explore-projex.md

## Authoring

Projex documents should be named in this format: `{yyyymmdd}-{projex-name}-{projex-type}.md`

While each type of projex have different characteristics therefore need to be formatted differently, some common patterns are applied to most, if not all types:
- Projexs often relates to other ones. A project may be directly or indirectly related to existing projects, or derive or split into multiple projects. These relationships must be added/maintained in all involve projex documents.
- Once a projex is authored, it should be refined once to put the general important info (that helps quick assessment at a glance) to the beginning of the file.

## Organizing

Projex files are always nested inside folders named "projex", but actual file location depends on projex states.

A pending projex usually just resides in the parent "projex" folder, regardless the type; Closed projex and the walkthrough should be placed in "projex/closed" folder; If a projex is archived (unlikely to continue), it should be in "projex/archived". Abandoned projexs usually just get deleted by the user, but would be in "projex/abandoned" if any.

Furthermore, a repo/project may have multiple "projex" folders in different path, each dedicated to individual module/component/domain/areas, etc. For example, a language design project, may have separate path to store language spec, implementation spec (general description and pseudo code for any implementing language, derived from langauge spec), poc runtime implementation (derived from and constantly reflects impl specs); These should be decoupled and their Projex files should be individually managed. New Projex files should not cover more than 1 area or violate dependencies.

**Examples**
```
your-repo/
├── projex/           # Master projexs
│   ├── closed/
│   │   └── closed_project.md
│   ├── project.md
│   └── ...
├── docs/              # Specifications and documentation
│   ├── projex/ # doc projexs
│   │   ├── abandoned/
│   │   │   └── ... 
│   │   ├── project.md
│   │   └── ... 
│   └── ...
├── src/               # Source code
│   └── projex/ # src projexs
│       ├── project.md
│       └── ... 
└── projex-framework.md

```

## Workflow

Workflow spec files are the "actions", containing clear instruction to work with projex files. They are referenced in verb sense.

Workflow usages/invocations examples:
- `/propose-projex.md I want to add XXX feature.`
- `/eval-projex.md Does current spec compatible with this proposal?` or `/eval-projex.md What can be improved in the current implementation?`
- `/plan-projex.md Update current impl to keep up with latest specs.` or `/plan-projex.md @20260731-database-service-refactor-proposal.md`
- `/review-projex.md @20260731-language-macro-syntax-change-proposal.md` or `/review-projex.md the project we just made`
- `/redteam-projex.md @20260731-auth-system-plan.md` or `/redteam-projex.md current API design`
- `/audit-projex.md @20260731-auth-system-plan.md` or `/audit-projex.md the database migration we just finished`
- `/interview-projex.md authentication system design` or `/interview-projex.md user requirements for the new feature`
- `/patch-projex.md Fix the off-by-one error in the parser loop` or `/patch-projex.md Execute objective 2 of @20260201-api-cleanup-plan.md`
- `/simulate-projex.md What happens if we remove the legacy compatibility layer?` or `/simulate-projex.md Trial-run @20260201-api-migration-plan.md`
- `/navigate-projex.md Game engine project roadmap` or `/navigate-projex.md @20260201-engine-roadmap-nav.md`
- `/execute-projex.md @20260731-language-macro-syntax-change-plan.md`
- `/close-projex.md` after the user reviewed the result of /execute-projex.

## Git Integration

The **Execute → Walkthrough** cycle is wrapped in an ephemeral git branch to provide isolation, traceability, and clean rollback.

### Ephemeral Branch Lifecycle

```
[base branch] ─── execute-projex ───> [ephemeral branch] ─── close-projex ───> [merge/squash back]
                  (branch created)     (changes made here)    (branch finalized)
```

**Branch naming:** `projex/{yyyymmdd}-{plan-name}`

### Workflow

1. **`/execute-projex.md`** — Creates ephemeral branch from current HEAD before any changes
2. **Execution** — All plan implementation happens in the ephemeral branch
3. **`/close-projex.md`** — Finalizes the branch with user choice:
   - **Squash merge** — Clean single commit to base branch (default)
   - **Merge** — Preserve full commit history
   - **Rebase** — Replay commits onto base
   - **Abandon** — Delete branch without merging (failed execution)

### Benefits

- **Isolation** — Execution changes don't affect base branch until verified
- **Rollback** — Easy to discard failed executions
- **Traceability** — Branch name links directly to plan
- **Review** — Changes can be reviewed before merge (PR optional)

### Prerequisites

- **Plan must be committed to base branch before execution** — The plan document must exist in git history on the base branch. This ensures:
  - Plans are reviewable before execution
  - Plans persist even if execution is abandoned
  - Clean separation: base branch = plans, ephemeral branch = execution

### Multi-Repo Awareness

Workspaces may contain multiple related repositories side by side. Before any git operation or projex file manipulation:

- **Confirm which repo you are in** — Run `git rev-parse --show-toplevel` if uncertain. Never assume the working directory matches the intended repo.
- **Match projex to repo** — Each `projex/` folder belongs to the repo whose root contains it. Do not create, move, or reference projex documents across repo boundaries.
- **Scope git commands to the correct repo** — A `git add`, `git commit`, or `git checkout` in the wrong repo is silently destructive. When the workspace root is not itself a repo, always verify your cwd or use `-C <repo-path>` before running git commands.

### Git Operation Discipline

**CRITICAL: Git commands must be executed sequentially, one at a time, waiting for each to complete and verifying success before proceeding.**

- **Never parallelize git operations** — Each git command must finish before the next begins
- **Verify success** — Check exit code and output before proceeding
- **No assumptions** — Don't assume a command succeeded; confirm it
- **Handle failures** — If a git operation fails, stop and address it before continuing
- **Stage files by explicit path** — Always `git add` each file by its exact path. Never use `git add .`, `git add -A`, directory paths, or wildcards. This prevents accidentally staging unintended files (secrets, build artifacts, unrelated changes).

```bash
# WRONG - parallel/batched
git add file1.txt & git add file2.txt & git commit -m "msg"

# WRONG - imprecise staging
git add .
git add -A
git add projex/closed/
git add src/

# CORRECT - sequential with explicit file paths
git add file1.txt        # wait, verify success
git add file2.txt        # wait, verify success
git commit -m "msg"      # wait, verify commit created
```

### Notes

- Execute/Walkthrough and Simulation workflows use ephemeral branches
- Simulation branches (`projex/sim/`) are always discarded — only the report is committed to base branch
- Proposal, Plan, Eval, Review, Navigation workflows operate on current branch and should be committed normally
- If execution spans multiple sessions, branch persists until close
- Walkthrough document is committed as final commit before merge

---

## NOTES

### AVOID ABSOLUTE PATHS
USE file paths RELATIVE to project root to reference files in the repo. REDACT paths to files external to the repo.

### PARALLELIZATION DISCIPLINE
If subsequent actions/commmands/toolcalls depends on prior ones, DO NOT parallel/burst them, split them up instead.