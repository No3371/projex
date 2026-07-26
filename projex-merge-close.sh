#!/usr/bin/env bash
# projex-merge-close.sh — Merge with full history into base, then delete ephemeral
# Usage: projex-merge-close.sh <repo-root> <base-branch> <ephemeral-branch> "merge message" [--worktree] [--resolve-conflicts <paths>]
#
# --worktree: merge from base, then best-effort remove the worktree at <repo>/.projexwt/<branch-suffix>.
#             The main working directory must already be on the base branch.
#
# --resolve-conflicts: comma-separated repo-relative paths (files or directory prefixes) where conflicts
#             are ANTICIPATED; repeatable. Default behaviour on conflict is unchanged: abort and roll back.
#             With this flag, if EVERY conflicted path is covered by the list, the merge is left in
#             progress (exit 2) so the caller can resolve it. A conflict in any path outside the list
#             still aborts. Once the caller commits the resolution, re-running this exact command
#             finishes the close.
#
# Exit codes: 0 = closed, 1 = failed and rolled back, 2 = left in progress for the caller to resolve.

set -euo pipefail

# Parse flags
WORKTREE_MODE=false
RESOLVE_PATHS=()
POSITIONAL=()
while [ $# -gt 0 ]; do
  case "$1" in
    --worktree)
      WORKTREE_MODE=true
      shift
      ;;
    --resolve-conflicts)
      if [ $# -lt 2 ]; then
        echo "Error: --resolve-conflicts requires a comma-separated path list" >&2
        exit 1
      fi
      IFS=',' read -r -a _entries <<< "$2"
      RESOLVE_PATHS+=("${_entries[@]}")
      shift 2
      ;;
    *)
      POSITIONAL+=("$1")
      shift
      ;;
  esac
done

