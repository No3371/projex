# Red Team: Source Hygiene Guardrails Plan

> **Lead:** agent (Claude, opus)
> **Subject:** `2608052327-source-hygiene-guardrails-plan.md` — Ready, uncommitted Plan rendering Option B of the accepted proposal into 8 root spec files
> **Related:** 2608052327-source-hygiene-guardrails-plan.md | 2608051553-source-hygiene-guardrails-proposal.md | 2608111922-source-hygiene-guardrails-plan-review.md | 2604031727-workflow-guardrails-determinism-imagine.md
> **Dispositioned:** 2026-08-11 — all 5 Must-Fix applied and both No-Go conditions cleared in the plan via `/revise-projex`; every Should-Fix and Monitor item recorded with a disposition in the plan's Notes § Red Team Dispositions. Findings below are the as-filed record and were **not** rewritten — read the plan for current state.

---

## Bottom Line

**Verdict:** Fix Issues

Direction is sound and the mechanics hold under test — `stage-n-commit`'s `--trailer` split works identically in `.sh` and `.ps1`, the multi-line close message produces a parseable trailer, every line anchor and the five-heading renumber are correct. The defects are scoping, wording, and unchecked obligations, not architecture. Five of them fire on the first execution or the first audit.

**Top Vulnerabilities:**
1. **The sole traceability channel can be silently dead.** Rule 1 removes comment citations; the trailer replacing them is stripped by GitHub squash-merge whenever `squash_merge_commit_message` is PR-body or blank — a repo setting the framework neither states nor checks. The proposal recorded this forfeit; the plan lands the unconditional claim into canonical spec text. Chained with the unenforced promotion clause, the excused type inaccuracy, and a post-close audit that can only report, a repo can be fully "compliant" with worse traceability than before and a green audit saying otherwise (findings 7, 8, 12).
2. **The enforcement point's scope command flags what the rules exempt.** `":(exclude).projex/"` is root-anchored; reproduced in a throwaway repo, `docs/.projex/nested.md` lands in the pass's input. Rule 2 explicitly blesses `file:ln` inside projex documents, so the audit's first act is to flag them (finding 1) — and at 100x, retrofit mode sweeps whole files through the same defect.
3. **The plan's own safety net does not exist.** Its terminal check demands "exactly 8 files changed" from a `{base}..HEAD` diff that necessarily contains 10 (execute-projex commits the log with every step and the plan at completion), and the `Verify-Projex: Encouraged` markers on its two Medium-confidence steps match nothing — execute-projex triggers only on `Required`, and `Do-Projex` has no consumer in any spec (findings 3, 4).

---

## Stakeholder Roles

| Wave | Role | Cares About | Pain Points | Critical Assumptions |
|------|------|-------------|-------------|---------------------|
| 1 | Executing Agent (execute/do) | Landing 7 steps without tripping its own verification | Checks that fail on a correct execution; inert safety markers | Plan's greps/counts are runnable and true |
| 1 | Framework Maintainer (owns the 8 specs) | Specs stay consistent, dense, non-duplicating | Two normative copies of the same rules; contradictions between specs | Duplication is justified by a real context gap |
| 1 | Auditing Agent (the designated enforcement point) | A pass that produces actionable findings | Scope command that grabs the wrong files; findings it cannot get fixed | `.projex/` exclusion works; the audited work has a diff range |

### Wave 1 Attack Surface

**Executing Agent:**
- Claims to this role: per-step greps prove each edit; `Do-Projex: Encouraged` / `Verify-Projex: Encouraged` route risky steps to independent agents; step-4 smoke test gates the multi-line mechanic
- Assumptions: markers have consumers; final `git diff --stat` matches the plan's own file accounting
- Dependencies: `stage-n-commit` `--trailer` pass-through (both variants); close scripts accept a body; worktree contains the plan

**Framework Maintainer:**
- Claims: rules stated "once, canonically" in SKILL.md; do-projex copy is forced by the sub-workflow contract
- Assumptions: SKILL.md is absent from a do-projex agent's context; 8 files is the complete commit-template surface
- Dependencies: no other spec asserts a competing convention

**Auditing Agent:**
- Claims: diff-only default scope; two-directional check; commit-composition check over landed commits
- Assumptions: `":(exclude).projex/"` excludes projex documents; `{base}..{head}` is resolvable at audit time; "comment" is well-defined in the audited diff
- Dependencies: the close mode preserved a range to diff

---

## Critical Findings

### Finding 1: Audit-pass scope command sweeps nested `.projex/` folders as source
**Severity:** Critical | **Likelihood:** High

**Affects Roles:** Auditing Agent, Framework Maintainer

**Attack Vector:** Step 7a's scope command is `git -C <repo-root> diff {base}..{head} -- . ":(exclude).projex/"`. A git pathspec with no wildcard anchors at the pathspec's own directory, so `.projex/` excludes only the repo-root folder. SKILL.md § Organizing explicitly supports multiple `.projex/` folders (`docs/.projex/`, `src/.projex/`).

Reproduced in a throwaway repo (root `.projex/`, `docs/.projex/`, `src/`, all three modified):

```
$ git diff --name-only -- . ':(exclude).projex/'
docs/.projex/nested.md
src/code.ts
```

The nested projex document is handed to the pass as source.

