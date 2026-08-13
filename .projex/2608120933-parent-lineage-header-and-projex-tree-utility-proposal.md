# Parent Lineage Header and Projex Tree Utility

> **Status:** Draft
> **Author:** OpenAI Codex (Agent)
> **Parent:** User
> **Related Projex:** 2604031730-util-script-ideas-imagine.md (`projex-refs` prior art) | 2604031727-workflow-guardrails-determinism-imagine.md (spawn lineage principle) | 2608120952-parent-lineage-header-and-projex-tree-utility-redteam.md (adversarial review) | 2608121003-parent-lineage-header-and-projex-tree-utility-proposal-stress.md (adversarial stress) | 2608121022-parent-lineage-and-projex-tree-redesign-plan.md (abandoned redesign) | 2608121756-parent-lineage-and-projex-tree-addition-plan.md (replacement plan) | 2608121035-parent-lineage-and-projex-tree-redesign-redteam.md (abandoned-plan red-team)

---

## Summary

Require exactly one machine-readable `> **Parent:**` header on every projex document. Value: `User` | `Orchestrator` | one projex filename ending in `.md`. Add paired `projex-tree.{sh,ps1}` utilities: given a repo root and filename, discover that file across repo-scoped `.projex/` folders, follow incoming `Parent` edges recursively, and print its deterministic descendant tree.

**Recommendation:** strict single-parent lineage, separate from topical `Related Projex` links. Enforce at creation through `new-projex.{sh,ps1}` and every document-producing workflow; make the tree utility the integrity checker and reader. This yields an actual tree, not a cyclic reference graph.

---

## Problem Statement

### Current State

- Common scaffold emits `Status`, `Author`, `Related Projex`; no creation lineage.
- Workflow-specific headers vary widely (`Source`, `Subject`, `Nav`, `Source Plan`, `Successor`, `Related Projex`). None gives one framework-wide, mechanically traversable parent edge.
- Execution logs and walkthroughs are created outside `new-projex`; generator-only enforcement would miss them.
- `Related Projex` is many-to-many and semantic: related, superseded, reviewed, implemented, or merely adjacent. Following it recursively can cycle and cannot produce a canonical tree.
- Existing prior art, `2604031730-util-script-ideas-imagine.md § projex-refs`, proposes arbitrary filename-reference graphs. It does not define lineage or tree invariants.
- Archive indexes retain `Related` but not parent lineage. Conclude may remove source documents entirely; current-corpus traversal can therefore encounter historical gaps.

### Gap / Need

Agents and humans cannot answer mechanically:

- Which workflow/document directly spawned this document?
- Which documents descend from a proposal, plan, nav, or orchestrator run?
- What complete current subtree belongs to a root projex?
- Are lineage links malformed, duplicated, cyclic, or dangling?

Manual filename-reference scans over-report topical links, under-report implicit creation, and become expensive across multiple `.projex/` scopes and lifecycle folders.

### Why Now?

Projex now has 21 document types, orchestration, nested workflow chains, multiple `.projex/` roots, and archive/conclude compression. Lineage is already operationally important—close sweeps related artifacts and orchestration manages child lifecycles—but remains encoded inconsistently in prose.

---

## Proposed Change

### Parent Contract

Every projex document carries exactly one strict line near the top:

```markdown
> **Parent:** User
> **Parent:** Orchestrator
> **Parent:** 2608120933-parent-lineage-header-and-projex-tree-utility-proposal.md
```

Only one form appears per document. Grammar:

```text
^> \*\*Parent:\*\* (User|Orchestrator|[0-9]{10}-[a-z0-9][a-z0-9-]*-[a-z0-9]+\.md)$
```

Semantics:

1. **Projex filename wins when a document directly derives from another projex.** Example: proposal → plan → execution log/walkthrough; target plan → review/red team/audit.
2. **`Orchestrator` marks a root created by orchestration when no projex file is the direct parent.**
3. **`User` marks a root created from direct user instruction when no projex file is the direct parent.**
4. **Multi-source workflows choose one primary parent deterministically**—the workflow's source-of-record or first explicit target. Remaining sources stay in `Related Projex`, `Sources`, `Nav`, or type-specific provenance fields.
5. **Parent is causal lineage, not topical relation.** It does not replace `Related Projex`, `Source`, `Nav`, `Successor`, or other type-specific metadata.
6. **Filename only; never a path.** State moves do not change it. No self-parenting; one parent filename must resolve uniquely when created.

Each document-producing workflow must state its parent-selection rule. No agent judgment where the workflow already has a source-of-record:

