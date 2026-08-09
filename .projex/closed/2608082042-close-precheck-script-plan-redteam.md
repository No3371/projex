# Red Team: close-precheck Script Plan

> **Status:** Complete (Findings Incorporated; PowerShell Evidence Deferred)
> **Close Disposition:** Required A1 contract changes were incorporated; runtime parity remains explicitly deferred in the plan walkthrough.
> **Lead:** luna (xhigh)
> **Subject:** `2608081953-close-precheck-script-plan.md` — Ready; report-only close-precheck script pair, tests, and documentation | **Related:** `2607291729-close-projex-modernization-proposal.md`, `2608082031-close-precheck-script-plan-stress.md`

---

## Bottom Line

The plan's report-only direction is valuable, but its claimed close handoff is not yet safe to implement as written. Redesign the A1 contract before execution; no execution is authorized by this report.

**Verdict:** Redesign

**Top Vulnerabilities:**

1. **No versioned machine-readable or freshness contract:** raw mixed output cannot be safely parsed or bound to the state close finalizes (Findings 1, 2, 6, 11).
2. **Child-worktree auxiliary documents can be omitted and lost:** `.projexwt` exclusion conflicts with “every `.projex` file” and the auxiliary artifact lifecycle (Findings 5, 7).
3. **Path/input security and cross-platform readiness are unproven:** canonicalization, untrusted output, read-only command boundaries, PowerShell execution, and runner membership remain underspecified (Findings 3, 4, 8–10).

---

## Stakeholder Roles

| Wave | Role | Cares About | Pain Points | Critical Assumptions |
| ------ | ------ | ------------- | ------------- | --------------------- |
| 1 | Close operator / orchestrator | Correct handoff, no accidental mutation, fast close context | Manual re-discovery, stale or ambiguous report | A successful report is current and complete enough to drive close; exit 0 means usable evidence |
| 1 | Shell/PowerShell utility maintainer | Safe parsing, portability, behavioral equivalence | Duplicated implementations, path and Markdown edge cases | Strict headers and Git output behave identically across platforms |
| 1 | Test/CI maintainer | Independent evidence, fixture isolation, runner coverage | Missing runtime/platform coverage, false parity confidence | Both suites execute somewhere; listed matrix exercises the dangerous cases |
| 2 | Close/finalizer integrator | Precheck and finalizer agree on target, state, and gates | Stale handoff, duplicated checks, wrong checkout risk | Finalizer reruns enough checks to make precheck context safe |
| 2 | Worktree / auxiliary-document author | No related document is missed or lost during close | Untracked child docs, multi-folder discovery, status ambiguity | A repo-root scan covers the execution worktree and every relevant document |
| 2 | Release/CI owner | Supported platforms, repeatable gates, maintainable utility pair | Optional runtime coverage, platform drift, unclear readiness | A documented limitation is not mistaken for cross-platform acceptance |
| 3 | Attacker / malicious repository contributor | Partial exploit, hidden or redirected close work, low-cost disruption | Strong parsing and path validation, visible evidence | User-controlled plan/log/path content cannot influence target or consumer interpretation |
| 3 | Security/compliance reviewer | Non-mutation, provenance, least privilege, defensible evidence | False safety claims, untested threat paths, silent loss | Fixture invariance and finalizer gates cover the meaningful security boundary |
| 3 | Framework owner / release maintainer | Durable contract, lifecycle coherence, platform support | Deferred ownership, duplicated semantics, premature adoption | Later A2/A4 work will repair gaps before any consumer relies on A1 |

### Wave Derivation

- **Wave 1 → 2:** The report's consumer gap and stale-context risk implicate the close/finalizer integrator; path and inventory ambiguity implicate worktree and auxiliary-document authors; unexercised PowerShell parity implicates the release/CI owner.
- **Wave 2 → 3:** Wave 2's child-document omission and lifecycle ambiguity surface an attacker who can hide or redirect a related artifact; stale handoff and path trust surface the security/compliance reviewer; runner/readiness and deferred-consumer gaps surface the framework owner/release maintainer accountable for adoption.

## Roles Not Attacked

> Roles that surfaced after wave 3 closed. Recorded, not analyzed.

| Role | Surfaced by | What would have been asked |
| ------ | ------------- | --------------------------- |
| Support / incident responder | Final cross-wave stale or disputed close cascade | How to reconstruct provenance, identify the report snapshot consumed, and recover omitted auxiliary artifacts |

---

## Attack Surface (Per Role)

### Wave 1 — Direct Roles

**Close operator / orchestrator:**

- Claims to this role: one report resolves plan/log/repo/base/ephemeral context, inventories related documents, surfaces stashes, and reports both § 7 gates without mutation (`2608081953-close-precheck-script-plan.md`, Summary, Success Criteria).
- Assumptions by/about role: stdout is machine-readable enough for a later handoff; a valid report remains representative until close; no-argument branch inference identifies the intended plan.
- Dependencies: Git refs and worktree registration, execution-log headers, filesystem scan, shell/PowerShell runtime, later close workflow adoption.

**Shell/PowerShell utility maintainer:**

- Claims to this role: independent implementations expose the same sections, key/value fields, classifications, warnings, and exit codes (plan Step 1–2).
- Assumptions by/about role: strict Markdown headers are stable; paths can be normalized consistently; Git's multi-line/human output can coexist with key/value output; platform duplication will not drift.
- Dependencies: Git behavior, Bash/PowerShell quoting, path canonicalization, execution-log template, `.projex` layout conventions.

**Test/CI maintainer:**

- Claims to this role: throwaway-repository suites cover resolution, inventory, gates, warnings, non-mutation, and parity, and both runners execute them (plan Step 3–4, Verification Plan).
- Assumptions by/about role: PowerShell is available or its absence is an acceptable limitation; the matrix represents real worktree/path failures; PASS/FAIL summaries prove the contract.
- Dependencies: supported runtimes, independent fixture setup/cleanup, runner registration, platform-specific Git semantics.

### Wave 2 — Implicated Roles

**Close/finalizer integrator:**

- Claims to this role: precheck output supplies the repo/base/ephemeral context and § 7 evidence while finalizer scripts remain the enforcement backstop (plan Summary, Out of Scope, Step 1).
- Assumptions by/about role: a later close consumer can safely combine report fields with finalizer arguments; rerunning cleanliness gates compensates for report drift.
- Dependencies: exact recorded repo/worktree identity, output parsing, finalizer path/branch assertions, timing between precheck and mutation.

