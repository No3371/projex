# projex-tree Native Port (bash + PowerShell, no Python)

> **Status:** Complete
> **Author:** Opus 5.5 (Plan subagent)
> **Parent:** Orchestrator
> **Source:** Direct request — make `projex-tree` a pure bash + PowerShell utility (human-approved after the `projex-list` native rewrite)
> **Related Projex:** 2608120933-parent-lineage-header-and-projex-tree-utility-proposal.md | 2608121756-parent-lineage-and-projex-tree-addition-plan.md | 2608130419-parent-lineage-and-projex-tree-addition-walkthrough.md | 2608121919-parent-lineage-audit-remediation-patch.md | 2610010520-projex-tree-native-port-plan-stress.md | 2610011956-projex-tree-native-port-audit.md | 2610012008-projex-tree-relative-repo-root-patch.md
> **Worktree:** Yes
> **Completed:** 2026-10-01
> **Walkthrough:** 2610010506-projex-tree-native-port-walkthrough.md
> **Log:** 2610010506-projex-tree-native-port-log.md

---

## Summary

Replace `.projex-tree.py` engine with two self-contained native engines — `projex-tree.sh` (bash + `LC_ALL=C` find/sort/awk) and `projex-tree.ps1` (pwsh 7 / .NET) — preserving CLI, tree rendering, error codes, messages, and exit codes. Behavior pinned first by a written contract + shared fixtures; Python kept as differential oracle until the last step, then deleted.

**Scope:** `projex-tree` engine, its test suites/fixtures, one `.gitattributes` line-ending pin, two README rows. No output redesign.
**Estimated Changes:** 2 scripts rewritten | 1 engine deleted | 2 test suites extended | 6 fixture dirs + 1 TSV added | `.gitattributes` created | 2 doc rows edited.

---

## Objective

### Problem / Gap / Need

- Python engine is an implementation deviation (not in proposal/plan; walkthrough 2608130419 § Deviation), contradicting the human's "pure bash + PowerShell utilities" rule.
- Engine is broken on this Windows host: stdout+stderr emitted CRLF → current suites fail 7/46 each (`expected.stdout` differ at char 31, line 1 = `\r`). Verified 2610-01 by running both suites.
- `discover()` strips `.git` from `dirs` (line 17) before its nested-repo check (line 18) → nested repositories never skipped. Verified: doc under `sub/.git`-bearing `sub/.projex/` renders in host tree.
- Nested `.projex` inside a `.projex` root walked twice → same file discovered twice → false `E_TARGET_AMBIGUOUS` / `E_IDENTITY_DUPLICATE`. Verified.
- Suites print `PASS=n FAIL=n CASES=n`; `tests/run-all.{sh,ps1}` require `^PASS=\d+ FAIL=\d+$` → runner flags the suite even when green. Verified.
- Fresh checkout under this host's `core.autocrlf=true` (global) materializes fixture goldens as CRLF (`git ls-files --eol` → `i/lf w/crlf`), so byte-exact goldens depend on checkout config. Verified via scratch clone.

### Success Criteria

- [x] `.projex-tree.py` deleted; `grep -n -i python projex-tree.sh projex-tree.ps1 README.md` (tree row) → no hits.
- [x] `bash tests/projex-tree.test.sh` and `pwsh tests/projex-tree.test.ps1` → `FAIL=0`, identical assertion counts, summary line matches `^PASS=[0-9]+ FAIL=[0-9]+$`.
- [x] `tests/run-all.sh` / `tests/run-all.ps1` report the projex-tree suite without the "did not emit exactly one PASS=N FAIL=M summary" line.
- [x] All stdout/stderr bytes LF-terminated UTF-8 without BOM on Windows, both engines (goldens compared with `cmp` / `Get-FileHash`).
- [x] Differential run (Step 5): sh, ps1, and Python (CRLF→LF normalized) byte-identical on every parity case and on every document of this repo's own corpus as target; differences only in the enumerated deltas D1–D9; corpus run yields ≥1 exit-0 tree per engine (non-vacuous).
- [x] No committed fixture byte makes `projex-tree` fail on this repo: after Step 2, tree on any real doc of `<work-root>` exits 0. (Close correction: 62 of 64 real docs exit 0; the other 2 exit 3 with `E_PARENT_DANGLING` — a pre-existing content error, not fixture-caused; criterion intent, no fixture-induced failure or `E_IO`, met.)
- [x] `projex-tree.{sh,ps1}` agree on C1 for 0/1/3 args, `-`-prefixed extras, and empty-string args (suite-covered).
- [x] Fresh scratch clone of the ephemeral branch (autocrlf=true) passes both suites.

### Out of Scope

- Output/format/error-code redesign; new flags.
- `projex-list.{sh,ps1}` (uncommitted, not ours) — sibling observations in Notes only.
- Repo-wide `.gitattributes` policy (scripts, other fixtures).
- `close-projex.md` / `conclude-projex.md` — invoke `projex-tree.{sh|ps1}` by name; interface unchanged.
- Windows PowerShell 5.1 support (existing wrapper already pwsh-targeted via tests).

---

## Context

### Current State

