---
description: This workflow guides the creation of **Walkthrough** projex documents — comprehensive records authored after every Plan execution. (This is part of @projex-framework skill. It is a MUST to load the skill first.)
---

## PURPOSE

Walkthroughs capture what actually happened during execution. They provide complete traceability, verify success criteria, and preserve insights for future reference.

**Key characteristics:**
- Complete record of execution outcomes
- Detailed file changes down to line numbers
- Success criteria verification with proof
- Lessons learned and pattern discoveries

---

## INVOCATION

```
/close-projex.md
```

**Timing:** Invoke when the projex is ready to close — all criteria satisfied AND closing is allowed (user instructed to close, or projex is marked auto-close). See execute-projex.md § CLOSING for the full protocol.

---

## PREREQUISITES

Before closing:

- [ ] Plan execution is complete (status is `Complete` or `Blocked`)
- [ ] User has reviewed and is satisfied — OR projex is marked `Auto-Close: Yes`
- [ ] All success criteria are verifiable
- [ ] Execution log/notes are available (including any user interventions — mid-execution and post-plan)
- [ ] Currently on ephemeral branch `projex/{yymmddhhmm}-{plan-name}`
- [ ] All execution changes are committed (including changes from user interventions)

---

## WORKFLOW STEPS

### 0. RESOLVE REPO AND BASE BRANCH

**Resolve the target repo**: we find the exact git repo the projex belongs to.

```bash
cd <absolute-path-to-projex-file-directory> && git rev-parse --show-toplevel && git branch --show-current
```

Record the `--show-toplevel` output as `<repo-root>`. All script calls below use this value.

- [ ] **Correct repository** — `rev-parse --show-toplevel` matches the repo that owns the plan's `.projex/` folder

Read the `Base Branch:` field from the execution log (`{yymmddhhmm}-{plan-name}-log.md`). All git commands below use `{base-branch}` — **never assume `main`**.

If the execution log is missing or lacks the field, determine the base branch by asking the user.

### 1. GATHER EXECUTION DATA

Collect all information from the execution:

#### From the Plan
1. Original objectives
2. Success/acceptance criteria
3. Planned steps
4. Expected file changes

#### From Execution
1. What actually happened for each step
2. Any deviations from plan
3. Issues encountered and resolutions
4. Actual file changes made

#### From Verification
1. Test results
2. Verification outcomes
3. User feedback

### 2. DOCUMENT ACTUAL CHANGES

**IMPORTANT: Document what actually happened, not what was planned.** The walkthrough is a historical record of reality.

1. **Query git for actual changes:**

```bash
# List all commits in ephemeral branch
git log --oneline {base-branch}..HEAD

# See all files changed
git diff --stat {base-branch}..HEAD

# Get detailed diff
git diff {base-branch}..HEAD
```

2. **For each file changed, record:**
   - File path
   - Change type (created/modified/deleted)  
   - Specific changes (line numbers, actual before/after)
   - Purpose of change
   - **Whether this matches or deviates from plan**

3. **Compare against plan:**
   - Files in plan but not changed → Document why (already done? not needed? blocked?)
   - Files changed but not in plan → Document why (discovered during execution? dependency?)
   - Changes different from plan → Document what and why

### 3. VERIFY SUCCESS CRITERIA

For each success criterion from the plan:

1. **State the criterion**
2. **Document verification method used**
3. **Record the evidence/proof**
4. **Mark pass/fail with notes**

### 4. CAPTURE INSIGHTS

Document learnings:

- **Lessons learned** — What would you do differently?
- **Pattern discoveries** — New patterns identified
- **Gotchas/pitfalls** — Traps encountered
- **Reusable knowledge** — Insights for future work

### 5. DRAFT THE WALKTHROUGH

Create a new file: `{yymmddhhmm}-{plan-name}-walkthrough.md`

**Template Structure:**

