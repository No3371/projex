---
description: This workflow guides **Interview** projex sessions — interactive Q&A between LLM and user, scoped to specific topics/subjects/files, conducted in rounds with detailed logging of questions, answers, and interpretations. (This is part of @projex-framework skill. It is a MUST to load the skill first.)
---

## PURPOSE

Interviews extract knowledge, clarify understanding, and explore topics through structured back-and-forth Q&A. Each round the agent explores the scope, formulates questions, asks them one-by-one, and logs everything with interpretations.

**CRITICAL: Interviews are read-only. No code changes, no file edits, no implementations. Only the interview document itself is written.**

**Key characteristics:**
- Scoped to specific topics/subjects/files
- Conducted in rounds (3-5 questions per round)
- Questions asked sequentially, not in batch
- Full transcript logged: questions, raw answers, interpretations
- User controls continuation or conclusion
- Read-only: gather information, don't take action

---

## INVOCATION

```
/interview-projex.md <scope/topic>
/interview-projex.md authentication system design
/interview-projex.md @20260731-database-schema.md
/interview-projex.md user requirements for the new feature
```

---

## WORKFLOW

### 1. ESTABLISH INTERVIEW SCOPE

**Define scope:**
- What topics/subjects/files are in scope?
- What's the goal of this interview? (extract requirements, clarify design, understand constraints, etc.)
- What depth is needed? (high-level overview vs deep technical details)
- Any specific areas to focus on or avoid?

**Create interview file:** `{yyyymmdd}-{topic}-interview.md`

### 2. ROUND STRUCTURE

Each round follows this pattern:

1. **Explore scope** — Review what's known, identify knowledge gaps
2. **Formulate questions** — Generate 3-5 questions to ask
3. **Log questions** — Write them to the interview document
4. **Ask sequentially** — Ask ONE question, wait for answer, log it, then ask next
5. **After round** — Ask user: continue or conclude?

### 3. QUESTION FORMULATION

**Good interview questions:**
- Open-ended (not yes/no unless clarifying)
- Focused on one aspect at a time
- Build on previous answers
- Explore gaps in current understanding
- Appropriate depth for the scope

**Question types to use:**
- **Exploratory:** "What are the main challenges with X?"
- **Clarifying:** "When you said Y, did you mean Z?"
- **Contextual:** "How does X relate to Y?"
- **Constraint-seeking:** "What limitations exist for X?"
- **Priority-seeking:** "What's most important about X?"
- **Edge-case probing:** "What happens when X?"

### 4. ASKING QUESTIONS

**Critical: Ask ONE question at a time**

Wait for user's answer before asking the next question. Do NOT batch questions.

**Pattern:**
```
Agent: [Question 1]
User: [Answer 1]
Agent: [Logs answer] [Question 2]
User: [Answer 2]
Agent: [Logs answer] [Question 3]
...
```

### 5. LOGGING ANSWERS

For each answer, log three things:

1. **Question** — The exact question asked
2. **Raw Answer** — User's verbatim response
3. **Interpretation** — Agent's understanding/summary of what was said

**Interpretation should:**
- Summarize key points
- Extract actionable information
- Note ambiguities or contradictions
- Identify follow-up needs

### 6. INTERVIEW DOCUMENT TEMPLATE

Create file: `{yyyymmdd}-{topic}-interview.md`