- `projex-tree.sh` (10 lines): arg-count check → `exec python3 .projex-tree.py`.
- `projex-tree.ps1` (19 lines): `[CmdletBinding()]` param `RepoRoot`/`Filename`; E_USAGE when `$args` present or either empty — `$args` branch dead: advanced scripts never populate `$args`, so `. a b c` → PowerShell binding error exit 1, and `-Verbose`/`--` bind as common params (probed 2610-01); finds `python3|python` (E_IO `runtime` exit 4 if absent); runs engine.
- `.projex-tree.py` (197 lines): `discover()` → `main()` (target checks → ancestor chain → descendant BFS → error sort → render).
- Tests: `tests/projex-tree.test.{sh,ps1}` 46 cases each; fixtures `tests/fixtures/projex-tree/{basic,duplicate-parent,invalid-utf8}`.
- Precedent: `projex-list.{sh,ps1}` (uncommitted native rewrite) — find/sed/`LC_ALL=C` awk + `LC_ALL=C sort`; .NET recursion + raw `OpenStandardOutput` UTF-8 writes.
- Toolchain here: GNU Awk 5.4.0, pwsh 7.6.5, Git Bash. Probes (scratch, discarded): gawk C-locale byte regex validates UTF-8 correctly incl. NUL, overlong, surrogate, >U+10FFFF, truncation; `UTF8Encoding($false,$true)` rejects the same set; `CompareOrdinal(U+FF01, U+1F600) > 0` (UTF-16 order ≠ code-point order); culture `StartsWith` matches `">­ **Parent:**"` against `"> **Parent:**"`; CRLF-materialized bash+awk script runs identically under Git Bash **except backslash-newline continuations** (shell and awk both break on `\`+CRLF — stress Finding 2); param-less pwsh script receives every arg verbatim in `$args` (empty strings, `-Foo`, `-Verbose`, `--` included); unprivileged `New-Item -ItemType Junction|SymbolicLink` succeeds here, `LinkTarget` non-null for both.
- Every `.md` under any `.projex/` of this repo is corpus — committed fixture docs included (`tests/fixtures/projex-tree/basic/.projex/` already is). C3 aborts on the first bad file → one committed invalid-UTF-8 fixture doc makes every tree call in this repo exit 4.

### Key Files

| File | Role | Change Summary |
|------|------|----------------|
| `.gitattributes` | none (absent) | New: `tests/fixtures/projex-tree/** -text` |
| `projex-tree.sh` | bash entry | Rewrite: native engine |
| `projex-tree.ps1` | pwsh entry | Rewrite: native engine |
| `.projex-tree.py` | Python engine | Delete (Step 6) |
| `tests/projex-tree.test.sh` / `.ps1` | suites | New fixture cases, UTF-8 table, summary format |
| `tests/fixtures/projex-tree/*` | shared corpus | Add `nested-projex/`, `nested-repo/`, `sort-order/`, `header-quirks/`, `error-order/`, `io-order/`, `utf8-cases.tsv` |
| `README.md` | utility table | Tree row: drop "requires Python 3" |
| `tests/README.md` | coverage table | Tree row: counts + coverage text |

### Dependencies

- **Requires:** `projex-list` native rewrite (+ its `README.md`, `tests/README.md`, `tests/run-all.{sh,ps1}` edits) committed to `main` first. This plan edits adjacent lines of `README.md`/`tests/README.md`; close's dirty-base gate refuses to merge into a checkout with those files dirty. Enforced by the Step 1 pre-gate (unmet at planning time: those files dirty/untracked in `<repo-root>`).
- **Blocks:** nothing.

### Constraints

- CLI, messages, codes, exit codes unchanged except deltas D1–D9.
- bash side: POSIX `find`/`sort`/`sed` + awk under `LC_ALL=C`; no gawk-only features (`asort`, `/dev/stderr`, `{n}` intervals, `-i`), no `iconv`, no Python/Perl.
- pwsh side: no external processes; .NET only.
- Both scripts: ASCII-only source (box glyphs via octal escapes / `[char]` codes; regex code points as `\uXXXX`) → immune to script-encoding.
- No backslash-newline continuation in `projex-tree.sh` or `tests/projex-tree.test.sh`, shell or awk → immune to autocrlf. Long commands via variables / arrays; long awk regexes via string concatenation on one line or `U = U "…"` statements.
- No committed fixture `.md` under a `.projex/` path may be invalid UTF-8 (or otherwise make C3 abort); invalid bytes are written into the suite's temp copy at run time (existing `invalid-utf8` precedent).
- Source Hygiene (SKILL.md) — no projex refs, rationale comments name the rejected alternative.

### Assumptions

- macOS/BSD awk honors octal-escape bracket ranges under `LC_ALL=C` (verified only on gawk; macOS untested here).
- File names contain no `\n`, `\001`, `\002` bytes (bash pipeline field/sort keys).
- `FileSystemInfo.LinkTarget` (.NET 6+) is non-null exactly for symlinks/junctions (non-null for both probed here; Step 2 link cases check it).

### Impact Analysis

- **Direct:** the files above.
- **Adjacent:** `close-projex.md` § tree step, `conclude-projex.md` § tree step (callers; interface stable). `tests/run-all.*` (consumes summary line).
- **Downstream:** any host without Python gains a working `projex-tree`.

---

## Behavior Contract (pinned — both engines implement exactly this)

**C1 Invocation.** Both engines: exactly 2 args (empty strings count) else `projex-tree: E_USAGE: invocation: expected <repo-root> <filename>` (exit 2). ~~pwsh: existing `param` block and E_USAGE rule kept verbatim~~ (superseded 2610-01: under `[CmdletBinding()]` the `$args` branch is dead — extras exit 1 with a PowerShell binding error; `-Verbose`/`--` bind as common params). pwsh: no `param` block, no `[CmdletBinding()]`; parse `$args` positionally (`$args.Count -ne 2` → E_USAGE). Empty arg no longer E_USAGE in pwsh — falls through to E_REPO / E_TARGET_NAME like bash (D9). Then, in order: repo not a directory (or unenterable) → `E_REPO: <repo as given>: repository root not found` (2); target empty → `E_TARGET_NAME: <empty>: …`; target containing `/`, `\`, or `:` → `E_TARGET_NAME: <target>: filename basename required` (2).

**C2 Discovery.** Pre-order walk from repo root; per directory: its files sorted, then its subdirectories sorted (sort = C8). Pruned dirs: named `.git` or `.projexwt` (ordinal); any dir below root containing an entry named exactly `.git` (file or dir; ordinal, from that dir's own enumeration — `.GIT` does not prune); symlinked/junction dirs (not descended). Unreadable dirs silently skipped. Doc = non-symlink regular file, name ends `.md` (case-sensitive, `.md` itself included), with a `.projex` path component below root — or anywhere, when the resolved repo root's own basename is `.projex` (Python line 21 parity; `rel` then has no `.projex/` prefix). Each file discovered once. `rel` = repo-relative, `/`-separated.

**C3 Read.** Docs read in C2 order; first failure aborts: read error → `E_IO: <rel>: read failed` (4); invalid UTF-8 anywhere in file → `E_IO: <rel>: invalid UTF-8` (4). Valid = Unicode well-formed (Table 3-7): rejects overlong, surrogates `ED A0–BF`, > U+10FFFF, `F5–FF`, stray continuation, truncation. NUL valid. Exactly one leading `EF BB BF` stripped.

**C4 Lines.** Break on `\r\n` and each of `\n \r \v \f \x1c \x1d \x1e U+0085 U+2028 U+2029` (Python `str.splitlines`). Extra empty lines produced by splitting `\r\n` as two breaks are harmless (C5 skips blanks).

**C5 Header parse** (per doc, line index from 0): idx 0 starting `#` → started, next. `strip(line) == "---"` → stop. Starts `> ` → started; if starts `> **Parent:**` append `strip(rest)`; next. `strip(line) == ""` → next. Else if started → stop; else next (pre-header text skipped). All prefix tests ordinal. `strip` set = Python `str.isspace`: `09–0D 1C–20 85 A0 1680 2000–200A 2028 2029 202F 205F 3000`.

**C6 Graph** = Python `main()` lines 82–160 transliterated, minus proven-dead branches: line 154 (subsumed by line 156), lines 161–165, and `check_cycle` (lines 166–178). Proof: chain phase returns on any multi/malformed Parent; BFS admits only single-Parent `NAME_RE` members, each once → members form a tree → no descendant cycle, no multi/malformed member. Equality/lookup ordinal, case-sensitive (`User`, `Orchestrator`, names). `NAME_RE` = `^[0-9]{10}-[a-z0-9][a-z0-9-]*-[a-z0-9][a-z0-9-]*\.md$`, ASCII classes only (no `\d`).

**C7 Errors** (exit 3): set-deduplicated `(code, loc, detail)` tuples sorted tuple-wise (field by field, C8), printed `projex-tree: <code>: <loc>: <detail>`. Tuple ≠ whole-line order when a loc is a prefix of another (`:` 0x3A vs `-` 0x2D).

**C8 Order.** Code-point order (= UTF-8 byte order). pwsh must not use `CompareOrdinal`/`Sort-Object`/culture compares; compare UTF-8 byte arrays.

**C9 Output.** Render as Python lines 184–192 (`├── └── │   ` + 4 spaces, children sorted C8). stdout/stderr: UTF-8, no BOM, every line `\n`-terminated, on every OS. Exit 0 prints stdout only; nonzero prints stderr only.

**Deliberate deltas vs Python** (the only allowed differential mismatches):
- **D1** LF output on Windows (Python emits CRLF).
- **D2** nested repositories (`.git` file or dir below root) pruned (Python bug: never pruned).
- **D3** nested `.projex` discovered once (Python: twice → false duplicates).
- **D4** `E_IO` read-error detail fixed `read failed` (Python: `str(exc)` with absolute, OS-specific path).
- **D5** symlinked `.md` files not discovered (Python followed them; matches `projex-list` `find -type f`).
- **D6** `\` in target rejected on POSIX too (Python: Windows only); pwsh E_USAGE/E_REPO stderr now LF.
- ~~**D7** target with drive colon (`c:x.md`): not rejected → `E_TARGET_NOT_FOUND`~~ (superseded 2026-10-01: human forbade `:` in projex filenames — SKILL.md § Authoring).
- **D7** target containing `:` (`c:x.md`, `a:b.md`): rejected on every OS → `E_TARGET_NAME` (2). Matches Windows Python (`ntpath.basename` ≠ target); POSIX Python instead reports `E_TARGET_NOT_FOUND`.
- **D8** repo dir exists but unenterable → `E_REPO` (Python: `isdir` passes, `os.walk` swallows → `E_TARGET_NOT_FOUND`).
- **D9** pwsh wrapper CLI (vs old `.ps1`, not vs Python): extra / `-`-prefixed args → E_USAGE exit 2 (was binding error exit 1 or silent common-param bind); empty arg → E_REPO / E_TARGET_NAME (was E_USAGE) — now identical to bash.

---

## Implementation

### Overview

Pin line endings → write contract fixtures/tests (fail-first on deltas) → bash engine → pwsh engine → differential oracle → delete Python + docs. All edits in `<work-root>`.

### Step 1: Pin fixture line endings

**Objective:** Byte-exact goldens independent of `core.autocrlf`.
**Confidence:** High
**Depends on:** None
**Do-Projex:** Encouraged

**Files:** `.gitattributes` (new)

**Changes:**

Pre-gate (before creating anything; record both outputs in the execution log):

```bash
git -C <repo-root> status --porcelain -- README.md tests/README.md tests/run-all.sh tests/run-all.ps1   # must print nothing
git -C <repo-root> ls-files --error-unmatch projex-list.sh projex-list.ps1                              # must succeed
```

Either fails → stop, set plan `Blocked` (waiting on the `projex-list` commit); no worktree changes.

```gitattributes
// Before: (file absent)
// After:
tests/fixtures/projex-tree/** -text
```

Then re-materialize the worktree copy (it was checked out before the attribute existed): delete `<work-root>/tests/fixtures/projex-tree` from disk, `git -C <work-root> checkout -- tests/fixtures/projex-tree`. Record baseline: `bash tests/projex-tree.test.sh` → expect `FAIL=7` (Python CRLF).

**Rationale:** `-text` stores and checks out bytes verbatim — needed for CRLF/lone-CR/invalid-byte inputs and LF goldens. Rejected: normalizing in tests (would hide D1); repo-wide `eol=lf` (policy change beyond scope).

**Verification:** pre-gate outputs recorded (empty status, `ls-files` success); `git -C <work-root> ls-files --eol tests/fixtures/projex-tree` → every row `w/lf` or `w/none` with `attr/-text`; `git -C <work-root> status --porcelain` shows only `.gitattributes`.

**If this fails:** delete `.gitattributes`, restore fixture dir via checkout.

---

### Step 2: Contract fixtures + suites (fail-first)

**Objective:** Encode C1–C9 and D1–D9 as shared fixtures before any engine change.
**Confidence:** High
**Depends on:** Step 1
**Verify-Projex:** Encouraged

**Files:** `tests/fixtures/projex-tree/{nested-projex,nested-repo,sort-order,header-quirks,error-order,io-order}/…`, `tests/fixtures/projex-tree/utf8-cases.tsv`, `tests/projex-tree.test.sh`, `tests/projex-tree.test.ps1`

**Changes — fixtures** (`R` = the fixture's root doc; doc bodies `# t\n> **Parent:** <p>\n---\n` unless shown; all expected files LF):

| Fixture | Docs (under `.projex/` unless noted) | Target → expected |
|---|---|---|
| `nested-projex` | `2609100000-root-proposal.md` (User); `inner/.projex/2609100001-inner-plan.md` (R) | either target → exit 0, `R\n└── 2609100001-inner-plan.md\n` **(D3)** |
| `nested-repo` | `2609110000-host-proposal.md` (User); `vendor/.projex/2609110001-vendored-plan.md` (R). Test creates `vendor/.git` at run time (git cannot commit it) | no `.git`: R + `└── …vendored…`; `vendor/.git/` dir: `R\n` only, vendored target → `E_TARGET_NOT_FOUND` (2); `vendor/.git` file (`gitdir: x`): same **(D2)** |
| `sort-order` | R=`2609120000-root-proposal.md`; children of R: `2609120001-alpha-plan.md`, `2609120002-case-plan.md`, `closed/2609120002-CASE-plan.md`, `Zeta.md`, `ßeta.md`, `！.md` (U+FF01), `😀.md`; `2609120003-grand-log.md` (alpha) | target `2609120002-case-plan.md` (not ambiguous: case-sensitive) → golden A |
| `header-quirks` | R=`2609130000-root-proposal.md`; exact bytes in table below | target R → golden B; target `2609130009-empty-parent-plan.md` → exit 3, stderr `projex-tree: E_PARENT_MALFORMED: .projex/2609130009-empty-parent-plan.md: Parent is not a projex filename: \n` (trailing space) |
| `error-order` | R=`2609140000-root-proposal.md`; `2609140001-dup-plan.md` (two `> **Parent:** R`); `2609140001-dup-plan.md-old/2609140002-dup-plan.md` (Parents R, `2609149999-other-plan.md`); `2609140003-twin-plan.md` + `closed/2609140003-twin-plan.md` (R) | target R → exit 3, golden C (C7 tuple order) |
| `io-order` | committed: `2609150000-root-proposal.md` (User) + goldens only. ~~byte `FF` files committed~~ (superseded 2610-01: would poison this repo's corpus → every tree call exit 4). Suite writes `FF` files into the temp copy at run time: `2609150002-bad-plan.md`, `0/2609150001-bad-plan.md`, `x/2609150003-bad-plan.md`, `x-y/2609150004-bad-plan.md` | target R → `E_IO: .projex/2609150002-bad-plan.md: invalid UTF-8` (4); test then deletes that file + `0/` → `E_IO: .projex/x/2609150003-bad-plan.md: invalid UTF-8` (C2 files-first, `x` before `x-y`) |

`header-quirks` bytes (`R` literal root name):

| File | Bytes | Child of R? |
|---|---|---|
| `2609130001-nbsp-plan.md` | `# t\n> **Parent:** R\xC2\xA0\n---\n` | yes (strip) |
| `2609130002-lonecr-plan.md` | `# t\r> **Parent:** R\r---\r` | yes |
| `2609130003-formfeed-plan.md` | `# t\f> **Parent:** R\n---\n` | yes |
| `2609130004-preamble-plan.md` | `Intro text\n\n> **Parent:** R\n---\n` | yes |
| `2609130005-body-plan.md` | `# t\n> **Status:** Draft\n\nBody\n> **Parent:** R\n` | no |
| `2609130006-dashes-plan.md` | `# t\n \t--- \n> **Parent:** R\n` | no |
| `2609130007-u2028-plan.md` | `# t\xE2\x80\xA8> **Parent:** R\n` | yes |
| `2609130008-late-heading-plan.md` | `\n# t\n> **Parent:** R\n` | yes |
| `2609130009-empty-parent-plan.md` | `# t\n> **Parent:**\n---\n` | no |

Goldens (Python outputs, verified during planning, CRLF stripped):

```text
A:
2609120000-root-proposal.md
├── 2609120001-alpha-plan.md
│   └── 2609120003-grand-log.md
├── 2609120002-CASE-plan.md
├── 2609120002-case-plan.md
├── Zeta.md
├── ßeta.md
├── ！.md
└── 😀.md
B:
2609130000-root-proposal.md
├── 2609130001-nbsp-plan.md
├── 2609130002-lonecr-plan.md
├── 2609130003-formfeed-plan.md
├── 2609130004-preamble-plan.md
├── 2609130007-u2028-plan.md
└── 2609130008-late-heading-plan.md
C:
projex-tree: E_IDENTITY_DUPLICATE: 2609140003-twin-plan.md: child identity resolves to multiple documents
projex-tree: E_PARENT_DUPLICATE: .projex/2609140001-dup-plan.md: multiple Parent headers
projex-tree: E_PARENT_DUPLICATE: .projex/2609140001-dup-plan.md-old/2609140002-dup-plan.md: multiple Parent headers
```

Each fixture dir holds its docs plus `expected*.stdout|stderr|exit` files named per target (e.g. `expected-empty-parent.stderr`); write goldens as raw bytes (`printf` / `[IO.File]::WriteAllBytes`), never via editors that normalize.

`utf8-cases.tsv` (`label<TAB>hex<TAB>valid|invalid`), appended after a valid header `# t\n> **Parent:** User\n---\n`, one fresh temp repo per row, doc `.projex/2609160000-utf8-plan.md`; valid → exit 0, stdout `2609160000-utf8-plan.md\n`; invalid → exit 4, stderr `projex-tree: E_IO: .projex/2609160000-utf8-plan.md: invalid UTF-8\n`:

```text
nul	00	valid
two-byte	c2a9	valid
three-byte	e282ac	valid
max-bmp	efbfbf	valid
four-byte	f09f9880	valid
max-scalar	f48fbfbf	valid
inner-bom	efbbbf	valid
lone-cont	80	invalid
overlong-c0	c0af	invalid
overlong-c1	c1bf	invalid
overlong-e0	e080af	invalid
surrogate	eda080	invalid
overlong-f0	f08f8080	invalid
above-max	f4908080	invalid
lead-f5	f5808080	invalid
trunc-2	c2	invalid
trunc-3	e282	invalid
trunc-4	f09f98	invalid
trunc-before-lf	e2820a	invalid
byte-ff	ff	invalid
```

**Changes — suites** (both, mechanically parallel):
- Keep all 46 existing cases.
- Add: each fixture row above; `utf8-cases.tsv` loop; target `a\b.md` → `E_TARGET_NAME` (2) **(D6)**; targets `c:x.md` and `a:b.md` → `E_TARGET_NAME` (2) **(D7)**.
- C1 usage (D9 on pwsh): 0 args, 1 arg, 3 args, `. <R> -Verbose`, `. <R> --` → E_USAGE exit 2, exact stderr line; `'' <R>` → `projex-tree: E_REPO: : repository root not found` (2); `. ''` → `projex-tree: E_TARGET_NAME: <empty>: filename basename required` (2). pwsh suite invokes via `pwsh -NoProfile -File` so args reach the script unparsed by the caller.
- Repo arg is a `.projex` dir: `basic` copy, repo = `<tmp>/.projex` → golden from Python output (rel without `.projex/` prefix; parity, C2).
- `.GIT` (run time, `nested-repo` copy): `vendor/.GIT/` dir → vendored doc still discovered (ordinal `.git`, C2).
- NUL Parent (run time, fresh temp repo): `.projex/2609170000-nul-plan.md` = `# t\n> **Parent:** a\0b\n---\n`, target it → exit 3, stderr bytes `projex-tree: E_PARENT_MALFORMED: .projex/2609170000-nul-plan.md: Parent is not a projex filename: a\0b\n` (parity with Python; catches `$()` NUL loss).
- Links (run time, guarded): pwsh `New-Item -ItemType Junction` (dir) / `-ItemType SymbolicLink` (file); bash `MSYS=winsymlinks:nativestrict ln -s` (dir + file). Dir link under `.projex/` pointing at a dir with a doc → not descended; file link `x.md` → not discovered **(D5)**. Creation fails → print `SKIP <case>: link creation unsupported`, count neither PASS nor FAIL (identical counts wherever both suites share capability; both succeed on this host).
- Read failure / unenterable repo (run time, guarded): Windows `icacls <path> /deny "<user>:(R)"` (file) / `(RX)` (repo dir); POSIX non-root `chmod 000`. Expect `E_IO: <rel>: read failed` (4) **(D4)** / `E_REPO` (2) **(D8)**. Still readable after deny → `SKIP` as above. Restore ACL/mode before temp cleanup.
- Summary: `printf 'PASS=%d FAIL=%d\n'` / `"PASS=$Pass FAIL=$Fail"` (drop `CASES=`).
- Fixture copies: `cp -R` / `Copy-Item -Recurse` into temp, never run in-tree. Every invalid-byte / NUL / link / ACL input is created in the temp copy, never committed.

**Rationale:** Contract lives in shared bytes both platforms read (existing convention: "both platforms compare the same fixture corpus"). Fixtures chosen as discriminators: each fails if the specific pitfall (culture compare, UTF-16 order, whole-line error sort, full-path walk order, case-insensitive lookup, nested roots) is present.

**Verification:** Against Python engine, run both suites; every new *parity* case must fail only by CRLF (check by rerunning Python output through `tr -d '\r'` in a scratch harness and comparing to goldens → identical); D2/D3/D5–D9 cases fail on content (or `SKIP`). Record per-case outcome in the execution log. Corpus-poison check: `bash projex-tree.sh <work-root> 2608120933-parent-lineage-header-and-projex-tree-utility-proposal.md` → exit 0 (any `E_IO … tests/fixtures/…` → a committed fixture violates the Constraint; move the bytes to run time).

**If this fails:** golden mismatches beyond CRLF on a parity case → contract row is wrong; fix the golden from Python output only after confirming the Python behavior is intended (else convert it into an enumerated delta and stop for review).

---

### Step 3: bash engine

**Objective:** `projex-tree.sh` implements C1–C9 natively.
**Confidence:** Medium (single awk program; portability beyond gawk unverified)
**Depends on:** Step 2
**Verify-Projex:** Encouraged

**Files:** `projex-tree.sh`

**Changes:**

```bash
// Before:
exec python3 "$script_dir/.projex-tree.py" "$repo_root" "$filename"

// After (structure; one file, no helper files):
set -euo pipefail
# C1: usage / E_REPO ([ -d ] then cd, failure → E_REPO) / E_TARGET_NAME (case: '' | */* | *\\* | *:*)
# messages via printf '%s\n' ... >&2
nested=$(find . \( -path ./.git -o -name .projexwt \) -prune -o -name .git -print -prune 2>/dev/null || true)   # "./vendor/.git" → prefix "vendor/"; root .git pruned, never listed
docs=$(find . \( -name .git -o -name .projexwt \) -prune -o -type f -name '*.md' -path '*/.projex/*' -print 2>/dev/null || true)
#   repo root basename (pwd -P) is ".projex" → same find without -path (C2)
# stage 1 (LC_ALL=C awk): drop nested-repo prefixes; emit walk key:
#   rel with "/" → "\002", last separator → "\002\001"   (files < subdirs; "x" < "x-y")
# stage 2: LC_ALL=C sort
# stage 3 (LC_ALL=C awk, target via ENVIRON — avoids -v escape processing):
#   read each doc (getline < path; -1 → E_IO read failed, exit 4); close(path) after each doc (fd limit on BWK/mawk)
#   validate every physical line with U (below) after gsub(/\000/,"",t) → E_IO invalid UTF-8, exit 4
#   line 1: strip one "\357\273\277"; gsub C4 separators
#     (\015|\013|\014|\034|\035|\036|\302\205|\342\200\250|\342\200\251) → "\n"; split; C5 parse
#   then C6 graph; stdout "OK" block, or error records "code\001loc\001detail"; exit 0|2|3
#   stage-3 output → temp file (mktemp, trap-removed), never $(...) capture: bash drops NUL bytes (Parent values may hold NUL, C3)
# exit 3 → LC_ALL=C sort -u (\001 < every name byte ⇒ whole-record order = tuple order, C7)
#          → awk rejoins first two \001 as ": " with "projex-tree: " prefix → stderr
```

UTF-8 validator (probed on gawk 5.4):

```awk
U = "^([\001-\177]|[\302-\337][\200-\277]|\340[\240-\277][\200-\277]|[\341-\354\356\357][\200-\277][\200-\277]|\355[\200-\237][\200-\277]|\360[\220-\277][\200-\277][\200-\277]|[\361-\363][\200-\277][\200-\277][\200-\277]|\364[\200-\217][\200-\277][\200-\277])*$"
```

`strip` in awk: loop removing leading/trailing `[\011-\015\034-\040]`, `\302\205`, `\302\240`, `\341\232\200`, `\342\200[\200-\212]`, `\342\200\250`, `\342\200\251`, `\342\200\257`, `\342\201\237`, `\343\200\200`. Child sort: insertion sort with awk `<` under `LC_ALL=C` (byte order). Render recursive via awk function locals. Box glyphs as octal: `├──` `\342\224\234\342\224\200\342\224\200`, `└──` `\342\224\224\342\224\200\342\224\200`, `│` `\342\224\202`. No `'` inside the awk program (single-quoted shell string). No trailing `\` on any line (shell or awk) — `U` above built by concatenation on one line or successive `U = U "…"` statements.