```markdown
# Walkthrough: [Plan Title]

> **Execution Date:** YYYY-MM-DD
> **Completed By:** [name or agent]
> **Source Plan:** [link to plan document]
> **Duration:** [how long execution took]
> **Result:** Success | Partial Success | Failed

---

## Summary

[2-3 sentences: What was accomplished and final outcome]

---

## Objectives Completion

| Objective | Status | Notes |
|-----------|--------|-------|
| [Objective 1 from plan] | Complete/Partial/Failed | [Details] |
| [Objective 2 from plan] | Complete/Partial/Failed | [Details] |

---

## Execution Detail

> **NOTE:** This section documents what ACTUALLY happened, derived from git history and execution notes. 
> Differences from the plan are explicitly called out.

### Step 1: [Step Title from Plan]

**Planned:** [What the plan specified]

**Actual:** [What was actually done — be specific, cite actual code/files]

**Deviation:** [None / Description of deviation and reasoning]
- If different from plan: WHY? (discovered issue, better approach, prerequisite missing, etc.)

**Files Changed (ACTUAL):**
| File | Change Type | Planned? | Details |
|------|-------------|----------|---------|
| `path/to/file.ext` | Modified | Yes | Lines 45-67: [actual changes made] |
| `path/to/new.ext` | Created | No | [why this was added] |

**Verification:** [How this step was verified — actual results]

**Issues:** [Any issues encountered and how resolved]

---

### Step 2: [Step Title]

[Same structure as Step 1]

---

### Step N: [Final Step]

[Same structure]

---

## Complete Change Log

> **Derived from:** `git diff --stat {base-branch}..HEAD` — This is the authoritative record of what changed.

### Files Created
| File | Purpose | Lines | In Plan? |
|------|---------|-------|----------|
| `path/to/file.ext` | [What it does] | [line count] | Yes/No |

### Files Modified
| File | Changes | Lines Affected | In Plan? |
|------|---------|----------------|----------|
| `path/to/file.ext` | [Summary of changes] | [line ranges] | Yes/No |

### Files Deleted
| File | Reason | In Plan? |
|------|--------|----------|
| `path/to/file.ext` | [Why deleted] | Yes/No |

### Planned But Not Changed
| File | Planned Change | Why Not Done |
|------|----------------|--------------|
| `path/to/file.ext` | [What was planned] | [Reason: blocked, not needed, deferred, etc.] |

---

## Success Criteria Verification

### Criterion 1: [Criterion from Plan]

**Verification Method:** [How it was tested]

**Evidence:**
```
[Actual output, test results, or proof]
```

**Result:** PASS / FAIL

---

### Criterion 2: [Criterion]

[Same structure]

---

### Acceptance Criteria Summary

| Criterion | Method | Result | Evidence |
|-----------|--------|--------|----------|
| [Criterion 1] | [Method] | Pass/Fail | [Link or ref] |
| [Criterion 2] | [Method] | Pass/Fail | [Link or ref] |

**Overall:** [X/Y criteria passed]

---

## Deviations from Plan

### Deviation 1: [Title]
- **Planned:** [What was planned]
- **Actual:** [What was done instead]
- **Reason:** [Why the deviation occurred]
- **Impact:** [Effect on outcome]
- **Recommendation:** [Should plan be updated?]

---

## Issues Encountered

### Issue 1: [Title]
- **Description:** [What happened]
- **Severity:** Low/Medium/High
- **Resolution:** [How it was fixed]
- **Time Impact:** [How long it delayed]
- **Prevention:** [How to avoid in future]

---

## Key Insights

### Lessons Learned

1. **[Lesson Title]**
   - Context: [When/why this was learned]
   - Insight: [The actual lesson]
   - Application: [How to apply in future]

2. **[Lesson Title]**
   [Same structure]

### Pattern Discoveries

1. **[Pattern Name]**
   - Observed in: [Where it was found]
   - Description: [What the pattern is]
   - Reuse potential: [Where else it applies]

### Gotchas / Pitfalls

1. **[Gotcha Title]**
   - Trap: [What the pitfall is]
   - How encountered: [How you ran into it]
   - Avoidance: [How to prevent]

### Technical Insights

- [Insight about the codebase]
- [Insight about tools/frameworks]
- [Insight about process]

---

## Recommendations

### Immediate Follow-ups
- [ ] [Action that should happen soon]
- [ ] [Related task to consider]

### Future Considerations
- [Long-term improvement to consider]
- [Technical debt identified]

### Plan Improvements
If this plan were to be executed again:
- [What should change in the plan]
- [Missing information that would help]

---

## Related Projex Updates

### Documents to Update
| Document | Update Needed |
|----------|---------------|
| [Plan document] | Mark as Complete |
| [Proposal document] | Link to walkthrough |

### New Projex Suggested
| Type | Description |
|------|-------------|
| Plan | [Follow-up work identified] |
| Proposal | [New idea discovered] |

---

## Appendix

### Execution Log
```
[Raw execution notes/log if useful]
```

### Test Output
```
[Relevant test or verification output]
```

### References
- [Links to relevant commits, PRs, or documents]
```

