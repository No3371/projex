# Parent Lineage and Projex Tree Addition

> **Status:** In Progress
> **Author:** OpenAI Codex (Agent)
> **Parent:** 2608120933-parent-lineage-header-and-projex-tree-utility-proposal.md
> **Source:** Direct revision request after abandoned execution of 2608121022-parent-lineage-and-projex-tree-redesign-plan.md
> **Related Projex:** 2608120933-parent-lineage-header-and-projex-tree-utility-proposal.md | 2608121022-parent-lineage-and-projex-tree-redesign-plan.md | 2608121805-parent-lineage-and-projex-tree-addition-plan-redteam.md
> **Worktree:** Yes

---

## Summary

Add one causal `Parent` header to newly created projex documents and paired `projex-tree` readers that print the complete currently discoverable lineage tree containing any queried document. Carry causal origin explicitly through orchestration, enforce new-document correctness in the scaffold and every creator, and make close/conclude consume the tree as bounded lifecycle inventory. Keep `SKILL.md` guidance to one Authoring invariant. Existing documents without Parent remain valid legacy documents and act as lineage roots when reached.

**Scope:** Explicit Parent-origin handoff, creator guardrails/cutover, paired target-component tree readers, close/conclude read integration, shared cross-platform contract fixtures, compact utility docs.
**Estimated Changes:** 2 scaffold scripts, 2 new tree utilities, orchestration handoff, all current creator specs, close/conclude consumer steps, 4 new focused suites, shared fixtures/goldens, compact edits to `SKILL.md` and utility inventories. Three steps.

---

## Objective

### Problem / Gap / Need

Projex documents expose topical relationships but no universal causal edge. Full lineage-tree discovery therefore depends on manual interpretation. The previous Plan turned this addition into a framework redesign: versioned metadata, governed/ungoverned classes, trusted-root registries, correction ledgers, orchestration records, status changes, retention gates, and a large new `SKILL.md` chapter. Those mechanisms exceed the requested feature and duplicate what creation-time guardrails can enforce.

### Success Criteria

- [ ] Newly scaffolded documents require exactly one `> **Parent:** User|Orchestrator|{projex-filename}.md` header and reject a discovered repo-wide filename collision before creation
- [ ] Orchestrated creation receives explicit Parent origin; each workflow selects Parent by declared causal-role precedence, never hidden context or input order
- [ ] Every current scaffold caller and manual writer—including `sprint-projex.md`—emits one deterministic Parent; an asserted creator inventory prevents omissions
- [ ] Existing documents without Parent remain readable and act as roots for explicit descendants
- [ ] `projex-tree.{sh,ps1} <repo-root> <filename>` find the queried document's topmost currently discoverable root and print that complete deterministic component regardless of whether input names its root, intermediate node, or leaf
- [ ] Target-affecting duplicate identities, malformed/duplicate Parent headers, cycles, ambiguous targets, and dangling filename parents emit no stdout, sorted coded stderr, and the specified nonzero exit class; unrelated-component defects do not fail a valid query
- [ ] Shell and PowerShell scaffold/tree suites consume the same creator matrix and tree transcript goldens; parity is observable, not inferred from separate green summaries
- [ ] `close-projex.md` executes `projex-tree` for its plan and `conclude-projex.md` executes it for the successor/sources during context gathering; both state that the result is advisory and not guaranteed exhaustive
- [ ] `SKILL.md` gains only a compact Authoring invariant; enforcement details live in scripts and tests

### Out of Scope

- Framework redesign or new projex type
- Metadata versions or governed/ungoverned document classes
- Migration/backfill of existing projex files
- Broad lifecycle/retention gates beyond the bounded close/conclude read integration, durable historical lineage, or orchestration run documents
- Backward-compatibility shims for the old `new-projex` CLI
- JSON/DOT output, mutable child registries, separate ancestor-only output, arbitrary `Related Projex` traversal, or an implicit corpus-check mode

---

## Context

### Current State

- `SKILL.md § Authoring` defines filename-only references but no universal Parent invariant.
- `new-projex.sh` and `new-projex.ps1` accept `<repo-root> <type> <title> [<projex-dir>]` and emit Status, Author, and Related Projex.
- Standard authoring workflows use `new-projex`; `execute-projex.md`, `close-projex.md`, and `debug-projex.md` contain manual document templates; `sprint-projex.md` directly writes a sprint document.
- Current orchestration handoffs carry prompt, artifacts, facts, depth, and model, but no causal Parent origin.
- Close currently discovers touched documents from plan metadata/reverse references; conclude derives sources from successor references or an explicit literal list. Neither consumes a causal tree.
- The source proposal defines the useful contract: one causal Parent distinct from topical relationships and a read-only lineage tree.
- The abandoned Plan added unrelated governance systems to protect that one field. User direction rejects those systems and requires guardrails over repetitive guidance.