**Worktree / auxiliary-document author:**

- Claims to this role: every related `.projex` document is classified across refs and filesystem state, including untracked documents, while multiple `.projex` folders are supported (plan Success Criteria, Current State, Constraints).
- Assumptions by/about role: the repository-root filesystem scan reaches the child execution worktree; excluding `.projexwt` cannot hide a document that close must reconcile.
- Dependencies: worktree path resolution, filesystem traversal roots, literal filename matching, Git tracking queries, status parsing.

**Release/CI owner:**

- Claims to this role: shell and PowerShell suites independently verify the same contract and both standard runners include them (plan Step 3–4, Verification Plan).
- Assumptions by/about role: the repository can provide both runtimes or can gate readiness explicitly; duplicated scripts remain maintainable without a shared executable.
- Dependencies: CI OS matrix, PowerShell availability, Git version/behavior, suite exit and aggregation semantics.

### Wave 3 — Adversarial & Accountable Roles

**Attacker / malicious repository contributor:**

- Claims to this role: arbitrary repo content is inspected read-only and cannot redirect context, hide related documents, or confuse a future consumer (plan Constraints; Success Criteria).
- What they can exploit: controlled filenames, log fields, branch/worktree timing, unusual Git subjects, symlinks, and child-only untracked documents; partial success (one omitted document or wrong handoff) is enough to force a bad close or expensive recovery.
- Defenses probed: strict headers, path containment, shell quoting, canonicalization, inventory completeness, snapshot identity, and finalizer gates.

**Security/compliance reviewer:**

- Claims to this role: report-only means no refs/index/worktree/files/stash mutation and finalizers remain the enforcement backstop (plan Constraints; Out of Scope; Verification Plan).
- Assumptions by/about role: byte/ref invariance fixtures and finalizer tests establish the full threat boundary; stale evidence is merely inconvenient, not safety-relevant.
- Dependencies: untrusted-input handling, canonical paths, read-only Git command set, report provenance, CI evidence, deletion/cleanup policy.

**Framework owner / release maintainer:**

- Claims to this role: A1 is an independently landable foundation that later A2–A4 can consume without changing the lifecycle (plan Summary, Out of Scope, Split Decision).
- Assumptions by/about role: later consumers will not adopt underspecified output early; duplicated shell/PowerShell contracts and auxiliary policy can evolve coherently.
- Dependencies: SKILL.md contracts, close/orchestrate workflow owners, test/CI availability, artifact status policy, future schema compatibility.

---

## Critical Findings

### Finding 1: “Machine-readable” output has no record grammar

**Severity:** High | **Likelihood:** High | **Wave:** 1

**Affects Roles:** Close operator / orchestrator; shell/PowerShell utility maintainer; test/CI maintainer

**Evidence:** The plan promises machine-readable context fields and stable sections (Success Criteria; Implementation Overview), but specifies only labels, `key=value` fields, and `NONE`. It does not define record delimiters, escaping, duplicate handling, multiline behavior, status-value grammar, schema/version, or whether Git subjects and paths are raw or encoded. The existing `execute-precheck.sh` emits key/value lines followed by human prose and raw Git-derived text; it is a compatibility baseline, not a serialization specification.

**Attack Vector:** Create a plan/log or related document under a path containing spaces, tabs, `=`, `%`, or a newline-free but punctuation-heavy name; use a commit with unusual subject text and inventory statuses containing spaces. A consumer splits on `=` or newlines and mistakes a warning, commit, or path line for a new record. Bash and PowerShell can each produce human-equivalent but parser-different quoting.

**Role-Specific Impact:**

- **Close operator / orchestrator:** Cannot safely feed inventory or gate state into keyed/cold-start close; malformed parsing can omit an auxiliary document or treat `WARN` as `PASS`.
- **Shell/PowerShell utility maintainer:** “Behavioral equivalence” is untestable beyond hand-picked output because no canonical encoding exists.
- **Test/CI maintainer:** Tests can assert substrings while a real parser fails on unrepresented path/subject characters.

**Blast Radius:** Every future automated consumer, especially the source proposal's standalone/orchestrated close path; human copy/paste remains possible but does not fulfill the stated machine-readable claim.

**Remediation:** Specify a versioned record protocol before implementation: record type, field order, escaping, path separators, multiline handling, `NONE`, duplicate paths, warnings/errors, and terminal result. Prefer a separate `--format`/JSON mode if human output must remain compatible. Add path-with-spaces and unusual-subject parity fixtures.

### Finding 2: The report is not bound to the state that close will finalize

**Severity:** High | **Likelihood:** Medium | **Wave:** 1

**Affects Roles:** Close operator / orchestrator; test/CI maintainer

**Evidence:** The plan says the report can replace manual discovery and is safe to hand to later close steps (Summary, Implementation Overview), but emits no base/ephemeral ref tips, worktree HEAD, generation time, or rerun-on-drift rule. It intentionally makes no `close-projex.md` changes (Out of Scope; Step 4), so no consumer is required to invoke it or compare its result. The close workflow itself rechecks finalizer gates, but that does not refresh the report's commit list, inventory, or stash snapshot.

**Attack Vector:** Generate a clean report, then add a commit, create a stash, modify a related untracked document, or change the originating checkout before close consumes the output. The report still says `PASS` and presents evidence for the earlier state.

**Role-Specific Impact:**

- **Close operator / orchestrator:** May reconcile or narrate the wrong commit range/document set, then discover drift during finalization and redo work; a consumer that trusts stdout can make an incomplete decision.
- **Test/CI maintainer:** Non-mutation tests prove the script does not alter a fixture, not that a delayed consumer detects changed state.

**Blast Radius:** Cold-start and orchestrated handoffs with any delay; finalizer cleanliness gates limit direct cleanup bypass but do not make stale evidence current.

**Remediation:** Emit snapshot identities (`BASE_SHA`, `EPHEMERAL_SHA`, recorded worktree HEAD/registration identity, generation timestamp, schema version) and define comparison/rerun semantics. State explicitly that exit 0 is not approval and that finalizers remain authoritative. Add a drift fixture or defer the “safe handoff” claim until a consumer exists.

### Finding 3: Repository/worktree path trust is under-specified

