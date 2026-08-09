# Stress: close-precheck Script Plan

> **Status:** Complete (Findings Incorporated)
> **Close Disposition:** Plan revision incorporated required contract changes; preserved with the plan's close record.
> **Lead:** luna (xhigh)
> **Subject:** `2608081953-close-precheck-script-plan.md` — Ready; report-only close-precheck script pair, tests, and documentation
> **Related:** `2607291729-close-projex-modernization-proposal.md`

---

## Bottom Line

**Verdict:** Fix Issues

The direction is sound and the report-only boundary is valuable, but the contract needs sharper discovery and output semantics before implementation. It can omit child-worktree documents from the inventory, produce human-readable warnings that are weakly machine-addressable, and hand off evidence with no snapshot identity. The existing child cleanliness gate limits the omission's damage: residue remains visible and blocks finalization. The plan is fixable before implementation; no execution is authorized by this stress pass.

**Top Vulnerabilities:**

1. **Child-worktree documents can be omitted from the inventory.** The scan excludes `.projexwt`, so the report is incomplete even though the child gate still exposes residue and prevents cleanup (`close-projex.md:424-440`).
2. **Warning output needs an explicit machine-readable result.** A1 intentionally leaves close integration unchanged (`:15`, `:38`) and returns zero for resolved warnings (`:145-146`, `:332`); this is an output-contract/adoption concern, not a bypass of finalizer enforcement.
3. **The report has no freshness or schema identity.** Ref tips, gates, and inventory can drift after generation, and the unspecified record grammar makes shell/PowerShell parity unverifiable by a consumer.

---

## Angle Triage

| Angle | Status | Reason / Earned by |
| ------- | -------- | -------------------- |
| Assumption | Selected | Correctness depends on strict log headers, path interpretation, and one unique branch-to-plan match (`:86-89`). |
| Edge Case | Selected | Child-only untracked docs, symlinked paths, malformed fields, and relative worktree paths threaten the stated context contract. |
| Failure Cascade | Selected | A stale or incomplete report feeds later close discovery, auxiliary reconciliation, and destructive finalization (`:101`, `:228`). |
| Inversion | Skipped | Replacing read-only preflight with mutation would violate the hard report-only constraint (`:41`, `:77`), not expose a valid in-scope alternative claim. |
| Scale | Selected | Inventory recursively scans all eligible `.projex` folders and both refs (`:81`, `:134-137`); no workload bound is specified. |
| Omission | Selected | Record delimiters, escaping, child-worktree inventory semantics, snapshot identity, and symlink policy are not specified. |
| Hidden | Selected | A1 calls the script a mandatory close action in the source proposal (`2607291729-close-projex-modernization-proposal.md:66`), while this plan makes no close-workflow change (`:15`, `:38`). |
| Worst Case | Selected | An incomplete or stale report can cause missed reconciliation and delayed close; the child gate limits direct cleanup loss. |
| Incentive | Selected | Zero exit on warnings rewards automation that checks only exit status (`:145-146`, `:332`). |
| Time | Selected | Exact log/status conventions and duplicated platform logic can drift as the framework evolves (`:72`, `:86`, `:176-184`). |
| Dependency | Selected | Git, Bash, and PowerShell are required; the plan permits environments that cannot run the parity suite (`:72`, `:230`). |
| Observability | Selected | No report version, generation time, ref SHA, or freshness comparison is required. |
| Adoption | Selected | The utility is documented but not invoked by the close workflow; its claimed replacement of manual discovery is deferred to A2/A4. |

## Angles Not Attacked

> No new angle surfaced after the implication pass. The skipped Inversion angle remained inapplicable to the fixed report-only contract. Compound cascades are recorded below.

| Angle | Surfaced by | What would have been asked |
| ----- | ----------- | --------------------------- |
| None  | —           | —                           |

---

## Findings

### Finding 1: Child-worktree related documents are outside the inventory

**Severity:** Medium | **Likelihood:** Medium | **Angle:** Edge Case / Omission

**Target Claim:** The inventory covers every `.projex` file referencing the plan and identifies untracked auxiliary documents (`2608081953-close-precheck-script-plan.md:30`, `:134-137`, `:216-218`).

**Attack Vector:** In worktree mode, create an untracked `.projex/2608082035-review.md` inside the recorded child worktree and make it reference the plan filename. The plan requires filesystem-only scans to exclude `.projexwt` (`:81`, `:134`), so ref-backed paths and a root scan cannot include this child-only file.