**Rationale:** One awk process mirrors `projex-list.sh` precedent and reads each file once. `\001`/`\002` keys replace a hand-written walker. Rejected: `iconv` (not guaranteed, surrogate handling varies), `grep -axv` locale tricks (msys locale support uncertain), gawk-only `asort` (portability).

**Verification:** `bash tests/projex-tree.test.sh` → `FAIL=0`. `grep -c -i python projex-tree.sh` → 0. Non-ASCII check: `LC_ALL=C grep -n '[^[:print:][:space:]]' projex-tree.sh` → none. Continuation check: `grep -n '\\$' projex-tree.sh tests/projex-tree.test.sh` → none. CRLF-copy run (before Step 4): copy `projex-tree.sh`, `tests/projex-tree.test.sh`, `tests/fixtures/projex-tree/` into a scratch dir (same relative layout), `sed -i 's/$/\r/'` the two scripts, run the copied suite → `FAIL=0`.

**If this fails:** `git -C <work-root> checkout -- projex-tree.sh` (Python wrapper back); suites return to Step 2 state.

---

### Step 4: PowerShell engine

**Objective:** `projex-tree.ps1` implements C1–C9 natively.
**Confidence:** Medium
**Depends on:** Step 2 (independent of Step 3)
**Verify-Projex:** Encouraged

