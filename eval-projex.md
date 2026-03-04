---
description: This workflow guides the creation of **Evaluation** projex documents — systematic analysis and scrutinization of status quo versus new ideas, changes, or proposals. (This is part of @projex-framework skill. It is a MUST to load the skill first.)
---

## PURPOSE

Evaluations provide rigorous, intellectually honest analysis. They research essence, explore principles, and assess whether and why ideas will succeed.

**Key characteristics:**
- The broadest analytical tool — can be systematic scrutiny, open exploration of an idea, comparative research, or deep-dive into a solution
- Deep analysis of paradigms, values, and scope
- Exploration of underlying principles and assumptions
- Assessment of prior approaches and why they fell short
- Intellectual rigor with adaptive depth

**Contrast with Exploration and Proposal:**
- **Evaluation** — open-ended: any question, idea, or solution; no fixed framing or direction
- **Exploration** — anchored to the status quo: investigates what exists, how it works, and why
- **Proposal** — directional: explores a specific change or idea with trade-offs and approaches

---

## INVOCATION

```
/eval-projex <question or subject>
```

**Examples:**
- `/eval-projex Does current spec support this proposal?`
- `/eval-projex What can be improved in the current implementation?`
- `/eval-projex Compare REST vs GraphQL for our use case`
- `/eval-projex @20260731-caching-layer-proposal.md`

**Deepening an existing evaluation:**
- `/eval-projex @20260304-auth-rewrite-eval.md deepen assumptions section`
- `/eval-projex @20260304-auth-rewrite-eval.md update with new benchmarks`
- `/eval-projex @20260304-auth-rewrite-eval.md challenge conclusions`

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

## DEPTH TIERS

Tier is selected during framing (step 1) based on stakes, uncertainty, complexity, and time constraints.

### Quick Take
One-page assessment for low-stakes or time-sensitive questions.
- 1-2 analytical lenses, minimal research from immediately available sources
- **Skip:** Foundations, Comparative Analysis, Evidence Log, Appendix
- **Output:** Executive Summary + one Analysis section + Recommendation
- Can grow into Standard via iterative deepening

### Standard
Balanced depth for most evaluations — the default tier.
- 2-3 analytical lenses, moderate research across primary and secondary sources
- Full template
- **Output:** Complete evaluation document

### Deep Research
Multi-source, potentially multi-phase investigation for high-stakes or high-uncertainty subjects.
- All relevant analytical lenses applied
- Composes with other projex workflows for structured evidence gathering
- Extended evidence log, sensitivity analysis
- May span multiple sessions via iterative deepening
- **Output:** Comprehensive evaluation with evidence log and full appendix

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

**Select depth tier:**
| Signal | Tier |
|--------|------|
| Low stakes, quick answer needed, well-understood domain | Quick Take |
| Moderate stakes, some uncertainty, reasonable scope | Standard |
| High stakes, significant uncertainty, broad scope, or complex dependencies | Deep Research |

If deepening an existing eval, identify the deepening mode (expand, update, challenge, extend) and target sections.

### 2. RESEARCH PHASE

#### Source Hierarchy

Research quality depends on source quality. Prefer higher tiers:

**Primary sources** — Direct observation and measurement
- Read actual code, configs, schemas, data
- Run experiments, benchmarks, or tests
- Examine real behavior (logs, metrics, outputs, error patterns)

**Secondary sources** — Documentation and recorded decisions
- Project docs, READMEs, specs, ADRs, changelogs
- Commit history and PR discussions
- Existing projex documents (explorations, definitions, maps, scans)

**Tertiary sources** — External references
- Industry standards, best practices, RFCs
- Library/framework documentation
- Research papers, technical blogs, conference talks

**Research scope by tier:**
- **Quick Take** — Primary sources from what's immediately accessible
- **Standard** — Primary + secondary sources within the project
- **Deep Research** — All tiers, including external research and composed projex