### 6. FINALIZE DOCUMENTS

1. **Update the source plan:**
   - Change status to `Complete`
   - Add links to **both** the walkthrough and the execution log — filenames only, never paths:

```markdown
> **Completed:** YYYY-MM-DD
> **Walkthrough:** {yymmddhhmm}-{name}-walkthrough.md
> **Log:** {yymmddhhmm}-{name}-log.md
```

   `Log:` may already be present from execute-projex POST-EXECUTION — verify it names the real file rather than assuming. Writing it here is what makes the log discoverable from the plan: nothing else links plan → log, so a plan closed without this field leaves its log unreachable by any later sweep or audit.

2. **Reconcile the execution log's status with the plan's** — open the log and confirm its `> **Status:**` is terminal (`Complete` or `Blocked`) and matches what you just wrote on the plan. If execute-projex left it at `In Progress`, set it now. The log has no closed state of its own — like the plan, its move into `.projex/closed/` is what marks it closed. Opening the file here is deliberate: it is the step that puts the log's real filename in front of you before the sweep below.

3. **Sweep every projex document this plan's lifecycle touched:** the execution log (`{yymmddhhmm}-{plan-name}-log.md`) always, plus anything produced against the plan if it exists (Proposal, Memo, Red Team, Audit, Review, Eval, Interview, Coach, Exploration, Imagination, ...). Check the plan's `Source:` and `Related Projex:` fields, and anything else that references this plan, then sort each by its type's closing rule (SKILL.md § Organizing):

   | Type's closing rule | Action |
   |---|---|
   | Never closed (Definition) | Update in place — never move |
   | Navigation | Update in place — closing a plan never closes a nav (see below) |
   | Born closed already (Patch, Scan, Debug, Simulation, Guide, Archive) | Already in `closed/` — nothing to move |
   | Born open → Closed (Proposal, Memo, Evaluation, Review, Red Team, Audit, Interview, Coach, Exploration, Imagination) | If this plan's completion **addresses/resolves** it, close it now alongside the plan. If it's still open on an unrelated concern, leave it active and update its link to the walkthrough |
   | Dependent plans not yet complete | Update the link only — they close on their own cycle |

   **Nav:** if the plan notes `> **Nav:** {nav-filename}`, update that nav only — check off the milestone, link the walkthrough, append a Revision Log entry. Skip navs not referenced by the plan. Navigations close only through their own closing workflow (navigate-projex § CLOSING A NAVIGATION) — even if this plan completes the nav's last milestone, do not close it here; flag it to the user as a closure candidate instead.

   Result: a list of documents (the Plan, its execution log, plus zero or more others) moving to `closed/` together.

4. **Move every document from step 3 in one `move-n-stage` call** — one src/dst pair per document, staged atomically in a single operation:

```bash
{projex-scripts}/move-n-stage.{sh|ps1} <repo-root> \
  .projex/{yymmddhhmm}-{name}-plan.md .projex/closed/{yymmddhhmm}-{name}-plan.md \
  .projex/{yymmddhhmm}-{name}-log.md .projex/closed/{yymmddhhmm}-{name}-log.md \
  .projex/{yymmddhhmm}-{doc-a}.md .projex/closed/{yymmddhhmm}-{doc-a}.md \
  .projex/{yymmddhhmm}-{doc-b}.md .projex/closed/{yymmddhhmm}-{doc-b}.md \
  ... (one pair per document from step 3)
```

Write the new Walkthrough file directly at `.projex/closed/{yymmddhhmm}-{name}-walkthrough.md` — newly created, not moved.

5. **Commit the walkthrough, every move, and any in-place updates (nav, still-open related docs) in one commit.** Splitting across commits leaves some documents in `closed/` with siblings still active:

```bash
# One path per document moved or updated this close — include only what applies:
{projex-scripts}/stage-n-commit.{sh|ps1} <repo-root> "projex: close {plan-name} - add walkthrough" \
  .projex/closed/{yymmddhhmm}-{name}-walkthrough.md \
  .projex/closed/{yymmddhhmm}-{name}-plan.md \
  .projex/closed/{yymmddhhmm}-{name}-log.md \
  .projex/closed/{yymmddhhmm}-{doc-a}.md \
  .projex/closed/{yymmddhhmm}-{doc-b}.md \
  .projex/{yymmddhhmm}-{nav-name}-nav.md
```

---

### 7. FINALIZE GIT BRANCH

**GATE: two checkouts, two different bars.** Execution may *begin* against a dirty originating worktree — that is what worktree mode is for — but finalization has requirements in both places:

| Checkout | Bar | Why |
|---|---|---|
| Originating/base worktree (`<repo-root>`) | **No tracked changes.** Untracked and ignored files may stay. A dirty submodule alone does not count. | This is where the merge / fast-forward lands. Tracked index or worktree content is what an integration can consume or a rollback discard. |
| Child execution worktree (`{repo-name}/.projexwt/<name>`) | **Fully clean** — no untracked entries either. | It is about to be deleted, so anything left in it is lost. |

**Originating/base worktree:**

```bash
git -C <repo-root> status --porcelain --untracked-files=no --ignore-submodules=dirty
```

If output is non-empty, commit or stash those changes before continuing. The most common offender is the plan file — if it was updated but not committed, stage and commit it now. Untracked files (`??`) do **not** block: busy repos keep them, and `.projexwt/` itself shows up as untracked wherever the `.git/info/exclude` registration is missing.

**Worktree mode — also check the execution worktree for leftovers:**

```bash
git -C <worktree-path> status --porcelain --ignored=matching
```

Untracked (`??`) or modified/staged tracked (`M`/`A`) entries: commit them or remove agent-created tooling — the finalization scripts exit (before any merge) rather than merge from a stale commit or risk deleting untracked files. Ignored (`!!`) entries (deps, build output): remove agent-created ones now; they don't block git-level removal but can make it fail half-way on some filesystems.

**These are pre-flight checks, not enforcement.** Every finalizer applies both gates itself, independently of this workflow — but each is a single check before the operation, and nothing re-checks between the check and the mutation. An IDE autosave, a file watcher, or a parallel agent can still dirty the tree inside that window. Git's own refusal to overwrite tracked or untracked paths remains the real backstop. Do not treat a passing gate as a licence to leave work uncommitted.

The ephemeral branch must be finalized. Present options to user.

**Worktree mode:** If execution used a worktree (`{repo-name}/.projexwt/`), pass `--worktree` to the finalization script. The script merges first, then removes the worktree as best-effort cleanup (abandon removes it directly). A removal failure never undoes the close — the script reports what remains. The originating/base worktree is already on the base branch — no checkout needed.

**`<repo-root>` and `{base-branch}` must match each other.** `<repo-root>` is the *recorded originating worktree* — whichever worktree the execution branched from, which is not necessarily the repository's primary checkout. `{base-branch}` is its recorded parent branch. Finalizers assert that `<repo-root>` still has `{base-branch}` checked out and exit `1` without changing anything if it does not; they never search for another worktree or fall back to `main`/`master`. This keeps stacked work honest — a child of `projex/outer` closes into `projex/outer` at the utility worktree that holds it, never into `main`.

`{base-branch}` must also be a **local branch** — any local branch, including a utility or outer Projex branch, but not a tag, a raw SHA, or a remote-tracking ref like `origin/main`. Those resolve fine but cannot be advanced by a close; the scripts exit `1` naming what the value actually resolved to.

**Rebase close, worktree mode, one extra refusal:** untracked content at `<repo-root>` is allowed, but if one of those untracked paths is a path the ephemeral branch adds as a *tracked* file, the fast-forward would be refused — and a rebase rewrites the ephemeral commits before it ever reaches the fast-forward. `projex-rebase-close` therefore checks for that collision up front and exits `1` naming the paths, with the ephemeral branch untouched. Move, delete, or commit those files and re-run.

