# Plan: close-precheck Script

> **Status:** Ready
> **Author:** luna (xhigh)
> **Source:** 2607291729-close-projex-modernization-proposal.md
> **Related Projex:** 2607132112-projex-rebase-close-scripts-redteam.md | 2607261121-close-scripts-dirty-base-safety-plan.md (closed) | 2607261520-close-scripts-dirty-base-safety-audit.md (closed)
> **Worktree:** Yes

---

## Summary

Add a report-only close preflight that replaces close-projex's manual repo, branch, diff, and auxiliary-document discovery. The shell and PowerShell pair will resolve explicit or inferred plan context, read the execution log's recorded base, emit a versioned escaped record set with snapshot identity, classify every related `.projex` document in the originating and recorded child roots, surface stashes, and report the two § 7 cleanliness gates without mutating the repository. Output is advisory evidence, not close authorization.

**Scope:** Root utility scripts, their behavioral tests, test runners, and utility documentation; no close workflow or finalizer behavior.
**Estimated Changes:** 9 files — 2 new scripts, 2 new test suites, 2 test-runner edits, 3 documentation edits.

## Objective

### Problem / Gap / Need

`close-projex.md` currently asks the close agent to reconstruct repository state by hand. `execute-precheck.{sh,ps1}` establishes the local convention for a report-only preflight, but close has no equivalent for the recorded base branch, ephemeral commit range, change stat, related auxiliary documents, stash state, or the § 7 gates.

The A1 direction in the source proposal is independently actionable under the human-confirmed scope: build the script pair and tests first, without changing close's lifecycle, finalizers, or verification rules. The source proposal remains Draft; this plan does not imply whole-proposal acceptance or close the source. Its A1 dependency note is aligned separately with this revision's stricter hard-error boundary.

### Success Criteria

- [ ] `close-precheck.sh` and `close-precheck.ps1` accept an optional plan file; with no argument they infer a unique plan from the current `projex/*` branch, and both fail clearly on missing, ambiguous, malformed, duplicate, or inaccessible context.
- [ ] A valid run emits `SCHEMA_VERSION=1` plus machine-readable `REPO_ROOT`, `BASE_BRANCH`, `EPHEMERAL_BRANCH`, `PLAN_REL`, and `LOG_REL` values, obtains `BASE_BRANCH` from exactly one execution-log header, and never assumes `main`/`master`.
- [ ] All variable output values use one documented percent-encoded UTF-8 record grammar; record types, field order, `NONE`, duplicate paths, warnings/errors, and terminal `RESULT` values are stable and identical across platforms. No raw path, status, subject, or control character can spoof a record.
- [ ] A valid run emits `BASE_SHA`, `EPHEMERAL_SHA`, recorded worktree identity/HEAD when applicable, and UTC generation metadata. If refs or worktree registration drift during the run, it emits `RESULT=STALE` and exits non-zero; consumers must compare identity and rerun rather than treat the report as authorization.
- [ ] A valid run emits the ephemeral commit list, `base..ephemeral` diff stat, stash entries, and a related-document inventory covering every matching `.projex` file in the originating root plus the recorded child worktree's eligible `.projex` roots. Each entry has repo-relative path, `ORIGIN`/`CHILD` location, `tracked-on-ephemeral`, `tracked-on-base`, or `untracked` classification, and strict status (or `MISSING`). A path tracked on both refs is `tracked-on-ephemeral` with explicit `also-on-base`; child-only entries remain factual `untracked` records and never imply deletion or resolution.
- [ ] The report emits both § 7 gate results: originating/base checkout tracked-clean status and, when a worktree is recorded, child-worktree fully-clean status. Gates are `PASS`, `WARN`, or `N/A`; warnings preserve evidence and do not cause mutation.
- [ ] Missing/ambiguous/unsupported execution context (including the log or `> **Base Branch:**` header) exits non-zero with an encoded error record; resolved context with dirty/untracked warnings exits zero with `RESULT=PASS_WITH_WARNINGS`. `RESULT=PASS` and `RESULT=PASS_WITH_WARNINGS` are advisory, never approval.
- [ ] Neither implementation mutates refs, index, worktrees, files, stash state, or branch checkout. The documented Git allowlist, argument-quoting rules, canonical path containment, symlink policy, and sequential-read precondition are independently checked.
- [ ] Both test runners execute the new suites exactly once and fail closed on missing suite summaries; shell and PowerShell suites independently verify the same observable contract. Cross-platform acceptance is incomplete, not green, when PowerShell evidence is `NOT RUN`.
- [ ] The framework/README inventory documents the new utility, protocol, snapshot/rerun rule, child-root scope, and advisory boundary.

