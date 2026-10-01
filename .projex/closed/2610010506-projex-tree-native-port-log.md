# Execution Log: projex-tree Native Port

> **Status:** Complete
> **Started:** 20261001 06:40
> **Repo Root:** S:/Repos/projex
> **Plan File:** .projex/2610010506-projex-tree-native-port-plan.md
> **Parent:** 2610010506-projex-tree-native-port-plan.md
> **Base Branch:** main
> **Worktree Path:** projex/.projexwt/2610010506-projex-tree-native-port

## Pre-Check Results
```
PASS  Plan is committed (a0adf32 projex: add plan - projex-tree-native-port (with stress report))
WARN  Working tree has 18 uncommitted change(s)
PRE-CHECK PASSED
```
WARN: all 18 are untracked files in the base checkout unrelated to this plan (zips, other `.projex` docs, `.codegraph/`, `.github/`, `.gitignore`); worktree mode isolates execution from them.

## Initialization
- Plan status → In Progress, committed on `main` (52459cf).
- Worktree created via `projex-worktree.sh` on branch `projex/2610010506-projex-tree-native-port`. Bootstrap: none needed (no package manifest; tools = bash/awk/pwsh/python3 on host).

## Steps

### [20261001 06:45] - Step 1: Pin fixture line endings
**Action:** Pre-gate in `<repo-root>`: `git status --porcelain -- README.md tests/README.md tests/run-all.sh tests/run-all.ps1` → empty output (rc 0); `git ls-files --error-unmatch projex-list.sh projex-list.ps1` → both listed (rc 0). Appended `tests/fixtures/projex-tree/** -text` to existing `.gitattributes` (file already present from 5ce0c28 with the projex-list line — see Deviations). Deleted worktree `tests/fixtures/projex-tree` from disk, `git checkout -- tests/fixtures/projex-tree`.
**Result:** `git ls-files --eol tests/fixtures/projex-tree` → every row `w/lf` (one `w/none`: empty `basic/expected.stderr`), all `attr/-text`. `git status --porcelain` → only `.gitattributes` (+ this log). Baseline `bash tests/projex-tree.test.sh` → `PASS=39 FAIL=7 CASES=46` (Python CRLF output), as expected.
**Status:** Success

### [20261001 07:20] - Step 2: Contract fixtures + suites (fail-first)
**Action:** Generated fixtures as raw bytes with a scratch `printf` script: `nested-projex/`, `nested-repo/`, `sort-order/`, `header-quirks/`, `error-order/`, `io-order/` (docs + `expected*.stdout|stderr` goldens) and `utf8-cases.tsv` (20 rows). Extended `tests/projex-tree.test.sh` and `tests/projex-tree.test.ps1` (46 existing cases kept) with mechanically parallel `expect`/`Expect` helpers (3 assertions each: exit, stdout bytes, stderr bytes): every fixture row, UTF-8 table loop, D6/D7 target names, C1 usage (0/1/3 args, `-Verbose`, `--`, empty repo, empty target), repo-is-`.projex`, `.GIT`, NUL Parent, guarded dir/file links, guarded read-deny / repo-deny (icacls on Windows, chmod 000 on POSIX). Summary → `PASS=n FAIL=n`. pwsh suite spawns `pwsh -NoProfile -File` via `ProcessStartInfo.ArgumentList` and reads raw stdout/stderr bytes (empty args and `-Verbose`/`--` reach the script verbatim; no host re-encoding).
**Result:**
- Goldens A/B/C + empty-parent, io-order first/second, repo-is-`.projex` (`unrelated-malformed.md` loc without `.projex/`), NUL Parent: confirmed against Python (CR stripped) before committing.
- Bash suite vs Python wrapper: `PASS=140 FAIL=65` (205 assertions). Same suite against a scratch CR-stripping Python wrapper (D1 removed): `PASS=185 FAIL=20`; the 20 remaining all map to deltas: nested-projex-root/inner (D3), nested-repo-dir/-file + targets (D2), link-file-root/target (D5), read-failed stderr (D4: Python detail = OS message), unenterable-repo stderr (D8: Python `E_TARGET_NOT_FOUND`). Every parity case differs only by CRLF.
- pwsh suite vs old wrapper: `PASS=129 FAIL=76` (205 assertions, equal to bash). Extra vs bash: usage-0/1 stderr CRLF (D6 tail), usage-3/`--` exit 1 binding error, `-Verbose` exit 0 (common param bind), empty-repo/empty-target → old E_USAGE (all D9); link-dir-target exit 0 (Python walks a junction; C2 says not descended — link delta, grouped with D5).
- No `SKIP` on this host: junction/symlink creation, icacls file `(R)` and dir `(RX)` denial all effective (probe: `cd` into RX-denied dir → Permission denied; awk `getline` on R-denied file → -1).
- Corpus-poison check: `bash projex-tree.sh <work-root> 2608120933-parent-lineage-header-and-projex-tree-utility-proposal.md` → exit 0, 5-line tree.
- Continuation check `grep -n '[\]$' tests/projex-tree.test.sh` → none; non-ASCII check on both suites → none.
**Status:** Success

