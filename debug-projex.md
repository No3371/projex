---
description: Workflow to debug a concrete, specific issue through hypothesis-fix-verify iteration in an isolated worktree. Confirms the issue, enumerates causes, attempts fixes one by one, observes outcomes, and either delivers the fix or exhausts all imaginable cases. (Part of @projex-framework skill. Load the skill first.)
---

## PURPOSE

Debug-projex tackles a specific, reproducible issue when the cause is unknown. The agent investigates: confirm symptom → enumerate hypotheses → test each → fix or rule out → repeat until the bug is dead or every imaginable case is exhausted.

**Key characteristics:**
- **Issue-bound** — one concrete bug per debug-projex; not exploratory, not generative
- **Iterative** — hypothesis → instrument → fix attempt → verify → next, looped until resolved or exhausted
- **Worktree-first** — runs in an isolated worktree; main directory untouched regardless of experiment aggressiveness
- **Exhaustive** — does not stop at the first plausible failure; continues until the fix passes verification AND no obvious adjacent failure mode remains
- **Two terminal states:** **Resolved** (fix squash-merged to base) or **Exhausted** (all hypotheses ruled out, document handed back)
- **Live-logged** — every hypothesis, attempt, and observation written to a debug log file in the worktree, committed with the change it describes. The final document is composed from this log, not from memory.

**Distinct from neighbors:**
- vs `patch-projex` — patch handles small, well-understood changes with a known fix. Debug starts with an unknown cause.
- vs `preplan-projex` — preplan runs minimal planning probes and always discards. Debug investigates exhaustively and ships a real fix; rollback is per-attempt, not terminal.
- vs `execute-projex` — execute follows a pre-written plan. Debug discovers as it goes; the hypothesis list is the evolving plan.

---

## INVOCATION

```
/debug-projex <concrete issue description>
```

**Examples:**
- `/debug-projex Login button does nothing on Safari iOS — works on Chrome/Firefox`
- `/debug-projex POST /api/orders returns 500 when payload includes Unicode in customer_name`
- `/debug-projex Background worker exits silently after ~6 hours with no log line`
- `/debug-projex Test suite passes locally, fails on CI with "module not found" for the same import`

**Required from user:** symptom, observation context (where, when, how reproduced), error messages. If the report is too vague to reproduce, ask before starting — see PRE-DEBUG CHECKLIST step 4.

---

## REVERSIBILITY MODEL

Debug-projex runs in an isolated worktree (`{repo-name}/.projexwt/{branch-suffix}/`) on an ephemeral branch (`projex/debug/{yymmddhhmm}-{debug-name}`). The main working directory stays on the base branch throughout. Per-attempt rollback uses `git reset --hard` or `git checkout -- .` within the worktree.

### ALLOWED inside the worktree

- Create, modify, delete files freely
- Add `console.log` / `print` / instrumentation freely — stripped before the final fix commit
- Run local builds, compilers, transpilers, linters, formatters
- Run tests, including writing new failing-test reproductions
- Install local dependencies (lockfile changes are git-tracked and evaluated for inclusion in the fix)
- Read external resources (docs, GET-only API calls)

### FORBIDDEN at all times

| Action | Why |
|--------|-----|
| `git push` to any shared branch | Exposes incomplete or instrumentation-laden state |
| External API mutations (POST/PUT/DELETE against shared services) | Cannot undo |
| Database writes against shared/staging/prod DBs | Mutates real data |
| Package publishing | Cannot unpublish |
| Sending notifications | Cannot unsend |
| Deploying to any environment | Affects running systems |
| Modifying files outside the worktree | Not git-tracked here |
| Destructive system commands outside the worktree | Affects host |

If reproducing the bug requires a forbidden action (e.g. a write against a shared DB), use a local equivalent (sqlite, docker container, fixture). If no local equivalent exists, document as "would do X" and ask the user before proceeding.

---

## PRE-DEBUG CHECKLIST

**GATE: Do not explore the codebase, read source files, or run any git commands beyond repo resolution before completing this checklist and step 1: INITIALIZE DEBUG. Premature exploration causes context drift and skipped preconditions.**

### 1. RESOLVE REPO AND BASE BRANCH

