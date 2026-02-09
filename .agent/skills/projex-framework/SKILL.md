---
name: projex-framework
description: When the user mentions `close-projex`, `eval-projex`, `execute-projex`, `plan-projex`, `propose-projex`, `review-projex`, `explore-projex`, `redteam-projex`, `audit-projex`, `interview-projex`, `patch-projex`, `simulate-projex`, `navigate-projex`, `map-projex`, `guide-projex`, load this skill and the document with the mentioned name.
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
- **Patch** — Quick-action for small, well-understood changes. Skips Plan → Execute → Close — born closed. Can execute specific objectives from existing plans. Escalates if complexity exceeds threshold. WORKFLOW -> @./patch-projex.md
- **Simulation** — Disposable execution: makes changes, observes outcomes, rolls back everything. Only the report survives. No irreversible actions. Can trial-run plans or "what if" scenarios. WORKFLOW -> @./simulate-projex.md
- **Navigation** — Living roadmap at any scale. Continuously revised each invocation. Nestable. Never closed. WORKFLOW -> @./navigate-projex.md
- **Map** — Living structural index of directories/key files. Incrementally built, scope-flexible. Never closed. WORKFLOW -> @./map-projex.md
- **Exploration** — Status-quo-grounded investigation: map what exists, how it works, and why. Unlike Eval (open-ended) or Proposal (directional). WORKFLOW -> @./explore-projex.md
- **Guide** — Curated reading path for human learners. Phased steps with focus cues and takeaways. Sources span code, docs, specs, external pages. Closed by default. WORKFLOW -> @./guide-projex.md

## Authoring

File naming: `{yyyymmdd}-{projex-name}-{projex-type}.md`

- Cross-reference related projex in all involved documents
- Front-load key info for quick assessment at a glance
- **Reference by filename, not path** — Projex files move between folders (active → closed → archived), so relative paths break. Use the filename alone: `20260208-virtual-checkpoint-token-impl-doc-plan.md`, not `../../../impl/projex/20260208-virtual-checkpoint-token-impl-doc-plan.md`. Filenames are unique by date-prefix convention.

## Organizing

Files live in `projex/` folders in one or more paths (each dedicated to a individual domain/module/components/area/scope, etc.). Location in projex folders reflects state:
- Active → `projex/`
- Closed → `projex/closed/`
- Archived → `projex/archived/`
- Abandoned → `projex/abandoned/` (or deleted)

A repo may have multiple `projex/` folders scoped to different areas (e.g., `docs/projex/`, `src/projex/`). Each is independently managed. New projex should not cross area boundaries or violate dependencies, for example a language spec update projex should not touch runtime implementation, and vice versa.

```
your-repo/
├── projex/              # Master projexs
│   ├── closed/
│   └── ...
├── docs/projex/         # Doc-scoped projexs
├── src/projex/          # Src-scoped projexs
└── ...
```

## Workflow

Workflow specs are actions invoked in verb sense:

- `/propose-projex.md I want to add XXX feature.`
- `/eval-projex.md Does current spec compatible with this proposal?` or `/eval-projex.md What can be improved in the current implementation?`
- `/plan-projex.md Update current impl to keep up with latest specs.` or `/plan-projex.md @20260731-database-service-refactor-proposal.md`
- `/review-projex.md @20260731-language-macro-syntax-change-proposal.md`
- `/redteam-projex.md @20260731-auth-system-plan.md`
- `/audit-projex.md the database migration we just finished`
- `/interview-projex.md authentication system design`
- `/patch-projex.md Fix the off-by-one error in the parser loop` or `/patch-projex.md Execute objective 2 of @20260201-api-cleanup-plan.md`
- `/simulate-projex.md What happens if we remove the legacy compatibility layer?`
- `/navigate-projex.md Game engine project roadmap` or `/navigate-projex.md @20260201-engine-roadmap-nav.md`
- `/map-projex.md Whole project structure`
- `/guide-projex.md Understand our authentication system end-to-end`
- `/execute-projex.md @20260731-language-macro-syntax-change-plan.md`
- `/close-projex.md` after user reviewed execution results

## Git Integration

The **Execute → Walkthrough** cycle uses an ephemeral branch for isolation and clean rollback.

```
[base branch] ── execute-projex ──> [projex/{yyyymmdd}-{plan-name}] ── close-projex ──> [merge back]
```

1. `/execute-projex.md` creates ephemeral branch from current HEAD
2. All implementation happens in the ephemeral branch
3. `/close-projex.md` finalizes: squash merge (default), merge, rebase, or abandon

**Prerequisite:** Plan must be committed to base branch before execution — ensures plans survive abandoned executions and are reviewable independently.

### Multi-Repo Awareness

Before any git operation, confirm which repo you are in (`git rev-parse --show-toplevel`). Match projex to the repo whose root contains them. Scope git commands accordingly — wrong-repo operations are silently destructive.

### Git Operation Discipline

**CRITICAL: Each git operation must be its own sequential tool call. Never mix different git operation types (add, commit, checkout, branch, merge, rebase, stash) in parallel tool calls.**

- **One operation type at a time** — A commit must not be issued until all staging is verified. A branch switch must not coincide with a commit. Never burst add + commit + checkout as parallel calls.
- **Read output before proceeding** — After each git command, actually read its output and confirm it succeeded. Do not fire-and-forget — if `git add` errors or warns, you must catch it before committing.
- **Stop on failure** — If any git operation fails, address it before continuing
- **Stage by explicit path** — `git add <file> ...` by exact path. Never `git add .`, `git add -A`, `git add -u`, directories, or wildcards

```bash
# WRONG — parallel burst of different operation types
git add file.txt  |  git commit -m "msg"  |  git checkout -b new-branch

# WRONG — imprecise staging
git add .

# CORRECT — sequential, one operation type per step
git add file1.txt file2.txt    # verify success
git commit -m "msg"            # verify commit created
git checkout -b new-branch     # verify branch switched
```

### Notes

- Execute/Walkthrough and Simulation use ephemeral branches
- Simulation branches (`projex/sim/`) always discarded — only report committed to base
- Other workflows operate on current branch, committed normally
- Walkthrough committed as final commit before merge

---

## NOTES

### AVOID ABSOLUTE PATHS
Use file paths RELATIVE to project root. REDACT external paths.

### PARALLELIZATION DISCIPLINE
If subsequent actions depend on prior ones, DO NOT parallel them.