**Severity:** High | **Likelihood:** Medium | **Wave:** 1

**Affects Roles:** Close operator / orchestrator; shell/PowerShell utility maintainer; test/CI maintainer

**Evidence:** The plan requires validation of recorded `Repo Root`, `Base Branch`, and optional `Worktree Path`, and says plans/logs outside the repo must fail (Step 1; Constraints). It does not specify canonicalization before containment checks, the base for resolving a relative worktree path, symlink policy, or exact validation against `git worktree list --porcelain` branch/path identity. “Validate registration” can still accept a stale or reused path unless branch and HEAD are pinned.

**Attack Vector:** Use a symlinked `.projex` directory, a log with a relative worktree path, a path containing spaces, or a removed/reused child worktree. Exercise Bash and PowerShell from different current directories. Lexical prefix checks or platform-specific normalization can make the script inspect a repository/worktree other than the one represented by the log.

**Role-Specific Impact:**

- **Close operator / orchestrator:** Receives internally consistent-looking fields for the wrong checkout and may hand them to destructive finalizers.
- **Shell/PowerShell utility maintainer:** Must independently solve security-sensitive path semantics without an explicit contract.
- **Test/CI maintainer:** The listed matrix has no symlink, relative-path, path-reuse, or mixed-separator acceptance case.

**Blast Radius:** Nested repositories, worktree mode, Windows path normalization, and any environment where a child path is reused between execution and close.

**Remediation:** Define path semantics: canonicalize existing paths, resolve relative `Worktree Path` relative to recorded canonical `Repo Root` or reject it, reject symlink escapes, and verify exact registered path plus branch and HEAD. Add cross-platform fixtures for each case before calling context resolution complete.

### Finding 4: PowerShell “parity” can pass without PowerShell evidence

**Severity:** Medium | **Likelihood:** High | **Wave:** 1

**Affects Roles:** Shell/PowerShell utility maintainer; test/CI maintainer; close operator / orchestrator on Windows

**Evidence:** Step 2 requires parser/runtime validation, but Step 3 explicitly permits environments without PowerShell to record a platform limitation rather than claim parity. The Verification Plan still lists PowerShell checks as acceptance criteria, and no CI/matrix requirement ensures a PowerShell job exists.

**Attack Vector:** Implement/test Bash on Linux, record PowerShell as unavailable, and merge an unparsed `.ps1` file. A quoting, exit-code, path, or process-capture defect then appears only on Windows.

**Role-Specific Impact:**

- **Utility maintainer:** Receives a false sense of completion from the shared prose contract.
- **Test/CI maintainer:** Cannot distinguish `PASS`, `NOT RUN`, and “not applicable” in the plan's completion checklist.
- **Windows close operator:** Encounters parity failure at the point where close context is needed.

**Blast Radius:** Every Windows user and every future duplicated-script edit when the repository's ordinary runner is Bash-only.

**Remediation:** Require a supported PowerShell parser/runtime CI job or make the plan explicitly platform-gated with `NOT RUN` distinct from `PASS`; do not mark cross-platform acceptance complete without executable evidence.

### Finding 5: Child-worktree auxiliary documents can disappear from the promised inventory

**Severity:** High | **Likelihood:** Medium | **Wave:** 2

**Affects Roles:** Worktree / auxiliary-document author; close/finalizer integrator; close operator / orchestrator

**Evidence:** The plan claims inventory coverage for every `.projex` file and untracked auxiliary document, but its scan explicitly excludes `.projexwt` (Constraints; Step 1). A recorded child worktree lives under `.projexwt`, so a filesystem-only document created there cannot be found by a repo-root traversal that prunes that directory. The close workflow's child gate checks cleanliness, but that is a leftover detector, not an auxiliary-document inventory or status reconciliation mechanism.

**Attack Vector:** In worktree mode, create an untracked `review`/`redteam`/`proposal` document under the child worktree's `.projex` folder, reference the plan filename, and run precheck from the originating checkout. The document is neither tracked on base nor ephemeral and is outside the planned scan root; it is omitted while the report can still end with a warning-bearing success.

**Role-Specific Impact:**

- **Worktree / auxiliary-document author:** A resolved or still-open document can be left behind, misclassified, or lost when the child worktree is removed; the role receives no inventory row to decide its lifecycle.
- **Close/finalizer integrator:** Must re-open the child worktree and manually distinguish disposable scratch from auxiliary projex; precheck's promised complete dataset is false.
- **Close operator / orchestrator:** May believe the inventory is exhaustive and fail to ask whether the omitted document should move to base/closed.

**Blast Radius:** Worktree-mode closes with child-only untracked `.projex` docs; the child cleanliness gate may prevent removal, but only after the omission has already caused manual rework and an unclear resolution path.

**Remediation:** Either scan the recorded child worktree's eligible `.projex` roots and emit location plus classification, or explicitly scope inventory to the originating repository and state that child-only docs are reported only through the child gate. If the latter, add a test proving omission is intentional and require close to inspect/document those paths before cleanup; do not claim “every `.projex` file.”

### Finding 6: Finalizer enforcement does not repair a stale or incomplete precheck handoff

**Severity:** High | **Likelihood:** Medium | **Wave:** 2

**Affects Roles:** Close/finalizer integrator; close operator / orchestrator

**Evidence:** The plan correctly leaves mutation to finalizers and requires two § 7 gate reports, but treats finalizers as an enforcement backstop without specifying how report fields are bound to their arguments. The close workflow requires the recorded originating worktree to have the logged base branch checked out and tells close to rerun status immediately before finalization; this catches some target errors and dirtiness but not a stale commit list, stash list, inventory, or report parser result. A report can be “complete” yet not be the data finalizer consumes.

**Attack Vector:** Parse `REPO_ROOT`, `BASE_BRANCH`, and `EPHEMERAL_BRANCH` from a report generated before branch/worktree drift, then invoke a finalizer after a new commit or document appears. Or parse a warning-bearing human line as a clean result while still passing the original ref arguments. Finalizer may refuse a later gate, but it cannot validate that the inventory and narrative were current.

**Role-Specific Impact:**

- **Close/finalizer integrator:** Has two independently evolving contracts and no rule for report/result freshness; safety logic is duplicated rather than composed.
- **Close operator / orchestrator:** Pays the manual investigation cost the proposal claimed to remove and can still make an incomplete auxiliary-doc decision before the finalizer refuses.

