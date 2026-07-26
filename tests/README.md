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
|-------|-----------:|--------|
| `resolve-conflicts.test.sh` | 30 | `--resolve-conflicts` core contract: covered conflicts halt (exit 2), uncovered abort (exit 1), no-flag behaviour unchanged, directory-prefix vs exact-file matching, `.projexwt` not matched by a `.projex` entry |
| `resume.test.sh` | 52 | What a careless caller does between exit 2 and the re-run: re-running having done nothing, resolving without `git add`, staging without committing, committing conflict markers, dropping the flag, using the wrong close script, double-close, multi-commit rebase where a second conflict must not destroy the first resolution |
| `worktree.test.sh` | 34 | Worktree mode for all three scripts, including the rebase gate targeting the worktree rather than the repo root, and paths containing spaces |
| `resolve-conflicts.test.ps1` | 33 | PowerShell parity for the core contract (checkout mode) |
| `worktree.test.ps1` | 39 | PowerShell parity for worktree mode |

The `.sh` and `.ps1` variants of each script carry duplicated logic, so both are tested independently
— parity is not assumed. That is not theoretical: the PowerShell suite is what caught that
`projex-squash-close` cannot be resumed by re-running, because a squash commit does not record the
ephemeral branch as a parent and the squash is therefore recomputed from the same base.

## Conventions

- `chk <name> <got> <want>` / `Chk` is the only assertion helper; suites print `FAIL: ...` lines and a
  final `PASS=<n> FAIL=<n>` summary that the runners parse.
- Assertions check observable git state — exit codes, `MERGE_HEAD`, rebase directories, unmerged
  index entries, branch existence, committed content — never script internals.
- Suites deliberately assert the *documented* behaviour, including behaviour that looks like a
  failure (squash re-run re-conflicting), so that a future "fix" that changes the contract is caught.
