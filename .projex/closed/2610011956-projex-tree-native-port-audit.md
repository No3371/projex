# Audit: projex-tree Native Port

> **Status:** Complete (Accepted with Conditions - Conditions Met)
> **Author:** Opus 5.5 (audit subagent, orchestrated)
> **Parent:** 2610010506-projex-tree-native-port-plan.md
> **Related Projex:** 2610010506-projex-tree-native-port-plan.md | 2610010506-projex-tree-native-port-log.md | 2610010520-projex-tree-native-port-plan-stress.md
> **Audit Date:** 2026-10-01 | **Auditor:** Opus 5.5 | **Work Period:** 2026-10-01 06:40–09:10
> **Subject:** `main..projex/2610010506-projex-tree-native-port` (817309b … ce2dc52, 7 commits)

---

## Audit Summary

**Claim:** `projex-tree` became pure bash + PowerShell (no Python), behavior pinned by C1–C9 contract + shared fixtures, deltas vs Python limited to D1–D9, both suites green at equal counts, autocrlf-proof, `.projex-tree.py` deleted.

**Verdict:** Verified

**Assessment:** Completeness: High | Correctness: Medium-High | Quality: High | Value: High

**Top Issues:**
1. `projex-tree.ps1` resolves a relative `<repo-root>` against the .NET process CWD, not PowerShell `$PWD` → in-process call (`& projex-tree.ps1 . X`) after `Set-Location` reports `E_REPO` / `E_TARGET_NOT_FOUND` or silently trees a **different repo**. Regression vs old wrapper and vs `projex-list.ps1`; introduced by the Step 4 deviation the log calls "same literal-path semantics".
2. `projex-tree.ps1` payload bypasses the PowerShell pipeline (raw `OpenStandardOutput`) → in-process `$t = & projex-tree.ps1 …` captures 0 lines (old wrapper: 5). Shared with `projex-list.ps1` precedent.
3. Sh↔ps1 differential harness and C1–C9 contract live only in projex documents (log/plan) — the plan's own Risk says rerun it on every engine edit, but nothing shipped carries it.

---

## Claims vs Evidence