**Blast Radius:** Any future A2/A4 consumer, cold-start standalone close, and automation that treats report output as an authorization-like handoff.

**Remediation:** Define the report as advisory evidence, not authorization; require consumer-side ref/worktree identity comparison and rerun on mismatch; make the finalizer invocation derive from freshly validated context rather than raw stale stdout. Add an integration-shaped fixture without changing finalizers in this plan.

### Finding 7: Auxiliary-document policy and inventory classification have incompatible scopes

**Severity:** Medium | **Likelihood:** Medium | **Wave:** 2

**Affects Roles:** Worktree / auxiliary-document author; close/finalizer integrator

**Evidence:** Framework policy says auxiliary workflows create artifacts without automatic commits, while close's documented sweep moves resolved auxiliary documents alongside the plan. The plan's inventory classifies paths as tracked-on-ephemeral, tracked-on-base, or untracked, but does not define whether a child-only untracked document is still-open, resolved, scratch, or safe to delete, nor who makes that decision. A classification is not reconciliation authority.

**Attack Vector:** Put a resolved red-team artifact in a child worktree, or an open review artifact on base, and run the report. The same `untracked`/`tracked-on-base` label can require opposite actions; the report has no lifecycle/status rule for selecting the correct one.

**Role-Specific Impact:**

- **Worktree / auxiliary-document author:** Cannot tell whether the document should be committed, moved, left open, or preserved before worktree removal.
- **Close/finalizer integrator:** May encode an unsafe automatic policy later, or leave all ambiguous docs for manual review and lose the proposed time savings.

**Blast Radius:** Mixed auxiliary chains (proposal → plan → redteam/stress/audit), especially when artifacts are intentionally uncommitted under the framework policy.

**Remediation:** Keep inventory factual but add explicit lifecycle fields (`status`, location, ref presence, child/root scope) and a close decision table owned by A4. Require human/orchestrator disposition for unresolved or child-only docs; do not infer “resolved” from tracking class.

### Finding 8: CI readiness can be reported as green while the new suite is absent from the actual runner

**Severity:** Medium | **Likelihood:** Medium | **Wave:** 2

**Affects Roles:** Release/CI owner; test/CI maintainer; Windows close operator

**Evidence:** Existing `tests/run-all.sh` and `tests/run-all.ps1` enumerate fixed suite arrays and aggregate only parsed `PASS=` lines. The plan says to add the new suites but does not require a runner assertion that each suite is executed exactly once, nor a distinct status when a platform runner is unavailable. A typo, wrong path, or conditional skip can leave the aggregate green if the suite is omitted rather than run.

**Attack Vector:** Register the suite in documentation but not the array, or add a path that fails before emitting `PASS=` and rely on the Bash runner's `${p:-0}` fallback. On a Bash-only host, no PowerShell aggregate runs. The plan's final verification can still observe the old runner's zero failures.

**Role-Specific Impact:**

- **Release/CI owner:** Ships a script pair without evidence that the new safety suite is part of the standard gate.
- **Test/CI maintainer:** Assertion count and aggregate output conceal missing execution.
- **Windows close operator:** Receives untested PowerShell behavior.

**Blast Radius:** Every future regression in the omitted suite; especially dangerous for report-only scripts whose failures do not mutate state and therefore are not caught by finalizer tests.

**Remediation:** Add runner-level assertions/log markers for exact suite membership and execution, fail on missing summary or nonzero process status, and report platform `NOT RUN` separately. Add a test that detects omission from each runner's suite list without relying on manual read-back.

### Finding 9: Untrusted report content can spoof the handoff without violating repository invariance

**Severity:** High | **Likelihood:** Medium | **Wave:** 3

**Affects Roles:** Attacker / malicious repository contributor; close operator / orchestrator; security/compliance reviewer

**Evidence:** The plan reads log headers, status lines, Git subjects, paths, and filesystem documents controlled by the repository context, then emits mixed machine-readable and human-readable output. It requires literal matching and strict fields but does not specify duplicate-header rejection, control-character/terminal-output handling, or an encoding boundary for untrusted values (Constraints; Success Criteria; Step 1). A state-invariance test does not prove that a human or parser interpreted the report safely.

**Attack Vector:** Supply duplicate `Repo Root`/`Base Branch`/`Worktree Path` headers with conflicting values, an inventory filename or commit subject containing terminal control sequences, or an auxiliary document whose status line is crafted to resemble a report record. If the implementation takes the first/last match inconsistently, or a caller parses raw lines, the attacker gains a wrong-target, hidden-document, or operator-confusion partial exploit without any repository mutation.

**Adversarial Impact:**

- **Attacker / malicious repository contributor:** Low-cost control of branch/log/document text can redirect attention or cause a stale/wrong close attempt; full compromise is unnecessary.
- **Close operator / orchestrator:** Cannot distinguish data from control text and may act on a spoofed record.
- **Security/compliance reviewer:** Sees green invariance tests while provenance/integrity of the emitted evidence is unproven.

**Blast Radius:** Any report consumed by a human, shell, PowerShell, or orchestration parser; finalizer target checks may stop the worst wrong-branch action but do not prevent confusion or omitted reconciliation.

**Remediation:** Treat all parsed fields and emitted values as untrusted: reject conflicting duplicate required headers, define control-character handling, encode/quote every field, use structured output for automation, and test spoofing/path cases. Keep the finalizer as an independent authorization boundary.

### Finding 10: The report-only security claim lacks a threat-model and read-command guard

**Severity:** High | **Likelihood:** Medium | **Wave:** 3

**Affects Roles:** Security/compliance reviewer; shell/PowerShell utility maintainer; attacker / malicious repository contributor

**Evidence:** The plan says no command may mutate refs, index, worktrees, files, stash state, or checkout and asks tests to prove observable invariance. It does not enumerate an allowlist of read-only Git commands, require static review of process invocation, or define behavior under concurrent path changes/symlink swaps (Constraints; Step 1; Step 3).

**Attack Vector:** A future implementation shells out with unquoted log/path data, uses a command with side effects while preserving the tested final state, or validates a path then reads a replaced symlink. A malicious contributor supplies branch/path/document values that exercise that gap. The attacker need not gain code execution: causing a false report, failed close, or unsafe operator decision is a cheaper partial win.

**Role-Specific Impact:**

