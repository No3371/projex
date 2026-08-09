# tests

Behavioural tests for the git-safety-critical utility scripts. Projex is a prompt framework with no
build system — these exist because the close scripts rewrite history and delete branches, so a silent
regression there costs real work.

## Running

```bash
tests/run-all.sh
```

```powershell
pwsh tests/run-all.ps1
```

Each suite creates throwaway repositories under the system temp directory, exercises the scripts
against them, and removes them afterwards. Nothing touches the repository you run them from, and no
network or fixtures are needed — only `git` and the relevant shell. A suite exits non-zero if any
assertion fails; the runners aggregate and do the same.

## Coverage

| Suite | Assertions | Covers |
| ------- | -----------: | -------- |
| `resolve-conflicts.test.sh` | 30 | `--resolve-conflicts` core contract: covered conflicts halt (exit 2), uncovered abort (exit 1), no-flag behaviour unchanged, directory-prefix vs exact-file matching, `.projexwt` not matched by a `.projex` entry |
| `resume.test.sh` | 52 | What a careless caller does between exit 2 and the re-run: re-running having done nothing, resolving without `git add`, staging without committing, committing conflict markers, dropping the flag, using the wrong close script, double-close, multi-commit rebase where a second conflict must not destroy the first resolution |
| `worktree.test.sh` | 34 | Worktree mode for all three scripts, including the rebase gate targeting the worktree rather than the repo root, and paths containing spaces |
| `dirty-base.test.sh` | 139 | The dirty-base gate: tracked staged/unstaged changes in the integration checkout refused pre-mutation, dirty submodules and unrelated untracked content still allowed, a colliding untracked path refused with the ephemeral tip unmoved, `Base` required to be a local branch, `RepoRoot` required to still have `Base` checked out, nested utility/parent-Projex origins closing into their recorded parent, safe (non-`--hard`) squash rollback |
| `close-precheck.test.sh` | 38 | Report-only close context: explicit/inferred plans, encoded schema/snapshots, worktree and checkout modes, inventory classification/location, gates, warnings, malformed context, and non-mutation |
| `close-precheck.test.ps1` | 14 | Independent PowerShell contract: encoded context, worktree identity, child inventory/gates, no-argument inference, and malformed-header failure |
| `resolve-conflicts.test.ps1` | 33 | PowerShell parity for the core contract (checkout mode) |
| `worktree.test.ps1` | 39 | PowerShell parity for worktree mode |
| `dirty-base.test.ps1` | 139 | PowerShell parity for the dirty-base gate — same matrix, mechanically parallel names |

The `.sh` and `.ps1` variants of each script carry duplicated logic, so both are tested independently
— parity is not assumed. That is not theoretical: the PowerShell suite is what caught that
`projex-squash-close` cannot be resumed by re-running, because a squash commit does not record the
ephemeral branch as a parent and the squash is therefore recomputed from the same base.

`close-precheck` fixtures assert a versioned, UTF-8 percent-encoded record protocol (`SCHEMA_VERSION=1`), snapshot identities, deterministic origin/child inventory, and `PASS_WITH_WARNINGS` as advisory evidence only. The utility is report-only: it is not close authorization and never replaces finalizer gates. Reports are complete-or-fail under the 8 MiB budget; a consumer reruns on `STALE`. Child-only documents remain factual `untracked` records with no inferred lifecycle disposition. PowerShell parser/runtime evidence is required for parity; `NOT RUN` is incomplete acceptance.

## Conventions

- `chk <name> <got> <want>` / `Chk` is the only assertion helper; suites print `FAIL: ...` lines and a
  final `PASS=<n> FAIL=<n>` summary that the runners parse.
- Assertions check observable git state — exit codes, `MERGE_HEAD`, rebase directories, unmerged
  index entries, branch existence, committed content — never script internals.
- Suites deliberately assert the *documented* behaviour, including behaviour that looks like a
  failure (squash re-run re-conflicting), so that a future "fix" that changes the contract is caught.
- One branch is knowingly unexercised: the rollback-failure path in `projex-squash-close`, where
  `git reset --merge HEAD` itself fails. It is **not constructible as a deterministic regression
  case; reachable only through the documented gate→merge window** — the tracked-clean gate and the
  in-progress gate leave the tree tracked-clean when `merge --squash` runs, but nothing re-checks in
  between, so a concurrent writer that leaves a tracked file at `index != HEAD != worktree` makes the
  merge refuse pre-mutation *and* the reset fail. A test cannot pre-seed that state: the gate rejects
  it up front. `safe_rollback` therefore splits its message on whether unmerged paths actually exist,
  and `dirty-base.test.*` covers the reachable neighbours instead and says so inline.
