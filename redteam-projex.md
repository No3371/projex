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

### 1. IDENTIFY STAKEHOLDER ROLES

Before attacking, identify whose perspective matters. List ALL roles involved in or affected by the subject:

**Common roles to consider:**
- **End Users** — Who uses this?
- **Operators** — Who runs/maintains this?
- **Developers** — Who builds/extends this?
- **Security** — Who defends this?
- **Business/Product** — Who measures success?
- **Support** — Who handles issues?
- **Compliance/Legal** — Who ensures conformance?
- **Integrators** — Who connects to this?
- **Competitors** — Who benefits from this failing?
- **Attackers** — Who actively tries to break this?

**For each role, note:**
- What do they care about?
- What would make them unhappy?
- What assumptions do they make?
- What edge cases hit them?

### 2. ESTABLISH ATTACK SURFACE PER ROLE

For each identified role, map their specific attack surface:

**Per-Role Questions:**
- What does this role expect/require?
- What promises are made to this role?
- What assumptions does this role make?
- What can go wrong from this role's perspective?
- How does this role fail or get failed by the system?

### 3. ROLE-BASED ATTACK VECTORS

**For each role, execute these attacks:**

**Assumption Attacks (from role's view):**
- Says who? (What evidence does this role have?)
- Always? (What cases break for this role?)
- What if opposite? (from this role's perspective)
- Hidden dependencies? (What does this role need that's unstated?)

**Edge Cases (that hit this role):**
What specific scenarios cause problems for this role? Min/max values, null/empty data, concurrency, degraded dependencies, partial failures, resource exhaustion.

**Failure Modes (experienced by this role):**
What breaks when dependencies fail, assumptions prove false, scale increases, network partitions, data corrupts from this role's viewpoint?

**Security (from role's threat model):**
What would this role's adversary target? What's valuable to attack from this role's perspective?

### 4. CHALLENGE FRAMEWORK (ROLE-GROUNDED)

Apply these across all roles:

**Five Whys (per role):**
From each role's perspective: Why believe → assertion → evidence → source → authority → first principles or circular reasoning

**What Could Go Wrong Cascade (per role):**
Each role's happy path → first failure → cascade → worst-case → recovery cost

**Inversion Test (per role):**
For each role: "Should X" → "What if we don't X from this role's view?"

### 5. DRAFT RED TEAM REPORT

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

## Stakeholder Roles

| Role | Cares About | Pain Points | Critical Assumptions |
|------|-------------|-------------|---------------------|
| End Users | [What matters] | [What hurts] | [What they assume] |
| Operators | [What matters] | [What hurts] | [What they assume] |
| Developers | [What matters] | [What hurts] | [What they assume] |
| Security | [What matters] | [What hurts] | [What they assume] |
| [Other Role] | [What matters] | [What hurts] | [What they assume] |

---

## Attack Surface (Per Role)

**[Role 1]:**
- Claims to this role: [What's promised]
- Assumptions by/about role: [What's assumed]
- Dependencies: [What must work]

**[Role 2]:**
- Claims to this role: [What's promised]
- Assumptions by/about role: [What's assumed]
- Dependencies: [What must work]

---

## Critical Findings

### Finding 1: [Title]
**Severity:** Critical/High/Medium/Low | **Likelihood:** High/Medium/Low

**Affects Roles:** [Which roles experience this]

**Attack Vector:** [How to exploit]

**Role-Specific Impact:**
- **[Role 1]:** [How this hurts them]
- **[Role 2]:** [How this hurts them]

**Blast Radius:** [Scope of damage]

**Remediation:** [How to fix]

---

## Role-Based Assumption Challenges

### [Role]: [Assumption]
**Challenge:** [Why might this be false from role's perspective]
**Counter-Evidence:** [Evidence against from role's view]
**If Wrong:** [Impact on this role]
**Action:** Validate | Relax | Reject

---

## Role-Specific Edge Cases & Failures

### [Role]: [Edge Case/Failure Mode]
**Trigger:** [What causes this for this role]
**Role Experience:** [What this role sees/feels]
**Recovery:** Possible/Difficult/Impossible
**Mitigation:** [How to prevent from role's perspective]

---

## What's Hidden (Per Role)

**Omissions per role:**
- **[Role 1]:** What wasn't told to them?
- **[Role 2]:** What wasn't told to them?

**Tradeoffs per role:**
- **[Role 1]:** What did they sacrifice?
- **[Role 2]:** What did they sacrifice?

---

## Scale & Stress (Role Impact)

**At 10x:**
- **[Role 1]:** [What breaks for them]
- **[Role 2]:** [What breaks for them]

**At 100x:**
- **[Role 1]:** [What's impossible for them]
- **[Role 2]:** [What's impossible for them]

---

## Remediation

### Must Fix (Before Proceeding)
- **[Issue]** (affects: [roles]) → [Fix] → [Verify with roles]

### Should Fix (Before Production)
- **[Issue]** (affects: [roles]) → [Fix]

### Monitor
- **[Issue]** (affects: [roles]) → [When to revisit]

---

## Final Assessment

**Soundness:** Flawed | Serious Issues | Fixable | Solid with Caveats | Sound
**Risk:** Unacceptable | High | Medium | Low
**Readiness:** Not Ready | Needs Work | Ready with Fixes | Ready

**Per-Role Readiness:**
- **[Role 1]:** Ready/Not Ready — [Why]
- **[Role 2]:** Ready/Not Ready — [Why]

**Conditions for Approval:**
- [ ] [Must be met] (for [roles])

**No-Go If:**
- [ ] [This is true] (impacts [roles])
```

### 6. VALIDATION

**Checks:**
- [ ] All relevant stakeholder roles identified
- [ ] Each role's perspective analyzed independently
- [ ] Claims/assumptions challenged from each role's viewpoint
- [ ] Edge cases tested for each role's experience
- [ ] Acknowledged what's solid for each role
- [ ] Severity ratings justified per role impact
- [ ] Remediation addresses role-specific concerns

### 7. FINALIZE

Save to appropriate `projex/` folder. Link to subject being analyzed.

---

## PRINCIPLES

- **Role-first thinking** — Every finding must be grounded in a stakeholder role's reality
- **Assume nothing** — Every assumption is guilty until proven innocent per role
- **Break it first** — Find failure modes in safety from each role's perspective
- **No sacred cows** — Authority ≠ evidence, popularity ≠ correctness
- **Honest adversary** — Attack ideas not people, provide solutions not just criticism
- **Productive paranoia** — Build better systems through role-grounded skepticism

---

## WHEN TO RED TEAM

**Always:** Security, auth, payments, privacy, consensus
**Strongly consider:** Major architecture, accepted proposals, plans before execution, production deploys
**Optional:** Internal tools, minor features, low-risk changes

---

## OUTPUT

Produces `projex/{yyyymmdd}-{name}-redteam.md` with severity-prioritized findings and remediation.

**Folder placement:** Active → `projex/` | Addressed → `projex/closed/` | Superseded → `projex/archived/`