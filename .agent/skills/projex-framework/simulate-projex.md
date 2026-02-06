---
description: This workflow executes changes experimentally — freely making file modifications, observing outcomes and side-effects, then rolling back everything except the output documentation. Nothing persists but knowledge. (This is part of @projex-framework skill. It is a MUST to load the skill first.)
---

## PURPOSE

Simulations are disposable executions. Make real changes, run real builds, observe real outcomes — then throw it all away and keep only the report. The value is in what you learn, not what you ship.

**Key characteristics:**
- Freely and aggressively make file changes to observe outcomes
- All changes are rolled back — only the simulation document survives
- Ephemeral git branch (`projex/sim/{yyyymmdd}-{name}`) provides isolation and guaranteed clean rollback
- The branch is ALWAYS discarded. There is no merge option.
- Aggressive logging — the changes themselves vanish; only your notes survive. **If you don't write it down, it never happened.**
- **NEVER perform actions that cannot be rolled back**

---

## INVOCATION

```
/simulate-projex <directive or plan reference>
```

**Examples:**
- `/simulate-projex What happens if we replace the ORM with raw SQL queries in the user module?`
- `/simulate-projex Trial-run @20260201-api-migration-plan.md`
- `/simulate-projex Try switching from webpack to esbuild and see what breaks`
- `/simulate-projex Remove the legacy compatibility layer and observe test failures`

---

## IRREVERSIBILITY GUARD

**CRITICAL: Before and during every action, verify it can be undone by discarding the ephemeral git branch.**

### ALLOWED (Reversible via branch discard)

- Create, modify, or delete files within the repository
- Run local builds, compilers, transpilers
- Run tests, linters, formatters
- Execute local scripts that only affect the repo
- Install local dependencies (lockfile changes are git-tracked)
- Read external resources (documentation, APIs via GET)

### FORBIDDEN (Irreversible — NEVER do these)

| Action | Why |
|--------|-----|
| `git push` (any branch) | Exposes changes to remote/collaborators |
| External API mutations (POST/PUT/DELETE) | Cannot undo remote state changes |
| Database writes, migrations, seed operations | Mutates shared or persistent data |
| Package publishing (`npm publish`, `cargo publish`, etc.) | Published artifacts cannot be unpublished |
| Sending notifications (email, Slack, webhooks) | Messages cannot be unsent |
| Deploying to any environment | Affects running systems |
| Modifying files outside the repository | Not tracked by git, not rolled back |
| Destructive system commands (`rm` outside repo, `kill`, etc.) | Affects host system state |
| Generating or writing to persistent external storage | Data outlives the simulation |

**If an action's reversibility is uncertain — do NOT perform it.** Ask the user first.

**If the plan/directive requires a forbidden action:** Document it as "would do X here" in the simulation log without actually performing it. Note the expected outcome as speculative.

---

## WORKFLOW STEPS

### 1. PRE-SIMULATION

1. **Understand the directive** — What are we trying to learn or observe?
2. **Frame the simulation** — Define question, method, and observation targets
3. **Read relevant files** — Understand baseline state before making changes
4. **Check working state** — Ensure clean git state, no uncommitted changes

```
Frame the simulation as:
  QUESTION: [What we want to learn]
  METHOD:   [What changes we will make]
  OBSERVE:  [What outcomes we will measure/record]
```

### 2. CREATE EPHEMERAL BRANCH

```bash
git checkout -b projex/sim/{yyyymmdd}-{simulation-name}
```

Verify you are on the new branch before proceeding.

### 3. EXECUTE AND EXPLORE

Make changes aggressively. The branch will be discarded — there is no cost to experimentation. Try things you wouldn't in a real execution. Break things intentionally. Explore edge cases.

**For each action taken:**

1. **Record "before" state** — Capture relevant code snippets, file content, test baselines
2. **Make the change**
3. **Observe the outcome** — Run builds, tests, linters, or whatever reveals the impact
4. **Record findings** — Capture diffs, output, errors, observations
5. **Commit if useful** — Commits help track incremental changes; use `git diff` between commits to capture precise diffs for the report

```bash
# Commit convention within simulation (these commits will be discarded)
git add <files>
git commit -m "sim: [description of what was tried]"
```

**Simulations are not linear.** You may try approach A then revert and try approach B, stack changes to see cumulative effects, or partially implement to find hidden obstacles. Use git within the branch to manage iterations:

```bash
git checkout -- .           # Revert to baseline for a different approach
git stash / git stash pop   # Create savepoints within the simulation
```

Log each iteration separately — even failed attempts are valuable data.

**Useful diff commands:**
```bash
git diff main..HEAD                    # All changes vs baseline
git diff main -- path/to/file.ext     # Specific file vs baseline
git diff <earlier-commit>..HEAD        # Between simulation steps
```

### 4. GATHER FINAL OBSERVATIONS AND ROLLBACK

**This is your last chance to extract data.** Once the branch is deleted, the changes are gone.

1. Run full test suite, build, linter — capture all output
2. Capture final diffs: `git diff --stat main..HEAD` and `git diff main..HEAD`
3. Note any runtime observations (behavior differences, performance changes)

**Then rollback:**

