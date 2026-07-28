---
description: This workflow guides **Interview** projex sessions — relentless Q&A that walks the decision tree of a topic until reaching shared understanding. (This is part of @projex-framework skill. It is a MUST to load the skill first.)
---

## PURPOSE

Interviews extract knowledge through relentless, focused Q&A. Walk each branch of the topic tree, resolve dependencies between answers one-by-one, and log everything.

**CRITICAL: Interviews are read-only. No code changes, no file edits, no implementations. Only the interview document itself is written.**

---

## INVOCATION

```
/interview-projex <scope/topic>
/interview-projex authentication system design
/interview-projex @2607311430-database-schema.md
/interview-projex book chapter outline and argument structure
```

---

## WORKFLOW

### 1. ESTABLISH SCOPE

Define what the interview covers, its goal, and create the interview file: `{yymmddhhmm}-{topic}-interview.md`

### 2. INTERVIEW

Ask questions **one at a time**. For each question:

- **Provide your recommended answer** — show your thinking, then ask the user to confirm, correct, or expand.
- **If the codebase can answer it, explore the codebase instead** — don't ask the user what you can discover yourself.
- **Walk the decision tree** — each answer opens branches; follow them systematically.
- **Log as you go** — record the question, answer, and your interpretation in the document.

Keep going until reaching shared understanding on all branches. The user can stop at any time.

### 3. CONCLUDE

When all branches are resolved or the user stops:

- Summarize key findings and decisions
- Extract actionable outcomes
- Recommend next steps (proposals, plans, etc.)
- Update status to `Complete (Concluded)`

---

## DOCUMENT TEMPLATE

```bash
{projex-scripts}/new-projex.{sh|ps1} <repo-root> interview "{topic}" <projex-folder>
```

```markdown
# Interview: [Topic]

> **Date:** YYYY-MM-DD | **Scope:** [What this interview covers]
> **Goal:** [Purpose] | **Status:** In Progress | Complete (Concluded)

---

## Scope

**In scope:** [Topics covered]
**Out of scope:** [What's excluded]

---

## Q&A

### Q1: [Question]

**Recommended answer:** [Agent's recommendation with reasoning]

**User's answer:**
> [Verbatim response]

**Interpretation:** [Key points, actionable info, ambiguities]

---

### Q2: [Question]

[Same structure]

---

[Continue for all questions — no artificial round limits]

---

## Conclusion

**Key Findings:**
1. [Finding]

**Decisions Made:**
- [Decision]

**Open Questions:**
- [ ] [Unresolved]

**Recommended Next Steps:**
1. [Action]

---

## Artifacts

**Follow-up Projex:** [Proposals, plans, etc. to create based on this interview]
```

---

## PRINCIPLES

- **Read-only** — NEVER edit code or take implementation actions
- **One question at a time** — never batch questions
- **Recommend answers** — show your thinking, let the user confirm or correct
- **Self-serve** — explore the codebase instead of asking when possible
- **Relentless** — keep going until shared understanding on all branches
- **Honest interpretation** — note when unclear, don't assume meaning

---

## OUTPUT

Produces `.projex/{yymmddhhmm}-{topic}-interview.md` with full Q&A transcript.

**Folder placement:** Active (`In Progress`) → `.projex/` | `Complete (Concluded)` → `.projex/closed/`

**Committing:** Present to the user. Do not commit automatically.
