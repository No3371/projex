# Parent Lineage and Projex Tree Redesign

> **Status:** Ready
> **Author:** OpenAI Codex (Agent)
> **Parent:** 2608120933-parent-lineage-header-and-projex-tree-utility-proposal.md
> **Source:** 2608120933-parent-lineage-header-and-projex-tree-utility-proposal.md — direction accepted by direct request; proposal header remains Draft by design
> **Related Projex:** 2608120933-parent-lineage-header-and-projex-tree-utility-proposal.md | 2608120952-parent-lineage-header-and-projex-tree-utility-redteam.md | 2608121003-parent-lineage-header-and-projex-tree-utility-proposal-stress.md | 2608121035-parent-lineage-and-projex-tree-redesign-redteam.md | 2604031730-util-script-ideas-imagine.md | 2604031727-workflow-guardrails-determinism-imagine.md
> **Worktree:** Yes

---

## Summary

Land a causal lineage contract that survives orchestration, lifecycle removal, legacy migration, and cross-platform parsing. Replace anonymous `Orchestrator` roots with collision-safe thin `{yymmddhhmm}-{name}-{token}-orchestrate.md` run records; bound live metadata to a versioned top-of-file block; reserve filename identity across explicitly registered `.projex` roots; retain removed nodes and Parent-correction evidence in versioned grammars; provide targeted `projex-tree` reads plus strict `--check`; migrate legacy evidence through an auditable manifest without inventing `User` ancestry.

**Scope:** Root Projex framework distribution: core/workflow specs, paired scaffold/tree scripts, focused behavioral suites, public utility inventories, root-registration and correction ledgers, and current root `.projex/` corpus. One repo; root `.projex/` is the only initially authorized lineage root.
**Estimated Changes:** 2 new utilities, 2 scaffolders, 27 framework/workflow specs, 7 test files, 3 public docs, 3 governance TSVs, current 66-document corpus. Six coupled implementation steps.

---

## Objective

### Problem / Gap / Need

Current framework has topical and type-specific links but no universal causal edge. Original strict-Parent proposal chose the right tree abstraction, yet adversarial reports show its implementation contract is unsafe: line-regex parsing reads fenced examples as headers; filename identity and orchestration record minting collide; `Orchestrator` merges unrelated runs; scaffolding emits noncanonical `Closed`; archive/conclude retention has no schema or quarantine-compatible gate; Parent corrections erase evidence; name-only `.projex` discovery permits poisoning; one legacy defect can deny all queries; handwritten creators can bypass the field; no proactive integrity mode or migration evidence trail exists.

The redesign must preserve what held: one causal Parent distinct from `Related Projex`; filename-only stable references; deterministic sibling order; hard scaffold cutover; paired shell/PowerShell behavior; visible cycle/dangling diagnostics. It must not mistake the proposal's retained Draft header for unresolved human intent: this Plan is authorized to implement the direction after applying the red-team/stress fixes and settled `-orchestrate.md` suffix.

### Success Criteria

- [ ] Every newly created projex document has one bounded metadata preamble beginning `> **Projex Metadata:** 1`, followed immediately by exactly one `> **Parent:** User|{projex-filename}.md`; body examples never count as headers
- [ ] Source-less and nested orchestration runs mint distinct thin `*-{24-lowercase-hex}-orchestrate.md` records via 96-bit CSPRNG tokens, exclusive reservation, and at most eight fresh-token attempts; top-level dispatched artifacts parent to their run record; execution logs/walkthroughs retain plan parentage
- [ ] `new-projex.{sh,ps1}` require Parent with no compatibility default, reject invalid/unresolved parents, map every scaffold type to a canonical lifecycle Status, reserve full filenames across authorized live/virtual roots, and cannot both win one candidate during a cross-platform race
- [ ] `projex-tree.{sh,ps1}` implement identical registered-root discovery, bounded parsing, canonical live/virtual Status validation, virtual-record parsing, targeted subtree output, deterministic diagnostics/exit classes, `--check`, and `--check-name`; unregistered nested `.projex` roots never contribute identities
- [ ] Targeted queries return a valid requested subtree despite unrelated legacy quarantine/corruption; corruption affecting the target or its reachable descendants returns partial output plus nonzero; `--check` reports the whole authorized corpus
- [ ] Archive and conclude preserve deleted nodes in the same `projex-lineage-v1` record grammar, bind any Parent-correction IDs, validate live→virtual handoff before deletion, and preserve ancestry/evidence afterward
- [ ] All 20 current `new-projex` workflow call sites supply deterministic Parent; orchestrate, execute, close, debug, and sprint manual writers route through the scaffold or an equivalent shared validation gate
- [ ] Migration manifest covers every discovered current document (66 at planning time, adjusted only for files created before execution), records evidence/confidence/resolver/disposition, and never maps missing evidence to `User`; later Parent changes append complete correction evidence before metadata changes
- [ ] Archive/conclude remain unavailable until manifest coverage is complete; afterward a scoped-quarantine gate permits only target-clean transitions when global defects exactly equal recorded unrelated quarantine, and records the accepted quarantine snapshot
- [ ] Shared shell/PowerShell fixtures cover bounded examples, CRLF/BOM, symlinks, registered/unregistered roots, nested repos/worktrees, concurrent run-token collisions, canonical/noncanonical Status, cycles, dangling parents, correction→retention, virtual handoff under quarantine, diagnostic ordering, and exit classes
- [ ] `README.md`, `AGENTS.md`, and `CLAUDE.md` expose the new utility/identity/root-registration contract; `USAGE.md` and `AUTHORING.md` remain unchanged after confirmed absence of relevant utility/header inventories
- [ ] Auxiliary proposal/plan/eval/review/redteam/stress/etc. artifacts remain no-auto-commit; this Plan and its relationship edits are not committed by planning