#### Composing with Other Projex (Deep Research)

For complex evaluations, other projex workflows serve as structured research tools:

| Research need | Compose with |
|---|---|
| Understand what exists and how it works | `/explore-projex` |
| Inventory all touchpoints or dependencies | `/scan-projex` |
| Gather stakeholder perspectives | `/interview-projex` |
| Map structural relationships | `/map-projex` |
| Understand a component's identity and boundaries | `/define-projex` |

Reference composed projex in the eval's Related Projex field and Evidence Log.

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

#### Evidence Discipline

For each major finding, track:
- **What** was observed
- **Where** it was observed (file, doc, conversation, measurement)
- **Confidence** — High (directly observed/measured), Medium (inferred from strong evidence), Low (assumption or limited evidence)

If a finding rests on inference rather than observation, say so. Never fabricate or overstate evidence.

### 3. CRITICAL ANALYSIS

#### Analytical Lenses

Select lenses appropriate to the evaluation type — not all apply to every eval.

**First Principles Decomposition**
Break the subject into its most fundamental components. What is irreducibly true? What follows from those truths? Strip away convention and ask what you would build from scratch.
*Best for: novel approaches, challenging conventional wisdom, deep "why" questions.*

**Inversion**
Instead of "how will this succeed?", ask "what would make this fail?" List concrete failure modes and assess their likelihood.
*Best for: proposals, major decisions, risk assessment.*

**Steel-Manning**
Construct the strongest possible version of the opposing view before arguing against it. If you can't articulate why someone would disagree, you haven't understood the subject.
*Best for: any evaluation with a clear "other side" — controversial changes, contested trade-offs.*

**Pre-Mortem**
Assume the initiative has already failed (or the status quo has already collapsed). Work backwards: what went wrong? What was the earliest warning sign?
*Best for: plans, proposals, major migrations, anything with execution risk.*

**Sensitivity Analysis**
Identify the key assumptions. For each: what changes if this assumption is wrong? Which assumptions, if invalidated, would change the recommendation?
*Best for: evaluations with uncertain inputs, forecasts, dependency-heavy decisions.*

**Constraint Mapping**
Identify all constraints (technical, business, human, time). Which are hard vs soft? Which are self-imposed? Removing a constraint often reveals solutions invisible while it's assumed.
*Best for: status quo evaluations, gap analysis, "why can't we just..." questions.*

**Lens selection by tier:**
- **Quick Take** — 1-2 lenses, whichever cut deepest for this subject
- **Standard** — 2-3 lenses
- **Deep Research** — All relevant lenses

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
> **Tier:** Quick Take | Standard | Deep Research
> **Lenses Applied:** [which analytical lenses were used]
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
| Assumption | Validity | Risk if Wrong | Sensitivity |
|------------|----------|---------------|-------------|
| [Assumption 1] | Valid/Questionable/Invalid | [Impact] | [Would recommendation change?] |
| [Assumption 2] | Valid/Questionable/Invalid | [Impact] | [Would recommendation change?] |

### Prior Work
[Previous approaches, attempts, related work]

---

## Analysis

### [Analysis Area 1]

**Finding:** [Key finding]
**Confidence:** High / Medium / Low
**Lens:** [Which analytical lens produced this finding]

**Evidence:**
- [Evidence point 1 — source: file/doc/measurement]
- [Evidence point 2 — source: file/doc/measurement]

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

## Evidence Log

| # | Finding | Source | Type | Confidence | Notes |
|---|---------|--------|------|------------|-------|
| 1 | [What was observed] | [file:line / doc / measurement] | Primary/Secondary/Tertiary | High/Med/Low | [context] |
| 2 | ... | ... | ... | ... | ... |

---

## Evaluation Against Criteria

