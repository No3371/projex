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
/audit-projex.md @20260731-auth-system-plan.md
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
Git commits, code files, tests (existence, pass, coverage), documentation (accurate, complete), logs, metrics

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

### 4. QUALITY ASSESSMENT

**Completeness:** All objectives/criteria/edge cases/docs?
**Correctness:** Works in all cases? Subtle bugs? Error handling?
**Quality:** Code/test/doc/architecture quality
**Value:** Solves problem? Usable? Meets performance? Production-ready?

### 5. OPEN EXPLORATION

**Undocumented Discovery:**
What else changed? Problems hidden? Workarounds? Assumptions?

**Impact Analysis:**
Downstream effects, future work enabled/blocked, technical debt, risks introduced

**Value Questioning:**
Actual user value? Could be better/simpler? Missed opportunities? What makes it excellent?

### 6. DRAFT AUDIT REPORT

Create file: `{yyyymmdd}-{subject}-audit.md`

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

### 7. VALIDATION

**Checks:**
- [ ] All claims cross-referenced against evidence
- [ ] Code/tests/docs/logs inspected
- [ ] Quality assessed beyond completion
- [ ] Undocumented issues discovered
- [ ] Findings supported by concrete evidence

### 8. FINALIZE

Save to `projex/`. Link to audited work. Update related projex if issues found.

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

Produces `projex/{yyyymmdd}-{name}-audit.md` with verification status, quality scores, and findings.

**Placement:** Active → `projex/` | Completed → `projex/closed/` | Reference → `projex/archived/`