### Out of Scope

- Traversing `Related Projex`, `Source`, `Nav`, `Sprint`, commit trailers, or arbitrary filename references as tree edges
- JSON/DOT output, ancestor queries, graph visualization, daemon/index service, or a central mutable child registry
- Reconstructing lineage from remote systems or deleted git history during normal tree reads
- Rewriting historical commits or assigning unsupported legacy provenance to make strict checks green
- Changing lifecycle meanings beyond replacing noncanonical scaffold output with the existing canonical vocabulary; no new lifecycle state is introduced
- Auto-committing this Plan, its source proposal, adversarial reports, or any other auxiliary artifact

---

## Context

### Current State

- `SKILL.md § Authoring` defines filename-only references but no Parent or bounded metadata block. Orchestration explicitly says it has no standalone document.
- `new-projex.sh` and `.ps1` accept `<repo-root> <type> <title> [<projex-dir>]`, emit Status/Author/Related only, reject only the exact target path, and emit noncanonical `Closed` for born-closed types. Supported types omit orchestrate, sprint, and walkthrough. Generic `log` is marked born-closed although execution logs live beside active plans.
- Exactly 20 workflow specs call `new-projex`: `archive-projex.md`, `audit-projex.md`, `coach-projex.md`, `conclude-projex.md`, `define-projex.md`, `eval-projex.md`, `explore-projex.md`, `guide-projex.md`, `imagine-projex.md`, `interview-projex.md`, `memo-projex.md`, `navigate-projex.md`, `patch-projex.md`, `plan-projex.md`, `preplan-projex.md`, `propose-projex.md`, `redteam-projex.md`, `review-projex.md`, `scan-projex.md`, `stress-projex.md`.
- Manual writers: `execute-projex.md` creates active `-log.md`; `close-projex.md` creates closed `-walkthrough.md`; `debug-projex.md` creates active `-debug-log.md` and closed `-debug.md`; `sprint-projex.md` creates active `-sprint.md`; `orchestrate-projex.md` creates no artifact.
- `archive-projex.md` retains Filename/Title/Date/Type/Outcome/Summary/Touched/Keywords/Related as free-form Markdown. `conclude-projex.md` retains source filename + disposition in a prose successor ledger. Neither preserves a parseable Parent edge, correction reference, or quarantine-compatible removal gate.
- Current corpus: 66 Markdown documents under root `.projex/`: 18 active, 47 closed, 1 abandoned. The proposal/red-team/stress artifacts already use live Parent lines; most older documents have none. No trusted-root registry, Parent-correction ledger, or archive/conclude virtual-node contract exists.
- Tests cover close/precheck safety. `tests/run-all.sh` lists 5 suites; `.ps1` lists 4. No `new-projex` or lineage suite exists. Test convention: isolated temp repos, observable assertions, one `PASS=N FAIL=N` summary, independent shell/PowerShell logic.
- Public docs: `README.md` has a utility table; `AGENTS.md`/`CLAUDE.md` have repository trees and filename-uniqueness guidance. `USAGE.md`/`AUTHORING.md` have no matching utility/header inventory.

### Key Files

| File(s) | Role | Change Summary |
|---|---|---|
| `SKILL.md` | Canonical framework contract | Versioned live preamble, Parent semantics/precedence, canonical Status mapping, registered-root trust boundary, virtual retention, Parent-correction governance, phased migration, orchestration-record policy |
| `orchestrate-projex.md` | Per-run user-level coordinator | Collision-safe thin `-orchestrate.md` minting; pass its filename as parent to dispatched roots; nested parentage; commit-policy handling |
| `new-projex.sh`, `new-projex.ps1` | Creation enforcement | Required Parent; canonical Status by type; new/manual types; authorized-root identity scan; exclusive candidate reservation; tokenized orchestration minting; versioned header emission |
| `projex-tree.sh`, `projex-tree.ps1` | New read-only utility | Registered-root discovery/parser/index/tree/check contract with parity; correction and lifecycle-gate validation |
| `.projex/trusted-roots-v1.tsv` | Root admission policy | Canonical root plus explicit repo-relative scoped-root registrations, owners, dates, evidence |
| 20 scaffold-calling `*-projex.md` specs | Standard artifact creators | Parent selection, new argument, header preservation, readiness checks |
| `execute-projex.md`, `close-projex.md`, `debug-projex.md`, `sprint-projex.md` | Manual creators | Route log/walkthrough/debug/sprint docs through scaffold and assign internal lineage |
| `orchestrate-projex.md`, `archive-projex.md`, `conclude-projex.md`, `revise-projex.md` | Identity/lifecycle governance | Run minting; correction logging; scoped-quarantine gate; correction-bound virtual records before removal |
| `.projex/parent-lineage-migration-v1.tsv` | Migration decision trail | One row per physical legacy doc; evidence/confidence/resolver/disposition |
| `.projex/parent-lineage-corrections-v1.tsv` | Durable correction trail | Append-only correction events plus one-time retained-record binding |
| `.projex/**/*.md` | Current corpus | Add bounded metadata + evidence-backed Parent where resolved; leave unsupported rows quarantined, never fabricated |
| `tests/new-projex.test.{sh,ps1}` | Scaffold contract | Argument/header/type/identity/reservation behavior |
| `tests/projex-tree.test.{sh,ps1}` | Reader/integrity contract | Shared scenario matrix and exact output/exit assertions |
| `tests/run-all.{sh,ps1}`, `tests/README.md` | Test integration | Register/document both paired suites |
| `README.md`, `AGENTS.md`, `CLAUDE.md` | Public/agent inventory | Utility, suffix, filename identity, Parent summary |

