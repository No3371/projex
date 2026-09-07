---
description: This workflow guides **Interview** projex sessions — relentless Q&A that walks the decision tree of a topic until reaching shared understanding. (This is part of @projex-framework skill. It is a MUST to load the skill first.)
---

## PURPOSE

Extract knowledge or intention through relentless, focused Q&A. Walk each branch of the topic tree, resolve dependencies between answers one-by-one, and log everything, until all ambiguities and uncharted domains are exhausted.

No code changes, no file edits, no implementations. Only touch the interview document.

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

Define what the interview covers, its goal, and create the interview file:
```bash
Resolve `{parent}` from an explicit causal topic/source filename; else supplied orchestrator Parent; else `User`.
{projex-scripts}/new-projex.sh --repo-root <repo-root> --type interview --title "{topic}" --parent {parent} --projex-dir <projex-folder>
```
```powershell
{projex-scripts}\new-projex.ps1 -RepoRoot <repo-root> -Type interview -Title "{topic}" -Parent {parent} -ProjexDir <projex-folder>
```

### 2. INTERVIEW

Loop:

- Walk the topic tree. Research what needs to be discussed or answered.
- Explore established facts/sources that are relevant and may answer the question.
- Derive the next question. Then look ahead: if the questions that follow it are already clear and their framing does not change no matter how this one is answered, derive them now and ask the whole set together.
- Stop extending the batch at the first question whose wording, options, or relevance depends on an answer still pending. That one waits for the next round.
- Batch size follows the lookahead, not a target — usually 2–4; one question is the normal case when the tree branches on every answer.
- Number a batch as one question with lettered parts (`Q3a`, `Q3b`, …) so the shared derivation stays visible in the transcript.
- Provide your recommended answer for each question — show your thinking, then ask the user to confirm, correct, or expand.
- Log as you go — Write the question first before asking, then record the answer and your interpretation in the document.
- Each answer may branches the interview; follow them systematically.

Keep going until reaching shared understanding on all branches. The user can stop at any time.

Note: User facing conversation/Questions should be as rich/verbose as what is written into the question, if not more. It'd be inconvenience that the user must research your questions or referenced subjects. Utilize ask tool from the environment when applicable.

### 3. CONCLUDE

When all branches are resolved or the user stops:

- Summarize key findings and conclusions
- Extract actionable outcomes
- Recommend next steps (proposals, plans, etc.)
- Update status to `Complete (Concluded)`

---

## DOCUMENT TEMPLATE


```markdown
# Interview: [Topic]

> **Scope:** [What this interview covers]
> **Goal:** [Purpose] | **Status:** In Progress | Complete (Concluded)

---

## Scope

**In scope:** [Topics covered]
**Out of scope:** [What's excluded]

---

## Q&A

### Q1: [Question]

[**Context: Why the question**]

**Recommended answer:** [Agent's recommendation with reasoning]

**User's answer:**
> [Verbatim response]

**Interpretation:** [Key points, actionable info, ambiguities]

---

### Q2: [Question]

[Same structure]

---

### Q3: [Shared question framing — batched parts]

[**Context: Why these are asked together — what made the later parts derivable in advance**]

**Q3a: [Question]**
**Recommended answer:** [Agent's recommendation with reasoning]

**Q3b: [Question]**
**Recommended answer:** [Agent's recommendation with reasoning]

**User's answer:**
> [Verbatim response]

**Interpretation:** [Key points per part, actionable info, ambiguities]

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
- **Batch by lookahead** — ask together only the questions already derivable and unchanged by the pending answers; otherwise one at a time
- **Recommend answers** — show your thinking, let the user confirm or correct
- **Self-serve** — do your own research, ask right and good question
- **Relentless** — keep going until shared understanding on all branches
- **Honest interpretation** — note when unclear, ask for clarification when needed, avoid making assumptions

---

## OUTPUT

Produces `.projex/{yymmddhhmm}-{topic}-interview.md` with full Q&A transcript.

**Folder placement:** Active (`In Progress`) → `.projex/` | `Complete (Concluded)` → `.projex/closed/`

**Committing:** Present to the user. Do not commit automatically.