| Claim | Evidence | Status | Notes |
|-------|----------|--------|-------|
| 6 steps Success | 6 step commits 817309b…51ba575 + log entries | ✓ | Commit scopes match step file lists |
| `.projex-tree.py` deleted, no Python refs | `git grep -i python HEAD -- . ':(exclude,glob)**/.projex/**'` → none | ✓ | |
| Both suites 205/205 | Re-ran in worktree: `PASS=205 FAIL=0` each (bash 35 s) | ✓ | |
| Summary line runner-parseable | Both print `PASS=n FAIL=n` | ✓ | |
| Fresh autocrlf clone passes | Re-ran: `git -c core.autocrlf=true clone -b <branch>` → scripts `w/crlf`, both suites `PASS=205 FAIL=0` | ✓ | Clone removed |
| Zero sh↔ps1 mismatches; 6 Python mismatches all D2/D3 | Re-ran logged harness with Python oracle from `main:.projex-tree.py` (scratch) | ✓ | See Testing Validation |
| ASCII-only engines, no `\`-newline continuation | `LC_ALL=C grep -c '[^[:print:][:space:]]'` → 0 on both engines + both suites; `grep -c '[\]$'` → 0 | ✓ | |
| No gawk-only features | grep `asort|/dev/stderr|{n}|gensub|PROCINFO|BEGINFILE` → none | ✓ | |
| `new-projex.test.ps1` / `close-precheck.test.ps1` failures pre-existing | Re-ran: `PASS=188 FAIL=1` ("creator inventory" = spec-inventory check) and close-precheck failures; neither suite nor its subject in the diff | ✓ | Not re-run on `main`; unchanged inputs |
| Two real docs exit 3 because Parent audits "exist only untracked in the base checkout" | `2608121912-…-audit.md`, `2608130624-…-audit.md`: absent from disk (base + worktree) and from all git history | ⚠ | Conclusion (pre-existing content error, not fixture-caused) holds; stated cause wrong |
| Success criterion "tree on any real doc exits 0" | Same 2 docs exit 3 | ⚠ | Intent (no fixture poisoning, no `E_IO`) met; wording over-claims |
| Step 4 deviation: `[IO.Directory]::Exists` + `GetFullPath` = "same literal-path semantics" as `Test-Path`/`Resolve-Path` | Probe below | ✗ | Relative paths resolve against process CWD, not `$PWD` |

---

## Objective Verification

### Objective 1: Remove Python runtime dependency
**Evidence:** 51ba575 (`del-n-stage` of `.projex-tree.py`), README row, grep.
**Verification:** ✓ Verified

### Objective 2: Fix Windows CRLF output, nested-repo pruning, nested `.projex` double-walk, runner summary
**Evidence:** D1 goldens byte-compared (`cmp` / byte arrays); `nested-repo` (+`.git` dir/file/`.GIT`) and `nested-projex` cases; summary format.
**Verification:** ✓ Verified — hidden-attribute probe also passes (hidden `.md` included, Hidden `vendor/.git` pruned, sh = ps1).

### Objective 3: autocrlf-independent fixtures
**Evidence:** `.gitattributes` `tests/fixtures/projex-tree/** -text`; fresh-clone run.
**Verification:** ✓ Verified

---

## Code/Implementation Inspection

### `projex-tree.sh`

**Claimed:** native engine — `find` + `\001`/`\002` walk key + `LC_ALL=C sort` + single awk engine.
**Actual:** as claimed — Quality: High. Chain/BFS a faithful transliteration of Python `main()` lines 82–160; omitted lines 154, 161–165, `check_cycle` are dead under the stated tree argument (verified against Python source on `main`). C4 separators, C5 strip set, `NAME_RE`, one-BOM strip, NUL-safe file capture, tuple error sort all match contract. `cd -P` / `CDPATH=''` / `./-` guards present.

**Issues Found:**
- Rule 6 gaps (see Source Hygiene) — Low.
- Symlinked repo root: `pwd -P` basename decides the repo-is-`.projex` rule; Python used `abspath` basename (no link resolution). Undeclared delta, rare — Low.

**Undocumented:** none beyond log Deviations.

### `projex-tree.ps1`

**Claimed:** native .NET engine, no `param`/`CmdletBinding`, ordinal everything, UTF-8 byte order comparer, raw-byte output.
**Actual:** as claimed — Quality: High, except repo-root resolution.

**Issues Found:**
- **Relative repo root vs `$PWD`** — Severity: Significant (Medium). `[IO.Directory]::Exists($RepoRoot)` / `[IO.Path]::GetFullPath($RepoRoot)` resolve against `[Environment]::CurrentDirectory`; PowerShell `Set-Location` does not move it. Probe (scratch repo with one doc, `Set-Location` there, `& projex-tree.ps1 . 2610019999-only-here-plan.md`): `PWD=…\scratchpad\audit\rel procCWD=…\2610010506-projex-tree-native-port` → `projex-tree: E_TARGET_NOT_FOUND …`, exit 2 — it walked the worktree instead. From `tests/fixtures/projex-tree`, `& projex-tree.ps1 basic …` → `E_REPO: basic`; old wrapper on `main` → correct tree. `projex-list.ps1` uses `Resolve-Path` and is unaffected. Suite misses it: every invocation is a child `pwsh -File`, where process CWD = `$PWD`.
- **In-process output not capturable** — Severity: Low. `Emit` writes `[Console]::OpenStandardOutput()`/`OpenStandardError()`; `$x = & projex-tree.ps1 <abs> <doc>` → `captured count=0` while the tree still prints to the console (old wrapper: 5 lines captured). `2>$null` cannot silence errors in-process either. Same trade as `projex-list.ps1` (guarantees LF bytes).
- Non-regular files: on POSIX pwsh, any non-directory `.md` entry (FIFO, socket) is read; bash `-type f` skips it. Edge — Low.

**Metrics:** Readability High | Test coverage: every contract clause has a case | Technical debt: Low.

### Tests (`tests/projex-tree.test.{sh,ps1}`, fixtures)

46 legacy + 159 new assertions, mechanically parallel, byte-exact (`cmp -s` / byte arrays), runtime-only invalid/NUL/link/ACL inputs. pwsh `InvokeTree` uses `ProcessStartInfo.ArgumentList` + raw streams — sound. Gaps: no relative repo-root case; no in-process pwsh invocation.

---

## Testing Validation

**Coverage:** C1–C9, D1–D9, UTF-8 table (20 rows), links, ACL denial — all present; no SKIP on this host.
**Execution:** All pass? Yes — worktree 205/205 ×2; fresh autocrlf clone 205/205 ×2. Flaky: none seen.
**Differential re-run** (logged harness, Python oracle from `main:.projex-tree.py`, scratch only): `RUNS: fixtures=37 corpus=107 utf8=20` | `CORPUS EXIT-0: sh=99 ps=99 py=97` | `SH-PS MISMATCH: 0` | `SH-PY MISMATCH: 6` — nested-projex root/inner ×2 (fixture + corpus) → D3; nested-repo+git host/vendored → D2. Matches the log exactly.
**Missing:** relative `<repo-root>` (both engines); in-process `& projex-tree.ps1`; non-gawk awk (acknowledged Risk, unverifiable here).
**Quality Issues:** none — assertions are byte-level, not substring.

---

## Documentation Audit

**Completeness:** README + tests/README rows updated — Complete. Engine headers state usage, exit codes, output encoding, filename assumption.
**Accuracy:** Matches implementation? Yes. Log: one wrong cause (dangling audits "untracked in base" — they exist nowhere) and one wrong equivalence claim (Step 4 deviation).
**Quality:** High. Plan `## Verification Plan` checkboxes left unticked though Success Criteria ticked — doc hygiene only.

---

## Source Hygiene

**Scope:** Diff only (`main..projex/2610010506-projex-tree-native-port`, `.projex/**` excluded)

| Rule | Location (symbol) | Quote | Severity |
|------|-------------------|-------|----------|
| 1–5 | — | none found (fixture IDs in goldens/test args are data, not comments) | — |

**Rule 6 gaps** (non-obvious change, no rationale comment):
- `tests/projex-tree.test.sh` → `expect` — engine run with `</dev/null` — without it a child drains the `utf8-cases.tsv` loop's stdin and the loop runs once (log Deviation); a cleanup pass would delete the redirect.
- `tests/projex-tree.test.ps1` / `.sh` → NUL-Parent case temp dir `nulparent` — `nul` is a Windows reserved device name (spurious `E_REPO`); a rename to the obvious `nul` reintroduces it.
- `projex-tree.sh` → `engine` / `load` — `gsub(/\000/, "", t)` before the `UTF8` match — the byte regex starts at `\001`; NUL is valid but unmatched; reader cannot tell the strip is load-bearing.
- `projex-tree.sh` → `PT_TARGET` / `PT_NESTED` via `ENVIRON` — rejected alternative `awk -v` processes backslash escapes (mangles POSIX paths holding `\`); unstated.
- `projex-tree.sh` → `load` → `close(path)` — fd exhaustion on BWK/mawk without it; unstated.

**Rule 6 vacuity:** none — existing rationale comments name the rejected alternative (`cd -`/CDPATH, raw-path sort, `$(...)` NUL loss, `CmdletBinding`, culture `StartsWith`, `CompareOrdinal`, `TrimStart`, `Test-Path`, `ReparsePoint`, console writers, `pwsh 2>file`).

**Rationale promotion:** no walkthrough yet (close pending). Unpromoted: (a) the sh↔ps1 differential harness + "rerun on first edit to either engine" (plan § Risks) — exists only in the execution log; (b) C1–C9 contract and D1–D9 deltas vs the old engine — only in the plan; fixtures encode behavior but not intent. Target: `tests/README.md` (contract summary + harness pointer) and a committed `tests/` harness script.

**Commit composition** (informational — fix forward, never rewrite history): 7 commits checked — typed subject: n/a (ephemeral `projex: step …`; landing subject composed at close) | `Projex:` trailer 5/5 on commits touching files outside `.projex/` (817309b, 0e9476f, ca3753e, 38c2dcc, 51ba575); 4b0b804, ce2dc52 doc-only, exempt.
**Violations:** None.

**Trailer survival on `main`:** 1/30 (798df6f) — not zero, so not Critical. Most sampled commits are direct framework commits (`feat:`/`refactor:`/`docs:`), not projex landings; 2df4acf (squash landing of named-new-projex plan) lacks one — informational.

---

## Gap Analysis

### Promised But Not Delivered
| Promise | Status | Impact |
|---------|--------|--------|
| "Harness command set … reusable as the sh↔ps1 cross-check after Python is gone" | Partial — in log only, not shipped | Medium |

### Undocumented Issues
| Issue | Severity | Affects |
|-------|----------|---------|
| ps1 relative repo root resolves against process CWD | Significant | in-process PowerShell callers using relative paths |
| ps1 output not capturable in-process | Low | callers assigning/piping output |
| Symlinked repo root resolved for `.projex` basename rule (Python did not) | Low | rare repo layouts |

### Unhandled Edge Cases
- Relative `<repo-root>` from an in-process PowerShell session — wrong repo, no error when target name also exists there.
- Non-regular `.md` entries on POSIX pwsh — blocking read on a FIFO.

---

## Quality Assessment

### Completeness: High
**Strengths:** every contract clause and delta has a byte-exact case; corpus-poison guard; non-vacuity check; autocrlf proof.
**Gaps:** harness/contract unpromoted; relative-path case.

### Correctness: Medium-High
**Works:** tree, errors, ordering, UTF-8, links, nested repos, CRLF/autocrlf: Yes.
**Bugs:** ps1 relative repo root vs `$PWD` — Severity: Significant.

### Code Quality: High
**Positive:** ASCII-only, autocrlf-immune, no external processes in pwsh, dead Python branches removed with a stated proof, strong rationale comments.
**Concerns:** five Rule 6 gaps.
**Tech Debt:** ~30 synthetic fixture docs (twins, dup Parents, `Zeta.md`) now in this repo's corpus (acknowledged plan Risk) — Low.

### Value Delivered: High
**Intended:** Python-free, working-on-Windows tree utility.
**Actual:** delivered; two Python bugs fixed; suites green and runner-parseable.
**Impact:** User: Positive.

---

## Open Findings

### Undocumented Discoveries
- Changes: none outside the log's Deviations.
- Problems: ps1 `$PWD` regression — Evidence: probe above; Step 4 deviation text.
- Workarounds: pwsh suite invokes via child `pwsh -File` — sound for byte capture, but masks in-process behavior.

### Impact Analysis
- Downstream: `close-projex.md` / `conclude-projex.md` pass `<repo-root>` (absolute by convention) → exposure limited to ad-hoc relative calls.
- Future: Enabled: Python-free hosts. Blocked: none.
- Risks: engine drift between sh/ps1 after close without a shipped harness — Likelihood: Medium.

### Improvements
- Could be better: resolve repo root via `$ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($RepoRoot)` (filesystem-only check kept) or `[IO.Path]::GetFullPath($RepoRoot, $PWD.ProviderPath)`.
- Would make excellent: committed `tests/projex-tree.diff.sh` (sh↔ps1 mode) wired into `run-all`.

---

## Stakeholder Impact

| Stakeholder | Promised | Reality | Impact |
|-------------|----------|---------|--------|
| Human (no-Python rule) | pure bash + PowerShell utility | delivered | Positive |
| Agents on Windows | working tree in close/conclude | works with absolute `<repo-root>`; relative in-process call misresolves | Positive |

---

## Findings

### Critical (Must Address)
- None.

### Significant (Should Address)
- **ps1 relative `<repo-root>` resolves against process CWD, not `$PWD`** — silent wrong-repo result for in-process calls; regression vs old wrapper and `projex-list.ps1`. → Small code fix in `projex-tree.ps1` (top-level repo-root block): resolve against `$PWD.ProviderPath` before `[IO.Directory]::Exists`; add a suite case running the engine in-process (`& $Tree . <doc>` after `Set-Location`) plus a relative-path case for bash.

### Minor (Nice to Fix)
- **Rule 6 gaps** (5 sites, Source Hygiene) → small comment additions.
- **In-process output not capturable** (`Emit` raw streams) → document in README / script header, or design change shared with `projex-list.ps1` (larger; out of this plan's scope).
- **Unpromoted harness + contract** → commit the sh↔ps1 harness under `tests/`, summarize C1–C9 / filename assumptions in `tests/README.md` (larger; fits close's rationale promotion or a follow-up patch).
- **Log inaccuracies** → `## Data Gathered` cause of the 2 dangling Parents (docs exist nowhere, not "untracked in base"); Step 4 deviation equivalence claim.
- **Plan `## Verification Plan` checkboxes unticked**; Success Criterion "any real doc exits 0" over-claims (2 pre-existing exit-3 docs) → doc touch-up at close.
- **Undeclared edge deltas** (symlinked repo root basename; POSIX non-regular files in ps1) → note in script header or accept.

### Positive
- Contract-first execution: fail-first fixtures, every delta enumerated and suite-covered, Python kept as oracle until proven redundant.
- Executor's numbers reproduced exactly (205/205 ×2, fresh clone, harness counts).
- Fixture poisoning caught and designed out before commit; NUL/CRLF/autocrlf traps handled deliberately.

---

## Recommendations

**Immediate:** patch `projex-tree.ps1` repo-root resolution + in-process/relative suite cases; add the five Rule 6 comments.
**Future:** ship the sh↔ps1 harness; align `projex-list.ps1` header-grammar quirks (plan Sibling observations).
**Process:** when a deviation replaces a sketched API, probe the replaced semantics (relative paths, provider paths) rather than asserting equivalence.

---

## Final Verdict

**Status:** Accept with Conditions

**Overall Assessment:**
- Completeness: High
- Correctness: Medium-High
- Quality: High
- Value: High

**Conditions:**
- [x] `projex-tree.ps1` resolves a relative `<repo-root>` against `$PWD` (with suite case), or the limitation is documented as accepted by the human

**Sign-off:** Yes, conditional — claims verified and reproduced; one small, well-scoped regression in the PowerShell entry remains.