```bash
# Step 1: Return to base branch — WAIT, verify "Switched to branch '...'"
git checkout main

# Step 2: Delete the ephemeral branch — WAIT, verify deletion
git branch -D projex/sim/{yyyymmdd}-{simulation-name}
```

**Verify:** Confirm base branch, branch deleted, working directory clean via `git status`.

**CRITICAL: Do NOT proceed to write the simulation document until rollback is verified complete.**

### 5. WRITE THE SIMULATION DOCUMENT

Now on the base branch with all changes rolled back, write the simulation report from gathered logs and observations.

Create: `{yyyymmdd}-{simulation-name}-simulation.md` in `projex/closed/` (simulations are born closed).

**Template:**

```markdown
# Simulation: [Title]

> **Date:** YYYY-MM-DD
> **Author:** [name or agent]
> **Directive:** [The original instruction/question]
> **Source:** [link to plan/proposal if applicable, otherwise "Direct"]
> **Related Projex:** [links to related projex documents]

---

## Question

[The specific question this simulation set out to answer]

---

## Method

[High-level description of what was tried — approach taken, files targeted, changes made]

---

## Execution Log

### Action 1: [Title]

**What was done:**
[Exact description — files changed, code written, commands run]

**Changes made:**
```[language]
// Before:
[original code/state]

// After:
[modified code/state]
```

**Observed outcome:**
```
[Build output, test results, errors, behavior, etc.]
```

**Interpretation:**
[What this tells us]

---

### Action N: [Title]

[Same structure]

---

## Iterations

> If multiple approaches were tried, document each:

### Approach A: [Name]
- **What:** [Changes made]
- **Result:** [What happened]
- **Verdict:** [Viable / Not viable / Partial]

### Approach B: [Name]
[Same structure]

---

## Observed Side-Effects

| Side-Effect | Severity | Description | Affected Files/Components |
|-------------|----------|-------------|---------------------------|
| [Effect 1] | Low/Med/High | [What happened] | [Where] |

---

## Test / Build Impact

### Test Results
| Suite/Test | Before | After | Delta |
|------------|--------|-------|-------|
| Total | X pass / Y fail | X pass / Y fail | [net change] |

### Build Results
- **Compiles:** Yes / No
- **Warnings:** [count and summary]
- **Errors:** [count and summary]

### Lint Results
- **New issues:** [count and summary]
- **Resolved issues:** [count and summary]

---

## Findings

### What Worked
- [Finding 1]

### What Broke
- [Finding 1 — what, why, severity]

### Surprises
- [Unexpected discovery 1]

### Blockers Discovered
- [Blocker 1 — what would prevent real execution]

---

## Feasibility Assessment

**Overall Verdict:** Feasible | Feasible with caveats | Not feasible

**Confidence:** High | Medium | Low

**Reasoning:**
[Why this verdict — supported by evidence from the simulation]

**Estimated Effort (if executed for real):**
[Based on actual experience during simulation — what would it take?]

**Prerequisites for Real Execution:**
- [What must be true or in place before this could be done for real]

---

## Recommendations

### If Proceeding
- [Recommendation 1 — approach to take, pitfalls to avoid]

### If Not Proceeding
- [Alternative approach to consider]

### Follow-up Projex Suggested
| Type | Description |
|------|-------------|
| [Plan/Proposal/Eval/etc.] | [What and why] |

---

## Appendix

### Key Diffs

> Preserved diffs from the simulation (the branch no longer exists):

#### [File or change description]
```diff
[captured diff output]
```

### Raw Output
```
[build output, test output, error logs, etc.]
```

### Actions NOT Taken (Irreversible)

| Action | Expected Outcome (Speculative) | Why Skipped |
|--------|-------------------------------|-------------|
| [action] | [what we think would happen] | [irreversibility reason] |
```

### 6. COMMIT AND UPDATE RELATED DOCUMENTS

```bash
git add projex/closed/{yyyymmdd}-{simulation-name}-simulation.md
git commit -m "projex(sim): add simulation report - {simulation-name}"
```

If the simulation was against an existing plan or proposal:
- Add a reference to the simulation in the source document's Related Projex section
- Note the simulation's verdict and key findings
- If blockers were found, update the source document's risks/open questions

```bash
git add [updated related documents]
git commit -m "projex(sim): update related projex - {simulation-name}"
```

---

## QUALITY CHECKLIST

- [ ] Ephemeral branch deleted, back on base branch with clean state
- [ ] Simulation document captures all key changes as diffs/snippets
- [ ] All observations (build, test, lint, runtime) recorded
- [ ] Side-effects documented
- [ ] Feasibility verdict provided with supporting evidence
- [ ] No forbidden irreversible actions were taken
- [ ] Simulation document placed in `projex/closed/`
- [ ] Related projex documents updated (if applicable)
- [ ] All commits on base branch are documentation only

---

## NOTES

- The simulation document must be self-contained — the branch is gone, if it's not in the doc, it's lost
- Report what actually happened, not what you hoped would happen — a simulation proving an approach won't work is equally valuable
- If a simulation proves viability, the natural next step is `/plan-projex` or `/patch-projex`
- Multiple simulations can explore different approaches to the same question
- Use relative paths when referencing repository files
- The `projex(sim):` commit prefix distinguishes simulation docs in git history
- **When in doubt about reversibility, don't do it**
