---
description: This workflow guides **Coach** projex sessions — interactive judgment: collect the full picture through Q&A, state a position, hear pushback, and converge with the user on the best practical answer. (This is part of @projex-framework skill. It is a MUST to load the skill first.)
---

## PURPOSE

Coach takes any judgeable subject — abstract (an idea, a belief, a drive to do something) or concrete (something done, an event, a plan) — collects the full picture through Q&A, then exercises judgment: states a position with reasoning, hears the user's response, and iterates until both sides agree on the best/practical answer — or the disagreement itself is documented.

Boundaries: Interview collects without judging. Red Team attacks an artifact unilaterally. Eval is the agent thinking alone. Coach = interactive + judgmental + convergent.

**CRITICAL: Coach sessions are read-only. No code changes, no file edits, no implementations. Only the coach document itself is written.**

---

## INVOCATION

```
/coach-projex <subject>
/coach-projex should I rewrite the sync engine or keep patching it
/coach-projex @2607311430-database-schema.md
/coach-projex my decision to self-host the CI runners
/coach-projex I want to turn this side project into a product
```

---

## WORKFLOW

### 1. ESTABLISH SUBJECT

Define what is being judged and what "best outcome" would mean — agree on the criteria up front. Create the coach file: `{yymmddhhmm}-{subject}-coach.md`

### 2. COLLECT

Interview-style Q&A to build enough picture to judge fairly. Ask **one question at a time**:

- **If the codebase/documents can answer it, explore instead** — don't ask the user what you can discover yourself.
- **Log as you go** — question, verbatim answer, interpretation.
- Stop collecting when you can state a fair position — not when every branch is exhausted. Later rounds may reopen collection.

### 3. JUDGE & DISCUSS

Iterate in rounds. Each round:

- **State your position first** — assessment + reasoning, committed to the document before hearing the user's rebuttal. Never ask what the user thinks the verdict should be before giving yours.
- **Hear the response** — the user confirms, rebuts, or adds context. Log verbatim.
- **Move only for reasons** — change position only for a stated reason, and record that reason. New facts and better arguments move you; pressure and repetition do not.
- New information may send you back to COLLECT — that's normal.

Continue until positions converge, or stop moving.

### 4. CONCLUDE

Two valid closes:

- **Consensus** — both sides agree on the answer/outcome. Record it, and how each side moved to get there.
- **Dissent** — positions are stable but apart. Record both final positions and the crux of disagreement. This is a valid close, not a failure — never manufacture consensus to end the session.

Then extract recommended next steps and set status to `Complete (Consensus)` or `Complete (Dissent)`.

---

## DOCUMENT TEMPLATE
```bash
Resolve `{parent}` from an explicit causal subject/nav/source filename; else supplied orchestrator Parent; else `User`.
{projex-scripts}/new-projex.sh --repo-root <repo-root> --type coach --title "{subject}" --parent {parent} --projex-dir <projex-folder>
```
```powershell
{projex-scripts}\new-projex.ps1 -RepoRoot <repo-root> -Type coach -Title "{subject}" -Parent {parent} -ProjexDir <projex-folder>
```

```markdown
# Coach: [Subject]

> **Subject:** [What's being judged]
> **Goal:** [What "best outcome" means — agreed criteria] | **Status:** In Progress | Complete (Consensus) | Complete (Dissent)

---

## Subject

**Being judged:** [The idea / event / plan / decision]
**Best outcome means:** [Criteria agreed in step 1]

---

## Collection

### Q1: [Question]

**User's answer:**
> [Verbatim response]

**Interpretation:** [Key points, actionable info, ambiguities]

---

[Continue as needed — collection may reopen between rounds]

---

## Rounds

### Round 1

**Position:** [Agent's assessment + reasoning — stated before hearing rebuttal]

**Response:**
> [Verbatim user response]

**Movement:** [Held — why the rebuttal doesn't change it | Moved — what changed and the stated reason]

---

### Round 2

[Same structure]

---

## Conclusion

**Outcome:** Consensus | Dissent

**Final answer:** [The agreed answer/outcome — or each side's final position]

**How positions moved:** [Trail: who moved, on what, for what reason]

**Crux (if Dissent):** [The load-bearing disagreement neither side could resolve]

**Recommended Next Steps:**
1. [Action]

---

## Artifacts

**Follow-up Projex:** [Plans, proposals, memos to create based on this session]
```

---

## PRINCIPLES

- **Read-only** — NEVER edit code or take implementation actions
- **Position before rebuttal** — commit your assessment to the document before the user responds to it
- **Move only for reasons** — every position change carries a recorded reason; agreement is never the goal, the best answer is
- **Dissent is a valid close** — documented disagreement beats manufactured consensus
- **One question at a time** — during collection, never batch
- **Self-serve** — explore instead of asking when possible
- **Judge the subject, not the person** — candor about the idea, respect for its owner

---

## OUTPUT

Produces `.projex/{yymmddhhmm}-{subject}-coach.md` with full transcript: collection Q&A, round-by-round position trail, and the consensus or dissent record.

**Folder placement:** Active (`In Progress`) → `.projex/` | `Complete (Consensus/Dissent)` → `.projex/closed/`

**Committing:** Present to the user. Do not commit automatically.
