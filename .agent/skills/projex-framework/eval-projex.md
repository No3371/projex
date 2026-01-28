# Eval Projex Workflow

(This is part of @projex-framework skill. Is is a MUST to load the skill first.)

This workflow guides the creation of **Evaluation** projex documents — systematic analysis and scrutinization of status quo versus new ideas, changes, or proposals.

---

## PURPOSE

Evaluations provide rigorous, intellectually honest analysis. They research essence, explore principles, and assess whether and why ideas will succeed.

**Key characteristics:**
- Deep analysis of paradigms, values, and scope
- Exploration of underlying principles and assumptions
- Assessment of prior approaches and why they fell short
- Intellectual rigor with adaptive depth

---

## INVOCATION

```
/eval-projex.md <question or subject>
```

**Examples:**
- `/eval-projex.md Does current spec support this proposal?`
- `/eval-projex.md What can be improved in the current implementation?`
- `/eval-projex.md Compare REST vs GraphQL for our use case`
- `/eval-projex.md @20260731-caching-layer-proposal.md`

---

## EVALUATION TYPES

### Proposal Evaluation
Assess a specific proposal's viability and alignment.

### Status Quo Evaluation
Analyze current state to identify improvements or issues.

### Comparative Evaluation
Compare multiple approaches, technologies, or designs.

### Compatibility Evaluation
Determine if changes align with existing specs/patterns.

### Gap Analysis
Identify what's missing between current and desired state.

---

## WORKFLOW STEPS

### 1. FRAME THE EVALUATION

Define what's being evaluated:

```
Questions to establish:
- What exactly is being evaluated?
- What is the evaluation trying to determine?
- What criteria matter for this evaluation?
- Who are the stakeholders/consumers of this evaluation?
- What decisions will this evaluation inform?
```

**Scope calibration:**
- Quick assessment → Focus on key criteria
- Deep dive → Comprehensive multi-angle analysis
- Specific question → Targeted investigation

### 2. RESEARCH PHASE

#### Understand the Subject

**For Ideas/Proposals:**
1. What is the essence of this idea?
2. What paradigm does it represent?
3. What value does it claim to provide?
4. What scope does it cover?

**For Status Quo:**
1. What exists today and why?
2. What patterns and conventions are established?
3. What constraints shaped current design?
4. What has worked well? What hasn't?

#### Explore Foundations

1. **Principles** — What theories or principles underpin this?
2. **Assumptions** — What is assumed to be true?
3. **Prior work** — What came before? What was learned?
4. **Context** — What external factors are relevant?

### 3. CRITICAL ANALYSIS

#### Problem Assessment

- What problem does this address?
- Is this the right problem to solve?
- How significant is this problem?
- Who experiences this problem?

#### Prior Approach Analysis

- Why didn't previous approaches solve this?
- What was missing or wrong?
- Were they actually tried? What happened?
- What has changed since?

#### Solution Assessment

- How does this address the problem?
- Why will this succeed where others failed?
- What makes this approach different?
- What are the potential challenges?

### 4. DRAFT THE EVALUATION

Create a new file: `{yyyymmdd}-{eval-name}-eval.md`

**Template Structure:**

