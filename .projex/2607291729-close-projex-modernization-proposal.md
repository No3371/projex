# Proposal: close-projex Modernization

> **Status:** Draft
> **Author:** Claude (fable) via orchestrate-projex
> **Related Projex:** 2607132112-projex-rebase-close-scripts-redteam.md | 2607152043-agent-close-lock-plan.md | 2607261121-close-scripts-dirty-base-safety-plan.md (closed) | 2607261520-close-scripts-dirty-base-safety-audit.md (closed)
> **Plans:** 2608081953-close-precheck-script-plan.md (A1) | 2607291750-close-projex-evidence-and-tiers-plan.md (A2+A3) | 2607291750-close-projex-aux-docs-and-keyed-intake-plan.md (A4) — open questions resolved in the plans' Notes → Resolved Questions

---

## Summary

close-projex spends most of its runtime on model composition, not git work — a measured close: 83% reasoning/drafting, 17% tool execution. Proposes modernizing the workflow on four axes: mechanize state discovery (a `close-precheck` script, mirroring `execute-precheck`), stop re-deriving verification execute already produced (evidence-consumption instead of re-verification), right-size the walkthrough template (tiers + derive-from-log rule), and define the two situations the spec predates — untracked auxiliary docs and standalone orchestrated dispatch.

**Recommended:** Option A (incremental hardening) + the evidence-consumption verification rule. Defer structural decomposition (Option B).

---

## Problem Statement

### Current State

`close-projex.md` is a monolithic workflow: gather execution data (§ 1) → document actual changes (§ 2) → verify success criteria (§ 3) → capture insights (§ 4) → draft walkthrough from a maximal single-tier template (§ 5) → finalize documents incl. aux-doc sweep (§ 6) → finalize branch via scripts (§ 7) → restore stash (§ 8).

The git-ceremony half (§ 6–8) is well-mechanized — close scripts with gates, rollback, conflict handling, tests. The analysis half (§ 1–5) is entirely freehand: the agent manually reconstructs git state, re-reads the plan in full, re-derives the diff, re-verifies criteria, then composes the largest template in the framework.

### Gap / Need — grounded in a measured close

User-run timing of a real close transcript (117 steps, ~15m23s wall-clock):

> 771s of the 923s total (83%) was the model composing/reasoning — not tools running. Actual tool/script execution summed to only 152s (17%), and no single command took more than 21.5s.

Three biggest chunks, all thinking/drafting:

| Chunk | Time | Root cause in the spec |
| --- | --- | --- |
| Untracked-vs-tracked doc reconciliation | ~2m40s | Aux docs (review/redteam/proposal) sit **untracked on base** per SKILL.md Auxiliary Artifact Commit Policy, while plan+log live tracked on the ephemeral branch. close's sweep (§ 6.3) silently assumes every doc is committed and movable — the agent must discover and resolve the mismatch itself |
| Plan re-read + diff reconstruction | ~3m | § 1–2 direct full plan read + manual `git log`/`diff --stat`/`diff` reconstruction across all commits — no mechanized precheck exists for close (execute has `execute-precheck`) |
| Walkthrough drafting | ~2m26s | § 5 template is one-size-fits-all maximal: per-step Execution Detail + Complete Change Log + criteria verification + deviations + issues + insights + recommendations + appendix — much duplicating the execution log, which survives alongside the walkthrough in `closed/` anyway |

Specific gaps:

1. **Verification duplication.** execute-projex § 7 already runs full verification, validates every success criterion with documented proof, and commits that evidence to the log. close § 3 then re-verifies each criterion from scratch. Meanwhile `verify-projex` exists as the framework's independent-checking contract — close neither consumes execute's recorded evidence nor reuses the verifier machinery. (User: "We recently added verify-projex. close-projex also contains verification, right? Can it use it?")
2. **No state-discovery mechanization.** execute gets `execute-precheck` emitting `REPO_ROOT`/`BRANCH`/`PLAN_REL` as the mandatory first action. close § 0–2 asks the agent to hand-derive repo root, base branch (from log), commit list, changed files, and doc inventory — the exploratory phase the timing data shows is expensive.
3. **Aux-doc lifecycle undefined at close time.** Spec's sweep predates the auxiliary commit policy and today's usage: "close was designed with plan, execute in the early days. Nowadays we often use these with review, redteam, audit, etc." Modular composition means no fixed lineage is guaranteed — per the user: "plan→execute lineage isn't guaranteed. Nor redteam and audit. I was saying that it can take advantages of prior steps but should not depend on them." Aux docs may exist in any mix of tracked/untracked, base/ephemeral, resolved/still-open, or not at all — the spec addresses only the resolved-and-tracked case.
4. **Standalone dispatch friction.** "Close could be orchestrated as a standalone step." Invocation is bare `/close-projex.md` — no arguments. Prerequisites read as same-session continuity with execute ("execution log/notes are available", "user has reviewed"). A cold close agent must rediscover which plan, which branch, which log — from nothing.
5. **Walkthrough duplicates the log.** Both files move to `closed/` together; the template re-narrates per-step detail the log already carries with timestamps and evidence.

### Why Now?

Three converging triggers: `verify-projex` just landed (reuse question is fresh); orchestrate-projex now dispatches close as a standalone chain step (cold-start cost multiplies per orchestration); token-cost observation is measured, not anecdotal — the 83/17 split says optimization belongs in the spec's analysis half, not the scripts.

---

## Proposed Change

### Overview

Modernize `close-projex.md` in place: mechanize what is deterministic, consume evidence instead of re-deriving it, scale the walkthrough to the execution, and specify the two undefined situations (untracked aux docs, standalone dispatch). Keep the § 6–8 git ceremony untouched — it is the part that already works.

### Approach Options

#### Option A: Incremental hardening (keep monolith)

Four independent, separately-landable changes:

- **A1 — `close-precheck.{sh,ps1}`.** Mirror of `execute-precheck`; mandatory first action of close. Input: plan file (or infer from branch name). Emits: `REPO_ROOT`, `BASE_BRANCH` (parsed from log header — fail loudly if absent), `EPHEMERAL_BRANCH`, commit list (`log --oneline base..HEAD`), `diff --stat base..HEAD`, **doc inventory** — every `.projex/` file referencing the plan, classified tracked-on-ephemeral / tracked-on-base / untracked, with `> **Status:**` line each — plus stash entries and the two § 7 cleanliness gates as PASS/WARN. Inventory is discovery-based — reports what exists, expects nothing; an execution with no aux docs (or no evidence trail) is a normal report, not a warning. Replaces the ~5m40s of manual investigation with one deterministic script read. No mutations — report-only, same contract as execute-precheck.
- **A2 — Evidence-consumption verification (opportunistic, never dependent).** Rewrite § 3 around the principle: **prior-step artifacts are accelerators close may exploit, never prerequisites it depends on.** Per criterion: log/plan carries recorded evidence (execute § 7 output, verify-projex verdicts folded into log entries, audit/redteam findings) → cite it, done. Evidence missing, stale, or the lineage never existed (no execute § 7 pass, no aux workflows ran) → close verifies that criterion itself, exactly as today — full self-verification remains the defined floor, not a failure mode. Never silently re-derive what is already proven; never assume anything is. Answers the verify-projex question directly: **no reuse as-is** — verify-projex is step-scoped, pre-commit, executor-spawned by contract (SKILL.md § Sub-Workflows: caller-only invocation, never nests) — but its *posture* transfers: trust nothing unevidenced, re-test cheaply where unproven.
- **A3 — Tiered walkthrough + derive-from-log rule.** Two tiers. **Light** (execution matched plan, ≤ ~3 steps, no deviations, all criteria evidenced): Summary + criteria table + change log stat + insights — one screen. **Standard** (deviations, partial results, interventions, or user request): current full template. Both tiers: per-step narration is *derived from the log by reference*, not re-composed — walkthrough records outcome + deviation-from-plan; the log (moved alongside) keeps the blow-by-blow.
- **A4 — Aux-doc reconciliation protocol + optional keyed intake.** New § 6 sub-step, driven by A1's inventory: untracked aux doc resolved by this plan → commit it on base (its policy-mandated pending commit) then sweep; untracked and still-open → leave untracked, note in walkthrough; tracked cases → existing sweep table. And an optional keyed invocation form — `/close-projex.md plan=<file> [repo=] [base=]` — for orchestrated dispatch; bare invocation with session context stays valid. Keyed args make close cold-startable without reclassifying it as a sub-workflow (it remains human/orchestrator-dispatched, produces a document, keeps its own ceremony).