### Dependencies

- **Requires:** Accepted direction from direct request; adversarial requirements in `2608120952-parent-lineage-header-and-projex-tree-utility-redteam.md`, `2608121003-parent-lineage-header-and-projex-tree-utility-proposal-stress.md`, and five Must Fix findings in `2608121035-parent-lineage-and-projex-tree-redesign-redteam.md`; settled orchestration suffix `-orchestrate.md`.
- **Blocks:** Reliable orchestration-run subtree queries; future `projex-refs` graph work and additional scoped-root registrations may reuse discovery but are not part of this Plan.
- **Execution order:** Contract → paired parser/tree + root registry → scaffold cutover → workflow/manual creators + retention/correction rules (retention inactive) → corpus manifest migration + retention activation → docs/integration verification.

### Constraints

- Filename is immutable identity. Orchestration's 96-bit token is part of its filename slug, not a second stored identifier; no separate UUID or central child registry.
- Parent is causal only. Top-level artifact dispatched by orchestration uses the run record; internal execution artifacts use their workflow source (`plan` or `debug-log`). Type-specific provenance remains intact.
- Trusted discovery bootstrap: canonical `<repo-root>/.projex` only. Additional roots participate only when their canonical repo-relative path has one committed `.projex/trusted-roots-v1.tsv` row with owner/date/evidence; symlinked paths, `.git`, `.projexwt`, nested repositories, unregistered `.projex` directories, and paths escaping repo are excluded.
- Live parser reads only a versioned preamble: first `# ` heading, blank line, `> **Projex Metadata:** 1`, immediate Parent line, remaining unique blockquote metadata, blank line, `---`. Text/fences after the separator are never metadata.
- Status uses SKILL's exact canonical state plus optional outcome. Live/virtual parsers reject `Closed` and every other noncanonical state; they never normalize. Transitional handoff compares the full Status text exactly.
- Virtual parser reads only `projex-lineage-v1` fences under `## Lineage Records` in files ending `-archive.md` or `-conclude.md`.
- No compatibility default for missing Parent on new creation. Legacy exceptions live only in the migration manifest/quarantine path.
- A Parent change after initial creation/migration is valid only with an atomic `revise-projex` correction-ledger row. Lifecycle removal binds every applicable correction ID into the retained virtual record before deletion.
- Archive/conclude activation requires a complete migration manifest. Recorded scoped-quarantine mode may tolerate only global defects that exactly equal unrelated manifest quarantine; target/reachable defects and unrecorded global defects always block.
- Auxiliary artifact commit policy remains authoritative. A chain that explicitly enters execute/close may commit its required plan + orchestration record together as an execution prerequisite; auxiliary-only chains do not gain implicit commit permission.
- Worktree mode: Yes because base working directory is dirty; implementation creates many files and may coexist with other activity.

### Assumptions

- Full filename identity remains practical because names already carry time + slug + type; orchestration adds 96-bit filename entropy solely to distinguish concurrent runs. Repo-wide reservation across registered roots closes the actual gap without adding a second identifier.
- A strict Markdown preamble plus type-scoped virtual fences is implementable in both Bash and PowerShell without a general Markdown parser.
- Target-local error scoping provides useful reads during migration while `--check` remains the explicit global health gate; exact manifest comparison makes scoped retention auditable rather than a bypass.
- Current 66-document count is a planning snapshot. Execution must discover again and make manifest row count equal discovered physical documents before asserting coverage or enabling retention.

### Impact Analysis

- **Direct:** every future document creation, orchestration run, Parent correction, lifecycle archive/conclude operation, and lineage query.
- **Adjacent:** execute/close/debug/sprint state artifacts; authorized-root registration; auxiliary relationship edits; test runners; public utility inventory.
- **Downstream:** repos syncing this framework must migrate all `new-projex` calls atomically, create their canonical root registry, and satisfy manifest coverage before retention; scripts reject old arity. Existing legacy docs remain readable through quarantine-aware targeted mode until resolved.
- **Failure containment:** unregistered roots never enter identity resolution; malformed unrelated authorized legacy docs affect `--check`, not valid target queries; duplicate identity or cycle on the reachable target remains fatal and visible.

---

## Implementation

### Overview

Six steps form one clean cutover. Step 1 fixes semantics and creates queryable run roots. Step 2 implements the single registered-root discovery/parser contract twice and makes scaffold identity/Status enforcement consume it. Step 3 migrates every standard creator. Step 4 closes manual-writer, Parent-correction, and destructive-retention gaps but keeps removal inactive pending manifest coverage. Step 5 performs auditable phased corpus migration and activates scoped-quarantine retention. Step 6 integrates docs/tests and proves parity. No step introduces a second lineage convention.

### Step 1: Canonical Contract and Queryable Orchestration Roots