- **Security/compliance reviewer:** Cannot defend “report-only” as a reviewed capability boundary from fixture results alone.
- **Utility maintainer:** Has no security checklist for Bash eval/quoting, PowerShell process argument passing, or TOCTOU behavior.
- **Attacker:** Probes the least-tested platform and path form; effort is low because the report consumes repository-controlled strings.

**Blast Radius:** All repositories invoking the utility, with greater exposure when orchestration runs it automatically or when the report is treated as close input.

**Remediation:** Add a read-only Git command allowlist and forbidden-command review, shell-safe argument tests, symlink/path-race policy (or explicit non-concurrent precondition), and security-focused fixtures on both platforms. Keep no-execution authorization unchanged.

### Finding 11: Deferred ownership permits premature downstream adoption

**Severity:** High | **Likelihood:** High | **Wave:** 3

**Affects Roles:** Framework owner / release maintainer; close/finalizer integrator; close operator / orchestrator; security/compliance reviewer

**Evidence:** The source proposal calls A1 a mandatory close preflight and says it replaces manual investigation, while the plan explicitly defers all close/orchestrator consumer changes to A2–A4 and leaves the output grammar, freshness, child scope, and lifecycle disposition unresolved. No acceptance gate names who owns the schema or blocks a later consumer from parsing the initial human-oriented output.

**Attack Vector:** A future close/orchestrate change consumes `REPO_ROOT`, `BASE_BRANCH`, or inventory lines opportunistically before A2/A4 resolves the contract. A framework maintainer assumes the plan's Ready status and `PRE-CHECK PASSED WITH WARNINGS` are sufficient; a consumer then ossifies ambiguous semantics that cannot be changed without compatibility breakage.

**Role-Specific Impact:**

- **Framework owner / release maintainer:** Inherits a de facto public interface without versioning or owner, making future corrections costly.
- **Close/finalizer integrator:** Builds one-off parsing and freshness rules that diverge from later plan revisions.
- **Close operator / orchestrator:** Receives inconsistent behavior across standalone and chained closes.
- **Security/compliance reviewer:** Cannot identify a single accountable decision-maker for report trust and lifecycle safety.

**Blast Radius:** A1 adoption can spread to all close workflows before the later modernization axes land; remediation then becomes a breaking change rather than a pre-implementation fix.

**Remediation:** Make A1's readiness conditional: freeze and own a schema/consumer contract, or label output experimental and forbid automation consumption until A2/A4. Add explicit owner, version, compatibility policy, and adoption gate to the plan; do not rely on future work to retroactively secure a published interface.

---

## Held

### Report-only boundary

**Tried:** Checkout, stage, commit, stash, merge, rebase, worktree registration, cleanup, and ref mutation as shortcuts to discover state.
**Held because:** The plan explicitly forbids mutation and requires fixture invariance (Constraints; Success Criteria; Step 3). This is a sound safety boundary; the red-team concern is stale/ambiguous evidence around it, not an accusation that the proposed utility should mutate.

### Base branch source

**Tried:** Guessing `main`/`master`, accepting a tag/SHA/remote-tracking ref, or silently inferring the base from current branch history.
**Held because:** The plan requires the execution log's strict `> **Base Branch:**` field, local-branch validation, and non-zero failure for missing/invalid context (Success Criteria; Resolved Decisions). This preserves the close finalizer's recorded-parent rule.

### Explicit both-ref classification

**Tried:** A related document tracked on both base and ephemeral refs.
**Held because:** The plan gives `tracked-on-ephemeral` precedence and requires an `also-on-base` annotation, with a dedicated test case (Success Criteria; Step 3; Resolved Decisions). The remaining weakness is output encoding and child-worktree scope, not missing precedence.

### Finalizer cleanliness bars

**Tried:** A report-only script silently authorizing dirty originating or child worktrees, or using one cleanliness bar for both.
**Held because:** `close-projex.md` § 7 and the finalizer scripts distinguish tracked-clean originating state from fully-clean child state; the plan mirrors both and keeps finalizers authoritative. The finding is that those gates do not reconcile omitted documents or stale evidence.

### Adversarial read-only bypass

**Tried:** Treating a malformed log, unusual path, duplicate header, terminal-control subject, or child-only document as proof that the script should mutate or clean up.
**Held because:** The plan's hard report-only constraint is correct: adversarial input must cause rejection or visible evidence, never checkout/commit/stash/worktree cleanup. The missing threat model and encoding are reasons to strengthen implementation/tests, not to authorize mutation.

---

## Role-Based Assumption Challenges

### Close operator / orchestrator: “A complete report is safe to hand to close”

**Challenge:** The report is stdout without snapshot identity, schema version, or mandatory close integration; repository state and consumer obligations remain external.
**Counter-Evidence:** Plan Summary says the utility replaces manual discovery, but Out of Scope excludes `close-projex.md`, and no drift rule is specified.
**If Wrong:** Operator narrates stale commits/inventory or treats warning-bearing exit 0 as approval; close rework or incomplete reconciliation follows.
**Action:** Reject the “safe handoff” implication until snapshot/rerun and consumer semantics are explicit; retain report-only scope.

### Shell/PowerShell utility maintainer: “Strict Markdown plus Git text is a stable interface”

**Challenge:** Strict headers constrain context parsing but do not define output serialization; Git and filesystem strings have platform-sensitive quoting and line behavior.
**Counter-Evidence:** The plan names key fields/sections but no escaping or record grammar.
**If Wrong:** A later parser diverges across platforms or drops a path/record.
**Action:** Reject; define protocol and fixtures.

### Test/CI maintainer: “Independent suites establish parity even if one runtime is absent”

**Challenge:** Independent tests only establish parity where both execute; a documented limitation is not a passing test.
**Counter-Evidence:** Step 3 allows no-PowerShell environments to record limitation while Verification Plan lists parser/runtime acceptance.
**If Wrong:** Windows-only defects ship unobserved.
**Action:** Relax the completion claim; require platform evidence or mark cross-platform readiness conditional.

### Worktree / auxiliary-document author: “Repo-root inventory covers all related documents”

**Challenge:** The scan excludes `.projexwt`, precisely where a child-only filesystem artifact resides.
**Counter-Evidence:** Plan Constraints explicitly exclude `.projexwt`; close § 7's child gate only reports leftovers and does not classify their lifecycle.
**If Wrong:** A document disappears with the child worktree or forces late manual recovery.
**Action:** Reject the completeness claim; scan child roots or make the exclusion an explicit, tested close obligation.