**Files:** `projex-tree.ps1`

**Changes:**

```powershell
# Before: lines 11-19 locate python and run .projex-tree.py

# After (structure):
# no [CmdletBinding()], no param block (C1): $args.Count -ne 2 → E_USAGE; $RepoRoot, $Filename = $args
# Emit([string]$Text, [int]$Code, [bool]$Err): UTF8Encoding($false).GetBytes → OpenStandardError/Output; exit $Code
# E_REPO: '' first (Test-Path throws on ''), then Test-Path -LiteralPath -PathType Container, then a materialized
#   enumeration of the root (failure → E_REPO, D8); Root = (Resolve-Path -LiteralPath).ProviderPath.TrimEnd('\','/')
# E_TARGET_NAME: '' | IndexOfAny('/','\',':') -ge 0
# Walk(dir, inProjex): try { $e = @($d.EnumerateFileSystemInfos()) } catch → return (C2 silent skip)
#   materialize inside try: enumeration is lazy, UnauthorizedAccessException fires on first MoveNext
#   (EnumerationOptions alternative needs IgnoreInaccessible=$true AND AttributesToSkip=0 — default skips Hidden|System)
#   dir below root with any $e entry Name -ceq '.git' → return (ordinal, not Test-Path: NTFS case-insensitive)
#   files: not Directory, $null -eq LinkTarget, Name.EndsWith('.md', Ordinal); sorted C8; emit when inProjex
#   dirs:  Directory, $null -eq LinkTarget, Name -cne '.git' -and -cne '.projexwt'; sorted C8;
#          recurse with (inProjex -or Name -ceq '.projex')
# initial call: Walk(Root, (Split-Path -Leaf Root) -ceq '.projex')   (C2 repo-is-.projex parity)
# Read: ReadAllBytes (IOException|UnauthorizedAccessException → E_IO read failed);
#   strip one EF BB BF; UTF8Encoding($false,$true).GetString (DecoderFallbackException → E_IO invalid UTF-8)
# Lines: [regex]::Split($text, '\r\n|[\n\r\v\f\x1c\x1d\x1e\x85\u2028\u2029]')   # single-quoted: regex escapes, not PS
# Strip: $s.Trim([char[]] C5 set)   # String.Trim() alone misses 1C-1F
# Prefix tests: StartsWith(x, [StringComparison]::Ordinal)
# Maps: [Collections.Generic.Dictionary[string,object]]::new([StringComparer]::Ordinal); HashSet[string] Ordinal
# NAME_RE: -cmatch with explicit [0-9]{10}
# C8 comparer: UTF-8 byte arrays compared lexicographically, shorter-prefix first
# Errors: HashSet dedupe of "code`0loc`0detail"; List.Sort with tuple comparer (C8 per field)
# Glyphs: [char]0x251C, 0x2514, 0x2500, 0x2502 — no non-ASCII literals
```

