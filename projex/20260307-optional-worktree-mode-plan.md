# Optional Worktree Mode — Implementation Plan

> **Status:** Ready
> **Created:** 2026-03-07
> **Author:** Claude (agent)
> **Source:** 20260306-optional-worktree-mode-proposal.md
> **Related Projex:** 20260306-optional-worktree-mode-proposal.md

---

## Summary

Implement optional worktree mode for all ephemeral-branch workflows. Adds a new worktree creation script with gitignore enforcement, extends the three finalization scripts with `--worktree` support, and updates the workflow specs (execute, simulate, close) and SKILL.md to document both modes.

**Scope:** All changes within this repo — workflow specs (.md), framework spec (SKILL.md), and utility scripts (.sh/.ps1)
**Estimated Changes:** 10 files modified, 2 files created

---

## Objective

### Problem / Gap / Need

Ephemeral-branch workflows (`execute-projex`, `simulate-projex`, `close-projex`) only support checkout-based branch switching. This requires clean working state, disrupts the working directory, and blocks parallel execution. The proposal (`20260306-optional-worktree-mode-proposal.md`) was accepted — this plan implements it.

### Success Criteria

- [ ] New `projex-worktree` script creates worktrees in `.projexwt/` with gitignore enforcement gate
- [ ] All three finalization scripts (`projex-squash-close`, `projex-merge-close`, `projex-abandon`) accept `--worktree` flag and handle worktree removal
- [ ] `execute-projex.md` documents worktree mode as a conditional alongside checkout mode
- [ ] `simulate-projex.md` defaults to worktree mode with checkout as fallback
- [ ] `close-projex.md` documents worktree finalization
- [ ] `SKILL.md` has a "Worktree Mode" section under Git Integration
- [ ] Execution log template includes optional `Worktree Path:` field

### Out of Scope