### Close/finalizer integrator: “Finalizer gates make any precheck handoff safe”

**Challenge:** Finalizers validate target checkout and cleanliness at mutation time but do not validate report snapshot, inventory completeness, or parser semantics.
**Counter-Evidence:** No report identity/rerun contract exists; close workflow's finalizer call consumes separately supplied arguments.
**If Wrong:** Stale narrative and unclassified aux docs survive a successful merge/cleanup.
**Action:** Relax: finalizer remains enforcement, while consumer must compare and rerun advisory evidence.

### Release/CI owner: “Runner aggregation proves the new suite ran”

**Challenge:** Aggregators parse summary output from a fixed list; omission from that list is indistinguishable from a zero-assertion suite unless runner membership is tested.
**Counter-Evidence:** Existing runners enumerate arrays and default missing Bash counts to zero; the plan asks for registration but no exact-membership assertion.
**If Wrong:** A green gate ships without close-precheck coverage.
**Action:** Reject; fail closed on missing suite execution and distinguish platform `NOT RUN`.

### Attacker / malicious repository contributor: “Strict fields prevent report spoofing”

**Challenge:** Strict syntax does not make field values or emitted Git/document text trusted; duplicate headers, terminal controls, and path timing remain attack surfaces.
**Counter-Evidence:** No duplicate conflict rule, output encoding, read-command allowlist, or concurrent-path policy is in the plan.
**If Wrong:** A low-effort partial exploit causes wrong-target attention, hidden reconciliation, or denial of close.
**Action:** Reject; treat all repository-controlled strings as untrusted and retain finalizer authorization.

### Security/compliance reviewer: “Fixture invariance proves report-only safety”

**Challenge:** End-state invariance cannot establish command allowlisting, argument safety, or provenance integrity under malformed/concurrent inputs.
**Counter-Evidence:** Plan requests before/after state checks but no threat model or static/process audit.
**If Wrong:** A side effect or unsafe interpretation can escape the test matrix.
**Action:** Relax the evidence claim; add security-focused process/path checks.

### Framework owner / release maintainer: “Later A2/A4 will resolve the contract before adoption”

**Challenge:** The proposal labels A1 mandatory and independently actionable, while no owner or gate blocks consumers from using its output early.
**Counter-Evidence:** A1 is Ready and documentation/discoverability are in scope; consumer changes are merely out of scope, not prohibited.
**If Wrong:** An ambiguous interface becomes de facto public and later fixes become breaking.
**Action:** Reject; make readiness conditional on a versioned owner-backed contract or mark output experimental/non-consumable.

---

## Role-Specific Edge Cases & Failures

### Close operator / orchestrator: report consumed after repository drift

**Trigger:** New ephemeral commit, changed base checkout, new stash, or auxiliary document change after report generation.
**Role Experience:** Fields look valid; finalizer may later reject state, but commit/inventory narrative is stale and must be rebuilt manually.
**Recovery:** Difficult — rerun is possible but no comparison signal tells the role when it is mandatory.
**Mitigation:** Ref/worktree snapshot IDs, generation metadata, and explicit rerun-on-mismatch rule.

### Shell/PowerShell utility maintainer: symlinked or relative worktree path

**Trigger:** `Worktree Path` is relative, symlinked, reused, or normalized differently by Bash and PowerShell.
**Role Experience:** Wrong repo inspected or valid context rejected; failure may look like a missing branch/log rather than path confusion.
**Recovery:** Difficult — manual path investigation before any close.
**Mitigation:** Canonical containment and exact registered path/branch/HEAD fixtures.

### Test/CI maintainer: PowerShell unavailable

**Trigger:** Linux-only runner executes Bash suite and skips the PowerShell parser/runtime.
**Role Experience:** `close-precheck.ps1` is present and reviewed but has no executable evidence.
**Recovery:** Difficult — deferred Windows discovery.
**Mitigation:** Required PowerShell CI job; explicit `NOT RUN` result that cannot satisfy parity acceptance.

### Worktree / auxiliary-document author: child-only resolved artifact

**Trigger:** A related document is created in a child `.projex` folder, remains untracked, and the child worktree is removed after merge.
**Role Experience:** No inventory row; close sees only a generic child cleanliness warning or removal failure.
**Recovery:** Difficult/Possibly impossible after deletion if no external copy exists.
**Mitigation:** Include child roots in inventory or require an explicit human disposition before cleanup.

### Close/finalizer integrator: report and finalizer disagree

**Trigger:** Report generated before branch/worktree drift; finalizer arguments are copied from stale output.
**Role Experience:** Finalizer may reject one gate while the operator has already acted on stale inventory; partial close/retry complexity increases.
**Recovery:** Difficult — finalizer safety is preserved, but report lineage must be rebuilt manually.
**Mitigation:** Snapshot comparison and a single fresh context-resolution handoff.

### Release/CI owner: suite omitted from aggregator

**Trigger:** Runner array or path is wrong, suite emits no summary, or only one OS runner executes.
**Role Experience:** Aggregate `FAIL=0` does not prove the new suite ran; release decision is ambiguous.
**Recovery:** Difficult — requires inspecting runner implementation and obtaining the missing platform.
**Mitigation:** Exact membership/execution assertions and fail-closed aggregation.

### Attacker / malicious repository contributor: crafted report values

**Trigger:** Conflicting log headers, terminal-control path/subject, child-only document, or a path replaced between validation and read.
**Role Experience:** Partial exploit yields operator confusion, wrong context, omitted reconciliation, or denial of close at low authoring cost.
**Recovery:** Difficult if consumer has already narrated or acted; finalizer may stop mutation but not undo reasoning/work.
**Mitigation:** Reject conflicts, encode output, canonicalize/pin paths, allow only read commands, and require fresh finalizer validation.

### Security/compliance reviewer: safety claim without provenance

**Trigger:** Report passes fixture invariance but no schema, source identity, command allowlist, or threat-case evidence exists.
**Role Experience:** Cannot produce a defensible audit trail for why report output was safe to consume.
**Recovery:** Difficult — requires reconstructing implementation/process assumptions.
**Mitigation:** Versioned protocol, snapshot IDs, security test matrix, and explicit advisory-vs-authorization boundary.