### Out of Scope

- Any edit to `close-projex.md`, `execute-projex.md`, `orchestrate-projex.md`, or other workflow contracts; those are A2–A4 work.
- Evidence consumption, walkthrough tiers, auxiliary-document reconciliation actions, keyed close invocation, or `verify-projex` integration.
- Generalizing the utility for `debug-projex` closure; this plan is close/plan lifecycle-specific.
- Any checkout, commit, stage, stash, worktree creation/removal, merge, rebase, or cleanup operation.
- Changes to the existing finalizer scripts or their 466-assertion safety matrix.

## Context

### Current State

- `execute-precheck.sh`/`.ps1` resolve a plan directory, repo root, current branch, and plan-relative path, then report commit/cleanliness warnings while remaining read-only. Their output and `git -C` style are the compatibility baseline.
- `close-projex.md` § 0–3 manually finds the repo/base branch, execution data, and actual diff; § 7 defines two different cleanliness bars for the originating checkout and child execution worktree.
- The execution-log template records `Repo Root`, `Plan File`, `Base Branch`, and an optional `Worktree Path`. The plan may carry a `Log` filename after execution; otherwise the companion `*-log.md` is the fallback.
- Related auxiliary documents can be tracked on the ephemeral branch, tracked only on base, present in both refs, or untracked under a `.projex` folder. Multiple `.projex` folders are supported; scanning must not assume only the repository-root folder.
- Existing behavioral tests build throwaway repositories, assert observable state, and report `PASS=N FAIL=M`. Shell and PowerShell suites are intentionally independent.

### Key Files

> Quick reference — detailed changes are in Implementation steps below.

| File | Role | Change Summary |
| ------ | ------ | ---------------- |
| `close-precheck.sh` | POSIX close preflight | New report-only implementation and stable output contract. |
| `close-precheck.ps1` | Windows close preflight | Independent PowerShell implementation with matching behavior/output. |
| `tests/close-precheck.test.sh` | Bash behavior suite | New throwaway-repo matrix for resolution, inventory, gates, warnings, and non-mutation. |
| `tests/close-precheck.test.ps1` | PowerShell behavior suite | Independent parity matrix using PowerShell fixtures and assertions. |
| `tests/run-all.sh` | Bash suite runner | Include the new suite in aggregation. |
| `tests/run-all.ps1` | PowerShell suite runner | Include the new suite in aggregation. |
| `tests/README.md` | Test contract/index | Document the new suite, coverage, and report-only fixture guarantee. |
| `README.md` | Human utility index | Add `close-precheck` beside `execute-precheck`. |
| `SKILL.md` | Framework utility guidance | Add a `Prechecks` utility subsection documenting both precheck pairs; the current file has no utility-script table, so do not invent a table or alter unrelated sections. |

### Dependencies

- **Requires:** Git; Bash for the `.sh` suite; PowerShell for `.ps1` parity; the existing execution-log header contract; no package installation.
- **Blocks:** Nothing. A2–A4 may consume the report only after schema v1, snapshot/rerun, and supported-platform acceptance complete; their consumer work remains outside this plan.

### Constraints