This is the first action. The directive may be invoked from any cwd — the projex file location (or the user's referenced file) is the source of truth.

```bash
cd <absolute-path-to-related-projex-or-affected-file-directory> && git rev-parse --show-toplevel && git branch --show-current
```

- Record `--show-toplevel` output as `<repo-root>`. **All script calls and git commands below use this value. Do not use your CWD.**
- Record `--show-current` output as `{base-branch}`. **Never assume `main`.**

If no projex file or affected file path was given, infer the repo from cwd and confirm with the user before proceeding.

### 2. MANUAL VALIDATION

- [ ] **Correct repository** — `<repo-root>` matches the repo where the bug occurs
- [ ] **Correct base branch** — `{base-branch}` is the branch the user expects the fix to land on
- [ ] **Working directory state acceptable** — worktree mode keeps the main dir untouched; uncommitted work in main dir is OK
- [ ] No active `projex/debug/*` branch already targets the same issue (check `git -C <repo-root> branch --list "projex/debug/*"`)

### 3. ISSUE INTAKE — LOCK THE SYMPTOM

Restate the issue in **three required fields**. If any is missing or vague, ask the user before continuing.

```
SYMPTOM:        [one-sentence description of what is wrong]
TRIGGER:        [steps, command, input, or condition that produces it]
EXPECTED:       [what should happen]
ACTUAL:         [what happens instead]
ERROR/EVIDENCE: [verbatim error, stack trace, log excerpt, or screenshot path — if any]
```

### 4. DEFINE THE VERIFY-SIGNAL

A verify-signal is a concrete, automatable, binary check that tells the agent whether the bug is present. Without it, "fixed" is a guess.

Acceptable forms (in order of preference):
1. A **failing test** the agent will write in CONFIRM REPRODUCTION — strongest signal, becomes a regression guard
2. A **command** with a clear pass/fail exit code (build, lint, type-check, custom script)
3. An **observable check** with explicit pass criteria (page loads without error, log line absent, response status 200)

Record the verify-signal in the debug log header. **Do not skip this step. No fix attempt may begin until the verify-signal is defined.**

### 5. SEED HYPOTHESES

Without reading code yet, list 3–7 plausible causes ordered by likelihood from the symptom and your stack knowledge. New hypotheses will be appended during ITERATE; this is the seed only.

---

## WORKFLOW STEPS

### 1. INITIALIZE DEBUG

#### A. Create the worktree (mandatory — no checkout fallback)

```bash
{projex-scripts}/projex-worktree.{sh|ps1} <repo-root> projex/debug/{yymmddhhmm}-{debug-name}
```

Record `<worktree-root>` as `{repo-name}/.projexwt/{yymmddhhmm}-{debug-name}/` (inside the repo). All subsequent script calls use `<worktree-root>` as the working repo for `stage-n-commit` and other utilities.

#### B. Create the debug log file

`{yymmddhhmm}-{debug-name}-debug-log.md` in the worktree's `.projex/` folder. Live record — written and committed as the debug proceeds, not reconstructed at the end.

Populate the header from PRE-DEBUG CHECKLIST output:

```markdown
# Debug Log: {debug-name}

> **Repo Root:** {repo-root}
> **Worktree Root:** {worktree-root}
> **Base Branch:** {base-branch}
> **Debug Branch:** projex/debug/{yymmddhhmm}-{debug-name}
> **Started:** YYYY-MM-DD HH:MM
> **Status:** In Progress

## Symptom
SYMPTOM:        ...
TRIGGER:        ...
EXPECTED:       ...
ACTUAL:         ...
ERROR/EVIDENCE: ...

## Verify-Signal
[The concrete pass/fail check]

## Seed Hypotheses
1. [hypothesis]
2. [hypothesis]
...

## Attempts
[Filled live during ITERATE]

## Adjacent Cases
[Filled during FINALIZE]
```

Commit the initial log:

```bash
{projex-scripts}/stage-n-commit.{sh|ps1} <worktree-root> "projex(debug): init - {debug-name}" .projex/{yymmddhhmm}-{debug-name}-debug-log.md
```

### 2. BUILD TASK LIST

**Before any fix attempt, translate the work into a task list using your environment's todo/task tool** (e.g., `TaskCreate` in Claude Code, or equivalent). **Not optional** — the task list is the structural backbone preventing skipped gates and forgotten log entries.

Required tasks (minimum):
- One task per **seed hypothesis** ("Test hypothesis 1: {short name}")
- One task for **CONFIRM REPRODUCTION** (must complete before any hypothesis task starts)
- One task for **adjacent-case verification**
- One task for **strip instrumentation**
- One task for **squash attempts into clean fix commit**
- One task for **WRITE DEBUG DOCUMENT**
- One task for **CLOSE WORKTREE**

When new hypotheses surface during ITERATE, append new tasks. **Mark each task in-progress before starting and completed only after the work AND its log entry are both committed.** If a task isn't marked complete, the step isn't done.

### 3. CONFIRM REPRODUCTION

**GATE: No fix attempt may begin until the bug is reproduced in the worktree against the verify-signal. If reproduction fails, stop and consult the user — do not start guessing at fixes.**

#### A. Run the verify-signal in its current form

If the verify-signal is a failing test that doesn't yet exist, **write it now** before running anything else. A test reproduction is the strongest signal and survives as a regression guard.

#### B. Confirm the failure mode matches the report

The verify-signal MUST fail as described. Capture the exact failure output verbatim into the debug log under `## Attempts` → `### Attempt 0 — Reproduction`.

#### C. Commit the reproduction

If a new repro test was written:

```bash
{projex-scripts}/stage-n-commit.{sh|ps1} <worktree-root> "projex(debug): add failing repro test - {debug-name}" path/to/repro.test.ext .projex/{yymmddhhmm}-{debug-name}-debug-log.md
```

Otherwise commit the log update alone.

#### D. Decision

- **Reproduces** → proceed to ITERATE
- **Does NOT reproduce** → log the non-repro finding with the exact command output, mark `Status: Escalated (Non-Repro)`, present to user, do NOT proceed. Likely causes: incomplete report, environment-specific, already fixed by intervening change.

### 4. ITERATE — HYPOTHESIS → ATTEMPT → VERIFY

**The core loop. Repeat until Resolved or Exhausted.**

For each hypothesis (most likely first), use the same lettered micro-structure:

#### A. PREPARE

1. Mark the hypothesis's task in-progress
2. State the hypothesis precisely: "X is caused by Y because Z." Vague hypotheses produce vague fixes.
3. Read only the files needed to evaluate this hypothesis. Do not pre-read everything.

#### B. INSTRUMENT (when cause is unconfirmed)

Cheaper to observe than to patch blindly. Add logging, asserts, breakpoints to confirm or deny the hypothesis **before** modifying production logic. Run the verify-signal with instrumentation in place; capture what it reveals.

- Hypothesis confirmed → proceed to C. ATTEMPT
- Hypothesis denied → record evidence in the log, mark ruled out, return to A with the next hypothesis
- Inconclusive → refine instrumentation. **Do not skip to ATTEMPT and guess.**

#### C. ATTEMPT THE FIX

Make the smallest change that should eliminate the cause.

#### D. VERIFY

1. **Run the verify-signal** — must pass
2. **Run the broader regression check** — relevant tests, build, type-check, lint. A "fix" that breaks three other things is not a fix.
3. **Decide:**
   - Verify-signal passes AND no regressions → **candidate fix**, proceed to E. LOG, then continue to adjacent-case checks (FINALIZE step 5)
   - Verify-signal fails → revert this attempt, return to A with refined or next hypothesis
   - Verify-signal passes but regressions appear → revert, refine the fix, retry; or rule out this approach if fundamentally incompatible

**Per-attempt rollback within the worktree:**
```bash
git -C <worktree-root> reset --hard HEAD~1     # Drop last attempt commit
git -C <worktree-root> checkout -- path/file   # Drop unstaged changes for one file
```

#### E. LOG, COMMIT

**GATE: The log entry for this attempt must be written and committed before starting the next attempt. The debug log is a live record, not a retrospective summary. Gaps here become gaps in the final document.**

Append to `## Attempts` in the debug log:

```
### Attempt N — {hypothesis short name}

**Hypothesis:** [precise statement]
**Instrumentation:** [what was added; what it revealed — or "none"]
**Change:**
```diff
[diff or before/after snippet]
```
**Verify-signal result:** Pass / Fail — [output excerpt]
**Regression check:** Pass / Fail — [what was checked, output excerpt]
**Outcome:** Reverted / Kept-as-candidate / Refined-into-Attempt-{N+1}
```

Commit the attempt and its log entry **atomically**:

```bash
{projex-scripts}/stage-n-commit.{sh|ps1} <worktree-root> "projex(debug): attempt N - {hypothesis short name}" path/to/changed-file.ext .projex/{yymmddhhmm}-{debug-name}-debug-log.md
```

For reverted attempts, commit the log entry alone after the revert so the failed attempt is preserved as evidence:

```bash
{projex-scripts}/stage-n-commit.{sh|ps1} <worktree-root> "projex(debug): attempt N reverted - {hypothesis short name}" .projex/{yymmddhhmm}-{debug-name}-debug-log.md
```

Mark the hypothesis's task complete only after this commit lands.

#### RE-ANCHOR AFTER EXPLORATION

> If an attempt led to substantial code reading or architectural exploration, **re-read this workflow and the debug log header (Symptom, Verify-Signal)** before starting the next hypothesis. Exploration causes context drift; re-anchoring prevents the agent from drifting into adjacent refactoring.

#### Hypothesis spawning

When instrumentation reveals something unexpected, **append the new hypothesis to the seed list and create a new task**. Do not silently abandon the original list. Every hypothesis must end as `Confirmed`, `Denied`, or `Deferred-with-reason` — recorded in the debug log.

#### Stopping condition for ITERATE

Proceed to step 5 (FINALIZE) when a candidate fix passes verify-signal AND regression check. Proceed to step 8 (EXHAUSTION) only when EXHAUSTION CRITERIA are met.

### 5. ADJACENT-CASE VERIFICATION

**Do not declare success at the first green test.** Before finalizing, ask: *what adjacent case would also break under this hypothesis?* Examples by class:

| Bug class | Adjacent cases to check |
|-----------|------------------------|
| Input handling | Empty, null, max-length, Unicode, leading/trailing whitespace |
| Concurrency | Two simultaneous calls, retry under contention |
| Browser/platform | Other browsers, mobile vs desktop, other OS path separators |
| Locale/timezone | Non-en-US locale, DST boundary, UTC vs local |
| Auth/permissions | Anonymous, expired token, insufficient role |
| Data shape | Empty collection, single item, very large collection, missing optional field |

Pick the cases relevant to the bug class. Run each through the verify-signal (or analogous check). Record results in `## Adjacent Cases` in the debug log:

```
| Case | Result | Notes |
|------|--------|-------|
| Empty input | Pass | ... |
| Other browser | Pass | ... |
```

If any adjacent case fails, treat it as a new hypothesis and return to ITERATE step A. **Adjacent-case failures are not "out of scope" — they are the same bug surfacing through a sibling path.**

### 6. FINALIZE THE FIX

#### A. Strip instrumentation

Remove debug logging, temporary asserts, scratch files. The final fix commit must be production-clean.

```bash
git -C <worktree-root> diff {base-branch}..HEAD     # Review what's about to land
```

Read the diff and confirm: only the fix and (optional) repro test remain. No `console.log`, no commented-out code, no scratch files.

#### B. Squash attempt commits into a clean fix commit

The iteration history lives in the debug log; the git log on base should show the resolved fix, not the path to it.

```bash
git -C <worktree-root> reset --soft {base-branch}                    # Unwind all attempt commits, keep changes staged
git -C <worktree-root> reset HEAD .projex/{yymmddhhmm}-{debug-name}-debug-log.md   # Unstage log so it commits separately
{projex-scripts}/stage-n-commit.{sh|ps1} <worktree-root> "fix({scope}): {one-line description}" "--trailer Projex: {yymmddhhmm}-{debug-name}" path/to/fixed-file.ext [more files...]
```

If a repro test was kept, include it in the fix commit (or as a separate test commit immediately before the fix).

#### C. Final verification battery

Run the verify-signal once more on the squashed state. Run the full regression suite. Run the build. All must pass.

```bash
git -C <worktree-root> log --oneline {base-branch}..HEAD     # Confirm clean history: fix + log commits only
git -C <worktree-root> status --porcelain                    # Confirm clean working tree
```

### 7. WRITE THE DEBUG DOCUMENT

The **debug log** has grown live. Now compose the final **debug document** at `.projex/closed/{yymmddhhmm}-{debug-name}-debug.md`. Debug-projex are born closed.

The debug document is the polished, reader-facing artifact derived from the log. It does NOT replace the log — both are kept. The log shows every attempt; the document tells the story.

**Template:**

```markdown
# Debug: [Title]

> **Author:** [Model(Role), or Model, or self identity, fallback: "Agent"]
> **Issue:** [one-sentence symptom]
> **Status:** Complete (Resolved) | Escalated (Exhausted)
> **Fix Commit:** [SHA after squash, or "n/a — exhausted"]
> **Debug Log:** {yymmddhhmm}-{debug-name}-debug-log.md
> **Related Projex:** [filenames if any]

---

## Symptom

- **Trigger:** [how to reproduce]
- **Expected:** [what should happen]
- **Actual:** [what happens]
- **Verify-signal:** [concrete pass/fail check]

## Reproduction

[Exact steps or command]

```
[error / stack / log — verbatim]
```

---

## Hypotheses

| # | Hypothesis | Verdict | Evidence |
|---|------------|---------|----------|
| 1 | [precise statement] | Confirmed / Denied / Deferred | [what proved/disproved it — pull from log] |
| 2 | ... | ... | ... |

---

## Root Cause

[The actual cause, stated plainly. Distinguish from the surface symptom.]

## Fix

[What was changed and why this resolves the root cause — explanation, not a diff dump.]

**Files touched:**
- `path/to/file.ext` — [what changed]

**Regression guard:** [test added? where?]

---

## Adjacent Cases Checked

| Case | Result |
|------|--------|
| ... | Pass / Fail / N/A |

---

## Ruled Out

[Hypotheses that turned out wrong — kept so future debuggers do not retread.]

- **[Hypothesis]:** [evidence it was wrong]

---

## Open Items

[Anything noticed during debug that is out of scope but worth raising — adjacent bugs, code smells, tech debt. **Do NOT fix here.** Suggest follow-up projex if warranted.]

| Type | Description |
|------|-------------|
| [Patch/Plan/Eval] | [what and why] |

---

## If Exhausted (instead of Resolved)

> Use this section only when no fix was found.

- **Hypotheses tried:** [count]
- **Strongest remaining suspicion:** [what to investigate next]
- **What's needed to continue:** [missing repro environment, missing access, requires user knowledge, etc.]
```

Commit the debug document together with a final log update marking `Status: Complete (Resolved)` (or `Escalated (Exhausted)`):

```bash
{projex-scripts}/stage-n-commit.{sh|ps1} <worktree-root> "projex(debug): finalize - {debug-name}" .projex/closed/{yymmddhhmm}-{debug-name}-debug.md .projex/{yymmddhhmm}-{debug-name}-debug-log.md
```

### 8. CLOSE THE WORKTREE

**GATE: Verify clean working tree before proceeding.** The finalization scripts abort on uncommitted changes.

```bash
git -C <worktree-root> status --porcelain
```

If output is non-empty, commit or discard the remaining changes before continuing.

#### Closure decision tree

```
Was a candidate fix found and verified?
├── Yes → Was it accepted by the user (or auto-close marked)?
│   ├── Yes → Option A (Squash-Merge to base)
│   └── No  → Wait for user (do NOT close)
└── No → Was every hypothesis ruled out with evidence (EXHAUSTION CRITERIA met)?
    ├── Yes → Option B (Exhausted — preserve doc, abandon worktree)
    └── No  → Return to ITERATE
```

#### Option A: Squash-Merge (Resolved)

Brings the fix commit AND the debug document onto the base branch as a single squashed commit, removes the worktree.

```bash
{projex-scripts}/projex-squash-close.{sh|ps1} <repo-root> {base-branch} projex/debug/{yymmddhhmm}-{debug-name} "fix({scope}): {one-line}

Projex: {yymmddhhmm}-{debug-name}" --worktree
```

Verify from the main repo directory:
```bash
git -C <repo-root> log --oneline -1                  # Confirm squashed fix landed on base
git -C <repo-root> status --porcelain                # Confirm clean
git -C <repo-root> branch --list "projex/debug/{yymmddhhmm}-*"   # Confirm ephemeral branch deleted
```

#### Option B: Exhausted

Preserve the debug document on the base branch (so the investigation isn't lost), then abandon the worktree.

1. From the main repo, copy the debug document content out of the worktree branch:
```bash
git -C <repo-root> show projex/debug/{yymmddhhmm}-{debug-name}:.projex/closed/{yymmddhhmm}-{debug-name}-debug.md > <repo-root>/.projex/closed/{yymmddhhmm}-{debug-name}-debug.md
```

2. Commit the document on the base branch:
```bash
{projex-scripts}/stage-n-commit.{sh|ps1} <repo-root> "projex(debug): exhausted - {debug-name}" .projex/closed/{yymmddhhmm}-{debug-name}-debug.md
```

3. Abandon the worktree (also deletes the branch):
```bash
{projex-scripts}/projex-abandon.{sh|ps1} <repo-root> {base-branch} projex/debug/{yymmddhhmm}-{debug-name} --worktree
```

4. Hand back to user with the document path and the **If Exhausted** section highlighted.

---

## CLOSING PROTOCOL

A debug-projex is **ready to close** when either:
- A candidate fix passes verify-signal AND regression check AND adjacent-case verification (→ Option A), OR
- EXHAUSTION CRITERIA are met (→ Option B)

**Default: user-initiated.** After ITERATE produces a candidate fix, present results (verify-signal output, regression results, adjacent cases checked, files changed) and wait. Do not run Option A without user instruction.

**Auto-close (opt-in).** If the user requests auto-close, mark it in the debug log header (`> **Auto-Close:** Yes`) before proceeding. The mark in the document — not verbal instruction alone — is the valid signal. With auto-close marked, proceed directly to Option A after the verification battery passes.

**Exhausted state always closes via Option B without waiting** — the worktree is no longer useful and the document is the deliverable.

---

## EXHAUSTION CRITERIA

Mark **Exhausted** only when ALL of the following hold:

- [ ] Every seeded hypothesis has verdict `Confirmed`, `Denied`, or `Deferred-with-reason` in the debug log
- [ ] No new hypothesis surfaced from the latest two rounds of instrumentation
- [ ] The agent can articulate what additional input (env, access, user knowledge) would unblock further work
- [ ] The user has been informed and has not provided new information

"I tried three things and none worked" is **not** exhaustion. Exhaustion requires ruling things out with evidence, not running out of patience.

---

## QUALITY CHECKLIST

Before closing:

- [ ] `<repo-root>` and `{base-branch}` recorded from explicit `git -C <repo-root>` queries, not assumed
- [ ] Worktree was created and used; main directory never touched
- [ ] Verify-signal defined before any fix attempt (PRE-DEBUG step 4)
- [ ] Bug reproduced in the worktree before any fix attempt (CONFIRM REPRODUCTION gate)
- [ ] Task list created with one task per hypothesis + every gate; all marked complete or carried forward
- [ ] Every hypothesis in the debug log has a verdict with evidence
- [ ] Every fix attempt has verify-signal AND regression check results in the log
- [ ] Adjacent cases checked, not just the original repro
- [ ] Instrumentation stripped from final fix commit (diff reviewed)
- [ ] Attempt commits squashed into one clean `fix(scope):` commit
- [ ] Debug log file kept alongside debug document — both in `.projex/`
- [ ] Worktree closed (squash-merged via Option A if Resolved, abandoned via Option B if Exhausted)
- [ ] Main repo working directory clean and on `{base-branch}` — verified with `git status --porcelain`
- [ ] Ephemeral debug branch deleted — verified with `git branch --list`

---

## NOTES

- The debug document is the durable artifact for readers; the debug log is the durable artifact for auditors. Both survive closure.
- Report what actually happened, including dead ends. A debug-projex that proves five hypotheses wrong is valuable — the next debugger will not retread that ground.
- Resist bundling "while I'm here" cleanups into the fix commit. Note them in **Open Items** and let the user decide.
- If the bug turns out to be in user expectation rather than code, the document still closes as Resolved with the fix being "no code change — clarified expected behavior in [doc]". A real outcome.
- Use relative paths when referencing repository files in documents.
- Commit prefixes: `projex(debug):` for iteration commits in the worktree (squashed away on close); `fix(scope):` for the final landing commit on base.
- Reference projex by filename only — paths break when files move between `.projex/` states.
