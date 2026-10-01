# Patch: projex-tree Relative Repo Root

> **Status:** Complete
> **Author:** Opus 5.5 (patch subagent, orchestrated)
> **Parent:** 2610011956-projex-tree-native-port-audit.md
> **Related Projex:** 2610011956-projex-tree-native-port-audit.md | 2610010506-projex-tree-native-port-plan.md | 2610010506-projex-tree-native-port-log.md
> **Directive:** Patch the small code-level findings of 2610011956-projex-tree-native-port-audit.md (Significant finding + Final Verdict condition, Rule 6 gaps, in-process output note).
> **Source Plan:** Direct (audit findings on 2610010506-projex-tree-native-port-plan.md, branch `projex/2610010506-projex-tree-native-port`)
> **Result:** Success

---

## Summary

`projex-tree.ps1` resolved a relative `<repo-root>` against the .NET process CWD, not the PowerShell location → in-process `& projex-tree.ps1 <rel> X` after `Set-Location` walked a different directory (audit Significant finding, Final Verdict condition). Fix: join relative root to the session's FileSystem location. Added a relative-repo case to both suites (pwsh case runs in-process inside a child session whose process CWD differs from `$PWD` — reproduces the bug; fail-first confirmed `exit 2`). Added the 5 Rule 6 rationale comments and documented the in-process output limitation in the `Emit` comment.

Code commit: 496c445 (`Projex: 2610012008-projex-tree-relative-repo-root` trailer).

---

## Changes

### PowerShell engine

**File:** `projex-tree.ps1`
**Change Type:** Modified
**What Changed:**
- Repo-root block (lines 47–61): `$Full = [IO.Path]::GetFullPath($RepoRoot, (Get-Location -PSProvider FileSystem).ProviderPath)`; `[IO.Directory]::Exists($Full)` / `DirectoryInfo($Full)` replace the one-argument forms. Comment states rejected alternative (one-arg `GetFullPath` / `Directory.Exists` use process CWD, which `Set-Location` does not move). Non-filesystem-drive rejection kept (`Env:\` → `E_REPO`).
- `Emit` comment (lines 31–33): raw bytes bypass the pipeline → in-process caller cannot capture/redirect; capture via child `pwsh -File`.

**Why:** Audit condition; regression vs old wrapper and `projex-list.ps1`. `-PSProvider FileSystem` → current location on a non-filesystem drive (e.g. `Env:`) still yields the last filesystem location, not a provider path.

### Bash engine

**File:** `projex-tree.sh`
**Change Type:** Modified (comments only)
**What Changed:**
- `load`: rationale for `close(path)` (fd exhaustion on BWK awk / mawk) and for `gsub(/\000/, "", t)` (UTF8 byte regex starts at `\001`).
- Pipeline before `PT_NESTED` / `PT_TARGET`: `ENVIRON` vs rejected `awk -v` (backslash-escape processing mangles names holding `\`).

**Why:** Audit Source Hygiene Rule 6 gaps. Bash engine already resolved relative roots via `cd` — no behavior change.

### Test suites

**Files:** `tests/projex-tree.test.ps1` | `tests/projex-tree.test.sh` | `tests/README.md`
**Change Type:** Modified
**What Changed:**
- ps1: `InvokeTree` split into `InvokePwsh(Lead, Argv, Dir)` (adds optional `WorkingDirectory`) + thin `InvokeTree` wrapper. New `relative-repo` case: child `pwsh -Command "Set-Location <temp>; & <tree> dp <doc>"` started with process CWD = repo root; byte-exact exit/stdout/stderr vs `basic/expected.stdout`.
- sh: new `relative-repo` case (`cd "$tmp"`, repo arg `dp`, `cd "$OLDPWD"`); rationale comment on `expect`'s `</dev/null`.
- Both: `nulparent` comment — `nul` is a Windows reserved device name (spurious `E_REPO`).
- `tests/README.md`: count 205 → 208 each; coverage text names relative repo root.

**Why:** Audit asked for suite coverage of the regression; sh/ps1 parity kept (3 assertions each).

---

## Verification

**Method:** Fail-first ps1 run before engine fix; both suites after; in-process probes; ASCII check.

**Result:**
```
before fix (ps1): FAIL: relative-repo: exit 2, expected 0 ... PASS=205 FAIL=3
bash tests/projex-tree.test.sh                     → PASS=208 FAIL=0
pwsh -NoProfile -File tests/projex-tree.test.ps1   → PASS=208 FAIL=0
in-process: Set-Location tests/fixtures/projex-tree; & projex-tree.ps1 basic 2608051553-feature-proposal.md → tree, rc=0
in-process: Set-Location Env:; same call → tree, rc=0
in-process: & projex-tree.ps1 'Env:\' … → projex-tree: E_REPO: Env:\: repository root not found, rc=2
LC_ALL=C grep -c '[^[:print:][:space:]]' (both engines, both suites) → 0
```

**Status:** PASS

---

## Impact on Related Projex

| Document | Relationship | Update Made |
|----------|-------------|-------------|
| 2610011956-projex-tree-native-port-audit.md | Parent (patched subject) | None — auxiliary, uncommitted-by-policy text left as authored; condition satisfied by this patch |
| 2610010506-projex-tree-native-port-log.md | Execution log | Step 4 deviation equivalence claim annotated as superseded by this patch |

---

## Notes

Deliberately left (outside patch scope or for close):
- **Unpromoted sh↔ps1 differential harness + C1–C9 / D1–D9 contract** → audit labels larger; fits close's rationale promotion or a follow-up plan.
- **In-process output capture redesign** (`Emit` raw streams) — design change shared with `projex-list.ps1`; only documented here.
- **Log `## Data Gathered` wrong cause** (dangling audits exist nowhere) and **plan Verification Plan checkboxes / "any real doc exits 0" over-claim** → audit routes to close doc touch-up.
- **Undeclared edge deltas:** symlinked repo root basename (`pwd -P`) — accepted; POSIX pwsh reading non-regular `.md` (FIFO) — sh/ps1 parity gap, unverifiable on this Windows host, needs a POSIX probe → follow-up.
- Scaffold emitted `> **Status:** Closed` — non-canonical; set to `Complete`.