**Impact:** The report's inventory is incomplete and close must fall back to the child gate/manual inspection. The omission does **not** silently delete this file by itself: `git status --porcelain --ignored=matching` exposes untracked/ignored child content, and the existing close/finalizer cleanliness gate blocks removal while it remains. The defect is discovery completeness and avoidable reconciliation work, not a direct cleanup bypass.

**Blast Radius:** Worktree executions with child-only `.projex` content; the planned "untracked auxiliary doc" test is incomplete unless it places the fixture in the child worktree and asserts both inventory output and gate behavior.

**Remediation:** Either scan the recorded child worktree's eligible `.projex` folders and emit a location/classification, or explicitly document child inventory exclusion and rely on the existing child gate as the enforcement path. Add a child-only fixture proving the report may omit the file while `GATE` is `WARN` and the finalizer refuses cleanup; do not claim silent loss.

### Finding 2: Warning result lacks an explicit machine-readable contract

**Severity:** Medium | **Likelihood:** High | **Angle:** Incentive / Adoption

**Target Claim:** Valid context with dirty or document-state warnings can safely exit zero while preserving evidence (`:32`, `:80`, `:145-146`, `:332`).

**Attack Vector:** Run the script against a valid context with tracked base changes or child leftovers. A caller checks only `$?` and receives zero plus `PRE-CHECK PASSED WITH WARNINGS`; a caller that does not parse the report cannot distinguish a clean result from a warning result.

**Impact:** This is an output-contract/adoption weakness while A1 remains standalone. It does **not** bypass finalizer enforcement: the close/finalizer scripts rerun cleanliness gates and stop before mutation when child content remains. The plan deliberately leaves `close-projex.md` untouched (`:15`, `:38`), so consumer integration belongs to later A2/A4 work, not this A1 plan.

**Blast Radius:** Direct human use and future automation that consumes the report; ambiguity affects dirty origin, dirty child, and untracked auxiliary findings, while finalizer gates remain the enforcement backstop.

**Remediation:** In A1, add explicit machine-readable `RESULT=PASS|PASS_WITH_WARNINGS` plus per-gate `GATE_*` values and document that exit 0 is not approval. Do not require an A2/A4 consumer here; later close/orchestrator work should parse these fields or preserve the existing human workflow.

### Finding 3: The evidence has no snapshot boundary

**Severity:** High | **Likelihood:** Medium | **Angle:** Failure Cascade / Observability

**Target Claim:** One complete report safely hands repo state, commit range, inventory, stashes, and § 7 gates to later close steps (`:101`, `:129-146`).

**Attack Vector:** Generate a clean report. Before close consumes it, advance the ephemeral branch, add or remove a related document, create a stash, or modify the originating checkout. `close-projex.md` explicitly admits that pre-flight checks can go stale between check and mutation (`close-projex.md:442-448`). The plan emits no `BASE_SHA`, `EPHEMERAL_SHA`, worktree HEAD, generation time, or rerun/compare rule.

**Impact:** The displayed diff, inventory, and gate evidence can describe a different state from the one close reconciles. Finalizers recheck their cleanliness gates, so child residue still blocks mutation; they do not refresh the report's document set, stash list, or commit evidence.

**Blast Radius:** Any cold-start or orchestrated handoff with a delay between precheck and close; the result is stale evidence and rework, not a bypass of the finalizer's cleanup gate.

**Remediation:** Emit ref and worktree HEAD SHAs, worktree registration identity, report version, and generation timestamp. Future consumers can compare those values and rerun on mismatch; keep finalizer gates as the final enforcement backstop.

### Finding 4: The cross-platform output contract is not parseable by specification

**Severity:** High | **Likelihood:** Medium | **Angle:** Omission / Dependency

**Target Claim:** Shell and PowerShell expose a stable, behaviorally equivalent report (`:101`, `:176-179`, `:324`).

**Attack Vector:** Put spaces, tabs, quoting, or status text containing punctuation in paths, commit subjects, and inventory entries. The plan names section labels and key/value fields but does not define record delimiters, escaping, duplicate-path handling, error records, or whether multi-line Git output belongs to the current record. PowerShell is asked to preserve forward-slash paths, but no serialization grammar makes parity testable.

**Impact:** A later consumer can split one document/commit into multiple records, silently drop a path, or interpret platform-specific quoting differently. A human-readable report may look correct while an orchestrator parses it incorrectly.

**Blast Radius:** All consumers beyond copy/paste, especially the proposed keyed/cold-start orchestration path.

**Remediation:** Define a versioned line protocol with escaped fields (or a documented JSON mode), stable record types, explicit `NONE` semantics, and error/result records. Add paths with spaces and multi-line Git subjects to both parity suites.

