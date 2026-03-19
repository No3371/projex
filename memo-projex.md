---
description: This workflow guides the creation of **Memo** projex documents — lightweight capture of a raw source (quote, idea, issue, deferred objective) with whatever context the agent already has. No research, no exploration — just record and move on. (This is part of @projex-framework skill. It is a MUST to load the skill first.)
---

## PURPOSE

Memos capture something worth remembering before it gets lost — a user's offhand remark, an idea that surfaced during another workflow, an issue noticed in passing, objectives explicitly deferred. The agent records the raw source and annotates it with context from what it already knows at the time, without any further exploration or research.

**Key characteristics:**
- **Capture, not analyze** — record the thing, not a study of the thing
- **Zero research** — use only what's already in the agent's current context. Do not read additional files, explore code, or investigate. If context is thin, that's fine — the memo is honest about what was known
- **Active until consumed** — memos live in `.projex/` where they stay visible. Moved to `.projex/closed/` only when acted on (became a plan, fed into an eval, resolved, or deliberately dismissed)
- **Smallest projex type** — if a memo feels like it needs more than a few paragraphs, it's probably an Evaluation, Proposal, or Plan instead

**When to use:**
- User says something worth preserving verbatim ("we should eventually..." / "don't forget that..." / "I think the real problem is...")
- An idea surfaces during another workflow but is out of scope for that workflow
- An issue is noticed but shouldn't derail current work
- Objectives are explicitly deferred from a plan or patch
- A decision is made in conversation that should be recorded somewhere

**When NOT to use:**
- The thought needs investigation → Exploration or Evaluation
- The thought proposes a direction → Proposal
- The thought is actionable now → Patch or Plan
- The thought is a learning to remember for process → belongs in `_fluid_.md` or agent memory

---

## INVOCATION

```
/memo-projex <the thing to capture>
```

**Examples:**
- `/memo-projex User said "we should eventually split the parser into a separate crate"`
- `/memo-projex Deferred from @20260215-api-cleanup-plan.md: objectives 3 and 4 (auth token rotation)`
- `/memo-projex Noticed during execution: the test harness silently swallows stderr`
- `/memo-projex Idea: what if Maps auto-detected child maps instead of requiring manual linking?`

---

## WORKFLOW STEPS

### 1. IDENTIFY THE SOURCE

Classify what's being captured:

| Source Type | What it is |
|-------------|------------|
| **Quote** | Something the user said — preserve verbatim |
| **Idea** | A thought that emerged during work — attribute where it came from |
| **Issue** | A problem noticed in passing — describe what was observed |
| **Deferred** | Objectives or work explicitly postponed — reference the originating projex |

### 2. WRITE THE MEMO

Create file: `{yyyymmdd}-{memo-name}-memo.md` in `.projex/`

**Template:**

```markdown
# Memo: [Brief Title]

> **Date:** YYYY-MM-DD
> **Author:** [name or agent]
> **Source Type:** Quote | Idea | Issue | Deferred
> **Origin:** [where this came from — conversation, projex reference, workflow name, or "Direct"]

---

## Source

[The raw thing being captured — a verbatim quote, the idea as stated, the issue as observed, the deferred objectives listed. Preserve the original wording.]

---

## Context

[What the agent knows right now that makes this memo meaningful. Why does this matter? What was happening when this came up? What projex or work is this related to? What would someone need to know to pick this up later?

Do NOT research or explore to fill this section. Write only from current context.]

---

## Related Projex

- [Links to related projex documents, if any are known]
```

**That's it.** No analysis, no recommendations, no criteria, no validation checklist.

### 3. COMMIT

```bash
{projex-scripts}/projex-commit.{sh|ps1} <repo-root> "projex(memo): {brief description}" .projex/{yyyymmdd}-{memo-name}-memo.md
```

If a related projex should reference this memo (e.g., a plan whose objectives were deferred), update it:

```bash
{projex-scripts}/projex-commit.{sh|ps1} <repo-root> "projex(memo): link memo from {related-projex}" .projex/{related-projex-file}.md
```

---

## MEMO PRINCIPLES

- **Speed over completeness** — a memo that exists with thin context beats a memo that never gets written because the agent wanted to research first
- **Verbatim over paraphrase** — especially for user quotes. Capture their words, not your interpretation
- **Honest about context depth** — if you don't know much about why this matters, say so. Don't fabricate context
- **One thing per memo** — if you have three ideas, write three memos. Each should be independently discoverable
- **No scope creep** — if writing the memo makes you want to investigate, stop. Write the memo, then suggest the appropriate workflow (Eval, Explore, etc.) as a follow-up

---

## FOLDER PLACEMENT

See SKILL.md § Organizing. Memos stay active until consumed into plans, evaluations, or dismissed. A Navigation revision or Review pass is a natural time to sweep them.

---

## OUTPUT

This workflow produces:
- A memo document at `.projex/{yyyymmdd}-{memo-name}-memo.md`
- Optionally updated related projex documents

---

## NOTES

- Memos are the smallest projex type — if yours is growing past a few paragraphs, escalate
- Memos are searchable and linkable like any projex — they can be referenced by plans, evals, or navigations later
- A cluster of related memos may signal that an Evaluation or Proposal is warranted
- Navigation revisions are a natural time to sweep active memos — consume or dismiss them
- Use relative paths when referencing repository files
