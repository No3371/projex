---
description: This workflow guides the creation of **Evaluation** projex documents — systematic analysis and scrutinization of status quo versus new ideas, changes, or proposals. (This is part of @projex-framework skill. It is a MUST to load the skill first.)
---

## PURPOSE

Evaluations provide rigorous, intellectually honest analysis. They research essence, explore principles, and assess whether and why ideas will succeed.

**Key characteristics:**
- The broadest analytical tool — systematic scrutiny, open exploration, comparative research, or deep-dive
- Deep analysis of paradigms, values, scope, underlying principles and assumptions
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
- `/eval-projex @2607311430-caching-layer-proposal.md`
- `/eval-projex Comparative vs longitudinal design for the thesis study`

**Deepening an existing evaluation:**
- `/eval-projex @2603041430-auth-rewrite-eval.md deepen assumptions section`
- `/eval-projex @2603041430-auth-rewrite-eval.md update with new benchmarks`
- `/eval-projex @2603041430-auth-rewrite-eval.md challenge conclusions`

---

## EVALUATION TYPES

- **Proposal** — Assess a specific proposal's viability and alignment
- **Status Quo** — Analyze current state to identify improvements or issues
- **Comparative** — Compare multiple approaches, technologies, or designs
- **Compatibility** — Determine if changes align with existing specs/patterns
- **Gap Analysis** — Identify what's missing between current and desired state

---

## DEPTH TIERS

Select during framing (step 1) based on stakes, uncertainty, complexity, and time.

| Tier | When | Lenses | Research Scope | Sections |
|------|------|--------|----------------|----------|
| **Quick Take** | Low stakes, quick answer, well-understood domain | 1-2 | Primary sources, immediately available | Exec Summary + one Analysis + Recommendation. Skip Foundations, Evidence Log, Appendix. Can grow via deepening. |
| **Standard** | Moderate stakes, some uncertainty — the default | 2-3 | Primary + secondary within project | Full document |
| **Deep Research** | High stakes, significant uncertainty, broad scope | All relevant | All tiers + external + composed projex | Full document + extended evidence log + full appendix. May span multiple sessions. |

---

## WORKFLOW STEPS

### 1. FRAME THE EVALUATION

Establish: What exactly is being evaluated? What is the evaluation trying to determine? What criteria matter? Who are the stakeholders? What decisions will this inform?

**Select depth tier** per the table above. If deepening an existing eval, identify mode (expand, update, challenge, extend) and target sections.

### 2. RESEARCH PHASE

#### Source Hierarchy

Prefer higher tiers. Research scope scales with depth tier.

- **Primary** — Direct observation: read code/configs/schemas, run experiments/benchmarks, examine real behavior (logs, metrics, outputs)
- **Secondary** — Recorded decisions: project docs, specs, ADRs, changelogs, commit/PR history, existing projex
- **Tertiary** — External: industry standards, RFCs, library docs, research papers, technical blogs

#### Composing with Other Projex (Deep Research)

| Research need | Compose with |
|---|---|
| Understand what exists and how it works | `/explore-projex` |
| Inventory all touchpoints or dependencies | `/scan-projex` |
| Gather stakeholder perspectives | `/interview-projex` |
| Understand a component's identity and boundaries | `/define-projex` |

Reference composed projex in the eval's Related Projex and Evidence Log.

#### Understand the Subject

**For Ideas/Proposals:** Essence, paradigm, claimed value, scope.
**For Status Quo:** What exists and why, established patterns, shaping constraints, what works and what doesn't.

#### Explore Foundations

1. **Principles** — What theories or principles underpin this?
2. **Assumptions** — What is assumed to be true?
3. **Prior work** — What came before? What was learned?
4. **Context** — What external factors are relevant?

#### Evidence Discipline

Per major finding, track: **what** was observed, **where** (file, doc, measurement), and **confidence** — High (directly observed), Medium (inferred from strong evidence), Low (assumption or limited evidence). Never fabricate or overstate.

### 3. CRITICAL ANALYSIS

#### Analytical Lenses

Select lenses appropriate to the evaluation. Lens count scales with tier.

| Lens | Method | Best for |
|------|--------|----------|
| **First Principles** | Break to fundamental truths, rebuild from scratch | Novel approaches, deep "why" questions |
| **Inversion** | Ask "what makes this fail?", list concrete failure modes | Proposals, major decisions, risk assessment |
| **Steel-Manning** | Build strongest opposing argument before countering it | Contested trade-offs, controversial changes |
| **Pre-Mortem** | Assume failure already happened, work backwards to causes | Plans, migrations, execution risk |
| **Sensitivity** | Test each assumption — which ones flip the recommendation? | Uncertain inputs, forecasts, dependency-heavy decisions |
| **Constraint Mapping** | Catalog constraints (hard/soft/self-imposed), try removing each | Status quo evals, gap analysis |

#### Problem Assessment

- What problem does this address? Is it the right problem?
- How significant? Who experiences it?

#### Prior Approach Analysis

- Why didn't previous approaches solve this?
- What was missing? Were they actually tried? What changed since?

#### Solution Assessment

- How does this address the problem?
- Why will this succeed where others failed?
- What are the potential challenges?