**Role-Specific Impact:**
- **Auditing Agent:** flags rule-2 violations (`file:ln`) inside projex documents — which SKILL.md rule 2 as drafted *explicitly blesses* ("`file:ln` stays correct inside projex documents; they are point-in-time records"). The pass contradicts the rule it enforces, in its first paragraph.
- **Framework Maintainer:** the enforcement point ships mis-scoped; every scan/walkthrough/plan in a nested folder is a finding factory.

**Blast Radius:** Every audit in any repo using area-scoped projex folders — the exact organizing pattern SKILL.md recommends. Also mis-classifies those files under the boundary rule (trailer "required" for doc-only commits).

**Remediation:** Use a glob-magic exclusion in both the workflow step and the boundary-rule wording: `':(exclude,glob)**/.projex/**'` (plus the root form). State the boundary rule as "outside **any** `.projex/` folder".

---

### Finding 2: The commit-composition check produces findings that cannot be remediated
**Severity:** High | **Likelihood:** High

**Affects Roles:** Auditing Agent, Framework Maintainer

**Attack Vector:** Step 7a: "every **landed** commit that changes a file outside `.projex/` carries a conventional-type subject and a `Projex:` trailer", and the report template records `**Violations:** [SHA — what is missing]`. Audit runs after close by construction (audit-projex § 1 gathers "walkthroughs, logs/commits"). A missing subject type or trailer on a landed commit is fixable only by rewriting published history — which the plan's own Out of Scope forbids ("rewriting existing commit history in this or any repo") and which SKILL.md § Critical Git Rules gates behind explicit human confirmation.

**Role-Specific Impact:**
- **Auditing Agent:** emits findings with no legal remedy; graded into `## Findings` severities alongside actionable ones.
- **Framework Maintainer:** audit reports accumulate permanent unfixable entries, degrading the signal of the report the framework calls its enforcement point.

**Blast Radius:** Every audit of an execution that predates or misapplies the convention — i.e. all existing work in every target repo, forever.

**Remediation:** Split the check: (a) *blocking* pre-close check — move commit composition into `close-projex.md` § finalization where the message is still being composed; (b) *informational* post-close roll-up in audit, graded `Monitor`, explicitly marked non-remediable, with "fix forward, do not rewrite" stated.

---

### Finding 3: The plan's own diff-size check fails on a correct execution
**Severity:** High | **Likelihood:** High

**Affects Roles:** Executing Agent, Framework Maintainer

**Attack Vector:** Verification Plan automated check: `git -C <worktree> diff --stat {base}..HEAD` → "exactly 8 files changed, all at repo root, all `.md`". But execute-projex § 4.C item 5 commits `.projex/{yymmddhhmm}-{plan-name}-log.md` with **every** step commit, and § 7 item 8 (line 250) commits the plan file and the log on the branch. A correct execution therefore shows **10** changed files: 8 specs + `-log.md` + `-plan.md`, two of them under `.projex/`, none of them at repo root.

**Role-Specific Impact:**
- **Executing Agent:** hits a red check at the last gate after every step passed. Two outcomes, both bad — escalate a non-problem, or learn to wave the check through (and the adjacent, real check "No `.sh`, `.ps1`, or `tests/` file appears in the diff" goes with it).
- **Framework Maintainer:** the acceptance-criteria table row "No script/test surface touched → 8 `.md` files, repo root only" is unsatisfiable as written.

**Blast Radius:** Terminal verification of this plan; the mis-specified check is the last thing standing between execution and close.

**Remediation:** Restate as `git diff --stat {base}..HEAD -- ':(exclude,glob)**/.projex/**'` → 8 files; and separately assert the `.projex/` side contains only the plan and log.

---

### Finding 4: The plan's stated risk mitigations are inert — `Encouraged` has no consumer
**Severity:** High | **Likelihood:** High

**Affects Roles:** Executing Agent, Framework Maintainer

**Attack Vector:** The plan marks its two Medium-confidence steps `Verify-Projex: Encouraged` (step 4 multi-line message mechanic, step 7 renumbering) and four steps `Do-Projex: Encouraged`. Grep over every root spec:

```
execute-projex.md:119,135,173 — all read `Verify-Projex: Required`
plan-projex.md:285,286        — writes `Do-Projex: Encouraged` / `Verify-Projex: Encouraged`
SKILL.md:48                   — `Verify-Projex: Required`
```

`Do-Projex` appears in **no** consumer at all; delegate mode is chosen per-plan and per-objective (execute-projex § 3), never per-step marker. `Verify-Projex: Encouraged` never matches execute-projex's `Required` trigger. Both markers are decorative.

**Role-Specific Impact:**
- **Executing Agent:** the two steps the plan itself flagged as the most likely to go subtly wrong get exactly the same self-review as the mechanical ones.
- **Framework Maintainer:** a plan-authoring vocabulary that its execution workflow cannot read — a framework defect this plan silently inherits and depends on.

**Blast Radius:** Every plan authored by plan-projex since the marker was introduced. For *this* plan, it removes the only independent check on the renumbering step and on the one mechanic the plan itself rates unproven.

**Remediation:** Within this plan's scope: promote steps 4 and 7 to `Verify-Projex: Required`. Outside it: a `/revise-projex` or follow-up reconciling `Encouraged` vs `Required` (and giving `Do-Projex` a consumer) — record as a dependency, not a silent assumption.

---

### Finding 5: The justification for inlining the six rules into do-projex is contradicted by do-projex itself
**Severity:** Medium | **Likelihood:** High

