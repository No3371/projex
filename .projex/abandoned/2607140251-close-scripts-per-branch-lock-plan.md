# Close Scripts: Per-Base-Branch Lock

> **Status:** Abandoned (Superseded)
> **Created:** 2026-07-14
> **Author:** Claude (orchestrate-projex subagent)
> **Source:** Direct request
> **Related Projex:** Superseded by `2607152043-agent-close-lock-plan.md` (agent-level lock chosen as the sole mechanism). Unrelated to `2607140239-active-projex-folder-proposal.md`.
> **Worktree:** Yes
> **Abandoned:** 2026-07-16 — user consolidated on the agent-level lock (`2607152043-agent-close-lock-plan.md`, hardened with a deterministic `projex-close-lock` helper) as the single close-concurrency mechanism; this script-level mutex approach is not being implemented. Recoverable from git history if the decision is revisited.

---

## Summary

Concurrent `close-projex` finalizations targeting the **same base branch** race on `$RepoRoot`'s shared working tree/index — even in worktree mode, finalization always funnels through `git -C $RepoRoot ...` against the one shared directory. Adds a per-base-branch mkdir-mutex to the four finalization scripts (squash-close, merge-close, rebase-close, abandon) so two closes onto the *same* base N are mutually exclusive, while closes onto *different* bases stay fully concurrent.

**Scope:** 8 files — `projex-squash-close.{ps1,sh}`, `projex-merge-close.{ps1,sh}`, `projex-rebase-close.{ps1,sh}`, `projex-abandon.{ps1,sh}`. No other files touched.
**Estimated Changes:** 8 files, ~10-15 inserted lines per file (lock acquire/guard + release), no removed logic.

---

## Objective

### Problem / Gap / Need

All four branch-finalization scripts mutate `$RepoRoot` — the single shared main working directory — when finalizing onto base, even in `-Worktree` mode where the *execution* phase was isolated. Worktrees isolate execute/debug/simulate cleanly (each ephemeral branch gets its own directory), but finalization always funnels back through `git -C $RepoRoot ...` against the one shared working tree and index. Two concurrent finalizations targeting the same base branch can interleave uncommitted squash/merge/rebase state in that shared index — actual state corruption risk, not a benign git ref-lock rejection.

**Human's explicit requirement:** "I want merge into branch N to be solo per N" — locking scoped per target base branch N, not global. Two closes finalizing onto *different* base branches must remain fully concurrent and unmediated.

### Success Criteria