- Report-only is a hard contract: use file reads and this Git read allowlist only — `rev-parse`, `branch --show-current`, `show-ref`, `for-each-ref`, `log`, `diff --stat`, `ls-tree`, `ls-files`, `status`, `stash list`, and `worktree list --porcelain`; no command may alter checkout, refs, index, worktree registration, files, or stash state. Pass every path/ref as a quoted argument; never use `eval` or a shell-generated command string.
- Derive the target repository from the plan/log context and use `git -C`; do not rely on the caller's current directory after resolution and never fall back to `main`/`master`. Canonicalize existing paths before containment checks, reject symlink escapes, resolve relative `Worktree Path` only relative to the recorded canonical `Repo Root`, and verify exact registered worktree path, branch, and HEAD.
- Base branch must be a local branch ref. Reject a tag, SHA, remote-tracking ref, malformed/duplicate field, or missing field before emitting a misleading commit range. Distinguish unsupported historical log format from malformed current context.
- Preserve the existing precheck convention: hard context/format/snapshot errors are non-zero; cleanliness/document-state warnings remain visible, encoded, and do not silently become failures.
- Use literal plan-filename matching for inventory, recurse across eligible `.projex` folders in the originating root and recorded child worktree, exclude `.git` and unrelated `.projexwt`, and keep all emitted repository paths stable and encoded repo-relative except the required encoded `REPO_ROOT`/worktree values. Inventory is factual; lifecycle disposition remains a later close decision.
- Keep `.sh` and `.ps1` logic behaviorally equivalent, but do not make one platform's tests depend on the other platform's runtime. PowerShell parser/runtime evidence is required for parity acceptance; otherwise record `NOT RUN`.
- Reports are complete-or-fail: batch Git/filesystem discovery, enforce a fixed 8 MiB report-output budget in both implementations, and never silently truncate inventory or records. A budget breach emits `RESULT=ERROR` and non-zero exit.
- Schema ownership/adoption: the framework utility maintainer owns schema v1 and its compatibility policy; A2/A4 automation must not parse the report before this plan's protocol and platform gates pass.

### Assumptions

- A closeable execution has a companion execution log. `> **Repo Root:**` and `> **Base Branch:**` are one-line fields in that log; `> **Worktree Path:**` is optional and identifies worktree mode. Required headers occur exactly once; conflicting duplicates are hard errors.
- The plan's `> **Log:**` filename, when present, is authoritative relative to the plan's `.projex` folder; absent that field, the sibling `<plan-stem>-log.md` is the only fallback. Existing plan/log paths are canonicalized and must remain in the same Git repository/worktree set.
- `Worktree Path` may be absolute or relative to the recorded `Repo Root`; only an exact registered worktree with the logged branch/HEAD is accepted. Symlink escapes and reused/mismatched registrations fail.
- Branch names and document filenames do not contain newlines; other repository-controlled values are untrusted and percent-encoded. Framework filename uniqueness makes a no-argument branch-to-plan lookup safe only when it returns exactly one candidate.
- A document's first strict `> **Status:**` line is its displayed status. Missing status is reportable (`MISSING`), not a reason to suppress the document from inventory. Inventory class does not infer whether an auxiliary document is resolved or safe to remove.
- The report captures a sequential snapshot; concurrent mutation is outside the utility's guarantee. Ref/worktree drift detected before terminal output yields `STALE`/non-zero, and future consumers must compare snapshot identity and rerun.

### Impact Analysis

- **Direct:** Two new read-only utilities, two independent test suites, runner registration, and utility documentation.
- **Adjacent:** `close-projex.md` can consume the emitted report in a later A2/A4 change; finalizer gates remain the enforcement backstop.
- **Downstream:** Agents/orchestrators gain a deterministic close context, but no existing invocation or exit code changes because no workflow calls the script in this plan.

## Implementation

### Overview

Implement resolution and reporting once per platform with the same externally visible sections, versioned record grammar, snapshot fields, and failure taxonomy. Resolve plan → log → recorded repo/base/worktree → ephemeral branch first; canonicalize and pin registered paths; capture ref/worktree identities; only then gather refs, diff, inventory, stashes, and gates. Recheck ref/worktree identity before the terminal result. Tests cover each resolution mode, child-root inventory, encoded/untrusted values, drift, scale budget, and prove that warnings/reporting leave the fixture byte-for-byte and ref-for-ref unchanged.

### Step 1: Implement the POSIX close precheck

