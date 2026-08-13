# Execution Log: Named-parameter `new-projex` API migration

> **Status:** Complete (Scoped Success; Aggregate Baseline Failures)
> **Started:** 20260813 05:20
> **Repo Root:** /workspace
> **Plan File:** .projex/2608130511-named-new-projex-parameter-migration-plan.md
> **Base Branch:** main
> **Worktree Path:** /workspace/.projexwt/2608130511-named-new-projex-parameter-migration-plan

## Pre-Check Results
REPO_ROOT=/workspace
BRANCH=main
PLAN_REL=.projex/2608130511-named-new-projex-parameter-migration-plan.md

PASS  Plan is committed (5246e43 projex(revise): strengthen named parser verification)
WARN  Working tree has 25 uncommitted change(s)

Executing in Worktree mode? Remember to bootstrap the branch/worktree (missing dev deps, etc.)

PRE-CHECK PASSED

## Steps

### 20260813 05:20 - Initialization
**Action:** Ran mandatory execute precheck; updated plan status to `In Progress` and committed it on `main` as `2272444`; created isolated worktree branch `projex/2608130511-named-new-projex-parameter-migration-plan`; checked project files for bootstrap needs.
**Result:** Precheck passed. Base retained its pre-existing dirty/untracked files. Worktree contains tracked shell, PowerShell, workflow, test, and inventory files; no package manifest or dependency bootstrap command is present.
**Status:** Success

### 20260813 05:25 - Step 1: Implement strict named parsers
**Action:** Replaced positional parsing in `new-projex.sh` with a left-to-right named-option parser tracking presence and duplicate flags; replaced PowerShell positional binding with raw-token, case-insensitive named parsing and duplicate/missing-value checks. Kept post-parse normalization and creation logic unchanged.
**Result:** `bash -n new-projex.sh` passed. PowerShell AST parse reported `AST_ERRORS=0`. Parser usage text now advertises the exact platform-native signatures; parser failures exit 2 before filesystem operations.
**Status:** Success
### 20260813 06:10 - Step 2: Cut over every scaffold directive
**Action:** Replaced all 20 scaffold workflow directives with explicit platform-native named commands, preserving each workflow's adjacent Parent-resolution precedence and archive/conclude born-closed notes. Manual writers remain unchanged.
**Result:** Controlled workflow inventory now contains 20 scaffold creators with one fully named Shell and one fully named PowerShell invocation each; the four manual writers contain no scaffold call.
**Status:** Success
### 20260813 06:20 - Step 3: Replace focused contract coverage
**Action:** Replaced positional test calls with named syntax; retained shared Parent fixture semantics; added explicit default-directory coverage, parser-negative IDs for missing/duplicate/unknown/stray/legacy tokens, exact exit/usage/stdout/no-write assertions, full filesystem snapshots, mixed-case PowerShell success including `-ProjexDir`, and closed caller inventory checks.
**Result:** `bash tests/new-projex.test.sh` passed `PASS=178 FAIL=0`; PowerShell AST parses reported `AST_ERRORS=0` and `TEST_AST_ERRORS=0`; `pwsh -NoProfile -File tests/new-projex.test.ps1` passed `PASS=181 FAIL=0`. Both focused suites now emit the aggregate-runner-compatible `PASS=N FAIL=M` summary.
**Status:** Success
### 20260813 06:45 - Step 4: Align utility and test inventories; complete atomic verification
**Action:** Updated `README.md`, `AGENTS.md`, and `tests/README.md` with the strict named API and observed focused counts; aligned focused-suite summaries with the existing aggregate-runner contract; ran both aggregate runners after temporarily enabling the repository's non-executable shell utility files for the smoke run, then restored their tracked modes.
**Result:** Final focused rerun passed `bash tests/new-projex.test.sh` with `PASS=178 FAIL=0`; PowerShell AST parses reported `AST_ERRORS=0` and `TEST_AST_ERRORS=0`; `pwsh -NoProfile -File tests/new-projex.test.ps1` passed `PASS=181 FAIL=0`. Shell aggregate suites passed all executed assertions (`PASS=495 FAIL=0`) but the runner returned failure because pre-existing `projex-tree.test.sh` emits `PASS=46 FAIL=0 CASES=46`, which does not match its runner's strict summary regex. PowerShell aggregate runner also returned failure in pre-existing `projex-tree`/lifecycle suites; the new-projex PowerShell suite itself passed `PASS=181 FAIL=0`.
**Status:** Partial
### 20260813 07:20 - Close readiness
**Action:** Independent audit found the focused PowerShell suite's inherited successful-process exit state; patched `tests/new-projex.test.ps1` to exit `0` after cleanup when assertions pass. Re-ran focused Shell and PowerShell suites. Stashed originating checkout tracked user changes as `projex-close-2608130511-preserve-base-user-changes` without untracked artifacts.
**Result:** Shell focused suite: `PASS=178 FAIL=0`; PowerShell focused suite: `PASS=181 FAIL=0`, exit `0`. Aggregate runners remain blocked only by unrelated baseline utility modes, summary-shape, and lifecycle-suite failures. User authorized scoped closure.
**Status:** Success




## Deviations
Aggregate verification remains partial because unrelated pre-existing suites violate the runner summary regex and PowerShell lifecycle suites fail independently; no out-of-scope files were changed to mask those failures.

## Issues Encountered
The repository tracks shell utilities and several shell suites as mode `100644`; aggregate execution therefore required a temporary executable-bit smoke setup, which was restored before finalization. The new API-focused shell suite invokes `new-projex.sh` through `bash` and does not retain a mode change.

## Data Gathered

None.

## User Interventions

None.
