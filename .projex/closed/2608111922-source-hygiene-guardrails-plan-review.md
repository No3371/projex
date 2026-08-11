# Review: Source Hygiene Guardrails Plan

> **Reviewer:** agent (Claude Sonnet 5)
> **Status:** Complete
> **Targets:** 1 | **Related Projex:** 2608052327-source-hygiene-guardrails-plan.md | 2608051553-source-hygiene-guardrails-proposal.md | 2608052346-source-hygiene-guardrails-plan-redteam.md

---

## Summary

Plan is pre-execution, high-stakes (8 root spec files, core framework), reviewed at Deep tier. Direction remains sound and matches the accepted proposal — no supersession, no obsolescence. But two independent drift sources compound: (1) upstream edits to `execute-projex.md` (2026-08-08) and `close-projex.md` (2026-08-07, 2026-08-09) landed *after* the plan was authored, staling several `current line N` citations and — more materially — restructuring execute-projex's per-step do/verify delegation from a marker-gated mechanism into a freely-chosen one, which the plan's own `Do-Projex: Encouraged` / `Verify-Projex: Encouraged` step tags still assume; (2) a sibling Red Team filed 19 minutes after the plan returned **Fix Issues** with 5 "Must Fix (Before Proceeding)" items and 2 "No-Go If" conditions, none of which are reflected in the plan's current text. The plan carries `> **Status:** Ready` with no acknowledgment of either. Verdict: **Revise** — content edits needed before this is safe to execute, core approach otherwise intact.

**Verdict counts:** Valid: 0 | Revise: 1 | Expand: 0 | Archive: 0 | Abandon: 0
**Ripple:** 2 referrers found — both informational, no escalation. Contained.

---

## Targets

| # | Document | Type | Age | Tier | Verdict | Note |
|---|----------|------|-----|------|---------|------|
| 1 | 2608052327-source-hygiene-guardrails-plan.md | Plan | 6 days | Deep | Revise | Stale line-anchors + unaddressed sibling redteam findings |

---

## 2608052327-source-hygiene-guardrails-plan.md

> **Verdict:** Revise

**Recon (independent):** Plan authored 2026-08-05 23:27, Status `Ready`, Worktree `Yes`. Confirmed not yet executed — no `## Source Hygiene`, `SOURCE HYGIENE PASS`, or `trailer Projex` text exists in any of the 8 target files today. Its source proposal (`2608051553-source-hygiene-guardrails-proposal.md`) remains `Complete (Accepted)` — unrevised, still the plan's valid mandate.

Since authoring, 9 commits touched at least one of the plan's 8 target files (2026-08-06 → 2026-08-11):
- **`45c43c1` "polish: execute-projex" (2026-08-08)** — restructured § 4 EXECUTE STEPS from A/B/C (PREPARE/EXECUTE/LOG-VERIFY-COMMIT) into A/B/C/D/E (PREPARE/EXECUTE/LOG/VERIFY/COMMIT), and replaced the marker-driven mode gate with a free per-step choice ("carry out the step... either by yourself or via a `do-projex` sub-subagent"). `Verify-Projex: Required` remains the only read trigger anywhere in the specs (`execute-projex.md:117`, `SKILL.md:49`) — unchanged by this commit — but the plan's own `Verify-Projex: Encouraged` / `Do-Projex: Encouraged` tags on steps 2, 3, 4, 5, 6, 7 still match no trigger, before or after the restructure.
- **`03407c0` "fix(close-projex): squash message guardrails for smaller models" (2026-08-09)** — inserted one sentence immediately before the Option A squash command block that the plan's step 4b edits.
- **`4749410` "feat(navigate-projex): now can be closed" (2026-08-07)** — edited close-projex.md § 6 step 3's born-closed table (added a Navigation row); the stale `Simulation` entry the plan's own Notes § Follow-ups already flags as out-of-scope survives unchanged — that specific plan claim is still accurate.
- **`213c97f` "Improve placeholder for projex Author header" (2026-08-09)** — 1-line net-zero edit across 12 specs including `patch-projex.md` and `debug-projex.md` — no line-count shift.

