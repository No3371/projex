# Parent Lineage and Projex Tree Redesign

> **Status:** Ready
> **Author:** OpenAI Codex (Agent)
> **Parent:** 2608120933-parent-lineage-header-and-projex-tree-utility-proposal.md
> **Source:** 2608120933-parent-lineage-header-and-projex-tree-utility-proposal.md — direction accepted by direct request; proposal header remains Draft by design
> **Related Projex:** 2608120933-parent-lineage-header-and-projex-tree-utility-proposal.md | 2608120952-parent-lineage-header-and-projex-tree-utility-redteam.md | 2608121003-parent-lineage-header-and-projex-tree-utility-proposal-stress.md | 2608121035-parent-lineage-and-projex-tree-redesign-redteam.md | 2604031730-util-script-ideas-imagine.md | 2604031727-workflow-guardrails-determinism-imagine.md
> **Worktree:** Yes

---

## Summary

Land a causal lineage contract for future and explicitly adopted documents. Replace anonymous `Orchestrator` roots with collision-safe thin `{yymmddhhmm}-{slug}-orchestrate.md` run records; bound governed live metadata to a versioned top-of-file block; reserve filename identity across explicitly registered `.projex` roots; retain removed governed nodes and Parent-correction evidence in versioned grammars; provide targeted `projex-tree` reads plus strict `--check`.

**Forward-only boundary:** A document is governed only when created through the new contract or later adopted by an evidence-backed `revise-projex` Parent event. Pre-contract documents remain outside strict lineage: targeted traversal refuses to present one as a tree, and `--check` lists it as excluded rather than compliant or defective. No historical ancestry is inferred.

**Scope:** Root Projex framework distribution: core/workflow specs, paired scaffold/tree scripts, focused behavioral suites, public utility inventories, root-registration and correction ledgers. One repo; root `.projex/` is the only initially authorized lineage root.
**Estimated Changes:** 2 new utilities, 2 scaffolders, 27 framework/workflow specs, 7 focused test files, 3 public docs, 2 governance TSVs. Five coupled implementation steps.

---

## Objective

### Problem / Gap / Need

Current framework has topical and type-specific links but no universal causal edge. Original strict-Parent proposal chose the right tree abstraction, yet adversarial reports show its implementation contract is unsafe: line-regex parsing reads fenced examples as headers; filename identity and orchestration record minting collide; `Orchestrator` merges unrelated runs; scaffolding emits noncanonical `Closed`; archive/conclude retention has no schema; Parent corrections erase evidence; name-only `.projex` discovery permits poisoning; handwritten creators can bypass the field; no proactive integrity mode exists.

The redesign must preserve what held: one causal Parent distinct from `Related Projex`; filename-only stable references; deterministic sibling order; hard scaffold cutover; paired shell/PowerShell behavior; visible cycle/dangling diagnostics. It must not mistake the proposal's retained Draft header for unresolved human intent: this Plan is authorized to implement the direction after applying the red-team/stress fixes and settled `-orchestrate.md` suffix.

### Success Criteria

- [ ] Every newly created governed projex document has one bounded metadata preamble beginning `> **Projex Metadata:** 1`, followed immediately by exactly one `> **Parent:** User|{projex-filename}.md`; body examples never count as headers
- [ ] Source-less and nested orchestration runs mint thin `{yymmddhhmm}-{slug}-orchestrate.md` records through exclusive no-clobber reservation; a same-minute, same-normalized-title collision fails `E_ORCHESTRATE_NAME_COLLISION` as likely duplicate dispatch, while genuinely distinct concurrent runs use meaningfully distinct titles; top-level dispatched artifacts parent to their run record; execution logs/walkthroughs retain plan parentage
- [ ] `new-projex.{sh,ps1}` require Parent with no compatibility default, reject invalid/unresolved parents, map every scaffold type to a canonical lifecycle Status, reserve full filenames across authorized live/virtual roots, and cannot both win one candidate during a cross-platform race
- [ ] `projex-tree.{sh,ps1}` implement identical registered-root discovery, bounded governed-document parsing, canonical live/virtual Status validation, virtual-record parsing, targeted subtree output, deterministic diagnostics/exit classes, `--check`, and `--check-name`; unregistered nested `.projex` roots never contribute identities
- [ ] A pre-contract document is never shown as a valid lineage node: a targeted request reports `E_UNGOVERNED_DOCUMENT`; `--check` reports it as excluded from strict lineage, not compliant or malformed
- [ ] A pre-contract document enters strict lineage only through one explicit, evidence-backed `revise-projex` adoption event; later Parent changes append complete correction evidence before metadata changes
- [ ] Archive and conclude preserve deleted governed nodes in the same `projex-lineage-v1` record grammar, bind any Parent-correction/adoption IDs, validate target-local live→virtual handoff before deletion, and preserve ancestry/evidence afterward
- [ ] All 20 current `new-projex` workflow call sites supply deterministic Parent; orchestrate, execute, close, debug, and sprint manual writers route through the scaffold or an equivalent shared validation gate
- [ ] Archive/conclude gates apply only to governed source documents and their governed reachable lineage; unrelated pre-contract documents neither satisfy nor block the gate
- [ ] Shared shell/PowerShell fixtures cover bounded examples, CRLF/BOM, symlinks, registered/unregistered roots, nested repos/worktrees, same-minute orchestration-name collisions and distinct-title concurrent runs, canonical/noncanonical Status, cycles, dangling parents, pre-contract exclusion, evidence-backed adoption, correction→retention, virtual handoff, diagnostic ordering, and exit classes
- [ ] `README.md`, `AGENTS.md`, and `CLAUDE.md` expose the new utility/identity/root-registration contract; `USAGE.md` and `AUTHORING.md` remain unchanged after confirmed absence of relevant utility/header inventories
- [ ] Auxiliary proposal/plan/eval/review/redteam/stress/etc. artifacts remain no-auto-commit; this Plan and its relationship edits are not committed by planning

### Out of Scope

