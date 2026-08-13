# Walkthrough: Parent Lineage and Projex Tree Addition

> **Status:** Complete (Success)
> **Execution Date:** 2026-08-12—2026-08-13
> **Completed By:** OpenAI Codex agents
> **Source Plan:** 2608121756-parent-lineage-and-projex-tree-addition-plan.md
> **Log:** 2608121844-parent-lineage-and-projex-tree-addition-log.md
> **Parent:** 2608121756-parent-lineage-and-projex-tree-addition-plan.md
> **Result:** Success

## Summary

Added mandatory causal `Parent` metadata for new projex documents, deterministic current-corpus lineage-tree utilities, shared shell/PowerShell contract tests, and advisory lineage context in close/conclude. Audit findings corrected incomplete creator cutover and unsafe tree failures; focused shared-fixture suites pass on both hosts.

## Objectives Completion

| Objective | Status | Evidence |
|---|---|---|
| Parent creation guardrail | Complete | Required scaffold Parent operand; 20 caller/manual-writer cutover; shared creator matrix. |
| Paired lineage tree | Complete | Shared Python engine with shell/PowerShell wrappers; deterministic golden corpus and failure API. |
| Inventory and lifecycle integration | Complete | Utility/test inventories, runners, and advisory close/conclude invocation. |

## Execution Detail

### Step 1: Parent Creation Guardrail

**Planned:** Require one valid Parent at creation; pass deterministic causal origin from every creator.

**Actual:** `new-projex.sh` and `new-projex.ps1` require and validate Parent, reject repo-wide filename collisions before writes, and emit one header. `SKILL.md`, orchestration handoff, 20 scaffold callers, and execute/close/debug/sprint manual writers were cut over. Shared creator inventory/matrix and paired suites enforce the cutover.

**Deviation:** None. The later audit found `conclude-projex.md` and the walkthrough template omitted Parent; remediation corrected both.

**Verification:** Shell and PowerShell `new-projex` suites: `PASS=46 FAIL=0 CASES=46` each.

### Step 2: Paired Projex Tree Utility

**Planned:** Add shell/PowerShell readers that print one deterministic component for root, intermediate, or leaf input; fail safely for target-component corruption.

**Actual:** Added `.projex-tree.py`, `projex-tree.sh`, and `projex-tree.ps1`; basic corpus/goldens cover shared full-tree output, legacy roots, malformed unrelated components, and targeted failures. Audit remediation added reachable duplicate-Parent and invalid-UTF-8 goldens; the engine now returns empty stdout with normalized `E_PARENT_DUPLICATE`/exit 3 or `E_IO`/exit 4 instead of partial output or a traceback.

**Deviation:** The paired entry points share one Python engine rather than duplicating parsing/traversal logic; public inventories now state the Python 3 dependency.

**Verification:** Shell and PowerShell `projex-tree` suites: `PASS=46 FAIL=0 CASES=46` each. Close context invocation produced the complete plan component:

```text
2608120933-parent-lineage-header-and-projex-tree-utility-proposal.md
├── 2608121022-parent-lineage-and-projex-tree-redesign-plan.md
└── 2608121756-parent-lineage-and-projex-tree-addition-plan.md
    ├── 2608121844-parent-lineage-and-projex-tree-addition-log.md
    └── 2608121912-parent-lineage-and-projex-tree-addition-audit.md
        └── 2608121919-parent-lineage-audit-remediation-patch.md
```

Tree output was advisory, current-corpus context only; lifecycle judgment remained independent.

### Step 3: Inventory and Integration

**Planned:** Register utilities and suites; make close/conclude advisory tree consumers.

**Actual:** `README.md`, `AGENTS.md`, `tests/README.md`, and both runners register the utilities and exact focused suites. `close-projex.md` and `conclude-projex.md` invoke the host-matched tree utility during context gathering and state its output is advisory and not guaranteed exhaustive.

**Deviation:** Existing aggregate runners remain environment-limited by pre-existing executable-permission and unrelated close-precheck failures (exit 126); focused changed-contract suites are the verified evidence.

**Verification:** Runner and workflow inspection; four focused suites pass as recorded below.

## Complete Change Log

**Derived from:** `git diff --stat main..HEAD`: 59 files, 25 created, 34 modified, 983 insertions, 117 deletions. No files deleted.

### Created

| Files | Purpose |
|---|---|
| `.projex-tree.py`; `projex-tree.sh`; `projex-tree.ps1` | Shared lineage traversal engine and public host wrappers. |
| `.projex/2608121844-parent-lineage-and-projex-tree-addition-log.md` | Execution record and remediation evidence. |
| `.projex/closed/2608121919-parent-lineage-audit-remediation-patch.md` | Closed remediation patch record. |
| `tests/new-projex.test.sh`; `tests/new-projex.test.ps1`; `tests/projex-tree.test.sh`; `tests/projex-tree.test.ps1` | Paired focused contract suites. |
| `tests/fixtures/projex-creators.txt`; `tests/fixtures/new-projex-cases.tsv` | Shared creator inventory and scaffold matrix. |
| `tests/fixtures/projex-tree/basic/` (five `.projex` inputs, `unrelated-malformed.md`, `expected.exit`, `expected.stderr`, `expected.stdout`) | Shared valid/component-isolation tree corpus. |
| `tests/fixtures/projex-tree/duplicate-parent/` (`input.md`, `expected.exit`, `expected.stderr`); `tests/fixtures/projex-tree/invalid-utf8/` (`expected.exit`, `expected.stderr`) | Shared regression fixtures for audit findings. |

### Modified

