#!/usr/bin/env bash
# stage-by-pattern.sh — Stage only diff lines whose content matches a regex
# Usage: stage-by-pattern.sh <repo-root> <pattern> [-v] [-n] [-- file1 file2 ...]
#
# Filters unstaged changes through a pattern and stages only matching +/- lines.
# Useful for structured changes like renames or method signature updates where
# the diff is highly regular and describable with a precise regex.
#
# Options:
#   -v   Invert: stage lines NOT matching the pattern
#   -n   Dry run: print the filtered diff to stdout, don't stage
#
# Pattern uses awk extended-regex syntax and is matched against the content of
# changed lines (without the +/- prefix). Context lines are never filtered.
#
# For replacement pairs (-old / +new), the pattern should match BOTH sides.
# E.g. renaming getFoo→getBar: use 'getFoo|getBar', not just 'getBar',
# otherwise only the addition is staged without the corresponding deletion.

set -euo pipefail

if [ $# -lt 2 ]; then
  echo "Usage: stage-by-pattern.sh <repo-root> <pattern> [-v] [-n] [-- file1 file2 ...]" >&2
  exit 1
fi

REPO_ROOT="$1"
PATTERN="$2"
shift 2

# Validate repo root
TOPLEVEL=$(git -C "$REPO_ROOT" rev-parse --show-toplevel 2>/dev/null) || {
  echo "Error: '$REPO_ROOT' is not a git repository" >&2
  exit 1
}
REPO_CANONICAL=$(cd "$REPO_ROOT" && pwd -P)
TOP_CANONICAL=$(cd "$TOPLEVEL" && pwd -P)
if [ "$REPO_CANONICAL" != "$TOP_CANONICAL" ]; then
  echo "Error: '$REPO_ROOT' is not a repo root — toplevel is '$TOPLEVEL'" >&2
  echo "  The <repo-root> argument must be the repository's top-level directory." >&2
  exit 1
fi

# Snapshot staging area state — verification only runs when staging was clean
CLEAN_STAGE=0
if git -C "$REPO_ROOT" diff --cached --quiet 2>/dev/null; then
  CLEAN_STAGE=1
fi

# Parse options and files
INVERT=0
DRY_RUN=0
FILES=()

while [ $# -gt 0 ]; do
  case "$1" in
    -v) INVERT=1; shift ;;
    -n) DRY_RUN=1; shift ;;
    --) shift; FILES=("$@"); break ;;
    *)  FILES+=("$1"); shift ;;
  esac
done