Forbidden in engine (case-insensitive or culture): `@{}` for name maps, `-eq/-ne/-in/-contains/-match/-split/-like` on names or headers, `Sort-Object`, `Select-Object -Unique`, `[string]::CompareOrdinal` for ordering, `[Console]::Error.WriteLine`, `Write-Output` for payload, `TrimStart([char]0xFEFF)` (strips repeatedly), `[CmdletBinding()]` / `param(...)` (binder pre-empts C1), `Test-Path` for child `.git` (case-insensitive on NTFS), lazy `Enumerate*` outside the `try`.

**Rationale:** Each forbidden construct was confirmed or is documented to diverge from C5/C8 (probe: culture `StartsWith` + soft hyphen; `CompareOrdinal` UTF-16 order). `LinkTarget` over `ReparsePoint` — OneDrive/dedup placeholders are reparse points but not links.

**Verification:** `pwsh -NoProfile -File tests/projex-tree.test.ps1` → `FAIL=0`, same PASS count as bash. `Select-String -Pattern 'python' projex-tree.ps1` → none. `LC_ALL=C grep -n '[^[:print:][:space:]]' projex-tree.ps1` → none.

**If this fails:** `git -C <work-root> checkout -- projex-tree.ps1`.

---

### Step 5: Differential oracle run

