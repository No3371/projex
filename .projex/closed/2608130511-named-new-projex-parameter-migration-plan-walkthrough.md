# Walkthrough: Named-parameter `new-projex` API migration

> **Status:** Complete (Scoped Success; Aggregate Baseline Failures)
> **Execution Date:** 2026-08-13
> **Completed By:** OpenAI Codex agents
> **Source Plan:** 2608130511-named-new-projex-parameter-migration-plan.md
> **Log:** 2608130511-named-new-projex-parameter-migration-plan-log.md
> **Parent:** 2608130511-named-new-projex-parameter-migration-plan.md
> **Result:** Scoped Success

## Summary

Replaced positional `new-projex` creation interfaces with strict platform-native named parameters and cut all 20 scaffold workflows over without changing Parent resolution. Paired focused contracts prove parser rejection/no-write behavior, caller inventory, Parent headers, default directory behavior, and PowerShell case-insensitivity; docs state the observed coverage. An audit found the PowerShell suite leaked an expected command's exit code into the aggregate runner; a one-file patch makes its successful path exit `0` after cleanup.

The migration-specific contract passes. Aggregate runners still exit nonzero only for unrelated baseline utility-mode, summary-shape, and lifecycle-suite failures; user explicitly authorized closure with that exception recorded.

## Objectives Completion

| Objective | Status | Evidence |
|---|---|---|
| Strict named parsers | Complete | `new-projex.sh:3-70`; `new-projex.ps1:2-58`; focused suites. |
| 20 workflow cutover | Complete | Closed 20/4 creator inventory; named-command guards in paired suites. |
| Paired strict-contract coverage | Complete | Shell `PASS=178 FAIL=0`; PowerShell `PASS=181 FAIL=0`. |
| Docs, suite integration | Complete (baseline exception) | `README.md`, `AGENTS.md`, `tests/README.md`; PowerShell suite now returns `0` to its runner. |

## Execution Detail

### Step 1: Strict named parsers

**Planned:** Replace positional interfaces with exact named APIs; reject malformed token streams before filesystem activity.

**Actual:** `new-projex.sh:11-70` advertises and parses `--repo-root`, `--type`, `--title`, `--parent`, and optional `--projex-dir`; it tracks each option, rejects unknown/duplicate/bare/missing-value tokens, then checks required presence before normalization. `new-projex.ps1:14-58` raw-parses `$args`, normalizes option identity with `ToLowerInvariant()`, preserves advertised PascalCase names, and enforces equivalent cardinality before `Test-Path`/creation logic.

**Deviation:** None. Existing semantic validation, type mapping, Parent grammar, collision scan, headers, and output behavior remain after parser handoff.

**Verification:** `bash -n new-projex.sh`; PowerShell AST checks recorded `AST_ERRORS=0`; focused suites passed.

### Step 2: Workflow directive cutover

**Planned:** Replace each positional scaffold directive with Shell and PowerShell native named commands while preserving local Parent precedence.

**Actual:** Updated `archive-projex.md`, `audit-projex.md`, `coach-projex.md`, `conclude-projex.md`, `define-projex.md`, `eval-projex.md`, `explore-projex.md`, `guide-projex.md`, `imagine-projex.md`, `interview-projex.md`, `memo-projex.md`, `navigate-projex.md`, `patch-projex.md`, `plan-projex.md`, `preplan-projex.md`, `propose-projex.md`, `redteam-projex.md`, `review-projex.md`, `scan-projex.md`, and `stress-projex.md`. Each now contains one fully named Shell command and one fully named PowerShell command; adjacent Parent-selection prose and four manual writers remain unchanged.

**Deviation:** None.

**Verification:** Paired tests compare the exact 20 scaffold/4 manual inventory and reject any scaffold line missing a required named flag (`tests/new-projex.test.sh:114-138`; `tests/new-projex.test.ps1:110-132`).

### Step 3: Shared contract coverage

**Planned:** Prove successful Parent semantics, strict parser failures/no writes, optional-directory default, PowerShell case handling, and no positional callers.

**Actual:** Both suites use named positive calls, full filesystem snapshots, separate stderr/stdout capture, 17 parser-negative IDs covering missing/duplicate/missing-value/unknown/stray/legacy inputs, and the existing Parent fixture/inventory. Shell assertions are at `tests/new-projex.test.sh:20-92`; PowerShell assertions are at `tests/new-projex.test.ps1:20-94`. PowerShell also proves mixed-case success and case-folded duplicate rejection.

**Deviation:** `tests/fixtures/new-projex-cases.tsv` and `tests/fixtures/projex-creators.txt` were planned as potential edits but stayed unchanged: their shared Parent rows and 20/4 inventory already supported the stronger test code.

**Verification:** `bash tests/new-projex.test.sh` → `PASS=178 FAIL=0`; `pwsh -NoProfile -File tests/new-projex.test.ps1` → `PASS=181 FAIL=0`.

### Step 4: Inventories, aggregate repair, and verification

**Planned:** Align public/test inventories and run focused plus aggregate runners before atomic commit.

**Actual:** Updated `README.md`, `AGENTS.md`, and `tests/README.md` for the named API and observed `178`/`181` focused counts. Audit finding `2608130624-named-new-projex-parameter-migration-implementation-audit.md` identified that the successful PowerShell suite inherited a final expected collision's exit `2` when invoked in-process; `tests/new-projex.test.ps1:135-139` now cleans up, exits `1` only for assertion failures, and explicitly exits `0` otherwise. Closed patch record: `2608130629-new-projex-powershell-suite-exit-status-patch.md`.

