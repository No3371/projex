---
description: This workflow guides the creation of **Stress** projex documents — adversarial analysis driven directly by attack angles, with no stakeholder modeling. (This is part of @projex-framework skill. It is a MUST to load the skill first.)
---

## PURPOSE

Stress tests break the subject directly: challenge assumptions, find weaknesses, exploit edge cases, expose hidden flaws. The unit of attack is the **angle** — a named way the subject can fail. No stakeholder modeling: the subject's own claims are the attack surface.

**Attack angle inventory:**

- **Assumption** — What beliefs are taken for granted that could be false?
- **Edge Case** — What inputs, states, or sequences weren't designed for?
- **Failure Cascade** — What breaks when one dependency fails?
- **Inversion** — What if the opposite approach were taken?
- **Scale** — What breaks at 10x, 100x load or volume?
- **Omission** — What was quietly sacrificed or glossed over?
- **Hidden** — What can be inferred from artifacts, patterns, or gaps that was never stated outright?
- **Worst Case** — If everything goes wrong, how bad does it get?
- **Incentive** — Who benefits from this failing or being gamed?
- **Time** — What holds now but degrades as assumptions age?
- **Dependency** — What external things does this rely on that you don't control? Vendor APIs, libraries, teams, licenses — what if one changes, deprecates, or disappears?
- **Observability** — Will you know when this is failing? Can it fail silently? What's the detection lag between something going wrong and someone noticing?
- **Adoption** — Will people use this as designed, or work around it, misuse it, or ignore it? What's the gap between designer intent and actual user behavior?

---

## INVOCATION

```
/stress-projex.md <subject to attack>
/stress-projex.md @2607311430-parser-refactor-plan.md
/stress-projex.md The retry logic in the sync script
```

---

## WORKFLOW

### 1. TRIAGE ANGLES

Walk the full inventory once. Mark every angle **Selected** or **Skipped** — each skip carries a one-line reason. No silent skips, and no padding: attacking an irrelevant angle to look thorough is worse than skipping it with a stated reason. Typically 4–8 angles are selected.

Triage is a claim about the subject, not a budget decision — "Scale skipped: single-user local script, no load dimension" is a reason; "Scale skipped: out of scope" is not.

### 2. SCAFFOLD REPORT

```bash
{projex-scripts}/new-projex.{sh|ps1} <repo-root> stress "{subject}" <projex-folder>
```

**Scaffold the file before attacking.** The report is the working artifact: record the triage table first, then append findings as each angle closes. The implication pass (step 4) is derived from what is *written down*, not from memory.

**Write Bottom Line last.** Open the file with the placeholder exactly as shown in the template. Do not fill in Verdict or Top Vulnerabilities until all angles are closed.

### 3. ATTACK PASS

For each selected angle, in the order most likely to draw blood first:

1. **State the target claim** — what the subject implicitly promises that this angle threatens ("the input is always well-formed", "the dependency stays available", "usage matches design").
2. **Attack it** — concrete scenarios, not abstract doubt. Name the input, the state, the sequence, the timeline.
3. **Record the outcome** — a finding with severity/likelihood and evidence, or a **hold**: the claim survived, with what was tried. A survived attack is a result, not a blank — record it under Held.

Findings must be grounded in concrete evidence from the subject (quote the line, cite the `file:ln`, name the artifact). No unsubstantiated severity ratings.

### 4. IMPLICATION PASS

Re-read all recorded findings once. Two checks:

- **Promotion** — a finding can implicate an angle triage skipped (an edge-case finding reveals a scale cliff; an omission finding exposes a dependency). Promote that angle to Selected, mark it **Promoted** in the triage table with the finding that earned it, and run step 3 on it. One promotion round only — angles surfacing after that are logged under `## Angles Not Attacked` with the unasked question, and do not reopen the pass.
- **Cascade** — findings that compound across angles (an edge case that triggers a failure cascade that nothing observes). Record compound findings as their own entries, citing the member findings.

An implication pass that promotes nothing and finds no cascades is a valid outcome — say so in the document rather than manufacturing connections.

### 5. DRAFT STRESS REPORT

