#!/usr/bin/env bash
# projex-rebase-close.sh — Rebase ephemeral onto base for linear history, fast-forward base, delete ephemeral
# Usage: projex-rebase-close.sh <repo-root> <base-branch> <ephemeral-branch> [--worktree] [--resolve-conflicts <paths>]
#
# Replays the ephemeral branch's commits onto the tip of base (rewriting their SHAs),
# then fast-forwards base to include them. No merge commit is created.
#
# --worktree: the ephemeral branch is checked out in a worktree at <repo>/.projexwt/<branch-suffix>.
#             The rebase runs inside that worktree; the main working directory must be on base.
#             The worktree is removed after the fast-forward succeeds.
#
# --resolve-conflicts: comma-separated repo-relative paths (files or directory prefixes) where conflicts
#             are ANTICIPATED; repeatable. Default behaviour on conflict is unchanged: abort and roll back.
#             With this flag, if EVERY conflicted path is covered by the list, the rebase is left in
#             progress (exit 2) so the caller can resolve it. A conflict in any path outside the list
#             still aborts. Once the caller concludes the rebase, re-running this exact command
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

if [ ${#POSITIONAL[@]} -ne 3 ]; then
  echo "Usage: projex-rebase-close.sh <repo-root> <base-branch> <ephemeral-branch> [--worktree] [--resolve-conflicts <paths>]" >&2
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

# Commits still queued behind the current stop, or -1 if it cannot be determined.
# A rebase halts at the FIRST conflicting commit, so a covered stop is not a promise that the
# remaining commits are conflict-free — the same gate is applied again at every later stop.
remaining_rebase_commits() {
  local git_dir
  git_dir=$(git -C "$1" rev-parse --absolute-git-dir 2>/dev/null || true)
  if [ -z "$git_dir" ]; then echo -1; return 0; fi
  if [ -f "$git_dir/rebase-merge/git-rebase-todo" ]; then
    grep -cvE '^[[:space:]]*(#|$)' "$git_dir/rebase-merge/git-rebase-todo" || echo 0
  elif [ -f "$git_dir/rebase-apply/next" ] && [ -f "$git_dir/rebase-apply/last" ]; then
    echo $(( $(tr -d ' \r\n' < "$git_dir/rebase-apply/last") - $(tr -d ' \r\n' < "$git_dir/rebase-apply/next") ))
  else
    echo -1
  fi
  return 0
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

# Refuse to start on top of an unfinished operation — never silently discard someone's half-done
# resolution (a mid-flight multi-commit rebase would otherwise be aborted, losing earlier resolutions)
if [ "$WORKTREE_MODE" = true ]; then OP_DIR="${REPO_ROOT%/}/.projexwt/${EPHEMERAL##*/}"; else OP_DIR="$REPO_ROOT"; fi
IN_PROGRESS=$(in_progress_op "$OP_DIR")
if [ -n "$IN_PROGRESS" ]; then
  if [ "$IN_PROGRESS" = rebase ]; then FINISH="git -C $OP_DIR rebase --continue"; else FINISH="git -C $OP_DIR commit"; fi
  echo "Error: a $IN_PROGRESS is already in progress in '$OP_DIR' — nothing was changed. Finish it (resolve, git -C $OP_DIR add <paths>, $FINISH) then re-run, or cancel it first (git -C $OP_DIR rebase --abort / merge --abort)." >&2
  exit 1
fi

if [ "$WORKTREE_MODE" = true ]; then
  # Worktree mode: rebase inside the worktree (ephemeral is checked out there), then ff base.
  WT_PATH="${REPO_ROOT%/}/.projexwt/${EPHEMERAL##*/}"
  if [ ! -d "$WT_PATH" ]; then
    echo "Error: worktree '$WT_PATH' does not exist — is worktree mode correct?" >&2
    exit 1
  fi
  # Pre-flight cleanliness gate — refuse to rewrite history / finalize over a non-clean worktree
  # (unified: git status --porcelain covers untracked AND uncommitted tracked, replacing the old tracked-only check)
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
  if ! git -C "$WT_PATH" rebase "$BASE" 2>&1; then
    CONFLICTED=$(unmerged_paths "$WT_PATH")
    if [ ${#RESOLVE_PATHS[@]} -gt 0 ] && [ -n "$CONFLICTED" ]; then
      UNCOVERED=$(uncovered_conflicts "$WT_PATH")
      if [ -z "$UNCOVERED" ]; then
        echo "Anticipated conflicts — rebase left IN PROGRESS in worktree '$WT_PATH' (not aborted):" >&2
        echo "$CONFLICTED" | sed 's/^/  /' >&2
        REMAINING=$(remaining_rebase_commits "$WT_PATH")
        if [ "$REMAINING" -gt 0 ] 2>/dev/null; then
          echo "$REMAINING commit(s) remain to be replayed after this one — a rebase stops at the first conflicting commit, so later stops may surface conflicts outside --resolve-conflicts. The same gate applies at each stop." >&2
        fi
        echo "Resolve them, then:" >&2
        echo "  git -C $WT_PATH add <paths>" >&2
        echo "  git -C $WT_PATH rebase --continue   (repeat if later commits conflict)" >&2
        echo "Then re-run this exact command to finish the close." >&2
        exit 2
      fi
      git -C "$WT_PATH" rebase --abort 2>/dev/null || true
      echo "Error: rebase conflict outside --resolve-conflicts — aborted, worktree '$WT_PATH' left on '$EPHEMERAL'. Unanticipated conflicts:" >&2
      echo "$UNCOVERED" | sed 's/^/  /' >&2
      exit 1
    fi
    git -C "$WT_PATH" rebase --abort 2>/dev/null || true
    echo "Error: rebase conflict — aborted, worktree '$WT_PATH' left on '$EPHEMERAL'. Resolve manually or use Option A/B." >&2
    exit 1
  fi
else
  # Checkout mode: require clean tree, remember starting branch, rebase ephemeral onto base.
  if ! git -C "$REPO_ROOT" diff --quiet 2>/dev/null || ! git -C "$REPO_ROOT" diff --cached --quiet 2>/dev/null; then
    echo "Error: working tree has uncommitted changes — commit or stash before closing" >&2
    exit 1
  fi

  ORIG_BRANCH="$(git -C "$REPO_ROOT" rev-parse --abbrev-ref HEAD)"

  if ! git -C "$REPO_ROOT" checkout "$EPHEMERAL" 2>&1; then
    echo "Error: could not checkout '$EPHEMERAL' — no state changed" >&2
    exit 1
  fi

  # Rebase ephemeral onto base (rewrites ephemeral's commits)
  if ! git -C "$REPO_ROOT" rebase "$BASE" 2>&1; then
    CONFLICTED=$(unmerged_paths "$REPO_ROOT")
    if [ ${#RESOLVE_PATHS[@]} -gt 0 ] && [ -n "$CONFLICTED" ]; then
      UNCOVERED=$(uncovered_conflicts "$REPO_ROOT")
      if [ -z "$UNCOVERED" ]; then
        echo "Anticipated conflicts — rebase left IN PROGRESS on '$EPHEMERAL' in '$REPO_ROOT' (not aborted):" >&2
        echo "$CONFLICTED" | sed 's/^/  /' >&2
        REMAINING=$(remaining_rebase_commits "$REPO_ROOT")
        if [ "$REMAINING" -gt 0 ] 2>/dev/null; then
          echo "$REMAINING commit(s) remain to be replayed after this one — a rebase stops at the first conflicting commit, so later stops may surface conflicts outside --resolve-conflicts. The same gate applies at each stop." >&2
        fi
        echo "Resolve them, then:" >&2
        echo "  git -C $REPO_ROOT add <paths>" >&2
        echo "  git -C $REPO_ROOT rebase --continue   (repeat if later commits conflict)" >&2
        echo "Then re-run this exact command to finish the close." >&2
        exit 2
      fi
      git -C "$REPO_ROOT" rebase --abort 2>/dev/null || true
      git -C "$REPO_ROOT" checkout "$ORIG_BRANCH" 2>/dev/null || true
      echo "Error: rebase conflict outside --resolve-conflicts — aborted, restored to '$ORIG_BRANCH'. Unanticipated conflicts:" >&2
      echo "$UNCOVERED" | sed 's/^/  /' >&2
      exit 1
    fi
    git -C "$REPO_ROOT" rebase --abort 2>/dev/null || true
    git -C "$REPO_ROOT" checkout "$ORIG_BRANCH" 2>/dev/null || true
    echo "Error: rebase conflict — aborted, restored to '$ORIG_BRANCH'. Resolve manually or use Option A/B." >&2
    exit 1
  fi
fi

# Fast-forward base to the rebased ephemeral tip (no merge commit).
# In checkout mode we must switch to base first; in worktree mode base is already checked out in the main dir.
if [ "$WORKTREE_MODE" = false ]; then
  if ! git -C "$REPO_ROOT" checkout "$BASE" 2>&1; then
    echo "Error: rebased '$EPHEMERAL' but could not checkout '$BASE' to fast-forward — finish manually: git checkout $BASE && git merge --ff-only $EPHEMERAL" >&2
    exit 1
  fi
fi

if ! git -C "$REPO_ROOT" merge --ff-only "$EPHEMERAL" 2>&1; then
  echo "Error: fast-forward of '$BASE' failed unexpectedly after rebase — '$EPHEMERAL' is rebased; finish manually: git merge --ff-only $EPHEMERAL" >&2
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
  echo "Warning: could not delete '$EPHEMERAL' — changes are on '$BASE', delete manually: git branch -d $EPHEMERAL"
else
  echo "Rebased '$EPHEMERAL' -> '$BASE' (linear, fast-forward). Branch deleted."
fi