### Finding 5: Path containment and worktree-base resolution are underspecified

**Severity:** High | **Likelihood:** Medium | **Angle:** Assumption / Hidden

**Target Claim:** A plan/log outside the repo is rejected and the recorded repo/worktree is validated before reporting (`:124-127`, `:150`, `:322`).

**Attack Vector:** Supply a symlinked plan directory or a log with a relative `Worktree Path:`. Lexical path-prefix checks can accept a symlink whose real target is outside the repo or resolve the child relative to different working directories on Bash and PowerShell. A stale-but-registered path can also point to a different checkout after worktree reuse.

**Impact:** The script may inspect the wrong repository/worktree, report unrelated refs, or falsely reject valid worktree mode. This undermines the promise that `REPO_ROOT`, `BASE_BRANCH`, and `EPHEMERAL_BRANCH` describe one execution.

**Blast Radius:** Symlinked repos, nested worktrees, Windows path normalization, and reused worktree directories.

**Remediation:** Canonicalize existing paths before containment checks; define relative `Worktree Path:` as relative to the recorded `Repo Root:` (or reject relative values); verify exact registered path plus branch and worktree HEAD via `git worktree list --porcelain`. Add symlink, relative-path, and path-reuse fixtures.

### Finding 6: Recursive inventory has no scale or output budget

**Severity:** Medium | **Likelihood:** Medium | **Angle:** Scale

**Target Claim:** A deterministic script replaces manual discovery with one report (`:13`, `:81`, `:101`, `:134-138`).

**Attack Vector:** Use a repository with hundreds of `.projex` folders and thousands of tracked/untracked documents. The implementation must enumerate both refs, filesystem paths, read candidates for literal plan references, parse statuses, and emit every match. No file-count, byte, timeout, or performance acceptance bound exists.

**Impact:** The precheck can become slower and larger than the manual work it replaces, hit shell/PowerShell process or output limits, or tempt a future implementation to truncate results while still claiming completeness.

**Blast Radius:** Monorepos and repositories using the framework's supported multi-folder organization.

**Remediation:** Set a benchmark and maximum-output policy; use batched Git queries and one filesystem traversal per root; report `TRUNCATED`/hard failure rather than silently dropping entries. Add a generated large-fixture smoke test.

### Finding 7: Strict format dependence has no compatibility/version path

**Severity:** Medium | **Likelihood:** Medium | **Angle:** Time / Dependency

**Target Claim:** Strict log/status parsing provides safe context and remains a reliable framework contract (`:50`, `:86-89`, `:124-127`).

**Attack Vector:** A later execution-log template changes spacing, header names, or status representation, or an old valid log lacks the newly required field. The script hard-fails before producing useful evidence. The plan has no format version, migration note, or diagnostic distinguishing an old log from a malformed one.

**Impact:** Closeability is coupled to exact duplicated Markdown syntax. Framework evolution or an older execution can turn a valid execution into an opaque precheck failure, increasing manual reconstruction rather than reducing it.

**Blast Radius:** Historical plans, repos with locally customized templates, and future changes to `execute-projex.md`/`SKILL.md`.

**Remediation:** Version the log contract or centralize its parser contract in one documented section; emit a precise unsupported-format diagnostic and preserve safe partial context where possible. Add old/current template fixtures and a migration test.

### Finding 8: PowerShell parity can be accepted without being exercised

**Severity:** Medium | **Likelihood:** High on non-Windows CI | **Angle:** Dependency

**Target Claim:** Both platform suites independently verify the same observable contract (`:33`, `:184`, `:230`, `:284-287`).

**Attack Vector:** Run in an environment without PowerShell. The plan explicitly allows recording the platform limitation rather than claiming parity (`:230`), yet still lists the PowerShell parser/suite as an acceptance check (`:284-287`). A Bash-only implementation pass can therefore leave the new `.ps1` unparsed and untested.

**Impact:** Windows users receive a script whose parity is asserted by design but not evidence. Cross-platform drift is detected only after deployment.

**Blast Radius:** Any project runner without a Windows/PowerShell job; the risk repeats for every future change to the duplicated pair.

**Remediation:** Add a supported PowerShell CI/matrix job or make the plan's Ready gate conditional on an actual parser/runtime result. Record `NOT RUN` distinctly from `PASS`, never as an implicit completion.

### Compound: Incomplete discovery + warning ambiguity stalls reconciliation

**Severity:** Medium | **Likelihood:** Medium | **Angles:** Edge Case, Omission, Incentive, Failure Cascade | **Member findings:** Finding 1 + Finding 2