- Traversing `Related Projex`, `Source`, `Nav`, `Sprint`, commit trailers, or arbitrary filename references as tree edges
- JSON/DOT output, ancestor queries, graph visualization, daemon/index service, or a central mutable child registry
- Reconstructing lineage from remote systems, deleted git history, or current-corpus metadata during normal tree reads
- Editing pre-contract documents solely to make them appear governed, or assigning unsupported provenance to make strict checks green
- Changing lifecycle meanings beyond replacing noncanonical scaffold output with the existing canonical vocabulary; no new lifecycle state is introduced
- Auto-committing this Plan, its source proposal, adversarial reports, or any other auxiliary artifact

---

## Context

### Current State

- `SKILL.md § Authoring` defines filename-only references but no Parent or bounded metadata block. Orchestration explicitly says it has no standalone document.
- `new-projex.sh` and `.ps1` accept `<repo-root> <type> <title> [<projex-dir>]`, emit Status/Author/Related only, reject only the exact target path, and emit noncanonical `Closed` for born-closed types. Supported types omit orchestrate, sprint, and walkthrough. Generic `log` is marked born-closed although execution logs live beside active plans.
- Exactly 20 workflow specs call `new-projex`: `archive-projex.md`, `audit-projex.md`, `coach-projex.md`, `conclude-projex.md`, `define-projex.md`, `eval-projex.md`, `explore-projex.md`, `guide-projex.md`, `imagine-projex.md`, `interview-projex.md`, `memo-projex.md`, `navigate-projex.md`, `patch-projex.md`, `plan-projex.md`, `preplan-projex.md`, `propose-projex.md`, `redteam-projex.md`, `review-projex.md`, `scan-projex.md`, `stress-projex.md`.
- Manual writers: `execute-projex.md` creates active `-log.md`; `close-projex.md` creates closed `-walkthrough.md`; `debug-projex.md` creates active `-debug-log.md` and closed `-debug.md`; `sprint-projex.md` creates active `-sprint.md`; `orchestrate-projex.md` creates no artifact.
- `archive-projex.md` retains Filename/Title/Date/Type/Outcome/Summary/Touched/Keywords/Related as free-form Markdown. `conclude-projex.md` retains source filename + disposition in a prose successor ledger. Neither preserves a parseable Parent edge, correction reference, or virtual-node contract.
- Existing `.projex/` documents use heterogeneous headers; some recent artifacts carry a Parent line, but none are governed until the contract creates or explicitly adopts them. No trusted-root registry or Parent-correction ledger exists.
- Tests cover close/precheck safety. `tests/run-all.sh` lists 5 suites; `.ps1` lists 4. No `new-projex` or lineage suite exists. Test convention: isolated temp repos, observable assertions, one `PASS=N FAIL=N` summary, independent shell/PowerShell logic.
- Public docs: `README.md` has a utility table; `AGENTS.md`/`CLAUDE.md` have repository trees and filename-uniqueness guidance. `USAGE.md`/`AUTHORING.md` have no matching utility/header inventory.

### Key Files

| File(s) | Role | Change Summary |
|---|---|---|
| `SKILL.md` | Canonical framework contract | Versioned governed preamble, Parent semantics/precedence, forward-only boundary, canonical Status mapping, registered-root trust boundary, virtual retention, Parent-correction/adoption governance, orchestration-record policy |
| `orchestrate-projex.md` | Per-run user-level coordinator | Collision-safe thin `-orchestrate.md` minting; pass its filename as parent to dispatched roots; nested parentage; commit-policy handling |
| `new-projex.sh`, `new-projex.ps1` | Creation enforcement | Required Parent; canonical Status by type; new/manual types; authorized-root identity scan; exclusive no-clobber reservation; timestamp-plus-title orchestration minting; versioned header emission |
| `projex-tree.sh`, `projex-tree.ps1` | New read-only utility | Registered-root discovery/parser/index/tree/check contract with parity; governed/pre-contract boundary, correction and lifecycle-gate validation |
| `.projex/trusted-roots-v1.tsv` | Root admission policy | Canonical root plus explicit repo-relative scoped-root registrations, owners, dates, evidence |
| 20 scaffold-calling `*-projex.md` specs | Standard artifact creators | Parent selection, new argument, header preservation, readiness checks |
| `execute-projex.md`, `close-projex.md`, `debug-projex.md`, `sprint-projex.md` | Manual creators | Route log/walkthrough/debug/sprint docs through scaffold and assign internal lineage |
| `orchestrate-projex.md`, `archive-projex.md`, `conclude-projex.md`, `revise-projex.md` | Identity/lifecycle governance | Run minting; evidence logging for corrections/adoptions; governed-document gate; correction-bound virtual records before removal |
| `.projex/parent-lineage-corrections-v1.tsv` | Durable correction/adoption trail | Append-only evidence events plus one-time retained-record binding |
| `tests/new-projex.test.{sh,ps1}` | Scaffold contract | Argument/header/type/identity/reservation behavior |
| `tests/projex-tree.test.{sh,ps1}` | Reader/integrity contract | Shared scenario matrix and exact output/exit assertions |
| `tests/run-all.{sh,ps1}`, `tests/README.md` | Test integration | Register/document both paired suites |
| `README.md`, `AGENTS.md`, `CLAUDE.md` | Public/agent inventory | Utility, suffix, filename identity, Parent summary |

### Dependencies

- **Requires:** Accepted direction from direct request; adversarial requirements in `2608120952-parent-lineage-header-and-projex-tree-utility-redteam.md`, `2608121003-parent-lineage-header-and-projex-tree-utility-proposal-stress.md`, and five Must Fix findings in `2608121035-parent-lineage-and-projex-tree-redesign-redteam.md`; settled orchestration suffix `-orchestrate.md`.
- **Blocks:** Reliable orchestration-run subtree queries; future `projex-refs` graph work and additional scoped-root registrations may reuse discovery but are not part of this Plan.
- **Execution order:** Contract → paired parser/tree + root registry → scaffold cutover → workflow/manual creators + correction/retention rules → docs/integration verification.

### Constraints

