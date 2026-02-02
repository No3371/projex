---
description: This workflow guides the creation of **Red Team** projex documents — adversarial analysis that challenges assumptions, finds weaknesses, exploits edge cases, and identifies imperfections. (This is part of @projex-framework skill. It is a MUST to load the skill first.)
---

## PURPOSE

Red Teams break things before they break in production. Attack ideas, find exploits, challenge assumptions, expose hidden flaws.

**Modes:** Attack (break it) | Skeptic (challenge it) | Pessimist (worst case) | Contrarian (argue opposite) | Forensic (what's hidden)

---

## INVOCATION

```
/redteam-projex.md <subject to attack>
/redteam-projex.md @20260731-auth-system-plan.md
```

---

## WORKFLOW

### 1. ESTABLISH ATTACK SURFACE

What exactly are you attacking? What does it claim? What assumptions does it make? Who benefits/loses? What's the blast radius?

Map: claims to disprove, assumptions to challenge, edge cases to break, dependencies that can fail, promises that can't be kept.

### 2. ATTACK VECTORS

**Assumption Attacks:**
- Says who? (What evidence?)
- Always? (What cases break this?)
- What if opposite?
- Hidden dependencies?

**Edge Cases:**
Min/max values, null/empty data, concurrency, degraded dependencies, partial failures, resource exhaustion, race conditions, timing.

**Failure Modes:**
What breaks when: dependencies fail, assumptions prove false, scale increases 10x/100x, network partitions, data corrupts, users misbehave, time passes.

**Security:**
What would an attacker target? Highest-value exploit? Trust boundaries? Missing validation? Missing rate limits?

### 3. CHALLENGE FRAMEWORK

**Five Whys (Adversarial):**
1. Why believe this? → assertion
2. Why true? → evidence  
3. Why valid? → source
4. Why trust? → authority
5. Why accept? → first principles or circular reasoning

**What Could Go Wrong Cascade:**
Happy path → first failure → cascade → worst-case → recovery cost

**Inversion Test:**
"Should X" → "What if we don't X?"
"Improves Y" → "What if worse Y?"

### 4. DRAFT RED TEAM REPORT

Create file: `{yyyymmdd}-{subject}-redteam.md`

```markdown
# Red Team: [Subject]

> **Created:** YYYY-MM-DD | **Lead:** [name] | **Mode:** Attack/Skeptic/Pessimist/Contrarian/Forensic
> **Subject:** [what is being attacked] | **Related:** [projex links]

---

## Bottom Line

**Verdict:** Abort | Redesign | Fix Issues | Proceed with Caution | Approve

**Top Vulnerabilities:**
1. [Most critical]
2. [Second critical]  
3. [Third critical]

---

## Attack Surface

**Claims:** What does it promise?
**Stated Assumptions:** What does it assume?
**Hidden Assumptions:** What's unstated?
**Dependencies:** What must work for this to work?

---

## Critical Findings

### Finding 1: [Title]
**Severity:** Critical/High/Medium/Low | **Likelihood:** High/Medium/Low

**Attack Vector:** [How to exploit]

**Impact:** [Technical/Business/Security consequences]

**Blast Radius:** [Scope of damage]

**Remediation:** [How to fix]

---

## Assumption Challenges

### [Assumption]
**Challenge:** [Why might this be false]
**Counter-Evidence:** [Evidence against]
**If Wrong:** [Impact]
**Action:** Validate | Relax | Reject

---

## Edge Cases & Failures

### [Edge Case/Failure Mode]
**Trigger:** [What causes this]
**Behavior:** [What actually happens]
**Recovery:** Possible/Difficult/Impossible
**Mitigation:** [How to prevent]

---

## What's Hidden

**Omissions:** What wasn't mentioned?
**Tradeoffs:** What was sacrificed?
**Alternative:** What else could work?

---

## Scale & Stress

**At 10x:** [What breaks]
**At 100x:** [What's impossible]
**Under Stress:** [Failure modes]

---

## Remediation

### Must Fix (Before Proceeding)
- [Issue] → [Fix] → [Verify]

### Should Fix (Before Production)
- [Issue] → [Fix]

### Monitor
- [Issue] → [When to revisit]

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

### 5. VALIDATION

**Checks:**
- [ ] Every claim challenged, multiple attack vectors explored
- [ ] Edge cases tested (not just imagined)
- [ ] Acknowledged what's actually solid
- [ ] Severity ratings justified, recommendations actionable

### 6. FINALIZE

Save to appropriate `projex/` folder. Link to subject being analyzed.

---

## PRINCIPLES

- **Assume nothing** — Every assumption is guilty until proven innocent
- **Break it first** — Find failure modes in safety, not production
- **No sacred cows** — Authority ≠ evidence, popularity ≠ correctness
- **Honest adversary** — Attack ideas not people, provide solutions not just criticism
- **Productive paranoia** — Build better systems through skepticism

---

## WHEN TO RED TEAM

**Always:** Security, auth, payments, privacy, consensus
**Strongly consider:** Major architecture, accepted proposals, plans before execution, production deploys
**Optional:** Internal tools, minor features, low-risk changes

---

## OUTPUT

Produces `projex/{yyyymmdd}-{name}-redteam.md` with severity-prioritized findings and remediation.

**Folder placement:** Active → `projex/` | Addressed → `projex/closed/` | Superseded → `projex/archived/`