**Affects Roles:** Framework Maintainer, Executing Agent

**Attack Vector:** Step 3c duplicates ~15 lines of normative rule text into `do-projex.md`, justified as: "SKILL.md § Sub-Workflows rule 2 states all do-projex context is caller-supplied, so the 'rules ride SKILL.md into every session' mitigation does not hold here" and "SKILL.md may not be in this agent's context."

`do-projex.md` § 1. ANCHOR, item 1 (line 59): **"Read `SKILL.md` and this file (`do-projex.md`)"** — reading SKILL.md is the sub-workflow's first mandated action. Rule 2 ("keyed arguments") governs *task context* (plan, objective, log, repo, branch), not spec loading; execute-projex § 3 confirms it passes exactly those five arguments and states "sub-subagent boundaries are enforced by `do-projex.md`", i.e. the spec is read.

**Role-Specific Impact:**
- **Framework Maintainer:** permanent second normative copy of rules the plan elsewhere insists must be stated "once, canonically". The plan concedes the drift risk (Risks: "do-projex inline copy drifts from SKILL.md — Medium/Low") and mitigates it with a comment telling future editors to keep them in sync — a manual-diff obligation, in a repo whose own § Dehydrate demands density.
- **Executing Agent:** step 3's verification is a `sed`/`diff` against `/tmp/*.txt` — an absolute external path, which SKILL.md § NOTES forbids in projex documents, and a path that does not exist in the plan's own declared PowerShell/Windows environment.

**Blast Radius:** One file, but permanently — every future edit to the six rules now needs a matched edit in a second file with no mechanical check.

**Remediation:** Drop step 3c; keep 3a (trailer) and 3b, and make 3b a pointer: "Comments written into source obey `SKILL.md § Source Hygiene`, read at § 1 ANCHOR." If the maintainer still wants the copy for robustness, say so honestly ("belt-and-braces duplication") rather than resting it on a premise the target file falsifies, and replace the `/tmp` diff with a relative-path or in-repo check.

---

### Finding 6: `<type>` correctness is unenforced everywhere, and explicitly excused
**Severity:** Medium | **Likelihood:** High

**Affects Roles:** Executing Agent, Framework Maintainer

**Attack Vector:** Step 1b lands "A wrong type beats no type — pick the closest and move on." Step 7a's commit check verifies a typed subject is *present*, never that it *matches the diff*. No other check anywhere reads the type. The proposal's headline evidence is that 94% of subjects were `projex:` and therefore `git log --oneline` "can't answer feat-vs-fix".

**Role-Specific Impact:**
- **Executing Agent:** rational move is one default type per close; nothing measures it.
- **Framework Maintainer:** the stated problem (uninformative subjects) is addressable by a convention only if the type carries signal; presence-only enforcement plus an explicit accuracy excuse does not secure that.

**Blast Radius:** The primary claimed benefit of the commit half of Option B.

**Remediation:** Cheap type-selection guidance in SKILL.md § Commit Composition keyed to the diff (touched tests only → `test`; only `.md`/docs → `docs`; new capability → `feat`; behaviour correction → `fix`), and make the audit check read type-vs-diff rather than type-presence. Keep "wrong type beats no type" as a tie-breaker, not a blanket excuse.

---

## What's Solid (Wave 1)

Attacked and held:

- **Trailer mechanics.** `stage-n-commit.sh` lines 24–35 split a `--`-prefixed argument at the **first** space, so `"--trailer Projex: 2608052327-source-hygiene-guardrails"` forwards as `--trailer` + `Projex: 2608…`. `stage-n-commit.ps1` lines 19–26 do the same. The plan flagged the `.sh` variant as needing re-confirmation — it behaves identically.
- **Multi-line close message.** Verified live: a `-m` message of subject / blank line / `Projex: …` yields `SUBJ=[feat(x): subject line]`, `TRAILER=[2608052327-source-hygiene-guardrails]`. `projex-squash-close` passes its positional message to `git commit -m`; `projex-merge-close.sh:200` passes it to `git merge --no-ff -m`. Step 4's Medium confidence rating was warranted and the mechanic works (git 2.55).
- **Line anchors.** SKILL.md 206/208–210, 341, 352, 354; audit-projex 49/63/165/173/279/288; close-projex 405/471/476/486/491/501; patch-projex 101–107/294; do-projex 92/113/162; debug-projex 211/283/289/347/349/492 — all confirmed against the files.
- **Audit renumber list (7b)** is complete and correct: current steps run 1–8 with QUALITY ASSESSMENT at 4; the five-heading bottom-up shift is exactly right.
- **Debug reasoning (6c).** `reset --soft {base-branch}` at debug-projex:347 does unwind the repro and attempt commits; debug offers only squash-close or abandon, so exactly one commit reaches base. Leaving those templates untrailered is correct.
- **Stale-note targets are real.** patch-projex:294 and revise-projex Notes do assert the superseded prefix vocabulary as fact.

---

## Wave 2 — Implicated Roles

Derived from wave-1 findings, not from the subject. See § Wave Derivation.