**Objective:** Add the canonical Bash report-only implementation.
**Confidence:** High
**Depends on:** None
**Verify-Projex:** Encouraged

**Files:**

- `close-precheck.sh`

**Changes:**

```text
Before: file absent.
After: close-precheck.sh [<plan-file>]

Resolution:
1. Accept an explicit plan path, or with no argument require the current branch to be
   projex/* and find exactly one matching *-plan.md under an eligible .projex/ folder.
2. Canonicalize the plan and derive its log from the plan's > **Log:** filename, or its
   sibling *-log.md fallback. Require plan/log containment in the same Git repository;
   fail on absent, escaped, symlinked, or inaccessible paths.
3. Parse exactly one > **Repo Root:**, > **Base Branch:**, and optional > **Worktree Path:**
   header from the log. Resolve a relative worktree path against the canonical recorded
   repo root; validate exact `git worktree list --porcelain` path/branch/HEAD identity,
   local base ref, and the ephemeral branch's current checkout. Reject conflicting
   duplicates, tags, SHAs, remote refs, reused paths, and unsupported log format.
4. Capture `SCHEMA_VERSION=1`, `GENERATED_AT_UTC`, `BASE_SHA`, `EPHEMERAL_SHA`, recorded
   origin/worktree HEAD and registration identity, then emit encoded context fields
   `REPO_ROOT`, `BASE_BRANCH`, `EPHEMERAL_BRANCH`, `PLAN_REL`, `LOG_REL`, and applicable
   `WORKTREE_PATH`.

Record protocol:
- Every value is UTF-8 percent-encoded (including `%`, tab, CR/LF, `=`, and terminal
  control bytes); fixed keys and record type/field order are ASCII and stable.
- `SECTION=COMMITS|DIFF_STAT|PROJEX_INVENTORY|STASHES|GATES` starts each section;
  records are `RECORD=<TYPE>\t<encoded fields>`. `RECORD=NONE\t<TYPE>` represents an
  empty section. `ERROR=<encoded message>` is emitted on hard failure.
- Commit records carry SHA + encoded subject; diff/stat and stash records carry encoded
  Git lines; inventory records carry path, `ORIGIN`/`CHILD`, tracking class, strict
  status/`MISSING`, and `also-on-base`; gate records carry gate name, `PASS`/`WARN`/`N/A`,
  and encoded evidence. Duplicate paths are one record with deterministic precedence.
- Terminal output is exactly one `RESULT=PASS|PASS_WITH_WARNINGS|STALE|ERROR`; `PASS` and
  `PASS_WITH_WARNINGS` exit 0, `STALE` and `ERROR` exit non-zero. Human-readable labels
  may accompany records but are never part of the parse contract.

Report sections:
- `COMMITS base..ephemeral`: `git log --oneline` (or encoded `NONE`).
- `DIFF_STAT base..ephemeral`: `git diff --stat` (or encoded `NONE`).
- `PROJEX_INVENTORY`: collect tracked paths from both refs plus filesystem-only `.projex`
  files in the recorded originating root and child worktree's eligible roots. Exclude
  `.git` and unrelated `.projexwt`; retain files containing the literal plan filename,
  classify with ephemeral precedence plus `also-on-base`, and print first strict status
  or `MISSING`. Child-only files are reported as `CHILD`/`untracked`; no disposition is
  inferred.
- `STASHES`: print `git stash list` (or encoded `NONE`).
- `GATES`: check the recorded originating/base checkout with
  `status --porcelain --untracked-files=no --ignore-submodules=dirty`; if a worktree
  is recorded, check it with `status --porcelain --ignored=matching`. Print PASS/WARN
  evidence and use N/A for the child gate in checkout mode.

After gathering, re-read ref tips and worktree registration. If identity changed, emit
`RESULT=STALE` and exit non-zero; never claim a complete report for a moving context.
For stable context, exit 0 after a complete report, including warnings, with
`RESULT=PASS` or `RESULT=PASS_WITH_WARNINGS`. Hard context, format, path, output-budget,
or Git-read errors emit encoded `ERROR` plus `RESULT=ERROR` and exit non-zero; never
report a false context for missing/ambiguous/unsupported plan, log, required header,
repo, local base, ephemeral branch, path identity, or snapshot.
```

