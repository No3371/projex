# Optional Worktree Mode Across the Board

> **Status:** Draft
> **Created:** 2026-03-06
> **Author:** Claude (agent)
> **Related Projex:** 20260217-framework-self-eval.md

---

## Summary

Add an optional **worktree mode** to all projex workflows that create ephemeral branches (`execute-projex`, `simulate-projex`, `close-projex`). Instead of `git checkout -b` in the current working directory, worktree mode uses `git worktree add` to create a separate directory for the ephemeral branch — leaving the base branch undisturbed. This eliminates mandatory stashing, allows parallel executions, and prevents editor/IDE disruption.

---

## Problem Statement

### Current State

All ephemeral branch workflows operate via checkout-based switching in a single working directory:

1. `execute-projex` creates `projex/{yyyymmdd}-{plan-name}` via `git checkout -b`
2. `simulate-projex` creates `projex/sim/{yyyymmdd}-{name}` via `git checkout -b`
3. `close-projex` finalizes via `git checkout {base}` + merge/squash/abandon + branch delete
4. All utility scripts (`projex-squash-close`, `projex-merge-close`, `projex-abandon`) use `git checkout` internally

### Gap / Need / Opportunity

**Checkout-based switching has friction costs:**

1. **Clean-state requirement** — Execution cannot start with uncommitted changes. The agent must stash, the execution log must track the stash, and `close-projex` must restore it. Stash discipline is fragile — easy to forget, easy to lose.

2. **Working directory disruption** — Every file in the repo changes on branch switch. Editors and IDEs see the rug pulled out — open buffers invalidated, file watchers fire, build caches may be invalidated.

3. **No parallel execution** — Only one branch can be checked out at a time. Two plans cannot execute concurrently in the same repo, and a simulation cannot run alongside an in-progress execution.

4. **Path identity confusion** — The repo root directory serves double duty: it's both where the base branch lives and where the ephemeral branch works. Agents and scripts must carefully track which branch is active. A crash or interrupted session may leave the repo on the wrong branch.

5. **Agent tooling mismatch** — Claude Code already has an `EnterWorktree` tool (available in the deferred tools list), but the projex framework doesn't leverage it. The tooling supports worktrees; the workflow specs don't.

### Why Now?

- The framework is pre-1.0 and actively evolving — changing branch mechanics now is cheap
- The `EnterWorktree` agent tool exists but has no framework integration
- Worktree support in git is mature and well-understood (available since git 2.5, 2015)
- No existing consumers would break — the framework hasn't committed to checkout-only semantics in any contract

---

## Proposed Change

### Overview

Introduce **worktree mode** as an opt-in alternative to the current checkout mode for ephemeral branch operations. Both modes coexist — checkout mode remains the default. Worktree mode is selected per-execution (not globally), so repos and users can choose per situation.

### Approach Options

#### Option A: Workflow-Level Flag

Add a `Worktree: Yes` header to plan/execution documents. The workflow specs detect this and use worktree commands instead of checkout commands.

**Execution would look like:**
```bash
# Instead of: git checkout -b projex/{yyyymmdd}-{plan-name}
git worktree add .projexwt/{yyyymmdd}-{plan-name} -b projex/{yyyymmdd}-{plan-name}
```

The agent then operates in the worktree directory. On close:
```bash
# Instead of: git checkout {base} + merge
cd {repo-root}
git merge --squash projex/{yyyymmdd}-{plan-name}
git worktree remove .projexwt/{yyyymmdd}-{plan-name}
git branch -D projex/{yyyymmdd}-{plan-name}
```

- **Pros:** Explicit per-execution, no global config, each plan decides for itself
- **Cons:** Adds a header field to learn; workflows must branch on two code paths
- **Effort:** Moderate — workflow spec changes + script variants

#### Option B: Worktree-Aware Scripts with Auto-Detection

Update the utility scripts to accept a `--worktree` flag. The scripts handle worktree creation/teardown internally. Workflow specs stay almost unchanged — they just pass the flag through.

```bash
# Script creates worktree and reports the path
projex-checkout.sh <repo-root> <branch-name> [--worktree <wt-dir>]
# Returns the working directory path (repo-root or worktree path)

# Close scripts detect whether branch has an associated worktree
projex-squash-close.sh <repo-root> <base> <ephemeral> "msg"  # auto-detects worktree
```