| Wave | Role | Cares About | Pain Points | Critical Assumptions |
|------|------|-------------|-------------|---------------------|
| 2 | Downstream Repo Owner (runs the framework on their own repo) | Their history and doc tree staying usable | Audit findings they cannot act on; a pass that flags their own projex docs | The convention is scoped to code, and audits produce fixable work |
| 2 | Future Reader / Archive Agent (terminus of blame → commit → trailer → doc) | Recovering *why* a line exists, years later | The chain ends at a compressed index entry, or at an identifier that names no file | The trailer resolves to a readable document |
| 2 | Delivery Tooling / Integrator (GitHub PR merge, commitlint, mirrors) | Mechanical processing of subjects and bodies | Bodies dropped by a merge setting nobody in the framework controls | Trailers always survive to base |

### Wave 2 Attack Surface

**Downstream Repo Owner:**
- Claims: forward-only, no breaking changes; retrofit is opt-in; enforcement is one dedicated pass
- Assumptions: "source" means their code; audits yield remediable findings
- Dependencies: their `.projex/` layout matching the pass's exclusion; their repo actually being code-shaped

**Future Reader / Archive Agent:**
- Claims: the trailer is the sole code→doc channel and creates no deletion veto, so "archival stays free to compress"
- Assumptions: compression preserves enough; load-bearing rationale was promoted; the trailer value is resolvable
- Dependencies: rule 1's mandatory-promotion clause actually happening; archive index keyed compatibly

**Delivery Tooling / Integrator:**
- Claims: "Trailers ride the body, which GitHub carries into the squash description"; "subject linters never touch" them
- Assumptions: repo merge settings preserve commit bodies
- Dependencies: `squash_merge_commit_message` not set to PR body / blank

---

### Finding 7: "The trailer survives delivery tooling" is stated as fact but is a repo-configurable coin flip
**Severity:** High | **Likelihood:** Medium

**Affects Roles:** Delivery Tooling / Integrator, Future Reader, Downstream Repo Owner

**Attack Vector:** Step 1b's SKILL.md text: "Trailers ride the body, **which GitHub carries into the squash description**". GitHub's squash-merge message is a repo setting (`squash_merge_commit_message`): `COMMIT_MESSAGES` carries the bodies, `PR_BODY` replaces them with the PR description, `BLANK` drops them. Under the latter two, every `Projex:` trailer in the PR is discarded at merge. The proposal recorded this forfeit case honestly ("tooling that strips commit *bodies* loses traceability — accepted, no in-file fallback exists under Rule 1"); the plan drops the caveat and lands the unconditional claim into the canonical spec.

Compounding: `close-projex.md` has **no PR path at all** (grep for `pull request` / `gh_pr` / `PR ` → zero hits). The plan's Impact Analysis reasons about `.github/gh_pr.ps1` as though it were part of the close lifecycle; it is not. So in a PR-gated repo, the commit that lands on the default branch is produced entirely outside anything the framework specifies.

**Role-Specific Impact:**
- **Future Reader:** rule 1 banned the comment citation. With the trailer stripped, code→doc traceability is exactly zero — worse than the status quo the proposal set out to improve.
- **Downstream Repo Owner:** discovers the loss only when someone needs the rationale, with no detection in between (nothing checks trailer survival post-merge).
- **Integrator:** nothing tells them their merge setting is now load-bearing.

**Blast Radius:** Every PR-gated repo adopting the convention — plausibly most of them.

**Remediation:** State the forfeit in SKILL.md § Commit Composition, one sentence: "Trailers survive GitHub squash-merge only when the repo's squash message setting is *commit messages*; PR-body/blank settings strip them — set it, or prefer merge/rebase." Add a one-line pre-adoption check to the audit pass's commit direction: sample the last N base commits for `Projex:` trailers and report survival. Without a survival check the sole channel can be silently dead.

---

### Finding 8: Rule 1's "mandatory" promotion clause has no owner, no trigger, and no check
**Severity:** High | **Likelihood:** High

**Affects Roles:** Future Reader / Archive Agent, Executing Agent, Framework Maintainer

**Attack Vector:** Rule 1 lands "**Mandatory promotion:** load-bearing rationale that exists only in a projex document must be promoted into a shipped doc. Mandatory, not advisory — promotion is the only channel that survives archival compression." It is the sole mitigation for the proposal's own "Rationale loss" risk (Med/Med).

Trace the obligation through the plan: no step adds a promotion prompt to `plan-projex.md`, `execute-projex.md`, `do-projex.md`, or `close-projex.md`; step 7a's pass is explicitly two-directional over **rules 1–5 violations and rule 6 false negatives** — promotion is neither. Nothing creates it, nothing reminds anyone, nothing checks it. A "mandatory" rule with zero touchpoints is a wish.

Second edge: when an agent *does* comply, it edits shipped documentation that the plan under execution never scoped — expanding the diff, and colliding with SKILL.md § Organizing ("New projex should not cross area boundaries") and with the executing agent's own scope discipline. The plan gives no guidance on which shipped doc, or on how the promotion is scoped, staged, or reviewed.

**Role-Specific Impact:**
- **Future Reader:** the chain rule 1 promises (`git blame` → commit → trailer → doc) terminates, after an archive run, at an archive index entry — a summary plus 10–20 keywords (archive-projex § 3). The rationale itself is gone unless promoted, and promotion is unenforced. Rule 1 removed the working channel and replaced it with one that decays.
- **Executing Agent:** either ignores a mandatory rule, or performs unplanned out-of-scope edits.

**Blast Radius:** The single mitigation holding up rule 1's deletion-veto argument.