**Objective:** Freeze all redesign decisions before scripts/workflows consume them.
**Confidence:** High
**Depends on:** None
**Verify-Projex:** Required

**Files:**
- `SKILL.md`
- `orchestrate-projex.md`

**Changes:**

1. Add `SKILL.md § Parent Lineage` under Authoring with the exact live preamble:

```markdown
# [Title]

> **Projex Metadata:** 1
> **Parent:** User | {yymmddhhmm}-{name}-{type}.md
> **Status:** [when the type carries lifecycle status]
> [...unique type-specific metadata]

---
```

Define: marker/Parent ordering; blank + `---` terminator; no duplicate metadata keys; filename grammar `^[0-9]{10}-[a-z0-9][a-z0-9-]*-[a-z0-9]+\.md$`; no `Orchestrator` sentinel; no paths/self-parent; causal-vs-topical boundary; registered-root identity; live/virtual handoff; targeted vs `--check`; quarantine semantics.
2. Define deterministic Parent precedence:
   1. internal artifact's source-of-record (execution log/walkthrough → plan; final debug doc → debug log);
   2. orchestrator/sprint `parent=` handoff for a dispatched root;
   3. single referenced source/target;
   4. first explicit target left-to-right for multi-target workflows;
   5. `User` only when direct human instruction has no source projex.
   Remaining inputs stay in existing Source/Subject/Nav/Sources/Related fields.
3. Define canonical initial scaffold Status by type: `Draft` = propose|plan|eval|redteam|stress|audit|interview|coach|memo|define|map|imagine; `In Progress` = review|explore|navigate|log|sprint|orchestrate; `Complete` = patch|preplan|debug|scan|guide|conclude|archive|walkthrough. Workflow transitions may replace these only with another canonical state/outcome. `Closed` is invalid data, never an alias.
4. Define root admission: root `.projex` is bootstrap-authorized; every additional scoped root needs an exact row in `.projex/trusted-roots-v1.tsv` (`path	owner	added	evidence`). Registration changes require explicit human/repo-owner review; scanners ignore unregistered content for identity/tree resolution and report its directory only during `--check`.
5. Define Parent corrections: `revise-projex` appends one `.projex/parent-lineage-corrections-v1.tsv` event before/atomically with each live Parent edit; migration's initial assignment stays in the migration manifest. Lifecycle records reference correction IDs and bind them to the retaining archive/conclude artifact.
6. Revise SKILL orchestration description: orchestration has a thin record, not a new analytical type. Filename suffix fixed to `-orchestrate.md`; every run filename includes a 24-lowercase-hex CSPRNG token immediately before the suffix.
7. In `orchestrate-projex.md`, create the run record before first dispatch through the scaffold's orchestrate mint mode; update it only at dispatch completion/escalation. Template contains metadata, Status, verbatim goal, literal chain/model annotations, final outcome, and child filenames returned. No copied subagent reports.
8. Root record Parent: referenced source-of-record when orchestration is invoked against one; otherwise `User`. Nested record Parent: outer `-orchestrate.md`. Every directly dispatched document-producing workflow receives `parent={run-record-filename}`. Non-document subworkflows remain untouched.
9. Preserve auxiliary commit policy explicitly: record and auxiliary children are presented uncommitted for auxiliary-only chains. If explicit chain includes execute/close, commit the record with the required plan prerequisite so worktree branches can resolve Parent; no standalone implicit auxiliary commit.

**Rationale:** A per-run file with filename-embedded entropy is the smallest stable identity that makes concurrent and nested runs queryable. A literal sentinel or one-winner minute slug cannot. Registered roots prevent directory-name trust. Preamble version/boundary prevents examples in this proposal/plan from becoming headers.

**Verification:** Focused spec inspection: every Parent case maps to one precedence row; canonical status table covers every scaffold type once; two concurrent source-less and two concurrent nested same-goal runs each yield distinct queryable filenames; nested example forms `outer orchestrate → inner orchestrate → child`; unregistered roots never resolve; no `Parent: Orchestrator` remains in normative text except rejected-history discussion.

**If this fails:** Revert both specs together. Do not implement a parser against ambiguous semantics.

---

### Step 2: Paired Reader, Identity Gate, and Scaffold Cutover

**Objective:** Implement one normative discovery/parser behavior in both platforms and make all creation pass through it.
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

Exit `0`: requested operation valid; `1`: lineage/integrity failure; `2`: usage, invalid root, path input, or unsupported encoding. Diagnostics sort by filename then stable code; stdout tree siblings sort filename ascending.
2. Read root registrations only from canonical root `.projex/trusted-roots-v1.tsv`. Validate exact TSV schema, canonical repo-relative `.projex` paths, unique paths, and owner/date/evidence values; reject symlinks, exclusions, nested repos, and escapes. Root `.projex` is always present as the sole bootstrap row. Targeted mode ignores unregistered `.projex` trees completely; `--check` emits sorted `E_UNREGISTERED_ROOT` diagnostics without parsing their files.
3. Parse UTF-8 with optional BOM and LF/CRLF identically. Reject invalid byte sequences. Parse only live preamble and canonical virtual blocks; validate Status with the strict SKILL regex + canonical state set and reject `Closed` without normalization. Build identity map + Parent→children map. `Related Projex` and header-shaped body/fence lines are ignored.
4. Targeted mode validates requested identity and reachable descendants. Unrelated malformed/quarantined authorized nodes produce one deterministic summary warning and do not change exit `0`; reachable duplicate/cycle/malformed/dangling state prints partial tree, detailed stderr, exit `1`. `--check` emits every sorted authorized-corpus/registration/correction defect and exits `1` on any. `--check-name` checks grammar and absence across authorized physical/virtual identities without requiring legacy Parent completeness.
5. Change scaffold signature cleanly:

```text
new-projex.{sh|ps1} <repo-root> <type> <title> <parent> [<projex-dir>]
```

Validate Parent grammar; resolve filename parent uniquely through `projex-tree --check-name`/identity scan; reject User when a caller supplied a source parent; emit metadata marker + Parent + the Step 1 canonical initial Status; no old-arity fallback.
6. Add scaffold types needed by manual writers: `orchestrate → orchestrate` (active), `sprint → sprint` (active), `walkthrough → walkthrough` (born closed). Make generic `log` active; use title `{debug-name}-debug` for `-debug-log.md`; make final `debug` born closed. Preserve unrelated suffix mappings.
7. Orchestrate mint mode generates a fresh 96-bit CSPRNG value rendered as exactly 24 lowercase hex chars and computes `{stamp}-{slug}-{token}-orchestrate.md`. Acquire the canonical-root per-candidate lock, run authorized-root `--check-name`, and exclusively create. On candidate collision, release only the owned lock and retry with fresh entropy; maximum eight attempts, then stable `E_NAME_MINT_EXHAUSTED` with no artifact. Paired fixtures set `PROJEX_TEST_MODE=1` plus comma-separated `PROJEX_TEST_MINT_TOKENS`; either variable alone is usage error, each token must match `[0-9a-f]{24}`, exhaustion is deterministic, and production never reads an injected sequence.
8. Other types retain `{stamp}-{slug}-{suffix}.md`. Reserve each computed filename across authorized scopes before write. Both variants exclusively create the same per-filename lock under canonical root `.projex/.lineage-locks/`, run `--check-name`, create with exclusive/no-clobber semantics, and remove the owned lock in trap/finally. Existing/stale lock fails loud; never steal it. Remove empty lock dir best-effort. Scanner ignores this non-Markdown internal dir.
9. Define virtual handoff collision: one live + one virtual record with identical Filename/Parent/full canonical Status and virtual Source equal to live repo-relative path is a transitional pair; reader prefers live and warns. Any mismatch or >2 instances is an error. After deletion virtual record becomes sole identity.

**Rationale:** Filename identity keeps existing reference conventions; registered-root scan + exclusive reservation fixes sequential/concurrent collision, while per-run entropy lets every valid orchestration obtain a root. Canonical Status makes live→virtual equality meaningful. Tree utility owns discovery semantics so scaffold cannot drift into a second parser.

**Verification:** Run only the four focused suites. Required observable cases: invalid/missing Parent; every scaffold type emits its mapped canonical state; `Closed` live/virtual rejected; body examples accepted; two live headers rejected; concurrent same-minute same-goal source-less and nested orchestrations both mint distinct roots even when their first injected candidate collides; cross-root sequential/concurrent creation allows one winner per non-orchestrate candidate; unregistered duplicate/cycle roots cannot affect a target and make `--check` report only their directory; live/virtual mismatch rejected; target query survives unrelated malformed doc; reachable cycle returns partial output/exit 1; `.sh`/`.ps1` stdout/stderr/exit match byte-for-byte after newline normalization.

**If this fails:** Remove both new utilities and restore both scaffolders as one rollback unit. Do not migrate workflow arity until parity passes.

---

### Step 3: Migrate All Standard Document-Creating Workflows

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

**Rationale:** A hard scaffold signature without atomic caller migration breaks all authoring. Per-workflow local rules prevent agents from improvising multi-source ancestry.

**Verification:** Exact callsite search returns 20 invocations and each has five operands including Parent; every template includes/retains version + Parent; no workflow names `Orchestrator` as a Parent value; no open-ended “choose a parent” text remains.

**If this fails:** Restore all 20 specs together. Partial arity migration is invalid.

---

### Step 4: Close Manual-Creator and Lifecycle-Retention Gaps

**Objective:** Ensure every nonstandard artifact and every destructive lifecycle transition preserves lineage.
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
6. `revise-projex.md`: any post-creation/migration Parent change requires one atomic target+ledger commit. Append TSV columns `correction_id	date	filename	prior_parent	new_parent	evidence	resolver	reason	retained_record`; ID is `pc-` + 24 lowercase hex, evidence is a durable repo-relative/file-name locator or quoted human requirement, and `retained_record` starts blank. Refuse missing values, prior/current mismatch, repeated ID, or a second mutation not chained from the last row. Correction rows are append-only; only blank→`{archive|conclude filename}#{source filename}` retained-record binding is allowed before removal.
7. Add one virtual grammar to both archive and conclude:

```projex-lineage-v1
Filename: 2601011200-example-plan.md
Parent: User
Status: Complete
Source: .projex/closed/2601011200-example-plan.md
Disposition: Archived
Correction-Refs: none
```