- **Pros:** Minimal workflow spec changes, complexity lives in scripts, auto-detection reduces cognitive load
- **Cons:** Implicit behavior harder to reason about, auto-detection can misfire
- **Effort:** Moderate — new script + modifications to existing scripts

#### Option C: Separate Worktree Script Suite

Create parallel scripts: `projex-wt-checkout.sh`, `projex-wt-squash-close.sh`, etc. Workflow specs document both paths side-by-side.

- **Pros:** Clean separation, no conditionals in existing scripts, easy to test independently
- **Cons:** Script duplication, two sets to maintain, divergence risk over time
- **Effort:** High — full parallel implementation

### Recommended Approach

**Option A (Workflow-Level Flag)** combined with elements of Option B (smart scripts).

Rationale:
- The `Worktree: Yes` header makes the mode explicit and inspectable — no hidden state
- Scripts gain a `--worktree <path>` parameter but don't auto-detect — the workflow tells them what to do
- Workflow specs document both paths clearly, with the worktree path shown as a conditional block
- This avoids script duplication while keeping behavior transparent

---

## Impact Analysis

### Affected Areas

| Area | Impact |
|------|--------|
| `execute-projex.md` | Branch creation step gains worktree alternative. `REPO_ROOT` in commit commands points to worktree path. Execution log records worktree path. |
| `simulate-projex.md` | Same as execute — worktree creation/teardown for sim branches. |
| `close-projex.md` | Branch finalization gains worktree removal step. Merge operations run from main repo root, not worktree. |
| `SKILL.md` | New section: "Worktree Mode" documenting opt-in, worktree directory conventions, path semantics. |
| `projex-commit.sh/.ps1` | `REPO_ROOT` parameter may be a worktree path — already works since worktrees are full working directories. No change needed. |
| `projex-squash-close.sh/.ps1` | Gains `--worktree <path>` flag. Before checkout, removes worktree. |
| `projex-merge-close.sh/.ps1` | Same as squash-close. |
| `projex-abandon.sh/.ps1` | Same pattern — remove worktree before deleting branch. |
| `projex-commit.sh/.ps1` | No changes — `git -C` works with worktree paths already. |
| `stage-by-pattern.sh/.ps1` | No changes — operates on whatever working tree it's pointed at. |
| `move-n-stage.sh/.ps1` | No changes — same reasoning. |

### Dependencies

- **Requires:** git >= 2.5 (worktree support). Practically all modern git installations qualify.
- **Blocks:** Nothing — this is additive.

### Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Worktree directory naming collisions | Low | Medium | Convention-based path (`.projexwt/{name}`) + existence check before creation |
| Orphaned worktrees on crash/interrupt | Medium | Low | `git worktree prune` in pre-execution checklist; worktrees are cheap to clean up |
| Path confusion (agent operates in wrong directory) | Medium | Medium | Execution log records worktree path explicitly; scripts validate working directory |
| Editor confusion with two directories | Low | Low | This is actually an improvement — editor stays on base branch in the original directory |
| Windows path length limits | Low | Medium | Use short worktree directory names; document Windows-specific guidance |

### Breaking Changes

None. Checkout mode remains the default. All existing workflows, scripts, and documents continue to work unchanged.

---

## Design Details

### Worktree Directory Convention

```
{repo}/
  .projexwt/                 # Worktree container (gitignored)
    {yyyymmdd}-{plan-name}/  # One worktree per execution
  projex/                    # Projex documents (as usual)
```

`.projexwt/` lives inside the repo as a sibling to `projex/`. The dot-prefix signals "tooling artifact, not project content."

**`.gitignore` enforcement:** The worktree creation script must verify `.projexwt/` is gitignored *before* creating any worktree. If the entry is missing, the script adds it (or errors). This is a hard gate — not a recommendation. Specifically:

1. Check: `git check-ignore -q .projexwt` — if exit 0, proceed
2. If not ignored: append `.projexwt/` to the repo's root `.gitignore`, stage and commit it as a prerequisite (`projex: gitignore .projexwt/`)
3. Never create a worktree under `.projexwt/` without passing this gate

This prevents worktree contents from ever appearing in `git status`, staging, or commits — even if the user runs `git add .` (which projex forbids, but defense in depth).

### Execution Flow (Worktree Mode)

