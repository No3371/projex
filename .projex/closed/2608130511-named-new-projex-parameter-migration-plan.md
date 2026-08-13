# Named-parameter `new-projex` API migration

> **Status:** Complete (Scoped Success; Aggregate Baseline Failures)
> **Author:** Agent
> **Source:** Direct request
> **Parent:** User
> **Related Projex:** 2608130419-parent-lineage-and-projex-tree-addition-walkthrough.md
> **Worktree:** Yes
> **Log:** 2608130511-named-new-projex-parameter-migration-plan-log.md
> **Completed:** 2026-08-13
> **Walkthrough:** 2608130511-named-new-projex-parameter-migration-plan-walkthrough.md

---

## Summary

Replace positional `new-projex` interfaces with strict named parameters; migrate every scaffold workflow in lockstep. This makes role-bound values unambiguous without changing scaffold, Parent-selection, naming, collision, or header behavior.

**Scope:** root framework `new-projex` implementations, 20 scaffold workflow directives, paired contract tests/fixtures, utility and test inventories.
**Estimated Changes:** 29 files — 2 implementations | 20 workflow specs | 2 suites | 2 fixtures/inventories | 3 inventories/docs.
**Split:** No split — single root `.projex` scope; four ordered, tightly coupled changes; within size budget.

## Objective

### Problem

`new-projex.sh` and `new-projex.ps1` bind ordered operands, so the five creation fields rely on position. All 20 scaffold workflows teach that obsolete transport. Existing suites prove Parent placement and an extra operand but not strict named-parameter parsing; their workflow guard merely looks for `{parent}` in legacy-shaped command lines.

- [x] Shell accepts only `new-projex.sh --repo-root <repo-root> --type <type> --title <title> --parent <User|Orchestrator|filename.md> [--projex-dir <projex-dir>]`.
- [x] PowerShell accepts only `new-projex.ps1 -RepoRoot <repo-root> -Type <type> -Title <title> -Parent <User|Orchestrator|filename.md> [-ProjexDir <projex-dir>]`.
- [x] Both parsers reject unknown flags, duplicate flags (case-folded for PowerShell), absent mandatory flags, flags without values, and every positional token before any filesystem write; every parser-negative case exits 2 with one stable stderr usage marker and no stdout-created path; legacy positional forms have no fallback.
- [x] Every one of the 20 scaffold workflow directives contains named Shell and PowerShell invocations while preserving its local Parent-selection precedence.
- [x] Shared fixtures and both focused suites prove semantic Parent behavior, strict parser rejection/no-write behavior, caller inventory, and absence of positional invocations.
- [x] `README.md`, `AGENTS.md`, and `tests/README.md` describe the named API and revised focused-test coverage; full test runners still execute the focused suites.

### Out of Scope

- Changing Parent grammar, local Parent-selection semantics, status/type mappings, filename minting, collision scans, headers, output hints, or direct-writer templates.
- Adding compatibility aliases, positional fallback, new scaffold types, or changing `execute-projex.md`, `close-projex.md`, `debug-projex.md`, or `sprint-projex.md`.
- Touching untracked `2608121912-parent-lineage-and-projex-tree-addition-audit.md`.

## Context

### Current State

`new-projex.sh:3-21` consumes four required plus one optional positional operand; `new-projex.ps1:7-14` uses positional `param` attributes. Both then normalize paths, reject empty repo/title/Parent, validate type and Parent, reject self/collision, and emit one Parent header. Shell usage failure exits 2; PowerShell `Fail` exits 2 for expected validation errors.

All 20 inventory-listed workflow specs invoke the dual-platform placeholder form with positional `{parent}`. Their preceding prose already resolves `{parent}` from workflow-local causal sources, then supplied orchestrator Parent, then `User`; only argument transport changes. Four manual writers create documents without this utility and retain their Parent templates.

`tests/new-projex.test.sh` and `.ps1` consume `tests/fixtures/new-projex-cases.tsv`, inspect `tests/fixtures/projex-creators.txt`, and currently check legacy invocation shape rather than forbidding it. `tests/run-all.sh` and `.ps1` already select both suites; their suite lists need no behavioral edit.

### Key Files