- [ ] All 8 files acquire a per-base-branch lock immediately before the first `$RepoRoot`-mutating command that touches base, and release it immediately after the last one (worktree removal / branch deletion excluded from the locked region)
- [ ] Lock path is deterministic and identical between `.ps1` and `.sh` for the same branch name (`$RepoRoot/.git/projex-locks/<sanitized-branch>.lock`)
- [ ] Lock acquisition is atomic (mkdir-based mutex — no TOCTOU window)
- [ ] On contention, each script fails fast with a clear error naming the contested branch and instructing the caller to retry later — no retry/backoff loop
- [ ] Lock releases on every exit path (all pre-existing `exit 1` branches, plus the happy path) — verified per script via forced-failure test
- [ ] `projex-abandon.{ps1,sh}` only locks in checkout mode; worktree-mode abandon (which never touches `$RepoRoot`'s checked-out state) acquires no lock
- [ ] Two closes onto *different* base branches are not serialized by this change (no new contention introduced across branches)
- [ ] All 8 scripts remain behaviorally identical to each other (`.ps1` ↔ `.sh` parity) and unchanged in non-locking behavior (existing error messages, exit codes, worktree/branch cleanup) for the non-contended case

### Out of Scope

- Retry, wait, or backoff on lock contention (deliberate — fail-fast only, see Notes)
- Locking `projex-worktree.ps1/.sh` (creation is inherently isolated per ephemeral branch — different branch = different worktree path, no shared-base race)
- Locking `stage-n-commit`, `move-n-stage`, `del-n-stage`, `stage-by-pattern` (these operate within a single already-selected working directory during normal execution, not at branch-finalization time; out of this bug's blast radius)
- A shared lock-helper library file (see Rationale in Implementation Overview — duplication chosen over abstraction)
- Fixing checkout-mode's inherent cross-*different*-base race (two checkout-mode closes to different bases both mutate the one shared `$RepoRoot` checkout) — flagged as a residual risk in Notes, explicitly out of scope per the human's per-N (not global) requirement

---

## Context

### Current State

Confirmed by reading all 8 files directly (not secondhand):

| Script | Touches `$RepoRoot` when | Needs lock |
|---|---|---|
| `projex-squash-close.{ps1,sh}` | Checkout mode: `checkout $Base` (ps1:57 / sh:63) then squash-merge+commit. Worktree mode: squash-merge+commit only (`merge --squash` ps1:65/sh:70, `commit` ps1:82/sh:83) | Always |
| `projex-merge-close.{ps1,sh}` | Checkout mode: `checkout $Base` (ps1:57/sh:63) then `merge --no-ff` (ps1:65/sh:70). Worktree mode: `merge --no-ff` only | Always |
| `projex-rebase-close.{ps1,sh}` | Checkout mode: `checkout $Ephemeral` (ps1:82/sh:82), `rebase $Base` (ps1:89/sh:88), `checkout $Base` (ps1:101/sh:99), `merge --ff-only` (ps1:108/sh:105). Worktree mode: rebase runs inside the worktree (`git -C $WtPath rebase $Base`, ps1:63/sh:68) — does NOT touch `$RepoRoot` — but the final `merge --ff-only` (ps1:108/sh:105) always runs against `$RepoRoot` regardless of mode | Always (checkout mode: whole sequence; worktree mode: at minimum the final ff-merge) |
| `projex-abandon.{ps1,sh}` | Checkout mode: `checkout $Base` (ps1:50/sh:60). Worktree mode: `git worktree remove` (ps1:44/sh:55) only — does not touch `$RepoRoot`'s checked-out state at all | Checkout mode only |

None of the 8 files currently have any locking, mutex, or concurrency guard. Validation steps (repo exists, branches exist, base≠ephemeral) run before any mutation and don't need the lock.

### Key Files

| File | Role | Change Summary |
|------|------|----------------|
| `projex-squash-close.ps1` | Squash-merge finalization (Windows) | Insert lock acquire before mode branch; wrap checkout+squash+commit in `try`/`finally` |
| `projex-squash-close.sh` | Squash-merge finalization (bash) | Insert lock acquire + `trap EXIT`; explicit early release after commit succeeds |
| `projex-merge-close.ps1` | History-preserving merge (Windows) | Insert lock acquire before mode branch; wrap checkout+merge in `try`/`finally` |
| `projex-merge-close.sh` | History-preserving merge (bash) | Insert lock acquire + `trap EXIT`; explicit early release after merge succeeds |
| `projex-rebase-close.ps1` | Rebase + fast-forward (Windows) | Insert lock acquire before mode branch; wrap rebase+ff-merge in `try`/`finally` |
| `projex-rebase-close.sh` | Rebase + fast-forward (bash) | Insert lock acquire + `trap EXIT`; explicit early release after ff-merge succeeds |
| `projex-abandon.ps1` | Discard branch (Windows) | Insert lock acquire only inside checkout-mode branch; release right after checkout |
| `projex-abandon.sh` | Discard branch (bash) | Insert lock acquire + `trap EXIT` only inside checkout-mode branch |

### Dependencies

- **Requires:** Nothing — scripts are standalone, no other in-flight projex touches these files
- **Blocks:** Nothing currently known

### Constraints

- Lock lives under `$RepoRoot/.git/` — local, untracked, invisible to `git status` (per human's explicit requirement)
- Must work in both PowerShell (Windows) and git-bash (Windows) — no `flock` (unreliable in git-bash on Windows); mkdir-based mutex chosen for portability
- Fail-fast only — no retry/backoff loop (deliberate scope decision, see Notes)
- `.ps1` and `.sh` must derive the *identical* lock path for a given branch name so both variants coordinate through the same lock
- Lock must release on every exit path, not just the happy path (all pre-existing early-exit validation/failure branches in each script)
- Locked region stays tight: acquire immediately before the first `$RepoRoot`-mutating command touching base, release immediately after the last one; worktree removal / branch deletion excluded

### Assumptions

- `$RepoRoot/.git` is always a real directory (these scripts run `git -C $RepoRoot` against the main repo, never against a worktree path as `$RepoRoot` — worktrees live at `$RepoRoot/.projexwt/...` and are addressed separately) — verify early during execution if this ever changes
- Branch names in this framework never collide after `/` → `_` sanitization (see sanitization scheme below) — realistic branch patterns are `main`, `develop`, `feature/x`, `projex/{yymmddhhmm}-{name}` — verify no existing branch names would collide before executing (see Step 1 verification)
- `New-Item -ItemType Directory` (PowerShell) and `mkdir` (bash) are atomic check-and-create on the target filesystem (NTFS via Win32 `CreateDirectory`, and POSIX `mkdir(2)`) — both hold on Windows for both git-bash and native PowerShell

### Impact Analysis

- **Direct:** The 8 finalization scripts — new lock acquire/release logic only, no change to existing merge/rebase/abandon semantics for the uncontended case
- **Adjacent:** `close-projex.md` invokes these scripts as documented (`{projex-scripts}/projex-*-close.{sh|ps1} <repo-root> <base> <ephemeral> ...`) — invocation signature unchanged, no doc update needed
- **Downstream:** Any future concurrent `close-projex` runs (e.g. via `orchestrate-projex` dispatching parallel closes) now get correct mutual exclusion per base branch instead of racing

---

## Implementation

### Overview

Add a small mkdir-based mutex block to each of the 8 scripts, scoped to lock path `$RepoRoot/.git/projex-locks/<sanitized-branch>.lock`.

**Sanitization scheme:** replace every `/` in the branch name with `_` (PowerShell: `$Base -replace '/', '_'`; bash: `${BASE//\//_}`). Git already disallows the other filesystem-unsafe characters in branch names (no `\ : * ? " < > |`, no control chars, no consecutive dots) — `/` is the only character that needs translating for a flat lock filename. Collision risk is negligible for this framework's realistic branch patterns (`main`, `develop`, `feature/x`, `projex/{yymmddhhmm}-{name}` — the date-prefix convention makes accidental collisions after `/`→`_` substitution vanishingly unlikely, and a collision would only cause extra serialization between two different branches, never corruption, since the lock only ever gates against `$RepoRoot` mutation, not correctness of *which* branch is being merged).

**Shared helper vs. duplication — decision: duplicate the lock block in each of the 8 files, no shared helper script.**

Rationale: SKILL.md's utility scripts are currently independent, self-contained, per-purpose scripts with no shared-library pattern (`stage-n-commit`, `move-n-stage`, `del-n-stage`, `stage-by-pattern`, `projex-worktree`, `read_file.ps1` all stand alone). Introducing a shared `projex-lock.ps1`/`.sh` would require: (a) new files to create and maintain, (b) dot-sourcing/relative-path resolution logic in every one of the 8 scripts anyway (which is roughly as much code as the lock block itself — `$PSScriptRoot\projex-lock.ps1` vs `source "$(dirname "${BASH_SOURCE[0]}")/projex-lock.sh"`), and (c) a break from the established repo convention for a genuinely tiny (~10-15 line) piece of logic that's fail-fast (no retry loop, no complexity to hide). The abstraction cost roughly equals or exceeds the duplication cost here. Duplicating wins.

**PowerShell vs. bash release-timing asymmetry (important implementation detail):**

- **PowerShell:** wrap the locked region in `try { ... } finally { Remove-Item -Path $LockPath -Recurse -Force -ErrorAction SilentlyContinue }`. The `finally` block runs exactly when the `try` block ends — on success *or* on `exit` from within (PowerShell's `exit` still runs pending `finally` blocks) — so scoping the `try` tightly around only the `$RepoRoot`-mutating commands naturally satisfies both "release on every exit path" and "release immediately after the last mutating command." No extra code needed.
- **bash:** `set -euo pipefail` is active, and `trap '...' EXIT` only fires at actual process exit — not at an arbitrary mid-script point. A trap alone would hold the lock through the trailing worktree-removal/branch-delete code too (which should NOT be inside the locked region). So each `.sh` script needs **both**: (1) `trap 'rmdir "$LOCK_PATH" 2>/dev/null || true' EXIT` right after acquiring the lock — the safety net that guarantees release on every one of the script's existing early `exit 1` branches, and (2) an explicit `rmdir "$LOCK_PATH" 2>/dev/null || true` placed immediately after the last mutating command succeeds — the "tight release" on the happy path. The trap is idempotent (`rmdir` on an already-removed directory is a harmless no-op), so calling both is safe.

---

### Step 1: `projex-squash-close.ps1` / `.sh`

**Objective:** Lock is always required — checkout mode's `checkout $Base` and both modes' `merge --squash` + `commit` all mutate `$RepoRoot`.
**Confidence:** High
**Depends on:** None

**Files:**
- `projex-squash-close.ps1`
- `projex-squash-close.sh`

**Changes (`projex-squash-close.ps1`):**

Insert immediately after the existing `$WtPath` computation (after line 42, before the `if ($Worktree) {` mode branch at line 44), and close the `try` immediately after the existing commit-success block (after line 91, before the `if ($Worktree) { git -C $RepoRoot worktree remove ...` cleanup at line 93):

```powershell
// Before (lines 40-44):
$WtSuffix = ($Ephemeral -split '/')[-1]
$WtBase = Join-Path $RepoRoot ".projexwt"
$WtPath = Join-Path $WtBase $WtSuffix

if ($Worktree) {

// After:
$WtSuffix = ($Ephemeral -split '/')[-1]
$WtBase = Join-Path $RepoRoot ".projexwt"
$WtPath = Join-Path $WtBase $WtSuffix

# Acquire per-base lock: mkdir is an atomic check-and-create, so this is a safe mutex.
# ponytail: fail-fast only, no retry/backoff — contention means "retry after the other close finishes"
$LockDir = Join-Path (Join-Path $RepoRoot ".git") "projex-locks"
New-Item -ItemType Directory -Path $LockDir -Force | Out-Null
$SanitizedBase = $Base -replace '/', '_'
$LockPath = Join-Path $LockDir "$SanitizedBase.lock"
try {
    New-Item -ItemType Directory -Path $LockPath -ErrorAction Stop | Out-Null
} catch {
    Write-Error "Another close is already finalizing onto base branch '$Base' — lock held at '$LockPath'. Wait for it to finish, then retry."
    exit 1
}

try {
    if ($Worktree) {
```

And at the tail (existing lines 90-94, unindent not required beyond wrapping — just add the `try`'s closing `finally` after the commit-success block ends):

```powershell
// Before (lines 90-94):
    exit 1
}

if ($Worktree) {
    git -C $RepoRoot worktree remove $WtPath

// After:
    exit 1
}
} finally {
    Remove-Item -Path $LockPath -Recurse -Force -ErrorAction SilentlyContinue
}

if ($Worktree) {
    git -C $RepoRoot worktree remove $WtPath
```

Every line between the two insertion points (the mode `if/else`, the squash-merge block, the commit block — original lines 44-91) is otherwise **unchanged**, just now nested one level deeper inside the new `try`.

**Changes (`projex-squash-close.sh`):**

```bash
// Before (lines 48-53):
if [ "$BASE" = "$EPHEMERAL" ]; then
  echo "Error: base and ephemeral branch cannot be the same ('$BASE')" >&2
  exit 1
fi

if [ "$WORKTREE_MODE" = true ]; then

// After:
if [ "$BASE" = "$EPHEMERAL" ]; then
  echo "Error: base and ephemeral branch cannot be the same ('$BASE')" >&2
  exit 1
fi

# Acquire per-base lock: mkdir is atomic on POSIX, so this is a safe mutex.
# ponytail: fail-fast only, no retry/backoff — contention means "retry after the other close finishes"
LOCK_DIR="$REPO_ROOT/.git/projex-locks"
mkdir -p "$LOCK_DIR"
SANITIZED_BASE="${BASE//\//_}"
LOCK_PATH="$LOCK_DIR/$SANITIZED_BASE.lock"
if ! mkdir "$LOCK_PATH" 2>/dev/null; then
  echo "Error: another close is already finalizing onto base branch '$BASE' — lock held at '$LOCK_PATH'. Wait for it to finish, then retry." >&2
  exit 1
fi
trap 'rmdir "$LOCK_PATH" 2>/dev/null || true' EXIT

if [ "$WORKTREE_MODE" = true ]; then
```

```bash
// Before (lines 90-94):
  exit 1
fi

if [ "$WORKTREE_MODE" = true ]; then
  if ! git -C "$REPO_ROOT" worktree remove "$WT_PATH" 2>&1; then

// After:
  exit 1
fi

# Tight release: lock is no longer needed once the commit lands — worktree
# removal and branch delete below don't touch $RepoRoot's base-branch state.
rmdir "$LOCK_PATH" 2>/dev/null || true

if [ "$WORKTREE_MODE" = true ]; then
  if ! git -C "$REPO_ROOT" worktree remove "$WT_PATH" 2>&1; then
```

**Rationale:** Lock spans from before the mode branch (covers checkout-mode's `checkout $Base`) through the commit success (covers both modes' squash+commit). Worktree removal and branch delete (existing lines 93-109) are excluded per constraint — they never touch `$RepoRoot`'s base-branch state.

**Verification:** 
1. Syntax check: `bash -n projex-squash-close.sh` (exit 0); PowerShell AST parse: `powershell -NoProfile -Command "$e=$null; [void][System.Management.Automation.Language.Parser]::ParseFile('projex-squash-close.ps1',[ref]$null,[ref]$e); if($e){$e}"` (no errors printed)
2. Contention test: manually `mkdir <repo>/.git/projex-locks/main.lock`, then invoke the script with `<repo> main <some-ephemeral-branch> "msg"` — expect exit 1 and the "Another close is already finalizing..." message naming `main`; confirm the lock dir still exists afterward (script never touched it since it never acquired it)
3. Happy-path test: in a scratch git repo, create `main` + a throwaway ephemeral branch with one commit, run the script normally — confirm squash-merge lands on `main`, ephemeral branch is deleted, and `Test-Path <repo>/.git/projex-locks/main.lock` is `$false` afterward
4. Forced-failure test: repeat happy-path but induce a merge conflict (edit the same line on both branches) — confirm the script exits 1 with the existing conflict message AND the lock dir is gone afterward

**If this fails:** Revert the two files from git (`git checkout -- projex-squash-close.ps1 projex-squash-close.sh`) — no other state is touched by this change; safe to retry after fixing.

---

### Step 2: `projex-merge-close.ps1` / `.sh`

**Objective:** Same pattern as Step 1 — lock always required, mode branch + `merge --no-ff` are the mutating region.
**Confidence:** High
**Depends on:** None (independent of Step 1, same pattern applied to a structurally identical script)

**Files:**
- `projex-merge-close.ps1`
- `projex-merge-close.sh`

**Changes (`projex-merge-close.ps1`):**

```powershell
// Before (lines 40-44):
$WtSuffix = ($Ephemeral -split '/')[-1]
$WtBase = Join-Path $RepoRoot ".projexwt"
$WtPath = Join-Path $WtBase $WtSuffix

if ($Worktree) {

// After: identical lock-acquire insertion as Step 1, then:
...
try {
    if ($Worktree) {
```

```powershell
// Before (lines 78-82):
    exit 1
}

if ($Worktree) {
    git -C $RepoRoot worktree remove $WtPath

// After:
    exit 1
}
} finally {
    Remove-Item -Path $LockPath -Recurse -Force -ErrorAction SilentlyContinue
}

if ($Worktree) {
    git -C $RepoRoot worktree remove $WtPath
```

Lines 44-78 (mode `if/else` + `merge $Ephemeral --no-ff -m $MergeMsg` block) unchanged, nested one level deeper.

**Changes (`projex-merge-close.sh`):**

```bash
// Before (lines 48-53): identical anchor to Step 1
if [ "$BASE" = "$EPHEMERAL" ]; then
  echo "Error: base and ephemeral branch cannot be the same ('$BASE')" >&2
  exit 1
fi

// After: identical lock-acquire block as Step 1 (same LOCK_DIR/SANITIZED_BASE/LOCK_PATH/trap), inserted before line 53's `if [ "$WORKTREE_MODE" = true ]; then`
```

```bash
// Before (lines 79-83):
  exit 1
fi

if [ "$WORKTREE_MODE" = true ]; then
  if ! git -C "$REPO_ROOT" worktree remove "$WT_PATH" 2>&1; then

// After:
  exit 1
fi

# Tight release: lock no longer needed once the merge commit lands.
rmdir "$LOCK_PATH" 2>/dev/null || true

if [ "$WORKTREE_MODE" = true ]; then
  if ! git -C "$REPO_ROOT" worktree remove "$WT_PATH" 2>&1; then
```

**Rationale:** Identical structure to Step 1 — merge-close has one mutating command (`merge --no-ff`) instead of squash-close's two (`merge --squash` + `commit`), but the lock boundary logic is the same: before the mode branch, through the merge's success/failure handling, released before worktree/branch cleanup.

**Verification:** Same four checks as Step 1, substituting `projex-merge-close.{ps1,sh}` and confirming the merge (not squash) lands with `--no-ff` history preserved.

**If this fails:** `git checkout -- projex-merge-close.ps1 projex-merge-close.sh`.

---

### Step 3: `projex-rebase-close.ps1` / `.sh`

**Objective:** Lock always required. Worktree mode's rebase runs inside the worktree (doesn't touch `$RepoRoot`) but the final `merge --ff-only` always does. Checkout mode's `checkout $Ephemeral` + `rebase $Base` + `checkout $Base` all touch `$RepoRoot` directly.
**Confidence:** High
**Depends on:** None

**Files:**
- `projex-rebase-close.ps1`
- `projex-rebase-close.sh`

**Changes (`projex-rebase-close.ps1`):**

Insert the lock-acquire block right before the mode branch (after the `$WtPath` computation, before `if ($Worktree) {` at line 47), and close the `try`/`finally` right after the ff-merge succeeds (after line 112, before worktree removal at line 114):

```powershell
// Before (lines 43-47):
$WtSuffix = ($Ephemeral -split '/')[-1]
$WtBase = Join-Path $RepoRoot ".projexwt"
$WtPath = Join-Path $WtBase $WtSuffix

if ($Worktree) {

// After:
$WtSuffix = ($Ephemeral -split '/')[-1]
$WtBase = Join-Path $RepoRoot ".projexwt"
$WtPath = Join-Path $WtBase $WtSuffix

# Acquire per-base lock (see Step 1 for full rationale).
# ponytail: this locks the worktree-mode rebase phase too, even though that phase
# only touches $WtPath, not $RepoRoot — a single lock/unlock pair spanning the whole
# rebase+ff-merge sequence is simpler and safer than two separate acquire/release
# windows with a dead zone between them. Upgrade to a narrower worktree-mode-only
# lock window if this measurably serializes concurrent same-base closes too much.
$LockDir = Join-Path (Join-Path $RepoRoot ".git") "projex-locks"
New-Item -ItemType Directory -Path $LockDir -Force | Out-Null
$SanitizedBase = $Base -replace '/', '_'
$LockPath = Join-Path $LockDir "$SanitizedBase.lock"
try {
    New-Item -ItemType Directory -Path $LockPath -ErrorAction Stop | Out-Null
} catch {
    Write-Error "Another close is already finalizing onto base branch '$Base' — lock held at '$LockPath'. Wait for it to finish, then retry."
    exit 1
}

try {
    if ($Worktree) {
```

```powershell
// Before (lines 108-115):
git -C $RepoRoot merge --ff-only $Ephemeral
if ($LASTEXITCODE -ne 0) {
    Write-Error "Fast-forward of '$Base' failed unexpectedly after rebase — '$Ephemeral' is rebased; finish manually: git merge --ff-only $Ephemeral"
    exit 1
}

if ($Worktree) {
    git -C $RepoRoot worktree remove $WtPath

// After:
git -C $RepoRoot merge --ff-only $Ephemeral
if ($LASTEXITCODE -ne 0) {
    Write-Error "Fast-forward of '$Base' failed unexpectedly after rebase — '$Ephemeral' is rebased; finish manually: git merge --ff-only $Ephemeral"
    exit 1
}
} finally {
    Remove-Item -Path $LockPath -Recurse -Force -ErrorAction SilentlyContinue
}

if ($Worktree) {
    git -C $RepoRoot worktree remove $WtPath
```

Lines 47-108 (both mode branches' rebase logic, the mode-conditional checkout-to-base, and the ff-merge) unchanged, nested one level deeper.

**Changes (`projex-rebase-close.sh`):**

```bash
// Before (lines 51-56):
if [ "$BASE" = "$EPHEMERAL" ]; then
  echo "Error: base and ephemeral branch cannot be the same ('$BASE')" >&2
  exit 1
fi

if [ "$WORKTREE_MODE" = true ]; then

// After:
if [ "$BASE" = "$EPHEMERAL" ]; then
  echo "Error: base and ephemeral branch cannot be the same ('$BASE')" >&2
  exit 1
fi

# Acquire per-base lock (see Step 1 for full rationale).
# ponytail: locks the worktree-mode rebase phase too (touches $WtPath only, not
# $RepoRoot) — one lock/unlock pair spanning rebase+ff-merge is simpler than two
# separate windows with a dead zone between them.
LOCK_DIR="$REPO_ROOT/.git/projex-locks"
mkdir -p "$LOCK_DIR"
SANITIZED_BASE="${BASE//\//_}"
LOCK_PATH="$LOCK_DIR/$SANITIZED_BASE.lock"
if ! mkdir "$LOCK_PATH" 2>/dev/null; then
  echo "Error: another close is already finalizing onto base branch '$BASE' — lock held at '$LOCK_PATH'. Wait for it to finish, then retry." >&2
  exit 1
fi
trap 'rmdir "$LOCK_PATH" 2>/dev/null || true' EXIT

if [ "$WORKTREE_MODE" = true ]; then
```

```bash
// Before (lines 105-111):
if ! git -C "$REPO_ROOT" merge --ff-only "$EPHEMERAL" 2>&1; then
  echo "Error: fast-forward of '$BASE' failed unexpectedly after rebase — '$EPHEMERAL' is rebased; finish manually: git merge --ff-only $EPHEMERAL" >&2
  exit 1
fi

if [ "$WORKTREE_MODE" = true ]; then
  if ! git -C "$REPO_ROOT" worktree remove "$WT_PATH" 2>&1; then

// After:
if ! git -C "$REPO_ROOT" merge --ff-only "$EPHEMERAL" 2>&1; then
  echo "Error: fast-forward of '$BASE' failed unexpectedly after rebase — '$EPHEMERAL' is rebased; finish manually: git merge --ff-only $EPHEMERAL" >&2
  exit 1
fi

# Tight release: lock no longer needed once the fast-forward lands.
rmdir "$LOCK_PATH" 2>/dev/null || true

if [ "$WORKTREE_MODE" = true ]; then
  if ! git -C "$REPO_ROOT" worktree remove "$WT_PATH" 2>&1; then
```

**Rationale:** A single lock/unlock pair spans both the mode-conditional rebase step and the always-present ff-merge step. This is deliberately *not* the tightest possible boundary — in worktree mode, the lock is held during the rebase-inside-`$WtPath` phase even though that phase alone doesn't touch `$RepoRoot`. Splitting into two separate lock windows (one narrowly around just the ff-merge in worktree mode) would require mode-conditional acquire/release points and a dead zone between them, adding real complexity for a benefit that's purely about serialization *duration*, not correctness — over-locking here is safe, just marginally more conservative. Flagged with a `ponytail:` comment in the code and as a Risk in Notes below.

**Verification:** Same four checks as Step 1, adapted:
1. `bash -n projex-rebase-close.sh`; PowerShell AST parse for `.ps1`
2. Contention test in both worktree and checkout mode (confirm the lock triggers even during what would be the worktree-only rebase phase)
3. Happy-path test in both modes — confirm rebase + fast-forward lands correctly, lock dir gone afterward
4. Forced rebase-conflict test — confirm the script's existing `rebase --abort` + restore-original-branch path still runs, and the lock is released (via `trap`/`finally`) despite the early exit

**If this fails:** `git checkout -- projex-rebase-close.ps1 projex-rebase-close.sh`.

---

### Step 4: `projex-abandon.ps1` / `.sh`

**Objective:** Lock only needed in checkout mode (`checkout $Base` mutates `$RepoRoot`). Worktree mode's `git worktree remove` never touches `$RepoRoot`'s checked-out state — no lock there.
**Confidence:** High
**Depends on:** None

**Files:**
- `projex-abandon.ps1`
- `projex-abandon.sh`

**Changes (`projex-abandon.ps1`):**

```powershell
// Before (lines 39-55):
if ($Worktree) {
    # Worktree mode: remove worktree (already on base branch)
    $WtSuffix = ($Ephemeral -split '/')[-1]
    $WtBase = Join-Path $RepoRoot ".projexwt"
    $WtPath = Join-Path $WtBase $WtSuffix
    git -C $RepoRoot worktree remove $WtPath --force
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Could not remove worktree '$WtPath' — remove manually: git worktree remove $WtPath --force"
    }
} else {
    # Checkout mode: switch to base
    git -C $RepoRoot checkout $Base
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Could not checkout '$Base' — still on '$Ephemeral', nothing lost"
        exit 1
    }
}

// After:
if ($Worktree) {
    # Worktree mode: remove worktree (already on base branch) — no lock needed,
    # this never touches $RepoRoot's checked-out state.
    $WtSuffix = ($Ephemeral -split '/')[-1]
    $WtBase = Join-Path $RepoRoot ".projexwt"
    $WtPath = Join-Path $WtBase $WtSuffix
    git -C $RepoRoot worktree remove $WtPath --force
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Could not remove worktree '$WtPath' — remove manually: git worktree remove $WtPath --force"
    }
} else {
    # Checkout mode: switch to base — this mutates $RepoRoot, needs the per-base lock.
    $LockDir = Join-Path (Join-Path $RepoRoot ".git") "projex-locks"
    New-Item -ItemType Directory -Path $LockDir -Force | Out-Null
    $SanitizedBase = $Base -replace '/', '_'
    $LockPath = Join-Path $LockDir "$SanitizedBase.lock"
    try {
        New-Item -ItemType Directory -Path $LockPath -ErrorAction Stop | Out-Null
    } catch {
        Write-Error "Another close is already finalizing onto base branch '$Base' — lock held at '$LockPath'. Wait for it to finish, then retry."
        exit 1
    }

    try {
        git -C $RepoRoot checkout $Base
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Could not checkout '$Base' — still on '$Ephemeral', nothing lost"
            exit 1
        }
    } finally {
        Remove-Item -Path $LockPath -Recurse -Force -ErrorAction SilentlyContinue
    }
}
```

**Changes (`projex-abandon.sh`):**

```bash
// Before (lines 52-64):
if [ "$WORKTREE_MODE" = true ]; then
  # Worktree mode: remove worktree (already on base branch)
  WT_PATH="${REPO_ROOT%/}/.projexwt/${EPHEMERAL##*/}"
  if ! git -C "$REPO_ROOT" worktree remove "$WT_PATH" --force 2>&1; then
    echo "Warning: could not remove worktree '$WT_PATH' — remove manually: git worktree remove $WT_PATH --force"
  fi
else
  # Checkout mode: switch to base
  if ! git -C "$REPO_ROOT" checkout "$BASE" 2>&1; then
    echo "Error: could not checkout '$BASE' — still on '$EPHEMERAL', nothing lost" >&2
    exit 1
  fi
fi

// After:
if [ "$WORKTREE_MODE" = true ]; then
  # Worktree mode: remove worktree (already on base branch) — no lock needed,
  # this never touches $REPO_ROOT's checked-out state.
  WT_PATH="${REPO_ROOT%/}/.projexwt/${EPHEMERAL##*/}"
  if ! git -C "$REPO_ROOT" worktree remove "$WT_PATH" --force 2>&1; then
    echo "Warning: could not remove worktree '$WT_PATH' — remove manually: git worktree remove $WT_PATH --force"
  fi
else
  # Checkout mode: switch to base — this mutates $REPO_ROOT, needs the per-base lock.
  LOCK_DIR="$REPO_ROOT/.git/projex-locks"
  mkdir -p "$LOCK_DIR"
  SANITIZED_BASE="${BASE//\//_}"
  LOCK_PATH="$LOCK_DIR/$SANITIZED_BASE.lock"
  if ! mkdir "$LOCK_PATH" 2>/dev/null; then
    echo "Error: another close is already finalizing onto base branch '$BASE' — lock held at '$LOCK_PATH'. Wait for it to finish, then retry." >&2
    exit 1
  fi
  trap 'rmdir "$LOCK_PATH" 2>/dev/null || true' EXIT

  if ! git -C "$REPO_ROOT" checkout "$BASE" 2>&1; then
    echo "Error: could not checkout '$BASE' — still on '$EPHEMERAL', nothing lost" >&2
    exit 1
  fi

  # Tight release: lock no longer needed once checkout succeeds.
  rmdir "$LOCK_PATH" 2>/dev/null || true
fi
```

**Rationale:** This is the one script where the two modes genuinely differ in whether locking applies at all — worktree-mode abandon is already fully isolated (per the human's grounding, confirmed by reading the code: `git worktree remove` only removes the worktree registration, never touches `$RepoRoot`'s HEAD/index/working tree). Locking it would be pure unneeded serialization with zero safety benefit, so it's correctly excluded.

**Verification:**
1. `bash -n projex-abandon.sh`; PowerShell AST parse for `.ps1`
2. Contention test in checkout mode only (worktree mode should proceed unaffected even with the lock pre-held, since it never checks the lock)
3. Happy-path test in both modes — confirm branch abandoned, base checked out (checkout mode) or worktree removed (worktree mode), lock dir absent afterward in checkout mode
4. Forced-failure test: checkout mode with a nonexistent/corrupt base ref forcing `checkout $Base` to fail — confirm exit 1 with existing error message and lock released

**If this fails:** `git checkout -- projex-abandon.ps1 projex-abandon.sh`.

---

## Verification Plan

> Per-step verification (above) confirms each script in isolation. This section confirms the four scripts work together correctly under the specific concurrency scenario the human described.

### Automated Checks
- [ ] `bash -n` syntax check passes for all 4 `.sh` files
- [ ] PowerShell AST parse passes for all 4 `.ps1` files
- [ ] Every forced-failure test (per step) confirms the lock directory is absent after the script exits, regardless of exit path

### Manual Verification
- [ ] **Same-base mutual exclusion:** in a scratch repo, pre-create `.git/projex-locks/main.lock`, then run any one of the 4 scripts targeting base `main` — confirm immediate fail-fast with the contention error naming `main`, no `$RepoRoot` mutation occurred (verify `git status`/`git log` on `main` unchanged)
- [ ] **Different-base concurrency preserved:** pre-create `.git/projex-locks/develop.lock` (a *different* base than the one under test), then run a script targeting base `main` — confirm it proceeds normally, unaffected by the `develop` lock
- [ ] **Branch-name sanitization parity:** for a branch name containing `/` (e.g. `projex/2607140251-test`), confirm `.ps1`'s `$Base -replace '/', '_'` and `.sh`'s `${BASE//\//_}` produce byte-identical lock filenames (manually diff the two computed paths)
- [ ] **No lock leakage on success:** after a full successful run of each of the 4 scripts (happy path), confirm `.git/projex-locks/` contains no leftover lock directory for the branch just processed

### Acceptance Criteria Validation

| Criterion | How to Verify | Expected Result |
|-----------|---------------|-----------------|
| Per-base (not global) locking | Different-base concurrency test above | Lock on branch A does not block a close targeting branch B |
| Atomic acquisition | Code review: `New-Item -ItemType Directory` / `mkdir` with no separate existence check | No TOCTOU window — single atomic syscall |
| Fail-fast, no retry loop | Code review of all 8 files | No `sleep`/loop/backoff constructs anywhere in the lock logic |
| Release on every exit path | Forced-failure test per step (4 scripts × their existing failure branches) | Lock directory absent after every failure exit, not just success |
| `.ps1`/`.sh` identical lock path | Sanitization parity test above | Byte-identical computed lock filename for the same branch name |
| Abandon worktree-mode has no lock | Code review + contention test (worktree mode unaffected by a pre-held lock) | Worktree-mode abandon proceeds even with the base's lock pre-held by another process |

---

## Rollback Plan

Per-step rollback (above) reverts each file pair independently via `git checkout -- <file1> <file2>`. If the overall change must be abandoned after all 8 files are modified:

1. `git checkout -- projex-squash-close.ps1 projex-squash-close.sh projex-merge-close.ps1 projex-merge-close.sh projex-rebase-close.ps1 projex-rebase-close.sh projex-abandon.ps1 projex-abandon.sh`
2. Confirm `git status --porcelain` shows no changes to these 8 files
3. No other state is touched by this plan — no lock directories persist outside of an active script run (each lock is created and removed within a single script invocation), so no cleanup beyond the file revert is needed

---

## Notes

### Risks

- **Residual cross-*different*-base race in checkout mode:** two concurrent *checkout-mode* closes targeting **different** base branches still both mutate the single shared `$RepoRoot` working directory/index (checkout to base A vs. checkout to base B can't both hold at once regardless of per-branch locks). This is explicitly out of scope — the human's requirement is "solo per N," not a global lock, and worktree mode (SKILL.md's existing recommended path for concurrent execution scenarios) is the actual mitigation for this residual case, not a new fix in this plan. Flagged here so the human can decide later whether checkout-mode's cross-base race warrants a follow-up (e.g. a small note in `close-projex.md` recommending worktree mode when parallel closes are expected).
- **`projex-rebase-close` over-locks slightly in worktree mode:** the lock is held during the worktree-only rebase phase (which doesn't touch `$RepoRoot`), not just the final ff-merge. This trades a small amount of unnecessary serialization for a simpler single lock/unlock pair (see Step 3 Rationale). Marked with a `ponytail:` comment in the code so a future pass can narrow it if this measurably matters.
- **Stale lock on process kill:** if a script is killed with `SIGKILL`/`taskkill /F` (not a normal exit), neither the PowerShell `finally` nor the bash `trap EXIT` runs, leaving a stale lock directory. No automatic stale-lock detection/expiry is included (would require a retry/staleness-check mechanism, explicitly out of scope per the fail-fast-only requirement). Recovery is manual: `rmdir <repo>/.git/projex-locks/<branch>.lock` (or delete the directory). Worth a one-line mention in the script's error message if this becomes a real recurring issue — not addressed now.

### Open Questions

*(none — all design choices resolved above; see Sanitization scheme and Shared-helper-vs-duplication decision in Implementation Overview)*