### [20261001 07:45] - Step 3: bash engine
**Action:** Rewrote `projex-tree.sh` as a native engine (no helper files): C1 checks (`[ -d ]` + `CDPATH='' cd -P`, `-` guarded as `./-`; `case` target filter `''`/`*/*`/`*\\*`/`*:*`); nested-repo `find … -name .git -print -prune` prefix list; doc `find` (`-type f -name '*.md' -path '*/.projex/*'`, or `-path '*'` when `pwd -P` basename is `.projex`); stage-1 awk walk key (dir components + `\002`, name prefixed `\001`; drops nested-repo prefixes); `LC_ALL=C sort`; stage-3 awk engine (getline read, `-1` → `read failed`; NUL-stripped per-line UTF-8 regex built by `UTF8 = UTF8 "…"` concatenation; one-BOM strip; C4 separators → `\n` split; C5 parse with byte-exact `strip`; C6 chain + BFS; insertion-sort render with octal box glyphs). Engine output → `mktemp` file (trap-removed); exit 3 → `LC_ALL=C sort -u` + awk rejoin of the first two `\001` as `: `. Pipeline continues via trailing `|` (no backslash continuations).
**Result:** `bash tests/projex-tree.test.sh` → `PASS=205 FAIL=0`, no SKIP. `grep -c -i python projex-tree.sh` → 0. Non-ASCII grep → none. Continuation grep `[\]$` on `projex-tree.sh` + suite → none. CRLF-copy run (both scripts `sed`-converted to CRLF in scratch, fixtures copied) → `PASS=205 FAIL=0`. Real repo: tree for `2608120933-parent-lineage-header-and-projex-tree-utility-proposal.md` byte-identical to Python (`tr -d '\r'`), 0.54 s; `env PATH=/usr/bin:/bin` run → exit 0.
**Status:** Success

### [20261001 08:30] - Step 4: PowerShell engine
**Action:** Rewrote `projex-tree.ps1` as a native .NET engine: no `param`/`[CmdletBinding()]`, `$args.Count -ne 2` → E_USAGE; raw-byte `Emit` via `OpenStandardOutput/Error` (UTF-8 no BOM, LF); E_REPO = `[IO.Directory]::Exists` + `GetFullPath` + materialized `GetFileSystemEntries` (D8); E_TARGET_NAME on empty / `IndexOfAny('/','\',':')`; recursive `Walk` (materialized `EnumerateFileSystemInfos` inside `try`, ordinal `.git` entry check below root, `LinkTarget` skip, `.md` ordinal suffix, files then dirs in `Utf8Order`, repo-is-`.projex` via resolved root name); `ReadAllBytes` → one-BOM strip → strict `UTF8Encoding($false,$true)`; `[regex]::Split` C4 breaks; ordinal `StartsWith`/`Trim([char[]] isspace set)`; ordinal `Dictionary`/`HashSet`; chain + BFS port; errors NUL-joined in an ordinal `HashSet`, sorted with `Utf8Order` (PowerShell class implementing `IComparer[string]`, UTF-8 byte compare); glyphs via `[char]` codes.
**Result:** `pwsh -NoProfile -File tests/projex-tree.test.ps1` → `PASS=205 FAIL=0` (= bash count), no SKIP. `python` grep on both engines → 0. Non-ASCII grep → 0 (after fixing two escapes the file-write tool had materialized as literal U+00AD / U+2028 / U+2029 — regex now appends `[char]0x2028 + [char]0x2029`). Real repo tree for `2608120933-…-proposal.md` exit 0, ~0.6 s.
**Status:** Success