**Deviation:** Aggregate runners remain nonzero outside migration scope. Shell runner is blocked by pre-existing utility execute modes and `projex-tree.test.sh` summary shape; PowerShell runner is blocked by pre-existing tree/close-precheck/lifecycle summary failures. The repaired new-projex PowerShell suite is accepted by the aggregate runner.

**Verification:** Current focused rerun: Shell `PASS=178 FAIL=0`; PowerShell `PASS=181 FAIL=0` with process exit `0`. Recorded aggregate runs preserve their unrelated baseline failures rather than masking them.

## Complete Change Log

**Derived from:** `git diff --stat main..HEAD` before close: 30 files, 481 insertions, 106 deletions. No files deleted.

### Created

| File | Purpose |
|---|---|
| `.projex/2608130511-named-new-projex-parameter-migration-plan-log.md` | Execution evidence, baseline attribution, close readiness. |
| `.projex/closed/2608130629-new-projex-powershell-suite-exit-status-patch.md` | Closed record for focused-suite exit repair. |

### Modified

| Files | Actual change |
|---|---|
| `new-projex.sh:3-79` | Strict named Shell parser and usage contract before normalization/write checks. |
| `new-projex.ps1:2-67` | Strict case-insensitive named PowerShell parser and usage contract before creation checks. |
| 20 workflow specs listed in Step 2 | One Shell and one PowerShell named creator command; Parent precedence retained. |
| `tests/new-projex.test.sh:20-140` | Full-state parser-negative checks, named calls, default directory, closed creator proof. |
| `tests/new-projex.test.ps1:20-139` | Equivalent PowerShell checks, mixed-case proof, explicit successful-process exit. |
| `README.md`; `AGENTS.md`; `tests/README.md` | Named API and focused-contract coverage/count descriptions. |
| `.projex/2608130511-named-new-projex-parameter-migration-plan.md` | Execution status transitioned to complete at close. |

### Planned But Unchanged

| File | Reason |
|---|---|
| `tests/fixtures/new-projex-cases.tsv`; `tests/fixtures/projex-creators.txt` | Existing shared fixture rows and closed inventory remained authoritative; stronger assertions were implemented in both suites. |
| `tests/run-all.sh`; `tests/run-all.ps1` | Both already select focused suites; changing runner behavior was out of scope. |

## Success Criteria Verification

| Criterion | Method | Result | Evidence |
|---|---|---|---|
| Shell named API only | Focused positive/negative shell matrix | Pass | `new-projex.sh:27-70`; `PASS=178 FAIL=0`. |
| PowerShell named API only | Focused positive/negative PowerShell matrix | Pass | `new-projex.ps1:30-58`; `PASS=181 FAIL=0`. |
| Strict parser failure contract | Per-ID exit/stderr/stdout/full-snapshot assertions | Pass | Shell `:57-92`; PowerShell `:29-87`; each parser-negative case asserts exit `2`, one usage marker, no stdout, unchanged state. |
| 20 caller cutover and Parent semantics | Shared inventory plus command and header assertions | Pass | Shell `:114-138`; PowerShell `:110-132`; 20 scaffold/4 manual inventory. |
| Docs and runner selection | Inventory review, focused suites, aggregate attribution | Pass with baseline exception | Docs updated; both runners invoke focused suites; aggregate exit failures are pre-existing and unrelated. |

**Overall:** 5/5 migration acceptance criteria satisfied; aggregate-runner completion remains an explicitly preserved baseline exception.

## Issues and Deviations

### Aggregate baseline failures

- **Description:** Both aggregate runners exit `1` outside the migration contract.
- **Resolution:** None in this branch; masking unrelated suite/mode/summary/lifecycle failures is out of scope.
- **Impact:** Does not change focused migration behavior or acceptance evidence; recorded in plan, log, audit, and this walkthrough.

### PowerShell focused-suite exit state

- **Description:** A final expected collision left `$LASTEXITCODE=2` despite zero assertion failures when the suite ran in-process.
- **Resolution:** Move decision after `finally`; explicitly `exit 0` on success (`tests/new-projex.test.ps1:135-139`).
- **Verification:** Focused run returns `PASS=181 FAIL=0` and exit `0`; failed-assertion control recorded exit `1`.

## Key Insights

- Parse complete named token streams before normalization or filesystem checks; this makes malformed calls non-mutating by construction.
- Shared fixtures can remain stable while contract strength moves into paired platform assertions.
- PowerShell suites that deliberately invoke failing external commands must set their own final process exit explicitly after cleanup.
- **Rationale promoted:** none needed; source comments retain only durable implementation rationale.

## Lifecycle and Preservation

- Plan and execution log move together to `.projex/closed/`; this walkthrough is created there.
- `2608130629-new-projex-powershell-suite-exit-status-patch.md` was already born closed and remains there.
- Intentionally uncommitted auxiliary artifacts are preserved outside this close commit: `2608130514-2608130511-named-new-projex-parameter-migration-plan-stress.md` and `2608130624-named-new-projex-parameter-migration-implementation-audit.md`. The audit was copied to the originating checkout before worktree removal; neither artifact is staged, moved, deleted, or committed.
- Originating-checkout tracked user changes were stashed as `projex-close-2608130511-preserve-base-user-changes` for finalization and must be restored after landing.