**Rationale:** Close needs the recorded originating repo and base branch, not a guessed `main` or the caller's current directory. Canonical paths and exact registration identity prevent wrong-worktree reports; a versioned escaped protocol prevents parser spoofing; snapshots make drift visible. Resolving all context before reporting keeps output safe to hand to later close steps as advisory evidence; warnings remain evidence rather than mutations or hidden gate failures.

**Verification:** `bash -n close-precheck.sh`; run the Bash suite directly; parse every successful output with the protocol fixture parser; inspect explicit/inferred runs for identical encoded context and snapshot fields; exercise spaces, `=`, `%`, tabs, duplicate headers, symlink/relative/reused paths, child-only docs, and snapshot drift; static-review the Git allowlist and shell quoting; assert no ref/index/file/worktree/stash changes before and after.

**If this fails:** Delete the new untracked script in the execution worktree and rerun the suite from the unchanged base; do not use checkout/reset commands to recover a report-only fixture.

---

### Step 2: Implement the PowerShell parity script

**Objective:** Provide the same close-precheck contract on Windows.
**Confidence:** High
**Depends on:** Step 1 for the observable contract; implementation remains independent.
**Verify-Projex:** Encouraged

**Files:**

- `close-precheck.ps1`

**Changes:**

```text
Before: file absent.
After: close-precheck.ps1 [-PlanFile <plan-file>]

Mirror Step 1's resolution order, strict-header/duplicate rejection, canonical path and
exact worktree registration validation, local-branch validation, snapshot capture/drift
check, child-root inventory, read-only Git allowlist, percent-encoded record protocol,
section labels, gate semantics, warning behavior, and exit codes. Use PowerShell-native
path/process handling and quote every Git argument; do not shell out to the Bash
implementation. Preserve forward-slash repo-relative paths in encoded inventory so
output is comparable. A missing PowerShell runtime is `NOT RUN`, never parity PASS.
```

**Rationale:** The repository treats shell and PowerShell utilities as duplicated contracts and tests them independently; parity cannot be inferred from one implementation.

**Verification:** Parse the script with PowerShell's parser/AST API; run the PowerShell suite directly on Windows/PowerShell; compare its fixture assertions and decoded key/record fields with the Bash contract. Confirm malformed, duplicate, escaped-path, and drifted context exits non-zero and dirty-but-resolved context exits zero. If PowerShell is unavailable, record `NOT RUN` and leave cross-platform acceptance open.

**If this fails:** Remove only the new PowerShell script and its generated temporary fixtures; leave the Bash implementation and repository state untouched.

---

### Step 3: Add independent behavioral coverage

**Objective:** Lock down the read-only contract and cross-platform edge cases before any workflow consumes the report.
**Confidence:** High
**Depends on:** Steps 1–2.
**Verify-Projex:** Encouraged

**Files:**

- `tests/close-precheck.test.sh`
- `tests/close-precheck.test.ps1`

**Changes:**

