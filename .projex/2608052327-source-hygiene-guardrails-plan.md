# Source Hygiene Guardrails — Rules, Commit Composition, Audit Pass

> **Status:** In Progress
> **Author:** agent (Claude, opus)
> **Source:** 2608051553-source-hygiene-guardrails-proposal.md (Option B, accepted)
> **Related Projex:** 2608051553-source-hygiene-guardrails-proposal.md | 2608052346-source-hygiene-guardrails-plan-redteam.md | 2608111922-source-hygiene-guardrails-plan-review.md | 2604031727-workflow-guardrails-determinism-imagine.md
> **Worktree:** Yes
> **Reviewed:** 2026-08-11 — 2608111922-source-hygiene-guardrails-plan-review.md — Verdict: Revise. All 5 Actions applied 2026-08-11 (§ Revision Log).
> **Red Team:** 2608052346-source-hygiene-guardrails-plan-redteam.md — Verdict: Fix Issues / Needs Work. All 5 Must-Fix + 2 No-Go conditions dispositioned (Notes § Red Team Dispositions).

---

## Summary

Renders Option B of the accepted proposal into the framework specs: a six-rule `SKILL.md § Source Hygiene` governing what execution writes into source comments, a commit-composition convention (conventional-type subjects on commits that land source + a `Projex:` trailer) canonical in `execute-projex.md § Commit Message Convention`, the per-workflow commit-template edits that follow from it, and a dedicated Source Hygiene Pass in `audit-projex.md` as the single enforcement point.

**Scope:** Markdown spec files at the repo root only. No script changes, no test changes, no `.projex/` document changes beyond this plan's own lifecycle.
**Estimated Changes:** 8 files, 7 steps — 1 new SKILL.md section, 1 rewritten execute-projex convention block, 1 new audit-projex workflow step + report section, 6 commit-template/cross-reference edits.

---

## Objective

### Problem / Gap / Need

The framework governs projex *documents* rigorously (Dehydrate, De-slop, naming, git discipline) but is silent on what an executing agent writes into *source*. Evidence from a mature target repo (proposal § Evidence): 173 comments citing bare projex IDs, 122 hardcoded `file:ln` refs (5 provably rotted), 94% of commit subjects flattened to bare `projex:`, 40 `// Step N:` markers plus 48 banner runs. Two coupled gaps:

1. **No source-comment ruleset.** Nothing constrains comment content, so plan structure, doc citations, and rotting line numbers accumulate.
2. **Commit convention overwrites semantics.** `projex:` on every landing commit means `git log --oneline` cannot answer feat-vs-fix, and there is no durable code→doc link that survives archival.

The two must ship together: banning comment citations (rule 1) without a replacement channel severs traceability entirely.

### Success Criteria