| File(s) | Role | Change |
|---|---|---|
| `new-projex.sh`; `new-projex.ps1` | scaffold API | strict named parser; usage/error contract |
| `archive-projex.md`; `audit-projex.md`; `coach-projex.md`; `conclude-projex.md`; `define-projex.md`; `eval-projex.md`; `explore-projex.md`; `guide-projex.md`; `imagine-projex.md`; `interview-projex.md` | first 10 scaffold callers | named directives only |
| `memo-projex.md`; `navigate-projex.md`; `patch-projex.md`; `plan-projex.md`; `preplan-projex.md`; `propose-projex.md`; `redteam-projex.md`; `review-projex.md`; `scan-projex.md`; `stress-projex.md` | remaining 10 scaffold callers | named directives only |
| `tests/new-projex.test.sh`; `tests/new-projex.test.ps1`; `tests/fixtures/new-projex-cases.tsv`; `tests/fixtures/projex-creators.txt` | shared contract and caller guard | named invocations, malformed-input matrix, no-positional proof |
| `README.md`; `AGENTS.md`; `tests/README.md` | utility/test inventories | API and coverage wording |

### Dependencies

- **Requires:** committed Ready plan; a worktree because base checkout is dirty and this is a 29-file cutover.
- **Blocks:** workflow authors must not copy a positional scaffold command after migration.

### Constraints

- Mandatory named parameters occur exactly once; `--projex-dir` / `-ProjexDir` occurs zero or one time.
- Shell flag names are lowercase kebab case; PowerShell parameter names are advertised PascalCase and bind case-insensitively.
- A flag consumes exactly its next non-option token. Missing value, unknown option, duplicate option, omitted mandatory option, or non-option token is a usage error: exit 2, exactly one stable stderr usage marker, no stdout-created path, and no file/directory write.
- Keep current semantic validation diagnostics and exit classes after parsing: empty values, missing repo directory, unknown type, invalid Parent, empty slug, self Parent, collision, and write failures retain their current behavior.
- Do not reframe any workflow's Parent precedence. Direct invocation remains `User`.

### Impact Analysis

- **Direct:** argument parsing, usage text, all standard scaffold directives, focused test inputs.
- **Adjacent:** utility guidance and suite inventories; `tests/run-all.sh` / `.ps1` continue to call the renamed-contract suites unchanged.
- **Downstream:** agents invoking copied workflow commands; both POSIX and PowerShell environments.

## Implementation

### Overview

Make parsing strict before existing normalization and creation logic; preserve the validated value variables thereafter. Cut workflow examples over atomically, then replace legacy-shape checks with executable no-positional proof and update descriptions.

### Step 1: Implement strict named parsers

**Objective:** Make both scaffolders accept only their platform API while preserving all post-parse behavior.
**Confidence:** High
**Depends on:** None
**Do-Projex:** Encouraged
**Verify-Projex:** Encouraged

**Files:** `new-projex.sh`; `new-projex.ps1`

**Changes:**

1. Replace positional usage banners and assignments with the exact platform signatures:
   ```text
   new-projex.sh --repo-root <repo-root> --type <type> --title <title> --parent <parent> [--projex-dir <projex-dir>]
   new-projex.ps1 -RepoRoot <repo-root> -Type <type> -Title <title> -Parent <parent> [-ProjexDir <projex-dir>]
   ```
2. Parse left-to-right into the existing `repo_root`/`RepoRoot`, `type`/`Type`, `title`/`Title`, `parent`/`Parent`, and optional projex-dir variables. Track presence separately so empty supplied values still reach existing semantic validation rather than masquerading as omitted flags.
3. Reject an unrecognized option, repeated accepted option, option missing a following non-option value, a bare positional token, or a finished parse missing any mandatory option. Emit exactly one stable usage marker to stderr, emit no created path to stdout, and exit 2; perform this entire phase before path normalization, root discovery, `mkdir`, or write.
4. In PowerShell, parse raw invocation tokens rather than relying on positional `param` binding, so duplicate and stray-token behavior is explicit and testable. Accept PowerShell parameter spelling case-insensitively, normalize it to the advertised parameter before cardinality checking, and reject all other token forms.
5. Leave type mapping, Parent grammar/self check, born-closed routing, slug/time/collision logic, emitted header, and stdout hints unchanged after parser handoff.

**Rationale:** One parser per platform guarantees exactly-once semantics that shell arity checks and PowerShell parameter binding cannot prove consistently. Reusing existing variables avoids a behavioral rewrite.

**Verification:**