```text
Before: no close-precheck suites.
After: each suite creates and removes throwaway repositories, reports PASS=N FAIL=M,
and asserts observable behavior rather than implementation details.

Required matrix:
- explicit plan path resolves encoded repo/log/base/ephemeral fields, schema, snapshot
  IDs, generation metadata, and exact registered worktree identity;
- no-argument inference succeeds for one matching plan and fails for zero/multiple
  candidates or a non-projex current branch;
- missing/duplicate/conflicting headers, unsupported old format, missing log, missing
  Base Branch, invalid/non-local base, escaped/symlinked/relative/reused worktree path,
  and wrong/non-projex ephemeral branch fail before a false result;
- commit list, diff stat, stash entries, `NONE`, and terminal results decode through the
  protocol parser; paths/subjects/statuses containing spaces, `=`, `%`, tabs, and
  terminal-control bytes cannot create records or alter arguments;
- inventory covers an ephemeral-only plan/log, base-only tracked auxiliary doc,
  untracked auxiliary doc, tracked-on-both annotation, multiple originating `.projex`
  folders, a recorded child-worktree `.projex` folder with child-only docs, missing
  status, deterministic duplicate paths, and literal filename matching without false
  path matches. Child-only records remain `untracked` and require no inferred
  disposition;
- clean checkout and worktree fixtures report PASS; tracked originating changes,
  child untracked/modified/ignored content, and checkout-mode child N/A report the
  documented gate/result records;
- ref/worktree drift during reporting emits `STALE` and non-zero; a generated scale
  fixture (at least 100 eligible folders / 1,000 candidates) completes without silent
  truncation, and a controlled output-budget breach fails explicitly;
- every successful warning/report run leaves branch tips, checked-out branches,
  worktree registrations, index, file bytes, and stash list unchanged; static checks
  reject mutating Git commands and unsafe shell/process construction;
- both suites parse and verify the same decoded key/record/exit-code contract
  independently.
```

**Rationale:** The output feeds a later destructive close, so tests must prove truthful, parseable, snapshot-bound discovery and non-mutation. The matrix covers the source proposal's multi-`.projex` and untracked-auxiliary risks, child-worktree loss path, untrusted values, and platform drift without testing finalizer behavior again.

**Verification:** Run each suite directly and assert its summary has zero failures plus protocol-parser coverage. Run the full Bash and PowerShell aggregators after runner registration; each must prove exact suite execution and fail closed on a missing summary. On environments without PowerShell, record `NOT RUN`; do not claim cross-platform parity or complete acceptance.

**If this fails:** Fix the script or fixture; never weaken an assertion merely because a warning is inconvenient. Temporary repositories must be removed by suite cleanup even on assertion failure.

---

### Step 4: Register and document the utility

**Objective:** Make the new pair discoverable and ensure every standard test invocation exercises it.
**Confidence:** High
**Depends on:** Steps 1–3.
**Do-Projex:** Encouraged

**Files:**

- `tests/run-all.sh`
- `tests/run-all.ps1`
- `tests/README.md`
- `README.md`
- `SKILL.md`

**Changes:**

```text
Before:
- tests/run-all.{sh,ps1} omit close-precheck.test.{sh,ps1}; tests/README.md has no
  close-precheck coverage row.
- README.md's utility table stops at execute-precheck.
- SKILL.md's Utility Scripts section has no precheck subsection.
- The Bash runner can aggregate a missing suite as zero and no runner-level assertion
  proves exact suite membership/execution.

After:
- Add close-precheck.test.sh and close-precheck.test.ps1 to the corresponding suite
  arrays, preserving PASS/FAIL aggregation and existing suite order semantics; fail
  closed on nonzero suite process status or a missing/duplicate `PASS=N FAIL=M` summary.
- Add a runner-level fixture/assertion that each close-precheck suite is executed exactly
  once; report PowerShell `NOT RUN` distinctly when its runtime is unavailable.
- Add the suite, assertion count after implementation, fixture/no-network guarantee,
  report-only boundary, versioned encoded protocol, snapshot/rerun rule, child-root
  inventory scope, scale/output-budget behavior, and platform-gate policy to
  tests/README.md.
- Add `close-precheck` to README.md's utility table beside `execute-precheck`, marked
  report-only/advisory and not an authorization or finalizer replacement.
- Add a `#### Prechecks` subsection to SKILL.md's Utility Scripts guidance documenting
  `execute-precheck` (execution validation) and `close-precheck` (versioned close-context
  report, required log/base context, child-root inventory, report-only/advisory result);
  do not alter unrelated utility contracts.