| Created document | Parent |
|---|---|
| Proposal/eval/imagination/memo/etc. from direct prompt | `User` |
| Orchestrator-started root without source projex | `Orchestrator` |
| Plan derived from proposal/nav/memo | source filename |
| Execution log | plan filename |
| Walkthrough | plan filename |
| Review/red team/stress/audit of one projex | target filename |
| Batch or multi-source artifact | workflow-defined primary; all others remain related |
| Patch executing a plan objective | plan filename |

### Creation Enforcement

Clean-cut `new-projex` interface:

```text
new-projex.{sh|ps1} <repo-root> <type> <title> <parent> [<projex-dir>]
```

Both variants:

- require parent—no compatibility default;
- reject values outside the grammar;
- for filename parents, resolve exactly one matching current document or archive-index entry under repo-scoped `.projex/` roots before writing;
- emit `> **Parent:**` in the common header;
- leave type-specific workflows responsible for deterministic parent selection.

Update all `new-projex` call sites and templates. Also update manual creators: execution log, walkthrough, debug records, and any other spec that writes a document without the scaffold. Add Parent to `SKILL.md § Authoring` as a universal invariant and to proposal/plan/etc. readiness gates.

### `projex-tree` Utility

```text
projex-tree.{sh|ps1} <repo-root> <filename>
```

Algorithm:

1. Validate repo root and input basename; reject paths.
2. Discover documents in every repo-scoped `.projex/`, including active, `closed/`, `abandoned/`, and archive-index virtual entries; exclude `.git/`, `.projexwt/`, and nested repositories.
3. Parse exactly one Parent header per document/index entry.
4. Resolve input filename uniquely.
5. Build `parent filename → children[]`.
6. Print input root plus all recursive descendants; siblings sort by filename ascending.
7. Detect cycles, duplicate filenames, malformed/missing Parent headers, and dangling parent filenames. Never recurse forever or silently omit a bad edge.

Default human output:

```text
2608051553-feature-proposal.md
├── 2608052327-feature-plan.md
│   ├── 2608052327-feature-log.md
│   └── 2608112108-feature-walkthrough.md
└── 2608052346-feature-plan-redteam.md
```

Diagnostics go to stderr with filename and reason. Success exits `0`; invalid input, ambiguous identity, cycle, or malformed lineage exits nonzero. A dangling historical parent prints `[missing]` and fails: visible partial output is more useful than either fabrication or silent truncation.

**Tree boundary:** Parent edges only. `Related Projex` stays a graph and is not traversed. `projex-refs` remains valid separate prior art for arbitrary cross-references.

### Archive and Removal

Archive summary extraction and index entries gain:

```markdown
- **Parent:** `filename.md` | User | Orchestrator
```

The tree utility treats indexed entries as virtual documents, preserving lineage after originals are removed. Conclude-removal metadata must preserve filename + Parent in its successor ledger or another machine-readable retained entry; otherwise the utility reports the deleted node as missing. Historical reconstruction from git is out of default scope.

### Migration

Enforcement means current corpus, not only future files:

1. Inventory every existing projex document and archive entry.
2. Derive Parent only from explicit evidence: source fields, invocation records, plan/log/walkthrough naming, nav derivation, or git history.
3. Manually resolve ambiguous roots. Do not label unknown provenance `User` merely to pass validation.
4. Add all headers before enabling strict tree checks in normal workflows.

The allowed vocabulary has no `Unknown`; unresolved migration items block completion rather than corrupt lineage.

### Approach Options

#### Option A: Strict Parent tree + dedicated paired utility

- **Description:** Contract and migration above; `new-projex` hard gate; `projex-tree.{sh,ps1}` traverses Parent only.
- **Pros:** Canonical, deterministic, cycle-checkable tree; causal lineage remains distinct from semantic links; no central mutable registry.
- **Cons:** Broad spec/template migration; single parent forces primary selection for multi-source artifacts; archive/conclude retention must change.
- **Effort:** Medium-high.

#### Option B: Recursively scan every filename reference

- **Description:** Extend prior `projex-refs`; treat every referenced filename as a tree edge.
- **Pros:** Little header/schema work; surfaces all relationships.
- **Cons:** Produces a cyclic graph, duplicate nodes, and unstable “parents”; cannot satisfy canonical tree semantics or distinguish spawned-from from merely related.
- **Effort:** Medium, but wrong abstraction.

#### Option C: Central lineage registry

- **Description:** Store parent/child edges in one repo-level index; tree utility reads it.
- **Pros:** Fast traversal; removed documents can remain as registry nodes.
- **Cons:** Every creation/move/archive/conclude becomes a two-file atomic update; merge conflicts and drift create a second source of truth.
- **Effort:** High.

