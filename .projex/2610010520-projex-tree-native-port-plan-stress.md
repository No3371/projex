# Stress: projex-tree Native Port Plan

> **Status:** Draft
> **Lead:** Opus 5.5 (stress subagent)
> **Parent:** 2610010506-projex-tree-native-port-plan.md
> **Remediated in:** 2610010506-projex-tree-native-port-plan.md § Revision Log 2026-10-01 — Findings 1–10 + Compound 1 applied (Finding 4a matched to Python instead of a delta; 4b/4c → D7/D8); target-claim quotes below describe the pre-revision plan.
> **Subject:** 2610010506-projex-tree-native-port-plan.md | **Related:** 2608120933-parent-lineage-header-and-projex-tree-utility-proposal.md | 2608121756-parent-lineage-and-projex-tree-addition-plan.md | 2608130419-parent-lineage-and-projex-tree-addition-walkthrough.md | 2608121919-parent-lineage-audit-remediation-patch.md

---

## Bottom Line

**Verdict:** Fix Issues

Contract core (C2–C9, dead-branch proof, goldens, CRLF/summary diagnoses) survives attack. Defects sit in fixture placement, the CLI edge, execution gating, and CRLF-portability discipline — all fixable by plan revision without redesign.

**Top Vulnerabilities:**
1. `io-order` fixture commits invalid-UTF-8 `.md` files under a `.projex/` dir → after merge, `projex-tree` on this repo exits 4 (`E_IO`) for **every** target; Step 5's real-corpus differential becomes vacuous (Finding 1, Compound 1).
2. pwsh E_USAGE for extra args is dead code — `[CmdletBinding()]` rejects binding first (exit 1, PowerShell error); C1 pins it as contract, no suite tests E_USAGE on either side (Finding 3).
3. "Immune to autocrlf" holds only without backslash-newline continuations — CRLF breaks both shell and awk continuations; nothing forbids them and detection waits until Step 5 (Finding 2).

---

## Angle Triage

| Angle | Status | Reason / Earned by |
|-------|--------|--------------------|
| Assumption | Selected | Plan rests on stated invariants: CRLF immunity, C6 dead-branch proof, D1–D6 exhaustive |
| Edge Case | Selected | Byte-level contract (UTF-8, line breaks, CLI args, fixture bytes) — edge inputs are the subject |
| Failure Cascade | Selected | `close-projex.md:62` and `conclude-projex.md:43` invoke tree on every close/conclude in this repo |
| Inversion | Selected | Two hand-written engines vs. one shared engine is the plan's biggest cost choice |
| Scale | Selected | Engines walk the whole repo and read every doc; awk file handles and pwsh per-dir calls scale with tree size |
| Omission | Selected | Plan claims "only D1–D6" divergences and pins C1 verbatim — gaps would be silent |
| Hidden | Selected | Prior implementer deviated to Python; plan snippets may carry non-obvious bytes |
| Worst Case | Skipped | Tree output is advisory in both callers (`close-projex.md:62`, `conclude-projex.md:43`); bounded by Failure Cascade analysis |
| Incentive | Skipped | Single-user local dev tool; no party gains from gaming it |
| Time | Promoted | Finding 5 + Compound 1: oracle deleted in Step 6, harness scratch-only |
| Dependency | Selected | Hard precondition on uncommitted `projex-list` work; awk/pwsh variant reliance |
| Observability | Selected | Plan self-declares untested paths (read failure, symlinks) |
| Adoption | Skipped | Callers invoke `projex-tree.{sh|ps1}` by name; interface unchanged, no user behavior shift |

## Angles Not Attacked

| Angle | Surfaced by | What would have been asked |
|-------|-------------|---------------------------|
| Adoption | Finding 6 | Does `projex-list` output for this repo degrade once ~30 synthetic fixture docs (twins, dup Parents, `Zeta.md`) join its corpus? |

---

## Findings