# Validate file paths belong to this repo
if [ ${#FILES[@]} -gt 0 ]; then
  for f in "${FILES[@]}"; do
    check_dir="$REPO_ROOT/$f"
    while [ ! -d "$check_dir" ]; do check_dir=$(dirname "$check_dir"); done
    FILE_TOP=$(cd "$check_dir" && git rev-parse --show-toplevel 2>/dev/null) || true
    if [ -z "$FILE_TOP" ]; then
      echo "Error: '$f' is not inside any git repository" >&2
      echo "  Expected repo root: $TOPLEVEL" >&2
      exit 1
    fi
    FILE_TOP_CANONICAL=$(cd "$FILE_TOP" && pwd -P)
    if [ "$FILE_TOP_CANONICAL" != "$TOP_CANONICAL" ]; then
      echo "Error: '$f' belongs to a different repo than '$REPO_ROOT'" >&2
      echo "  File's repo root: $FILE_TOP" >&2
      echo "  Expected repo root: $TOPLEVEL" >&2
      echo "  Verify the <repo-root> argument matches the repository containing these files." >&2
      exit 1
    fi
  done
fi

# Capture unstaged diff
if [ ${#FILES[@]} -gt 0 ]; then
  DIFF=$(git -C "$REPO_ROOT" diff -- "${FILES[@]}") || { echo "Error: git diff failed" >&2; exit 1; }
else
  DIFF=$(git -C "$REPO_ROOT" diff) || { echo "Error: git diff failed" >&2; exit 1; }
fi

if [ -z "$DIFF" ]; then
  echo "No unstaged changes." >&2
  exit 0
fi

# Filter the diff with awk.
#
# Algorithm per hunk:
#   +/- line matching pattern  → keep as +/-  (will be staged)
#   -   line NOT matching      → convert to context " " (stays unstaged)
#   +   line NOT matching      → drop entirely          (stays unstaged)
#   context / meta lines       → keep as-is
#   "\ No newline" after a dropped line → also dropped
#
# With -v the match sense is inverted.
# Empty hunks (no surviving +/-) are discarded.
# File headers emitted only when at least one hunk survives.
# Hunk new-start line numbers are adjusted for filtered content.

FILTERED=$(printf '%s\n' "$DIFF" | PATTERN="$PATTERN" awk -v invert="$INVERT" '
BEGIN { pattern = ENVIRON["PATTERN"] }

/^diff --git / {
  flush_hunk()
  emit_file()
  file_buf      = $0 "\n"
  file_has_out  = 0
  adj           = 0
  next
}

/^@@ / {
  flush_hunk()
  in_hunk      = 1
  hunk_n       = 0
  orig_add     = 0
  orig_del     = 0
  last_dropped = 0

  # parse @@ -old[,cnt] +new[,cnt] @@[suffix]
  old_spec = $2; sub(/^-/, "", old_spec)
  split(old_spec, _o, ",")
  cur_old_start = _o[1] + 0

  new_spec = $3; sub(/^\+/, "", new_spec)
  split(new_spec, _n, ",")
  cur_new_start = _n[1] + 0

  cur_suffix = ""
  s = $0
  sub(/^@@ -[^ ]+ \+[^ ]+ @@/, "", s)
  cur_suffix = s
  next
}

# Hunk body — MUST come before file header detail pattern below,
# otherwise lines like "+++counter" or "---flag" would match as headers.
in_hunk {
  ch = substr($0, 1, 1)

  # Context line (or empty line from whitespace-stripped context)
  if (ch == " " || $0 == "") {
    hunk_n++; hl[hunk_n] = $0; ht[hunk_n] = "c"
    last_dropped = 0
  }
  else if (ch == "-") {
    orig_del++
    content = substr($0, 2)
    if (want(content)) {
      hunk_n++; hl[hunk_n] = $0; ht[hunk_n] = "d"
    } else {
      hunk_n++; hl[hunk_n] = " " content; ht[hunk_n] = "c"
    }
    last_dropped = 0
  }
  else if (ch == "+") {
    orig_add++
    content = substr($0, 2)
    if (want(content)) {
      hunk_n++; hl[hunk_n] = $0; ht[hunk_n] = "a"
      last_dropped = 0
    } else {
      last_dropped = 1
    }
  }
  else if (ch == "\\") {
    # "\ No newline at end of file" — belongs to the preceding line.
    # If that line was dropped, this must be dropped too.
    if (!last_dropped) {
      hunk_n++; hl[hunk_n] = $0; ht[hunk_n] = "m"
    }
    # Do not reset last_dropped: meta line is not a real content line
  }
  next
}

# File header detail lines — only reached when NOT in a hunk.
/^(index |old mode|new mode|new file|deleted file|similarity|rename |copy |Binary|---|\+\+\+)/ {
  file_buf = file_buf $0 "\n"
  next
}

{ print }

END { flush_hunk(); emit_file() }

function want(text) {
  m = (text ~ pattern) ? 1 : 0
  return invert ? !m : m
}

function flush_hunk() {
  if (!in_hunk) return
  in_hunk = 0

  oc = 0; nc = 0; has = 0
  for (i = 1; i <= hunk_n; i++) {
    if (ht[i] == "c") { oc++; nc++ }
    else if (ht[i] == "d") { oc++; has = 1 }
    else if (ht[i] == "a") { nc++; has = 1 }
  }

  if (!has) {
    adj += orig_add - orig_del
    clear_hunk()
    return
  }

  if (!file_has_out && file_buf != "") {
    printf "%s", file_buf
    file_has_out = 1
  }

  printf "@@ -%d,%d +%d,%d @@%s\n", cur_old_start, oc, cur_new_start - adj, nc, cur_suffix

  fn = 0
  for (i = 1; i <= hunk_n; i++) {
    if (ht[i] == "a") fn++
    if (ht[i] == "d") fn--
  }
  adj += (orig_add - orig_del) - fn

  for (i = 1; i <= hunk_n; i++) print hl[i]
  clear_hunk()
}

function clear_hunk() {
  for (i in hl) delete hl[i]
  for (i in ht) delete ht[i]
  hunk_n = 0
}

function emit_file() {
  file_buf = ""
  adj = 0
}
')

if [ -z "$FILTERED" ]; then
  echo "No changes match the pattern." >&2
  exit 0
fi

if [ "$DRY_RUN" -eq 1 ]; then
  printf '%s\n' "$FILTERED"
  exit 0
fi

# Apply filtered diff to index
if ! APPLY_OUT=$(printf '%s\n' "$FILTERED" | git -C "$REPO_ROOT" apply --cached 2>&1); then
  echo "Error: git apply --cached failed" >&2
  echo "$APPLY_OUT" >&2
  exit 1
fi

# Verify: when staging was clean before, every staged +/- line must match the pattern.
# If any line doesn't, the filtering logic produced an incorrect diff — rollback.
if [ "$CLEAN_STAGE" -eq 1 ]; then
  if ! BAD=$(git -C "$REPO_ROOT" diff --cached | PATTERN="$PATTERN" awk -v invert="$INVERT" '
    BEGIN { pattern = ENVIRON["PATTERN"] }
    /^@@ /         { ih = 1; next }
    /^diff --git /  { ih = 0; next }
    ih && /^[-+]/ {
      content = substr($0, 2)
      m = (content ~ pattern) ? 1 : 0
      keep = invert ? !m : m
      if (!keep) { bad++; print }
    }
    END { if (bad > 0) exit 1 }
  '); then
    echo "Error: verification failed — staged diff contains lines not matching the pattern:" >&2
    echo "$BAD" >&2
    git -C "$REPO_ROOT" reset HEAD > /dev/null 2>&1
    echo "Rolled back — staging area restored to clean state." >&2
    exit 1
  fi
fi

COUNT=$(printf '%s\n' "$FILTERED" | grep -c '^diff --git ' || true)
echo "Staged filtered changes in $COUNT file(s):"
printf '%s\n' "$FILTERED" | grep '^diff --git ' | sed 's|^diff --git a/\(.*\) b/.*|  \1|'