```markdown
# Stress: [Subject]

> **Lead:** [name]
> **Subject:** [what is being attacked] | **Related:** [projex links]

---

## Bottom Line

> **PLACEHOLDER — fill in last, after all angles are closed.**

**Verdict:** Abort | Redesign | Fix Issues | Proceed with Caution | Approve

**Top Vulnerabilities:**
1. [Most critical — filled in last]
2. [Second critical — filled in last]
3. [Third critical — filled in last]

---

## Angle Triage

| Angle | Status | Reason / Earned by |
|-------|--------|--------------------|
| Assumption | Selected | [why relevant] |
| Scale | Skipped | [one-line reason] |
| Dependency | Promoted | [finding that implicated it] |

## Angles Not Attacked

> Angles implicated after the implication pass closed. Recorded, not analyzed.

| Angle | Surfaced by | What would have been asked |
|-------|-------------|---------------------------|
| [Angle] | [Finding that implied it] | [The unasked question] |

---

## Findings

### Finding 1: [Title]
**Severity:** Critical/High/Medium/Low | **Likelihood:** High/Medium/Low | **Angle:** [which]

**Target Claim:** [What the subject implicitly promises]

**Attack Vector:** [Concrete scenario — input, state, sequence, timeline]

**Impact:** [What breaks, how badly]

**Blast Radius:** [Scope of damage]

**Remediation:** [How to fix]

### Compound: [Title]
**Severity:** ... | **Angles:** [members] | **Member findings:** [Finding 2 + Finding 5]

[The cross-angle cascade]

---

## Held

> Claims attacked and survived. What was tried, and why it held.

### [Angle]: [Target claim]
**Tried:** [Attack scenarios attempted]
**Held because:** [The evidence or property that resisted]

---

## Remediation

### Must Fix (Before Proceeding)
- **[Issue]** ([angle]) → [Fix] → [How to verify]

### Should Fix (Before Production)
- **[Issue]** ([angle]) → [Fix]

### Monitor
- **[Issue]** ([angle]) → [When to revisit]

---

## Final Assessment

**Soundness:** Flawed | Serious Issues | Fixable | Solid with Caveats | Sound
**Risk:** Unacceptable | High | Medium | Low
**Readiness:** Not Ready | Needs Work | Ready with Fixes | Ready

**Conditions for Approval:**
- [ ] [Must be met]

**No-Go If:**
- [ ] [This is true]
```

### 6. VALIDATION

**Checks:**
- [ ] Every angle in the inventory appears in the triage table — Selected, Skipped (with reason), or Promoted (with earning finding)
- [ ] No angle attacked without a stated target claim
- [ ] Every finding cites concrete evidence — no unsubstantiated severity ratings
- [ ] Survived attacks recorded under Held with what was tried
- [ ] Implication pass run once — promotions and cascades checked, or their absence stated
- [ ] Angles surfacing after the implication pass logged under Angles Not Attacked
- [ ] Compound findings cite their member findings
- [ ] Remediation tiers map to findings, not generic advice
- [ ] Bottom Line written last and reflects the actual findings

### 7. FINALIZE

**De-slop pass:** Before saving, strip agent self-narration ("I'll now analyze...", "Let me consider..."), hollow hedging ("it's worth noting that", "it's important to consider"), and redundant restatements of findings already captured in the template sections.

**Fill in Bottom Line.** Replace the placeholder with the actual Verdict and Top Vulnerabilities synthesized from the completed findings.

Save to appropriate `.projex/` folder. Link to subject being analyzed. Do not commit automatically — commit only when explicitly requested.

---

## PRINCIPLES

- **Angle-first thinking** — Every finding traces to one named angle (or a named compound of angles)
- **Triage honestly** — Skips carry reasons; padding an irrelevant angle is worse than skipping it
- **Attacks target claims** — Name what the subject promises before breaking it; abstract doubt is not an attack
- **Survived attacks are results** — What held, and what was thrown at it, goes in the report
- **Assume nothing** — Every claim is guilty until proven innocent
- **No sacred cows** — Authority ≠ evidence, popularity ≠ correctness
- **Honest adversary** — Attack ideas not people, provide solutions not just criticism

---

## WHEN TO STRESS

**Well suited:** algorithms, configs, single scripts, document arguments, small designs, internal tooling — subjects whose claims can be attacked head-on.
**Strongly consider:** plans before execution, accepted proposals, anything about to become load-bearing.
**Optional:** minor features, low-risk changes.

---

## OUTPUT

Produces `.projex/{yymmddhhmm}-{name}-stress.md` with angle triage, severity-prioritized findings, held claims, and remediation.

**Folder placement:** Active → `.projex/` | Addressed → `.projex/closed/` | Superseded → `.projex/archived/`