```

**Rationale:** The repo's human-facing script inventory is in README.md, while SKILL.md has prose utility subsections rather than a table. Updating both actual surfaces avoids leaving the new script undiscoverable and records the report-only boundary for future workflow authors.

**Verification:** Confirm each runner executes the new suite exactly once, fails on missing/duplicate summary or nonzero process status, and still parses the final `PASS=N FAIL=M` line. Check README/SKILL references use exact filenames and describe encoding, snapshots, child scope, advisory results, and no mutations. Run complete available aggregators; report PowerShell `NOT RUN` separately and verify documentation describes only A1, not future A2–A4 behavior.

**If this fails:** Revert only the documentation/runner edits in the worktree; retain the tested scripts until the mismatch is understood.

## Verification Plan

> Per-step verification above checks each change in isolation; this section checks the complete contract.

### Automated Checks

- [ ] `bash -n close-precheck.sh` passes; protocol parser accepts only schema v1 records.
- [ ] PowerShell parser/AST validation passes for `close-precheck.ps1` and its test suite; `NOT RUN` remains incomplete acceptance when runtime is absent.
- [ ] `bash tests/close-precheck.test.sh` ends `PASS=N FAIL=0`.
- [ ] `pwsh tests/close-precheck.test.ps1` ends `PASS=N FAIL=0` where PowerShell is supported.
- [ ] `bash tests/run-all.sh` and `pwsh tests/run-all.ps1` include the new suites exactly once, fail closed on missing summaries/process errors, and end with zero failures on supported platforms.
- [ ] Scale/output-budget, path canonicalization, duplicate-header, encoded-value, child-root, and snapshot-drift fixtures pass without silent truncation.
- [ ] Static read-command/argument review confirms no mutating Git command, `eval`, or unquoted path/ref construction; no existing finalizer/workflow file changed.

### Manual Verification

- [ ] Run with an explicit plan from a checkout-mode fixture and with no argument from its ephemeral branch; decoded context, schema, snapshot fields, and report sections agree.
- [ ] Run from a worktree fixture; confirm `REPO_ROOT` points to the recorded originating checkout while `WORKTREE_PATH`/child gate and child inventory identify the execution worktree.
- [ ] Review warning output for tracked base changes, child leftovers, and untracked auxiliary docs; encoded warnings preserve evidence, state no disposition, and do not modify the fixture.
- [ ] Review output for a multi-`.projex` fixture and confirm every related document includes location, classification, and status value.
- [ ] Generate a report, advance a ref or change registration, and confirm `STALE`/non-zero forces rerun; no consumer treats a prior result as authorization.

### Acceptance Criteria Validation

| Criterion | How to Verify | Expected Result |
| ----------- | --------------- | ----------------- |
| Context/path resolution | Explicit/inferred, malformed/duplicate, symlink/relative/reused-path fixtures | Stable encoded fields; errors non-zero; no `main` fallback; exact registration identity |
| Protocol/snapshot | Parser, unusual values, ref/worktree drift fixtures | Schema v1 decodes deterministically; `STALE` forces rerun; no raw value spoofs a record |
| Close evidence report | Fixture with commits, diff, stash, child/root related docs | Commit list, stat, stash, complete classified/location-aware inventory are present |
| § 7 gates | Clean, dirty-origin, dirty-child, checkout-mode fixtures | PASS/WARN/N/A and advisory RESULT match bars; no mutation |
| Scale/security | 100-folder/1,000-candidate and output-budget/allowlist fixtures | Complete-or-fail output; no silent truncation or mutating/unsafe command path |
| Cross-platform parity | Independent `.sh` and `.ps1` suites + runtime evidence | Same decoded fields, records, classifications, and exit semantics; `NOT RUN` is not PASS |
| Discoverability | Runner and documentation read-back | Both aggregators run suite exactly once; README/SKILL describe A1 accurately |

## Rollback Plan

Per-step rollback is specified above. If the implementation must be abandoned:

1. Remove the two new scripts and two new test suites.
2. Remove their explicit entries from both test runners and the documentation additions from `tests/README.md`, `README.md`, and `SKILL.md`.
3. Confirm `git status` shows no tracked changes from this plan and that no existing finalizer/workflow file was modified.

No close/finalizer command, branch deletion, reset, stash operation, or other destructive recovery is part of this rollback.

## Revision Log

- **2026-08-08:** Tightened A1 with a versioned escaped record protocol, snapshot identity/drift handling, canonical path/worktree validation, recorded child-root inventory, read-only command/argument rules, scale and runner fail-closed requirements, explicit PowerShell evidence gating, and a schema-adoption gate — trigger: validated stress findings 1–8 and red-team findings 1–11 in `2608082031-close-precheck-script-plan-stress.md` and `2608082042-close-precheck-script-plan-redteam.md`. Scope guard: qualifies as Revise — existing Ready Plan, concrete findings, and report-only A1 direction/boundary still hold; no re-author escalation.

## Notes

### Risks

- **Log-format drift:** Missing or changed headers could produce false context. Mitigation: strict required-header failures, explicit tests, and no guessed base branch.
- **Worktree path ambiguity/reuse:** Relative, symlinked, or reused child paths can redirect discovery. Mitigation: canonical containment, relative-to-recorded-root rule, exact registered path/branch/HEAD, and path fixtures.
- **Inventory false negatives/lifecycle ambiguity:** Auxiliary docs can live under multiple `.projex` roots, child worktrees, or remain untracked. Mitigation: scan originating plus recorded child roots, encode location/class/status, retain child-only records, and leave disposition to close.
- **Output/protocol drift:** Independent implementations can diverge or untrusted values can spoof raw records. Mitigation: schema v1, percent encoding, parser fixtures, duplicate rejection, and decoded parity tests.
- **Snapshot drift:** Refs or registration can change during/after reporting. Mitigation: start/end identity check, `STALE` non-zero result, and consumer-side compare/rerun rule; report remains advisory.
- **Scale/output pressure:** Large multi-folder repos can exceed practical output limits. Mitigation: batched discovery, explicit budget, complete-or-fail output, and generated scale fixture; never silently truncate.
- **Warnings mistaken for enforcement:** `RESULT=PASS_WITH_WARNINGS` is not approval and cannot close a dirty checkout. Mitigation: document finalizer scripts as independent enforcement backstop; precheck only reports.

### Resolved Decisions

- Base branch source: execution log's `> **Base Branch:**`, required and validated as a local branch; never inferred from `main`.
- Plan source: explicit argument preferred; no-argument branch inference allowed only for one unique matching plan.
- Inventory both-ref paths: `tracked-on-ephemeral` wins, with `also-on-base` annotation; base-only is `tracked-on-base`; neither is `untracked`. Scan originating and recorded child `.projex` roots; child-only records are factual and never authorize deletion.
- Output contract: schema v1, fixed record types/field order, UTF-8 percent-encoded values, explicit `NONE`, `ERROR`, and terminal `RESULT`; `PASS`/`PASS_WITH_WARNINGS` are advisory. Framework utility maintainer owns compatibility; A2/A4 cannot adopt pre-gate output.
- Snapshot contract: emit ref/worktree identity and UTC generation time; ref/registration drift during a run yields `STALE`/non-zero, and later consumers rerun on mismatch.
- Path/security contract: canonical containment, relative child paths resolve from recorded repo root, exact worktree registration is required, conflicting duplicate headers fail, and only the documented Git read allowlist is permitted.
- Warning exit policy: valid stable context with warnings exits zero and says `RESULT=PASS_WITH_WARNINGS`; missing/ambiguous/unsupported context or drift exits non-zero.
- Platform/scale policy: PowerShell `NOT RUN` cannot satisfy parity; runner omission/missing summaries fail closed; output is complete-or-fail within the fixed 8 MiB budget.
- Scope: plan/close lifecycle only; no `debug-projex` generalization and no A2–A4 workflow edits.

### Open Questions

None.

## Split Decision

**No split — single repo-root scope, four tightly coupled steps, within size budget.**

## Finalization Checklist

- [x] All implementation steps name exact files, behavior, verification, and recovery.
- [x] Success criteria are observable and testable.
- [x] Scope excludes close workflow/finalizer changes and later modernization axes.
- [x] No open questions remain.
- [x] Must-fix stress/red-team findings are converted into A1 requirements without changing the report-only boundary.
- [x] Worktree mode recorded `Yes` because the base working tree is dirty.
- [x] Auxiliary plan only; no execution or close initiated.