**Pros:** Each piece lands independently; no lifecycle changes; directly targets all three measured cost chunks; scripts testable under `tests/`.
**Cons:** Monolith remains — a single agent still holds full context across analysis + authoring + ceremony; composition time shrinks but is not restructured away.
**Effort:** Medium. A1 largest (new script pair + tests); A2–A4 are spec edits.

#### Option B: Structural decomposition (close as coordinator)

Split close into three phases with distinct contracts: **Reconcile** (mechanical: precheck + doc sorting), **Author** (walkthrough composition — delegable to a fresh-context sub-agent fed only log + diff + criteria evidence, mirroring the do/verify delegation pattern), **Ceremony** (§ 6–8 as-is). Coordinator dispatches phases, reviews authored walkthrough, runs ceremony.

**Pros:** Context isolation for the expensive authoring chunk; walkthrough author starts undrifted (same rationale as verify-projex); natural fit with orchestration.
**Cons:** New sub-workflow contract to specify/maintain (SKILL.md § Sub-Workflows currently parents both existing ones under execute — close as a second parent is a framework change); spawn overhead may eat the savings on small closes; walkthrough quality depends on log quality more than today — thin logs produce thin walkthroughs with no memory to fall back on; higher blast radius.
**Effort:** High.

### Recommended Approach

**Option A.** The measured cost is dominated by re-derivation and over-composition, both addressable by spec edits + one script pair without touching lifecycle or sub-workflow contracts. Option B's isolation benefit is real but its precondition — a log reliable enough to author from alone — is exactly what A2/A3's derive-from-log discipline builds. Revisit B after A has bedded in and log quality under the new rules is observed. Land order: A1 → A2+A3 (joint spec edit) → A4.

---

## Impact Analysis

### Affected Areas

- `close-projex.md`: § 1–3 rewritten around precheck output + evidence consumption; § 5 tiered template; § 6 aux-doc protocol; invocation section gains keyed form
- New `close-precheck.{sh,ps1}` + behavioural tests under `tests/` (read-only script — lighter bar than the close scripts, but its BASE_BRANCH/inventory parsing feeds destructive downstream steps, so tested)
- `execute-projex.md`: minor — § 7 evidence recording named as the contract close consumes (tightens the existing step, no behavior change)
- `orchestrate-projex.md`: close handoff can carry keyed args (doc note only)
- `SKILL.md`: script table entry for close-precheck
- Untouched: close scripts (`projex-{squash,merge,rebase}-close`, `projex-abandon`), `verify-projex.md`, `do-projex.md`, sub-workflow rules

### Dependencies

- Requires: nothing hard. Log header discipline (`Base Branch:`, `Status:`) accelerates A1. The revised A1 plan treats missing/ambiguous/unsupported log context as a hard precheck error with no guessed base; close's manual fallback remains available before A1 adoption or when the utility is unavailable.
- Blocks: nothing. Future Option B would require A2/A3 first

### Risks