- [ ] `SKILL.md` contains a `## Source Hygiene` section stating all six rules, the source/comment definition sentence, rule 1's shipped-doc promotion clause, and the "no density or length caps" line
- [ ] `execute-projex.md § Commit Message Convention` contains the commit-class table, the `<type>` vocabulary with diff-keyed selection guidance, the trailer form `Projex: {yymmddhhmm}-{name}` with its resolution rule, and the trailer-survival condition; `close-projex.md` § 7 shows working multi-line message forms (bash and PowerShell) for the close scripts
- [ ] The boundary rule — trailer required on any commit that changes a file outside **any** `.projex/` folder; doc-only commits keep `projex(...)` subjects with no trailer — is stated once in `execute-projex.md § Commit Message Convention` and not contradicted by any workflow spec, including the close templates (doc-only executions carve out)
- [ ] `execute-projex.md`, `do-projex.md`, `close-projex.md`, `patch-projex.md`, `debug-projex.md` commit templates match the convention; every template that lands source shows both a typed subject (where applicable) and the trailer
- [ ] `do-projex.md` carries the six rules **inlined verbatim**, not by reference
- [ ] `patch-projex.md` and `revise-projex.md` Notes no longer claim `projex(patch):` / `projex:` are the code-commit prefixes
- [ ] `audit-projex.md` has a numbered `SOURCE HYGIENE PASS` step between Systematic Inspection and Quality Assessment, with all later steps renumbered and no duplicate or skipped numbers
- [ ] The audit pass specifies all four directions (rules 1–5 violations, rule 6 false negatives, rule 6 vacuity, unpromoted load-bearing rationale), diff-only default scope with a closed-execution fallback, opt-in retrofit mode, and symbol-not-`file:ln` location recording
- [ ] The audit pass's scope command excludes **nested** `.projex/` folders (`':(exclude,glob)**/.projex/**'`), and its commit direction samples base history for `Projex:` trailer survival
- [ ] The audit report template gains a `## Source Hygiene` section with the findings table and the commit-composition check
- [ ] `grep -rn "projex(patch):" *.md` and `grep -rn '"projex: step' *.md` return only occurrences consistent with the new convention
- [ ] No spec file still asserts a bare `projex:` / `projex(patch):` prefix as the convention for a commit that changes source

### Out of Scope

- Any change to `.sh` / `.ps1` scripts, and therefore to `tests/`. The convention rides existing pass-through (`stage-n-commit --trailer`) and existing message arguments
- `hygiene-lint` (proposal Option C) — deferred to a follow-up proposal
- Retrofitting existing comments or rewriting existing commit history in this or any repo
- `review-projex.md` — the pass stays audit-only (see Notes § Resolved Questions)
- The stale `Simulation` entry in `close-projex.md` § 6 step 3's born-closed table (see Notes § Follow-ups)
- `README.md` / `USAGE.md` / `AGENTS.md` — checked, they document no commit convention

---

## Context

### Current State

> Line anchors re-verified 2026-08-11 against the working tree (review action 1). Where a locator moved, the **text** anchor still resolves verbatim — only the numbers drifted.

- **`SKILL.md`** — 407 lines. Hygiene rules exist only for documents (§ Dehydrate, § De-slop, both under `## Authoring`). `## Git Integration` holds `### Git Operation Discipline` (line 352) and `### Worktree Mode (Optional)` (line 365). Nothing governs source comments; nothing defines a commit-message convention.
- **`execute-projex.md`** — 352 lines. § 3 EXECUTE STEPS SEQUENTIALLY was restructured by `45c43c1` (2026-08-08) from A/B/C into A/B/C/D/E; the step commit now lives in **§ 3.E COMMIT** (line 191), template `"projex: step N - [brief description]"`. § Commit Message Convention (lines 277–280) is three bullets, prefix-only. Same commit made do/verify delegation a **free per-step choice** (§ 3.B, § 3.D) — no marker gates it (see § Implementation Overview, Step markers).
- **`do-projex.md`** — 181 lines, sub-workflow. Commit templates `projex(do): obj {id} step {n}` (line 92) and `projex(do): obj {id} complete` (line 113). Pre-conditions declare context is entirely caller-supplied; nothing points at SKILL.md for authoring rules.
- **`close-projex.md`** — 647 lines. § 7 FINALIZE GIT BRANCH (line 417) holds the close options: Option A squash message `"projex: {plan-name} - [summary of changes]"` (lines 472, 477); Option B merge message `"projex: merge {plan-name}"` (lines 487, 492); Option C rebase takes no message (line 502); doc-close commit `"projex: close {plan-name} - add walkthrough"` (line 406) in § 6 FINALIZE DOCUMENTS. `03407c0` (2026-08-09) added one sentence *after* the Option A heading and `4749410` (2026-08-07) added a row to § 6's born-closed table — neither touches a message template this plan edits.
- **`patch-projex.md`** — code commit `projex(patch):` (lines 102, 239); doc commit `projex(patch): add patch doc` (lines 209, 242); closing Note (line 294) claims the `projex(patch):` prefix is what distinguishes patches in history.
- **`revise-projex.md`** — commits `projex(revise):` (lines 98, 111); closing Note (line 171) enumerates the old prefix vocabulary `projex:` / `projex(patch):`.
- **`debug-projex.md`** — 581 lines. Attempt commits `projex(debug): attempt N` (lines 283, 289) and repro commit (line 211) are all unwound by § 6.B `reset --soft {base-branch}` (line 347); the surviving in-branch commit is `fix({scope}): {one-line}` (line 349); the only commit reaching base is the Option A squash-close message (line 492). Anchors unchanged since authoring.
- **`audit-projex.md`** — 316 lines, 8 numbered workflow steps. `### 3. SYSTEMATIC INSPECTION` ends line 61; `### 4. QUALITY ASSESSMENT` starts line 63. Report template runs `## Documentation Audit` (165) → `## Gap Analysis` (173); § VALIDATION at 279. § Artifact Forensics already mentions "commit message quality" but defines no standard to check against. Anchors unchanged since authoring — as are those in `do-projex.md` (92, 113, 162), `patch-projex.md` (99–107, 209, 235–245, 271–282, 294), and `revise-projex.md` (98, 111, 171).
- **Scripts (verified, unchanged by this plan):** `stage-n-commit.ps1` splits any `--`-prefixed argument at the first space and forwards it to `git commit`, so `"--trailer Projex: {id}"` works verbatim. `projex-squash-close` / `projex-merge-close` take one positional message and pass it to `git commit -m` / `git merge -m` — a multi-line string carries a body. `projex-rebase-close` has no message parameter.

### Key Files

> Quick reference — detailed changes are in Implementation steps below.

| File | Role | Change Summary |
|------|------|----------------|
| `SKILL.md` | Framework core spec, loaded with every workflow | +`## Source Hygiene` (six rules) |
| `execute-projex.md` | Plan execution on ephemeral branch | Step-commit template gains trailer; § Commit Message Convention becomes the canonical composition block |
| `do-projex.md` | Sub-workflow, caller-supplied context only | Commit template gains trailer; six rules inlined verbatim |
| `close-projex.md` | Branch finalization + walkthrough | Option A/B message templates: typed subject + trailer body; doc-only carve-out; Option C note; walkthrough `**Rationale promoted:**` prompt |
| `patch-projex.md` | Quick-action, commits directly to base | Code-commit convention typed + trailer; stale Notes line replaced; checklist item |
| `revise-projex.md` | Document-only edits | Stale Notes line replaced (cross-reference only) |
| `debug-projex.md` | Issue-bound investigation in worktree | Fix commit + squash-close message gain trailer |
| `audit-projex.md` | Enforcement point | New workflow step 4 + renumbering; report template `## Source Hygiene` section; validation checklist item |

### Dependencies

- **Requires:** Nothing upstream. All eight files exist and are tracked at repo root.
- **Blocks:** A future `hygiene-lint` proposal (Option C) — its regex set derives from the rule wording landed here.

### Constraints

- Text edits only. Touching `stage-n-commit.*` or the close scripts pulls in `tests/run-all.{sh,ps1}` (188 assertions, both platforms) — explicitly out of scope.
- A background session may be concurrently editing `new-projex.{ps1,sh}`. Do not touch those files; worktree mode isolates this execution from that work.
- `SKILL.md` is loaded on every workflow invocation — new sections must be dense (SKILL.md § Dehydrate applies to the specs themselves).
- Rule 1 and the trailer are mutually load-bearing: neither step 1 half may land without the other in the same execution.

### Assumptions

- `stage-n-commit` forwards `"--trailer Projex: {id}"` correctly — **verified both variants**: `stage-n-commit.ps1` (lines 19–26) and `stage-n-commit.sh` (lines 24–35) both split a `--`-prefixed argument at the *first* space. The `.sh` re-confirmation this plan originally deferred was carried out by the sibling red team (§ What's Solid).
- The close scripts accept a multi-line message argument — **verified live** by the sibling red team (git 2.55): a `-m` of subject / blank line / `Projex: …` yields a parseable trailer through `projex-squash-close` (`git commit -m`) and `projex-merge-close.sh:200` (`git merge --no-ff -m`). Step 4's smoke test is retained as an environment check, not as an open question.
- `git commit --trailer` requires git ≥ 2.32; the framework states no minimum git version. Monitored, not gated — revisit if a target environment reports an unknown-option failure.
- `git interpret-trailers --parse` and `git log --grep` are the intended readers of the trailer; no repo tooling currently parses commit subjects, so changing them breaks nothing here.
- No spec file other than the eight listed carries a commit-message template. Verified by grep over `*.md` at repo root; re-run the grep in step 7's verification.

### Impact Analysis

- **Direct:** the eight spec files listed above.
- **Adjacent:** every future execution/patch/debug run in any repo using this framework — commit subjects change shape from the next run onward. Existing history is untouched (forward-only).
- **Downstream:** PR-gated repos. `close-projex.md` specifies **no PR path** (grep `pull request` / `gh_pr` / `PR ` → zero hits); `.github/gh_pr.ps1` is a standalone utility, not part of the close lifecycle. So in a PR-gated repo the commit that lands on the default branch is produced outside anything the framework specifies, and trailer survival depends on GitHub's `squash_merge_commit_message` repo setting: `COMMIT_MESSAGES` carries bodies, `PR_BODY` and `BLANK` discard them. That condition is stated in step 2b and sampled by the audit pass (step 7a) rather than assumed. Any consumer grepping for a uniform `projex:` prefix over history loses that uniformity for source commits; `git log --grep 'Projex: '` replaces it.

---

## Implementation

### Overview

Step 1 lands the rule half of the contract in `SKILL.md`; step 2 lands the commit-composition half in `execute-projex.md § Commit Message Convention` — everything downstream references or mirrors those two. Steps 3–6 propagate the commit convention into the remaining commit-producing specs, in dependency order (do → close → patch/revise → debug). Step 7 lands the enforcement point in audit-projex. Steps 3, 5, 6 are mechanical template edits; steps 1, 2, 4 and 7 are authoring.

**Step markers.** `Verify-Projex: Required` is the only step marker any workflow reads (`execute-projex.md` § 2 BUILD TASK LIST, line 117; `SKILL.md` § Sub-Workflows). Since `45c43c1` (2026-08-08) `execute-projex.md` chooses do/verify delegation **freely per step** (§ 3.B, § 3.D) — it is a mechanism change, not merely an unread trigger, so `Do-Projex: Encouraged` and `Verify-Projex: Encouraged` gate nothing and are advisory hints to the executor only. The two Medium-confidence steps (4, 7) therefore carry `Verify-Projex: Required`, the marker that does fire. Framework-level reconciliation of the `Encouraged` vocabulary is a follow-up (Notes § Follow-ups).

---

### Step 1: SKILL.md — § Source Hygiene

**Objective:** State the six rules once, canonically.
**Confidence:** High
**Depends on:** None

**Files:**
- `SKILL.md`

**Changes:**

Insert a new top-level section between the end of `## Auxiliary Artifact Commit Policy` (current line 211) and the `---` preceding `## Substrate` (current lines 213–215).

```markdown
// Before:
The commit commands shown in auxiliary workflow docs are **reference templates**, not automatic steps.

---

## Substrate

// After:
The commit commands shown in auxiliary workflow docs are **reference templates**, not automatic steps.

---

## Source Hygiene

**Subject.** *Source* = files a program or build consumes: code, config, schemas, scripts. *Comment* = a construct the language ignores at runtime. Prose files (`.md`, docs, specs) are shipped documentation — rule 1's promotion target — and are outside these rules unless a retrofit sweep names them. Bind every workflow that edits source (execute, do, patch, debug). Enforcement: `audit-projex.md` § Source Hygiene Pass.

1. **No projex references in sources** — no projex ID, filename, or section pointer in a comment. Projexs are authoring layer artifacts, and should be invisible in the product. **Promotion:** load-bearing rationale that exists only in a projex document belongs in a shipped doc (README, spec, ADR) — promotion is the only channel that survives archival compression. Referencing a *shipped* doc from a comment is fine; the ban is on workflow artifacts.
2. **Symbols, not line numbers** — name the function, const, or type; never `file:123` or bare `:123`. `file:ln` stays correct inside projex documents — they are point-in-time records.
3. **Present tense** — what the code does, not what it used to do. Live hazard: state the hazard, not the changelog.
4. **No plan shape in code** — no `// Step N:`, no `====` / `----` banners.
5. **Reassurance must warn** — "deliberate" / "by design" only with the rejected alternative and its consequence.
6. **Non-obvious decisions carry rationale** — a rejected alternative, surprising constraint, or don't-fix trap gets a self-contained comment. Naming none of the three is not compliance — a rationale comment that asserts without naming what it rejected is as much a violation as its absence.

**No density or length caps.** Long comment blocks are not a violation; thinning comments to reach zero findings is (rule 6).

---

## Substrate
```

**Rationale:** The rules are the contract every other edit in this plan mirrors, so they land first and land once. They are authoring rules, not git operations, so they sit with the other authoring/policy sections. The commit convention lands in `execute-projex.md` § Commit Message Convention (step 2), its historic home — SKILL.md carries no commit tables.

**Verification:**
```bash
grep -n "^## Source Hygiene" SKILL.md
```
Read the new section end-to-end: subject-definition lead present (source / comment / prose carve-out), six numbered rules present, rule 1 carries the promotion sentence, rule 2 carries the projex-document carve-out, rule 6 carries the vacuity clause, no-caps line present. Confirm `## Substrate` follows intact.

**If this fails:** `git checkout -- SKILL.md` in the worktree. No other step has landed yet, so nothing depends on it.

---

### Step 2: execute-projex.md — step-commit trailer + Commit Message Convention

**Objective:** Ephemeral-branch step commits carry the trailer; § Commit Message Convention becomes the canonical composition block (table, vocabulary, trailer form).
**Confidence:** High
**Depends on:** Step 1
**Do-Projex: Encouraged**

**Files:**
- `execute-projex.md`

**Changes:**

**2a.** § 3.E COMMIT commit template (current line 191 — was § 4.C item 5 before `45c43c1` restructured § 3 into A/B/C/D/E):

```bash
# Before:
{projex-scripts}/stage-n-commit.{sh|ps1} <repo-root> "projex: step N - [brief description]" path/to/changed-file1.ext .projex/{yymmddhhmm}-{plan-name}-log.md

# After:
{projex-scripts}/stage-n-commit.{sh|ps1} <repo-root> "projex: step N - [brief description]" "--trailer Projex: {yymmddhhmm}-{plan-name}" path/to/changed-file1.ext .projex/{yymmddhhmm}-{plan-name}-log.md
```

Append one sentence after the code block: `Investigative steps that commit only the log entry drop the trailer — it is required only on commits that change a file outside any .projex/ folder (§ Commit Message Convention).`

**2b.** § GIT BRANCH MANAGEMENT → § Commit Message Convention (current lines 277–280):

```markdown
// Before:
### Commit Message Convention
- Prefix with `projex:` for traceability
- Reference step number when applicable
- Keep messages concise but descriptive

// After:
### Commit Message Convention

Subjects carry the *type* of change; a `Projex:` trailer carries the link back to the document.

| Commit class | Subject | Trailer |
|---|---|---|
| Step commits on an ephemeral branch | `projex: step N - …` / `projex(do): obj {id} step {n} - …` | required |
| Squash-close message landing on base | `<type>(<scope>): <summary>` | required |
| Merge-close merge commit | `<type>(<scope>): <summary>` | required |
| Patch code commits (land directly) | `<type>(<scope>): <summary>` | required |
| Debug fix commit | `fix(<scope>): <summary>` | required |
| Doc-only commits (plan add, walkthrough, log, memo, nav, revise, archive, preplan, patch doc) | `projex(...)` family — unchanged | not required |

**Boundary rule** — the trailer is required on every commit that changes a file outside **any** `.projex/` folder (a repo may hold several — `docs/.projex/`, `src/.projex/`). Commits touching only projex documents keep their `projex(...)` subject and need no trailer. An execution whose entire diff stays inside `.projex/` is doc-only at close too: keep the `projex:` close subject, omit the trailer.

`<type>` = conventional-commit vocabulary: `feat` | `fix` | `docs` | `refactor` | `test` | `chore`. `<scope>` = module/area touched. Pick by what the diff does: new capability → `feat` | behaviour correction → `fix` | prose/docs only → `docs` | tests only → `test` | same behaviour, different shape → `refactor` | tooling/deps/housekeeping → `chore`. Genuinely torn between two → pick either and move on; an approximate type beats no type. That is a tie-breaker, not a licence to default every commit to one type.

**Trailer form** — `Projex: {yymmddhhmm}-{name}`: the projex document's filename minus its `-{type}.md` suffix. **Resolving one** — prefix-match `{yymmddhhmm}-*` across `.projex/`, `.projex/closed/`, `.projex/archived/`, and archive index entries; the stem is shared by the plan, its log, and any walkthrough of the same execution, so expect a small set, not one file.

**Attaching it** — `stage-n-commit` forwards any `--`-prefixed argument to `git commit`; pass the trailer as one quoted string (template above). The close scripts take a single message argument — the landing trailer rides the message body (forms in `close-projex.md` § 7). `projex-rebase-close` takes no message and needs nothing extra: the step commits already carry the trailer.

**Why a trailer** — delivery tooling rewrites subjects; bodies usually survive. Read back via `git log --grep 'Projex: '` or `git interpret-trailers --parse`.

**Survival condition** — trailers reach base through a GitHub squash-merge only when the repo's `squash_merge_commit_message` setting is *commit messages*; `PR_BODY` and `BLANK` discard every body in the PR, and with rule 1 in force that leaves no code→doc link at all. Set it, or prefer merge/rebase close. `audit-projex.md` § Source Hygiene Pass samples base history for trailer survival — a rate of zero is a Critical finding, not a footnote.

**Why every step commit** — `git blame` resolves to the commit that introduced a line, and merge/rebase closes land step commits on base verbatim.

Step commits keep the `projex: step N - …` subject and add the trailer whenever they touch a file outside any `.projex/` folder; doc-only commits (log entries, plan status) take no trailer; the landing subject is composed at close.
```

**2c.** § 7 item 8 commit (current line 240) is doc-only (plan + log) — leave unchanged, no trailer.

**Rationale:** Under merge-close and rebase-close, step commits land on base verbatim and are what `git blame` resolves to. § Commit Message Convention is the convention's historic home; it now holds the full composition block, keeping SKILL.md free of commit tables.

**Verification:**
```bash
grep -n "trailer Projex" execute-projex.md
grep -n -A45 "^### Commit Message Convention" execute-projex.md
grep -n "projex: complete {plan-name}" execute-projex.md
```
Expect: the 2a template with the trailer argument; the convention block with the six-row table, boundary rule (naming *any* `.projex/` folder and the doc-only close carve-out), `<type>` vocabulary with diff-keyed selection, trailer form with its resolution rule, and the survival condition; line 240's complete-commit untouched.

**If this fails:** `git checkout -- execute-projex.md`.

---

### Step 3: do-projex.md — trailer + six rules inlined

**Objective:** The highest-comment-volume path carries the rules in its own spec, since its context is entirely caller-supplied.
**Confidence:** High
**Depends on:** Steps 1, 2
**Do-Projex: Encouraged**

**Files:**
- `do-projex.md`

**Changes:**

**3a.** § 2.C sub-step commit template (current line 92):

```bash
# Before:
{projex-scripts}/stage-n-commit.{sh|ps1} <repo-root> "projex(do): obj {id} step {n} - [brief]" path/to/changed.ext .projex/{log-filename}

# After:
{projex-scripts}/stage-n-commit.{sh|ps1} <repo-root> "projex(do): obj {id} step {n} - [brief]" "--trailer Projex: {yymmddhhmm}-{plan-name}" path/to/changed.ext .projex/{log-filename}
```

Append after the existing `Investigative sub-steps commit the log entry alone.` line: `Log-only commits drop the trailer.` § 3 item 2's objective-complete commit (current line 113) is doc-only — unchanged.

**3b.** § 2.B EXECUTE (current lines 74–75) gains one bullet:

```markdown
// Before:
#### B. EXECUTE
- Carry out the sub-step (edit / run / gather)

// After:
#### B. EXECUTE
- Carry out the sub-step (edit / run / gather)
- Comments written into source obey § SOURCE HYGIENE below — a deliberate second copy of `SKILL.md § Source Hygiene`, kept here so the rules survive any context loss on the sub-subagent boundary
```

**3c.** New top-level section immediately before `## GIT DISCIPLINE` (current line 162), carrying rules 1–6 **verbatim** from `SKILL.md § Source Hygiene` (subject-definition lead, numbered list, no-caps line), under this header and lead:

```markdown
## SOURCE HYGIENE

Deliberate copy of `SKILL.md § Source Hygiene` — do-projex is the highest-comment-volume path in the framework and this spec is what its agent is guaranteed to have. Redundant by design: edit either copy and update the other.

[subject-definition lead + rules 1–6 + the no-caps closing line, verbatim from SKILL.md § Source Hygiene]
```

**Rationale:** Honest justification, corrected. The original one — "do-projex context is entirely caller-supplied, so SKILL.md may be absent" — is **false**: `do-projex.md` § 1 ANCHOR item 1 (line 59) mandates "Read `SKILL.md` and this file (`do-projex.md`)" as the sub-workflow's first action, and SKILL.md § Sub-Workflows rule 2 governs *task arguments*, not spec loading. The copy is kept anyway as belt-and-braces redundancy on the framework's highest-volume comment-writing path, at the known cost of a manual sync obligation (Risks). `verify-projex.md` stays reference-only — it is read-only and writes no comments.

**Verification:**
```bash
grep -n "trailer Projex" do-projex.md
grep -n "^## SOURCE HYGIENE" do-projex.md
grep -c "^[1-6]\. \*\*" do-projex.md
```
Diff the inlined rules against SKILL.md's to confirm they are verbatim, not paraphrased — scratch files inside the worktree, repo-relative, removed before close (worktree Cleanup contract):
```bash
sed -n '/^## SOURCE HYGIENE/,/^## GIT DISCIPLINE/p' do-projex.md > .sh-do-rules.tmp
sed -n '/^## Source Hygiene/,/^## Substrate/p' SKILL.md > .sh-skill-rules.tmp
diff .sh-do-rules.tmp .sh-skill-rules.tmp   # expect only header/lead-paragraph differences
rm .sh-do-rules.tmp .sh-skill-rules.tmp
```

**If this fails:** `git checkout -- do-projex.md`. Steps 1–2 remain valid independently.

---

### Step 4: close-projex.md — typed landing subjects + trailer body

**Objective:** The message that lands on base carries a conventional type and the trailer.
**Confidence:** Medium — the multi-line message argument is the one mechanic in this plan not already exercised by an existing template.
**Depends on:** Steps 1, 2
**Verify-Projex: Required**

**Files:**
- `close-projex.md`

**Changes:**

**4a.** Insert a lead paragraph immediately before `#### Option A: Squash Merge (Default/Recommended)` (current line 467):

```markdown
**Composing the landing message.** The message passed to a close script is what history shows on base, so it takes a conventional-type subject, not the `projex:` prefix — `<type>(<scope>): <summary>` with `<type>` from `feat` | `fix` | `docs` | `refactor` | `test` | `chore`. It also carries the `Projex:` trailer in its body: subject, blank line, `Projex: {yymmddhhmm}-{plan-name}`. **Doc-only executions are exempt** — if the execution changed nothing outside a `.projex/` folder, keep the `projex: {plan-name} - …` subject and omit the trailer (boundary rule). Full convention: `execute-projex.md` § Commit Message Convention.
```

**4b.** Option A, both modes (current lines 471–478):

```bash
# Before (checkout mode):
{projex-scripts}/projex-squash-close.{sh|ps1} <repo-root> {base-branch} projex/{yymmddhhmm}-{plan-name} "projex: {plan-name} - [summary of changes]"

# After (checkout mode):
{projex-scripts}/projex-squash-close.{sh|ps1} <repo-root> {base-branch} projex/{yymmddhhmm}-{plan-name} "<type>(<scope>): [summary of changes]

Projex: {yymmddhhmm}-{plan-name}"
```

Worktree-mode block: identical message change, `--worktree` still last. PowerShell form (either mode):

```powershell
$msg = @"
<type>(<scope>): [summary of changes]

Projex: {yymmddhhmm}-{plan-name}
"@
{projex-scripts}/projex-squash-close.ps1 <repo-root> {base-branch} projex/{yymmddhhmm}-{plan-name} $msg
```

**4c.** Option B, both modes (current lines 485–493): same transformation, `"projex: merge {plan-name}"` → `"<type>(<scope>): [summary of changes]\n\nProjex: {yymmddhhmm}-{plan-name}"` in the same literal multi-line form.

**4d.** Option C note (current line 512) gains one sentence: `No trailer argument is needed either — the step commits being replayed already carry theirs.`

**4e.** § 6 item 5 doc-close commit (current line 406) is doc-only — subject stays `"projex: close {plan-name} - add walkthrough"`, no trailer.

**4f.** § 5 DRAFT THE WALKTHROUGH (current line 126), `## Key Insights` section of the template (current line 276) gains one prompt line:

```markdown
**Rationale promoted:** [shipped doc(s) that received load-bearing rationale from this execution, per `SKILL.md § Source Hygiene` rule 1 — or "none needed"]
```

This is rule 1's promotion touchpoint: close is the one moment where the execution's rationale and the shipped-doc tree are both in view, and naming the target in the walkthrough makes the obligation auditable (step 7a direction 3). Without it "promotion" is a rule nothing ever triggers.

**Rationale:** Squash-close produces the single commit that represents the whole execution on base; merge-close's merge commit is the natural landing subject. Both scripts pass their message straight to `-m`, so a body is available without a script change. The doc-close commit touches only `.projex/`, so the boundary rule exempts it — trailering it would add noise on a commit whose blame target is the document itself.

**Verification:**
```bash
grep -n "projex: merge" close-projex.md                         # expect no matches
grep -n "projex: {plan-name}" close-projex.md                   # expect 1 — the 4a doc-only carve-out sentence only
grep -c "Projex: {yymmddhhmm}-{plan-name}" close-projex.md      # expect 5 (lead para + A×2 + B×2)
grep -n "projex: close {plan-name}" close-projex.md             # expect 1, unchanged
grep -n "Rationale promoted" close-projex.md                    # expect 1 (4f)
grep -n "Doc-only executions are exempt" close-projex.md        # expect 1 (4a)
```
Then prove the multi-line argument actually produces a body, using a throwaway commit inside the worktree (not a close):
```bash
git -C <worktree> commit --allow-empty -m "test(scope): trailer smoke test

Projex: 2608052327-source-hygiene-guardrails"
git -C <worktree> log -1 --format='%s|%(trailers:key=Projex,valueonly)'
git -C <worktree> reset --soft HEAD~1
```
Expect the subject and the trailer value on separate fields. If `%(trailers)` returns empty, the documented form is wrong and step 4 must be reworked before proceeding.

**If this fails:** `git checkout -- close-projex.md`. If the smoke test disproves the multi-line form in *this* environment, stop the whole execution and escalate — steps 2b and 6b document the same mechanic and would need reworking together. (The form itself is already proven: sibling red team verified it live on git 2.55.)

---

### Step 5: patch-projex.md + revise-projex.md — typed patch commits + stale cross-references

**Objective:** Patch code commits compose; both specs stop advertising the superseded prefix vocabulary.
**Confidence:** High
**Depends on:** Step 1
**Do-Projex: Encouraged**

**Files:**
- `patch-projex.md`
- `revise-projex.md`

**Changes:**

**5a.** `patch-projex.md` § 2 commit convention (current lines 99–107):

```markdown
// Before:
**Commit convention:**

{projex-scripts}/stage-n-commit.{sh|ps1} <repo-root> "projex(patch): [concise description of change]" path/to/changed-file1.ext path/to/changed-file2.ext

- Prefix: `projex(patch):` for traceability
- Single commit for the patch (group related changes)
- Distinct logical parts → multiple commits acceptable

// After:
**Commit convention:**

{projex-scripts}/stage-n-commit.{sh|ps1} <repo-root> "<type>(<scope>): [concise description of change]" "--trailer Projex: {yymmddhhmm}-{patch-name}" path/to/changed-file1.ext path/to/changed-file2.ext

- Subject: conventional type (`feat` | `fix` | `docs` | `refactor` | `test` | `chore`) — a patch lands directly on the current branch, so this subject is what history shows
- Trailer: `Projex: {yymmddhhmm}-{patch-name}` — required; it is the only link from the changed code back to the patch document
- `<type>`: `feat` | `fix` | `docs` | `refactor` | `test` | `chore` — full convention: `execute-projex.md` § Commit Message Convention
- Single commit for the patch (group related changes)
- Distinct logical parts → multiple commits acceptable
```

**5b.** `patch-projex.md` § GIT INTEGRATION → Commit Sequence (current lines 237–245): step 1 takes the same typed subject + trailer as 5a; step 2 (patch doc + related docs) is doc-only and keeps `"projex(patch): add patch doc - {patch-name}"` with no trailer.

**5c.** `patch-projex.md` § 4 item 6 doc commit (current line 209) — unchanged, doc-only.

**5d.** `patch-projex.md` QUALITY CHECKLIST (current lines 275–282) gains one item after `- [ ] Change implemented and committed`:

```markdown
- [ ] Code commit carries a conventional-type subject and a `Projex: {yymmddhhmm}-{patch-name}` trailer
```

**5e.** `patch-projex.md` closing Note (current line 294):

```markdown
// Before:
- The `projex(patch):` commit prefix distinguishes patches from full executions in git history

// After:
- A patch's *code* commit uses a conventional-type subject like any landing commit; its `Projex: {yymmddhhmm}-{patch-name}` trailer is what identifies it in history (`git log --grep 'Projex: '`). The patch *document* commit keeps the `projex(patch):` prefix
```

**5f.** `revise-projex.md` closing Note (current line 171):

```markdown
// Before:
- The `projex(revise):` commit prefix distinguishes document revisions from full additions (`projex:`) and code patches (`projex(patch):`) in git history

// After:
- The `projex(revise):` prefix marks document revisions in git history. It belongs to the `projex(...)` doc-op family alongside `projex:` (plan and log additions) and `projex(patch): add patch doc`. Commits that change source instead carry a conventional-type subject plus a `Projex:` trailer — `execute-projex.md` § Commit Message Convention
```

`revise-projex.md` § 3 COMMIT, § 4 item 3, and the checklist item `Commit(s) made with projex(revise): prefix` are unchanged: revise only edits projex documents, so the boundary rule exempts it entirely.

**Rationale:** Patches land directly on base, so their subject is permanent history — the class the composition change exists for. Both Notes lines assert the old vocabulary as fact and would read as contradictions of SKILL.md the moment step 1 lands.

**Verification:**
```bash
grep -n "projex(patch):" patch-projex.md
grep -n "trailer Projex" patch-projex.md
grep -n "projex(patch)" revise-projex.md
```
Expect in `patch-projex.md`: `projex(patch):` survives only on document commits (§ 4 item 6, § Commit Sequence step 2, § 5e's second sentence) and never on a code commit; two trailer occurrences (5a, 5b). In `revise-projex.md`: `projex(patch)` appears only inside the rewritten Note.

**If this fails:** `git checkout -- patch-projex.md revise-projex.md`.

---

### Step 6: debug-projex.md — trailer on the fix and landing commits

**Objective:** The debug commits that survive to base carry the trailer.
**Confidence:** High
**Depends on:** Steps 1, 4
**Do-Projex: Encouraged**

**Files:**
- `debug-projex.md`

**Changes:**

**6a.** § 6.B fix commit (current line 349):

```bash
# Before:
{projex-scripts}/stage-n-commit.{sh|ps1} <worktree-root> "fix({scope}): {one-line description}" path/to/fixed-file.ext [more files...]

# After:
{projex-scripts}/stage-n-commit.{sh|ps1} <worktree-root> "fix({scope}): {one-line description}" "--trailer Projex: {yymmddhhmm}-{debug-name}" path/to/fixed-file.ext [more files...]
```

**6b.** § 8 Option A squash-close message (current line 492):

```bash
# Before:
{projex-scripts}/projex-squash-close.{sh|ps1} <repo-root> {base-branch} projex/debug/{yymmddhhmm}-{debug-name} "fix({scope}): {one-line} - debug-projex {debug-name}" --worktree

# After:
{projex-scripts}/projex-squash-close.{sh|ps1} <repo-root> {base-branch} projex/debug/{yymmddhhmm}-{debug-name} "fix({scope}): {one-line}

Projex: {yymmddhhmm}-{debug-name}" --worktree
```

The ` - debug-projex {debug-name}` subject suffix is dropped: the trailer now carries that identity, and the subject stays a clean conventional-commit line.

**6c.** § 3.C repro commit (line 211), § 4.E attempt commits (lines 283, 289), and § 8 Option B's exhausted doc commit (line 513) are **unchanged**. The first three are unwound by § 6.B's `reset --soft {base-branch}` and never reach base; the fourth is doc-only.

**Rationale:** Debug offers only squash-close or abandon, so exactly one commit reaches base and it is the one that must be tagged. The in-branch `fix()` commit is trailered too, so a cherry-pick or a hand-finished close still carries the link.

**Verification:**
```bash
grep -n "trailer Projex\|Projex: {yymmddhhmm}-{debug-name}" debug-projex.md   # expect 2
grep -n "debug-projex {debug-name}" debug-projex.md                            # expect 0
grep -n "projex(debug):" debug-projex.md                                       # expect 4, unchanged
```

**If this fails:** `git checkout -- debug-projex.md`.

---

### Step 7: audit-projex.md — Source Hygiene Pass

**Objective:** Land the single enforcement point: a workflow step, a report section, and a validation item.
**Confidence:** Medium — inserting a numbered step cascades a renumber through five later headings.
**Depends on:** Steps 1–6 (the pass checks what they define)
**Verify-Projex: Required**

**Files:**
- `audit-projex.md`

**Changes:**

**7a.** Insert a new workflow step between `### 3. SYSTEMATIC INSPECTION` (ends current line 61) and `### 4. QUALITY ASSESSMENT` (current line 63):

````markdown
### 4. SOURCE HYGIENE PASS

Sweep the audited work against SKILL.md § Source Hygiene and `execute-projex.md` § Commit Message Convention. Not a general comment critique — only these rules. Subject is *source* as SKILL.md defines it: files a program or build consumes. Prose files carry no comments — skip them unless retrofit mode names them.

**Scope: the audited diff.** Comments the work *added or modified*, not whole files. The exclusion must be glob-magic — a plain `:(exclude).projex/` anchors at the repo root and hands nested `docs/.projex/`, `src/.projex/` documents to the pass as source.

```bash
git -C <repo-root> diff {base}..{head} -- . ':(exclude,glob)**/.projex/**'
git -C <repo-root> log {base}..{head} --format='%h %s%n  trailer: %(trailers:key=Projex,valueonly)'
```

**No range available?** After a squash close the ephemeral branch is gone and there is no `{base}..{head}`. The walkthrough names the landing commit — use `git show <squash-sha> -- . ':(exclude,glob)**/.projex/**'`. Never fall back to a repo-wide sweep to recover a range.

**Retrofit mode — opt-in.** On explicit user request the sweep extends to whole files or the whole repo. Never the default — a repo-wide sweep buries the findings the audit was called for.

**Four directions, all produce findings:**

1. **Rules 1–5 violations** — a comment citing a projex ID / filename / section, a hardcoded `file:ln` or bare `:123`, a changelog narration, plan structure (`// Step N:`, `====` banner runs), or reassurance with no rejected alternative attached.
2. **Rule 6 false negatives** — a non-obvious change in the diff (rejected alternative, surprising constraint, don't-fix trap) with **no** rationale comment. Without this direction the pass is gamed by deleting comments.
3. **Rule 6 vacuity** — a rationale comment that names no rejected alternative, constraint, or trap. Same finding as its absence; without it the pass is gamed by padding every site with generic prose.
4. **Unpromoted rationale** — load-bearing rationale that exists only in the projex document. The walkthrough's `**Rationale promoted:**` line is the check: named target, or a stated "none needed" that the diff supports.

**Commit check:** every landed commit that changes a file outside any `.projex/` folder carries a conventional-type subject and a `Projex:` trailer, and the subject's type matches what the diff does (not merely that a type is present). Doc-only commits are exempt.

**Trailer survival sample** — independent of the audited work, sample recent base history and report the rate:

```bash
git -C <repo-root> log {base-branch} -n 30 --format='%h %(trailers:key=Projex,valueonly)'
```

A rate of zero where the convention is supposed to be in force is a **Critical** finding — it means the sole code→doc channel is dead (typically a GitHub `squash_merge_commit_message` of `PR_BODY`/`BLANK`), and rule 1 has already removed the comment citations that used to carry it.

**Remediability** — a landed commit's subject or trailer cannot be fixed without rewriting published history, which this framework forbids without explicit human instruction. Grade commit-composition findings **informational / fix-forward**; never file them as actionable defects. Comment findings (directions 1–4) are ordinary actionable findings.

**Record locations by symbol, never `file:ln`** — the pass practises what it checks.

Findings land in the report's `## Source Hygiene` section and are graded into the standard `## Findings` severities.
````

**7b.** Renumber the following headings, bottom-up to avoid collisions: `### 8. FINALIZE` → `### 9. FINALIZE`; `### 7. VALIDATION` → `### 8. VALIDATION`; `### 6. DRAFT AUDIT REPORT` → `### 7. DRAFT AUDIT REPORT`; `### 5. OPEN EXPLORATION` → `### 6. OPEN EXPLORATION`; `### 4. QUALITY ASSESSMENT` → `### 5. QUALITY ASSESSMENT`.

**7c.** Report template: insert a new section between `## Documentation Audit` (ends current line 169) and the `---` preceding `## Gap Analysis`:

```markdown
## Source Hygiene

**Scope:** Diff only (`{base}..{head}` | `git show <squash-sha>`) | Retrofit (whole file) | Retrofit (whole repo)

| Rule | Location (symbol) | Quote | Severity |
|------|-------------------|-------|----------|
| [1–6] | `module` → `functionName` | "[verbatim comment fragment]" | Critical/High/Medium/Low |

**Rule 6 gaps** (non-obvious change, no rationale comment):
- `symbol` — [what is non-obvious] — [why a reader needs the rationale]

**Rule 6 vacuity** (rationale comment naming no alternative, constraint, or trap):
- `symbol` — "[verbatim fragment]" — [what it fails to name]

**Rationale promotion:** [shipped doc named in the walkthrough, or "none needed — supported by diff", or "unpromoted: what is missing"]

**Commit composition** (informational — fix forward, never rewrite history): [N] landed commits checked — typed subject [N/N] | type matches diff [N/N] | `Projex:` trailer [N/N]
**Violations:** [SHA — what is missing, or "None"]

**Trailer survival on `{base-branch}`:** [N/30] of recent commits carry a `Projex:` trailer — [OK | **Critical: channel dead**, cause if known]
```

**7d.** § VALIDATION checks (current lines 281–286) gain one item:

```markdown
- [ ] Source hygiene pass run against the audited diff (or the declared retrofit scope)
```

**Rationale:** Placement after Systematic Inspection and before Quality Assessment matches the proposal and the natural order — the pass reads the diff, which inspection has just loaded, and its output feeds the quality judgment. Enforcement lives here rather than in execute/patch because the executing agent reviews its own comments with author's blindness, and mid-context checklist items decay.

**Verification:**
```bash
grep -n "^### [0-9]\." audit-projex.md
```
Expect exactly nine steps, numbered 1–9, in order, with `4. SOURCE HYGIENE PASS` between Systematic Inspection and Quality Assessment. Then:
```bash
grep -n "^## Source Hygiene" audit-projex.md            # expect 1 (report template)
grep -n "Source hygiene pass run" audit-projex.md       # expect 1 (validation)
grep -n "Retrofit\|retrofit" audit-projex.md            # expect 4 (step: mode + no-fallback line; template scope line)
grep -n "exclude,glob" audit-projex.md                  # expect 2 (diff command + squash-sha fallback)
grep -n ":(exclude)\.projex/" audit-projex.md           # expect 0 — no root-anchored pathspec
```
Read § 4 in full: all four directions present, diff-only default explicit with the squash-sha fallback, retrofit explicitly opt-in, commit findings marked informational/fix-forward, trailer-survival sample present, symbol-not-`file:ln` instruction present.

**If this fails:** `git checkout -- audit-projex.md`. Steps 1–6 stand alone — the convention is stated and used; only enforcement is missing.

---

## Verification Plan

> Per-step verification confirms each edit in isolation. This section confirms the eight files agree with each other.

### Automated Checks

- [ ] `grep -rn "projex(patch):" *.md` — every hit is a document commit or the rewritten Notes line; none is a code commit
- [ ] `grep -rn "simulate-projex" *.md` — no hits
- [ ] `grep -rln "Projex: {yymmddhhmm}" *.md` — hits in exactly: `SKILL.md`, `execute-projex.md`, `do-projex.md`, `close-projex.md`, `patch-projex.md`, `debug-projex.md`
- [ ] `grep -rn "prefix with \`projex:\`\|Prefix: \`projex(patch):\`" *.md -i` — no surviving assertion that a bare prefix is the code-commit convention
- [ ] `grep -n "^### [0-9]\." audit-projex.md` — contiguous 1–9
- [ ] `git -C <worktree> diff --stat {base}..HEAD -- . ':(exclude,glob)**/.projex/**'` — exactly 8 files changed, all at repo root, all `.md`. **The unscoped form cannot pass**: execute-projex commits `-log.md` with every step and the plan file at completion, so the raw `{base}..HEAD` diff necessarily shows 10 files
- [ ] `git -C <worktree> diff --name-only {base}..HEAD -- '.projex/'` — exactly the two expected documents: `{yymmddhhmm}-source-hygiene-guardrails-plan.md` and `{yymmddhhmm}-source-hygiene-guardrails-log.md`
- [ ] No `.sh`, `.ps1`, or `tests/` file appears in the diff

### Manual Verification

- [ ] Read `SKILL.md § Source Hygiene` and `do-projex.md § SOURCE HYGIENE` side by side — rules 1–6 verbatim identical
- [ ] Every commit template across the eight files is classifiable by the boundary rule (source-touching → trailer; doc-only → no trailer) with no ambiguous case — including the doc-only *execution* case at close (step 4a carve-out)
- [ ] The multi-line message form in `close-projex.md`, `debug-projex.md`, and `execute-projex.md § Commit Message Convention` is identical in shape (subject, blank line, `Projex: …`)
- [ ] Trailer smoke test from step 4 passed — `%(trailers:key=Projex)` resolves on a commit made with the documented form
- [ ] The new SKILL.md sections read as dense spec prose, not narration (SKILL.md § Dehydrate, § De-slop)
- [ ] No spec instructs an agent to write a projex reference into a source comment

### Acceptance Criteria Validation

| Criterion | How to Verify | Expected Result |
|-----------|---------------|-----------------|
| Six rules stated canonically | `grep -n "^## Source Hygiene" SKILL.md`, read the section | Six numbered rules, rule 1's promotion sentence, no-caps line |
| Commit composition defined once | `grep -n -A45 "^### Commit Message Convention" execute-projex.md`, read | Table (6 rows), `<type>` vocabulary + diff-keyed selection, trailer form + resolution rule, boundary rule (any `.projex/`, doc-only close carve-out), survival condition |
| Convention propagated | Automated check 3 | Trailer present in all six commit-producing specs |
| Rules inlined in do-projex | Step 3 diff of the two sections | Only header/lead-paragraph differences |
| Stale cross-references removed | Automated checks 1 and 4 | No surviving contradiction of SKILL.md |
| Audit pass exists and is numbered | `grep -n "^### [0-9]\." audit-projex.md` | 1–9 contiguous, pass at 4 |
| Pass is four-directional, correctly scoped, opt-in for retrofit | Read audit-projex § 4; `grep -n "exclude,glob" audit-projex.md` | Rules 1–5 + rule 6 false-negative + rule 6 vacuity + promotion directions; glob-magic exclusion; diff-only default with squash-sha fallback; retrofit on request |
| Trailer channel is observable, not assumed | Read audit-projex § 4 commit direction + step 2b survival condition | Survival sample command present; zero-rate = Critical; GitHub squash-setting caveat stated |
| Report template extended | `grep -n "^## Source Hygiene" audit-projex.md` | One section with findings table, rule 6 gaps, rule 6 vacuity, promotion line, commit-composition line (informational), trailer-survival line |
| No script/test surface touched | `git diff --stat {base}..HEAD -- . ':(exclude,glob)**/.projex/**'` | 8 `.md` files, repo root only |

---

## Rollback Plan

Per-step rollback is `git checkout -- <file>` inside the worktree; every step touches one file (step 5 touches two), and steps 2–7 are independent of each other given step 1.

If the whole implementation must be abandoned:

1. Confirm nothing outside the worktree is affected — the base working directory was never checked out.
2. `{projex-scripts}/projex-abandon.ps1 <repo-root> main projex/2608052327-source-hygiene-guardrails --worktree`
3. The plan document remains on `main` for a later attempt; set its status back to `Ready` if it was moved to `In Progress`.

---

## Revision Log

- **2026-08-11:** Anchor refresh + red team reconciliation. Triggers: (a) `2608111922-source-hygiene-guardrails-plan-review.md` — Verdict Revise, 5 Actions; (b) `2608052346-source-hygiene-guardrails-plan-redteam.md` — Verdict Fix Issues, 5 Must-Fix + 2 No-Go, none previously applied. Changes: re-verified every `current line N` citation against the working tree and corrected the drifted ones (`SKILL.md` 206→211, 208–210→213–215, 391→407 lines; `execute-projex.md` § 4.C item 5 line 199 → § 3.E COMMIT line 191, § Commit Message Convention 287–290→277–280, 250→240; `close-projex.md` 466→467, 470–477→471–478, 484–492→485–493, 511→512, 405→406; `do-projex.md` / `patch-projex.md` / `revise-projex.md` / `debug-projex.md` / `audit-projex.md` re-verified unchanged). Restated the `Do-Projex`/`Verify-Projex` marker problem as a mechanism change (`45c43c1`, 2026-08-08, made delegation a free per-step choice) rather than an unread trigger, and promoted steps 4 and 7 to `Verify-Projex: Required`. Applied all 5 Must-Fix and cleared both No-Go conditions; dispositioned every Should-Fix and Monitor item (Notes § Red Team Dispositions). Fixed internal inconsistencies the review surfaced indirectly: Success Criterion 1 demanded a promotion clause and a no-caps line that step 1's rule text did not contain; Success Criterion 3 located the boundary rule in `SKILL.md` while § Deviations puts commit composition in `execute-projex.md`; steps 4 and Deviations referenced a "step 1b" that no longer exists (→ 2b/6b); step 3's verification used absolute `/tmp` paths, forbidden by SKILL.md § NOTES. Status held at `Ready`.

---

## Notes

### Split Decision

**No split — size heuristic tripped, steps tightly coupled.**

Required-split triggers: none. All 8 files sit at the repo root under a single `.projex/` scope, one repo, and the corpus has no upstream/downstream layering — the framework spec and the workflow specs are the same layer of the same artifact.

Size heuristic tripped on both arms (~800 lines post-revision, 7 steps). Proceeding anyway:

- Rule 1's citation ban and the `Projex:` trailer are mutually load-bearing — the proposal states they ship together or not at all. Splitting them across plans lands a traceability gap in whichever executes first.
- Steps 2–7 all mirror wording that step 1 defines. A child plan would have to restate SKILL.md text that has not landed yet, or depend on a sibling for its literal content.
- Length comes from verbatim before/after blocks, not scope breadth: 6 of 7 steps are single-file template edits verifiable by grep.

### Deviations from the Proposal

- **File count: 8, not ~9.** `simulate-projex.md` does not exist — commit `0e9248c` ("projex: replace simulation with preplanning spikes") replaced it with `preplan-projex.md`. The proposal's "simulate-projex.md — no change" line is void, and the same reasoning applies to `preplan-projex.md`: its only commit is doc-only (`projex(preplan): capture {preplan-name}`), so it needs no change.
- **Commit composition is canonical in `execute-projex.md § Commit Message Convention`, not SKILL.md.** The proposal names no home. The convention's historic home is execute-projex, and the human directed that SKILL.md carry no commit-convention section; other specs embed their literal templates and reference execute-projex for the table and vocabulary.
- **§ Source Hygiene placed with the authoring/policy sections, not inside `## Git Integration`.** The proposal said "near Git Operation Discipline". Git Operation Discipline is a `###` under `## Git Integration`; a `##`-level Source Hygiene there would swallow `### Worktree Mode` and `### Notes`.
- **Close-script trailer mechanics documented explicitly.** The proposal's "no script changes needed" holds, but only `stage-n-commit` has `--trailer` pass-through. `projex-squash-close` / `projex-merge-close` take one positional message, so the trailer must ride a multi-line message body; `projex-rebase-close` takes no message at all. Step 2b documents all three shapes and step 4 smoke-tests the multi-line form.
- **Rule 1's promotion clause gets a touchpoint.** The proposal states promotion as "mandatory, not advisory" but names no mechanism. A rule with no trigger is a wish, so this plan drops the "mandatory" rhetoric and instead gives promotion a home: a `**Rationale promoted:**` line in the walkthrough template (step 4f) and a fourth audit direction that reads it (step 7a).
- **Debug attempt and repro commits left untrailered.** The proposal's "trailer on every step commit" reasoning is about commits that land on base. In debug, § 6.B `reset --soft {base-branch}` unwinds every attempt and repro commit before close, and debug offers only squash-close or abandon — so exactly one commit reaches base. Trailering commits that are destroyed by design adds template noise for no traceability.

### Resolved Questions

- **Proposal open question — extend the pass to `review-projex.md`?** Resolved: no, audit-only. Review's subject is projex documents, not source; a source-comment sweep there has no diff to read and would duplicate audit's role. Recorded so this plan carries no open questions into execution.

### Red Team Dispositions

> Source: `2608052346-source-hygiene-guardrails-plan-redteam.md` — Verdict Fix Issues, Readiness Needs Work, 12 findings. Dispositioned 2026-08-11 during `/revise-projex`. Every Must-Fix and No-Go item is resolved in the plan text; Should-Fix items are individually accepted or deferred with reason.

**Must Fix (Before Proceeding) — 5/5 applied**

| # | Finding | Disposition | Where |
|---|---------|-------------|-------|
| 1 | Pathspec `:(exclude).projex/` is root-anchored; nested `docs/.projex/` swept as source | **Accept** — `':(exclude,glob)**/.projex/**'`; boundary rule restated as "outside **any** `.projex/` folder" | Steps 2b, 7a; Verification Plan; Success Criteria 3 |
| 3 | Terminal diff-size check cannot pass — a correct execution shows 10 files, not 8 | **Accept** — check scoped to exclude `.projex/`; plan+log asserted separately | Verification Plan § Automated Checks |
| 7 | Trailer-survival stated unconditionally; GitHub squash setting can strip every body | **Accept** — survival condition stated in the convention block; audit samples base for trailer rate, zero = Critical | Steps 2b, 7a; Impact Analysis |
| — | Doc-only executions contradict the close template (edge case, tied to success criterion 3) | **Accept** — carve-out clause on the step-4 lead paragraph and in the boundary rule | Steps 2b, 4a |
| 4 | `Encouraged` markers are inert | **Accept** — steps 4 and 7 promoted to `Verify-Projex: Required`; marker status stated once in § Overview; framework-level reconciliation recorded as a follow-up | § Overview; Steps 4, 7; § Follow-ups |

**No-Go If — both cleared**

- *Rule 1 lands without a stated, checkable trailer-survival condition* → cleared by Must-Fix 7: the condition is stated in `execute-projex.md § Commit Message Convention` and checked by the audit pass's survival sample.
- *Audit pass lands with the root-anchored pathspec* → cleared by Must-Fix 1.

**Should Fix (Before Production)**

| Finding | Disposition |
|---------|-------------|
| 8 — promotion clause has no owner/trigger/check | **Accept.** Given a home (step 4f walkthrough prompt) and a check (step 7a direction 4). "Mandatory, not advisory" rhetoric dropped in favour of an actual touchpoint |
| 5 — do-projex inlining rests on a false premise | **Accept (re-justify, not drop).** The premise *is* false — `do-projex.md:59` mandates reading SKILL.md. Step 3's rationale now says so plainly and keeps the copy as declared belt-and-braces redundancy on the highest-comment-volume path. The `/tmp` verification (absolute external path, forbidden by SKILL.md § NOTES) replaced with repo-relative scratch files removed before close |
| 11 — rule 6 gameable by padding | **Accept.** Vacuity clause added to rule 6's text (step 1) and as direction 3 of the pass (step 7a), with a report-template row |
| 6 — `<type>` correctness unenforced and explicitly excused | **Accept.** Diff-keyed selection guidance added to the convention block; "wrong type beats no type" narrowed to a tie-breaker; the audit commit check now reads type-vs-diff, not type-presence |
| 2 / edge case — post-close audits have no diff range | **Accept.** `git show <squash-sha>` fallback specified, with an explicit bar on falling back to a repo-wide sweep |
| 10 — "source" undefined for prose corpora | **Accept.** Subject-definition sentence added as the § Source Hygiene lead (step 1); the pass repeats it |
| 2 — commit-composition findings are unremediable | **Accept (partial).** Findings graded informational / fix-forward with history rewriting explicitly out; a *blocking* pre-close variant in `close-projex.md` is **deferred** — it is a new gate, not a template edit, and belongs with the deferred `hygiene-lint` work |

**Monitor**

- Finding 9 — trailer value is a stem, not a filename. Kept as a stem (subjects and trailers stay short) but the resolution rule is now stated in the convention block, closing the redteam's "silence is the only unacceptable option". Revisit at the first archive run under the convention.
- `git commit --trailer` needs git ≥ 2.32; no framework minimum stated. Recorded under Assumptions.
- Two conventions with no boundary marker in history. Revisit when a repo first needs to date the switch.

**Rejected / not carried**

- Finding 12's cascade is not a separate item — it is the conjunction of 6, 7, 8, 11, all accepted above. Its recommended structural fix (make trailer survival an observable) is the accepted Must-Fix 7 remedy.
- Redteam § Roles Not Attacked (hygiene-lint author, orchestrator, test-suite owner) raises no change to this plan's text; the orchestrator question folds into the `Encouraged`/`Required` follow-up.

### Follow-ups (out of scope)

- `close-projex.md` § 6 step 3's born-closed table still lists `Simulation` alongside Patch/Scan/Debug/Guide/Archive — stale since `0e9248c`, should read `Preplan`. A one-line `/revise-projex` fix, unrelated to this plan's subject.
- **`Encouraged` vs `Required` step markers.** `plan-projex.md` writes `Do-Projex: Encouraged` / `Verify-Projex: Encouraged`; no workflow reads either. Since `45c43c1`, `execute-projex.md` picks delegation freely per step, so the vocabulary describes a mechanism that no longer exists. Needs a framework-level decision (give `Encouraged` a consumer, or drop it from plan-projex) — out of scope here, where the fix is simply to use the marker that does fire.
- **`execute-projex.md` § WORKFLOW STEPS heading numbers skip 4** (`### 3. EXECUTE STEPS SEQUENTIALLY` → `### 5. HANDLE DEVIATIONS`), left over from `45c43c1`'s restructure. Cosmetic, one-line `/revise-projex`, unrelated to this plan.
- **Blocking pre-close commit-composition gate** in `close-projex.md` (redteam finding 2a) — a new gate rather than a template edit; pair it with `hygiene-lint`.
- `hygiene-lint` (proposal Option C) — the outright ID ban reduced its hardest check to `\b\d{10}\b` in comment context. Worth a follow-up proposal after the rules get field time.

### Risks

- **Multi-line close message fails in practice** (shell quoting, PowerShell here-string handling): Low likelihood (down from Medium — the form was verified live on git 2.55 by the sibling red team), High impact — it is the landing-commit channel. Mitigated by step 4's smoke test, which runs before the wording is finalized and escalates rather than proceeding. Fallback if it fails: rely on step-commit trailers only and pick merge- or rebase-close over squash-close, documented as a constraint.
- **Trailer stripped at merge in a PR-gated repo** (GitHub `squash_merge_commit_message` = `PR_BODY` / `BLANK`): Medium likelihood, Critical impact — rule 1 removes the comment citations first, so a stripped trailer leaves zero code→doc traceability. Converted from a silent assumption into an observable: the condition is stated in the convention block and the audit pass samples base history for the trailer rate, grading zero as Critical.
- **Audit renumbering skew** — five headings shift: Low. `grep -in "step [0-9]" audit-projex.md` currently returns nothing, so no internal cross-reference can break; the exposure is a mis-numbered or duplicated heading, caught by the contiguity grep.
- **do-projex inline copy drifts from SKILL.md** on a future edit to either: Medium/Low. Mitigated by the explicit "reproduced rather than referenced, because …" lead, which tells a future editor the copy is deliberate and must track the source.
- **Enforcement gap** — audit is triggered, not universal: accepted trade-off, carried from the proposal. Rules ride SKILL.md into every session and are inlined in do-projex; opt-in retrofit mode sweeps accumulation on request.
- **Agents pick a wrong conventional type at close:** Medium/Low. Vocabulary is listed inline in every template, the convention block keys type selection to what the diff does, and the audit commit check reads type-vs-diff rather than type-presence. Residual: nothing blocks a wrong type at commit time — only the post-hoc audit sees it.

### Open Questions

None.