```
[base branch in repo-root]
    |
    |-- gate: git check-ignore -q .projexwt (enforce gitignore)
    |-- git worktree add .projexwt/{name} -b projex/{name}
    |
    |   [worktree: .projexwt/{name}]
    |   All execution happens here
    |   projex-commit operates here (-C .projexwt/{name})
    |   Base branch working directory untouched throughout
    |
    |-- close-projex:
    |   (already on base branch — no checkout needed)
    |   git worktree remove .projexwt/{name}
    |   git merge --squash projex/{name}
    |   git commit -m "..."
    |   git branch -D projex/{name}
    |
[base branch, clean, worktree gone]
```

### What Changes Per Workflow

**execute-projex — Step 1.2 gains a conditional:**

> If worktree mode:
> ```bash
> git worktree add .projexwt/{yyyymmdd}-{plan-name} -b projex/{yyyymmdd}-{plan-name}
> # All subsequent commands use .projexwt/{yyyymmdd}-{plan-name} as working directory
> ```
> Record the worktree path in the execution log: `Worktree: .projexwt/{yyyymmdd}-{plan-name}`

**simulate-projex — Step 2 gains the same conditional** for `projex/sim/` branches.

**close-projex — Step 7 (branch finalization) gains worktree cleanup:**

> If worktree mode, before merge:
> ```bash
> git worktree remove .projexwt/{yyyymmdd}-{plan-name}
> ```
> Then proceed with merge as normal (already on base branch — no checkout needed).

**SKILL.md — New subsection under Git Integration:**

> ### Worktree Mode (Optional)
> Opt in by adding `> **Worktree:** Yes` to the plan header. When active:
> - `.projexwt/` must be in `.gitignore` — scripts enforce this as a hard gate before creating any worktree
> - Ephemeral branches are created as worktrees in `.projexwt/`
> - The main working directory stays on the base branch throughout execution
> - `REPO_ROOT` in script calls points to the worktree path during execution
> - Finalization removes the worktree before deleting the branch
> - No stashing is needed — the base branch working directory is never touched

---

## Open Questions

- [x] ~~Should `EnterWorktree` (the Claude Code tool) be the canonical way to create worktrees?~~ No. `EnterWorktree` is session-scoped isolation (switches the entire session's cwd into `.claude/worktrees/`, prompts on exit). Projex needs script-level worktree management — create, operate via `-C`, tear down — without redirecting the session. Different mechanism, different purpose. Projex scripts handle their own worktrees in `.projexwt/`.
- [x] ~~Where exactly should the worktree container live?~~ Decided: `.projexwt/` inside the repo, sibling to `projex/`. Gitignore entry enforced by scripts as a hard gate before worktree creation.
- [ ] Should worktree mode be the eventual default, with checkout mode as the legacy fallback? Or permanent equals? — **Decision: permanent equals.** Both modes remain first-class options indefinitely.
- [x] ~~How should the execution log's `Base Branch` field interact with the worktree path?~~ Add a separate `Worktree Path:` field to the execution log header when worktree mode is active. `Base Branch:` stays as-is.
- [x] ~~Should simulations always use worktree mode when available?~~ Yes. Simulation branches are always discarded — worktree mode is strictly better (no stash, no checkout disruption, guaranteed clean teardown). Simulations should default to worktree mode when git worktree support is available, without requiring explicit opt-in.

---

## Next Steps

If accepted:
1. Plan the SKILL.md and workflow spec changes (document-only, no code)
2. Plan the script modifications (`--worktree` flag for finalization scripts)
3. Implement and test with a trial execution in worktree mode
4. Document Windows-specific path guidance

---

## Appendix

### Research / References

- `git worktree` documentation: https://git-scm.com/docs/git-worktree
- Claude Code `EnterWorktree` tool — exists in the deferred tools list, purpose and interface TBD
- Current branch scripts: `projex-squash-close.sh`, `projex-merge-close.sh`, `projex-abandon.sh` — all use `git checkout` + `git branch -D` pattern

### Alternatives Considered

**1. Always-worktree (no opt-in):**
Rejected because worktrees add a directory management dimension that not all environments handle well (e.g., some CI systems, restricted filesystems, nested repos). Opt-in preserves the simpler checkout path for environments where it works fine.

**2. Stash improvements instead:**
Rejected because stashing addresses only one of the five problems (clean-state requirement). It doesn't help with parallel execution, editor disruption, or path identity confusion.

**3. Temporary clone instead of worktree:**
Rejected because `git clone --local` creates a separate `.git` directory and doesn't share refs efficiently. Worktrees are purpose-built for this use case — they share the same `.git` and all objects.