| Files | Actual change |
|---|---|
| `new-projex.sh`; `new-projex.ps1`; `SKILL.md` | Parent operand/validation/header and compact invariant. |
| `orchestrate-projex.md`; `archive-projex.md`; `audit-projex.md`; `coach-projex.md`; `conclude-projex.md`; `define-projex.md`; `eval-projex.md`; `explore-projex.md`; `guide-projex.md`; `imagine-projex.md`; `interview-projex.md`; `memo-projex.md`; `navigate-projex.md`; `patch-projex.md`; `plan-projex.md`; `preplan-projex.md`; `propose-projex.md`; `redteam-projex.md`; `review-projex.md`; `scan-projex.md`; `stress-projex.md` | Explicit causal Parent selection and new scaffold operand. |
| `execute-projex.md`; `close-projex.md`; `debug-projex.md`; `sprint-projex.md` | Deterministic Parent fields in direct-writer templates; close also gathers advisory tree context. |
| `README.md`; `AGENTS.md`; `tests/README.md`; `tests/run-all.sh`; `tests/run-all.ps1` | Utility/runtime and focused-suite inventories. |
| `.projex/2608121756-parent-lineage-and-projex-tree-addition-plan.md` | Marked complete, linked execution log, checked all criteria; close adds completion/walkthrough metadata. |

### Outside the execution diff

`2608121912-parent-lineage-and-projex-tree-addition-audit.md` is an intentional untracked auxiliary audit artifact. It is not committed or lifecycle-moved. Its Significant findings were addressed by `2608121919-parent-lineage-audit-remediation-patch.md`; the artifact is preserved untracked in the base checkout before worktree removal.

### Planned But Not Changed

None. The plan's named implementation files and fixture areas were covered; the audit remediation added targeted regression fixtures and Python-runtime documentation within the same scope.

## Success Criteria Verification

| Criterion | Method | Result | Evidence |
|---|---|---|---|
| New Parent enforced | Shared valid/invalid/collision matrix | Pass | Both scaffold suites: `46/46`. |
| Causal Parent selected | Direct/orchestrated/nested/follow-up/multi-source cases | Pass | Shared creator matrix and paired suites. |
| Creator cutover complete | Fixture-vs-discovery creator inventory | Pass | Audit remediation corrected conclude/walkthrough omissions; suites `46/46`. |
| Legacy docs tolerated | Legacy-root tree fixture | Pass | Shared basic corpus. |
| Complete current component | Root/intermediate/leaf golden queries | Pass | Identical component transcript; close invocation shown above. |
| Safe failure API | Shared target/unrelated defect goldens | Pass | Duplicate Parent and invalid UTF-8 regressions; empty failure stdout contract. |
| Guardrail-first docs | `SKILL.md` and workflow inspection | Pass | One Authoring invariant; operational detail in scripts/tests. |
| Cross-platform parity | Same fixture/golden inputs on both hosts | Pass | Both tree suites `46/46`; both scaffold suites `46/46`. |
| Close/conclude integration | Workflow inspection and close invocation | Pass | Host-matched advisory/non-exhaustive tree context in both workflows. |

**Overall:** 9/9 criteria passed.

## Issues and Deviations

- **Audit remediation:** Audit found two creator omissions, reachable duplicate Parent partial rendering, invalid-UTF-8 traceback, and undocumented Python runtime. Patch `2608121919-parent-lineage-audit-remediation-patch.md` repaired all actionable findings and recorded four passing focused suites.
- **Aggregate runners:** Pre-existing permission/environment failures prevented aggregate proof; focused changed-contract suites provide direct evidence.
- **Close metadata:** The execution log initially recorded the child worktree as `Repo Root`; close corrected it to the recorded originating checkout (`/workspace`) so required close-precheck can identify the base/worktree relationship.

## Key Insights

**Rationale promoted:** none needed.

- Required creator operands plus a tested inventory prevent Parent omissions more reliably than repeated workflow prose.
- A component-scoped tree reader must reject reachable corruption before rendering; partial output is unsafe advisory input.
- One shared parsing engine plus byte-exact cross-host goldens makes parity observable while retaining native entry points.

## Related Projex Updates

| Document | Action |
|---|---|
| `2608121756-parent-lineage-and-projex-tree-addition-plan.md` | Completed, linked log and this walkthrough, then closed. |
| `2608121844-parent-lineage-and-projex-tree-addition-log.md` | Complete and closed with plan. |
| `2608121919-parent-lineage-audit-remediation-patch.md` | Already closed; retained. |
| `2608121912-parent-lineage-and-projex-tree-addition-audit.md` | Intentionally preserved untracked; neither committed nor moved. |
| `2608120933-parent-lineage-header-and-projex-tree-utility-proposal.md` | Parent proposal remains active; not closed by this plan. |
| `2608121022-parent-lineage-and-projex-tree-redesign-plan.md` | Already abandoned; retained in `abandoned/`. |
| `2608121805-parent-lineage-and-projex-tree-addition-plan-redteam.md` | Related plan red team remains active; not resolved/moved by this close. |

## Verification Output

```text
bash tests/new-projex.test.sh                 PASS=46 FAIL=0 CASES=46
bash tests/projex-tree.test.sh                PASS=46 FAIL=0 CASES=46
pwsh -NoProfile -File tests/new-projex.test.ps1 PASS=46 FAIL=0 CASES=46
pwsh -NoProfile -File tests/projex-tree.test.ps1 PASS=46 FAIL=0 CASES=46
```

## References

- `053e064` — Parent creation guardrail
- `18a9776` — deterministic lineage tree utility
- `60da93a` — plan completion and integration
- `3d9beac` — audit remediation
- `3e19ee4` — remediation patch document