- `bash -n new-projex.sh`
- PowerShell parser AST has zero parse errors for `new-projex.ps1`.
- Focused paired suites pass after Steps 2–3.

**If this fails:** Revert only parser/usage changes; retain existing creation logic untouched and repair the token-to-variable boundary.

### Step 2: Cut over every scaffold directive

**Objective:** Replace all positional creator examples without changing Parent selection.
**Confidence:** High
**Depends on:** Step 1
**Do-Projex:** Encouraged

**Files:** the 20 workflow specs listed in **Key Files**.

**Changes:**

1. In each listed workflow, preserve its adjacent `Resolve {parent}` prose verbatim.
2. Replace its single dual-platform positional directive with two explicit commands:
   ```bash
   {projex-scripts}/new-projex.sh --repo-root <repo-root> --type <workflow-type> --title "<workflow-title>" --parent {parent} --projex-dir <projex-folder>
   ```
   ```powershell
   {projex-scripts}\new-projex.ps1 -RepoRoot <repo-root> -Type <workflow-type> -Title "<workflow-title>" -Parent {parent} -ProjexDir <projex-folder>
   ```
   Substitute each workflow's existing type and title placeholder; preserve archive/conclude born-closed explanatory notes.
3. Do not add scaffold calls to `execute-projex.md`, `close-projex.md`, `debug-projex.md`, or `sprint-projex.md`; retain their manual Parent-template assertions.

**Rationale:** Separate concrete examples prevent a fictitious shared flag syntax while maintaining each workflow's causal Parent rules.

**Verification:** Focused inventory guard reports exactly the existing 20 scaffold creators, detects one named Shell and one named PowerShell command for each, and finds no positional `new-projex.sh` / `.ps1` command.

**If this fails:** Correct the command form in the named workflow; do not alter its Parent-resolution text to satisfy the guard.

### Step 3: Replace focused contract coverage

**Objective:** Make shared tests prove the new API and reject the old one on both platforms.
**Confidence:** High
**Depends on:** Steps 1–2
**Do-Projex:** Encouraged
**Verify-Projex:** Encouraged

**Files:** `tests/new-projex.test.sh`; `tests/new-projex.test.ps1`; `tests/fixtures/new-projex-cases.tsv`; `tests/fixtures/projex-creators.txt`

**Changes:**

1. Keep the shared Parent fixture authoritative for `User`, `Orchestrator`, valid filename, missing Parent, malformed Parent, and path Parent. Extend it only where needed to distinguish explicit optional projex dir from omitted default behavior.
2. Convert every fixture-driven and direct positive call to its named platform syntax. Assert created path/header Parent exactly once as today; add default `.projex` placement coverage when optional dir is omitted.
3. Give every parser-negative case an ID, expected exit `2`, and expected stable usage marker. Cover every missing mandatory option; every duplicated mandatory option; a case-folded PowerShell duplicate (for example `-Type` plus `-type`); duplicate optional dir; each option lacking its next non-option value (including `--title --parent User` / `-Title -Parent User`); an unknown option; a stray positional token; and legacy positional forms. Capture stdout and stderr separately; assert exit exactly `2`, exactly one expected usage marker on stderr, and no stdout-created path. Before each malformed call, snapshot the complete temporary-repository filesystem state (entries, types, and contents); assert it is unchanged afterward, retaining unchanged Markdown-file count as the document-specific check.
4. Add a complete mixed-case PowerShell success call using case variants of every advertised parameter, including `-ProjexDir`; assert its created path and exactly-one Parent header as for nominal positives. Keep the case-folded duplicate in the parser-negative matrix.
5. Replace legacy line-substring/`{parent}` arity checking with a closed caller proof: inventory must remain exactly 20 scaffold and 4 manual writers; every scaffold workflow must contain its platform-specific fully named command; scanning the controlled workflow corpus must reject any `new-projex.sh`/`.ps1` invocation that is positional or lacks one required named parameter.
6. Keep manual Parent-template assertions and use shared fixture/inventory files from both suites; do not create separate platform matrices.
**Rationale:** Behavior tests cover parser and creation boundaries; a structural caller proof prevents future docs from reintroducing obsolete syntax.

**Verification:**

- `bash tests/new-projex.test.sh` emits `FAIL=0`.
- `pwsh -NoProfile -File tests/new-projex.test.ps1` emits `FAIL=0`.
- Every parser-negative call exits 2, emits exactly one expected stderr usage marker, emits no stdout-created path, and leaves the full temporary-repository filesystem state and Markdown count unchanged.