Fields/order exact; Filename is immutable identity; Parent uses live grammar; Status uses full canonical text; Source is repo-relative; Disposition is `Archived|Concluded`; Correction-Refs is `none` or sorted comma-separated correction IDs. Blocks occur only under `## Lineage Records`.
8. Archive extraction adds Parent + Correction-Refs and writes one record per source. Conclude report writes one per retired source; successor prose ledger remains human-facing. Before removal, bind every applicable correction ledger row to the retaining record, then validate record IDs, old→new chain, final Parent, source, and full Status. Missing/unbound/mismatched correction evidence blocks deletion.
9. Lifecycle activation is deferred until Step 5 proves the migration manifest exactly covers the authorized physical corpus. Thereafter every removal first runs global `--check`. Exit `0` selects `Global-Clean`; exit `1` may select `Scoped-Quarantine` only when the complete sorted diagnostic set equals manifest-declared unrelated quarantine and each source/descendant targeted check is clean except exact transitional-pair warnings. Any target-reachable quarantine, unregistered root, correction/registration defect, or extra diagnostic blocks.
10. Archive/conclude artifacts record `Lineage Gate: Global-Clean|Scoped-Quarantine`, migration-manifest SHA-256, sorted source filenames, sorted accepted quarantine filenames, check timestamp/resolver, and pre/post normalized targeted-tree hashes. Delete only after preflight record exists; run targeted checks after deletion and require hashes/ancestry unchanged. No manual flag or undocumented bypass.
11. Update creator inventory in SKILL/quality gates: future workflow adding a document must use `new-projex` or add a focused test proving identical metadata validation.

**Rationale:** Manual creators and removal paths are predictable drift points. One scaffold, correction ledger, scoped-but-recorded quarantine gate, and correction-bound virtual grammar preserve availability without sacrificing attribution or deletion proof.

**Verification:** Focused temp-repo scenarios: plan→log→walkthrough tree; orchestrate→plan and orchestrate→redteam siblings; outer→inner orchestrate; sprint→body artifact; debug-log→debug; archive child then conclude parent; all-virtual chain; ancestry/output identical before/after source deletion; valid archive and conclude each succeed in `Scoped-Quarantine` with one unrelated manifest quarantine; target-related or unrecorded defect blocks; Parent correction→archive and correction→conclude preserve old/new/evidence/resolver/date/reason plus mutual correction/retained-record references.

**If this fails:** Do not delete any source document. Revert workflow specs and generated fixture records; physical originals remain authoritative.

---

### Step 5: Evidence-Backed Current-Corpus Migration

**Objective:** Introduce lineage without fabricating history or blocking useful target queries.
**Confidence:** Medium
**Depends on:** Steps 1–4
**Verify-Projex:** Required

**Files:**
- `.projex/parent-lineage-migration-v1.tsv` (new)
- `.projex/parent-lineage-corrections-v1.tsv` (created in Step 4; validated here)
- every discovered authorized `.projex/**/*.md` physical document requiring metadata migration (66 at planning time; execution snapshot is authoritative)

**Changes:**

1. Create UTF-8 TSV with one row per authorized physical document and columns:

```text
filename	path	parent	evidence	confidence	resolver	disposition
```

`disposition=resolved|quarantined`; blank Parent only for quarantined; confidence `high|medium|none`; resolver stable agent/human identity; no tabs/newlines inside values.
2. Apply evidence ladder in order: existing bounded/live Parent; explicit type field (`Source Plan`, `Source`, `Subject`, `Successor`, `Nav`, `Sprint`) with one causal target; plan/log/walkthrough/debug stem + explicit cross-link; document creation/relationship record; git/session history; recorded human decision. `Related Projex` alone is never sufficient. A unique higher tier wins; conflicting same-tier or no evidence → quarantine.
3. For resolved rows, insert marker + Parent into the top preamble and normalize only the boundary needed for parser acceptance. Preserve canonical lifecycle status, prose, dates, and topical fields; replace legacy `Closed` only when evidence proves the canonical equivalent `Complete`.
4. For quarantined rows, preserve document bytes and record why evidence failed. Never write Parent User/another filename as a placeholder. Targeted reader reports aggregate quarantine warning; `--check` reports each row nonzero.
5. Reconcile the four current lineage artifacts explicitly: proposal Parent User; first red-team, stress, and this Plan Parent proposal; Plan-red-team Parent this Plan. Record planning-time relationship decisions in manifest rather than relying on current unversioned lines.
6. Validate corrections ledger header even when it has zero events. For any Parent changed after its manifest assignment, require a chronological correction chain from manifest Parent to live Parent; the migration row is immutable baseline, not edited to hide a correction.
7. After migration, assert authorized physical discovered filename/path set exactly equals manifest filename/path set; no duplicate basename across registered paths; every resolved row's file Parent equals manifest Parent followed by its correction chain; every absent Parent has one quarantined row; no unmanifested legacy exception.
8. Mark retention contract active only after these assertions pass and are committed on the execution branch. Quarantines remain permitted debt; incomplete coverage does not.

**Rationale:** Quarantine is an explicit phased state, not a fake Parent vocabulary value. It keeps target reads and scoped lifecycle transitions available while preserving initial and later attribution evidence.

**Verification:** Run `projex-tree --check` and compare diagnostics exactly to quarantined rows; query at least one resolved root whose unrelated quarantine exists and expect exit 0; perform one archive and one conclude in scoped mode and verify recorded manifest/quarantine hashes; sample one migration decision from each used evidence tier; mutate one fixture Parent without a correction row and prove checks/removal fail.

**If this fails:** Revert only corpus headers + governance TSVs. New-creation enforcement and targeted utility remain valid, but retention stays inactive; do not loosen Parent/Status grammar or relabel unknown roots.

---