### [20261001 08:50] - Step 5: Differential oracle run
**Action:** Scratch harness (session scratchpad, not committed) ran `python3 .projex-tree.py` (stdout/stderr `tr -d '\r'`, D1), `projex-tree.sh`, and `pwsh -NoProfile -File projex-tree.ps1` on (1) every committed fixture repo (`basic`, `nested-projex`, `nested-repo`, `sort-order`, `header-quirks`, `error-order`, `io-order`) x every discovered doc name, plus run-time variants `nested-repo` + `vendor/.git` and `io-order` + `FF` docs under `x/` and `x-y/`; (2) `<work-root>` x every `.md` name under any `.projex/` (committed fixture docs included); (3) every `utf8-cases.tsv` row. Compared `(exit, stdout, stderr)` bytes. Then `git clone -b projex/2610010506-projex-tree-native-port <repo-root> <scratch>/clone` (global `core.autocrlf=true`) and ran both suites there.
**Result:**
- Runs: fixtures=37, corpus=107, utf8=20 (x3 engines; 6 m 37 s, pwsh startup-dominated).
- `SH-PS MISMATCH: 0`.
- Corpus exit-0 counts (non-vacuity): sh=99, ps=99, py=97.
- `SH-PY MISMATCH: 6`, all mapped: `fixture:nested-projex` root (py `E_IDENTITY_DUPLICATE` inner, exit 3) and inner (py `E_TARGET_AMBIGUOUS`, exit 2) → **D3**; same two names in `corpus` (the committed `nested-projex` fixture is corpus) → **D3**; `fixture:nested-repo+git` host (py tree includes vendored child) and vendored target (sh `E_TARGET_NOT_FOUND`, py exit 0) → **D2**. No unexplained mismatch; every UTF-8 row identical across all three engines.
- Fresh clone: `projex-tree.sh`, `projex-tree.ps1`, `tests/projex-tree.test.sh` materialized CRLF; fixtures `w/lf` / `-text`. `bash tests/projex-tree.test.sh` → `PASS=205 FAIL=0`; `pwsh -NoProfile -File tests/projex-tree.test.ps1` → `PASS=205 FAIL=0`. Clone removed.
- Manual check (plan § Manual Verification) — real repo, `2608120933-parent-lineage-header-and-projex-tree-utility-proposal.md`: sh and ps1 output byte-identical to Python (`tr -d '\r'`), captured before Step 6 (covered by corpus run + Step 3 check).

Harness (sh<->ps1 cross-check runs without Python via `--no-python`; rerun on the first edit to either engine):