**Remediation:** Either (a) give it a home — one line in `close-projex.md`'s walkthrough step ("promote load-bearing rationale to a shipped doc; name it in the walkthrough") plus a third direction in the audit pass, or (b) demote it to advisory and say plainly that archival degrades rationale to index resolution. (a) is preferable; what is not defensible is "mandatory" with no mechanism.

---

### Finding 9: The trailer value is a new identifier that names no file
**Severity:** Medium | **Likelihood:** High

**Affects Roles:** Future Reader / Archive Agent

**Attack Vector:** Trailer form: `Projex: {yymmddhhmm}-{name}` — "the projex document's filename minus its `-{type}.md` suffix". SKILL.md § Authoring mandates the opposite for every other cross-reference: "**Reference by filename, not path** … Use the filename alone whenever you try to reference any projex." The trailer is the framework's only identifier that is deliberately *not* a filename, and the plan states no resolution procedure for turning one back into a document.

Two concrete costs: the prefix is shared by the plan, its `-log.md`, and any walkthrough carrying the same stem, so resolution is one-to-many; and `archive-projex` keys index entries by full filename (`### {filename}.md`), so a reader must know to prefix-match rather than look up.

**Role-Specific Impact:**
- **Future Reader:** an extra inferential hop at precisely the moment the chain is already at its weakest (post-archive).
- **Archive Agent:** no instruction to make index entries trailer-resolvable.

**Blast Radius:** Every trailer ever written — low per-incident cost, unbounded count.

**Remediation:** Either carry the full filename (`Projex: 2608052327-source-hygiene-guardrails-plan.md`) — self-consistent with § Authoring and unambiguous — or keep the stem and add one sentence stating the resolution rule ("prefix-match `{id}-*` within `.projex/`, `closed/`, `archived/`, and archive indexes"). Silence is the only unacceptable option.

---

### Finding 10: "Source" is defined as everything outside `.projex/`, but "comment" is defined only for code
**Severity:** Medium | **Likelihood:** High

**Affects Roles:** Downstream Repo Owner, Auditing Agent, Framework Maintainer

**Attack Vector:** Rule 1 scopes the six rules to "comments in code, config, **and any file outside `.projex/`**". SKILL.md § Substrate advertises the framework for "Files in a git repo (code, prose, any domain)". For a prose repo — documentation sites, spec corpora, legal/policy text, and **this repo**, whose entire tracked surface is 31 root `.md` files — the rules have no defined subject: markdown has no comment construct, so the pass either no-ops or fires on body prose.

The rules are self-contradictory when read against prose: rule 2 bans `file:ln` in "a source comment", yet a scan-projex or guide-projex document *shipped outside* `.projex/` (a legitimate placement) is built from `file:ln`; rule 4 bans `----`/`====` runs, which are valid markdown setext underlines; rule 3's present-tense rule collides with any changelog or migration doc, which is prose whose entire job is history.

**Role-Specific Impact:**
- **Downstream Repo Owner:** cannot tell whether the rules apply to their content.
- **Auditing Agent:** with finding 1's mis-scoping, it receives prose files it has no rule to apply and no instruction to skip.

**Blast Radius:** All non-code and mixed repos; the framework's own repo is the reference case.

**Remediation:** Define the subject once: "*Source* = files a program or build consumes: code, config, schemas, scripts. *Comment* = a construct the language ignores at runtime. Prose files (`.md`, docs) are shipped documentation — rule 1's carve-out target — and are out of the pass's scope unless retrofit mode names them." One sentence closes both this and half of finding 1.

---

## Wave 3 — Adversarial & Accountable Roles

| Wave | Role | Cares About | Pain Points | Critical Assumptions |
|------|------|-------------|-------------|---------------------|
| 3 | Minimal-Compliance Agent (adversarial — any agent optimizing for a clean audit) | Passing the enumerated checks at lowest cost | n/a — it succeeds | The checks are the rules; unchecked clauses are optional |
| 3 | Change Manager / History Accountability (governance — whoever answers for base history) | `git log` on base being trustworthy | Signing off on a convention whose failure is invisible | A green audit means the convention held |

### Wave 3 Attack Surface

**Minimal-Compliance Agent:**
- Capability: full write access to source and commit messages; reads the audit pass spec, which enumerates exactly what will be checked
- Partial vs full exploit: partial = strip cited comments, add nothing (rule 1 clean, rule 6 depends on the auditor independently spotting "non-obvious"); full = pad every non-obvious site with generic rationale, pick one default `<type>`, skip promotion
- Cost asymmetry: near-zero effort, zero detection, and the resulting report reads *better* than an honest one
- Defenses probed first: rule 6 (the only positive obligation, and the only one requiring auditor judgment with no rubric)

**Change Manager:**
- Claims to this role: history becomes semantically readable; a durable code→doc link exists
- Assumptions: audit findings mean something and can be acted on
- Dependencies: findings 2, 6, 7 all resolving in their favour

---

### Finding 11: The rule set's incentive gradient rewards vacuous rationale
**Severity:** Medium | **Likelihood:** High

**Affects Roles:** Minimal-Compliance Agent (gains), Future Reader (pays), Auditing Agent

**Attack Vector:** The proposal anticipated one gaming path — deleting comments to reach zero findings — and closed it with rule 6's false-negative direction. It did not close the cheaper inverse. Rule 6 obliges a rationale comment at every non-obvious decision; step 1b explicitly disclaims "**No density or length caps.** Long comment blocks are not a violation"; the pass checks only *presence* of rationale, never *quality*. The optimal play is a generic rationale sentence at every plausibly-non-obvious site: rule 6 satisfied, rules 1–5 untouched (own words, present tense, no IDs, no line numbers, no plan shape, no bare reassurance), no cap to trip.