### Step 6: Public Docs, Test Registration, and End-to-End Contract Proof

**Objective:** Make the contract discoverable and prevent cross-platform/workflow drift.
**Confidence:** High
**Depends on:** Steps 1–5
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

1. README utility table adds `projex-tree`; `new-projex` row states required Parent, canonical Status, registered-root identity, and tokenized orchestration minting. Add one compact orchestration-record note with exact `-orchestrate.md` suffix.
2. AGENTS/CLAUDE mirrored repository trees add `new-projex`, `projex-tree`, and root/correction registry files; filename guidance changes from convention-assumed uniqueness to enforced repo-wide authorized live/virtual identity; Parent references stay filename-only.
3. Register `new-projex.test` and `projex-tree.test` once in each runner; preserve one-summary parsing. Document assertion counts and scenario coverage in tests README after actual runs.
4. Keep `USAGE.md`/`AUTHORING.md` unchanged; record verification that neither contains a utility/header inventory requiring update.
5. Run focused suites individually, not the project-wide runners during implementation verification. Also run Bash syntax parse and PowerShell AST parse only for the four changed/new scripts.
6. Execute end-to-end smoke in one throwaway repo: concurrently mint two same-goal source-less and two same-goal nested orchestrations with a forced first-token collision; create children; query each tree; register one scoped root; inject an unregistered duplicate root and prove it cannot affect the target; remove that injected root and prove its sole `--check` error clears; correct one Parent with evidence; archive one child under unrelated manifest quarantine; conclude one ancestor; re-query; verify correction IDs survive, targeted output stays stable, and remaining `--check` failures exactly match recorded quarantine.

**Rationale:** Shared fixtures and independently executed platform suites are the parity contract. Public inventory prevents a correct utility or governance gate from remaining undiscoverable.

**Verification:** Focused suites exit 0 with one summary each; normalized golden stdout/stderr/exit records match across platforms; smoke proves concurrent minting, root admission, canonical Status, correction retention, and scoped-quarantine lifecycle; public docs name exact CLI/suffix; git diff contains only declared files plus plan lifecycle artifacts.

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
- [ ] Manifest filename/path set equals fresh authorized physical discovery; resolved/quarantined partition has no third state; retention is active only after equality
- [ ] Correction chain reconstructs manifest/creation Parent → current Parent; every retired corrected node has bidirectional correction/retained-record references
- [ ] Targeted tree golden files match normalized shell/PowerShell output; diagnostic order and exit classes match
- [ ] `--check-name`/mint fixtures cover live/live, live/virtual, virtual/virtual, cross-root, same-minute concurrent same-goal orchestration, and forced first-token collision

### Manual Verification

- [ ] Read SKILL Parent precedence against all 25 document-producing workflow paths; each resolves without judgment/open question
- [ ] Inspect a proposal-shaped doc containing header examples: parser sees one live Parent, never fenced examples
- [ ] Inspect records from two concurrent independent and two concurrent nested same-goal runs: all filenames/query roots are distinct and end `-orchestrate.md`
- [ ] Inspect trusted-root registry: only explicit canonical paths participate; planted nested `.projex` does not
- [ ] Inspect archive/conclude handoff before and after deletion: same filename, Parent, full canonical Status, correction references, ancestry
- [ ] Review every quarantined migration row: evidence explanation present; no fallback User assignment
- [ ] Review one Parent correction: old/new/evidence/resolver/date/reason retained and virtual record points back after deletion
- [ ] Confirm auxiliary-only planning/red-team chain leaves all artifacts uncommitted

### Acceptance Criteria Validation

| Criterion | How to Verify | Expected Result |
|---|---|---|
| Bounded live metadata | Duplicate-example fixture + two-live-header fixture | Example accepted; duplicate live field rejected |
| Queryable orchestration roots | Concurrent same-goal source-less + nested forced-collision fixture | Four distinct tokenized `-orchestrate.md` identities and correct trees |
| Repo-wide identity | Registered-root `--check-name` + concurrent scaffold fixture | One identity/writer per candidate; deterministic collision handling |
| Trusted root admission | Registered scoped root + planted unregistered duplicate/cycle | Registered content participates; planted root never affects target |
| Canonical Status | Table-driven scaffold + live/virtual invalid-state fixtures | Exact canonical states; `Closed` rejected, never normalized |
| Useful phased reads | Valid target + unrelated quarantine fixture | Complete target tree, exit 0, one summary warning |
| Reachable corruption loud | Reachable cycle/duplicate/dangling fixtures | Partial tree, sorted stderr, exit 1 |
| Retention stable under quarantine | Archive/conclude lifecycle fixture + unrelated quarantined row | Scoped gate recorded; tree identical before/after removal |
| Parent correction durable | Correction→archive/conclude fixture | Prior/new Parent and evidence retained with reciprocal IDs |
| Creator coverage | Callsite/manual inventory assertions | 20 standard + 5 manual workflow surfaces covered |
| Migration accountable | Manifest/file set comparison + sample audit | Every authorized physical doc resolved or quarantined with evidence |
| Cross-platform parity | Compare normalized paired suite artifacts | Same stdout, stderr codes/order, exit values |
| Commit policy preserved | Auxiliary-only smoke + git status | Artifacts present; no new commit |

---

## Rollback Plan

Per-step rollback follows worktree commits; destructive archive/conclude verification must occur before source removal.

If whole implementation is abandoned:

1. Run the framework abandon utility against the recorded base/ephemeral branch; do not reset the dirty base checkout.
2. Confirm no temporary `.lineage-locks` files, temp fixture repos, generated ignored artifacts, or partially bound correction rows remain.
3. Leave this Ready Plan and its uncommitted relationship edits on base for a later attempt; no legacy corpus header, root registration, manifest row, or retention activation is partially retained.

---

## Revision Log

- **2026-08-12:** Kept the accepted filename-only lineage/tree direction; made orchestration run minting collision-safe, mapped and validated canonical Status, bounded trusted `.projex` roots through registration/ownership, added durable Parent-correction evidence, and replaced unconditional lifecycle `--check` with a manifest-gated scoped-quarantine protocol — trigger: `2608121035-parent-lineage-and-projex-tree-redesign-redteam.md § Remediation / Must Fix` (five required corrections; verdict `Fix Issues`).

---

## Notes

### Split Decision

**No split — coupled single scope; auto-suggest threshold accepted.**

Auto-suggest split trips at 505 lines/52,741 bytes and six steps. No always-required trigger: one repo, one root framework/.projex scope; workflow Markdown is executable framework source, not an upstream product contract consumed by a separate downstream repo. Keep one Plan because breaking scaffold arity, registered discovery, creator migration, correction ledger, retention gate, and corpus rollout require one clean cutover; splitting creates an invalid intermediate framework.

### Resolved Redesign Decisions

| Adversarial requirement | Decision | Plan location |
|---|---|---|
| Header examples look like real headers | Versioned top-of-file preamble ending blank + `---`; body ignored | Steps 1–2 |
| Global filename identity absent | Filename remains identity; authorized-root live/virtual scan + exclusive reservation | Steps 1–2 |
| Same-minute run collision | 96-bit filename token + exclusive reservation + eight bounded retries | Steps 1–2 |
| `Orchestrator` unqueryable | Thin stable tokenized `-orchestrate.md`; sentinel removed | Steps 1, 4 |
| Noncanonical `Closed` emission | Exhaustive initial-state map; strict live/virtual canonical validation | Steps 1–2 |
| Archive/conclude schema undefined | One strict `projex-lineage-v1` fence grammar | Step 4 |
| Legacy debt denies all reads/removal | Target-local validation; strict global `--check`; manifest-gated scoped retention | Steps 2, 4–5 |
| Migration evidence/governance absent | TSV evidence/confidence/resolver/disposition manifest | Step 5 |
| Parent edits erase accountability | Append-only correction events + reciprocal retained-record references | Steps 1, 4–5 |
| Named `.projex` root poisoning | Bootstrap root + explicit path/owner/date/evidence registry | Steps 1–2 |
| Manual creators drift | Scaffold types + exhaustive 20 standard/5 manual inventory | Steps 3–4 |
| Cross-platform behavior underdefined | Normative roots/symlink/encoding/newline/diagnostic/exit contract + paired fixtures | Steps 2, 6 |
| Poisoned unrelated artifact denies query | Registered physical-root boundary + target-reachable failure scoping | Step 2 |
| Reader-only observability | `--check` explicit corpus-health mode; runners register focused suites | Steps 2, 6 |
| Human suffix decision | Exact orchestration record suffix `-orchestrate.md` | Steps 1, 4 |

### Deviations from Original Proposal

- Remove literal `Orchestrator`; it cannot name a run.
- Tokenize orchestration filenames so same-minute same-goal runs all mint roots; token is filename entropy, not a second identity.
- Allow phased legacy quarantine outside Parent grammar; unresolved history no longer blocks valid target queries, recorded scoped retention, or gets mislabeled User.
- Add live preamble version/boundary, registered-root identity reservation, canonical Status validation, target-local error scope, `--check`, migration/correction ledgers, and strict correction-bound virtual records.
- Route manual artifacts and Parent corrections through shared workflow gates instead of relying on prose validation alone.
- Keep filename identity; reject UUID/central registry as needless second identity/source of truth.
- Keep JSON/DOT deferred; no current consumer justifies them.

### Risks

- **Shell/PowerShell scan drift:** High impact. Mitigation: normative behavior + independently executed shared scenarios; parity is acceptance, not inference.
- **CSPRNG/token testability:** High/Low. Mitigation: 96-bit lowercase-hex token, exclusive reservation, eight retries, fixture-only injected sequence.
- **Exclusive lock leakage after crash:** Medium/Low. Stale lock fails loud and is never stolen; cleanup trap/finally + fixture proves normal cleanup.
- **Large legacy quarantine:** Medium. Targeted queries and recorded scoped lifecycle transitions remain usable; manifest makes debt measurable; no fake ancestry.
- **Archive transitional duplicate:** High if misclassified. Exact Source/Parent/full Status/correction equivalence is the only allowed duplicate; mismatch blocks deletion.
- **Silent Parent correction:** High/Medium. Revise requires atomic correction event; reader and lifecycle gates reconstruct correction chain and block missing evidence.
- **Root registration abuse:** High/Low. Only canonical bootstrap registry admits paths; each row carries owner/date/evidence and requires explicit review; unregistered content never resolves.
- **Workflow added without scaffold:** Medium. SKILL creator contract + inventory assertion/test update requirement.
- **Auxiliary record branch visibility:** Medium. Explicit execute/close chain must include run record in prerequisite commit; auxiliary-only chains remain uncommitted.

### Open Questions

None.