### Key Files

| File(s) | Role | Change Summary |
|---|---|---|
| `SKILL.md` | Framework authoring contract | Add one concise Parent invariant under Authoring |
| `new-projex.sh`, `new-projex.ps1` | Common creator guardrail | Require/validate/emit Parent; reject existing repo-wide filename collisions |
| `orchestrate-projex.md` | Causal-origin boundary | Add explicit Parent handoff datum |
| Scaffold-using `*-projex.md` specs | Creator callers | Set one local Parent by declared causal-role precedence and pass it |
| `execute-projex.md`, `close-projex.md`, `debug-projex.md`, `sprint-projex.md` | Direct document writers | Add deterministic Parent to every manual template |
| `projex-tree.sh`, `projex-tree.ps1` | New read-only addition | Print one complete current-corpus component with an exact failure API |
| `close-projex.md`, `conclude-projex.md` | Planned tree consumers | Use successful current-corpus trees as pre-mutation inventory without replacing lifecycle judgment |
| `tests/new-projex.test.{sh,ps1}` (new) | Scaffold/creator contract | Required argument, grammar, collision, header, closed creator inventory |
| `tests/projex-tree.test.{sh,ps1}` (new) | Tree contract | Shared component, corruption, stream, exit, and parity contract |
| `tests/fixtures/projex-creators.txt`, `tests/fixtures/new-projex-cases.tsv`, `tests/fixtures/projex-tree/` (new) | Shared oracle | One creator inventory and platform-neutral inputs/golden transcripts |
| `README.md`, `AGENTS.md`, `CLAUDE.md`, `tests/README.md`, runners | Inventories | Compact utility/test registration only where an inventory exists |

### Dependencies

- **Requires:** Filename-only projex identity and current `.projex` discovery conventions.
- **Blocks:** Reliable full-tree lookup by causal lineage.

### Constraints

- Parent is causal only; `Related Projex`, Source, Nav, and similar fields retain current meanings.
- Missing Parent means legacy document, not invalid document. It terminates upward traversal and becomes the root; children with explicit Parent edges still attach to it.
- New creation has no old-arity fallback. Shipped callers cut over atomically.
- Orchestrated handoffs always carry Parent; direct invocations without a causal document resolve to `User`. No workflow infers `User` vs `Orchestrator` from conversation state.
- Multi-source workflows declare one primary causal role by semantics; argument order never decides Parent. If no source is causally primary, use actor origin and retain every source in existing relationship fields.
- Repo-scoped discovery excludes `.git`, `.projexwt`, and nested repositories using existing repo-boundary conventions; no registration system.
- Lookup validates only the queried current-corpus component. Any nonzero result owns stderr only; stdout is empty.
- Shell and PowerShell behavior must match one shared fixture/golden corpus.
- Close/conclude execute the tree utility to gain lineage context. Its result is advisory and not guaranteed exhaustive; existing workflow judgment remains authoritative.
- Worktree mode: Yes because the base checkout is dirty.

### Assumptions

- Full-tree lookup follows explicit Parent edges upward to `User`, `Orchestrator`, or a legacy document without Parent, then prints every currently discoverable descendant from that resolved file root.
- Current filename convention provides sufficient identity. Duplicate discovery is an error when it makes the target component ambiguous; no new identity layer.
- Archive or conclude may remove a Parent-bearing file. The reader promises current-corpus completeness, reports an affected dangling edge, and does not claim durable history.

### Impact Analysis

- **Direct:** Future document creation, orchestration Parent handoff, Parent-based current-corpus queries, and richer close/conclude context.
- **Adjacent:** Every scaffold caller, manual document template, lifecycle document sweep, and focused runner.
- **Downstream:** Existing documents remain untouched; new descendants can name them as Parent. Close/conclude gain lineage context without retention redesign.

---

## Implementation

### Overview

Make causal origin explicit and invalid new documents hard to create, then add the reader with one target-component failure API. Prose states the invariant once; scripts encode grammar and behavior; shared fixtures carry edge-case and parity detail.

### Step 1: Parent Creation Guardrail