| Criterion | Score | Confidence | Rationale |
|-----------|-------|------------|-----------|
| [Criterion 1] | Strong/Adequate/Weak | High/Med/Low | [Reasoning] |
| [Criterion 2] | Strong/Adequate/Weak | High/Med/Low | [Reasoning] |

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
1. **[Finding 1]** (Confidence: High/Med/Low): [Explanation]
2. **[Finding 2]** (Confidence: High/Med/Low): [Explanation]
3. **[Finding 3]** (Confidence: High/Med/Low): [Explanation]

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
[How this evaluation was conducted — sources consulted, lenses applied, tier rationale]

### Sources
[Documents, code, conversations referenced]

### Dissenting Views
[Alternative perspectives considered — especially from steel-manning]

### Iteration History (if deepened)
| Date | Mode | Scope | Summary |
|------|------|-------|---------|
| [Date] | Expand/Update/Challenge/Extend | [What sections] | [What changed] |
```

### 5. VALIDATION

Before finalizing:

**Rigor Check:**
- [ ] All major assumptions identified and assessed
- [ ] Evidence supports findings (check Evidence Log completeness)
- [ ] Counter-arguments considered (steel-manning applied where relevant)
- [ ] Reasoning is traceable from evidence to finding to recommendation

**Honesty Check:**
- [ ] Uncomfortable truths not hidden
- [ ] Limitations acknowledged
- [ ] Uncertainty clearly stated (confidence levels assigned)
- [ ] Bias checked and noted if present

**Utility Check:**
- [ ] Answers the original questions
- [ ] Actionable recommendations provided
- [ ] Decision-makers have what they need
- [ ] Clear next steps if applicable

### 6. FINALIZE

1. **Refine document** — Front-load executive summary
2. **Calibrate depth** — Adjust detail to match tier (trim Quick Take, expand Deep Research)
3. **Update relationships** — Link to related projex
4. **Place correctly** — Save in appropriate projex folder

**Folder placement:**
- Active evaluations → `projex/`
- Completed evaluations (when no longer actively referenced) → `projex/closed/`
- Outdated/superseded evaluations → `projex/archived/`

### 7. VISUALIZE (optional)

If a visual would make findings or comparisons significantly clearer, add one. Skip if the text already communicates effectively.

| Evaluation type | Useful visuals |
|---|---|
| Comparative | Decision matrix, weighted scoring table, radar chart (as ASCII/table) |
| Gap Analysis | Current vs desired state diagram, coverage heatmap |
| Proposal | Before/after architecture diagram, data flow changes |
| Status Quo | Dependency graph, component map, bottleneck diagram |
| Risk-heavy | Risk quadrant (likelihood x impact), failure cascade diagram |

Produce visuals as **Mermaid diagrams** or **ASCII tables** within the document. A visual earns its space only if it communicates something the surrounding text does not.

---

## ITERATIVE DEEPENING

Evaluations are not one-shot. Re-invoke on an existing eval to deepen, update, or challenge it:

```
/eval-projex @{existing-eval}.md [mode] [target]
```

### Deepening Modes

| Mode | When to use | What happens |
|------|-------------|--------------|
| **Expand** | A section needs more depth | Add research, evidence, or analysis to targeted sections |
| **Update** | New information is available | Incorporate new context, re-assess affected findings |
| **Challenge** | Conclusions feel too comfortable | Adversarially re-examine with fresh eyes, apply inversion and steel-manning |
| **Extend** | New questions have emerged | Add analysis areas or evaluation criteria not originally covered |

### How it works

1. Load the existing eval
2. Identify the deepening mode and target sections
3. Re-enter the workflow at the appropriate step (usually Research or Critical Analysis)
4. Update findings, confidence levels, and recommendations as warranted
5. Log the iteration in the Appendix → Iteration History table

A **Quick Take** can grow into **Standard** by expanding across multiple iterations. A **Standard** eval can become **Deep Research** by composing with other projex and adding evidence. The tier field in the frontmatter updates to reflect current depth.

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
- Update evaluations if context changes significantly (or re-invoke to deepen)