**Anticipated conflicts (`--resolve-conflicts` / `-ResolveConflicts`):** By default any conflict aborts the close and rolls back. When you *expect* a conflict in specific files — typically `.projex/` documents both branches touched — declare them: `--resolve-conflicts '.projex/,docs/notes.md'` (comma-separated repo-relative files or directory prefixes; `-ResolveConflicts '.projex/','docs/notes.md'` in PowerShell). Then:

- **Every** conflicted path covered by the list → the operation is left **in progress** (nothing aborted) and the script exits **2**, listing the conflicts and the commands to resolve and continue.
- **Any** conflicted path outside the list → unchanged behaviour: abort, roll back, exit 1, listing only the uncovered paths. It is all-or-nothing — one uncovered conflict aborts the whole operation.

The list governs *which conflicts may halt instead of abort*; it does not restrict what gets integrated, and it cannot verify what you commit while resolving. Only declare paths you actually intend to resolve by hand.

Exit codes: `0` closed · `1` failed and rolled back · `2` left in progress for you to finish.

After resolving: **squash-close is not re-runnable** — a squash commit does not record the ephemeral branch as a parent, so re-running recomputes the same merge and conflicts again; follow the finishing commands the script prints. **merge-close and rebase-close are re-runnable** — once you have committed the merge or concluded the rebase, re-run the exact same command and it completes the cleanup. Re-running any of them *before* concluding the operation is refused with the work left untouched.

A rebase stops at the **first** conflicting commit, so a covered stop is not a promise the rest is clean — the same gate applies at every later stop, and the script reports how many commits remain.

#### Option A: Squash Merge (Default/Recommended)
Combines all execution commits into a single clean commit on base branch.

**Checkout mode:**
```bash
{projex-scripts}/projex-squash-close.{sh|ps1} <repo-root> {base-branch} projex/{yymmddhhmm}-{plan-name} "projex: {plan-name} - [summary of changes]"
```

**Worktree mode:**
```bash
{projex-scripts}/projex-squash-close.{sh|ps1} <repo-root> {base-branch} projex/{yymmddhhmm}-{plan-name} "projex: {plan-name} - [summary of changes]" --worktree
```

**Best for:** Clean history, routine executions

#### Option B: Merge with History
Preserves full commit history from execution.

**Checkout mode:**
```bash
{projex-scripts}/projex-merge-close.{sh|ps1} <repo-root> {base-branch} projex/{yymmddhhmm}-{plan-name} "projex: merge {plan-name}"
```

**Worktree mode:**
```bash
{projex-scripts}/projex-merge-close.{sh|ps1} <repo-root> {base-branch} projex/{yymmddhhmm}-{plan-name} "projex: merge {plan-name}" --worktree
```

**Best for:** Complex executions where step-by-step history is valuable

#### Option C: Rebase and Merge
Replays commits onto base branch for linear history (fast-forward, no merge commit).

**Checkout mode:**
```bash
{projex-scripts}/projex-rebase-close.{sh|ps1} <repo-root> {base-branch} projex/{yymmddhhmm}-{plan-name}
```

**Worktree mode:**
```bash
{projex-scripts}/projex-rebase-close.{sh|ps1} <repo-root> {base-branch} projex/{yymmddhhmm}-{plan-name} --worktree
```

**Best for:** Linear history preference, collaborative workflows

> **Note:** On a rebase conflict the script aborts cleanly and restores the original branch (checkout mode) or leaves the worktree intact (worktree mode), then exits non-zero — resolve manually, declare the paths via `--resolve-conflicts` (see above) to resolve them in place, or fall back to Option A/B. No merge-message argument is needed since `--ff-only` creates no merge commit.

> **If a script warns it could not remove the worktree:** the close itself succeeded. Run `git -C <repo-root> worktree list` — if the worktree path is no longer listed, only a plain untracked directory remains; inspect it for anything user-created, then delete it manually (`rm -rf` / `Remove-Item -Recurse -Force`) and run `git worktree prune`. If it is still listed, remove the blocking files it reported, then `git -C <repo-root> worktree remove <path>`.

#### Option D: Abandon (Failed Execution)
Discards the branch without merging.