**Objective:** Guarantee one valid Parent on every newly created projex document.
**Confidence:** High
**Depends on:** None
**Verify-Projex:** Encouraged

**Files:**
- `SKILL.md`
- `new-projex.sh`
- `new-projex.ps1`
- `orchestrate-projex.md`
- Scaffold callers: `archive-projex.md`, `audit-projex.md`, `coach-projex.md`, `conclude-projex.md`, `define-projex.md`, `eval-projex.md`, `explore-projex.md`, `guide-projex.md`, `imagine-projex.md`, `interview-projex.md`, `memo-projex.md`, `navigate-projex.md`, `patch-projex.md`, `plan-projex.md`, `preplan-projex.md`, `propose-projex.md`, `redteam-projex.md`, `review-projex.md`, `scan-projex.md`, `stress-projex.md`
- Manual writers: `execute-projex.md`, `close-projex.md`, `debug-projex.md`, `sprint-projex.md`
- `tests/new-projex.test.sh` (new)
- `tests/new-projex.test.ps1` (new)
- `tests/fixtures/projex-creators.txt` (new)
- `tests/fixtures/new-projex-cases.tsv` (new)

**Changes:**

1. Change both scaffold signatures to:

```text
new-projex.{sh|ps1} <repo-root> <type> <title> <parent> [<projex-dir>]
```

2. Validate Parent before file creation:
   - accept exact `User` or `Orchestrator`;
   - otherwise require a projex filename basename matching `{yymmddhhmm}-{name}-{type}.md`;
   - reject paths, empty values, a Parent equal to the generated filename, and extra/missing operands;
   - scan repo-scoped `.projex` identities before writing and reject an already-discovered generated filename in any scope/lifecycle folder;
   - emit exactly one `> **Parent:**` beside existing common metadata; create no file after validation failure.
3. Add one required `Parent` datum to every `orchestrate-projex.md` subagent handoff. Orchestrator supplies the immediate causal artifact filename when one exists, otherwise exact `Orchestrator`; nested and follow-up dispatches recompute it from their immediate cause rather than inheriting stale ancestry.
4. Require each scaffold-using workflow to assign one local `{parent}` by this precedence: workflow-defined explicit causal subject/nav/source role → supplied orchestrator Parent → `User` for direct source-less invocation. Each multi-source workflow names its primary causal role; never choose the first argument generically. Pass `{parent}` to the new scaffold operand.
5. Add Parent to all manual writers:
   - execution log → source plan;
   - walkthrough → source plan;
   - final debug document → debug log;
   - debug log and sprint document → explicit causal nav/subject when defined, else supplied orchestrator Parent, else direct `User`.
6. Preserve scaffold-generated Parent when filling full templates. Do not add per-workflow Parent essays; one local assignment or template field is enough.
7. Add one `SKILL.md § Authoring` bullet: every new projex has exactly one causal Parent using the grammar above; legacy files may omit it. Point to `new-projex` as enforcement rather than restating cases.
8. Add `tests/fixtures/projex-creators.txt` as the exact creator inventory above. Both new scaffold suites discover `new-projex` calls and direct `.projex` document templates in workflow specs, compare that set to the fixture, reject old arity, and require one Parent assignment/template field per classified creator.
9. Make both scaffold suites consume `tests/fixtures/new-projex-cases.tsv`: sentinels/filenames, missing/invalid/path/self values, extra operands, exact single-header emission, no file on failure, cross-scope collision, direct/orchestrated/nested/follow-up/multi-source Parent selection. A concurrent scan/create collision remains a documented residual race; no reservation registry.

**Rationale:** Creation is the cheapest and strongest enforcement point. A required scaffold operand plus tests prevents omission without a new metadata framework or repeated prose.

**Verification:** Run both new scaffold suites; require identical shared-matrix case counts, zero unclassified creators, no old-arity invocation, exact one Parent per manual template, and cross-scope collision rejection.

**If this fails:** Revert scaffold scripts, orchestration datum, callers/templates, creator fixtures/tests, and the single SKILL bullet together; partial origin/CLI cutover is invalid.

---

### Step 2: Paired Projex Tree Utility

**Objective:** Print the complete deterministic lineage tree containing any queried document without redefining existing documents.
**Confidence:** Medium
**Depends on:** Step 1
**Verify-Projex:** Encouraged

**Files:**
- `projex-tree.sh` (new)
- `projex-tree.ps1` (new)
- `tests/projex-tree.test.sh` (new)
- `tests/projex-tree.test.ps1` (new)
- `tests/fixtures/projex-tree/` (new)

