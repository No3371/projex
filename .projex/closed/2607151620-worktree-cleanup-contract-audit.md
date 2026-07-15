# Audit: Worktree Cleanup Contract + Close-Script Removal Diagnosis (execution)

> **Audit Date:** 2026-07-15 | **Auditor:** agent (Claude, opus) | **Work Period:** 2026-07-15 03:00–04:20
> **Subject:** Executed plan `2607150236-worktree-cleanup-contract-plan.md` on branch `projex/2607150236-worktree-cleanup-contract`
> **Related:** `2607150236-worktree-cleanup-contract-log.md` (execution log) | `2607150312-worktree-cleanup-contract-plan-redteam.md` (5 findings folded into plan)

---

## Audit Summary

**Claim:** Establish a worktree cleanup contract in the specs and replace blind `worktree remove --force` in the close scripts with a pre-flight cleanliness gate + registered-vs-unregistered removal diagnosis, across 13 files (3 specs, 10 scripts), with `.sh`/`.ps1` parity.

**Verdict:** Verified

**Assessment:** Completeness: High | Correctness: High | Quality: High | Value: High

**Top Issues:**
1. (Minor, non-blocking) The single legitimate `worktree remove` attempt still surfaces git's native `fatal: … is not a working tree` to stderr in the unregistered case, immediately before the friendly diagnosis. Pre-existing `2>&1` behavior, not a regression; the misleading *second* `--force` retry is gone.
2. (Monitor, out of scope by design) `debug-projex.md` / `simulate-projex.md` do not restate the contract; adoption rests on agents reading SKILL.md § Worktree Mode at close (red-team Finding 3b, deliberately deferred).
3. None else.

---

## Claims vs Evidence

| Claim | Evidence | Status | Notes |
|-------|----------|--------|-------|
| No `worktree remove --force` in the 6 merge-type scripts | `grep -c` = 0 in all four sh (ps1 mirror by inspection) | ✓ | abandon retains its intentional `--force` (by contract) |
| Unified pre-flight gate rejects any non-clean worktree | Read diff of all 6 scripts; independent tests S2/S3/P2/P3 exit 1 | ✓ | `git status --porcelain` covers untracked + tracked |
| Clean-worktree close unchanged (merged, wt gone, branch deleted) | Independent tests S1/P1 exit 0, base advanced, wt+branch gone | ✓ | both families |
| Unregistered removal → prune-hint message, no `--force`, no crash | Independent test S4 exit 0, "unregistered", "worktree prune" | ✓ | git's own fatal still echoed (cosmetic) |
| Registered removal → blocking-content diagnosis + retry line | Code inspection (SIGPIPE-guarded `{…\|\|true;}\|head`); executor matrix row 6 (lock) | ✓ | lock case relied on executor evidence + inspection, not independently re-run |
| Specs carry contract + hygiene gate + corrected ordering + recovery note | Read diff of SKILL.md, execute-projex.md, close-projex.md | ✓ | wording coherent, matches plan |
| Creation-side cleanup hint line | Read diff of projex-worktree.{sh,ps1} | ✓ | rides existing `# next:` pattern |
| `.sh` ↔ `.ps1` behavioral parity | Independent sh vs ps1 runs identical on S1/S2/S3 vs P1/P2/P3 | ✓ | output-style deviation is cosmetic |

---

## Red-Team Finding Closure (the acceptance bar)

The plan folded in 5 red-team findings; each is verified in the delivered work:

| Finding | Required fix | Delivered | Verified by |
|---------|--------------|-----------|-------------|
| 1 — squash/merge lacked tracked-dirty guard | unify gate on `git status --porcelain` | Present in all 3 merge-type pairs; rebase's old tracked-only check replaced | Independent tests S3/P3 (tracked edit, no untracked → exit 1) |
| 2 — still-registered branch untested | add lock matrix row | Row 6 present in log (sh + ps1); registered branch code present | Executor matrix + code inspection |
| 3 — contract wording overclaimed | scope "refuse" to non-clean; ignored = warn | SKILL.md bullet reworded ("does **not** block git-level removal") | Read diff |
| 4 — `git … \| head` SIGPIPE abort | wrap `{ …; } \| head` | Guard present in sh removal diagnosis | Read diff |
| 5 — inverted false-negative note + no prune | fix note, add `prune` to unregistered msg | `git worktree prune` in unregistered messages (Step 3b + abandon) | Read diff + test S4 |

Red-team's edge case (empty "Blocking content" under a pure lock) is also handled: the message states "an empty list above means the block is a lock, not dirty content."

---

## Code / Implementation Inspection