### Framework owner / release maintainer: experimental output adopted as API

**Trigger:** A2/A4 or an external automation parses initial output before contract ownership and compatibility rules are recorded.
**Role Experience:** Future correction creates cross-workflow drift or breaking migration.
**Recovery:** Difficult/expensive — consumers must be found and migrated.
**Mitigation:** Block automation until schema owner/compatibility gate exists; document experimental status.

---

## What's Hidden (Per Role)

**Omissions per role:**

- **Close operator / orchestrator:** No persisted report artifact, schema/version, freshness rule, required consumer invocation, or explicit mapping from `WARN` to close action.
- **Shell/PowerShell utility maintainer:** No canonical escaping, path containment algorithm, relative worktree semantics, or supported Git-output grammar.
- **Test/CI maintainer:** No runtime support matrix, coverage threshold for adversarial path cases, drift test, or proof that runner registration executes exactly once.
- **Close/finalizer integrator:** No ownership boundary for choosing report fields versus freshly recomputed finalizer arguments, and no atomic “precheck then close” handoff.
- **Worktree / auxiliary-document author:** No child-only document disposition, no distinction between scratch and resolved auxiliary artifact, and no deletion-preservation guarantee.
- **Release/CI owner:** No required OS matrix, suite-membership assertion, or fail-closed status for omitted/unavailable platform jobs.
- **Attacker / malicious repository contributor:** No abuse case for conflicting headers, terminal-control output, symlink replacement, or partial disruption; no explicit trust boundary around repository-controlled values.
- **Security/compliance reviewer:** No threat model, read-only command allowlist, provenance identity, or evidence standard separating end-state invariance from safe interpretation.
- **Framework owner / release maintainer:** No named schema owner, compatibility/version policy, adoption gate, or prohibition on premature consumer integration.

**Tradeoffs per role:**

- **Close operator / orchestrator:** Gains deterministic discovery but inherits another transient handoff and still carries manual work because integration is deferred.
- **Shell/PowerShell utility maintainer:** Gains a narrow report-only scope but pays for duplicated security-sensitive parsing without a shared implementation/spec.
- **Test/CI maintainer:** Gains throwaway fixture isolation but accepts platform gaps and may measure assertion counts rather than consumer correctness.
- **Close/finalizer integrator:** Gains a report-only discovery primitive but inherits two contracts and must build the missing freshness/integration layer later.
- **Worktree / auxiliary-document author:** Gains ref/tracking classification but loses visibility into child-only docs if the exclusion remains.
- **Release/CI owner:** Gains independent suites but pays for duplicated cross-platform maintenance and a support matrix not in the plan.
- **Attacker / malicious repository contributor:** Gains cheap control of input strings and timing; defenses are spread across parser, path, test, and finalizer layers rather than one atomic boundary.
- **Security/compliance reviewer:** Gains a narrow no-mutation objective but must reject broad safety claims unsupported by threat evidence.
- **Framework owner / release maintainer:** Gains incremental delivery but risks an unowned interface that later workflows depend on.

---

## Scale & Stress (Role Impact)

**At 10x:**

- **Close operator / orchestrator:** Ten related documents or a moderate delay make raw output parsing and stale evidence materially harder; one missed inventory entry triggers manual reconciliation.
- **Shell/PowerShell utility maintainer:** Ten `.projex` folders and paths with varied characters expose traversal, deduplication, and quoting differences.
- **Test/CI maintainer:** Ten platform/fixture combinations multiply runtime gaps; a Bash-only runner still gives no PowerShell confidence.

**At 100x:**

- **Close operator / orchestrator:** Hundreds/thousands of candidate files can produce an unwieldy report with no truncation/size contract; stdout becomes an operational failure mode.
- **Shell/PowerShell utility maintainer:** Recursive scans and ref/filesystem joins can time out or diverge; absent budget/truncation semantics invites silent omission.
- **Test/CI maintainer:** Large fixtures expose cleanup, timeout, and output-limit failures not represented in the required matrix.
- **Close/finalizer integrator:** At 10x consumers, report parsing and finalizer argument derivation become separate integration code; at 100x stale/incomplete handoffs create repeated close retries.
- **Worktree / auxiliary-document author:** At 10x mixed aux docs, tracking class no longer indicates lifecycle; at 100x child folders, omitted files make manual recovery unbounded and deletion risk material.
- **Release/CI owner:** At 10x platform/version combinations, duplicated behavior drifts; at 100x skipped runners and output limits can make aggregate green status meaningless.
- **Attacker / malicious repository contributor:** At 10x crafted paths/logs, one parser discrepancy can target many consumers; at 100x automation magnifies one spoofed field into repeated wrong closes or denial-of-service work.
- **Security/compliance reviewer:** At 10x repos, manual provenance review is untenable; at 100x an unversioned advisory report becomes an unbounded compliance exception.
- **Framework owner / release maintainer:** At 10x consumers, schema drift fragments behavior; at 100x retrofitting ownership and migration is a framework-wide breaking change.

---

## Wave 1 Close

Wave 1 found four direct-role weaknesses: output is described as machine-readable without a grammar; report evidence has no snapshot boundary; recorded path/worktree validation lacks exact canonical semantics; and PowerShell parity may be accepted without PowerShell execution. The report-only boundary, local logged base requirement, and both-ref classification survived attack. These written findings derive Wave 2 roles; no Wave 2 role is attacked before this record.

## Wave 2 Close

Wave 2 attacked only roles derived from written Wave 1 findings. It exposed a direct inventory omission for child-only `.projex` files, a gap between finalizer safety gates and stale/incomplete report evidence, an unresolved lifecycle decision for untracked auxiliary documents, and runner aggregation that can stay green when the new suite or platform is absent. The finalizer's two cleanliness bars survived as enforcement, but they do not repair discovery or handoff defects. These findings derive Wave 3 adversarial and accountable roles.

## Wave 3 Close

Wave 3 attacked only the attacker and accountable roles derived from written Wave 2 findings. It found that repository-controlled strings can spoof a mixed report even when no files/refs mutate; that end-state invariance is not a complete security/threat-model proof; and that deferred A2/A4 ownership permits premature adoption of an unversioned interface. The report-only boundary and finalizer authorization survived; no fourth wave is opened. The final cross-wave pass follows.