**Changes:**

1. Implement one CLI:

```text
projex-tree.{sh|ps1} <repo-root> <filename>
```

Expected successful stdout is the complete tree containing the requested filename. These invocations:

```text
projex-tree.sh <repo-root> 2608051553-feature-proposal.md
projex-tree.sh <repo-root> 2608052327-feature-plan.md
projex-tree.sh <repo-root> 2608052327-feature-log.md
```

all produce:

```text
2608051553-feature-proposal.md
└── 2608052327-feature-plan.md
    ├── 2608052327-feature-log.md
    ├── 2608052346-feature-plan-redteam.md
    └── 2608112108-feature-walkthrough.md
```

The utility first follows Parent upward from the queried document to the topmost file root, then prints every descendant from that root. A red team of the plan is the plan's child. The root filename is the unprefixed first line. Each descendant occupies one line; `├──` marks a non-final sibling, `└──` the final sibling, `│   ` continues an open ancestor branch, and four spaces continue beneath a final branch. Lines contain filenames only. Successful traversal writes the full tree to stdout; diagnostics use stderr.

2. Validate repo root and require a filename basename, never a path.
3. Discover Markdown documents under repo-scoped `.projex` folders and lifecycle subfolders while excluding `.git`, `.projexwt`, and nested repositories. Normalize diagnostic paths to repo-relative `/`.
4. Index filenames and every Parent-shaped line in each document's initial blockquote metadata. A file without Parent is legacy: keep its identity, assign no outgoing edge, emit no compatibility error. Body examples are ignored.
5. Resolve the requested filename uniquely, then define the target component as: its valid upward chain; the resolved file root; every recursive document with a valid Parent filename naming a reached member; and any duplicate/header defect whose candidate edge or identity names a reached member. Unrelated-component defects neither fail nor diagnose this query.
6. Build Parent → bytewise filename-sorted children within that component. `User` and `Orchestrator` terminate ascent as external sentinels; output starts at the highest file node.
7. Successful lookup: exit `0`, exact full tree on stdout, empty stderr.
8. Failed lookup: empty stdout; stderr lines use `projex-tree: <CODE>: <normalized locator>: <detail>` and sort bytewise by code, locator, detail. Exit classes:
   - `2`, invocation/target: `E_USAGE`, `E_REPO`, `E_TARGET_NAME`, `E_TARGET_NOT_FOUND`, `E_TARGET_AMBIGUOUS`;
   - `3`, target-component structure: `E_IDENTITY_DUPLICATE`, `E_PARENT_MALFORMED`, `E_PARENT_DUPLICATE`, `E_PARENT_SELF`, `E_PARENT_DANGLING`, `E_CYCLE`;
   - `4`, discovery/read failure: `E_IO`.
9. No partial tree is safe or emitted. No implicit global integrity sweep or corpus-check mode.
10. Both suites consume identical case directories under `tests/fixtures/projex-tree/`; each case contains corpus inputs plus exact `expected.stdout`, `expected.stderr`, and `expected.exit`. Cover root/intermediate/leaf equality; legacy/all-new roots; body example; CRLF/BOM; unrelated malformed/duplicate/cycle defects; target ambiguity/up-chain corruption; connected descendant duplicate/header corruption; dangling edge; self-parent; cycle; I/O/usage classes. Each platform compares byte-normalized output to the same goldens.

**Rationale:** Upward Parent traversal identifies one current containing component; downward traversal prints it completely. Component-scoped validation prevents unrelated Markdown from denying lookup, while empty stdout on failure prevents incomplete data consumption.

**Verification:** Run both tree suites against the shared golden corpus and one throwaway-repo smoke: root/intermediate/leaf queries match byte-for-byte; unrelated corruption leaves that transcript unchanged; target corruption yields empty stdout and exact coded stderr/exit.

**If this fails:** Remove both utilities, suites, and shared tree fixtures; creation-time Parent remains independently useful.

---

### Step 3: Inventory and Integration

**Objective:** Expose the addition, keep focused checks in normal test runs, and wire close/conclude as bounded tree consumers.
**Confidence:** High
**Depends on:** Steps 1–2
**Do-Projex:** Encouraged

**Files:**
- `README.md`
- `AGENTS.md`
- `CLAUDE.md`
- `tests/run-all.sh`
- `tests/run-all.ps1`
- `tests/README.md`
- `close-projex.md`
- `conclude-projex.md`

**Changes:**