A child-only related document is omitted from the inventory and the report's warning result is easy for a caller to under-parse. The child gate still exposes the document as untracked/ignored, and the finalizer blocks cleanup while it remains; therefore this compound causes incomplete context and manual/retry work, not silent deletion. The valid concern is that A1's report is less complete and less machine-addressable than its stated downstream role suggests; later consumer integration is a separate A2/A4 concern.

---

## Held

> Claims attacked and survived. What was tried, and why it held.

### Assumption: Base branch must be a real local branch

**Tried:** Tag, raw SHA, remote-tracking ref, missing field, and a guessed `main` fallback.
**Held because:** The plan explicitly requires the log's strict `Base Branch`, rejects non-local values, and forbids `main`/`master` fallback (`:79`, `:126`, `:150`, `:329`). This matches the close finalizer contract (`close-projex.md:448-450`).

### Omission: Report-only means no repository mutation

**Tried:** Checkout, commit, stage, stash, merge, rebase, cleanup, and worktree registration as possible implementation shortcuts.
**Held because:** These operations are explicitly out of scope (`:41`), the constraint forbids mutation (`:77`), and the planned suites assert refs/index/files/worktree/stash invariance (`:220-224`).

### Edge Case: Both-ref classification has explicit precedence

**Tried:** A related document tracked on both base and ephemeral refs.
**Held because:** The plan states `tracked-on-ephemeral` wins and requires `also-on-base` (`:30`, `:331`), with a dedicated test case (`:218`).

### Observability: Hard context errors differ from cleanliness warnings

**Tried:** Missing log/header versus valid context with dirty origin/child.
**Held because:** The plan specifies non-zero failure before false reporting, zero for resolved warnings, visible evidence, and distinct terminal messages (`:32`, `:80`, `:145-146`, `:332`). The weakness is caller ambiguity, not an absent distinction in human output.

## Implication Pass

No skipped angle was promoted. Cross-angle review found one bounded compound (Finding 1 + Finding 2); the existing child gate prevents the hypothesized cleanup bypass. No additional attack angle surfaced after this single pass.

---

## Remediation

### Must Fix (Before Proceeding)

- **Preserve inventory completeness** (Finding 1) → scan/report child-only related files, or document their exclusion and test the child-gate enforcement path; do not claim silent loss.
- **Make result semantics machine-readable** (Finding 2) → emit explicit result/gate records and document exit-0 warning semantics. Consumer integration belongs to later A2/A4 work.
- **Add snapshot identity for future consumers** (Finding 3) → emit ref/worktree SHAs and generation metadata so later close integration can rerun on drift.
- **Define a versioned output grammar** (Finding 4) → specify escaping, record types, `NONE`, and errors; test path/subject edge cases.
- **Canonicalize and pin path resolution** (Finding 5) → real-path containment and exact registered worktree validation.

### Should Fix (Before Production)

- **Scale budget** (Finding 6) → benchmark large multi-folder trees and report truncation/failure explicitly.
- **Format compatibility path** (Finding 7) → version or centralize Markdown header parsing and add old-log fixtures.
- **PowerShell evidence gate** (Finding 8) → provide CI/runtime coverage; distinguish `NOT RUN` from pass.

### Monitor

- **A2/A4 adoption** (Finding 2) → confirm close and orchestrate actually invoke and parse the report, rather than relying on documentation.
- **Staleness frequency** (Finding 3) → measure reruns between precheck and close.
- **Inventory runtime/output size** (Finding 6) → revisit after real multi-folder repos exercise the script.

---

## Final Assessment

**Soundness:** Fixable
**Risk:** High
**Readiness:** Needs Work

**Conditions for Approval:**

- [ ] Child-worktree-only related documents are inventoried, or their exclusion and child-gate enforcement are documented and tested.
- [ ] A documented machine-readable result/schema distinguishes clean from warning output; downstream WARN handling remains a later consumer task.
- [ ] Ref/worktree snapshot IDs and generation metadata are available for future consumers.
- [ ] Path canonicalization and relative worktree semantics are tested on both platforms.
- [ ] PowerShell parser/runtime evidence is available, or the plan is explicitly platform-gated.

**No-Go If:**

- [ ] A1 leaves clean and warning results indistinguishable in its machine-readable output.
- [ ] The report claims complete inventory while excluding child-worktree filesystem content without documenting the child-gate enforcement path.
- [ ] A future consumer treats snapshot-sensitive evidence as current without a documented comparison/rerun rule.
