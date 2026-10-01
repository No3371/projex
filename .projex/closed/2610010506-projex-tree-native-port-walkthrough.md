# Walkthrough: projex-tree Native Port (bash + PowerShell, no Python)

> **Execution Date:** 2026-10-01
> **Completed By:** Opus 5.5 (execute, audit, patch subagents); Sonnet 5.5 (close)
> **Source Plan:** 2610010506-projex-tree-native-port-plan.md
> **Parent:** 2610010506-projex-tree-native-port-plan.md
> **Duration:** 06:40 to 09:10 execution; audit and patch same day
> **Result:** Success

---

## Summary

`projex-tree` is now a pure native utility: `projex-tree.sh` (bash + `LC_ALL=C` find/sort/awk) and `projex-tree.ps1` (PowerShell 7 / .NET) are self-contained engines, `.projex-tree.py` is deleted, and no Python reference remains outside `.projex/`. Both suites pass 208/208 (205 at execution, 3 added by the patch) with identical counts. An audit found one significant regression (relative `<repo-root>` resolved against the process CWD in the PowerShell engine); a patch fixed it and the audit condition is met.

---

## Objectives Completion

| Objective | Status | Notes |
|-----------|--------|-------|
| Remove the Python runtime dependency | Complete | `.projex-tree.py` deleted (51ba575); `git grep -i python` outside `.projex/` is empty |
| Fix Windows CRLF output, nested-repo pruning, nested `.projex` double-walk, runner summary line | Complete | LF UTF-8 goldens byte-compared; D2/D3 cases; suites print `PASS=n FAIL=n` |
| Make fixture goldens independent of `core.autocrlf` | Complete | `tests/fixtures/projex-tree/** -text`; fresh autocrlf clone passes both suites |
| Preserve CLI, tree rendering, error codes, exit codes | Complete | Contract C1-C9 pinned; only deltas D1-D9 differ from the Python engine |

---

## Execution Detail

> Derived from `git log main..projex/2610010506-projex-tree-native-port` and the execution log.

### Step 1: Pin fixture line endings

**Planned:** Create `.gitattributes` with a `-text` rule for the projex-tree fixtures; re-materialize the fixtures.
**Actual:** Appended one line to the existing `.gitattributes` (created earlier by 5ce0c28 for `projex-list`); re-checked-out the fixtures. Every fixture row reports `w/lf`, `attr/-text`.
**Deviation:** File already existed, so the line was appended rather than the file created. No outcome impact.

| File | Change Type | Planned? | Details |
|------|-------------|----------|---------|
| `.gitattributes` | Modified | Yes | +1 line |

**Verification:** `git ls-files --eol` over the fixtures; baseline suite `PASS=39 FAIL=7` (Python CRLF output), as expected.

### Step 2: Contract fixtures and suites (fail-first)