**Objective:** Prove sh ≡ ps1 ≡ Python modulo D1–D9 beyond the fixtures.
**Confidence:** High
**Depends on:** Steps 3, 4

**Files:** none committed — harness in session scratchpad only.

**Changes:** Scratch harness (bash) runs `python3 .projex-tree.py`, `projex-tree.sh`, `pwsh -NoProfile -File projex-tree.ps1` on:
1. Every fixture repo × every discovered doc as target.
2. This repo (`<work-root>`) × every `.md` under any `.projex/` as target (~88 docs + committed fixture docs).
3. Every `utf8-cases.tsv` row.

Non-vacuity: harness prints per-engine exit-0 count for item 2; must be ≥1 and equal across engines (a corpus-wide identical `E_IO` would otherwise read as zero mismatches).

Compare `(exit, stdout, stderr)`; Python streams through `tr -d '\r'` (D1). Expected mismatches: only rows attributable to D2–D9 — list each in execution log with its delta id.

Then CRLF-materialization check: `git clone -b <ephemeral-branch> <repo-root> <scratch>/clone` (after Step 3–4 commits), run both suites there → `FAIL=0` (autocrlf=true CRLF scripts + `-text` fixtures).

**Verification:** Harness prints `MISMATCH` count and item-2 exit-0 counts; every mismatch mapped to D2–D9; zero sh↔ps1 mismatches; exit-0 count ≥1. Harness command set (sh↔ps1 part) copied verbatim into the execution log → carried into the walkthrough, reusable as the sh↔ps1 cross-check after Python is gone.