Rule 5 nearly catches this and then lets it go: it constrains only comments using "deliberate/intentional/by design". "This uses a map for lookup performance" is bare assertion with no rejected alternative, and violates nothing.

**Role-Specific Impact:**
- **Minimal-Compliance Agent:** clean pass, no judgment exercised.
- **Future Reader:** noise that reads like rationale — strictly worse than absence, which at least signals "nobody thought about this".
- **Auditing Agent:** its hardest judgment (what counts as non-obvious) gets no rubric; the two enumerated directions give it no basis to call padding a finding.

**Blast Radius:** The framework's one positive comment obligation.

**Remediation:** Add a third direction to the pass: "**Rule 6 vacuity** — a rationale comment that names no rejected alternative, constraint, or trap is a finding, same as its absence." One line, and it closes the gap symmetrically with the false-negative direction the proposal already reasoned to.

---

### Finding 12 (cross-wave cascade): Both halves of Option B can silently evaporate while every check passes
**Severity:** Critical | **Likelihood:** Medium

**Affects Roles:** all — cascade spans waves 1, 2, and 3

**Attack Vector:** Chain the individually-survivable findings:

1. Rule 1 lands → comment citations removed. Traceability now rests entirely on the trailer (by design, stated).
2. Finding 7 → in a PR-gated repo with `squash_merge_commit_message` = PR body/blank, trailers never reach base. Nothing in the framework detects this.
3. Finding 8 → the promotion clause that was supposed to backstop archival is unowned and unchecked, so rationale was never promoted.
4. Finding 6 + 11 → subjects carry a type but not a *correct* one; comments carry rationale but not a *substantive* one.
5. Finding 2 → the audit that would surface any of this runs post-close, can only report, and its commit findings are unremediable by the framework's own rules.

Terminal state: source comments no longer cite docs, base commits carry no trailer, no shipped doc received the rationale, `git log --oneline` is uniformly typed and uninformative — and the audit report is green, because every check the plan specifies is a presence check that passes. Net traceability is **strictly worse than the status quo the proposal set out to fix**, and the framework's instrumentation says the opposite.

**Role-Specific Impact:**
- **Downstream Repo Owner:** loses a working (if ugly) channel and gains a broken one, with a compliance signal telling them it worked.
- **Change Manager:** signs off on history quality on evidence that cannot detect the failure.
- **Framework Maintainer:** the failure surfaces years later, in the one situation the rules exist for.

**Blast Radius:** The entire value proposition of Option B, in the repos most likely to adopt it.

**Remediation:** One structural fix covers the cascade — **make trailer survival an observable**, not an assumption. Add to the audit pass's commit direction: sample the last N commits on base and report the `Projex:` trailer rate; a rate of zero is a Critical finding, not a footnote. This converts a silent, years-delayed failure into a same-audit detection, and it is the single highest-leverage line the plan can add. Pair with findings 6, 7, 8, 11 remediations.

---

### Wave Derivation

- **Wave 1 → 2:** Finding 1 (pass hands nested projex documents to the rules) and finding 2 (findings that cannot be fixed) both dead-end at someone outside the framework's control — spawning **Downstream Repo Owner**. Finding 2's "landed commits" framing and finding 6's "signal lives in the doc tree" forced the question of who actually *reads* a trailer, spawning **Future Reader / Archive Agent**. Finding 6 established that subjects are consumed by machines, not just humans — spawning **Delivery Tooling / Integrator**, which then produced finding 7.
- **Wave 2 → 3:** Findings 6, 7, and 8 share one shape: an obligation stated with no check. That is an exploitable surface, so an adversary who reads the pass spec and optimizes to it — **Minimal-Compliance Agent** — became derivable only once those three existed. Finding 2 (unremediable findings) plus finding 7 (silent trailer loss) implicate whoever answers for base history, spawning the accountable **Change Manager**. Neither role was nameable from the plan alone; both are implied entirely by wave-1/2 evidence.
- **Post-wave-3 cross-wave pass:** run — produced finding 12, visible only with all three waves present (a wave-3 adversary reaching a wave-1 enforcement gap through a wave-2 tooling failure).

## Roles Not Attacked

> Surfaced after wave 3 closed. Recorded, not analyzed.

| Role | Surfaced by | What would have been asked |
|------|-------------|---------------------------|
| `hygiene-lint` author (deferred Option C) | Findings 6, 11 — presence-only checks | Are type-correctness and rationale vacuity mechanizable at all, or does deferring C leave the pass permanently judgment-bound and therefore permanently gameable? |
| Orchestrator (`orchestrate-projex`) | Finding 4 — `Do-Projex` has no consumer | How does an orchestrator route delegation without a step-level marker any workflow reads? |
| Test-suite owner (`tests/run-all.*`) | The plan's Out of Scope claim | Does any assertion depend on commit-message shape, such that "no script changes ⇒ no test changes" holds for behaviour as well as for files? |

---

## Role-Based Assumption Challenges

### Framework Maintainer: "do-projex agents may not have SKILL.md in context"
**Challenge:** `do-projex.md` § 1 ANCHOR item 1 mandates reading SKILL.md as the sub-workflow's first action.
**Counter-Evidence:** Sub-Workflows rule 2 governs task arguments, not spec loading; execute-projex § 3 passes five keyed arguments and defers boundaries to the spec itself.
**If Wrong:** ~15 lines of duplicated normative text with a manual sync obligation and no mechanical check.
**Action:** Reject.