### 4. DRAFT THE EVALUATION

```bash
{projex-scripts}/new-projex.{sh|ps1} <repo-root> eval "{eval-name}" <projex-folder>
```

#### Document Structure

**Frontmatter:**
> Created, Author, Subject, Type (Proposal | Status Quo | Comparative | Compatibility | Gap Analysis), Tier, Lenses Applied, Related Projex

**Sections in order:**

1. **Executive Summary** — 3-5 sentences: what was evaluated, key findings, recommendation
2. **Evaluation Scope** — Subject description, questions addressed, evaluation criteria (table: criterion | weight | description), out of scope
3. **Context Analysis** — Current state, historical context, constraints, stakeholders
4. **Foundations** — Underlying principles. Key assumptions table: assumption | validity | risk if wrong | sensitivity (would recommendation change?). Prior work.
5. **Analysis** — Per area: finding, confidence (H/M/L), lens used, evidence with source citations, implications. Include comparative table if applicable.
6. **Evidence Log** (Standard+) — Table: # | finding | source | type (Primary/Secondary/Tertiary) | confidence | notes
7. **Evaluation Against Criteria** — Table: criterion | score (Strong/Adequate/Weak) | confidence | rationale. Overall assessment.
8. **Challenges and Risks** — Challenges with severity. Risk table: risk | likelihood | impact | mitigation.
9. **Findings** — Key findings with confidence ratings. Gaps identified. Opportunities.
10. **Recommendations** — Primary with reasoning. Conditional (if X → Y). Next steps: immediate, short-term, long-term.
11. **Open Questions** — Checklist of unresolved questions.
12. **Appendix** — Methodology (sources, lenses, tier rationale). Sources consulted. Dissenting views (especially from steel-manning). Iteration history if deepened (table: date | mode | scope | summary).

### 5. VALIDATION

**Rigor Check:**
- [ ] All major assumptions identified and assessed
- [ ] Evidence supports findings (check Evidence Log completeness)
- [ ] Counter-arguments considered (steel-manning applied where relevant)
- [ ] Reasoning traceable from evidence → finding → recommendation

**Honesty Check:**
- [ ] Uncomfortable truths not hidden
- [ ] Limitations acknowledged
- [ ] Uncertainty clearly stated (confidence levels assigned)
- [ ] Bias checked and noted

**Utility Check:**
- [ ] Answers the original questions
- [ ] Actionable recommendations provided
- [ ] Decision-makers have what they need
- [ ] Clear next steps if applicable

### 6. FINALIZE

1. **Refine** — Front-load executive summary
2. **Calibrate depth** — Trim Quick Take, expand Deep Research
3. **Update relationships** — Link to related projex
4. **Place correctly** — Active → `.projex/`, completed → `.projex/closed/`, outdated → `.projex/archived/`

### 7. VISUALIZE (optional)

Add a visual only if it communicates something the text does not. Use **Mermaid diagrams** or **ASCII tables**.

| Evaluation type | Useful visuals |
|---|---|
| Comparative | Decision matrix, weighted scoring table |
| Gap Analysis | Current vs desired state diagram, coverage heatmap |
| Proposal | Before/after architecture diagram, data flow changes |
| Status Quo | Dependency graph, component map, bottleneck diagram |
| Risk-heavy | Risk quadrant (likelihood x impact), failure cascade |

---

## ITERATIVE DEEPENING

Re-invoke on an existing eval: `/eval-projex @{existing-eval}.md [mode] [target]`

| Mode | When | What happens |
|------|------|--------------|
| **Expand** | Section needs more depth | Add research, evidence, or analysis to targeted sections |
| **Update** | New information available | Incorporate new context, re-assess affected findings |
| **Challenge** | Conclusions feel too comfortable | Adversarially re-examine — apply inversion and steel-manning |
| **Extend** | New questions emerged | Add analysis areas or criteria not originally covered |

**Process:** Load existing eval → identify mode and targets → re-enter at Research or Critical Analysis → update findings, confidence, recommendations → log in Appendix → Iteration History. Tier field updates to reflect accumulated depth.

---

## EVALUATION PRINCIPLES

- **Intellectual Honesty** — Follow evidence, not preferences. Acknowledge unknowns. Represent all perspectives.
- **Adaptive Depth** — Match rigor to stakes. Quick questions get quick analysis. Major decisions get thorough treatment.
- **Clarity** — State findings directly. Separate facts from opinions. Make reasoning explicit.
- **Actionability** — Connect analysis to decisions. Provide clear recommendations. Identify concrete next steps.

---

## OUTPUT

This workflow produces:
- An evaluation projex document at `.projex/{yymmddhhmm}-{name}-eval.md`
- Updated relationships in evaluated projex documents
- Clear findings and recommendations

**Folder placement:** See SKILL.md § Organizing.

**Committing:** Present the evaluation document to the user. Do not commit automatically — commit only when the user explicitly requests it.

---

## NOTES

- Evaluations inform decisions — they don't make them
- Challenge your own conclusions before finalizing
- Depth should match importance and uncertainty
- Use relative paths when referencing repository files
- Update evaluations if context changes significantly (or re-invoke to deepen)