1. Add `projex-tree` and the new `new-projex` signature to existing utility inventories only.
2. Add one filename-only Parent note where repository trees/authoring conventions are already summarized. Do not create a new guidance section.
3. In `close-projex.md`, execute `projex-tree.{sh|ps1} <repo-root> <plan-filename>` during context gathering, before document mutation. State only that its result is advisory and not guaranteed exhaustive; use it as additional context alongside the workflow's existing evidence.
4. In `conclude-projex.md § Identify Successor and Sources`, execute `projex-tree.{sh|ps1}` for the successor and selected sources. State only that its result is advisory and not guaranteed exhaustive; use it as additional context during the existing source, residue, and impact analysis.
5. Register exact new suite names in both runners. Update `tests/README.md` with actual assertion/case counts after execution and state that both platforms consume the same fixtures/goldens.
6. Leave docs without a relevant utility, authoring inventory, or named consumer role unchanged.
7. Run shell syntax checks, PowerShell AST parsing, the four focused suites, the Step 2 end-to-end smoke, and throwaway close/conclude inventory scenarios.

**Rationale:** Inventory edits expose the addition; tests—not prose—guard edge cases and parity. Close/conclude gain lineage context by executing the tool; their workflow judgment remains unchanged.

**Verification:** Focused suites/shared-golden smoke pass; runner inventories include exact suite names; inventory references match actual CLI. Inspect close/conclude specs for the tree invocation and advisory/non-exhaustive qualifier. No new metadata/governance terminology appears.

**If this fails:** Revert close/conclude consumer edits and inventory/runner edits; direct scaffold/tree suites remain independently valid.

---

## Verification Plan

### Automated Checks

- [ ] New paired scaffold suites consume one matrix, report matching case counts, and classify every current creator
- [ ] New paired tree suites consume one golden corpus and match exact stdout/stderr/exit transcripts
- [ ] Shell syntax succeeds for changed/new `.sh` scripts
- [ ] PowerShell AST parsing reports no errors for changed/new `.ps1` scripts
- [ ] Shipped `new-projex` call inventory contains no old-arity invocation
- [ ] Manual creator inventory contains exactly one Parent field per new document template, including sprint
- [ ] Cross-scope scaffold collision fixture rejects without creating a file
- [ ] Close/conclude specs invoke the host-matched tree utility during context gathering and label its result advisory/non-exhaustive

### Manual Verification

- [ ] Query the same tree by its root, an intermediate node, and a leaf; all three print the identical complete current-corpus tree
- [ ] Query an old document without Parent; it acts as root and shows explicit new children
- [ ] Put a Parent-shaped example in the body; utility ignores it
- [ ] Put malformed data in an unrelated component; valid target transcript remains successful and unchanged
- [ ] Introduce target ambiguity, dangling/header/self/cycle corruption; each emits empty stdout, sorted coded stderr, and its specified exit class
- [ ] Exercise direct, orchestrated, nested, follow-up, and multi-source creation; emitted Parent follows declared causal-role precedence
- [ ] Inspect `SKILL.md`: Parent addition is one compact Authoring rule, not a chapter
- [ ] Exercise close on a plan tree and confirm the agent receives tree context before applying existing close judgment
- [ ] Exercise conclude with successor/source trees and confirm the agent receives tree context before existing source/residue analysis
- [ ] Confirm both workflow specs state that tree context is advisory and not guaranteed exhaustive

### Acceptance Criteria Validation

| Criterion | How to Verify | Expected Result |
|---|---|---|
| New Parent enforced | Shared scaffold invalid/valid/collision matrix | Invalid creates nothing; valid emits one exact header; existing repo-wide identity blocks create |
| Causal Parent selected | Invocation-mode and multi-source fixtures | Explicit causal role wins; supplied orchestrator origin next; direct source-less uses `User`; input order has no effect |
| Creator cutover complete | Fixture-vs-discovery inventory check | Every scaffold caller/manual writer classified; sprint included; no old arity or missing template field |
| Legacy documents tolerated | Legacy-root fixture | Missing Parent terminates ascent; root and explicit descendants print |
| Complete current component | Query root/intermediate/leaf in golden fixture | All inputs print same stable filename-sorted tree |
| Failure API safe | Target/unrelated error goldens | Target failure: empty stdout + exact sorted code/exit; unrelated defects do not poison query |
| Guardrail-first docs | SKILL/workflow inspection | One invariant plus operand/template changes; no repeated guidance |
| Cross-platform parity | Both suites consume same fixture files | Shell and PowerShell match the same stdout/stderr/exit oracle |
| Close/conclude integration | Workflow inspection + throwaway invocation | Both execute tree during context gathering and label the result advisory/non-exhaustive |