### Auditing Agent: "`:(exclude).projex/` excludes projex documents"
**Challenge:** Anchored pathspec — root only.
**Counter-Evidence:** Reproduced: `docs/.projex/nested.md` appears in the pass's own scope command output.
**If Wrong:** The pass enforces rule 2 against documents rule 2 exempts.
**Action:** Reject — replace with glob magic.

### Executing Agent: "`Encouraged` markers route risky steps to independent agents"
**Challenge:** execute-projex triggers only on `Required`; `Do-Projex` has no consumer anywhere.
**Counter-Evidence:** Grep across all root specs: three `Required` reads, zero `Encouraged` reads, zero `Do-Projex` reads.
**If Wrong:** The two steps the plan rates Medium confidence get no independent check.
**Action:** Reject — promote steps 4 and 7 to `Required`.

### Future Reader: "archival stays free to compress because the trailer creates no veto"
**Challenge:** True about the *veto*, silent about the *referent*. Archive replaces documents with index entries; the chain still terminates in a summary.
**Counter-Evidence:** The proposal's own Rationale-loss risk, mitigated by a promotion clause the plan never gives a mechanism (finding 8).
**If Wrong:** Rule 1's central argument holds while its practical outcome does not.
**Action:** Validate — the veto asymmetry is real; state the resolution-degradation cost alongside it.

### Delivery Tooling: "GitHub carries the body into the squash description"
**Challenge:** Repo-configurable (`COMMIT_MESSAGES` | `PR_BODY` | `BLANK`).
**Counter-Evidence:** Proposal states the forfeit case; the plan drops it from the canonical text.
**If Wrong:** Sole traceability channel silently absent on base.
**Action:** Relax to a conditional claim + add a survival check.

---

## Role-Specific Edge Cases & Failures

### Executing Agent: doc-only execution meets the mandatory typed close message
**Trigger:** A plan whose entire diff is inside `.projex/` (doc reorganization, spec-status sweep) reaches close. Step 4 rewrites Option A/B templates to `<type>(<scope>)` + trailer **unconditionally**, while step 2 explicitly teaches the doc-only carve-out for step commits and step 4e preserves it for the walkthrough commit.
**Role Experience:** The boundary rule says no trailer; the close template says trailer. Success criterion 3 requires the boundary rule be "not contradicted by any workflow spec" — as drafted, step 4 contradicts it.
**Recovery:** Trivial, if caught in authoring.
**Mitigation:** One clause on the step-4 lead paragraph: "If the execution changed nothing outside `.projex/`, keep the `projex:` subject and omit the trailer."

### Auditing Agent: audited work whose branch no longer exists
**Trigger:** Step 7a's scope is `git diff {base}..{head}`. After squash-close the ephemeral branch is deleted and the execution is one commit on base; audit-projex § 1 defines scope in terms of claims and artifacts, never a commit range.
**Role Experience:** No defined way to compute `{base}`/`{head}`; the diff-only default has no anchor, pushing the agent toward the whole-repo sweep the plan explicitly forbids as a default.
**Recovery:** Possible — the walkthrough names the squash commit.
**Mitigation:** Specify the fallback: "closed executions → `git show <squash-sha>`; the walkthrough records it."

### Downstream Repo Owner: prose-only repo
**Trigger:** Framework used on a documentation or policy corpus (SKILL.md § Substrate advertises this).
**Role Experience:** Every tracked file is "source" by the boundary rule; no file has comments; rule 4 flags setext underlines; rule 3 flags changelogs.
**Recovery:** Possible.
**Mitigation:** Finding 10's definition sentence.

### Framework Maintainer: this very plan's execution
**Trigger:** Execution edits 8 root `.md` specs — all outside `.projex/`, so the boundary rule requires a typed subject and a trailer on the close, and the audit pass (once landed) would sweep the 8 spec files with no notion of what a "comment" is in them.
**Role Experience:** The framework's first dogfooding of the rule set is a case the rule set does not define.
**Recovery:** Possible.
**Mitigation:** Same definition sentence; it makes the framework's own repo a legible case.

---

## What's Hidden (Per Role)

**Omissions per role:**
- **Executing Agent:** that `Encouraged` markers do nothing; that the final file-count check cannot pass.
- **Downstream Repo Owner:** that adopting rule 1 makes a GitHub repo setting load-bearing for all future traceability.
- **Future Reader:** that the promotion clause holding up the chain has no mechanism, and that the trailer is not a filename.
- **Auditing Agent:** that its scope command over-collects, and that half its commit findings are unfixable by the framework's own rules.