## Final Cross-Wave Pass

- **Attacker → direct parser/consumer → accountable finalizer:** Crafted headers, paths, subjects, or child documents exploit Finding 1/3/5/9; a close operator or future integrator consumes ambiguous/stale output (Findings 2/6); finalizer gates may stop wrong checkout or leftover child content, but cannot restore omitted lifecycle decisions or undo a misleading narrative.
- **Missing PowerShell evidence → release owner → all roles:** Findings 4/8 leave a platform-specific parser/path defect unobserved; the framework owner adopts the output (Finding 11); Windows operators and security reviewers inherit a contract that was never executed on their platform.
- **Auxiliary policy → child worktree deletion:** Findings 5/7 allow a resolved artifact to be omitted and later removed with the child; the attacker need not be malicious for the loss, while a malicious author can exploit the same ambiguity to hide a document. The child gate is a useful refusal, not proof of preservation.
- **Report-only boundary → evidence trust:** Findings 2/6/10 show that non-mutation is necessary but insufficient: a truthful state snapshot, safe encoding, path identity, and consumer freshness are needed before report output can shorten close safely.

**Roles surfacing after wave 3:** Support/incident responder surfaced in the cross-wave cascade (who reconstructs a failed or disputed close from logs and reports) but was not attacked; record under Roles Not Attacked rather than opening a fourth wave.

---

## Remediation

### Must Fix (Before Proceeding)

- **Freeze a versioned, parseable output contract** (affects: all roles) → define record types, escaping/control-character policy, duplicate handling, `NONE`, warnings/errors, terminal result, and snapshot fields; name an owner and add adversarial parity fixtures.
- **Bind evidence to state and consumer behavior** (affects: close operator/orchestrator, integrator, security) → emit ref/worktree identities and generation metadata; define rerun-on-drift; mark report advisory, not authorization; block downstream parsing until the contract exists.
- **Resolve child-worktree inventory scope and auxiliary lifecycle** (affects: worktree/aux authors, integrator) → scan recorded child roots or explicitly exclude them with a mandatory close inspection/disposition protocol; do not claim every `.projex` file while pruning `.projexwt`.
- **Specify path and untrusted-input security** (affects: maintainers, attacker, security) → canonical containment, relative-path rule, duplicate-header rejection, safe argument passing, output encoding, read-only command allowlist, and concurrency/symlink policy.
- **Make platform readiness fail closed** (affects: release/CI, Windows operators) → require PowerShell parser/runtime CI or mark cross-platform acceptance `NOT RUN`; assert each suite executes exactly once and missing summaries fail.

### Should Fix (Before Production)

- **Scale and output budgets** (affects: all operators/maintainers) → benchmark multi-folder repositories; batch queries; report explicit truncation/failure, never silently drop inventory.
- **Format compatibility path** (affects: framework owner) → version/centralize log-header parsing, distinguish unsupported historical logs from malformed context, and add old/current fixtures.
- **Integration-shaped drift test** (affects: integrator) → generate a report, change refs/docs/stash, and prove consumer rerun detection without changing finalizer behavior.

### Monitor

- **A2/A4 adoption** (affects: framework owner, integrator) → ensure close/orchestrate invokes and parses only the owned schema.
- **Child-artifact loss/removal failures** (affects: aux authors, support) → measure omitted docs, worktree cleanup refusals, and manual recovery.
- **Platform drift and parser defects** (affects: release/CI) → track Windows/PowerShell failures and Git-version differences.

---

## Final Assessment

**Soundness:** Serious Issues
**Risk:** High
**Readiness:** Needs Work

**Per-Role Readiness:**

- **Close operator / orchestrator:** Not Ready — output lacks schema/freshness and current workflow integration; exit 0 with warnings is not a safe handoff.
- **Shell/PowerShell utility maintainer:** Not Ready — path, untrusted-input, and cross-platform grammar are underspecified.
- **Test/CI maintainer:** Not Ready — the required matrix omits threat/drift cases and platform execution may be absent.
- **Close/finalizer integrator:** Not Ready — finalizer gates do not bind or refresh report evidence.
- **Worktree / auxiliary-document author:** Not Ready — child-only inventory and lifecycle disposition are unresolved.
- **Release/CI owner:** Not Ready — runner membership and platform readiness can be ambiguous.
- **Attacker / malicious repository contributor:** Attack opportunity remains — controlled strings and timing can cause partial disruption at low cost.
- **Security/compliance reviewer:** Not Ready — end-state invariance is not sufficient provenance/threat evidence.
- **Framework owner / release maintainer:** Not Ready — no schema owner or adoption gate.

**Conditions for Approval:**

- [ ] Versioned machine-readable output and snapshot/rerun rule are specified and tested (all consumer roles).
- [ ] Child-worktree inventory/lifecycle behavior is explicit, tested, and preserves documents before cleanup (aux authors/integrator).
- [ ] Canonical path, safe argument, duplicate-header, and untrusted-output rules pass on both platforms (maintainers/security).
- [ ] PowerShell evidence and exact runner execution are available; `NOT RUN` cannot satisfy parity (release/CI).
- [ ] A named schema owner blocks A2/A4 automation until the A1 contract is stable (framework/integrator).

**No-Go If:**

- [ ] A1 is implemented or documented as machine-readable while record grammar, escaping, and schema version remain undefined.
- [ ] The report claims complete inventory while excluding child-worktree `.projex` content without a mandatory disposition path.
- [ ] Any downstream consumer treats exit 0 or `PRE-CHECK PASSED WITH WARNINGS` as authorization without fresh identity comparison.
- [ ] Cross-platform acceptance is marked complete with PowerShell suites/parser not run.

---

## Validation

- [x] Exactly three sequential waves run; no fourth wave opened.
- [x] Wave 2 roles trace to written Wave 1 findings; Wave 3 roles trace to written Wave 2 findings.
- [x] Each wave's roles were attacked only after the preceding wave was recorded.
- [x] Each role has an independent attack surface, assumption challenge, edge case, hidden tradeoff, and scale impact.
- [x] Held claims are recorded; severity ratings cite plan/workflow evidence and role impact.
- [x] Post-wave-3 cross-wave cascade pass completed.
- [x] Post-wave-3 Support / incident responder role recorded under Roles Not Attacked; no fourth wave opened.
- [x] Bottom Line synthesized last from the completed findings.