---

## Rollback Plan

1. Revert close/conclude consumer edits and inventory docs/runners.
2. Remove paired tree utilities/tests/shared goldens.
3. Revert scaffold signature, collision scan, orchestration Parent datum, callers/templates, creator fixtures/tests, and SKILL bullet as one unit.
4. Existing documents require no restoration because this Plan performs no migration.

---

## Revision Log

- **2026-08-12:** Re-authored as a minimal addition after the prior execution was abandoned. Removed redesign framing, legacy governance, metadata versioning, root/correction registries, orchestration records, status changes, and prose-heavy enforcement — trigger: human requirement, “It's not a redesign, the projex tree is an addition”; “Don't consider backward compatibility”; “Don't write guidance just to stress something that can be achieved with guardrails.”
- **2026-08-12:** Added the exact successful `projex-tree` stdout shape and tree-glyph/stream rules — trigger: human requirement, “add the expected projex-tree output shape.”
- **2026-08-12:** Corrected plan-redteam parentage and specified query-root behavior with proposal, plan, and leaf outputs — trigger: human correction that a plan red team cannot be a proposal child and question whether different targets print the same tree.
- **2026-08-12:** Changed target behavior from requested subtree to the complete containing tree: follow Parent upward to the topmost file root, then print all descendants; root, intermediate, and leaf inputs now have identical output — trigger: human requirement, “I want full tree regardless where it's in the tree.”
- **2026-08-12:** Resolved the plan red team's must-fix contract gaps: explicit orchestration Parent origin and semantic precedence; complete creator inventory including sprint; new scaffold suites; target-component failure API with empty failure stdout/coded exits; shared cross-platform fixtures; current-corpus wording; pre-create cross-scope collision rejection — trigger: 2608121805-parent-lineage-and-projex-tree-addition-plan-redteam.md § Bottom Line, § Critical Findings, § Remediation (re-verified against current workflow specs, scaffold scripts, and test inventory).
- **2026-08-12:** Added `close-projex.md` and `conclude-projex.md` as bounded `projex-tree` consumers: pre-mutation lineage inventory and no replacement of existing close/residue/confirmation authority. Initial fail-closed consumer behavior was superseded by the next revision — trigger: human requirement, “oh include this in the revise: close-projex and conclude-projex should make use of the projex tree script”.
- **2026-08-12:** Made close/conclude tree consumption explicitly advisory and non-exhaustive; successful output only adds candidates, absence proves nothing, and tree failure warns without bypassing or blocking existing discovery and lifecycle gates — trigger: human requirement, “close-projex and conclude-projex should claim that the tree is advisory and is not guaranteed to be exhaustive.”
- **2026-08-12:** Reduced close/conclude integration to the tool invocation plus one advisory/non-exhaustive qualifier; removed prescribed candidate unions, failure branches, and duplicated lifecycle rules because agents execute the tool to gain context and retain their workflow judgment — trigger: human requirement, “The script is a tool; by executing it the agents gain better context.”

---

## Notes

### Split Decision

**No split — single framework scope, three coupled steps.** Scaffold establishes edges consumed by the paired reader; integration exposes/tests the addition and reuses the reader in close/conclude without new lifecycle machinery.

### Risks

- **Shell/PowerShell drift:** both implementations consume identical input fixtures and exact transcript goldens.
- **False causal sentinel:** orchestration handoff carries Parent; workflows apply declared causal-role precedence, never hidden context or argument order.
- **Legacy ambiguity:** missing Parent terminates upward traversal and defines the file root; never fabricate ancestry. Incoming explicit children still work.
- **Body false positives:** parse only initial metadata block.
- **Connected corruption/denial:** only target-component defects fail; failure stdout is empty and diagnostics identify normalized locators.
- **Broad caller cutover:** asserted creator inventory catches old scaffold arity and missing manual Parent, including sprint; no compatibility shim.
- **Lifecycle decay:** output is explicitly current-corpus only; archive/conclude removal can later expose a dangling edge.
- **Lifecycle overreach:** close/conclude label tree context advisory/non-exhaustive; existing workflow judgment remains authoritative.
- **Concurrent identity race:** scaffold rejects already-discovered collisions, but concurrent cross-scope scan/create remains; monitor before adding reservation machinery.

### Open Questions

None.