**If this fails:** unexplained mismatch → fix the diverging engine (Step 3/4); if Python is right and the contract silent, add a contract clause + fixture before continuing.

---

### Step 6: Delete Python engine; update docs

**Objective:** Remove runtime dependency and its documentation.
**Confidence:** High
**Depends on:** Step 5
**Do-Projex:** Encouraged

**Files:** `.projex-tree.py` (delete via `del-n-stage`), `README.md`, `tests/README.md`

**Changes:**

```markdown
// README.md — Before:
| `projex-tree` | Read-only complete current-corpus Parent lineage tree; requires Python 3 |
// After:
| `projex-tree` | Read-only complete current-corpus Parent lineage tree |

// tests/README.md — Before:
| `projex-tree.test.sh` / `.ps1` | 46 each | Shared current-corpus tree goldens, target-component failures including reachable duplicate Parent and invalid UTF-8 discovery, BOM/CRLF, and parity |
// After (N = PASS count from Step 3/4 runs):
| `projex-tree.test.sh` / `.ps1` | N each | Shared current-corpus tree goldens, target-component failures including reachable duplicate Parent and invalid UTF-8 discovery, BOM/CRLF, header-parse quirks, code-point ordering, tuple error order, walk-order `E_IO`, UTF-8 validity table, nested repo/`.projex` handling, and parity |
```

**Rationale:** Python kept until Step 5 as oracle; after, it is dead weight and a second source of truth.

**Verification:** `test ! -e .projex-tree.py`; `grep -rn -i python README.md tests/README.md projex-tree.*` → none; both suites and both `run-all` runners green for projex-tree.

**If this fails:** `git -C <work-root> checkout HEAD -- .projex-tree.py README.md tests/README.md`.

---

## Verification Plan

