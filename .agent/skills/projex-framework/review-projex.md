---
description: This workflow guides the creation of **Review** projex documents — inspection reports that ensure existing projex documents remain valid, current, and valuable. (This is part of @projex-framework skill. Is is a MUST to load the skill first.)
---

## PURPOSE

Reviews combat projex decay. As codebases evolve and time passes, projex documents can become outdated, inaccurate, or obsolete. Reviews systematically validate projex health.

**Key characteristics:**
- Inspection against current status quo
- Challenge original assumptions and content
- Determine if expansion, modification, or archival needed
- High-level perspective avoiding original content bias

---

## INVOCATION

```
/review-projex.md @<projex-file>
/review-projex.md <recent-context>
```

**Examples:**
- `/review-projex.md @20260731-language-macro-syntax-change-proposal.md`
- `/review-projex.md the project we just made`
- `/review-projex.md all pending plans`

---

## REVIEW TRIGGERS

When to review projex documents:

- **Time-based:** Document is >30 days old without activity
- **Event-based:** Significant changes to related codebase areas
- **Dependency-based:** Related projex documents changed
- **Execution-based:** Before executing an older plan
- **Completion-based:** After related work completes
- **Request-based:** User or process requests review

---

## WORKFLOW STEPS

### 1. IDENTIFY REVIEW TARGET

Determine what to review:

**Specific document:**
1. Locate the referenced projex file
2. Note its type, status, and age
3. Identify its scope and related documents

**Context-based (e.g., "the project we just made"):**
1. Identify recently created/modified projex
2. Select appropriate documents for review

**Batch review (e.g., "all pending plans"):**
1. Query projex folders for matching documents
2. Prioritize by age, status, or relevance

### 2. GATHER CONTEXT

Before reviewing the projex content:

#### Timeline Analysis
```
Questions to answer:
- When was this projex authored?
- What has changed in the codebase since then?
- What other projex were created/completed since?
- What external factors have changed?
```

#### Status Quo Research
1. **Explore current state** — Look at relevant code/files now
2. **Check recent history** — Review commits, changes, decisions
3. **Identify drift** — Note differences from projex assumptions

### 3. INDEPENDENT ASSESSMENT

**Critical: Do NOT be biased by the projex content.**

Before deep-reading the projex, form independent views:

1. **Explore the domain** from scratch
2. **Ask fresh questions** about this area
3. **Form your own perspective** on what matters
4. **Note what you observe** without projex influence

### 4. PROJEX EXAMINATION

Now read the projex document with critical eye:

#### Validity Check
- Are the stated problems still problems?
- Are the assumptions still valid?
- Does the proposed approach still make sense?
- Have prerequisites/dependencies changed?

#### Completeness Check
- Does it cover everything it should?
- Are there gaps that status quo reveals?
- Should scope be expanded?

#### Accuracy Check
- Are file references still correct?
- Is technical content still accurate?
- Do code samples match reality?

#### Value Check
- Is this still worth doing/keeping?
- Has the value proposition changed?
- Is effort still justified by benefits?

### 5. CHALLENGE THE PROJEX

Formulate challenge questions:

```markdown
## Challenge Questions

1. [Question that challenges a core assumption]
   - Evidence for: [supporting points]
   - Evidence against: [contradicting points]
   
2. [Question that probes edge cases]
   - ...

3. [Question that tests relevance]
   - ...
```

Consider:
- What if the opposite approach was taken?
- What has been learned since authoring?
- What would make this projex obsolete?
- What risks weren't considered?

### 6. DETERMINE OUTCOME

Based on analysis, decide:

**No Changes Needed:**
- Projex remains valid and current
- Document review with timestamp

**Expansion Needed:**
- Status quo has additions projex should cover
- Document what should be added

**Modification Needed:**
- Content is no longer correct/complete/accurate
- Document what should be changed

**Archival Recommended:**
- Projex is obsolete or superseded
- Document reasoning for archival
- Move to `projex/archived/`

**Abandonment Recommended:**
- Projex is no longer relevant and not worth preserving
- Move to `projex/abandoned/` or delete

### 7. DRAFT THE REVIEW

Create a new file: `{yyyymmdd}-{original-projex-name}-review.md`

**Template Structure:**