**If this fails:** Repair the parser or command fixture indicated by the failing case; do not weaken inventory or no-positional assertions.

### Step 4: Align utility and test inventories; complete atomic verification

**Objective:** Document the new contract and commit only the complete migration.
**Confidence:** High
**Depends on:** Steps 1–3

**Files:** `README.md`; `AGENTS.md`; `tests/README.md`

**Changes:**

1. Update `README.md` and `AGENTS.md` utility descriptions to state that `new-projex` is a strict named-parameter scaffold and show/link the exact Shell and PowerShell forms where inventory prose supports usage detail.
2. Update `tests/README.md` from the current 46-case legacy Parent/arity description to the observed final test count and named-parser/no-positional coverage, including exact parser-negative usage/no-write assertions and PowerShell case-insensitivity coverage. Do not guess the count before running both suites.
3. Confirm `tests/run-all.sh` and `tests/run-all.ps1` already select the focused suites; leave their suite lists unchanged unless a test filename changes (not planned).
4. Run syntax, then both focused suites and confirm every parser-negative case proves exit `2`, one stderr usage marker, no stdout-created path, and unchanged full temporary-repository state; then run both aggregate runners. Stage only the 29 planned paths with `stage-n-commit` in one commit; do not stage pre-existing user changes or the excluded audit artifact.

**Rationale:** The public utility description and test inventory must match executable behavior; an explicit-path atomic commit prevents mixed old/new caller states.

**Verification:**

- `bash tests/run-all.sh` finishes with every suite passing.
- `pwsh -NoProfile -File tests/run-all.ps1` finishes with every suite passing.
- Focused-suite results show every parser-negative case: exit `2`, exactly one expected stderr usage marker, no stdout-created path, unchanged full temporary-repository filesystem state, and unchanged Markdown count.

**If this fails:** Restore untouched inventory prose or fix the named-contract failure; never broaden staging to absorb unrelated worktree changes.

## Verification Plan

### Automated Checks

- [ ] `bash -n new-projex.sh tests/new-projex.test.sh`
- [ ] PowerShell AST parse reports no errors for `new-projex.ps1` and `tests/new-projex.test.ps1`.
- [ ] `bash tests/new-projex.test.sh`
- [ ] `pwsh -NoProfile -File tests/new-projex.test.ps1`
- [ ] `bash tests/run-all.sh`
- [ ] `pwsh -NoProfile -File tests/run-all.ps1`

### Manual Verification

- [ ] Invoke each platform's former positional form and a missing-value token case; observe exit 2, exactly one stderr usage marker, no stdout-created path, and an unchanged complete disposable-repository filesystem snapshot.
- [ ] Inspect the 20 workflow specs: each preserves its existing Parent-resolution sentence and shows both platform-native named commands.

### Acceptance Validation

| Criterion | Method | Expected |
|---|---|---|
| Named APIs | positive calls in paired suites | one scaffold per valid command |
| Strict parsing | paired negative matrix | every case: exit 2, one stderr usage marker, no stdout-created path, unchanged full filesystem state and Markdown count |
| Complete caller cutover | inventory/no-positional guard | 20 scaffold, 4 manual; zero positional |
| Parent semantics | shared Parent rows and header count | accepted values copied once; invalid rejected |
| Docs/inventories | focused + aggregate runners | descriptions and suite counts match passing tests |

## Rollback Plan

1. Before the atomic commit, discard only edits to the 29 named paths in the execution worktree.
2. After commit but before close, abandon the ephemeral branch/worktree through the documented close workflow; base branch and unrelated dirty files remain unchanged.

## Revision Log

- **2026-08-13:** Strengthened Steps 1, 3–4 and verification contracts: every parser-negative case now proves exact exit/diagnostic/stdout/no-write behavior; PowerShell adds mixed-case success including `-ProjexDir` plus case-folded duplicate rejection — trigger: `2608130514-2608130511-named-new-projex-parameter-migration-plan-stress.md` Findings 1–3.

## Notes

### Risks

- Parser drift between platforms: identical shared case IDs and equivalent assertions expose divergence.
- A workflow keeps a positional example: closed inventory plus command-form proof fails.
- Broad base dirtiness: worktree mode and explicit-path staging isolate the migration.

### Open Questions

None.