### Recommended Approach

**Option A.** The required Parent header is the source of truth; the utility derives children by scanning, so no child-list synchronization exists. Paired shell/PowerShell variants follow repository parity. Archive metadata preserves ordinary lifecycle moves; explicit diagnostics expose irrecoverable removal gaps.

---

## Impact Analysis

### Affected Areas

- `SKILL.md` — universal Parent grammar, semantics, precedence, archive behavior, utility docs.
- `new-projex.sh`, `new-projex.ps1` — required Parent argument, validation, emitted header.
- All document-producing `*-projex.md` specs — call syntax, header templates, parent-selection rules, readiness checks.
- `execute-projex.md`, `close-projex.md`, `debug-projex.md` — manual log/walkthrough/debug document creation.
- `archive-projex.md` — extract and retain Parent for virtual archived nodes.
- `conclude-projex.md` — retain lineage metadata for removed sources.
- `projex-tree.sh`, `projex-tree.ps1` — new read-only utilities.
- `tests/` — cross-platform fixtures for traversal, multi-root discovery, archived entries, malformed/missing Parent, duplicate filename, dangling parent, and cycles.
- `README.md`, `USAGE.md`, `AUTHORING.md`, `AGENTS.md` — utility inventory and authoring examples where applicable.
- Existing `.projex/**/*.md` corpus — one-time evidence-based Parent backfill.

### Dependencies

- Filename uniqueness across a repo remains load-bearing.
- Archive entries must retain Parent before originals are deleted.
- Workflow specs must define primary-parent precedence for every multi-source type.

### Risks

| Risk | Likelihood | Impact | Mitigation |
|---|---:|---:|---|
| Parent conflated with “related” | Med | High | Define causal-only semantics; utility ignores all other references |
| Ambiguous multi-source ancestry | Med | Med | Type-specific deterministic primary; preserve remaining sources in existing fields |
| False legacy provenance | Med | High | Evidence-only backfill; unresolved items block migration |
| Archive/conclude erases nodes | Med | High | Archive Parent entries; conclude retained lineage ledger; loud dangling diagnostics |
| Cross-platform parser drift | Med | Med | Same fixture corpus and expected output for `.sh` and `.ps1` |
| Scan crosses nested repos/worktrees | Low | High | Explicit repo boundary; exclude nested `.git` and `.projexwt` |
| Mandatory generator argument breaks old callers | High | Med | Clean cutover: update every shipped call site in one plan; no shim/default |

### Breaking Changes

Yes. `new-projex` gains a required positional Parent argument; every caller must migrate atomically. Documents missing Parent become invalid after corpus migration. This is intentional: an optional or inferred-at-read-time field cannot enforce complete lineage.

---

## Open Questions

- [ ] For multi-target reviews/audits, should primary parent always be first CLI target, or should each workflow name a stronger source-of-record rule?
- [ ] What exact machine-readable block should conclude retain for removed source filename + Parent pairs?
- [ ] Should utility later add `--format json`/`dot`? Defer unless a real consumer exists; human tree output is the requested contract.

---

## Next Steps

If accepted:

1. `/plan-projex` — specify per-workflow Parent selection, migration inventory, exact utility output/exit contract, and paired test matrix.
2. Implement common header/generator cutover and all call-site/template updates atomically.
3. Backfill current corpus from evidence; resolve every ambiguity.
4. Implement archive/conclude retention, then `projex-tree.{sh,ps1}`.
5. Run shell and PowerShell behavioral suites plus direct tree smoke scenarios.

---

## Appendix

### Research / References

- `2604031730-util-script-ideas-imagine.md § projex-refs` — arbitrary filename-reference graph prior art.
- `2604031727-workflow-guardrails-determinism-imagine.md` — existing parent/child spawn declaration principle.
- `new-projex.sh`, `new-projex.ps1` — common header scaffold; current strongest enforcement point.
- `archive-projex.md § Summarize Each File / Draft the Archive Document` — current compression schema.

### Alternatives Considered

- **Reuse `Related Projex` as Parent:** rejected—multi-valued, semantic, often reciprocal, cyclic.
- **Infer parent from filename stems:** rejected—works for some plan/log/walkthrough chains, not reviews, audits, nav derivation, or orchestrator roots.
- **Allow `Unknown` for migration:** rejected by requested closed vocabulary; unresolved lineage must remain visible work.
- **Single-language utility only:** rejected—repository convention ships shell and PowerShell parity for general utilities.