```bash
#!/usr/bin/env bash
# Differential harness: sh vs ps1 (and Python oracle when present) over fixture repos, the work-root corpus,
# and the UTF-8 table. Usage: diff-harness.sh <work-root> [--no-python]
set -uo pipefail
W=$1
PY=1; [ "${2:-}" = --no-python ] && PY=0
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
mism=0; shps=0
declare -A zero
run() { # engine repo target -> $T/<engine>.{o,e,c}
    local e=$1 r=$2 t=$3
    case $e in
        sh) bash "$W/projex-tree.sh" "$r" "$t" > "$T/sh.o" 2> "$T/sh.e" < /dev/null; echo $? > "$T/sh.c" ;;
        ps) pwsh -NoProfile -File "$W/projex-tree.ps1" "$r" "$t" > "$T/ps.o" 2> "$T/ps.e" < /dev/null; echo $? > "$T/ps.c" ;;
        py) python3 "$W/.projex-tree.py" "$r" "$t" > "$T/py.raw.o" 2> "$T/py.raw.e" < /dev/null; echo $? > "$T/py.c"
            tr -d '\r' < "$T/py.raw.o" > "$T/py.o"; tr -d '\r' < "$T/py.raw.e" > "$T/py.e" ;;
    esac
}
same() { cmp -s "$T/$1.c" "$T/$2.c" && cmp -s "$T/$1.o" "$T/$2.o" && cmp -s "$T/$1.e" "$T/$2.e"; }
check() { # group repo target
    local g=$1 r=$2 t=$3
    run sh "$r" "$t"; run ps "$r" "$t"
    if ! same sh ps; then shps=$((shps + 1)); echo "SHPS-MISMATCH [$g] $t: sh=$(cat "$T/sh.c") ps=$(cat "$T/ps.c")"; head -c 300 "$T/sh.e"; head -c 300 "$T/ps.e"; fi
    if [ "$g" = corpus ] && [ "$(cat "$T/sh.c")" = 0 ]; then zero[sh]=$(( ${zero[sh]:-0} + 1 )); fi
    if [ "$g" = corpus ] && [ "$(cat "$T/ps.c")" = 0 ]; then zero[ps]=$(( ${zero[ps]:-0} + 1 )); fi
    if [ "$PY" = 1 ]; then
        run py "$r" "$t"
        if [ "$g" = corpus ] && [ "$(cat "$T/py.c")" = 0 ]; then zero[py]=$(( ${zero[py]:-0} + 1 )); fi
        if ! same sh py; then
            mism=$((mism + 1))
            echo "MISMATCH [$g] $t: sh=$(cat "$T/sh.c") py=$(cat "$T/py.c")"
            echo "  sh.err: $(head -c 200 "$T/sh.e" | tr '\n' '|')"
            echo "  py.err: $(head -c 200 "$T/py.e" | tr '\n' '|')"
            echo "  stdout-equal: $(cmp -s "$T/sh.o" "$T/py.o" && echo yes || echo no)"
        fi
    fi
}
targets() { find "$1" \( -name .git -o -name .projexwt \) -prune -o -type f -name '*.md' -path '*/.projex/*' -print | sed 's|.*/||' | LC_ALL=C sort -u; }

F=$W/tests/fixtures/projex-tree
n1=0
for fx in basic nested-projex nested-repo sort-order header-quirks error-order io-order; do
    rm -rf "$T/repo"; cp -R "$F/$fx" "$T/repo"
    while IFS= read -r t; do check "fixture:$fx" "$T/repo" "$t"; n1=$((n1 + 1)); done < <(targets "$T/repo")
done
# run-time variants
rm -rf "$T/repo"; cp -R "$F/nested-repo" "$T/repo"; mkdir "$T/repo/vendor/.git"
for t in 2609110000-host-proposal.md 2609110001-vendored-plan.md; do check fixture:nested-repo+git "$T/repo" "$t"; n1=$((n1 + 1)); done
rm -rf "$T/repo"; cp -R "$F/io-order" "$T/repo"; mkdir -p "$T/repo/.projex/x" "$T/repo/.projex/x-y"
printf '\377' > "$T/repo/.projex/x/2609150003-bad-plan.md"; printf '\377' > "$T/repo/.projex/x-y/2609150004-bad-plan.md"
check fixture:io-order+bad "$T/repo" 2609150000-root-proposal.md; n1=$((n1 + 1))

n2=0
while IFS= read -r t; do check corpus "$W" "$t"; n2=$((n2 + 1)); done < <(targets "$W")

n3=0
tab=$(printf '\t')
while IFS=$tab read -r label hex verdict; do
    rm -rf "$T/u8"; mkdir -p "$T/u8/.projex"
    { printf '# t\n> **Parent:** User\n---\n'; printf '%s' "$hex" | sed 's/../\\x&/g' | xargs -0 printf '%b'; } > "$T/u8/.projex/2609160000-utf8-plan.md"
    check "utf8:$label" "$T/u8" 2609160000-utf8-plan.md; n3=$((n3 + 1))
done < "$F/utf8-cases.tsv"

echo "RUNS: fixtures=$n1 corpus=$n2 utf8=$n3"
echo "CORPUS EXIT-0: sh=${zero[sh]:-0} ps=${zero[ps]:-0} py=${zero[py]:-0}"
echo "SH-PS MISMATCH: $shps"
[ "$PY" = 1 ] && echo "SH-PY MISMATCH: $mism"
```
**Status:** Success

### [20261001 09:10] - Step 6: Delete Python engine; update docs
**Action:** `del-n-stage.sh <work-root> .projex-tree.py`. `README.md` tree row → `Read-only complete current-corpus Parent lineage tree` (dropped "; requires Python 3"). `tests/README.md` tree row → `205 each` + extended coverage text (plan wording).
**Result:** `test ! -e .projex-tree.py` ✓. `grep -rn -i python README.md tests/README.md projex-tree.*` → none; `git grep -i python -- ':!.projex'` → none. `bash tests/projex-tree.test.sh` → `PASS=205 FAIL=0`; `pwsh -NoProfile -File tests/projex-tree.test.ps1` → `PASS=205 FAIL=0`. `bash tests/run-all.sh` → projex-tree summarized `PASS=205 FAIL=0`, total `PASS=494 FAIL=0`, no summary warning. `pwsh tests/run-all.ps1` → projex-tree `PASS=205 FAIL=0`, no warning for it; `new-projex.test.ps1` (`PASS=188 FAIL=1`, "creator inventory") and `close-precheck.test.ps1` (`PASS=17 FAIL=19`) flagged — pre-existing: identical counts on `main` in `<repo-root>`, files untouched by this branch (see Issues).
**Status:** Success

