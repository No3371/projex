---
description: This workflow guides the creation of **Audit** projex documents — suspicious, rigorous validation of completed work through inspection of docs/reports/logs and open exploration of final completeness, quality, and value delivered. (This is part of @projex-framework skill. It is a MUST to load the skill first.)
---

## PURPOSE

Audits validate that work was actually done, done correctly, and delivered value. Approach with suspicion, verify claims against evidence, and openly assess quality beyond just completion.

**Key characteristics:**
- Trust nothing, verify everything
- Cross-reference claims against artifacts
- Measure actual quality vs stated success
- Discover undocumented issues and gaps
- Assess real-world value delivered

---

## INVOCATION

```
/audit-projex.md <subject to audit>
/audit-projex.md @2607311430-auth-system-plan.md
/audit-projex.md the database migration we just finished
```

---

## WORKFLOW

### 1. ESTABLISH AUDIT SCOPE

**What:** Work claimed done, artifacts that should exist, success criteria defined, stakeholders affected, timeframe

**Gather:** Original plan/proposal, objectives, walkthroughs, code/configs/docs, logs/commits/deployments

### 2. IDENTIFY VALIDATION CHECKPOINTS

**Claims to verify:**
- "Completed X" → Does X exist? Work as claimed?
- "Fixed Y" → Is Y fixed? Any regression?
- "Improved Z" → Measurably better? By how much?

**Evidence to inspect:**
Git commits, code files, tests (existence, pass, coverage), documentation (accurate, complete), logs, metrics. Non-code work: deliverables, records, correspondence, published/filed artifacts

**Gaps to discover:**
Promised but not delivered, undocumented issues, unhandled edge cases, technical debt created

### 3. SYSTEMATIC INSPECTION

**Code/Implementation:**
Read actual code vs claimed changes, verify objectives, check for shortcuts/hacks/TODOs, identify undocumented changes and quality issues

**Testing:**
Review coverage and quality, run tests yourself, check for missing/flaky/meaningless tests

**Documentation:**
Does it match reality? All changes documented? Side effects? Migration/rollback docs? Examples work?

**Artifact Forensics:**
Git history patterns, commit message quality, file timestamps, reverted/hidden changes, copy-paste code

### 4. SOURCE HYGIENE PASS

Sweep the audited work against SKILL.md § Source Hygiene and `execute-projex.md` § Commit Message Convention. Not a general comment critique — only these rules. Subject is *source* as SKILL.md defines it: files a program or build consumes. Prose files carry no comments — skip them unless retrofit mode names them.

**Scope: the audited diff.** Comments the work *added or modified*, not whole files. The exclusion must be glob-magic — a root-anchored exclude pathspec would hand nested `docs/.projex/`, `src/.projex/` documents to the pass as source.

```bash
git -C <repo-root> diff {base}..{head} -- . ':(exclude,glob)**/.projex/**'
git -C <repo-root> log {base}..{head} --format='%h %s%n  trailer: %(trailers:key=Projex,valueonly)'
```

**No range available?** After a squash close the ephemeral branch is gone and there is no `{base}..{head}`. The walkthrough names the landing commit — use `git show <squash-sha> -- . ':(exclude,glob)**/.projex/**'`. Never fall back to a repo-wide sweep to recover a range.

**Retrofit mode — opt-in.** On explicit user request the sweep extends to whole files or the whole repo. Never the default — a repo-wide sweep buries the findings the audit was called for.

**Four directions, all produce findings:**

