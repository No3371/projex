# Proposal: Generalize Projex Beyond Software Development

> **Status:** Complete (Accepted)
> **Created:** 2026-07-29
> **Author:** Claude (Fable 5)
> **Related Projex:** 2607290443-generalize-beyond-software-plan.md (Complete) | 2607290457-generalize-beyond-software-patch.md
> **Implemented:** 2026-07-29 — Option A shipped in full via the patch above (commit `a91b9c8`, 15 files, +52/−3). Final scope 15 files, not the ~7 estimated here: the plan expanded example seeding to 12 specs.

---

## Summary

Make projex usable for non-technical subjects (writing, research, legal, planning, personal projects) without touching what makes it work for dev. Method: don't rewrite specs into abstract language — add a thin generalization layer to SKILL.md (substrate contract + no-VCS mode), make 3-4 surgical locator/vocabulary edits, and seed non-dev examples across invocation sections. Dev behavior: unchanged.

**Recommendation:** Option A (additive layer). ~7 files touched, all edits additive or example-level.

---

## Problem Statement

### Current State

Framework is already ~2/3 general. Measured git/dev-term density per spec:

- **Deeply git-coupled:** debug (88 term-lines), close (74), execute (46), simulate (43), do (29), patch (25), verify (21), SKILL.md git sections, all shell scripts
- **Barely coupled:** eval (3), redteam (2), imagine (2), explore (1), guide (2), propose (2), scan (3), review (4) — plus interview, memo, define, navigate, audit at single digits

In the barely-coupled group, git mentions are plumbing only: `new-projex` scaffold call, "do not commit automatically" finalize line, "relative paths for repo files". The methods themselves — steel-manning/sensitivity lenses (eval), stakeholder attack waves (redteam), claims-vs-evidence (audit), verdict rosters (review), Q&A rounds (interview) — carry zero software assumptions.

Real coupling is to **git as substrate**, not to software. The execution family needs four guarantees git provides: inspectable corpus | edit mechanism | checkpoint+rollback | provenance log. Any file-based subject in a git repo (book manuscript, course material, legal docs in markdown) gets the full framework today, unchanged. The unaddressed cases: (a) file-based work **outside** a git repo, (b) domains whose status quo isn't files at all (negotiations, events, physical-world tasks).

### Gap / Need / Opportunity

- Vision from inception: general framework, not dev-only
- Specs read as dev-only to an agent: every invocation example is code (`Fix the off-by-one in the parser loop`), locators are `file:ln`, review accuracy checks ask "Code samples match reality?" — an agent handed a non-dev subject has no signal the workflow applies
- Nothing structural blocks generalization — the gap is framing and a few hard-coded assumptions

### Why Now?

Framework recently stabilized (sub-workflows formalized, close scripts tested, orchestrate hardened). Adding an interpretation layer on a stable base is cheap; retrofitting after further dev-specific accretion gets harder.

---

## Proposed Change

### Overview

Separate **method** (universal thinking disciplines) from **substrate** (git as one pluggable implementation). SKILL.md admits the framework is general; workflow specs stay concrete and dev-flavored, gaining only examples and locator flexibility.

### Approach Options

#### Option A: Additive generalization layer (recommended)

- **Description:** Six bounded changes, all additive:
  1. **SKILL.md § Substrate Contract** (~25 lines) — name the four guarantees (inspectable corpus, edit mechanism, checkpoint/rollback, provenance log); git = reference implementation. Degradation table: git repo → full framework | plain files, no git → analytical workflows + revise/memo/define/nav; no execute/simulate/debug cycle (no rollback guarantee) | non-file domain → analytical workflows + field-mode cycle (see 3)
  2. **SKILL.md § No-VCS Mode** (~10 lines) — `.projex/` folder not inside a git repo: skip repo resolution, skip all commit/stage steps, create files directly; naming, statuses, folder states (`closed/`, `archived/`, `abandoned/`) unchanged. Covers every analytical workflow in one paragraph since their finalize steps already default to "don't commit automatically"
  3. **SKILL.md § Field Mode** (~10 lines) — for actions the agent can't perform (book venue, negotiate, submit filing): Plan authored normally → human executes → agent logs via interview-style debrief into the execution-log format → Close records evidence from the human's account, marked as human-reported. Analytical workflows unaffected — they never needed the agent to act
  4. **Locator generalization** — scan-projex already says "adaptive format"; extend its format table with non-code rows (`doc § heading`, `page:para`, `URL#anchor`). review-projex Accuracy check gets a parallel clause for non-code sources ("cites resolve? quoted claims match source?"). audit-projex evidence list mentions non-code artifacts (records, documents, deliverables)
  5. **Non-dev invocation examples** — one example each added to eval, redteam, propose, interview, define, navigate, guide, imagine, memo, scan, explore, review (e.g. `/redteam-projex.md @lease-agreement.md`, `/eval-projex Comparative or longitudinal design for the thesis?`, `/define-projex.md Our consulting engagement model`). Examples are what steer LLM applicability judgments — highest leverage per line
  6. **SKILL.md irreversibility principle** (~5 lines) — restate Critical Git Rules' spirit substrate-neutrally: explicit scope per state change, sequential operations, human confirmation before destruction. Git commands remain the dev instantiation