- Filename is immutable identity. Orchestration uses `{yymmddhhmm}-{slug}-orchestrate.md`; no token, separate UUID, or central child registry.
- Parent is causal only. Top-level artifact dispatched by orchestration uses the run record; internal execution artifacts use their workflow source (`plan` or `debug-log`). Type-specific provenance remains intact.
- Trusted discovery bootstrap: canonical `<repo-root>/.projex` only. Additional roots participate only when their canonical repo-relative path has one committed `.projex/trusted-roots-v1.tsv` row with owner/date/evidence; symlinked paths, `.git`, `.projexwt`, nested repositories, unregistered `.projex` directories, and paths escaping repo are excluded.
- Live parser reads only a versioned preamble: first `# ` heading, blank line, `> **Projex Metadata:** 1`, immediate Parent line, remaining unique blockquote metadata, blank line, `---`. Text/fences after the separator are never metadata.
- A governed document is created through a contract-aware creator or adopted later through `revise-projex`. A pre-contract document has no valid v1 preamble and is outside strict lineage; its unbounded/legacy header fields are not parsed as Parent metadata.
- Status uses SKILL's exact canonical state plus optional outcome. Live/virtual parsers reject `Closed` and every other noncanonical state; they never normalize. Transitional handoff compares the full Status text exactly.
- Virtual parser reads only `projex-lineage-v1` fences under `## Lineage Records` in files ending `-archive.md` or `-conclude.md`.
- No compatibility default for missing Parent on new creation. An adoption requires an explicit evidence-backed ledger event; `User` is valid only when its evidence records direct human instruction with no source projex.
- A Parent change after creation/adoption is valid only with an atomic `revise-projex` correction-ledger row. Lifecycle removal binds every applicable correction/adoption ID into the retained virtual record before deletion.
- Archive/conclude strict lineage gates run only for governed source documents and their governed reachable descendants. Pre-contract documents use existing retention behavior and must not yield v1 records or a claimed lineage validation.
- Auxiliary artifact commit policy remains authoritative. A chain that explicitly enters execute/close may commit its required plan + orchestration record together as an execution prerequisite; auxiliary-only chains do not gain implicit commit permission.
- Worktree mode: Yes because base working directory is dirty; implementation creates many files and may coexist with other activity.

### Assumptions

- Full filename identity remains practical because names already carry time + slug + type. An orchestration candidate collision requires the same normalized title in the same minute, is strong duplicate-dispatch evidence, and fails explicitly; genuinely distinct concurrent runs use meaningfully distinct titles. Repo-wide reservation across registered roots closes the actual gap without a second identifier.
- A strict Markdown preamble plus type-scoped virtual fences is implementable in both Bash and PowerShell without a general Markdown parser.
- Explicitly excluding pre-contract documents makes strict results truthful without changing their bytes. A later evidence-backed adoption is intentional new provenance, not a reconstruction of prior ancestry.
- `--check` can report the pre-contract exclusion set without treating it as a clean governed set or a failure in the governed contract.

### Impact Analysis

- **Direct:** every future document creation, orchestration run, Parent correction/adoption, governed lifecycle archive/conclude operation, and lineage query.
- **Adjacent:** execute/close/debug/sprint state artifacts; authorized-root registration; auxiliary relationship edits; test runners; public utility inventory.
- **Downstream:** repos syncing this framework must migrate all `new-projex` calls atomically, create their canonical root registry, and use explicit revise adoption when an older document needs strict lineage. Existing documents remain outside strict traversal until then.
- **Failure containment:** unregistered roots never enter identity resolution; pre-contract documents are explicitly excluded; malformed governed nodes affect their target/reachable tree and `--check`, not unrelated valid target queries.

---

## Implementation

### Overview

Five steps form one clean cutover. Step 1 fixes semantics and creates queryable run roots. Step 2 implements the single registered-root discovery/parser contract twice and makes scaffold identity/Status enforcement consume it. Step 3 updates every standard creator. Step 4 closes manual-writer, Parent-correction/adoption, and governed-retention gaps. Step 5 integrates docs/tests and proves parity. No step introduces a second lineage convention or historical reconstruction surface.

### Step 1: Canonical Contract and Queryable Orchestration Roots

**Objective:** Freeze all redesign decisions before scripts/workflows consume them.
**Confidence:** High
**Depends on:** None
**Verify-Projex:** Required

**Files:**
- `SKILL.md`
- `orchestrate-projex.md`

**Changes:**

1. Add `SKILL.md § Parent Lineage` under Authoring with the exact governed live preamble:

```markdown
# [Title]

> **Projex Metadata:** 1
> **Parent:** User | {yymmddhhmm}-{name}-{type}.md
> **Status:** [when the type carries lifecycle status]
> [...unique type-specific metadata]

---
```