```markdown
# Interview: [Topic]

> **Date:** YYYY-MM-DD | **Interviewer:** [agent name]
> **Scope:** [What this interview covers]
> **Goal:** [Purpose of this interview]
> **Status:** In Progress | Concluded

---

## Interview Scope

**Topics Covered:**
- [Topic 1]
- [Topic 2]

**Focus Areas:**
- [Area 1]
- [Area 2]

**Out of Scope:**
- [What's not covered]

---

## Round 1

**Goal for this round:** [What we're trying to learn]

**Questions prepared:**
1. [Question 1]
2. [Question 2]
3. [Question 3]
4. [Question 4]
5. [Question 5]

---

### Q1: [Question]

**Answer:**
```
[User's verbatim response]
```

**Interpretation:**
[Agent's understanding of the answer - key points, actionable info, ambiguities noted]

**Follow-up needed:** [Any clarifications needed, or None]

---

### Q2: [Question]

**Answer:**
```
[User's verbatim response]
```

**Interpretation:**
[Agent's understanding]

**Follow-up needed:** [Any clarifications needed, or None]

---

### Q3: [Question]

[Same structure]

---

### Round 1 Summary

**Key Learnings:**
- [Learning 1]
- [Learning 2]

**Gaps Identified:**
- [Gap 1]
- [Gap 2]

**Next Round Focus:** [What to explore next, if continuing]

---

## Round 2

**Goal for this round:** [What we're trying to learn based on Round 1]

**Questions prepared:**
1. [Question 1]
2. [Question 2]
3. [Question 3]

---

### Q1: [Question]

[Same Q&A structure as Round 1]

---

[Continue for each round]

---

## Interview Conclusion

**Total Rounds:** [Number]
**Total Questions:** [Number]

**Key Findings:**
1. [Major finding 1]
2. [Major finding 2]
3. [Major finding 3]

**Requirements Extracted:** (if applicable)
- [Requirement 1]
- [Requirement 2]

**Constraints Identified:** (if applicable)
- [Constraint 1]
- [Constraint 2]

**Decisions Made:** (if applicable)
- [Decision 1]
- [Decision 2]

**Open Questions:** (if any)
- [ ] [Unresolved question 1]
- [ ] [Unresolved question 2]

**Recommended Next Steps:**
1. [Action 1]
2. [Action 2]

---

## Artifacts

**Related Documents:**
- [Link to related projex/docs]

**Follow-up Projex:**
- [Proposals to create based on this interview]
- [Plans to create based on this interview]
```

### 7. ROUND EXECUTION GUIDE

**Starting a round:**

```markdown
--- Beginning Round [N] ---

Based on what we've learned so far, I've identified [N] questions to explore:

1. [Question preview 1]
2. [Question preview 2]
3. [Question preview 3]

Let me ask them one by one.

**Question 1:** [Full question text]
```

**After each answer:**

```markdown
[Log the answer to document]

Thank you. Let me ask the next question.

**Question 2:** [Full question text]
```

**After completing the round:**

```markdown
--- Round [N] Complete ---

That concludes Round [N]. 

**What we learned this round:**
- [Summary point 1]
- [Summary point 2]

**Would you like to:**
1. Continue with another round (I'll explore [topic/gap])
2. Conclude the interview

What would you prefer?
```

### 8. ADAPTATION STRATEGIES

**If user's answer is unclear:**
- Ask immediate clarifying follow-up (doesn't count toward round questions)
- Log the clarification in the same Q&A entry

**If user reveals unexpected information:**
- Adjust remaining questions in the round
- Add new areas to explore in next round
- Note this in round summary

**If scope needs adjustment:**
- Discuss with user before next round
- Update scope section in document
- Adjust question focus accordingly

### 9. CONCLUSION CRITERIA

**Interview should conclude when:**
- User requests to stop
- All major questions answered
- Diminishing returns on new questions
- Scope has been thoroughly covered
- Follow-up projex can now be created

**After conclusion:**
- Summarize key findings
- Extract actionable outcomes
- Recommend next steps (proposals, plans, etc.)
- Update status to "Concluded"

---

## PRINCIPLES

- **Read-only workflow** — NEVER edit code, create files, or take implementation actions during interview
- **One question at a time** — Never batch questions, always wait for answer
- **Active listening** — Build on what user says, adapt questions dynamically
- **Full transparency** — Log everything: questions, raw answers, interpretations
- **User controls pace** — User decides when to continue or stop
- **Scope discipline** — Stay within defined scope unless user expands it
- **Interpretation honesty** — Note when unclear, don't assume meaning

---

## INTERVIEW TYPES

**Requirements Gathering:**
Focus on what, why, who, constraints, priorities

**Design Clarification:**
Focus on how, tradeoffs, alternatives, rationale

**Knowledge Extraction:**
Focus on deep technical understanding, edge cases, gotchas

**Problem Exploration:**
Focus on pain points, current state, desired state

**Validation:**
Focus on confirming understanding, checking assumptions

---

## OUTPUT

Produces `projex/{yyyymmdd}-{topic}-interview.md` with full Q&A transcript, interpretations, and findings.

**Folder placement:** Active → `projex/` | Concluded → `projex/closed/`

---

## INTEGRATION WITH OTHER WORKFLOWS

**Interview typically leads to:**
- **Proposals** — Based on requirements/ideas extracted
- **Plans** — Based on clarified designs/approaches
- **Evaluations** — To assess options discussed
- **Explorations** — To investigate topics surfaced

**Interview can support:**
- **Review** — Interview stakeholders about existing projex validity
- **Audit** — Interview implementers about what was actually done
- **Red Team** — Interview from adversarial perspective to find issues

---

## NOTES

- Interviews are conversational but structured
- Every round's questions logged BEFORE asking
- Every answer logged WITH interpretation
- Adapt dynamically but stay in scope
- User always controls continuation
- Use relative paths when referencing repository files