**Tradeoffs per role:**
- **Framework Maintainer:** accepted a second normative copy of the rules on a premise the target file contradicts, and accepted "wrong type beats no type" — trading the convention's only measurable benefit for adoption friction that was never quantified.
- **Downstream Repo Owner:** traded a working-but-ugly channel (comment citations) for a durable-but-strippable one, with no transition marker in history separating the two conventions.
- **Auditing Agent:** absorbed all enforcement for a rule set written elsewhere, with a judgment-heavy rule 6 and no rubric.
- **Future Reader:** traded resolution (section-level citations — 146 of the evidence repo's 173) for plan-level, on the promise of promotion.

---

## Scale & Stress (Role Impact)

**At 10x (a repo running ~50 executions under the convention):**
- **Executing Agent:** the file-count check (finding 3) has failed ~50 times; the check is now ignored by convention, and the real `.sh`/`.ps1`/`tests/` guard next to it goes with it.
- **Auditing Agent:** each audit's `## Source Hygiene` section carries unremediable commit findings; readers start skipping the section.
- **Future Reader:** first archive run lands; trailers now resolve to index entries.

**At 100x (a repo the size of the proposal's evidence corpus — 1097 commits, 24 MB doc tree):**
- **Change Manager:** `git log --oneline` is uniformly typed and no more informative than `projex:` was — the flattening the proposal measured, restored in a new vocabulary (finding 6), with nothing having detected the regression.
- **Future Reader:** if finding 7's condition holds, zero trailers exist on base and no comment cites anything — traceability is unrecoverable, not merely degraded.
- **Downstream Repo Owner:** retrofit mode is now the only remedy for accumulated drift, and it sweeps whole files with the mis-scoped pathspec of finding 1 — the worst-case scale interaction in the plan.

---

## Remediation

### Must Fix (Before Proceeding)
- **Pathspec excludes only root `.projex/`** (affects: Auditing Agent, Downstream Repo Owner) → `':(exclude,glob)**/.projex/**'` in step 7a and in the boundary-rule wording → verify with the reproduction in finding 1
- **Diff-size check fails on a correct execution** (affects: Executing Agent) → scope the `--stat` check to exclude `.projex/`, assert the plan+log separately → run it before declaring the plan Ready
- **Trailer-survival claim stated unconditionally** (affects: Integrator, Future Reader) → add the GitHub squash-setting caveat to SKILL.md § Commit Composition and a trailer-rate sample to the audit commit check → confirms the sole channel is alive
- **Doc-only executions contradict the close template** (affects: Executing Agent) → one carve-out clause on step 4's lead paragraph → satisfies success criterion 3
- **`Encouraged` markers are inert** (affects: Executing Agent) → promote steps 4 and 7 to `Verify-Projex: Required`; record the `Encouraged`/`Required` mismatch as a follow-up

### Should Fix (Before Production)
- **Mandatory promotion has no mechanism** (affects: Future Reader, Executing Agent) → give it a home in close-projex + a third audit direction, or demote it to advisory and state the degradation honestly
- **do-projex inlining rests on a false premise** (affects: Framework Maintainer) → drop step 3c or re-justify it as deliberate redundancy; replace the `/tmp` diff verification (absolute external path, forbidden by SKILL.md § NOTES, nonexistent in the plan's declared environment)
- **Rule 6 gameable by padding** (affects: Future Reader) → add the vacuity direction to the pass
- **Type correctness unenforced** (affects: Change Manager) → diff-keyed type guidance; audit checks type-vs-diff
- **Post-close audits have no diff range** (affects: Auditing Agent) → specify the `git show <squash-sha>` fallback
- **"Source" undefined for prose** (affects: Downstream Repo Owner) → the one-sentence definition in finding 10

### Monitor
- **Trailer value is not a filename** (affects: Future Reader) → revisit at the first archive run in a repo using the convention
- **`git commit --trailer` requires git ≥ 2.32** (affects: Executing Agent) → the framework states no minimum git version; revisit if a target environment reports an unknown-option failure
- **Two conventions with no boundary marker in history** (affects: Change Manager) → revisit when a repo first needs to date the switch

---

## Final Assessment

**Soundness:** Fixable
**Risk:** Medium
**Readiness:** Needs Work

**Per-Role Readiness:**
- **Executing Agent:** Not Ready — a terminal check that cannot pass (finding 3) and inert safety markers (finding 4)
- **Framework Maintainer:** Ready with Fixes — line anchors, renumbering, and mechanics are accurate; the defects are wording and scope
- **Auditing Agent:** Not Ready — mis-scoped pathspec (1), no range for closed work, unremediable findings (2)
- **Downstream Repo Owner:** Not Ready — "source" undefined for their corpus (10); nested `.projex/` swept (1)
- **Future Reader:** Not Ready — the chain rule 1 promises depends on an unenforced clause (8) and a strippable carrier (7)
- **Delivery Tooling / Integrator:** Not Ready — a repo setting silently became load-bearing with no statement or check
- **Change Manager:** Not Ready — the failure mode in finding 12 is invisible to every instrument the plan specifies

**Conditions for Approval:**
- [ ] Pathspec exclusion glob-corrected in step 7a and boundary-rule wording (Auditing Agent, Downstream Repo Owner)
- [ ] Verification Plan's file-count check restated so a correct execution passes (Executing Agent)
- [ ] Trailer-survival caveat + trailer-rate check landed (Integrator, Future Reader, Change Manager)
- [ ] Doc-only close carve-out clause added to step 4 (Executing Agent)
- [ ] Steps 4 and 7 marked `Verify-Projex: Required` (Executing Agent)
- [ ] Promotion clause either given a mechanism or demoted from "mandatory" (Future Reader)

**No-Go If:**
- [ ] Rule 1 lands without a stated, checkable trailer-survival condition — the citation ban executes and the replacement channel is unverified (all roles; finding 12)
- [ ] The audit pass lands with the root-anchored pathspec — the enforcement point's first act is to flag documents the rules exempt (Auditing Agent)