if [ ${#POSITIONAL[@]} -ne 4 ]; then
  echo "Usage: projex-merge-close.sh <repo-root> <base-branch> <ephemeral-branch> \"merge message\" [--worktree] [--resolve-conflicts <paths>]" >&2
  exit 1
fi

# Paths git reports as unmerged (conflicted) in $1
unmerged_paths() {
  git -C "$1" diff --name-only --diff-filter=U 2>/dev/null || true
}

# Conflicted paths in $1 NOT covered by --resolve-conflicts (exact file match or directory prefix)
uncovered_conflicts() {
  local p entry covered
  while IFS= read -r p; do
    [ -z "$p" ] && continue
    covered=false
    for entry in ${RESOLVE_PATHS[@]+"${RESOLVE_PATHS[@]}"}; do
      entry="${entry%/}"
      [ -z "$entry" ] && continue
      if [ "$p" = "$entry" ] || [ "${p#"$entry"/}" != "$p" ]; then
        covered=true
        break
      fi
    done
    if [ "$covered" = false ]; then echo "$p"; fi
  done < <(unmerged_paths "$1")
  return 0
}

# Full symbolic ref name of $2 as resolved in $1, or empty when it is not a ref (raw SHA)
full_ref() {
  git -C "$1" rev-parse --symbolic-full-name "$2" 2>/dev/null || true
}

# Tracked staged/unstaged content in $1. Untracked and ignored files are deliberately NOT counted:
# busy repos keep them around, and .projexwt/ itself surfaces as untracked whenever the
# .git/info/exclude registration is missing, so counting them would self-block worktree mode.
# Submodule dirt is excluded too — a superproject whose recorded submodule commit is unchanged is
# not dirty for integration purposes.
tracked_dirt() {
  git -C "$1" status --porcelain --untracked-files=no --ignore-submodules=dirty 2>/dev/null || true
}

# Unfinished git operation in $1 — prints 'rebase', 'merge', 'conflict', or nothing
in_progress_op() {
  local git_dir
  git_dir=$(git -C "$1" rev-parse --absolute-git-dir 2>/dev/null || true)
  [ -z "$git_dir" ] && return 0
  if [ -d "$git_dir/rebase-merge" ] || [ -d "$git_dir/rebase-apply" ]; then
    echo rebase
  elif [ -f "$git_dir/MERGE_HEAD" ]; then
    echo merge
  elif [ -n "$(unmerged_paths "$1")" ]; then
    echo conflict
  fi
  return 0
}

REPO_ROOT="${POSITIONAL[0]}"
BASE="${POSITIONAL[1]}"
EPHEMERAL="${POSITIONAL[2]}"
MERGE_MSG="${POSITIONAL[3]}"

# Validate repo
if ! git -C "$REPO_ROOT" rev-parse --git-dir > /dev/null 2>&1; then
  echo "Error: '$REPO_ROOT' is not a git repository" >&2
  exit 1
fi

# Validate branches exist
if ! git -C "$REPO_ROOT" rev-parse --verify "$BASE" > /dev/null 2>&1; then
  echo "Error: base branch '$BASE' does not exist" >&2
  exit 1
fi

if ! git -C "$REPO_ROOT" rev-parse --verify "$EPHEMERAL" > /dev/null 2>&1; then
  echo "Error: ephemeral branch '$EPHEMERAL' does not exist" >&2
  exit 1
fi

if [ "$BASE" = "$EPHEMERAL" ]; then
  echo "Error: base and ephemeral branch cannot be the same ('$BASE')" >&2
  exit 1
fi

# Refuse to start on top of an unfinished operation — never silently discard someone's half-done resolution
IN_PROGRESS=$(in_progress_op "$REPO_ROOT")
if [ -n "$IN_PROGRESS" ]; then
  if [ "$IN_PROGRESS" = rebase ]; then FINISH="git -C $REPO_ROOT rebase --continue"; else FINISH="git -C $REPO_ROOT commit --no-edit"; fi
  echo "Error: a $IN_PROGRESS is already in progress in '$REPO_ROOT' — nothing was changed. Finish it (resolve, git -C $REPO_ROOT add <paths>, $FINISH) then re-run, or cancel it first (git -C $REPO_ROOT merge --abort / rebase --abort)." >&2
  exit 1
fi

# --- Dirty-base safety gate: everything below runs BEFORE any checkout/merge -------------------
# Base must be a local branch. `rev-parse --verify` above also accepts tags, raw SHAs and
# remote-tracking refs; none of those can be advanced by a close, so reject them by name.
BASE_REF=$(full_ref "$REPO_ROOT" "$BASE")
case "$BASE_REF" in
  refs/heads/*) : ;;
  refs/tags/*)    echo "Error: base '$BASE' resolves to a tag ($BASE_REF), not a local branch — nothing was changed." >&2; exit 1 ;;
  refs/remotes/*) echo "Error: base '$BASE' resolves to a remote-tracking ref ($BASE_REF), not a local branch — nothing was changed." >&2; exit 1 ;;
  "")             echo "Error: base '$BASE' resolves to a raw commit, not a local branch — nothing was changed." >&2; exit 1 ;;
  *)              echo "Error: base '$BASE' resolves to '$BASE_REF', not a local branch (refs/heads/*) — nothing was changed." >&2; exit 1 ;;
esac

if [ "$WORKTREE_MODE" = true ]; then
  # REPO_ROOT is the recorded originating/base worktree — which may be any registered worktree,
  # not necessarily the primary one. It must still have BASE checked out; never guess another.
  ORIGIN_REF=$(git -C "$REPO_ROOT" symbolic-ref --quiet HEAD 2>/dev/null || true)
  if [ -z "$ORIGIN_REF" ]; then
    echo "Error: '$REPO_ROOT' has a detached HEAD, not branch '$BASE' — nothing was changed. Check '$BASE' out there, or pass the worktree that holds it." >&2
    exit 1
  fi
  if [ "$ORIGIN_REF" != "$BASE_REF" ]; then
    echo "Error: '$REPO_ROOT' has '${ORIGIN_REF#refs/heads/}' checked out, not '$BASE' — nothing was changed. Finalizers never substitute another worktree or branch." >&2
    exit 1
  fi
fi

# Pre-flight (not a guarantee): the checkout about to be mutated must have no tracked changes.
# Nothing re-checks between here and the merge, so a concurrent writer can still dirty it —
# git's own overwrite refusal remains the real backstop.
DIRT=$(tracked_dirt "$REPO_ROOT")
if [ -n "$DIRT" ]; then
  echo "Error: '$REPO_ROOT' has tracked changes — commit or stash them before closing; nothing was changed. Untracked and ignored files are fine, and a dirty submodule alone does not count:" >&2
  echo "$DIRT" | head -n 10 >&2
  exit 1
fi

if [ "$WORKTREE_MODE" = true ]; then
  # Worktree mode: merge first; cleanup happens after merge so locks cannot block close.
  WT_PATH="${REPO_ROOT%/}/.projexwt/${EPHEMERAL##*/}"
else
  if ! git -C "$REPO_ROOT" checkout "$BASE" 2>&1; then
    echo "Error: could not checkout '$BASE' — still on ephemeral, no state changed" >&2
    exit 1
  fi
fi

# Pre-flight cleanliness gate (worktree mode) — refuse to finalize over a non-clean worktree
if [ "$WORKTREE_MODE" = true ]; then
  DIRTY=$(git -C "$WT_PATH" status --porcelain 2>/dev/null || true)
  if [ -n "$DIRTY" ]; then
    echo "Error: worktree '$WT_PATH' is not clean — commit tracked edits, and commit or remove untracked tooling, then re-run:" >&2
    echo "$DIRTY" | head -n 10 >&2
    exit 1
  fi
  IGNORED=$(git -C "$WT_PATH" status --porcelain --ignored=matching 2>/dev/null | grep '^!!' || true)
  if [ -n "$IGNORED" ]; then
    echo "Warning: worktree contains ignored content (deps/build output) — removal may leave a directory to clean manually:" >&2
    echo "$IGNORED" | head -n 5 >&2
  fi
fi

# Merge with full history
if ! git -C "$REPO_ROOT" merge "$EPHEMERAL" --no-ff -m "$MERGE_MSG" 2>&1; then
  CONFLICTED=$(unmerged_paths "$REPO_ROOT")
  if [ ${#RESOLVE_PATHS[@]} -gt 0 ] && [ -n "$CONFLICTED" ]; then
    UNCOVERED=$(uncovered_conflicts "$REPO_ROOT")
    if [ -z "$UNCOVERED" ]; then
      echo "Anticipated conflicts — merge left IN PROGRESS on '$BASE' in '$REPO_ROOT' (not aborted):" >&2
      echo "$CONFLICTED" | sed 's/^/  /' >&2
      echo "Resolve them, then:" >&2
      echo "  git -C $REPO_ROOT add <paths>" >&2
      echo "  git -C $REPO_ROOT commit --no-edit" >&2
      echo "Then re-run this exact command to finish the close (the merge will be a no-op; cleanup and branch deletion proceed)." >&2
      exit 2
    fi
    git -C "$REPO_ROOT" merge --abort 2>/dev/null || true
    echo "Error: merge conflict outside --resolve-conflicts — aborted on '$BASE'. Unanticipated conflicts:" >&2
    echo "$UNCOVERED" | sed 's/^/  /' >&2
    exit 1
  fi
  git -C "$REPO_ROOT" merge --abort 2>/dev/null || true
  if [ "$WORKTREE_MODE" = true ]; then
    echo "Error: merge failed — aborted on '$BASE'. Branch '$EPHEMERAL' still exists; re-create worktree with: git worktree add $WT_PATH $EPHEMERAL" >&2
  elif git -C "$REPO_ROOT" checkout "$EPHEMERAL" 2>/dev/null; then
    echo "Error: merge failed — aborted, rolled back to '$EPHEMERAL'" >&2
  else
    echo "Error: merge failed — aborted, still on '$BASE'" >&2
  fi
  exit 1
fi

if [ "$WORKTREE_MODE" = true ]; then
  if ! git -C "$REPO_ROOT" worktree remove "$WT_PATH" 2>&1; then
    WT_SUFFIX="${EPHEMERAL##*/}"
    if git -C "$REPO_ROOT" worktree list --porcelain | grep -q "/\.projexwt/${WT_SUFFIX}\$"; then
      echo "Warning: could not remove worktree '$WT_PATH' — close succeeded. Blocking content:" >&2
      { git -C "$WT_PATH" status --porcelain --ignored=matching 2>/dev/null || true; } | head -n 10 >&2
      echo "Remove the files above (or release any lock/open handle on the worktree — an empty list above means the block is a lock, not dirty content), then: git -C $REPO_ROOT worktree remove $WT_PATH" >&2
    else
      echo "Warning: worktree unregistered but directory remains at '$WT_PATH' — close succeeded; inspect and delete the plain directory manually, then run: git -C $REPO_ROOT worktree prune" >&2
    fi
  fi
fi

git -C "$REPO_ROOT" worktree prune 2>/dev/null || true

# Delete ephemeral branch (non-fatal)
if ! git -C "$REPO_ROOT" branch -d "$EPHEMERAL" 2>&1; then
  echo "Warning: could not delete '$EPHEMERAL' — changes are merged, delete manually: git branch -d $EPHEMERAL"
else
  echo "Merged '$EPHEMERAL' -> '$BASE' with history. Branch deleted."
fi
