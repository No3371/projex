# Util Scripts: Hint the Deterministic Next Step in Output

> **Status:** Accepted — implemented via 2607090230-util-script-output-hints-patch.md (Option A)
> **Created:** 2026-07-09
> **Author:** Agent
> **Related Projex:** 2604031727-workflow-guardrails-determinism-imagine.md (Direction 1 — Gate Architecture, Direction 5 — Re-Anchoring) | 2604031730-util-script-ideas-imagine.md | 2607090220-util-script-output-hints-proposal-verification-audit.md (audit: Accept with Conditions) | 2607090230-util-script-output-hints-patch.md (Option A implementation)

---

## Summary

Some util scripts stage a change but never commit it (`del-n-stage`, `move-n-stage`, `stage-by-pattern`) — the always-required next call is `stage-n-commit`, yet nothing in the script's own output says so. `new-projex.sh` already proves the pattern works: it prints the exact next command to run — but the command it prints (`projex-commit.sh`) doesn't exist; the real script is `stage-n-commit.sh`. Extend the working pattern to every stage-only script, fix the stale reference, and hint `projex-worktree`'s single mandatory follow-up (redirect all subsequent commands to the worktree path).

---

## Problem Statement

### Current State

Ten util scripts exist (`{repo-root}/*.{sh,ps1}`). Each is invoked by an agent mid-workflow, per SKILL.md § Utility Scripts. Only `new-projex.sh`/`.ps1` prints a follow-up command in its own stdout:

```
# next: scaffold contains header only — update the format, structure and content per {type}-projex.md
# commit: {script_dir}/projex-commit.sh {repo_root} "projex({type}): add {slug}" {rel_dir}/{file_name}
```

Verified by running it: `new-projex.sh` prints a `commit:` line invoking `projex-commit.sh`. That script doesn't exist in the repo — the actual committer is `stage-n-commit.sh`/`.ps1`. `CLAUDE.md`/`AGENTS.md` § Repository Structure list `projex-commit.{sh,ps1}` too — the stale name is in three places, not one. An agent that copy-pastes the printed hint gets `command not found`.

The other three stage-only scripts (`del-n-stage`, `move-n-stage`, `stage-by-pattern`) print only what they did:

```
Deleted 2 file(s):
  path/to/a.md
  path/to/b.md
```

Nothing states the deletions aren't committed yet. The workflows that call these scripts (execute-projex, close-projex, archive-projex) all follow with a separate `stage-n-commit` call — but that instruction lives in the *workflow spec*, not the script. An agent invoking the script outside its documented workflow context (or a human running it ad-hoc) has no signal from the tool itself.

`projex-worktree.sh` has a different single always-todo: once it succeeds, **every subsequent script/git call in the session must target the printed worktree path, not the original repo-root** — per execute-projex.md, simulate-projex.md, debug-projex.md all restating "all subsequent commands use `{worktree-root}` as the working directory." Current output:

```
Worktree created: {repo}/.projexwt/{suffix} (branch: {branch}, base: {base})
```

States the fact, doesn't frame it as an instruction.

### Gap / Need / Opportunity

Three stage-only scripts are silent about their mandatory follow-up. One script (`new-projex`) already hints it but points at a script that doesn't exist. `projex-worktree` states a fact but not the redirection it implies. In all four cases the follow-up is **single and deterministic** — not "maybe commit," not "one of several next steps" — exactly the class of hint the ladder favors: cheap to add, removes a class of agent omission (forgetting to commit staged-only changes) and a class of agent error (using a dead script name).

### Why Now?

`new-projex.sh` is the existing proof this pattern is cheap and already half-built. The imagination doc `2604031727-...-imagine.md` (Direction 1, Direction 5) already names "make the agent's position visible" as a guardrail direction — this proposal is the smallest concrete slice of that: no new script, no new workflow ceremony, just corrected + extended stdout on scripts that already run.

---

## Proposed Change

### Overview

1. **Fix** the stale `projex-commit.sh`/`.ps1` reference in `new-projex.sh`, `new-projex.ps1`, `CLAUDE.md`, `AGENTS.md` → `stage-n-commit.{sh,ps1}`.
2. **Add** a trailing hint line to `del-n-stage`, `move-n-stage`, `stage-by-pattern` — same shape as `new-projex`'s `# commit: ...` line — printing the literal `stage-n-commit` invocation with the exact files just staged.
3. **Add** a trailing hint line to `projex-worktree` — states that all subsequent commands must use the printed worktree path.

### Approach Options

#### Option A: Print the literal next command (matches `new-projex` precedent)

- **Description:** Each script's final `echo` includes a ready-to-run command line, e.g. `# next: commit these changes — {script_dir}/stage-n-commit.sh {repo_root} "projex: <msg>" {files...}`. Message is a placeholder the agent fills in; paths/files are concrete.
- **Pros:** Matches existing convention exactly (`new-projex` already does this) — zero new mental model. Copy-pasteable. Cheapest to verify (echo one more line).
- **Cons:** Commit message can't be inferred by the script — placeholder text only. Slight risk of an agent running it verbatim with a junk message if not careful.
- **Effort:** Tiny — one `echo` line per script, 4 scripts × 2 variants (sh/ps1) = 8 edits + 4 doc reference fixes.

