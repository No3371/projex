#!/usr/bin/env bash
# new-projex.sh — Scaffold a new projex file with minimal common header
# Usage: new-projex.sh <repo-root> <type> <title> [<projex-dir>]
#   <type>: propose|plan|eval|review|redteam|audit|interview|log|memo|patch|
#           simulate|debug|define|navigate|map|scan|explore|guide|imagine|archive
#   <projex-dir>: defaults to ".projex" (relative to repo-root)
# Prints the created file's path on success.
set -euo pipefail

repo_root="${1:?repo-root required}"
type="${2:?type required}"
title="${3:?title required}"
projex_dir="${4:-.projex}"

# suffix is authoritative per each *-projex.md spec and does NOT always match the type
# key (e.g. propose->proposal, simulate->simulation, define->def, navigate->nav).
case "$type" in
    propose)   suffix="proposal" ;;
    plan)      suffix="plan" ;;
    eval)      suffix="eval" ;;
    review)    suffix="review" ;;
    redteam)   suffix="redteam" ;;
    audit)     suffix="audit" ;;
    interview) suffix="interview" ;;
    log)       suffix="log" ;;
    memo)      suffix="memo" ;;
    patch)     suffix="patch" ;;
    simulate)  suffix="simulation" ;;
    debug)     suffix="debug" ;;
    define)    suffix="def" ;;
    navigate)  suffix="nav" ;;
    map)       suffix="map" ;;
    scan)      suffix="scan" ;;
    explore)   suffix="explore" ;;
    guide)     suffix="guide" ;;
    imagine)   suffix="imagine" ;;
    archive)   suffix="archive" ;;
    *) echo "Unknown type '$type'. Valid: propose plan eval review redteam audit interview log memo patch simulate debug define navigate map scan explore guide imagine archive" >&2; exit 1 ;;
esac

born_closed="log archive patch simulate scan guide"
is_born_closed=false
for t in $born_closed; do
    [ "$type" = "$t" ] && is_born_closed=true && break
done

if $is_born_closed; then
    dir="$repo_root/$projex_dir/closed"
    status="Closed"
    rel_dir="$projex_dir/closed"
else
    dir="$repo_root/$projex_dir"
    status="Draft"
    rel_dir="$projex_dir"
fi
mkdir -p "$dir"

slug=$(echo "$title" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//')
if [ -z "$slug" ]; then
    echo "Title produces an empty slug" >&2
    exit 1
fi

stamp=$(date +%y%m%d%H%M)
file_name="${stamp}-${slug}-${suffix}.md"
path="$dir/$file_name"

if [ -e "$path" ]; then
    echo "File already exists: $path" >&2
    exit 1
fi

today=$(date +%Y-%m-%d)

cat > "$path" <<EOF
# ${title}

> **Status:** ${status}
> **Created:** ${today}
> **Author:** [name or agent]
> **Related Projex:** [none yet]

---
EOF

echo "$path"
echo "# next: scaffold contains header only — update the format, structure and content per ${type}-projex.md"
script_dir="$(cd "$(dirname "$0")" && pwd)"
echo "# commit: $script_dir/projex-commit.sh $repo_root \"projex($type): add $slug\" $rel_dir/$file_name"