**Checkout mode:**
```bash
{projex-scripts}/projex-abandon.{sh|ps1} <repo-root> {base-branch} projex/{yymmddhhmm}-{plan-name}
```

**Worktree mode:**
```bash
{projex-scripts}/projex-abandon.{sh|ps1} <repo-root> {base-branch} projex/{yymmddhhmm}-{plan-name} --worktree
```

**Use when:** Execution failed, changes are not wanted

---

### Branch Finalization Decision Tree

```
Was execution successful?
├── Yes → Do you need step-by-step history?
│   ├── Yes → Option B (Merge with History)
│   └── No → Option A (Squash Merge) ← default
└── No → Are partial changes valuable?
    ├── Yes → Cherry-pick valuable commits, then Option D
    └── No → Option D (Abandon)
```

---

### 8. RESTORE STASHED CHANGES

Stashing is **caller-owned**: the finalization scripts never create or pop a stash on your behalf — they refuse to close over tracked changes and leave the decision to you, so any stash must be recorded in the execution log or it will be forgotten here.

If changes were stashed at the start of execution (check the execution log for stash entries):

```bash
git stash list          # verify stash exists
git stash pop           # restore stashed changes
```

If no stash was made, skip this step.

---

## WALKTHROUGH PRINCIPLES

### Completeness
- Document everything that happened
- Don't skip steps even if they went smoothly
- Include all file changes with specifics

### Traceability
- Link every change to a plan step
- Document deviations with reasoning
- Provide verifiable evidence

### Learning Capture
- Extract insights while fresh
- Document both failures and successes
- Make knowledge reusable

### Honesty
- Record actual outcomes, not desired ones
- Acknowledge what didn't work
- Document partial successes accurately

---

## OUTPUT

This workflow produces:
- A walkthrough projex document at `.projex/closed/{yymmddhhmm}-{name}-walkthrough.md`
- Source plan moved to `.projex/closed/` with completion status and walkthrough link
- Every other aux document this plan resolved (Proposal, Memo, Red Team, Audit, Review, Eval, Interview, Coach, Exploration, Imagination, ...) moved to `.projex/closed/` alongside it
- Still-open related documents and Nav updated in place with a link to the walkthrough, not moved
- **Ephemeral branch merged/deleted** — changes now on base branch

**Folder structure after close:**
```
.projex/
├── [other pending projex...]
└── closed/
    ├── {yymmddhhmm}-{name}-proposal.md    (if applicable)
    ├── {yymmddhhmm}-{name}-redteam.md     (if applicable — any resolved aux doc)
    ├── {yymmddhhmm}-{name}-plan.md
    ├── {yymmddhhmm}-{name}-log.md
    └── {yymmddhhmm}-{name}-walkthrough.md
```

**Git state after close:**
```
{base-branch}  ← you are here, with all changes merged
  └── (ephemeral branch deleted)
```

---

## WALKTHROUGH QUALITY CHECKLIST

Before considering walkthrough complete:

- [ ] Every plan objective has outcome documented
- [ ] Every plan step has actual execution recorded
- [ ] All file changes listed with specifics
- [ ] All success criteria verified with evidence
- [ ] All deviations explained
- [ ] All issues documented with resolutions
- [ ] Key insights captured
- [ ] Source plan updated
- [ ] Related projex linked
- [ ] Nav updated if plan noted one
- [ ] Plan, execution log, and Walkthrough moved to `.projex/closed/`
- [ ] Every aux document this plan resolved (proposal, memo, redteam, audit, review, eval, ...) moved to `.projex/closed/` in the same commit
- [ ] Still-open related documents linked to the walkthrough, not moved
- [ ] **Ephemeral branch finalized** (merged or abandoned)
- [ ] **Stashed changes restored** (if any were stashed at execution start)
- [ ] **Back on base branch** with clean state

---

## NOTES

- Walkthroughs are historical records — don't edit them after completion
- Be thorough — you'll thank yourself when reviewing later
- Use relative paths when referencing repository files
- The value of projex compounds when walkthroughs are complete
- If execution was complex, write the walkthrough immediately while fresh
- **Squash merge is the default** — preserves clean history while capturing all changes
- Branch finalization is the final step — don't forget to delete the ephemeral branch
- The walkthrough commit should be the last commit before merge