Define: marker/Parent ordering; blank + `---` terminator; no duplicate metadata keys; filename grammar `^[0-9]{10}-[a-z0-9][a-z0-9-]*-[a-z0-9]+\.md$`; no `Orchestrator` sentinel; no paths/self-parent; causal-vs-topical boundary; registered-root identity; live/virtual handoff; targeted vs `--check`; pre-contract exclusion semantics.
2. Define forward-only boundary. Governed = v1 preamble emitted by a contract-aware creator, or a later `revise-projex` adoption event. Pre-contract = any other document. Never infer a Parent from its fields, body, filename, git history, or relationship metadata. Targeted tree request for it emits `E_UNGOVERNED_DOCUMENT`; `--check` emits sorted `I_PRECONTRACT_EXCLUDED` records and validates only governed documents.
3. Define deterministic Parent precedence for governed creation and adoption: (1) internal artifact's source-of-record (execution log/walkthrough → plan; final debug doc → debug log); (2) orchestrator/sprint `parent=` handoff for a dispatched root; (3) single referenced source/target; (4) first explicit target left-to-right for multi-target workflows; (5) `User` only when direct human instruction has no source projex. Remaining inputs stay in existing Source/Subject/Nav/Sources/Related fields.
4. Define canonical initial scaffold Status by type: `Draft` = propose|plan|eval|redteam|stress|audit|interview|coach|memo|define|map|imagine; `In Progress` = review|explore|navigate|log|sprint|orchestrate; `Complete` = patch|preplan|debug|scan|guide|conclude|archive|walkthrough. Workflow transitions may replace these only with another canonical state/outcome. `Closed` is invalid data, never an alias.
5. Define root admission: root `.projex` is bootstrap-authorized; every additional scoped root needs an exact row in `.projex/trusted-roots-v1.tsv` (`path	owner	added	evidence`). Registration changes require explicit human/repo-owner review; scanners ignore unregistered content for identity/tree resolution and report its directory only during `--check`.
6. Define Parent evidence events: `revise-projex` appends one `.projex/parent-lineage-corrections-v1.tsv` event before/atomically with a live Parent edit. Columns: `event_id	date	filename	event_kind	prior_parent	new_parent	evidence	resolver	reason	retained_record`; `event_kind=adoption|correction`; adoption requires `prior_parent=none`, correction requires the current Parent; evidence is a durable repo-relative/file-name locator or quoted human requirement. Event IDs use `pc-` + 24 lowercase hex. Rows are append-only; only blank→`{archive|conclude filename}#{source filename}` retained-record binding is allowed before removal.
7. Revise SKILL orchestration description: orchestration has a thin record, not a new analytical type. Filename is exactly `{yymmddhhmm}-{slug}-orchestrate.md`; suffix remains fixed to `-orchestrate.md`.
8. In `orchestrate-projex.md`, create the run record before first dispatch through the scaffold's orchestrate mint mode; update it only at dispatch completion/escalation. Template contains metadata, Status, verbatim goal, literal chain/model annotations, final outcome, and child filenames returned. No copied subagent reports.
9. Root record Parent: referenced source-of-record when orchestration is invoked against one; otherwise `User`. Nested record Parent: outer `-orchestrate.md`. Every directly dispatched document-producing workflow receives `parent={run-record-filename}`. Non-document subworkflows remain untouched.
10. Preserve auxiliary commit policy explicitly: record and auxiliary children are presented uncommitted for auxiliary-only chains. If explicit chain includes execute/close, commit the record with the required plan prerequisite so worktree branches can resolve Parent; no standalone implicit auxiliary commit.

**Rationale:** A per-run timestamp-plus-title file is the smallest stable identity that makes runs queryable. Exclusive reservation converts a same-minute, same-normalized-title candidate into explicit likely-duplicate-dispatch evidence; genuinely distinct concurrent work names itself meaningfully. Registered roots prevent directory-name trust. The v1 boundary makes strict lineage truthful without fabricating history.

**Verification:** Focused spec inspection: every Parent case maps to one precedence row; canonical status table covers every scaffold type once; a pre-contract document has an explicit exclusion result rather than a guessed Parent; same-minute source-less and nested attempts with the same normalized title fail `E_ORCHESTRATE_NAME_COLLISION`; meaningfully distinct concurrent titles yield distinct queryable filenames; nested example forms `outer orchestrate → inner orchestrate → child`; unregistered roots never resolve; no `Parent: Orchestrator` remains in normative text except rejected-history discussion.

**If this fails:** Revert both specs together. Do not implement a parser against ambiguous semantics.

---

### Step 2: Paired Reader, Identity Gate, and Scaffold Cutover

**Objective:** Implement one normative discovery/parser behavior in both platforms and make all governed creation pass through it.
**Confidence:** Medium
**Depends on:** Step 1
**Verify-Projex:** Required

**Files:**
- `projex-tree.sh` (new)
- `projex-tree.ps1` (new)
- `new-projex.sh`
- `new-projex.ps1`
- `.projex/trusted-roots-v1.tsv` (new)
- `tests/new-projex.test.sh` (new)
- `tests/new-projex.test.ps1` (new)
- `tests/projex-tree.test.sh` (new)
- `tests/projex-tree.test.ps1` (new)

**Changes:**

1. Add identical CLI contracts:

```text
projex-tree.{sh|ps1} <repo-root> <filename>
projex-tree.{sh|ps1} <repo-root> --check
projex-tree.{sh|ps1} <repo-root> --check-name <filename>
```

Exit `0`: requested operation valid; `1`: governed-lineage/integrity failure; `2`: usage, invalid root, path input, unsupported encoding, or ungoverned target. Diagnostics sort by filename then stable code; stdout tree siblings sort filename ascending.
2. Read root registrations only from canonical root `.projex/trusted-roots-v1.tsv`. Validate exact TSV schema, canonical repo-relative `.projex` paths, unique paths, and owner/date/evidence values; reject symlinks, exclusions, nested repos, and escapes. Root `.projex` is always present as the sole bootstrap row. Targeted mode ignores unregistered `.projex` trees completely; `--check` emits sorted `E_UNREGISTERED_ROOT` diagnostics without parsing their files.
3. Parse UTF-8 with optional BOM and LF/CRLF identically. Only a valid v1 preamble creates a live lineage node; a document without it is pre-contract and no header-shaped line elsewhere is metadata. Parse canonical virtual blocks; validate Status with the strict SKILL regex + canonical state set and reject `Closed` without normalization. Build identity map + Parent→children map only from governed live/virtual records. `Related Projex` and header-shaped body/fence lines are ignored.
4. Targeted mode validates requested identity and reachable governed descendants. If the requested physical document exists but is pre-contract, emit `E_UNGOVERNED_DOCUMENT: {filename}: outside strict lineage; use revise-projex adoption with evidence` and exit `2`; do not print a tree. Unrelated malformed governed nodes produce one deterministic summary warning and do not change exit `0`; reachable duplicate/cycle/malformed/dangling state prints partial tree, detailed stderr, exit `1`. `--check` emits every sorted authorized-corpus/registration/correction defect plus one sorted `I_PRECONTRACT_EXCLUDED` record per pre-contract document; exclusion records do not make `--check` succeed for them or fail the governed set. `--check-name` checks grammar and absence across authorized physical/virtual identities without requiring a pre-contract document to become governed.
5. Change scaffold signature cleanly:

```text
new-projex.{sh|ps1} <repo-root> <type> <title> <parent> [<projex-dir>]
```

Validate Parent grammar; resolve filename parent uniquely through `projex-tree --check-name`/identity scan; reject User when a caller supplied a source parent; emit metadata marker + Parent + the Step 1 canonical initial Status; no old-arity fallback.
6. Add scaffold types needed by manual writers: `orchestrate → orchestrate` (active), `sprint → sprint` (active), `walkthrough → walkthrough` (born closed). Make generic `log` active; use title `{debug-name}-debug` for `-debug-log.md`; make final `debug` born closed. Preserve unrelated suffix mappings.
7. Orchestrate mint mode computes `{stamp}-{slug}-orchestrate.md`. Acquire the canonical-root per-candidate lock, run authorized-root `--check-name`, and exclusively create with no-clobber semantics. A candidate collision fails `E_ORCHESTRATE_NAME_COLLISION: {candidate}: likely duplicate dispatch; choose a meaningfully distinct title`; never randomize, inject entropy, or retry under another name.
8. Every computed filename reserves identity across authorized scopes before write. Both scripts create the same per-filename lock under canonical root `.projex/.lineage-locks/`, run `--check-name`, create with exclusive/no-clobber semantics, and remove the owned lock in trap/finally. Existing/stale lock fails loud; never steal it. Remove empty lock dir best-effort. Scanner ignores this non-Markdown internal dir.
9. Define virtual handoff collision: one live + one virtual record with identical Filename/Parent/full canonical Status and virtual Source equal to live repo-relative path is a transitional pair; reader prefers live and warns. Any mismatch or >2 instances is an error. After deletion virtual record becomes sole identity.

**Rationale:** Filename identity keeps existing reference conventions; registered-root scan + exclusive reservation fixes sequential/concurrent collision and turns an orchestration collision into useful duplicate-dispatch evidence. Canonical Status makes live→virtual equality meaningful. Tree utility owns discovery semantics so scaffold cannot drift into a second parser. Explicit pre-contract exclusion prevents a strict output from claiming unknown ancestry is valid.

**Verification:** Run only the four focused suites. Required observable cases: invalid/missing Parent; every scaffold type emits its mapped canonical state; `Closed` live/virtual rejected; body examples accepted; a pre-contract target returns `E_UNGOVERNED_DOCUMENT` and `--check` labels it excluded; evidence-backed adoption creates one valid v1 node; two live headers rejected; same-minute same-normalized-title source-less and nested orchestration attempts fail with the stable collision diagnostic while distinct-title concurrent runs mint distinct roots; cross-root sequential/concurrent creation allows one winner per candidate; unregistered duplicate/cycle roots cannot affect a target and make `--check` report only their directory; live/virtual mismatch rejected; target query survives unrelated malformed governed doc; reachable cycle returns partial output/exit 1; `.sh`/`.ps1` stdout/stderr/exit match byte-for-byte after normalizing platform paths/newlines.

**If this fails:** Remove both new utilities and restore both scaffolders as one rollback unit. Do not change workflow arity until parity passes.

---

### Step 3: Update All Standard Document-Creating Workflows

**Objective:** Make every current scaffold caller select Parent deterministically and preserve the bounded preamble.
**Confidence:** High
**Depends on:** Steps 1–2
**Do-Projex:** Encouraged

**Files:**
- `archive-projex.md`, `audit-projex.md`, `coach-projex.md`, `conclude-projex.md`, `define-projex.md`
- `eval-projex.md`, `explore-projex.md`, `guide-projex.md`, `imagine-projex.md`, `interview-projex.md`
- `memo-projex.md`, `navigate-projex.md`, `patch-projex.md`, `plan-projex.md`, `preplan-projex.md`
- `propose-projex.md`, `redteam-projex.md`, `review-projex.md`, `scan-projex.md`, `stress-projex.md`

**Changes:**

1. Update all 20 scaffold invocations to pass `<parent>` before `<projex-folder>`; no call retains old arity.
2. Add a concise Parent-selection rule to each source-analysis/create step, referencing SKILL precedence and spelling out its local source-of-record:
   - proposal/imagination/memo/navigation/definition/exploration/guide/scan/interview/coach: orchestrate/sprint handoff, else referenced source, else User;
   - plan/preplan/eval: handoff, else source proposal/preplan/nav/memo/first evaluated target, else User;
   - review/redteam/stress/audit: handoff, else first explicit target; never Related;
   - patch: handoff, else executed plan when objective-bound, else referenced source/User;
   - conclude: handoff, else successor;
   - archive: handoff, else User because a folder is not a projex parent.
3. Update every full template so agents retain `Projex Metadata` + Parent from scaffold rather than rewriting a legacy header. Add readiness/quality checks for exactly one bounded Parent.
4. Update relationship instructions: Source/Subject/Related remain reciprocal/topic fields and never override Parent. Multi-target order is command/input order, not filename sort.
5. Update `plan-projex.md` source gate: a direct human acceptance may authorize a Draft proposal when invocation context says so; document the exception in Source. Do not mutate proposal status automatically. Keep auxiliary no-auto-commit policy authoritative over the stale finalize commit template.

**Rationale:** A hard scaffold signature without atomic caller cutover breaks all authoring. Per-workflow local rules prevent agents from improvising multi-source ancestry.

**Verification:** Exact callsite search returns 20 invocations and each has five operands including Parent; every template includes/retains version + Parent; no workflow names `Orchestrator` as a Parent value; no open-ended “choose a parent” text remains.

**If this fails:** Restore all 20 specs together. Partial arity cutover is invalid.

---

### Step 4: Close Manual-Creator and Lifecycle-Retention Gaps

**Objective:** Ensure every nonstandard artifact and every governed destructive lifecycle transition preserves lineage.
**Confidence:** Medium
**Depends on:** Steps 1–3
**Verify-Projex:** Required

**Files:**
- `execute-projex.md`
- `close-projex.md`
- `debug-projex.md`
- `sprint-projex.md`
- `orchestrate-projex.md`
- `archive-projex.md`
- `conclude-projex.md`
- `revise-projex.md`
- `.projex/parent-lineage-corrections-v1.tsv` (new)