**Planned:** Six fixture directories plus a UTF-8 table; extend both suites mechanically in parallel.
**Actual:** Added `nested-projex`, `nested-repo`, `sort-order`, `header-quirks`, `error-order`, `io-order` fixtures and `utf8-cases.tsv` (20 rows); extended both suites from 46 to 205 assertions, byte-exact (exit, stdout, stderr). Goldens were confirmed against the Python engine (CR stripped) before commit. Link and ACL-denial cases ran with no SKIP on this host.
**Deviation:** `nested-repo` vendored doc placed at `vendor/.projex/` (so the no-`.git` case stays a Python-parity case); link cases also assert the root target; NUL-Parent temp dir named `nulparent` (`nul` is a Windows reserved device name); bash `expect` runs the engine with `</dev/null` (a child otherwise drains the TSV loop's stdin); two pwsh cases moved to a raw-byte `RunRaw` helper (PowerShell 7.6 rewrites native stderr with CRLF).
**Files Changed (ACTUAL):** `tests/projex-tree.test.sh` (+168), `tests/projex-tree.test.ps1` (+199), `tests/fixtures/projex-tree/**` (new fixture trees and goldens, `utf8-cases.tsv`).
**Verification:** Corpus-poison check (real doc tree exits 0); no backslash-newline continuation; no non-ASCII bytes in either suite.

### Step 3: Bash engine

**Planned:** Rewrite `projex-tree.sh` as a native find/sort/awk engine.
**Actual:** `projex-tree.sh` rewritten (+196/-7): C1 checks, nested-repo prefix list via `find`, walk-key sort with `\001`/`\002` separators, a single stage-3 awk engine (per-line UTF-8 validation, BOM strip, C4 line breaks, C5 header parse, C6 chain/BFS), NUL-safe temp-file capture, tuple-ordered error output.
**Deviation:** None.
**Verification:** Suite `PASS=205 FAIL=0`; CRLF-copy run `PASS=205 FAIL=0`; run with `PATH=/usr/bin:/bin` exits 0.

### Step 4: PowerShell engine

**Planned:** Rewrite `projex-tree.ps1` as a native .NET engine with no `param` block.
**Actual:** `projex-tree.ps1` rewritten (+218/-16): `$args.Count -ne 2` usage rule, raw-byte `Emit` (UTF-8 no BOM, LF), recursive `Walk` with ordinal comparisons, `ReadAllBytes` + strict UTF-8 decode, UTF-8-byte-order comparer, no external process.
**Deviation:** E_REPO uses `[IO.Directory]::Exists` + `[IO.Path]::GetFullPath` instead of the sketched `Test-Path` / `Resolve-Path`. The log called this "same literal-path semantics"; the audit proved it false for relative paths (see Issue 1), and the patch corrected it.
**Verification:** Suite `PASS=205 FAIL=0` (equal to bash).

### Step 5: Differential oracle run

**Planned:** Compare sh, ps1 and the Python oracle over fixtures, the real corpus and the UTF-8 table.
**Actual:** 37 fixture + 107 corpus + 20 UTF-8 runs. `SH-PS MISMATCH: 0`; 6 sh-vs-Python mismatches, all mapped to D2/D3; corpus exit-0 counts sh=99, ps=99, py=97. Fresh autocrlf clone passed both suites. The harness lived only in the session scratchpad (not committed).
**Deviation:** None.

### Step 6: Delete the Python engine; update docs

**Planned:** Delete `.projex-tree.py`; edit two README rows.
**Actual:** `.projex-tree.py` deleted via `del-n-stage`; `README.md` tree row (dropped "requires Python 3"); `tests/README.md` row (205 each plus coverage text).
**Deviation:** None.
**Verification:** `bash tests/run-all.sh` total `PASS=494 FAIL=0`; `run-all.ps1` projex-tree suite green (two unrelated suites fail identically on `main`, see Issue 3).

### Post-execution: audit and patch

- `a42e5da` added `2610011956-projex-tree-native-port-audit.md` (Verified; Accept with Conditions).
- `496c445` (`Projex: 2610012008-projex-tree-relative-repo-root`) fixed the PowerShell relative-root resolution, added a `relative-repo` case to both suites (3 assertions each; fail-first confirmed `exit 2`), added five Rule 6 rationale comments, and noted the in-process output limitation in the `Emit` comment. `bd92466` added the patch document (born closed).

---

## Complete Change Log

> Derived from `git diff --stat main..projex/2610010506-projex-tree-native-port`; fixture files grouped.

### Files Created
| File | Purpose | Lines | In Plan? |
|------|---------|-------|----------|
| `tests/fixtures/projex-tree/{nested-projex,nested-repo,sort-order,header-quirks,error-order,io-order}/**` | Contract fixtures and byte-exact goldens | ~40 files | Yes |
| `tests/fixtures/projex-tree/utf8-cases.tsv` | 20-row UTF-8 validity table | 20 | Yes |
| `.projex/2610010506-projex-tree-native-port-log.md` | Execution log | 163 | Yes |
| `.projex/2610011956-projex-tree-native-port-audit.md` | Audit | 250 | No (lifecycle stage) |
| `.projex/closed/2610012008-projex-tree-relative-repo-root-patch.md` | Patch record | 92 | No (lifecycle stage) |

### Files Modified
| File | Changes | Lines Affected | In Plan? |
|------|---------|----------------|----------|
| `projex-tree.sh` | Native bash engine; rationale comments added by patch | +196/-7 | Yes |
| `projex-tree.ps1` | Native .NET engine; relative-root fix by patch | +218/-16 | Yes |
| `tests/projex-tree.test.sh` | 46 to 208 assertions | +167/-1 | Yes |
| `tests/projex-tree.test.ps1` | 46 to 208 assertions; `InvokePwsh`/`RunRaw` helpers | +196/-3 | Yes |
| `.gitattributes` | `-text` rule for projex-tree fixtures | +1 | Yes |
| `README.md` | Tree row without the Python requirement | 1 line | Yes |
| `tests/README.md` | Counts and coverage text (205 then 208 each) | 1 line | Yes |
| `.projex/2610010506-projex-tree-native-port-plan.md` | Status, success criteria, verification ticks | +10/-9 | Yes |

### Files Deleted
| File | Reason | In Plan? |
|------|--------|----------|
| `.projex-tree.py` | Python engine replaced by native engines | Yes |

### Planned But Not Changed
| File | Planned Change | Why Not Done |
|------|----------------|--------------|
| `close-projex.md`, `conclude-projex.md` | None (interface stable) | Out of scope by design |

---

## Success Criteria Verification

| Criterion | Method | Result | Evidence |
|-----------|--------|--------|----------|
| `.projex-tree.py` deleted; no Python references | `test ! -e`; `git grep -i python` | Pass | Step 6 log entry; audit re-grep |
| Both suites `FAIL=0`, equal counts, parseable summary | Ran both suites | Pass | 205 each at execution; 208 each after patch (re-run in worktree) |
| `run-all` reports projex-tree without the summary warning | `run-all.sh`, `run-all.ps1` | Pass | Step 6 log entry |
| LF UTF-8 no BOM on Windows, both engines | `cmp` / byte-array golden compare | Pass | Suite assertions |
| Differential parity modulo D1-D9, non-vacuous | Step 5 harness; audit re-ran it | Pass | `SH-PS 0`; 6 sh-py mismatches all D2/D3; exit-0 counts sh=99 ps=99 py=97 |
| No committed fixture byte makes `projex-tree` fail on this repo | Corpus check over 64 real docs | Pass, with correction | 62 exit 0; 2 exit 3 (`E_PARENT_DANGLING`), a pre-existing content error. The criterion as worded ("any real doc exits 0") over-claims; its intent (no fixture-induced failure or `E_IO`) is met |
| sh and ps1 agree on C1 for 0/1/3 args, `-`-prefixed extras, empty args | Suite cases | Pass | Suite assertions |
| Fresh scratch clone (autocrlf=true) passes both suites | `git clone -b` and ran both | Pass | `PASS=205 FAIL=0` each (execution and audit) |

**Overall:** 8/8 criteria met (one with the wording correction above).

---

## Deviations from Plan

### Deviation 1: PowerShell E_REPO resolution
- **Planned:** `Test-Path -LiteralPath` + `Resolve-Path`.
- **Actual:** `[IO.Directory]::Exists` + `[IO.Path]::GetFullPath`, later `GetFullPath(root, Get-Location -PSProvider FileSystem)`.
- **Reason:** Avoid PowerShell-drive acceptance and the `Test-Path ''` throw.
- **Impact:** Introduced the relative-root regression (fixed by patch 496c445).
- **Recommendation:** None; plan is closed.

### Deviation 2: Fixture and suite details (Steps 1-2)
- `.gitattributes` appended rather than created; vendored fixture placement; `nulparent` temp dir; `</dev/null`; `RunRaw` helper. All recorded in the log Deviations; no outcome impact.

---

## Issues Encountered

### Issue 1: Relative `<repo-root>` resolved against process CWD (PowerShell)
- **Description:** In-process `& projex-tree.ps1 . X` after `Set-Location` reported `E_REPO` / `E_TARGET_NOT_FOUND` or walked a different repo. Missed by the suite because every invocation was a child `pwsh -File`.
- **Severity:** Medium (Significant)
- **Resolution:** Patch 496c445; `relative-repo` case runs in-process inside a child session whose process CWD differs from `$PWD`.
- **Prevention:** Probe the semantics of a replaced API (relative paths, provider paths) instead of asserting equivalence.

### Issue 2: Tooling artifacts in written files
- **Description:** The file-write tool turned escape text into literal U+00AD / U+2028 / U+2029; bash-tool strings collapsed `\\`.
- **Severity:** Low
- **Resolution:** Non-ASCII grep caught it; `[char]` concatenation used instead.

### Issue 3: Unrelated failing suites on `main`
- **Description:** `tests/new-projex.test.ps1` (`PASS=188 FAIL=1`, "creator inventory") and `tests/close-precheck.test.ps1` (`PASS=17 FAIL=19`) fail identically on `main`; neither is touched by this branch, so `pwsh tests/run-all.ps1` exits nonzero.
- **Severity:** Low (out of scope)
- **Resolution:** Not addressed here.

### Issue 4: Log and plan inaccuracies (corrected at close)
- The log said the two dangling-Parent audits "exist only untracked in the base checkout"; they exist nowhere (absent from disk and all git history). Corrected in the log's Data Gathered.
- Plan Verification Plan checkboxes were left unticked; ticked at close against the log evidence.
- The "any real doc exits 0" criterion over-claimed; annotated in place.

---

## Key Insights

**Rationale promoted:** Partial. The patch promoted the five Rule 6 rationale comments (`close(path)`, NUL strip, `ENVIRON` vs `awk -v`, `</dev/null`, `nulparent`) and the `Emit` in-process limitation into the engines and suites, and `tests/README.md` names the relative-root coverage. **Not promoted (open):** the sh-to-ps1 differential harness with its "rerun on the first edit to either engine" rule (the full script survives only in the execution log's Step 5 entry), and the C1-C9 contract and D1-D9 deltas (survive only in the plan). Target per the audit: `tests/README.md` plus a committed `tests/` harness script.

### Lessons Learned

1. **Contract-first with a live oracle**
   - Context: Python engine kept until the native engines proved byte-identical.
   - Insight: Enumerating allowed deltas (D1-D9) turned the differential run into a closed check; every mismatch had a name.
   - Application: Port tasks should pin the contract and the allowed deltas before writing the new engine.

2. **Child-process-only test harnesses hide in-process behavior**
   - Context: The suite always spawned `pwsh -File`, where process CWD equals `$PWD`.
   - Insight: The relative-root bug passed 205 assertions.
   - Application: Cover each supported invocation mode, not just the one that captures bytes cleanly.

### Pattern Discoveries

1. **Walk-key sort in awk**
   - Observed in: `projex-tree.sh`.
   - Description: Prefix path separators with `\002` and names with `\001` so `LC_ALL=C sort` yields files-before-subdirs pre-order.
   - Reuse potential: Any bash tool needing deterministic tree order without gawk.

### Gotchas / Pitfalls

1. **`awk -v` processes backslash escapes**
   - Trap: Mangles POSIX paths containing `\`.
   - Avoidance: Pass values through `ENVIRON`.
2. **`$(...)` drops NUL bytes**
   - Trap: Parent values may contain NUL.
   - Avoidance: Capture stage output through a temp file.
3. **`nul` is a reserved device name on Windows**
   - Trap: Fixture dir named `nul` fails `isdir`.
   - Avoidance: Name it `nulparent`.
4. **PowerShell 7.6 CRLF-rewrites native stderr when redirected with `2>`**
   - Avoidance: Capture raw bytes through `ProcessStartInfo`.
5. **`[IO.Path]::GetFullPath(x)` and `Directory.Exists(x)` ignore `Set-Location`**
   - Avoidance: Join relative paths to `Get-Location -PSProvider FileSystem` first.

### Technical Insights

- Dead Python branches (line 154, lines 161-165, `check_cycle`) were removed with a written proof that the BFS admits only a tree.
- Raw `OpenStandardOutput` writes guarantee LF bytes but bypass the PowerShell pipeline; in-process callers cannot capture or redirect (same trade as `projex-list.ps1`).

---

## Recommendations

### Immediate Follow-ups
- [ ] Promote the sh-to-ps1 differential harness into a committed `tests/` script and summarize C1-C9 / D1-D9 in `tests/README.md`.
- [ ] Triage the two pre-existing failing suites (`new-projex.test.ps1`, `close-precheck.test.ps1`).

### Future Considerations
- POSIX PowerShell reads non-regular `.md` entries (FIFO) where bash `-type f` skips them; needs a POSIX probe.
- Symlinked repo root: bash decides the repo-is-`.projex` rule by `pwd -P` basename (Python did not resolve links); accepted, rare.
- Non-gawk awk (macOS BWK/mawk) behavior is unverified on this host.
- `projex-list.ps1` header-grammar quirks (culture `StartsWith`, case-insensitive `*.md`, `TrimStart`) differ from `projex-tree`; candidate follow-up.
- About 30 synthetic fixture docs now sit in this repo's corpus (plan Risk); revisit if `projex-list` output gets noisy.

### Plan Improvements
- When a deviation replaces a sketched API, probe the replaced semantics before logging it as equivalent.
- Include an in-process invocation case in any PowerShell wrapper's test plan.

---

## Related Projex Updates

### Documents to Update
| Document | Update Needed |
|----------|---------------|
| `2610010506-projex-tree-native-port-plan.md` | Completed, linked to walkthrough and log; moved to `closed/` |
| `2610010506-projex-tree-native-port-log.md` | Data Gathered cause corrected; moved to `closed/` |
| `2610010520-projex-tree-native-port-plan-stress.md` | Complete (Remediated); moved to `closed/` |
| `2610011956-projex-tree-native-port-audit.md` | Complete (Accepted with Conditions - Conditions Met); moved to `closed/` |
| `2610012008-projex-tree-relative-repo-root-patch.md` | Already in `closed/` |
| `2610010531-new-projex-absolute-projex-dir-joined-to-repo-root-memo.md` | Unrelated concern, untracked in the base checkout; left alone |

### New Projex Suggested
| Type | Description |
|------|-------------|
| Plan | Ship the differential harness and contract summary under `tests/` |
| Patch | Triage the two pre-existing failing PowerShell suites |

---

## Appendix

### References
- Branch commits: 817309b, 0e9476f, ca3753e, 38c2dcc, 4b0b804, 51ba575, ce2dc52, a42e5da, 496c445, bd92466
- Execution log: `2610010506-projex-tree-native-port-log.md` (Step 5 holds the full harness script)
- Re-verification at close: both suites `PASS=208 FAIL=0` (orchestrator, in the worktree)
