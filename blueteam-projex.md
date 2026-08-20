---
description: This workflow guides **Blue Team** projex sessions — defending a subject against its red team report, screening each finding against current reality and settling a disposition per finding with the user. (This is part of @projex-framework skill. It is a MUST to load the skill first.)
---

## PURPOSE

Defend a subject against the red team report written about it. Screen every finding against what the subject actually is now, walk the findings that still hold one at a time with the user, and settle each into a disposition and a defense plan.

**Boundary:** `/redteam-projex.md` attacks and never defends. `/interview-projex.md` walks an open topic tree; here the tree is the source report's finding list. `/patch-projex.md` and `/plan-projex.md` own the fixes this workflow recommends.

No code changes, no file edits, no implementations. Only touch the blue team document.

---

## INVOCATION

```
/blueteam-projex.md @2607311430-auth-system-redteam.md
/blueteam-projex.md <red team document>
/blueteam-projex.md Defend the auth plan against its red team report
```

---

## WORKFLOW

### 1. LOAD THE RED TEAM REPORT

Input must be a `-redteam.md` document. Reject anything else.

Extract every record the report grades — `### Finding N:`, assumption challenges, edge cases and failure modes — into the ledger, one row each, with stable IDs (`F1`, `F2`, …). Carry the source severity forward unchanged.

Create the blue team file now, before screening:
```bash
Resolve `{parent}` from the source red team filename; else supplied orchestrator Parent; else `User`.
{projex-scripts}/new-projex.sh --repo-root <repo-root> --type blueteam --title "{subject}" --parent {parent} --projex-dir <projex-folder>
```
```powershell
{projex-scripts}\new-projex.ps1 -RepoRoot <repo-root> -Type blueteam -Title "{subject}" -Parent {parent} -ProjexDir <projex-folder>
```

### 2. SCREEN

Check each ledger entry against the subject as it stands now — code, documents, observed behavior. Assign a screen verdict with cited evidence:

- **Holds** — the attack still applies to the current subject
- **Lapsed** — already fixed, or the attacked construct no longer exists
- **Out of Scope** — targets something the subject does not own

Only `Holds` enters step 3. Record `Lapsed` and `Out of Scope` with their evidence in `## Screened Out`. The user may promote any screened-out finding back into the loop.

### 3. DEFEND

Loop over the holding findings, highest severity first:

- Research what the subject actually does against this attack and what compensating controls exist.
- Write the question into the document before asking it.
- State the recommended disposition and the defense, then ask one consolidated confirmation.
- Branch into further questions only when the user disputes the recommendation.
- Record the verbatim answer and the settled disposition before moving to the next finding.

Disposition: `Refuted | Already Mitigated | Accept Risk | Must Fix`.

Note: User facing conversation/Questions should be as rich/verbose as what is written into the question, if not more. It'd be inconvenience that the user mush look up the written question or referred document to understand what are you asking about.

### 4. CONSOLIDATE

Group the settled dispositions into the defense plan, order the `Must Fix` set by severity and dependency, and state what risk remains after everything in the plan lands.

### 5. VALIDATION

- [ ] Every record in the source report appears in the ledger exactly once
- [ ] Every `Holds` finding carries a question, a verbatim answer, and a disposition
- [ ] Every `Lapsed` or `Out of Scope` verdict cites evidence
- [ ] Every `Must Fix` disposition appears in the defense plan
- [ ] Residual risk accounts for every `Accept Risk` disposition
- [ ] No file outside the blue team document was written

### 6. FINALIZE

**De-slop pass:** strip hedging, restatement, and defensive framing from every record. A defense that needs a paragraph of qualification is an `Accept Risk`, not a `Refuted`.

**Fill in Bottom Line.** Write it last, from the settled ledger.

Update status, then present to the user.

---

## DOCUMENT TEMPLATE

```markdown
# Blue Team: [Subject]

> **Status:** In Progress
> **Source:** [redteam filename] | **Subject:** [what is being defended]
> **Related:** [projex links]

---

## Bottom Line

> [One paragraph: does the subject survive its red team]

**Verdict:** Hold Position | Fix Then Proceed | Redesign | Concede

**Top Residual Risks:**
1. [Risk]

---

## Finding Ledger

| ID | Finding | Severity | Screen | Disposition |
| --- | --- | --- | --- | --- |
| F1 | [Title from source] | Critical | Holds | Must Fix |

---

## Screened Out

### F2: [Finding title]
**Screen:** Lapsed | Out of Scope
**Evidence:** [file:ln, document, observed behavior]

---

## Defenses

### F1: [Finding title]

**Source:** Finding N | **Severity:** Critical/High/Medium/Low | **Screen:** Holds

**Attack restated:** [the red team's claim in one line]

**Evidence checked:** [file:ln, document, observed behavior]

**Recommended disposition:** Refuted | Already Mitigated | Accept Risk | Must Fix

**Defense:** [why the subject withstands this, or the compensating control]

**Question:** [verbatim question put to the user]

**User's answer:**
> [Verbatim response]

**Disposition:** Refuted | Already Mitigated | Accept Risk | Must Fix

**Follow-up:** [patch / plan / none]

---

### F3: [Finding title]

[Same structure]

---

## Defense Plan

### Must Fix
1. [F-id] [Action] — [owner workflow]

### Mitigate
- [F-id] [Compensating control]

### Accept & Monitor
- [F-id] [What is being accepted, what signal would reverse it]

---

## Residual Risk

[What remains exposed after the defense plan lands, and under what conditions it bites]

---

## Artifacts

**Follow-up Projex:** [Patches, plans, etc. to create from the Must Fix set]
```

---

## PRINCIPLES

- **Read-only** — NEVER edit code, and never edit the source red team document
- **Screen before defending** — a finding that no longer applies costs a citation, not an interview
- **Evidence over argument** — a defense cites what the subject does, not what it intends
- **One finding at a time** — never batch findings into one question
- **Concede cleanly** — `Must Fix` is a valid outcome; a report where nothing holds means the screening was lazy
- **Severity survives** — the source's severity carries forward unchanged, whatever the disposition

---

## OUTPUT

Produces `.projex/{yymmddhhmm}-{name}-blueteam.md` with a per-finding disposition ledger and a defense plan.

**Folder placement:** Active (`In Progress`) → `.projex/` | `Complete` → `.projex/closed/`

**Committing:** Present to the user. Do not commit automatically.