**Changes:**

1. `execute-projex.md`: create active log via `new-projex ... log "{plan-name}" {plan-filename} {projex-folder}`; template retains bounded preamble. Parent always plan, regardless of outer orchestration.
2. `close-projex.md`: create closed walkthrough via `new-projex ... walkthrough "{plan-name}" {plan-filename} {projex-folder}`. Parent always plan. Existing plan/log/walkthrough relationship updates remain.
3. `debug-projex.md`: create active `{debug-name}-debug-log.md` through `log` with Parent = orchestrate/sprint handoff, referenced source, or User. Create final closed debug doc through `debug` with Parent = debug-log filename. Keep both artifacts and cross-links.
4. `sprint-projex.md`: create sprint nav through `sprint`; Parent = outer orchestration record, external nav/source, or User. Every body artifact receives sprint-nav filename as `parent=`; existing `Sprint:` stamp remains iteration provenance, not tree edge.
5. `orchestrate-projex.md`: use `orchestrate` scaffold mint mode and settled suffix. Completion status is `Complete`; interruptions use canonical `Blocked`/`Escalated`; move completed record to `closed/` only when its chain's artifact policy permits persistence.
6. `revise-projex.md`: require one atomic target+ledger commit for an adoption or any later Parent change. Adoption may introduce the v1 preamble only for a currently pre-contract document and records `prior_parent=none`; correction requires an already governed current Parent. Refuse missing values, invalid event kind, prior/current mismatch, repeated ID, unsupported evidence, or a second mutation not chained from the last row. Preserve the event's original evidence/resolver/date/reason forever.
7. Add one virtual grammar to both archive and conclude:

```projex-lineage-v1
Filename: 2601011200-example-plan.md
Parent: User
Status: Complete
Source: .projex/closed/2601011200-example-plan.md
Disposition: Archived
Correction-Refs: none
```

Fields/order exact; Filename is immutable identity; Parent uses live grammar; Status uses full canonical text; Source is repo-relative; Disposition is `Archived|Concluded`; Correction-Refs is `none` or sorted comma-separated correction/adoption IDs. Blocks occur only under `## Lineage Records`.
8. Archive extraction adds Parent + Correction-Refs and writes one record per governed source. Conclude report writes one per retired governed source; successor prose ledger remains human-facing. Before removal, bind every applicable ledger row to the retaining record, then validate record IDs, old→new chain, final Parent, source, and full Status. Missing/unbound/mismatched evidence blocks governed deletion.
9. Gate each governed archive/conclude source with targeted `projex-tree` validation of that source and its governed reachable descendants before and after deletion. A valid preflight, exact virtual handoff, and stable post-removal ancestry are required; unrelated pre-contract documents are excluded from this gate. A pre-contract source follows existing archive/conclude retention behavior and produces no v1 record or lineage-gate claim.
10. Governed archive/conclude artifacts record `Lineage Gate: Target-Clean`, sorted governed source filenames, check timestamp/resolver, and pre/post normalized targeted-tree hashes. Delete only after preflight record exists; run targeted checks after deletion and require hashes/ancestry unchanged. No manual flag or undocumented bypass.
11. Update creator inventory in SKILL/quality gates: future workflow adding a document must use `new-projex` or add a focused test proving identical metadata validation.

**Rationale:** Manual creators and removal paths are predictable drift points. One scaffold, evidence ledger, target-clean gate, and correction-bound virtual grammar preserve governed attribution and deletion proof without imposing claims on pre-contract documents.

**Verification:** Focused temp-repo scenarios: plan→log→walkthrough tree; orchestrate→plan and orchestrate→redteam siblings; outer→inner orchestrate; sprint→body artifact; debug-log→debug; archive child then conclude parent; all-virtual chain; ancestry/output identical before/after governed source deletion; an unrelated pre-contract document neither blocks nor appears in the target gate; Parent correction→archive and correction→conclude preserve old/new/evidence/resolver/date/reason plus mutual correction/retained-record references; evidence-backed adoption→retention preserves its adoption event.

**If this fails:** Do not delete any governed source document. Revert workflow specs and generated fixture records; physical originals remain authoritative.

---

### Step 5: Public Docs, Test Registration, and End-to-End Contract Proof

**Objective:** Make the contract discoverable and prevent cross-platform/workflow drift.
**Confidence:** High
**Depends on:** Steps 1–4
**Do-Projex:** Encouraged

**Files:**
- `README.md`
- `AGENTS.md`
- `CLAUDE.md`
- `tests/run-all.sh`
- `tests/run-all.ps1`
- `tests/README.md`
- all focused test files from Step 2

**Changes:**

1. README utility table adds `projex-tree`; `new-projex` row states required Parent, canonical Status, registered-root identity, exclusive no-clobber reservation, and timestamp-plus-title orchestration minting. Add one compact orchestration-record note with exact `{yymmddhhmm}-{slug}-orchestrate.md` form and one forward-only boundary note.
2. AGENTS/CLAUDE mirrored repository trees add `new-projex`, `projex-tree`, and root/correction registry files; filename guidance changes from convention-assumed uniqueness to enforced repo-wide authorized live/virtual identity; Parent references stay filename-only; explain that older documents require evidence-backed adoption before strict traversal.
3. Register `new-projex.test` and `projex-tree.test` once in each runner; preserve one-summary parsing. Document assertion counts and scenario coverage in tests README after actual runs.
4. Keep `USAGE.md`/`AUTHORING.md` unchanged; record verification that neither contains a utility/header inventory requiring update.
5. Run focused suites individually, not the project-wide runners during implementation verification. Also run Bash syntax parse and PowerShell AST parse only for the four changed/new scripts.
6. Execute end-to-end smoke in one throwaway repo: concurrently mint source-less and nested orchestrations with meaningfully distinct titles and prove distinct query roots; attempt each again with the same normalized title in the same minute and prove exclusive reservation emits `E_ORCHESTRATE_NAME_COLLISION` without clobbering the first record; create children; query each tree; register one scoped root; inject an unregistered duplicate root and prove it cannot affect the target; create a pre-contract document and prove targeted traversal refuses it while `--check` labels it excluded; adopt it through an evidence-backed revise event; correct one governed Parent with evidence; archive one governed child; conclude one governed ancestor; re-query; verify correction IDs survive, targeted output stays stable, and governed `--check` failure state is unaffected by the excluded document.

