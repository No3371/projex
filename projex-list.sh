#!/usr/bin/env bash
# Read-only listing of projex documents, newest first: one block per document (path, then
# state/type/created/status lines), blocks separated by an empty line.
# Missing fields print "?". Active only unless folder toggles are given.
set -euo pipefail
usage() {
    echo "projex-list: E_USAGE: invocation: expected <repo-root> [--closed] [--archived] [--abandoned] [--all]" >&2
    exit 2
}
[ "$#" -ge 1 ] || usage
case $1 in --*) usage ;; esac
repo=$1; shift
states=" active "
all=0
for flag in "$@"; do
    case $flag in
        --closed | --archived | --abandoned) states="$states${flag#--} " ;;
        --all) all=1 ;;
        *) usage ;;
    esac
done
if [ ! -d "$repo" ]; then
    echo "projex-list: E_REPO: $repo: repository root not found" >&2
    exit 2
fi
cd "$repo"

# nested repositories (any .git below the root) are never walked
nested=$(find . -mindepth 2 \( -name .projexwt -prune \) -o \( -name .git -prune -print \) | sed 's|^\./||; s|/\.git$|/|')

tab=$(printf '\t')
find . \( -name .git -o -name .projexwt \) -prune -o -type f -name '*.md' -path '*/.projex/*' -print \
| sed 's|^\./||' \
| LC_ALL=C awk -v nested="$nested" -v states="$states" -v all="$all" '
BEGIN {
    n = split(nested, roots, "\n")
    stamp_re = "^[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-[a-z0-9][a-z0-9-]*-[a-z0-9]+\\.md$"
}
function trim(s) { sub(/^[ \t\r\n\f\v]+/, "", s); sub(/[ \t\r\n\f\v]+$/, "", s); return s }
function status_of(path,   line, idx, started, status) {
    idx = 0; started = 0; status = "?"
    while ((getline line < path) > 0) {
        sub(/\r$/, "", line)
        if (idx++ == 0) {
            sub(/^\357\273\277/, "", line)
            if (line ~ /^#/) { started = 1; continue }
        }
        if (trim(line) == "---") break
        if (substr(line, 1, 2) == "> ") {
            started = 1
            if (index(line, "> **Status:**") == 1) {
                status = trim(substr(line, 14))
                if (status == "") status = "?"
                break
            }
            continue
        }
        if (trim(line) == "") continue
        if (started) break
    }
    close(path)
    gsub(/\t/, " ", status)
    return status
}
{
    rel = $0
    for (i = 1; i <= n; i++) if (roots[i] != "" && index(rel, roots[i]) == 1) next
    after = rel
    if (substr(after, 1, 8) == ".projex/") after = substr(after, 9)
    else after = substr(after, index(after, "/.projex/") + 9)
    state = index(after, "/") ? substr(after, 1, index(after, "/") - 1) : "active"
    if (!all && index(states, " " state " ") == 0) next
    name = rel; sub(/.*\//, "", name)
    if (name ~ stamp_re) {
        stamp = substr(name, 1, 10)
        kind = name; sub(/\.md$/, "", kind); sub(/.*-/, "", kind)
        created = "20" substr(stamp, 1, 2) "-" substr(stamp, 3, 2) "-" substr(stamp, 5, 2) " " substr(stamp, 7, 2) ":" substr(stamp, 9, 2)
    } else {
        stamp = ""; kind = "?"; created = "?"
    }
    print stamp "\t" rel "\t" state "\t" kind "\t" created "\t" status_of(rel)
}' \
| LC_ALL=C sort -t "$tab" -k1,1r -k2,2 \
| LC_ALL=C awk -F '\t' '
NR > 1 { print "" }
{ print $2; print "state: " $3; print "type: " $4; print "created: " $5; print "status: " $6 }'