1. **Rules 1–5 violations** — a comment citing a projex ID / filename / section, a hardcoded `file:ln` or bare `:123`, a changelog narration, plan structure (`// Step N:`, `====` banner runs), or reassurance with no rejected alternative attached.
2. **Rule 6 false negatives** — a non-obvious change in the diff (rejected alternative, surprising constraint, don't-fix trap) with **no** rationale comment. Without this direction the pass is gamed by deleting comments.
3. **Rule 6 vacuity** — a rationale comment that names no rejected alternative, constraint, or trap. Same finding as its absence; without it the pass is gamed by padding every site with generic prose.
4. **Unpromoted rationale** — load-bearing rationale that exists only in the projex document. The walkthrough's `**Rationale promoted:**` line is the check: named target, or a stated "none needed" that the diff supports.

**Commit check:** Every landed commit that changes a file outside any `.projex/` folder carries a `Projex:` trailer. Conventional-type subject and type-vs-diff checks apply to landing, merge, patch, and debug-fix commits; ephemeral step commits may retain `projex: step …` / `projex(do): …` subjects. Doc-only commits are exempt.

**Trailer survival sample** — independent of the audited work, sample recent base history and report the rate:

```bash
git -C <repo-root> log {base-branch} -n 30 --format='%h %(trailers:key=Projex,valueonly)'
```

A rate of zero where the convention is supposed to be in force is a **Critical** finding — it means the sole code→doc channel is dead (typically a GitHub `squash_merge_commit_message` of `PR_BODY`/`BLANK`), and rule 1 has already removed the comment citations that used to carry it.

**Remediability** — a landed commit's subject or trailer cannot be fixed without rewriting published history, which this framework forbids without explicit human instruction. Grade commit-composition findings **informational / fix-forward**; never file them as actionable defects. Comment findings (directions 1–4) are ordinary actionable findings.

**Record locations by symbol, never `file:ln`** — the pass practises what it checks.

Findings land in the report's `## Source Hygiene` section and are graded into the standard `## Findings` severities.

### 5. QUALITY ASSESSMENT

**Completeness:** All objectives/criteria/edge cases/docs?
**Correctness:** Works in all cases? Subtle bugs? Error handling?
**Quality:** Code/test/doc/architecture quality
**Value:** Solves problem? Usable? Meets performance? Production-ready?

### 6. OPEN EXPLORATION

**Undocumented Discovery:**
What else changed? Problems hidden? Workarounds? Assumptions?

**Impact Analysis:**
Downstream effects, future work enabled/blocked, technical debt, risks introduced

**Value Questioning:**
Actual user value? Could be better/simpler? Missed opportunities? What makes it excellent?

### 7. DRAFT AUDIT REPORT

```bash
{projex-scripts}/new-projex.{sh|ps1} <repo-root> audit "{subject}" <projex-folder>
```

```markdown
# Audit: [Subject]

> **Audit Date:** YYYY-MM-DD | **Auditor:** [name] | **Work Period:** [timeframe]
> **Subject:** [what was audited] | **Related:** [plan/proposal/walkthrough links]

---

## Audit Summary

**Claim:** [What was supposed to be done]

**Verdict:** Verified | Partial | Failed | Misrepresented

**Assessment:** Completeness: High/Medium/Low | Correctness: High/Medium/Low | Quality: High/Medium/Low | Value: High/Medium/Low

**Top Issues:**
1. [Most critical]
2. [Second critical]
3. [Third critical]

---

## Claims vs Evidence

| Claim | Evidence | Status | Notes |
|-------|----------|--------|-------|
| Completed [X] | [File/commit/test] | ✓/✗/⚠ | [Observations] |
| Fixed [Y] | [File/commit/test] | ✓/✗/⚠ | [Observations] |
| Improved [Z] | [Metrics/benchmarks] | ✓/✗/⚠ | [Observations] |

---

## Objective Verification

### Objective 1: [Description]

**Evidence:** [File/commit/artifact inspected]

**Findings:**
- Actual: [What exists]
- Missing: [What's missing]
- Quality: High/Medium/Low

**Verification:** ✓ Verified | ✗ Failed | ⚠ Partial

**Issues:** [List issues found]

---

## Code/Implementation Inspection

### [Component/File]

**Claimed:** [What was supposed to change]
**Actual:** [What changed] — Quality: High/Medium/Low

**Issues Found:**
- [Issue] — Severity: Critical/High/Medium/Low

**Undocumented:** [Changes not mentioned]

**Metrics:**
- Readability/Maintainability: High/Medium/Low
- Test Coverage: [%]
- Technical Debt: None/Low/Medium/High

---

## Testing Validation

**Coverage:** Unit [%], Integration [%], Edge cases [covered/missing]
**Execution:** All pass? Yes/No | Flaky tests: [list]
**Missing:** [Scenarios not tested]
**Quality Issues:** [Problems with tests]

---

## Documentation Audit

**Completeness:** User/API/Migration/Rollback docs — Complete/Partial/Missing
**Accuracy:** Matches implementation? Yes/Partial/No | Examples work? Yes/No
**Quality:** Clarity/Completeness/Usability — High/Medium/Low

---

## Source Hygiene

**Scope:** Diff only (`{base}..{head}` | `git show <squash-sha>`) | Retrofit (whole file) | Retrofit (whole repo)

| Rule | Location (symbol) | Quote | Severity |
|------|-------------------|-------|----------|
| [1–6] | `module` → `functionName` | "[verbatim comment fragment]" | Critical/High/Medium/Low |

**Rule 6 gaps** (non-obvious change, no rationale comment):
- `symbol` — [what is non-obvious] — [why a reader needs the rationale]

**Rule 6 vacuity** (rationale comment naming no alternative, constraint, or trap):
- `symbol` — "[verbatim fragment]" — [what it fails to name]

**Rationale promotion:** [shipped doc named in the walkthrough, or "none needed — supported by diff", or "unpromoted: what is missing"]

**Commit composition** (informational — fix forward, never rewrite history): [N] landed commits checked — typed subject where required [N/N] | type matches diff where required [N/N] | `Projex:` trailer [N/N]
**Violations:** [SHA — what is missing, or "None"]

**Trailer survival on `{base-branch}`:** [N/30] of recent commits carry a `Projex:` trailer — [OK | **Critical: channel dead**, cause if known]

---

## Gap Analysis

### Promised But Not Delivered
| Promise | Status | Impact |
|---------|--------|--------|
| [Feature/fix] | Missing/Partial | High/Medium/Low |

### Undocumented Issues
| Issue | Severity | Affects |
|-------|----------|---------|
| [Issue] | Critical/High/Medium/Low | [Component/stakeholder] |

### Unhandled Edge Cases
- [Edge case] — Impact: [description]

---

## Quality Assessment

### Completeness: High/Medium/Low
**Strengths:** [What's done well]
**Gaps:** [What's missing]

### Correctness: High/Medium/Low
**Works:** [Aspect]: Yes/No
**Bugs:** [Bug] — Severity: [level]

### Code Quality: High/Medium/Low
**Positive:** [Attributes]
**Concerns:** [Issues]
**Tech Debt:** [Debt created] — Severity: [level]

### Value Delivered: High/Medium/Low
**Intended:** [What should've been achieved]
**Actual:** [What was achieved]
**Impact:** User: Positive/Neutral/Negative | Business: [description]

---

## Open Findings

### Undocumented Discoveries
- Changes: [What else changed]
- Problems: [Inferred issues] — Evidence: [what suggests this]
- Workarounds: [Workaround used] — Acceptable?

### Impact Analysis
- Downstream: [System]: [Impact]
- Future: Enabled: [what's possible] | Blocked: [what's harder]
- Risks: [Risk] — Likelihood: High/Medium/Low

### Improvements
- Could be better: [Opportunity]
- Would make excellent: [Enhancement]
- Missed: [Opportunity]

---

## Stakeholder Impact

| Stakeholder | Promised | Reality | Impact |
|-------------|----------|---------|--------|
| [Role] | [What was promised] | [What they got] | Positive/Neutral/Negative |

---

## Findings

### Critical (Must Address)
- **[Issue]** — [Why critical] → [Remediation]

### Significant (Should Address)
- **[Issue]** — [Why significant] → [Fix]

### Minor (Nice to Fix)
- **[Issue]** → [Improvement]

### Positive
- [What exceeded expectations]

---

## Recommendations

**Immediate:** [Action needed now]
**Future:** [Improvement for later]
**Process:** [Change to prevent similar issues]

---

## Final Verdict

**Status:** Accept | Accept with Conditions | Reject | Needs Rework

**Overall Assessment:**
- Completeness: High/Medium/Low
- Correctness: High/Medium/Low
- Quality: High/Medium/Low
- Value: High/Medium/Low

**Conditions:**
- [ ] [Required condition]

**Sign-off:** Yes/No — [Justification]
```

### 8. VALIDATION

**Checks:**
- [ ] All claims cross-referenced against evidence
- [ ] Code/tests/docs/logs inspected
- [ ] Quality assessed beyond completion
- [ ] Undocumented issues discovered
- [ ] Findings supported by concrete evidence
- [ ] Source hygiene pass run against the audited diff (or the declared retrofit scope)

### 9. FINALIZE

Save to `.projex/`. Link to audited work. Update related projex if issues found.

---

## PRINCIPLES

- **Trust but verify** — Assume good intent, check everything
- **Evidence over claims** — Artifacts prove work, not reports
- **Suspicious by default** — Look for what wasn't mentioned
- **Quality matters** — Completion ≠ quality ≠ value
- **Constructive criticism** — Find issues to improve, not blame

---

## AUDIT TRIGGERS

**Always:** Production deploys, security changes, major refactors, third-party integrations, compliance work
**Consider:** Complex features, critical bug fixes, performance claims, infrastructure changes, new/external teams
**Optional:** Minor features, doc-only changes, internal tools

---

## OUTPUT

Produces `.projex/{yymmddhhmm}-{name}-audit.md` with verification status, quality scores, and findings.

**Placement:** Active → `.projex/` | Completed → `.projex/closed/` | Reference → `.projex/archived/`