## Deviations
- Step 1: `.gitattributes` already existed (5ce0c28, `tests/fixtures/projex-list/** -text`); line appended instead of file created. No outcome impact.
- Step 2: `nested-repo` vendored doc placed at `vendor/.projex/…` (repo-root level, submodule-like) rather than under the host `.projex/`, so the no-`.git` case stays a Python-parity case and only the `.git` cases exercise D2 (under `.projex/` it would also trip D3). `nested-projex` keeps `inner/.projex/` under `.projex/` (D3 needs it).
- Step 2: link cases expect `R\n` for the root target as well as `E_TARGET_NOT_FOUND` for the linked target (plan named only "not descended / not discovered"); the dir-link case in pwsh uses a junction, which Python descends — recorded as a link-handling delta alongside D5.
- Step 2: suite temp dir for the NUL-Parent case named `nulparent`, not `nul` — `nul` is a reserved device name on Windows (`isdir` false → spurious E_REPO).
- Step 2: bash `expect` runs the engine with `</dev/null` — without it a child consumed the `utf8-cases.tsv` loop's stdin and the loop ran once.
- Step 4: pwsh E_REPO uses `[IO.Directory]::Exists` + `[IO.Path]::GetFullPath` instead of the sketched `Test-Path -LiteralPath -PathType Container` + `Resolve-Path` — same literal-path semantics, but no PowerShell-drive acceptance (`Env:`, `HKLM:`) and no `Test-Path ''` throw; materialized root enumeration kept (D8).
  - Superseded (audit 2610011956-projex-tree-native-port-audit.md): not equivalent for relative paths — one-arg `GetFullPath` / `Directory.Exists` resolve against process CWD, not `$PWD`. Fixed via 2610012008-projex-tree-relative-repo-root-patch.md (relative root joined to `Get-Location -PSProvider FileSystem`).
- Step 4: two of the 46 pre-existing pwsh cases (duplicate-parent stderr, invalid-UTF-8 stderr) captured the engine via `& pwsh … 2>$Err`; PowerShell 7.6 rewrites native stderr lines with CRLF there, so LF output (D1) could never hash-match. Those two invocations now go through a `RunRaw` helper (same `ProcessStartInfo` byte capture as the new cases); assertions and counts unchanged. `InvokeTree` moved above the old cases for that.

## Issues Encountered
- Bash-tool command strings collapse `\\` → `\`; fixture generation and suite/harness files were therefore written through the file-write tool or verified byte-wise (fixture goldens confirmed against Python before commit).
- File-write tool turned backslash-u escape text (U+00AD in a comment; U+2028 / U+2029 in the line-break regex) in `projex-tree.ps1` into literal characters; caught by the Step 4 non-ASCII grep and replaced with `[char]` concatenation / plain wording.
- Out of scope, pre-existing on `main`: `tests/new-projex.test.ps1` → `PASS=188 FAIL=1` ("creator inventory"); `tests/close-precheck.test.ps1` → `PASS=17 FAIL=19`. `pwsh tests/run-all.ps1` exits nonzero for these two suites independent of this plan.

## Data Gathered
- Corpus check (64 real, non-fixture doc names in `<work-root>`): 62 exit 0; 2 exit 3 with `E_PARENT_DANGLING` (`2608121919-parent-lineage-audit-remediation-patch.md` → `2608121912-…-audit.md`, `2608130629-new-projex-powershell-suite-exit-status-patch.md` → `2608130624-…-audit.md`): Parents name audit docs that exist nowhere (absent from disk in base and worktree, and from all git history — corrected at close; originally logged as "only untracked in the base checkout"). Content errors, identical under Python; not fixture-caused (no `E_IO`).

## Post-Execution
- Full verification: both suites `PASS=205 FAIL=0` (worktree + fresh autocrlf clone of final branch, `.projex-tree.py` absent); `run-all.sh` green; `run-all.ps1` projex-tree green (2 unrelated pre-existing suite failures, see Issues); harness `SH-PS MISMATCH: 0`, SH-PY mismatches all D2/D3.
- Spec compliance (plan contract C1-C9, D1-D9, Constraints): met. D1/D6-tail LF output, D2, D3, D4, D5 (+ junction), D7, D8, D9 each covered by a suite case; ASCII-only engines; no backslash-newline continuation in `projex-tree.sh` / `tests/projex-tree.test.sh`; no gawk-only features; pwsh engine runs no external process. Unverifiable here (plan Risk): non-gawk awk (BWK/mawk) behavior.
- Quality review: no projex IDs / plan shape in sources; rationale comments name rejected alternatives (raw-path sort, `$(...)` capture, `cd -`/CDPATH, `[CmdletBinding()]`, culture compares, `CompareOrdinal`, `TrimStart`, `Test-Path`, `ReparsePoint`, console writers).
- Cleanup: scratch CRLF copy and both scratch clones removed; harness/fixture generator remain in the session scratchpad only (outside the repo). Worktree `git status --porcelain` clean before final commit; no deps installed.

## User Interventions