| Risk | Likelihood | Impact | Mitigation |
| ------ | ------------ | -------- | ------------ |
| Light-tier walkthrough under-records; history value degrades | Med | Med | Tier gate is objective (deviations/interventions/partial force Standard); log always moves alongside; user can demand Standard |
| Evidence-consumption trusts a drifted/dishonest log | Med | Med | A2 requires spot re-run of automated checks when evidence is stale or unquoted; criteria without evidence are always re-verified |
| close-precheck scope creep toward mutation | Low | High | Contract fixed report-only; gates stay enforced by the finalizer scripts themselves (existing double-gate design unchanged) |
| Keyed intake drifts close toward sub-workflow semantics | Low | Med | A4 states explicitly: args are convenience context, not a caller-guarantee contract; close keeps validating its own prerequisites |
| A1 doc-inventory misclassifies in multi-`.projex/`-folder repos | Med | Low | Inventory scans by plan-filename reference (framework guarantees filename uniqueness); report includes folder of each hit |

### Breaking Changes

None. Bare `/close-projex.md` invocation, all four merge options, gates, and exit codes unchanged. Existing walkthroughs unaffected (historical records, never edited).

---

## Open Questions

- [ ] Light-tier gate: is "≤ ~3 steps, zero deviations, all criteria evidenced" the right line, or should the tier be user-selected with a recommended default?
- [ ] Should A2's "re-run stale automated checks" have a cost ceiling (e.g., skip long suites, record as unverified-at-close) or always run?
- [ ] A4: when close commits a previously-untracked resolved aux doc, commit on base before merge or on the ephemeral branch as part of the close commit? (Base matches policy intent; ephemeral keeps the close atomic.)
- [ ] Does close-precheck also serve `debug-projex` closure (Option A path) — worth generalizing the branch/inventory report, or keep plan-close-specific?
- [ ] Orchestration: should orchestrate-projex pass the execute subagent's completion report to the close subagent as a prior-finding pointer, further cutting cold-start cost?

---

## Next Steps

If accepted:

1. `/plan-projex.md` for A1 (`close-precheck` script pair + tests) — largest, independent piece
2. `/plan-projex.md` (or patch, if small enough) for A2+A3 spec rewrite of `close-projex.md` § 1–5
3. Patch for A4 (aux-doc protocol + keyed intake + orchestrate note)
4. After adoption: measure a comparable close; revisit Option B only if composition share remains dominant

---

## Revision Log

- **2026-08-08:** Aligned A1's dependency note with the revised close-precheck plan: invalid or missing recorded base context is a hard utility error, not a guessed/manual continuation after a partial report — trigger: close-precheck stress/red-team revision.

## Appendix

### Research / References

- Timing analysis: user-provided breakdown of close transcript agent-a2950d425486d4f8d.jsonl — 117 steps, 923s total, 771s composition / 152s tools, chunks: walkthrough ~2m26s, plan+diff ~3m, doc reconciliation ~2m40s
- `execute-projex.md` § PRE-EXECUTION (execute-precheck contract — the model for A1) and § 7 COMPLETE EXECUTION (evidence recording — the contract A2 consumes)
- `verify-projex.md` (invocation contract, § BOUNDARY vs audit-projex) and `SKILL.md § Sub-Workflows` (six-rule test explaining why close cannot invoke it as-is)
- SKILL.md § Auxiliary Artifact Commit Policy (source of the untracked-aux-doc state A4 resolves)

### Alternatives Considered

- **Reuse verify-projex directly from close** — rejected: violates sub-workflow rules 1 (caller-only: parent is execute) and its own "use only via execute-projex delegation" clause; step-scoped and pre-commit by design, close needs criteria-scoped and post-commit. Extending its parentage was judged a framework change disproportionate to the need — evidence-consumption (A2) achieves the intent without it.
- **Delegate walkthrough authoring to a sub-agent now (Option B partial)** — deferred: savings unproven vs spawn cost on typical closes; depends on log quality A2/A3 must first establish.
- **Drop the walkthrough for clean executions (log-only close)** — rejected: walkthrough is the plan-level synthesis (criteria proof, deviation summary, insights) that the step-level log does not provide; Light tier captures the same saving without losing the record type.