### Automated Checks
- [x] `bash tests/projex-tree.test.sh` → `PASS=N FAIL=0`
- [x] `pwsh -NoProfile -File tests/projex-tree.test.ps1` → `PASS=N FAIL=0` (same N)
- [x] `bash tests/run-all.sh` / `pwsh tests/run-all.ps1` → projex-tree suite summarized, no failure note
- [x] Step 5 harness: 0 unexplained mismatches, 0 sh↔ps1 mismatches, corpus exit-0 count ≥1
- [x] Fresh-clone suite run → `FAIL=0`
- [x] Step 2 corpus-poison check → exit 0; Step 3 continuation grep empty + CRLF-copy run `FAIL=0`

### Manual Verification
- [x] Run `projex-tree.{sh,ps1}` on `2608120933-parent-lineage-header-and-projex-tree-utility-proposal.md` in the real repo; output matches Python (`tr -d '\r'`) captured before Step 6.
- [x] `PATH` without Python: `env PATH=/usr/bin:/bin bash projex-tree.sh . <doc>` (Git Bash; pyenv shims absent) → exit 0.

### Acceptance Criteria Validation

| Criterion | How to Verify | Expected Result |
|-----------|---------------|-----------------|
| No Python | `test ! -e .projex-tree.py`; grep | absent / no hits |
| Suites green, runner-parseable | both suites + runners | `FAIL=0`, no summary warning |
| LF UTF-8 output | byte goldens via `cmp` / `Get-FileHash` | pass on Windows |
| Parity modulo D1–D9 | Step 5 harness | all mismatches mapped |
| autocrlf-proof | fresh clone run | `FAIL=0` |

---

## Rollback Plan

1. Before close: `projex-abandon` the ephemeral branch with `--worktree` (nothing reached `main`).
2. After close: `git revert` the squash commit on `main`; Python engine and wrapper return intact.

---

## Revision Log

- **2026-10-01:** Stress remediation applied — `io-order` invalid bytes moved to run time + Constraint forbidding committed invalid fixture docs + Step 2 corpus-poison check; Step 5 non-vacuity (exit-0 count ≥1) and recorded sh↔ps1 cross-check; C1 pwsh rewritten (no `CmdletBinding`/`param`, `$args` exact-2) + usage/empty-arg suite cases; Step 1 pre-gate on committed `projex-list` / clean README+runners; no-continuation Constraint + Step 3 grep and CRLF-copy run; C2 ordinal child-`.git` detection and repo-is-`.projex` Python parity; deltas D7 (drive colon), D8 (unenterable repo), D9 (pwsh wrapper CLI); NUL-safe stage-3 capture + NUL-Parent case; guarded link / ACL suite cases; materialized pwsh enumeration; awk `close(path)`; U+2028/2029 literals in Step 4 snippet → `\u` escapes — trigger: 2610010520-projex-tree-native-port-plan-stress.md Findings 1–10, Compound 1 (re-verified: pwsh `. a b c` → exit 1; Python line 21 `basename(base) == '.projex'`; unprivileged `New-Item -ItemType Junction|SymbolicLink` succeeded; snippet bytes `342 200 250 342 200 251`).
- **2026-10-01:** D7 flipped — target containing `:` now `E_TARGET_NAME` (2) on every OS instead of `E_TARGET_NOT_FOUND`; C1, D7, Step 2 suite row (`c:x.md`, `a:b.md`), Step 3/4 target-name sketches, Open Questions updated — trigger: human directive "Forbid : in projex file names" (rule added to SKILL.md § Authoring).

---

## Notes

### Risks
- **Non-gawk awk (macOS BWK/mawk) byte-range regex or NUL handling differs:** contract fixed by fixtures; any future macOS run of the suite surfaces it. Not verifiable on this host.
- **awk recursion depth / O(members × docs) BFS:** corpus ~88 docs, trees shallow; acceptable, same complexity as Python.
- **Worktree created before `.gitattributes`:** handled in Step 1 re-materialization; skipping it makes goldens CRLF and every byte-exact case fail.
- ~~Read-failure path has no automated test; D5 (symlinks) has no automated test — needs Developer Mode/admin~~ (superseded 2610-01: unprivileged junction + symlink creation verified on this host → guarded suite cases in Step 2). Residual: `icacls` deny unverified; if it does not block reads, read-failure / D8 cases `SKIP` here and run only on POSIX.
- **Fixture corpus pollution:** ~30 synthetic fixture docs (twins, dup Parents, `Zeta.md`) join this repo's `projex-list`/`projex-tree` corpus. Revisit if `projex-list` output here becomes noisy (option: store fixture trees under a non-`.projex` dir renamed at copy time).
- **No Python oracle after Step 6:** sh↔ps1 agreement guarded by shared goldens + the recorded Step 5 cross-check; rerun it on the first edit to either engine after close.
- **Filenames with `\n`/`\001`/`\002`:** unsupported by bash pipeline (Assumption); pwsh unaffected.

### Sibling observations (out of scope — `projex-list`)
- `projex-list.ps1` uses culture `StartsWith`, `GetFiles('*.md')` (case-insensitive on Windows), and `TrimStart([char]0xFEFF)`; `projex-list.sh` does not split lone `\r`. Header grammar thus differs subtly between the two tools. Candidate follow-up after this port lands.
- `tests/fixtures/projex-list/` goldens have the same autocrlf exposure fixed here for projex-tree.

### Split Verdict
`No split — single scope` (6 steps; ~500 lines after stress revision — growth is added checks, not scope; Steps 3/4 share the Step 2 contract and Step 5 needs both).

### Open Questions
- (none — D1–D6 per human-confirmed "port, fix nested-repo bug deliberately"; D7–D9 added by stress revision as rare-input / wrapper-CLI deltas; D7 settled by human 2026-10-01 (reject `:`); human may still prefer matching Python for D8)