SKILL.md grew from 391 lines (the plan's stated `Current State`) to 407 — driven by unrelated commits (close-precheck script, orchestrate-projex nesting). The plan's step-1 insertion anchor text ("The commit commands shown in auxiliary workflow docs are **reference templates**...") still resolves verbatim, immediately followed by `## Substrate` — content-anchor holds, the cited line numbers (206, 208–210) do not.

A sibling Red Team (`2608052346-source-hygiene-guardrails-plan-redteam.md`, filed 19 minutes after the plan) returned **Verdict: Fix Issues**, **Readiness: Needs Work**, 12 findings (2 Critical, 4 High), 5 "Must Fix (Before Proceeding)" items, and 2 "No-Go If" conditions. Checked each against the plan's current text — none are applied:
- Step 7a's scope pathspec is still the root-anchored `":(exclude).projex/"` (redteam finding 1 — should be `':(exclude,glob)**/.projex/**'`)
- The Verification Plan's diff-size check still asserts "exactly 8 files changed" with no `.projex/` exclusion (finding 3 — fails on every correct execution, since step commits land `-log.md`/`-plan.md` too)
- Steps 4 and 7 still carry `Verify-Projex: Encouraged`, not `Required` (finding 4)
- Step 4's lead paragraph has no doc-only-execution carve-out (redteam's edge-case: a doc-only close would get a mandatory typed subject + trailer, contradicting the boundary rule)
- The trailer-survival claim ("carries the body into the squash description") is still stated unconditionally, with no GitHub squash-setting caveat (finding 7)
Neither document carries a `> **Reviewed:**` note referencing the other.

**Drift:**

| Assumption/Ref | Then | Now | Impact |
|---|---|---|---|
| execute-projex.md step-commit template locator (§ 4.C item 5, line 199) | subsection C = combined LOG+VERIFY+COMMIT | subsection E, COMMIT only, post-restructure | Minor — text anchor intact, locator wrong |
| execute-projex.md § Commit Message Convention locator (lines 287–290) | 3-bullet stub at that line | same stub, now ~line 277 | Minor — text anchor intact, locator wrong |
| execute-projex.md Do-Projex/Verify-Projex step markers | assumed marker-gated mode selection | free per-step choice; `Verify-Projex: Required` still the sole trigger, still unmatched by the plan's `Encouraged` tags | Major — the mitigation the plan leans on for its two Medium-confidence steps routes to nothing, confirmed post-authoring and hardened by the restructure |
| close-projex.md Option A/B block locators (lines 466–511) | as cited | +1 sentence before Option A (`03407c0`), +1 net line in the born-closed table (`4749410`); message templates unchanged | Minor — text anchor intact, locators drifted a few lines |
| SKILL.md "391 lines" (Context § Current State) | 391 | 407 | Minor — factual claim in the plan's own recon is now wrong; insertion anchor still resolves |
| Sibling redteam's 5 Must-Fix + 2 No-Go conditions | filed 19 min after plan, Verdict Fix Issues | zero of the 5 fixes applied in plan text; no cross-reference either direction | Major — plan sits at `Ready` while its own commissioned critique says `Needs Work`, unresolved |

**Checks:** Validity: ✓ [core rule-set + commit-convention direction still sound; redteam's own Final Assessment rates it "Fixable", not invalidated] | Accuracy: ✗ [file:line citations stale in execute-projex.md and close-projex.md; "391 lines" claim wrong; redteam-confirmed defects — root-anchored pathspec, unsatisfiable diff-count check, inert Encouraged markers — remain unfixed] | Completeness: ✓ [scope matches accepted proposal Option B; deferred items (hygiene-lint, review-projex exclusion, Simulation-entry fix) correctly stay out of scope] | Value: ✓ [problem evidence and accepted proposal stand; nothing supersedes it]

**Challenges:**
- What single change since authoring most threatens this document? → `45c43c1`'s restructure of execute-projex.md § 4: it doesn't just shift lines, it swaps the marker-gated do/verify mechanism for a freely-chosen one, deepening the plan's already-flagged marker mismatch into a mechanism mismatch. **Landed** — reinforces Revise.
- What would make it obsolete tomorrow? → A further close-projex.md edit that rewrites the Option A/B message templates themselves (not just adjacent sentences, as the last two touches did) would break steps 4b/4c's before/after blocks outright. **Held for now** (hasn't happened) but the file has taken two unrelated touches in a 6-day window — live risk, not yet realized.
- If authored fresh today, would it differ? → Yes: target `§ 4.E COMMIT`, not `§ 4.C item 5`; account for the free per-step do/verify choice; fold in all 5 of the sibling redteam's Must-Fix items, none of which are currently reflected. **Landed**.

**Actions:** — all applied 2026-08-11 via `/revise-projex` (see the plan's `## Revision Log`)
- [x] Refresh file:line citations in Steps 1, 2, 4 against current `execute-projex.md` / `close-projex.md` / `SKILL.md` (text anchors still resolve; only the "current line N" numbers need updating)
- [x] Update Context § Current State's "SKILL.md — 391 lines" to 407
- [x] Reconcile Step 2's target with execute-projex.md's new COMMIT subsection; restate the Do-Projex/Verify-Projex mismatch as a mechanism change, not just an unread trigger — *correction: the subsection is `§ 3.E COMMIT`, not `§ 4.E`; `execute-projex.md`'s WORKFLOW STEPS headings run 1, 2, 3, 5, 6, 7 (a numbering gap left by `45c43c1`), recorded as a follow-up in the plan*
- [x] Incorporate or explicitly reject each of the sibling redteam's 5 "Must Fix (Before Proceeding)" items and 2 "No-Go If" conditions before the plan returns to `Ready`; record dispositions inline — *all 5 applied, both No-Go conditions cleared, Should-Fix and Monitor items dispositioned in the plan's Notes § Red Team Dispositions*
- [x] Add a `> **Reviewed:**` note to the plan; cross-link the redteam's unresolved status from the plan and vice versa

---

## Ripple

| Referrer | References | Its verdict | Disposition |
|----------|------------|-------------|--------------|
| 2608051553-source-hygiene-guardrails-proposal.md | 2608052327-source-hygiene-guardrails-plan.md | Complete (Accepted) — closed | Informational — source proposal, unaffected by the plan's Revise verdict |
| 2608052346-source-hygiene-guardrails-plan-redteam.md | 2608052327-source-hygiene-guardrails-plan.md | Fix Issues — closed critique | Informational — already the primary evidence for this review's verdict; no separate action beyond the plan's own |

No other active projex references the plan by filename. Decay contained to the one document.

---

## Open Questions

- [x] Should the plan be revised in place (`/revise-projex`) folding in both this review's line-anchor fixes and the redteam's 5 Must-Fix items, or re-planned from a fresh `/plan-projex` pass given how much of `execute-projex.md` has moved underneath it? This review recommends `/revise-projex` — the core content and step structure are still sound; only anchors and a bounded set of named defects need correction. **Resolved 2026-08-11:** user chose `/revise-projex`; revision applied, plan held at `Ready`.