```markdown
# [Evaluation Title]

> **Created:** YYYY-MM-DD
> **Author:** [name or agent]
> **Subject:** [what is being evaluated]
> **Type:** Proposal | Status Quo | Comparative | Compatibility | Gap Analysis
> **Related Projex:** [links to related projex documents]

---

## Executive Summary

[3-5 sentences capturing: what was evaluated, key findings, and recommendation]

---

## Evaluation Scope

### Subject
[Detailed description of what is being evaluated]

### Questions Addressed
1. [Primary question]
2. [Secondary question]
3. [Tertiary question]

### Evaluation Criteria
| Criterion | Weight | Description |
|-----------|--------|-------------|
| [Criterion 1] | High/Med/Low | [What it measures] |
| [Criterion 2] | High/Med/Low | [What it measures] |

### Out of Scope
- [What this evaluation does not cover]

---

## Context Analysis

### Current State
[Description of relevant status quo]

### Historical Context
[What led to current state, previous decisions, lessons learned]

### Constraints
[Technical, business, resource, timeline constraints]

### Stakeholders
[Who is affected by or interested in this evaluation]

---

## Foundations

### Underlying Principles
[The principles or theories the subject is built upon]

### Key Assumptions
| Assumption | Validity | Risk if Wrong |
|------------|----------|---------------|
| [Assumption 1] | Valid/Questionable/Invalid | [Impact] |
| [Assumption 2] | Valid/Questionable/Invalid | [Impact] |

### Prior Work
[Previous approaches, attempts, related work]

---

## Analysis

### [Analysis Area 1]

**Finding:** [Key finding]

**Evidence:**
- [Evidence point 1]
- [Evidence point 2]

**Implications:**
[What this means for the evaluation subject]

---

### [Analysis Area 2]

[Same structure]

---

### Comparative Analysis (if applicable)

| Aspect | Option A | Option B | Status Quo |
|--------|----------|----------|------------|
| [Aspect 1] | [Assessment] | [Assessment] | [Assessment] |
| [Aspect 2] | [Assessment] | [Assessment] | [Assessment] |

---

## Evaluation Against Criteria

| Criterion | Score | Rationale |
|-----------|-------|-----------|
| [Criterion 1] | Strong/Adequate/Weak | [Reasoning] |
| [Criterion 2] | Strong/Adequate/Weak | [Reasoning] |

**Overall Assessment:** [Summary judgment]

---

## Challenges and Risks

### Identified Challenges
1. [Challenge 1]: [Description and severity]
2. [Challenge 2]: [Description and severity]

### Risk Assessment
| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| [Risk 1] | High/Med/Low | High/Med/Low | [Approach] |

---

## Findings

### Key Findings
1. **[Finding 1]:** [Explanation]
2. **[Finding 2]:** [Explanation]
3. **[Finding 3]:** [Explanation]

### Gaps Identified
- [Gap 1]
- [Gap 2]

### Opportunities
- [Opportunity 1]
- [Opportunity 2]

---

## Recommendations

### Primary Recommendation
[Clear recommendation with reasoning]

### Conditional Recommendations
- **If [condition]:** [recommendation]
- **If [different condition]:** [alternative recommendation]

### Suggested Next Steps
1. [Immediate action]
2. [Short-term action]
3. [Long-term consideration]

---

## Open Questions

- [ ] [Unresolved question that needs further investigation]
- [ ] [Question outside this evaluation's scope]

---

## Appendix

### Methodology
[How this evaluation was conducted]

### Sources
[Documents, code, conversations referenced]

### Dissenting Views
[Alternative perspectives considered]
```

### 5. VALIDATION

Before finalizing:

**Rigor Check:**
- [ ] All major assumptions identified and assessed
- [ ] Evidence supports findings
- [ ] Counter-arguments considered
- [ ] Reasoning is traceable

**Honesty Check:**
- [ ] Uncomfortable truths not hidden
- [ ] Limitations acknowledged
- [ ] Uncertainty clearly stated
- [ ] Bias checked and noted if present

**Utility Check:**
- [ ] Answers the original questions
- [ ] Actionable recommendations provided
- [ ] Decision-makers have what they need
- [ ] Clear next steps if applicable

### 6. FINALIZE

1. **Refine document** — Front-load executive summary
2. **Calibrate depth** — Adjust detail to match context
3. **Update relationships** — Link to related projex
4. **Place correctly** — Save in appropriate projex folder

**Folder placement:**
- Active evaluations → `projex/`
- Completed evaluations (when no longer actively referenced) → `projex/closed/`
- Outdated/superseded evaluations → `projex/archived/`

---

## EVALUATION PRINCIPLES

### Intellectual Honesty
- Follow evidence, not preferences
- Acknowledge when you don't know
- Represent all relevant perspectives

### Adaptive Depth
- Match rigor to stakes
- Quick questions get quick analysis
- Major decisions get thorough treatment

### Clarity
- State findings directly
- Separate facts from opinions
- Make reasoning explicit

### Actionability
- Connect analysis to decisions
- Provide clear recommendations
- Identify concrete next steps

---

## OUTPUT

This workflow produces:
- An evaluation projex document at `projex/{yyyymmdd}-{name}-eval.md`
- Updated relationships in evaluated projex documents
- Clear findings and recommendations

**Folder placement by lifecycle:**
| Stage | Location |
|-------|----------|
| Active / Referenced | `projex/` |
| Completed / Historical | `projex/closed/` |
| Outdated / Superseded | `projex/archived/` |

---

## NOTES

- Evaluations inform decisions — they don't make them
- Challenge your own conclusions before finalizing
- Depth should match importance and uncertainty
- Use relative paths when referencing repository files
- Update evaluations if context changes significantly