#### Option B: Print a structured reminder, not a literal command

- **Description:** `# NEXT: staged but not committed — run stage-n-commit next.` No file list, no invocation string — just the fact framed as an instruction.
- **Pros:** Simpler string, no risk of a bad placeholder commit message being copy-pasted verbatim.
- **Cons:** Breaks the pattern `new-projex` already set (a full copy-pasteable line) — inconsistent within the same script family. Less useful — agent still has to reconstruct the file list.
- **Effort:** Same as A, marginally less text.

#### Option C: No script change — document the follow-up more forcefully in SKILL.md only

- **Description:** Leave scripts as-is; strengthen prose in SKILL.md's script docs ("always follow with stage-n-commit").
- **Pros:** Zero script edits.
- **Cons:** SKILL.md already documents this (it's in every calling workflow's steps) — the gap isn't missing documentation, it's the *script output* not reinforcing it at the moment an agent is most likely to skip a step (right after a successful stage-only call, mid-flow, attention on the next thing). Doesn't fix the dead `projex-commit.sh` reference either.
- **Effort:** Trivial, but doesn't address the actual finding.

### Recommended Approach

**Option A.** It's the pattern already proven in production (`new-projex.sh`) — extending it is consistent, not novel. Option B waters down the one part of the existing pattern that makes it useful (a runnable line). Option C ignores that the bug (dead script name) lives in output text, not workflow docs.

---

## Impact Analysis

### Affected Areas

- `del-n-stage.sh` / `.ps1` — add trailing commit hint
- `move-n-stage.sh` / `.ps1` — add trailing commit hint
- `stage-by-pattern.sh` / `.ps1` — add trailing commit hint (only on the staging path, not `-n` dry-run, not the "no changes" exits)
- `projex-worktree.sh` / `.ps1` — add trailing "use this path from now on" hint
- `new-projex.sh` / `.ps1` — fix `projex-commit.sh`/`.ps1` → `stage-n-commit.{sh,ps1}`
- `CLAUDE.md`, `AGENTS.md` § Repository Structure — same rename fix

### Dependencies

- **Requires:** None — pure additive/corrective script edits, no behavior change to existing exit codes or staging logic.
- **Blocks:** Nothing.

### Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Agent copy-pastes placeholder commit message verbatim | Low | Low | Placeholder clearly bracketed (e.g. `"<msg>"`), matches existing `new-projex` convention agents already handle correctly |
| Hint line breaks a caller that parses script stdout strictly | Low | Low | No current workflow parses stage-only script output beyond presenting it to the user; confirm via grep before executing |
| `stage-by-pattern` hint fires on the `-n` dry-run path by mistake | Low | Low | Gate the hint behind the same branch that prints `"Staged filtered changes..."` — dry-run/no-match paths already `exit 0` earlier |

### Breaking Changes

None — additive stdout lines only; exit codes, arguments, and staging behavior unchanged.

---

## Open Questions

- [ ] Should `execute-precheck.sh`'s `REPO_ROOT=/BRANCH=/PLAN_REL=` block also gain an explicit "record these for all subsequent calls" line, or does the key=value framing already read as instructional enough? (Weaker case than the four above — precheck's follow-up isn't single-action, it's "use these values repeatedly.")
- [ ] Do `projex-squash-close`/`merge-close`/`abandon` need a hint for restoring a stash? Deferred — that follow-up is conditional ("if a stash was made"), not always, so it falls outside this proposal's scope by definition.

---

## Next Steps

If accepted:
1. `/plan-projex.md` against this proposal — scope: 4 scripts × 2 variants + 2 doc fixes, single projex folder (repo root), no execution ceremony needed beyond a patch-sized change.
2. Given the bounded, well-understood nature of the change, `/patch-projex.md` may be the better fit than a full plan — flag this at planning time.

---

## Appendix

### Research / References

- Verified live: `new-projex.sh` execution (`.projex/2607090215-...-proposal.md` creation) printed `# commit: {path}/projex-commit.sh ...` — confirmed via `ls projex-commit*` (no match) and `grep -rn projex-commit` (only in `new-projex.{sh,ps1}`, `CLAUDE.md`, `AGENTS.md`) that the real script is `stage-n-commit.{sh,ps1}`.
- `del-n-stage.sh`, `move-n-stage.sh`, `stage-by-pattern.sh` read in full — confirmed none commit, none hint at the required follow-up commit.
- `projex-worktree.sh` read in full — confirmed output states the created path but not the "use this path from now on" instruction that execute-projex.md/simulate-projex.md/debug-projex.md all separately restate in prose.
- `2604031727-workflow-guardrails-determinism-imagine.md` — § Texture & Detail, illustrating Direction 1 (Gate Architecture): "make the agent's epistemic state visible" is the underlying principle this proposal operationalizes narrowly.
- `2604031730-util-script-ideas-imagine.md` — `projex-status` idea (auto-updating a status field) shares the same DNA: eliminate a step agents forget by having the tool state it.

### Alternatives Considered

See Approach Options above (B: structured-but-not-literal hint; C: docs-only). Both rejected — see Recommended Approach.