**Scripts (10 files) — Quality: High**
- Pre-flight gate: worktree-mode-guarded, runs before any base mutation → re-run after cleanup is free. Command-substitution `|| true` and builtin `echo | head` are SIGPIPE-safe; the one external `git … | head` is `{…}` wrapped. Correct.
- Removal diagnosis: registration test via `worktree list --porcelain` suffix regex on forward-slash paths (git prints `/` on Windows too — red-team-confirmed, and my S4 run matched). Two-branch registered/unregistered split behaves correctly.
- **Deviation 1 (rebase gate inlined, not re-wrapped):** rebase-close already sits inside an `if WORKTREE_MODE` / `if ($Worktree)` block; the unified gate replaces the old tracked-only check in place rather than adding a redundant nested wrapper. Strictly broader than the old check; behavior identical to squash/merge. Verified benign.
- **Deviation 2 (ps1 uses `Write-Error`/`Write-Warning` with newline-joined lists vs sh `echo | head`):** same observable outcome — exit code + first-N blocking lines to the error/warning stream, matching existing ps1 conventions. Parity holds (S1/S2/S3 == P1/P2/P3).

**Specs (3 files) — Quality: High**
- SKILL.md § Worktree Mode: cleanup-contract bullet, correctly scoped (refuse on non-clean; ignored warns).
- execute-projex.md: contract sentence at worktree init (ln 97) + step-7.5 paragraph.
- close-projex.md: worktree leftover hygiene check, corrected removal-ordering sentence ("merges first, then removes … best-effort"), registered/unregistered recovery note with `prune` self-heal.

**Undocumented changes:** None found. Diff is confined to the 13 planned files.

---

## Testing Validation

**Executor battery:** sh 32/32, ps1 31/31 across a 9-row matrix (log Step 6). Method sound (throwaway `git init` repos, `pwsh -File` child processes so `exit` doesn't kill the harness).

**Independent re-verification (this audit):** built fresh scratch repos and ran the *actual* edited scripts:
- sh: 13/13 meaningful checks (clean close; untracked gate; **Finding 1** tracked-dirty gate; unregistered/half-removal diagnosis).
- ps1: 10/10 (same scenarios) — parity confirmed.
- The one "FAIL" in my sh run was an over-strict assertion on git's native `fatal` text (see Issue 1), not a code defect.

**Not independently re-run:** the registered-worktree lock case (matrix row 6) — Windows `git worktree lock` setup; relied on the executor's evidence plus code inspection. Code path is present and SIGPIPE-guarded.

**Automated:** `bash -n` clean on all 5 touched `.sh` (re-run by me). shellcheck unavailable on host (executor noted; not installed — I did not install). PowerShell parser reported 0 errors per executor.

---

## Gap Analysis

**Promised but not delivered:** None. All 8 success criteria satisfied; all 13 files changed.

**Undocumented issues:** None.

**Residual (declared out of scope, not gaps):**
- `debug-projex.md` / `simulate-projex.md` contract restatement deferred (SKILL.md covers all worktree consumers). Red-team Finding 3b "monitor" item — revisit if a deps-leftover incident recurs.
- Auto-deletion of leftover directories intentionally kept manual (framework rule).

---

## Quality Assessment

- **Completeness: High** — every objective, success criterion, and folded red-team finding delivered.
- **Correctness: High** — independently verified on both families; gate fires pre-mutation, base HEAD never moves on a dirty worktree, no `--force` path remains, diagnosis branches resolve correctly.
- **Code Quality: High** — no dead code; the two deviations are documented and behavior-preserving; SIGPIPE guard and parity handled deliberately.
- **Value: High** — converts a silent data-loss path (blind `--force` deleting untracked files) and a misleading dead-end ("not a working tree" retry) into an actionable pre-flight stop + clear recovery guidance. Intended breaking change is documented for external-repo users.

---

## Findings

### Critical (Must Address)
- None.

### Significant (Should Address)
- None.

### Minor (Nice to Fix)
- **Native git `fatal: … is not a working tree` still echoes in the unregistered case** (from the single `worktree remove … 2>&1`), just before the friendly message. Pre-existing behavior the plan chose to keep. Could optionally suppress git's stderr on the first attempt, but that would also hide detail in the registered case. Cosmetic; not patch-worthy.

### Positive
- Independent re-test reproduced every load-bearing behavior claim, including the exact Finding-1 scenario (tracked edit, no untracked) that a naive `^??` gate would have let through.
- Deviations were surfaced honestly in the log's Deviations section and hold up under scrutiny.
- Worktree left clean (no untracked audit artifacts inside it); main HEAD unchanged at `107844e`.

---

## Recommendations

**Immediate:** Proceed to close. No pre-close patch required.
**Future:** If deps-leftover incidents recur, add a one-line contract pointer to `debug-projex.md`'s close section (red-team monitor item).
**Process:** Independent audit re-testing (vs trusting the executor matrix) caught nothing wrong here — a good sign for this executor, worth continuing.

---

## Final Verdict

**Status:** Accept

**Overall Assessment:**
- Completeness: High
- Correctness: High
- Quality: High
- Value: High

**Conditions:** None.

**Sign-off:** Yes — the delivered work implements the plan faithfully, satisfies all success criteria, resolves all 5 red-team findings, and passes independent behavioral re-verification on both `.sh` and `.ps1`. The two executor deviations preserve behavior and parity. No patch is warranted before close.