- Changing the default mode (checkout remains default for execute; worktree becomes default only for simulate)
- `EnterWorktree` integration (proposal resolved: different mechanism, different purpose)
- Worktree support for non-ephemeral workflows (patch, log, etc. — they don't use branches)

---

## Context

### Current State

All ephemeral branch operations use `git checkout -b` / `git checkout` in the same working directory. The three finalization scripts (`projex-squash-close`, `projex-merge-close`, `projex-abandon`) follow a pattern: validate → require clean tree → `git checkout {base}` → merge/delete → `git branch -D`.

### Key Files

| File | Role | Change Summary |
|------|------|----------------|
| `projex-worktree.sh` | *New* — worktree creation | Create worktree with gitignore gate |
| `projex-worktree.ps1` | *New* — worktree creation (Windows) | Same logic, PowerShell |
| `projex-squash-close.sh` | Squash-merge finalization | Add `--worktree` flag, skip checkout, remove worktree |
| `projex-squash-close.ps1` | Same (Windows) | Same changes |
| `projex-merge-close.sh` | Full-history merge finalization | Add `--worktree` flag, skip checkout, remove worktree |
| `projex-merge-close.ps1` | Same (Windows) | Same changes |
| `projex-abandon.sh` | Abandon finalization | Add `--worktree` flag, skip checkout, remove worktree |
| `projex-abandon.ps1` | Same (Windows) | Same changes |
| `SKILL.md` | Framework spec | Add Worktree Mode section, document new script |
| `execute-projex.md` | Execution workflow | Add worktree conditional to branch creation and log template |
| `simulate-projex.md` | Simulation workflow | Default to worktree mode |
| `close-projex.md` | Close/walkthrough workflow | Add worktree finalization path |

### Dependencies

- **Requires:** git >= 2.5 (worktree support) — universally available
- **Blocks:** Nothing

### Constraints

- Both .sh and .ps1 variants must be updated in lockstep
- Scripts must remain backward-compatible — no `--worktree` flag means checkout mode (existing behavior unchanged)
- Workflow spec changes must clearly show both modes without making the document hard to follow

### Assumptions

- `.projexwt/` as worktree container directory (confirmed in proposal)
- Gitignore gate is a hard prerequisite — script auto-adds the entry if missing (confirmed in proposal)
- `git -C <worktree-path>` works for all git operations within worktrees (verified: worktrees are full working directories)
- `git worktree remove` can be called from the main repo root to remove a worktree by path

### Impact Analysis

- **Direct:** The 12 files listed above
- **Adjacent:** Agents following these workflows will encounter the new worktree option — but since checkout is default, existing behavior is preserved
- **Downstream:** Future workflows or scripts that create ephemeral branches should follow the same pattern

---

## Implementation

### Overview

Four steps: (1) create the new worktree script, (2) update the three finalization scripts, (3) update SKILL.md, (4) update the three workflow specs. Steps 1-2 are script changes; steps 3-4 are documentation. Steps are ordered so scripts exist before docs reference them.

### Step 1: Create `projex-worktree` Script

**Objective:** New script that creates a worktree in `.projexwt/` with gitignore enforcement.
**Confidence:** High
**Depends on:** None

**Files:**
- `projex-worktree.sh` (new)
- `projex-worktree.ps1` (new)

**Changes:**

Usage: `projex-worktree.{sh|ps1} <repo-root> <branch-name> [<base-ref>]`

Behavior:
1. Validate `<repo-root>` is a git repository
2. **Gitignore gate:** Run `git check-ignore -q .projexwt`. If not ignored:
   - If `.gitignore` exists, append `.projexwt/` to it
   - If `.gitignore` doesn't exist, create it with `.projexwt/`
   - Stage and commit: `git add .gitignore && git commit -m "projex: gitignore .projexwt/"`
3. Create directory `.projexwt/` if it doesn't exist
4. Check if worktree already exists at `.projexwt/<branch-name-suffix>` — error if so
5. Run `git worktree add .projexwt/<branch-name-suffix> -b <branch-name> [<base-ref>]`
   - `<branch-name-suffix>` is the last path segment of `<branch-name>` (e.g., `projex/20260307-foo` → `20260307-foo`)
6. Print the worktree path on success

```bash
# Example invocations:
projex-worktree.sh /path/to/repo projex/20260307-my-plan
# Creates .projexwt/20260307-my-plan/ with branch projex/20260307-my-plan from HEAD

projex-worktree.sh /path/to/repo projex/sim/20260307-my-sim main
# Creates .projexwt/20260307-my-sim/ with branch projex/sim/20260307-my-sim from main
```

**Rationale:** Centralizes worktree creation with the gitignore gate as a hard prerequisite. Agents and workflows call one script instead of reimplementing the gate logic each time.

**Verification:** Run the script on a test repo. Confirm `.projexwt/` is gitignored, worktree is created, branch exists, and the worktree path is printed.

**If this fails:** No downstream impact — finalization scripts and workflow specs don't depend on this script existing yet.

---

### Step 2: Update Finalization Scripts with `--worktree` Support

**Objective:** All three finalization scripts accept an optional `--worktree` flag. When present, they remove the worktree instead of checking out base branch.
**Confidence:** High
**Depends on:** Step 1 (conceptually, though scripts are independently functional)

**Files:**
- `projex-squash-close.sh`, `projex-squash-close.ps1`
- `projex-merge-close.sh`, `projex-merge-close.ps1`
- `projex-abandon.sh`, `projex-abandon.ps1`

**Changes — same pattern across all three:**

The `--worktree` flag is detected in argument parsing. When present:
- **Skip** the clean-working-tree check (the main working directory is on base branch, untouched)
- **Skip** `git checkout {base}` (already on base)
- **Add** `git worktree remove .projexwt/<suffix>` before the merge/delete step
- Derive the worktree path from `<repo-root>/.projexwt/` + the last segment of `<ephemeral-branch>`
- If `git worktree remove` fails, error with context and do not proceed to merge

**projex-squash-close.sh — before:**
```bash
# Require clean working tree
if ! git -C "$REPO_ROOT" diff --quiet ... ; then
  echo "Error: working tree has uncommitted changes..." >&2
  exit 1
fi

# Checkout base
if ! git -C "$REPO_ROOT" checkout "$BASE" 2>&1; then
  ...
fi

# Squash merge
if ! git -C "$REPO_ROOT" merge --squash "$EPHEMERAL" 2>&1; then
  ...
fi
```

**projex-squash-close.sh — after:**
```bash
if [ "$WORKTREE_MODE" = true ]; then
  # Remove worktree (must succeed before merge)
  WT_PATH="$REPO_ROOT/.projexwt/${EPHEMERAL##*/}"
  if ! git -C "$REPO_ROOT" worktree remove "$WT_PATH" 2>&1; then
    echo "Error: could not remove worktree '$WT_PATH'" >&2
    exit 1
  fi
else
  # Require clean working tree
  if ! git -C "$REPO_ROOT" diff --quiet ... ; then
    echo "Error: working tree has uncommitted changes..." >&2
    exit 1
  fi

  # Checkout base
  if ! git -C "$REPO_ROOT" checkout "$BASE" 2>&1; then
    ...
  fi
fi

# Squash merge (same for both modes)
if ! git -C "$REPO_ROOT" merge --squash "$EPHEMERAL" 2>&1; then
  ...
fi
```

**Worktree-mode rollback note:** In checkout mode, merge failure rolls back to the ephemeral branch (`git checkout "$EPHEMERAL"`). In worktree mode, the worktree is already removed at that point, so rollback simply does `git reset --hard HEAD` on base. The ephemeral branch still exists — the user can re-create the worktree manually (`git worktree add`) to recover. Scripts should print this guidance on failure.

**projex-merge-close** and **projex-abandon** follow the identical pattern — the only difference is the merge/delete operation after the conditional block, which stays unchanged.

**Argument parsing addition** (all three scripts, bash):
```bash
WORKTREE_MODE=false
# Check for --worktree flag in arguments and shift accordingly
for arg in "$@"; do
  if [ "$arg" = "--worktree" ]; then
    WORKTREE_MODE=true
  fi
done
```

PowerShell equivalents use a `[switch]$Worktree` parameter.

**Rationale:** Adding a flag to existing scripts avoids duplication while preserving full backward compatibility. The worktree path is derived from convention (`.projexwt/` + branch suffix), not passed as a separate argument — one less thing to get wrong.

**Verification:** Test each script in both modes: (a) without `--worktree` — confirm existing behavior unchanged, (b) with `--worktree` — confirm worktree removed, merge succeeds, branch deleted.

**If this fails:** Revert the script changes. Existing checkout-mode behavior is untouched by the conditional.

---

### Step 3: Update SKILL.md

**Objective:** Add Worktree Mode documentation to Git Integration section. Document the new `projex-worktree` script.
**Confidence:** High
**Depends on:** Steps 1-2 (scripts must exist before docs reference them)

**Files:**
- `SKILL.md`

**Changes:**

**A. Add to "Utility Scripts" section (after Branch Finalization, before Git Operation Discipline):**

```markdown
#### Worktree Creation

`projex-worktree` — creates a worktree in `.projexwt/` with gitignore enforcement as a hard gate.

\```
{projex-scripts}/projex-worktree.{sh|ps1} <repo-root> <branch-name> [<base-ref>]
\```

Before creating the worktree, the script verifies `.projexwt/` is in `.gitignore`. If not, it adds the entry and commits it. The worktree is created at `.projexwt/<branch-suffix>/` where `<branch-suffix>` is the last path segment of `<branch-name>`.
```

**B. Add `--worktree` flag documentation to Branch Finalization entries:**

```markdown
- `projex-squash-close` — ... Usage: `{projex-scripts}/projex-squash-close.{sh|ps1} <repo-root> <base> <ephemeral> "msg" [--worktree]`
- `projex-merge-close` — ... Usage: `{projex-scripts}/projex-merge-close.{sh|ps1} <repo-root> <base> <ephemeral> "msg" [--worktree]`
- `projex-abandon` — ... Usage: `{projex-scripts}/projex-abandon.{sh|ps1} <repo-root> <base> <ephemeral> [--worktree]`

When `--worktree` is passed, the script removes the worktree at `.projexwt/<branch-suffix>` instead of checking out base. The main working directory must already be on the base branch (which it is — worktree mode never leaves it).
```

**C. Add new subsection after "Notes" (line 181), before the `---` separator:**

```markdown
### Worktree Mode (Optional)

Worktree mode creates ephemeral branches as separate working directories in `.projexwt/` instead of switching the main working directory via `git checkout`. The main directory stays on the base branch throughout.

**Opt-in:** Add `> **Worktree:** Yes` to the plan header. Simulations default to worktree mode.

**How it works:**
- `projex-worktree` creates the worktree with gitignore enforcement
- All execution happens in the worktree directory (`.projexwt/<name>/`)
- `projex-commit` works unchanged (`-C` accepts worktree paths)
- Finalization scripts receive `--worktree` flag to remove the worktree instead of checking out base
- No stashing needed — the base branch working directory is never touched

**Benefits over checkout mode:**
- No clean-state requirement at execution start
- No working directory disruption (editors/IDEs unaffected)
- Parallel executions possible (multiple worktrees)
- Crash-safe — main directory always on base branch

**`.projexwt/` is always gitignored.** The worktree creation script enforces this as a hard gate.
```

**Rationale:** SKILL.md is the authoritative reference for all framework behavior. The worktree mode documentation belongs here, with workflow specs referencing it.

**Verification:** Read the updated SKILL.md. Confirm all script usages match actual script interfaces. Confirm the worktree section is self-contained and doesn't contradict existing sections.

**If this fails:** Revert SKILL.md edits. Scripts remain functional regardless of documentation.

---

### Step 4: Update Workflow Specs

**Objective:** Add worktree mode conditionals to execute-projex, simulate-projex, and close-projex.
**Confidence:** High
**Depends on:** Step 3 (SKILL.md should document the mode before workflow specs reference it)

**Files:**
- `execute-projex.md`
- `simulate-projex.md`
- `close-projex.md`

**Changes:**

#### A. execute-projex.md

**Section "1. INITIALIZE EXECUTION" — step 2 "Create ephemeral branch and verify" (lines 93-98):**

Before:
```markdown
2. **Create ephemeral branch and verify**

\```bash
git checkout -b projex/{yyyymmdd}-{plan-name}
git branch --show-current
\```
```

After:
```markdown
2. **Create ephemeral branch and verify**

**Checkout mode (default):**
\```bash
git checkout -b projex/{yyyymmdd}-{plan-name}
git branch --show-current
\```

**Worktree mode** (when plan header has `> **Worktree:** Yes`):
\```bash
{projex-scripts}/projex-worktree.{sh|ps1} <repo-root> projex/{yyyymmdd}-{plan-name}
\```
All subsequent commands use `.projexwt/{yyyymmdd}-{plan-name}` as the working directory. The main directory stays on the base branch.
```

**Execution Log Template — add `Worktree Path:` field (line ~255):**

Before:
```markdown
# Execution Log: [Plan Name]
Started: [yyyymmdd hh:mm]
Base Branch: [branch name recorded at step 1.1]
```

After:
```markdown
# Execution Log: [Plan Name]
Started: [yyyymmdd hh:mm]
Base Branch: [branch name recorded at step 1.1]
Worktree Path: [.projexwt/{name} — omit if checkout mode]
```

#### B. simulate-projex.md

**Section "2. CREATE EPHEMERAL BRANCH" (lines 83-94):**

Before:
```markdown
### 2. CREATE EPHEMERAL BRANCH

Before creating the simulation branch, note your current branch:
\```bash
git branch --show-current  # Remember as {base-branch}
\```

Then create the simulation branch:
\```bash
git checkout -b projex/sim/{yyyymmdd}-{simulation-name}
\```

Verify you are on the new branch before proceeding.
```

After:
```markdown
### 2. CREATE EPHEMERAL BRANCH

Note your current branch:
\```bash
git branch --show-current  # Remember as {base-branch}
\```

**Worktree mode (default for simulations):**
\```bash
{projex-scripts}/projex-worktree.{sh|ps1} <repo-root> projex/sim/{yyyymmdd}-{simulation-name}
\```
All subsequent commands use `.projexwt/{yyyymmdd}-{simulation-name}` as the working directory. The main directory stays on the base branch.

**Checkout mode (fallback — when worktree is unavailable):**
\```bash
git checkout -b projex/sim/{yyyymmdd}-{simulation-name}
\```
Verify you are on the new branch before proceeding.
```

**Section "4. GATHER FINAL OBSERVATIONS AND ROLLBACK" — rollback command (lines 139-141):**

Before:
```markdown
\```bash
{projex-scripts}/projex-abandon.{sh|ps1} <repo-root> {base-branch} projex/sim/{yyyymmdd}-{simulation-name}
\```
```

After:
```markdown
**Worktree mode:**
\```bash
{projex-scripts}/projex-abandon.{sh|ps1} <repo-root> {base-branch} projex/sim/{yyyymmdd}-{simulation-name} --worktree
\```

**Checkout mode:**
\```bash
{projex-scripts}/projex-abandon.{sh|ps1} <repo-root> {base-branch} projex/sim/{yyyymmdd}-{simulation-name}
\```
```

#### C. close-projex.md

**Section "7. FINALIZE GIT BRANCH" — Options A, B, D (lines 386-457):**

Add a note before the options:

```markdown
> **Worktree mode:** If execution used worktree mode, pass `--worktree` to the finalization script. This removes the worktree at `.projexwt/` instead of checking out base (the main directory is already on base). All other behavior is identical.
```

Update each option's script invocation to show the `--worktree` variant:

```markdown
#### Option A: Squash Merge (Default/Recommended)
\```bash
# Checkout mode:
{projex-scripts}/projex-squash-close.{sh|ps1} <repo-root> {base-branch} projex/{yyyymmdd}-{plan-name} "projex: {plan-name} - [summary]"

# Worktree mode:
{projex-scripts}/projex-squash-close.{sh|ps1} <repo-root> {base-branch} projex/{yyyymmdd}-{plan-name} "projex: {plan-name} - [summary]" --worktree
\```
```

Same pattern for Options B and D.

**Rationale:** Workflow specs must show both modes clearly. Checkout mode stays first (it's the default for execute). Simulate flips the order (worktree is default there).

**Verification:** Read each updated workflow spec end-to-end. Verify the mode conditionals are consistent. Confirm script invocations match the interfaces from Steps 1-2.

**If this fails:** Revert workflow spec edits. Scripts and SKILL.md remain valid independently.

---

## Verification Plan

### Automated Checks

- [ ] All scripts pass `bash -n` (syntax check) / PowerShell `Test-ScriptAnalyzer`
- [ ] `projex-worktree.sh` creates worktree, enforces gitignore, prints path
- [ ] `projex-squash-close.sh --worktree` removes worktree and squash-merges
- [ ] `projex-abandon.sh --worktree` removes worktree and deletes branch
- [ ] All three scripts without `--worktree` behave identically to current versions

### Manual Verification

- [ ] Read SKILL.md Worktree Mode section — self-contained and accurate
- [ ] Read execute-projex.md — worktree conditional clear, execution log template has Worktree Path
- [ ] Read simulate-projex.md — worktree mode shown as default
- [ ] Read close-projex.md — all finalization options show both modes

### Acceptance Criteria Validation

| Criterion | How to Verify | Expected Result |
|-----------|---------------|-----------------|
| Gitignore gate works | Run `projex-worktree.sh` on repo without `.projexwt/` in `.gitignore` | Script adds the entry and commits before creating worktree |
| Backward compatibility | Run finalization scripts without `--worktree` | Identical behavior to current versions |
| Worktree removal on close | Run `projex-squash-close.sh --worktree` after execution in worktree | Worktree removed, squash-merge succeeds, branch deleted |
| Execution log records path | Follow execute-projex with `Worktree: Yes` | Log includes `Worktree Path:` field |

---

## Rollback Plan

Per-step rollback is noted in each step above. If the overall implementation must be abandoned:

1. Revert all modified files: `git checkout HEAD -- SKILL.md execute-projex.md simulate-projex.md close-projex.md projex-squash-close.sh projex-squash-close.ps1 projex-merge-close.sh projex-merge-close.ps1 projex-abandon.sh projex-abandon.ps1`
2. Delete new files: `git rm projex-worktree.sh projex-worktree.ps1`
3. Commit the revert

---

## Notes

### Risks

- PowerShell and Bash scripts must stay in sync — test both platforms during execution
- Workflow spec readability: adding conditionals to every branch-related section adds visual weight — keep the worktree blocks concise

### Open Questions

- (None — all questions resolved in proposal)