### Finding 1: Committed invalid-UTF-8 fixture poisons this repo's own corpus
**Severity:** High | **Likelihood:** High | **Angle:** Edge Case / Failure Cascade

**Target Claim:** New fixtures are inert test data (plan Step 2 table, row `io-order`: "byte `FF` files: `2609150002-bad-plan.md`, `0/…`, `x/…`, `x-y/…`" under `.projex/`).

**Attack Vector:** Fixture docs live at `tests/fixtures/projex-tree/io-order/.projex/*.md`. Both engines (C2) and Python discover every `.md` under any `.projex` component of the repo root — fixtures included (existing `tests/fixtures/projex-tree/basic/.projex/` is already part of this repo's 89-doc corpus). Reproduced in scratch: copy of root `.projex/` + one `printf '\377'` file at that fixture path → `projex-tree.sh r1 2610010506-projex-tree-native-port-plan.md` → `projex-tree: E_IO: tests/fixtures/projex-tree/io-order/.projex/2609150002-bad-plan.md: invalid UTF-8`, exit 4. Target-independent: C3 aborts on first bad file.

**Impact:** After merge, every `projex-tree` call in this repo fails. `close-projex.md:62` / `conclude-projex.md:43` specify only success handling ("Treat successful tree context as advisory") — failure behavior undefined → agents stall or improvise on every close.

**Blast Radius:** All close/conclude runs in the projex repo; Step 5 verification (Compound 1).

**Remediation:** Match existing precedent (`tests/projex-tree.test.sh` writes `printf '\377'` into the temp copy at run time; `invalid-utf8/` fixture holds only goldens). `io-order/` commits only valid docs + goldens; the suites write the four `FF` files into the temp copy. Same rule for any other invalid-byte fixture.

### Finding 2: CRLF immunity breaks on backslash-newline continuations
**Severity:** Medium | **Likelihood:** Medium | **Angle:** Assumption

**Target Claim:** "Both scripts: ASCII-only source … → immune to script-encoding/autocrlf" (Constraints); "CRLF-materialized bash+awk script runs identically under Git Bash" (Context probe).

**Attack Vector:** Probed Git Bash with a CRLF script: plain lines, heredoc `EOF\r`, and single-quoted awk program run fine; but `echo a \`+CRLF → `line 2: b: command not found`, and awk `"p" \`+CRLF → `awk: cmd. line:1: … backslash not last character on line`. The Step 3 sketch has long `find` commands and a ~250-char UTF-8 regex — natural continuation candidates. Constraints forbid gawk-isms, not continuations.

**Impact:** Engine passes Steps 3–4 in the LF worktree, fails only at Step 5 fresh-clone check (or in users' autocrlf clones if Step 5 is skipped).

**Blast Radius:** Every Windows autocrlf=true checkout of `projex-tree.sh`.

**Remediation:** Add constraint "no backslash-newline continuation in `projex-tree.sh`, shell or awk". Step 3 verification: `grep -n '\\$' projex-tree.sh` → none, plus one suite run against a CRLF-converted copy of the script before Step 4.

### Finding 3: pwsh E_USAGE for extra arguments is unreachable; C1 untested
**Severity:** Medium | **Likelihood:** High (on any 3+-arg call) | **Angle:** Omission / Edge Case

**Target Claim:** C1 — "pwsh: existing `param` block and E_USAGE rule kept verbatim (extra `$args` … → E_USAGE)"; bash "exactly 2 args else `E_USAGE` (exit 2)".

**Attack Vector:** `projex-tree.ps1` uses `[CmdletBinding()]`; advanced scripts never populate `$args`. `pwsh -NoProfile -File projex-tree.ps1 . a b c` → exit 1, `A positional parameter cannot be found that accepts argument 'b'.` (ANSI-colored). bash side exits 2 with E_USAGE. `grep E_USAGE tests/projex-tree.test.{sh,ps1}` → no hits: neither suite covers usage errors; Step 5 harness only issues 2-arg calls.

**Impact:** sh↔ps1 divergence in exit code and message on the contract's first clause, invisible to every planned check.

**Blast Radius:** CLI misuse paths on Windows hosts; contract credibility ("pinned — both engines implement exactly this").

**Remediation:** Capture extras (e.g. `[Parameter(ValueFromRemainingArguments)]$Rest` or drop `CmdletBinding` and parse `$args`) → E_USAGE exit 2. Add suite cases: 0, 1, 3 args, empty-string args — both suites.

### Finding 4: Deltas D1–D6 are not exhaustive
**Severity:** Medium | **Likelihood:** Low | **Angle:** Assumption / Omission

**Target Claim:** "Deliberate deltas vs Python (the only allowed differential mismatches)"; Success Criteria "differences only in the enumerated deltas D1–D6".

**Attack Vector:** Divergences no fixture or Step 5 input exercises:
- (a) Repo arg whose basename is `.projex`: Python line 21 treats the repo itself as a root — reproduced (`projex-tree.sh so/.projex …` → full tree, exit 0). C2 "`.projex` path component below root" → nothing discovered → `E_TARGET_NOT_FOUND`.
- (b) Windows target with drive colon: `ntpath.basename('c:x.md') != target` → Python `E_TARGET_NAME` (reproduced). C1 rejects only `/` `\` → `E_TARGET_NOT_FOUND`.
- (c) Unenterable repo dir: C1 → `E_REPO`; Python `isdir` passes, `os.walk` swallows → `E_TARGET_NOT_FOUND`.
- (d) NUL inside a Parent value (C3: "NUL valid"): Python emits `…filename: a\0b` (reproduced via `od`). bash `$(…)` capture drops NUL and prints `warning: command substitution: ignored null byte in input` (probed) → sh stderr ≠ ps1 stderr.
- (e) pwsh nested-repo test `Test-Path (Join-Path $d '.git')` is case-insensitive on NTFS; bash `find -name .git` is case-sensitive → a `.GIT` dir prunes only in pwsh.

**Impact:** Contract silently differs from Python and, for (d)/(e), between the two new engines; Success Criterion passes vacuously.

**Blast Radius:** Rare inputs; parity guarantee.

**Remediation:** Enumerate (a)–(c) as D7–D9 (or match Python). (d): stage-3 output via temp file instead of `$()`, add a NUL-Parent row. (e): detect child `.git` by ordinal name from the directory's own enumeration.

### Finding 5: "Untestable" symlink/junction paths are testable on this host
**Severity:** Medium | **Likelihood:** Medium | **Angle:** Observability

**Target Claim:** Risks — "D5 (symlinks) has no automated test — symlink creation on Windows needs Developer Mode/admin"; C2 prunes "symlinked/junction dirs".

**Attack Vector:** Scratch probe: `New-Item -ItemType Junction` and `-ItemType SymbolicLink` both succeeded unprivileged; `MSYS=winsymlinks:nativestrict ln -s` succeeded; Git Bash `find -type l` lists both junction and file symlink, `-type f` excludes them. Junctions never require privilege on Windows. The C2 junction-pruning clause and D5 would ship with zero coverage although coverage is cheap.

**Impact:** Link-handling divergence between `find -type f` / `LinkTarget` logic undetected; `LinkTarget` assumption (plan Assumptions) never checked.

**Blast Radius:** Repos with linked `.projex` dirs or docs.

**Remediation:** Add guarded cases to both suites (attempt link creation; on failure record a skip that counts identically in both suites to keep assertion parity). Read-failure path: try `icacls <tmpfile> /deny "$env:USERNAME:(R)"` on a temp copy (not verified here); keep manual only if that fails.

### Finding 6: Precondition "projex-list committed first" has no gate
**Severity:** Medium | **Likelihood:** Medium | **Angle:** Dependency

**Target Claim:** Dependencies — "Requires: `projex-list` native rewrite … committed to `main` first … close's dirty-base gate refuses to merge into a checkout with those files dirty."

**Attack Vector:** Current state (`git status`): `README.md`, `tests/README.md`, `tests/run-all.{sh,ps1}` modified; `projex-list.*` untracked. No step checks this. Worktree mode starts from HEAD → Steps 1–6 all succeed → close refuses squash into dirty `main`. Also Step 6's README edit is adjacent to the uncommitted `projex-list` row → conflict at merge.

**Impact:** Full execution completed, then blocked at close; rework/conflict resolution.

**Blast Radius:** Whole execution cycle.

**Remediation:** Step 1 pre-gate: `git -C <repo-root> status --porcelain -- README.md tests/README.md tests/run-all.sh tests/run-all.ps1` empty and `git -C <repo-root> ls-files --error-unmatch projex-list.sh projex-list.ps1` succeeds; else stop `Blocked`.

### Finding 7: awk engine leaks file handles
**Severity:** Low | **Likelihood:** Low | **Angle:** Scale / Dependency

**Target Claim:** Step 3 — "read each doc (getline < path; -1 → E_IO read failed, exit 4)".

**Attack Vector:** Sketch never `close(path)`. gawk multiplexes descriptors; BWK/mawk fail to open past the process limit → `getline` returns -1 → false `E_IO: <rel>: read failed` on large corpora on exactly the non-gawk hosts the plan cannot test.

**Impact:** Spurious exit 4 on big repos (macOS).

**Blast Radius:** Non-gawk hosts, corpora beyond fd limit.

**Remediation:** Mandate `close(path)` after each doc in Step 3 text.

### Finding 8: pwsh lazy enumeration escapes the silent-skip try
**Severity:** Low | **Likelihood:** Medium (on unreadable dirs) | **Angle:** Edge Case

**Target Claim:** Step 4 — "Walk(dir, inProjex): try EnumerateFileSystemInfos() catch → return (C2 silent skip)".

**Attack Vector:** `EnumerateFileSystemInfos()` is lazy; `UnauthorizedAccessException` fires on first `MoveNext`, outside a try that wraps only the call → terminating error under `$ErrorActionPreference = 'Stop'`. Swapping to `EnumerationOptions` with `IgnoreInaccessible` has its own trap: default `AttributesToSkip = Hidden | System` would drop hidden `.git` entries and hidden docs.

**Impact:** Unreadable subdir → crash instead of skip (Python skips).

**Blast Radius:** Repos with ACL-restricted dirs.

**Remediation:** Materialize inside the try (`@($d.EnumerateFileSystemInfos())`), or `EnumerationOptions` with `IgnoreInaccessible=$true` **and** `AttributesToSkip=0`.

### Finding 9: Plan snippet contains non-ASCII bytes
**Severity:** Low | **Likelihood:** Medium | **Angle:** Hidden

**Target Claim:** Constraints — "Both scripts: ASCII-only source".

**Attack Vector:** Step 4 regex line (`[regex]::Split(...)`) holds literal U+2028/U+2029 (`od`: `342 200 250 342 200 251`) that render as blanks. Copying the snippet verbatim violates the constraint.

**Impact:** Caught by Step 4 non-ASCII grep; costs an iteration.

**Blast Radius:** Step 4 only.

**Remediation:** Write `  ` in the snippet.

### Finding 10: No persistent oracle after Step 6
**Severity:** Low | **Likelihood:** Medium | **Angle:** Time (Promoted)

**Target Claim:** Step 5 — "harness in session scratchpad only"; Step 6 — Python "dead weight".

**Attack Vector:** After Step 6, sh↔ps1 agreement is guarded only by shared goldens. Clauses without fixtures (Finding 4 items, link handling pre-Finding 5) drift unobserved in future edits of one engine.

**Impact:** Gradual engine divergence; detection lag = until a user hits it.

**Blast Radius:** Future maintenance.

**Remediation:** Record the harness command set in the walkthrough, or keep a lightweight committed sh↔ps1 cross-check (both engines over every fixture target) runnable where both shells exist.

### Compound 1: Real-corpus differential proves nothing
**Severity:** High | **Angles:** Edge Case + Observability | **Member findings:** Finding 1 + Finding 5

Step 5 item 2 runs all three engines against `<work-root>` × ~88 targets. With Finding 1's fixture present, every run yields the identical `E_IO … io-order … invalid UTF-8`, exit 4 → zero mismatches → Success Criterion "byte-identical … on every document of this repo's own corpus" passes with no tree rendered. Combined with untested link/read paths, the plan's two broadest verification nets (corpus differential, observability of edge paths) both come back green without exercising the engines. Fixed by Finding 1's remediation; add an assertion that the corpus run yields ≥1 exit-0 tree.

---

## Held

### Assumption: C6 dead-branch proof
**Tried:** Traced `.projex-tree.py` 92–178 for a member with >1 Parent, a malformed Parent, a duplicate name, or a back-edge.
**Held because:** chain phase returns on multi/malformed/self/dangling/duplicate-identity; target and chain lookups require `len(by_name[..]) == 1`; BFS admits only single-Parent `NAME_RE` docs with unique names, once each (`members` check) → members form a tree rooted at a doc without a filename Parent. Line 154 ⊂ line 156; 161–165 and `check_cycle` unreachable.

### Assumption: author's verified diagnoses
**Tried:** Reran both suites; read runners; reproduced golden A.
**Held because:** `bash tests/projex-tree.test.sh` and `pwsh … projex-tree.test.ps1` → `PASS=39 FAIL=7 CASES=46`, cmp differ at char 31 (`\r`). `run-all.sh:19` / `run-all.ps1:23` require `^PASS=N FAIL=M$` → `CASES=` breaks it. Python on the scratch sort-order tree reproduces golden A byte-for-byte (modulo `\r`).

### Edge Case: sort/walk discriminators
**Tried:** Whole-path vs files-first, UTF-16 vs code-point order, tuple vs whole-line error order.
**Held because:** `0/` vs `2609150002-…` and `x` vs `x-y` discriminate walk order; `！` (EF BC 81) vs `😀` discriminate UTF-16 order; `…dup-plan.md` vs `…dup-plan.md-old/…` discriminate `:` vs `-`; `\001` field separator < every name byte makes `sort -u` whole-record order equal tuple order.

### Edge Case: C4/C5 byte grammar
**Tried:** `\r\n` double-split, BOM, strip set, awk string-vs-numeric comparison.
**Held because:** extra empty lines only affect idx>0 and blank lines are skipped; idx 0 unchanged. Strip set (bash octal list and pwsh `Trim` set) equals Python `str.isspace` for all listed code points. Names end `.md` → never numeric strnums, so awk `<` stays string compare.

### Edge Case: non-ASCII names through Git Bash `find`
**Tried:** `LC_ALL=C find` over `ßeta.md`, `！.md`, `😀.md`.
**Held because:** `od` shows raw UTF-8 bytes (`c3 9f`, `ef bc 81`, `f0 9f 98 80`) → byte sort = code-point order.

### Assumption: CRLF heredoc and single-quoted awk
**Tried:** CRLF script with heredoc `EOF\r`, multi-line single-quoted awk program.
**Held because:** Git Bash ran both correctly (continuations excepted — Finding 2).

### Inversion: one shared engine instead of two
**Tried:** bash-only engine (ps1 shells to bash); pwsh-only engine (sh shells to pwsh).
**Held because:** Git Bash not guaranteed on Windows hosts, pwsh not guaranteed on macOS/Linux; human rule "pure bash + PowerShell" plus `projex-list` precedent force two engines. Shared fixtures are the right mitigation.

### Hidden: repeat of the Python deviation
**Tried:** Whether the plan leaves room for the executor to fall back to Python again (walkthrough 2608130419 § Deviation).
**Held because:** Success Criteria grep for `python`, forbid Python/Perl/iconv, and per-step rollback restores the prior wrapper instead of inventing a new runtime.

### Assumption: D4–D6 (challenged per plan Open Questions)
**Tried:** Whether each delta harms a real user.
**Held because:** D4 removes an absolute, OS-specific path from output; D5 aligns with `projex-list` `find -type f`; D6 affects only POSIX filenames containing `\`. All defensible.

### Time: `.gitattributes` dirtying existing checkouts
**Tried:** Main checkout with CRLF fixtures turning "modified" under `-text`.
**Held because:** `git ls-files --eol` here → all `i/lf w/lf` (one `none`); this checkout stays clean.

### Implication pass
Promotion: Time promoted from Finding 5 + Compound 1 → Finding 10. Cascade: Compound 1 (Finding 1 + Finding 5). Adoption surfaced after the pass → Angles Not Attacked.

---

## Remediation

### Must Fix (Before Proceeding)
- **Invalid fixture in repo corpus** (Edge Case) → `io-order/` commits valid docs + goldens only; suites write `FF` files into the temp copy → after Step 2, `bash projex-tree.sh <work-root> 2610010506-projex-tree-native-port-plan.md` exits 0.
- **Vacuous corpus differential** (Compound 1) → Step 5 asserts ≥1 exit-0 tree among corpus runs → harness prints nonzero exit-0 count.
- **pwsh extra-arg E_USAGE unreachable** (Omission) → capture remaining args, emit E_USAGE exit 2; add 0/1/3-arg cases to both suites → `pwsh -File projex-tree.ps1 . a b c` → exit 2, E_USAGE line.
- **No precondition gate** (Dependency) → Step 1 pre-gate on clean `README.md`, `tests/README.md`, `tests/run-all.*` and tracked `projex-list.*` in `<repo-root>` → gate output recorded in execution log.
- **CRLF continuation trap** (Assumption) → Constraint: no backslash-newline continuations; Step 3 check `grep -n '\\$' projex-tree.sh` empty + suite run on CRLF-converted copy.

### Should Fix (Before Production)
- **Unenumerated deltas (a)–(e)** (Assumption/Omission) → enumerate as D7–D9, fix NUL capture and case-sensitive `.git` detection, add fixtures.
- **Link paths untested** (Observability) → guarded junction/symlink cases in both suites; try `icacls` deny for read-failure.
- **Lazy enumeration** (Edge Case) → materialize inside try, or `IgnoreInaccessible` + `AttributesToSkip=0`.
- **awk file handles** (Scale) → `close(path)` per doc.
- **Non-ASCII snippet** (Hidden) → `  ` in Step 4 text.

### Monitor
- **No persistent oracle** (Time) → revisit on the first edit to either engine after close.
- **Non-gawk awk (BWK 2nd-ed. UTF-8 mode, mawk) byte regex/NUL** (Dependency) → first macOS/Linux suite run.
- **Fixture corpus pollution** (Adoption, not attacked) → revisit if `projex-list` output on this repo becomes noisy; option: store fixture trees under a non-`.projex` dir renamed at copy time.

---

## Final Assessment

**Soundness:** Fixable
**Risk:** Medium
**Readiness:** Ready with Fixes

**Conditions for Approval:**
- [ ] No committed fixture byte sequence makes `projex-tree` fail on this repo
- [ ] Step 5 corpus run proven non-vacuous
- [ ] pwsh and bash agree on E_USAGE, covered by tests
- [ ] Execution gated on `projex-list` being committed
- [ ] Continuation ban + CRLF-copy check in Step 3

**No-Go If:**
- [ ] Any `.md` under a committed `.projex/` path in `tests/fixtures/` is invalid UTF-8
- [ ] Execution starts while `README.md` / `tests/README.md` / `tests/run-all.*` are dirty in `<repo-root>`