- **Pros:** dev specs keep full precision | small diff, reviewable | LLM instruction-following unharmed (concrete specs stay concrete) | non-dev capability unlocked where it's actually possible
- **Cons:** SKILL.md grows ~50 lines (token budget) | field mode is thin — real non-file domains get a degraded cycle, not a first-class one
- **Effort:** Low. One plan, ~7 files, no script or test changes.

#### Option B: Substrate-neutral rewrite of all specs

- **Description:** Rewrite all 24 specs in domain-neutral vocabulary ("corpus", "artifact", "state change"), git relegated to an appendix profile.
- **Pros:** conceptually pure; every workflow reads as general
- **Cons:** degrades the battle-tested asset — LLMs execute concrete instructions more reliably than abstractions; massive diff; invalidates accumulated prompt-tuning; violates the "without degrading dev success" constraint
- **Effort:** High.

#### Option C: Parallel general-purpose profile (fork)

- **Description:** Keep dev specs untouched; ship a second spec set (`projex-general/`) with substrate-neutral variants.
- **Pros:** zero risk to dev flow
- **Cons:** two spec sets drift immediately; every future improvement lands twice or not at all; agents must pick a profile before knowing the subject
- **Effort:** Medium up front, high forever.

### Recommended Approach

**Option A.** The framework's generality is latent, not missing — the fix is admission plus examples, not reconstruction. B destroys the precision that makes it work; C creates a maintenance fork for what a 50-line layer achieves.

---

## Impact Analysis

### Affected Areas

- `SKILL.md`: +3 short sections (Substrate Contract, No-VCS Mode, Field Mode) + irreversibility principle line
- `scan-projex.md`: format table rows
- `review-projex.md`: Accuracy check clause
- `audit-projex.md`: evidence list wording
- ~12 analytical specs: +1 invocation example each
- `README.md`: short "beyond software" section (human-facing)
- Scripts, tests, execute/close/debug/simulate/do/verify: **untouched**

### Dependencies

- Requires: nothing pending
- Blocks: nothing; any future "projex for X" guide builds on it

### Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Spec bloat dilutes LLM compliance on dev tasks | Low | High | All edits additive/example-level; no dev instruction reworded; verify with a dev-task smoke run post-change |
| Agents over-apply full cycle to no-checkpoint substrates | Med | Med | Degradation table is explicit: no git → no execute/simulate/debug |
| `new-projex` script fails outside a git repo | Resolved | — | Verified working outside git (no git commands in either variant); no mitigation needed |
| Field mode too thin to be useful | Med | Low | Ship minimal; if real usage demands more, dedicated follow-up proposal |

### Breaking Changes

None. Purely additive; existing invocations and chains behave identically.

---

## Open Questions

All resolved 2026-07-29:

- [x] **`new-projex.{sh|ps1}` outside a git repo** — verified: works. Tested `.ps1` in a plain non-git folder → file scaffolded, no error; grep of both variants shows zero git commands (one comment only). Printed commit hint is inapplicable outside git — No-VCS mode's "skip commit steps" covers it. No script patch needed.
- [x] **Field mode** — include in SKILL.md now (~10 lines, user-confirmed). Completes the degradation table; deepen later if real usage demands.
- [x] **Docs surface** — SKILL.md carries the generalization; README additionally gets a short "beyond software" section for human readers (user-confirmed). USAGE stays as-is.

---

## Next Steps

If accepted:
1. `/plan-projex.md @2607290435-generalize-beyond-software-proposal.md` — single plan, one scope (all files in repo root + SKILL.md)
2. Post-execution smoke check: run one dev-flavored and one non-dev-flavored analytical workflow against the updated specs

---

## Appendix

### Research / References

- Term-density measurement: `grep -ciE 'git|branch|commit|merge|rebase|worktree'` per spec, 2026-07-29 session
- Method/substrate split analysis: this session's framework survey (all 24 specs + SKILL.md reviewed)

### Alternatives Considered

- **Do nothing** — framework already works for file-based non-dev subjects in git repos. Rejected: agents don't recognize the applicability without examples; non-git and non-file cases stay silently unsupported rather than explicitly scoped.
- **Option B / C** — see Approach Options; rejected for precision loss and drift respectively.