**Rationale:** Shared fixtures and independently executed platform suites are the parity contract. Public inventory prevents a correct utility or governance gate from remaining undiscoverable.

**Verification:** Focused suites exit 0 with one summary each; normalized golden stdout/stderr/exit records match across platforms; smoke proves distinct-title concurrent minting, likely-duplicate collision failure without clobbering, root admission, canonical Status, pre-contract exclusion, evidence-backed adoption, correction retention, and target-clean lifecycle; public docs name exact CLI/filename form; git diff contains only declared files plus plan lifecycle artifacts.

**If this fails:** Revert docs/runner registration independently only if suites themselves remain runnable directly. Parser/scaffold parity failure rolls back Step 2, not merely runner entries.

---

## Verification Plan

### Automated Checks

- [ ] `tests/new-projex.test.sh` and `tests/new-projex.test.ps1` each emit exactly one `PASS=N FAIL=0`
- [ ] `tests/projex-tree.test.sh` and `tests/projex-tree.test.ps1` each emit exactly one `PASS=N FAIL=0`
- [ ] Shell syntax succeeds for `new-projex.sh` and `projex-tree.sh`; PowerShell AST parse reports zero errors for `.ps1` peers
- [ ] Exact workflow callsite inventory remains 20 and no old-arity `new-projex` invocation exists
- [ ] Manual creator inventory finds execute log, walkthrough, debug log/doc, sprint nav, orchestration record all routed through scaffold/validator
- [ ] Every scaffold type maps to exactly one canonical initial state; live/virtual `Closed` fixtures fail
- [ ] Registered-root set equals trusted-roots TSV; injected unregistered `.projex` identities are absent from targeted resolution
- [ ] A pre-contract fixture is absent from identity/tree maps, targeted request emits `E_UNGOVERNED_DOCUMENT`, and `--check` emits only its `I_PRECONTRACT_EXCLUDED` record
- [ ] Adoption requires one evidence event before the v1 preamble; its correction chain reconstructs adoption/current Parent; every retired corrected/adopted node has bidirectional correction/retained-record references
- [ ] Targeted tree golden files match normalized shell/PowerShell output; diagnostic order and exit classes match
- [ ] `--check-name`/mint fixtures cover live/live, live/virtual, virtual/virtual, cross-root, same-minute same-normalized-title orchestration collision, distinct-title concurrent orchestration, exclusive no-clobber behavior, and the stable collision diagnostic

### Manual Verification

- [ ] Read SKILL Parent precedence against all 25 document-producing workflow paths; each resolves without judgment/open question
- [ ] Inspect a proposal-shaped doc containing header examples: parser sees one live Parent, never fenced examples
- [ ] Inspect records from concurrent independent and nested runs with meaningfully distinct titles: filenames/query roots are distinct and match `{yymmddhhmm}-{slug}-orchestrate.md`; same-minute same-normalized-title attempts fail without replacing either record
- [ ] Inspect trusted-root registry: only explicit canonical paths participate; planted nested `.projex` does not
- [ ] Inspect a pre-contract document: targeted tree does not present it as governed; `--check` labels its exclusion; a later evidence-backed adoption is the only strict-lineage entry path
- [ ] Inspect archive/conclude handoff before and after deletion: same filename, Parent, full canonical Status, correction references, ancestry
- [ ] Review one Parent correction and one adoption: old/new or none/new, evidence/resolver/date/reason retained and virtual record points back after deletion
- [ ] Confirm auxiliary-only planning/red-team chain leaves all artifacts uncommitted

### Acceptance Criteria Validation

| Criterion | How to Verify | Expected Result |
|---|---|---|
| Bounded live metadata | Duplicate-example fixture + two-live-header fixture | Example accepted; duplicate live field rejected |
| Queryable orchestration roots | Distinct-title concurrent source-less + nested fixture; same-title collision fixture | Distinct `{yymmddhhmm}-{slug}-orchestrate.md` identities and correct trees; same candidate fails `E_ORCHESTRATE_NAME_COLLISION` without clobbering |
| Repo-wide identity | Registered-root `--check-name` + concurrent scaffold fixture | One identity/writer per candidate; deterministic collision handling |
| Trusted root admission | Registered scoped root + planted unregistered duplicate/cycle | Registered content participates; planted root never affects target |
| Canonical Status | Table-driven scaffold + live/virtual invalid-state fixtures | Exact canonical states; `Closed` rejected, never normalized |
| Forward-only boundary | Pre-contract target + `--check` fixture | No tree/compliance claim; targeted `E_UNGOVERNED_DOCUMENT`, explicit exclusion record |
| Evidence-backed adoption | Revise adoption fixture | One valid v1 node only after durable evidence event |
| Reachable corruption loud | Reachable cycle/duplicate/dangling fixtures | Partial tree, sorted stderr, exit 1 |
| Governed retention stability | Archive/conclude lifecycle fixture + unrelated pre-contract document | Target-clean gate recorded; tree identical before/after removal; excluded doc does not block |
| Parent correction durable | Correction/adoption→archive/conclude fixture | Prior/new or none/new Parent and evidence retained with reciprocal IDs |
| Creator coverage | Callsite/manual inventory assertions | 20 standard + 5 manual workflow surfaces covered |
| Cross-platform parity | Compare normalized paired suite artifacts | Same stdout, stderr codes/order, exit values |
| Commit policy preserved | Auxiliary-only smoke + git status | Artifacts present; no new commit |

---

## Rollback Plan

Per-step rollback follows worktree commits; destructive archive/conclude verification must occur before governed source removal.

If whole implementation is abandoned:

1. Run the framework abandon utility against the recorded base/ephemeral branch; do not reset the dirty base checkout.
2. Confirm no temporary `.lineage-locks` files, temp fixture repos, generated ignored artifacts, or partially bound correction/adoption rows remain.
3. Leave this Ready Plan and its uncommitted relationship edits on base for a later attempt; no root registration, correction/adoption row, or governed retention activation is partially retained.

---

## Revision Log

- **2026-08-12:** Kept the accepted filename-only lineage/tree direction; made orchestration run minting collision-safe, mapped and validated canonical Status, bounded trusted `.projex` roots through registration/ownership, added durable Parent-correction evidence, and replaced unconditional lifecycle `--check` with target-local governed retention — trigger: `2608121035-parent-lineage-and-projex-tree-redesign-redteam.md § Remediation / Must Fix` (five required corrections; verdict `Fix Issues`).
- **2026-08-12:** Replaced random-token orchestration naming with `{yymmddhhmm}-{slug}-orchestrate.md`; require exclusive no-clobber reservation and `E_ORCHESTRATE_NAME_COLLISION` for same-minute, same-normalized-title likely duplicate dispatch; distinct concurrent work uses meaningfully distinct titles — trigger: human requirement, “use timestamp-plus-title `-orchestrate.md` filenames without random tokens”; collision is duplicate-dispatch evidence.
- **2026-08-12:** Removed current-corpus migration, manifest, staged legacy quarantine, and associated retention gates. Strict lineage is forward-only; pre-contract documents are excluded until a later `revise-projex` adoption supplies durable Parent evidence — trigger: human requirement, “migration is not needed.”

---

## Notes

### Split Decision

**No split — coupled single scope; auto-suggest threshold accepted.**

Five steps remain one repo/root framework scope. Breaking scaffold arity, registered discovery, creator cutover, correction/adoption ledger, and governed retention requires one clean cutover; splitting creates an invalid intermediate framework.

### Resolved Redesign Decisions

| Adversarial requirement | Decision | Plan location |
|---|---|---|
| Header examples look like real headers | Versioned top-of-file preamble ending blank + `---`; body ignored | Steps 1–2 |
| Global filename identity absent | Filename remains identity; authorized-root live/virtual scan + exclusive reservation | Steps 1–2 |
| Same-minute run collision | Exclusive no-clobber reservation; same normalized title in one minute fails `E_ORCHESTRATE_NAME_COLLISION` as likely duplicate dispatch; genuinely distinct runs use meaningful titles | Steps 1–2 |
| `Orchestrator` unqueryable | Thin stable `{yymmddhhmm}-{slug}-orchestrate.md`; sentinel removed | Steps 1, 4 |
| Noncanonical `Closed` emission | Exhaustive initial-state map; strict live/virtual canonical validation | Steps 1–2 |
| Archive/conclude schema undefined | One strict `projex-lineage-v1` fence grammar for governed removals | Step 4 |
| Unknown historical ancestry | Forward-only boundary; explicit evidence-backed adoption is the sole later entry path | Steps 1–2, 4 |
| Parent edits erase accountability | Append-only correction/adoption events + reciprocal retained-record references | Steps 1, 4 |
| Named `.projex` root poisoning | Bootstrap root + explicit path/owner/date/evidence registry | Steps 1–2 |
| Manual creators drift | Scaffold types + exhaustive 20 standard/5 manual inventory | Steps 3–4 |
| Cross-platform behavior underdefined | Normative roots/symlink/encoding/newline/diagnostic/exit contract + paired fixtures | Steps 2, 5 |
| Poisoned unrelated artifact denies query | Registered physical-root boundary + target-reachable failure scoping | Step 2 |
| Reader-only observability | `--check` explicit governed-corpus-health mode; runners register focused suites | Steps 2, 5 |
| Human suffix decision | Exact orchestration record suffix `-orchestrate.md` | Steps 1, 4 |

### Deviations from Original Proposal

- Remove literal `Orchestrator`; it cannot name a run.
- Use timestamp-plus-title orchestration filenames; same-minute same-normalized-title collision fails as likely duplicate dispatch rather than minting a random alternate name.
- Apply strict Parent parsing only to governed v1 documents. Pre-contract files are explicitly excluded; no inferred ancestry, compatibility default, or corpus rewrite exists.
- Add live preamble version/boundary, registered-root identity reservation, canonical Status validation, target-local error scope, `--check`, correction/adoption ledger, and strict correction-bound virtual records.
- Route manual artifacts and Parent corrections through shared workflow gates instead of relying on prose validation alone.
- Keep filename identity; reject UUID/central registry as needless second identity/source of truth.
- Keep JSON/DOT deferred; no current consumer justifies them.

### Risks

- **Shell/PowerShell scan drift:** High impact. Mitigation: normative behavior + independently executed shared scenarios; parity is acceptance, not inference.
- **Same-minute orchestration collision:** Medium/Low. Exclusive reservation never clobbers; `E_ORCHESTRATE_NAME_COLLISION` identifies likely duplicate dispatch, and genuinely distinct runs must use meaningfully distinct titles.
- **Exclusive lock leakage after crash:** Medium/Low. Stale lock fails loud and is never stolen; cleanup trap/finally + fixture proves normal cleanup.
- **Unrecognized pre-contract ancestry:** Medium. Strict tooling labels it excluded and never guesses; later adoption requires durable evidence.
- **Archive transitional duplicate:** High if misclassified. Exact Source/Parent/full Status/correction equivalence is the only allowed duplicate; mismatch blocks governed deletion.
- **Silent Parent correction:** High/Medium. Revise requires atomic evidence event; reader and lifecycle gates reconstruct correction chain and block missing evidence.
- **Root registration abuse:** High/Low. Only canonical bootstrap registry admits paths; each row carries owner/date/evidence and requires explicit review; unregistered content never resolves.
- **Workflow added without scaffold:** Medium. SKILL creator contract + inventory assertion/test update requirement.
- **Auxiliary record branch visibility:** Medium. Explicit execute/close chain must include run record in prerequisite commit; auxiliary-only chains remain uncommitted.

### Open Questions

None.
