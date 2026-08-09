# Audit: Resumed close-precheck Safety Matrix

> **Status:** Complete (Conditions Accepted; PowerShell Evidence Deferred)
> **Close Disposition:** Human authorized partial-success close with the remaining PowerShell evidence explicitly deferred.
> **Audit Date:** 2026-08-09 | **Auditor:** depth-1 audit delegate
> **Subject:** 2608081953-close-precheck-script-plan.md; resumed Step 3, commits 5e1cd72 and ffe3868
> **Prior Audit:** 2608090614-close-precheck-script-plan-audit.md (stale pre-resume evidence)

---

## Summary

**Verdict:** Accept with Conditions.

Revised Bash matrix is independently reproduced: `bash tests/close-precheck.test.sh` → `PASS=62 FAIL=0`. Commits add Bash/PowerShell matrix source and PowerShell runner registration exists exactly once. Bash source syntax, runtime report, snapshot-drift logic, encoded protocol output, and read-only Git-command review support the claimed available-platform work.

**Assessment:** Completeness: Medium | Correctness: High (Bash) / Unverified (PowerShell) | Quality: Medium | Value: High.

## Claims vs Evidence

| Claim | Evidence | Status | Notes |
| --- | --- | --- | --- |
| Required Bash safety matrix added | `5e1cd72`; `tests/close-precheck.test.sh` | ✓ | Direct suite independently reproduced: `PASS=62 FAIL=0`. |
| Worktree-registration drift fails closed | `5e1cd72`; `close-precheck.sh:486-504` | ✓ | Compares initial/final porcelain registrations; emits encoded warning, `RESULT=STALE`, exit 1. |
| PowerShell matrix parity source added | `ffe3868`; `tests/close-precheck.test.ps1` | ⚠ | Source asserts path, encoding, gates, stash, 1000 inventory records, fixed budget, ref/worktree stale paths, no `eval`; runtime unavailable. |
| PowerShell runner executes suite once | `bdde857`; `tests/run-all.ps1:4,12,41` | ✓ | Suite array has one entry plus exact-once/fail-closed guards. |
| Full available-platform runner passes | `tests/run-all.sh` | ⚠ | Clean-mode independent run: exit 1, `PASS=83 FAIL=56`; new suite ran once and passed `62/0`. Failures are shared `100644` direct-invocation status-126 issue waived by human for this execution. |

## Objective Verification

### Step 3 required matrix

Plan requires failure-path, path/canonicalization, encoded-value, inventory/gate, stale, scale/budget, non-mutation, and cross-platform checks. Bash fixtures now cover documented failures, relative/reused paths, inference ambiguity, unsafe values, `MISSING`, origin/child gates, 100 roots/1000 candidates, controlled budget breach, ref and registration drift, and static read-only guard. Runtime evidence confirms the Bash suite.

PowerShell source contains corresponding assertions but `pwsh` is absent: parser, direct suite, and aggregate are **NOT RUN**, not pass.

### Implementation inspection

`close-precheck.sh` uses report-only Git reads (`show-ref`, `worktree list`, `log`, `diff --stat`, `stash list`, `ls-tree`, `status`, `rev-parse`); no mutating Git command or `eval` found. Direct explicit-plan execution returned schema-v1 encoded context, commits, gates, `RESULT=PASS_WITH_WARNINGS`, exit 0.

The current worktree also contains an uncommitted `close-precheck.sh` delta: 306 additions / 302 deletions. One non-whitespace hunk restructures inventory status `case` formatting; Bash syntax and the 62-assertion suite pass against it. It is not represented by `ffe3868`, so its disposition remains required.

## Findings

### Significant

- **PowerShell runtime parity unverified** — `pwsh` unavailable; parser/direct/aggregate evidence absent. → Run `pwsh -NoProfile -File tests/close-precheck.test.ps1` and `pwsh -NoProfile -File tests/run-all.ps1` on a supported host; retain zero-failure output.
- **Tracked source is dirty** — `close-precheck.sh` differs from `ffe3868`; audit cannot attribute it to a commit. → Owner must restore it or review, test, and commit it explicitly before any later lifecycle decision.

### Accepted execution constraint

- Full Bash aggregate cannot pass in clean tracked mode because existing utilities are `100644` and several legacy tests invoke them directly. Independent clean-mode result is `PASS=83 FAIL=56`, while `close-precheck.test.sh` ran exactly once and passed. Human waived this shared executable-mode blocker for execute → audit → optional patch only; it is not evidence authorizing close/merge.

### Positive

- Prior audit runner defect is fixed.
- No close/finalizer/workflow implementation changed in resumed commits.
- Report remains advisory and snapshot-bound; registration drift now fails closed.

## Final Verdict

**Status:** Accept with Conditions

**Conditions:**

- [ ] Obtain independent PowerShell parser, direct-suite, and aggregate-runner evidence.
- [ ] Resolve the uncommitted `close-precheck.sh` delta by restore or explicit reviewed commit.
- [ ] Do not close or merge under this audit; human authorization permits only optional patch evaluation.

**Sign-off:** No finalization sign-off. Available Bash work is accepted; cross-platform runtime acceptance remains incomplete.