```markdown
# Review: [Original Projex Title]

> **Review Date:** YYYY-MM-DD
> **Reviewer:** [name or agent]
> **Reviewed Projex:** [link to original]
> **Original Date:** [when projex was created]
> **Time Since Creation:** [duration]

---

## Review Summary

**Verdict:** Valid | Needs Expansion | Needs Modification | Recommend Archival

[2-3 sentences explaining the verdict]

---

## Timeline Analysis

### When Authored
- Created: [date]
- Last modified: [date]
- Status at authoring: [what was true then]

### What Changed Since
| Area | Then | Now | Impact |
|------|------|-----|--------|
| [Area 1] | [State then] | [State now] | [Effect on projex] |
| [Area 2] | [State then] | [State now] | [Effect on projex] |

### Related Events
- [Event 1]: [relevance to projex]
- [Event 2]: [relevance to projex]

---

## Status Quo Assessment

### Current State
[Description of relevant current implementation/situation]

### Drift from Projex Assumptions
| Assumption | Original | Current Reality | Drift Level |
|------------|----------|-----------------|-------------|
| [Assumption 1] | [What was assumed] | [What is true] | None/Minor/Major |

---

## Validity Assessment

### Problems Stated
| Problem | Still Valid? | Notes |
|---------|--------------|-------|
| [Problem 1] | Yes/Partial/No | [Reasoning] |

### Approach Proposed
| Aspect | Still Valid? | Notes |
|--------|--------------|-------|
| [Approach aspect] | Yes/Partial/No | [Reasoning] |

### Prerequisites/Dependencies
| Dependency | Status | Impact |
|------------|--------|--------|
| [Dependency 1] | Met/Unmet/Changed | [Effect] |

---

## Completeness Assessment

### Coverage Gaps
- [Gap 1]: [What should be added]
- [Gap 2]: [What should be added]

### Scope Expansion Candidates
- [Area that should now be included]

---

## Accuracy Assessment

### Technical Content
| Content | Status | Issue |
|---------|--------|-------|
| [File reference] | Accurate/Outdated/Broken | [Details] |
| [Code sample] | Accurate/Outdated | [Details] |

### Factual Content
- [Content that needs updating]

---

## Challenge Questions

### Challenge 1: [Question]
**Evidence for projex position:**
- [Point 1]

**Evidence against:**
- [Counter-point 1]

**Assessment:** [Conclusion]

---

### Challenge 2: [Question]
[Same structure]

---

## Value Assessment

| Aspect | Original Value | Current Value | Change |
|--------|----------------|---------------|--------|
| Problem significance | [Then] | [Now] | [Delta] |
| Solution benefit | [Then] | [Now] | [Delta] |
| Implementation cost | [Then] | [Now] | [Delta] |

**Value Verdict:** [Still valuable / Diminished value / No longer valuable]

---

## Recommendations

### Required Changes
1. [Specific change needed]
2. [Specific change needed]

### Suggested Improvements
1. [Optional improvement]

### Action Items
- [ ] [Action 1]
- [ ] [Action 2]

### Next Review
- Recommended: [timeframe or trigger]

---

## Appendix

### Independent Observations
[What was observed before reading the projex]

### Related Projex Status
[Status of related documents]
```

### 8. UPDATE ORIGINAL

Based on review findings:

1. **Add review note** to original projex:
```markdown
> **Reviewed:** YYYY-MM-DD - [link to review document]
> **Review Outcome:** [verdict summary]
```

2. **Update relationships** in both documents
3. **Flag for action** if changes needed

---

## REVIEW PRINCIPLES

### Fresh Eyes
- Look at status quo before reading projex
- Form independent opinions first
- Avoid anchoring to original content

### Challenge Everything
- Question assumptions explicitly
- Test claims against reality
- Consider what has changed

### Objective Assessment
- Separate what you want from what is
- Acknowledge when projex should be abandoned
- Value accuracy over attachment

### Constructive Output
- Don't just critique — recommend
- Provide actionable next steps
- Make updates easy to implement

---

## OUTPUT

This workflow produces:
- A review projex document at `projex/{yyyymmdd}-{original-name}-review.md`
- Review notation added to the reviewed projex
- Clear verdict and recommended actions
- Potential file moves based on verdict:
  - **Archival** → Move reviewed projex to `projex/archived/`
  - **Abandonment** → Move to `projex/abandoned/` or delete

---

## NOTES

- Reviews are about currency and validity, not quality judgment
- A "Recommend Archival" verdict is not failure — contexts change
- Use relative paths when referencing repository files
- Link reviews to originals bidirectionally
- Consider setting up periodic review schedules for critical projex
