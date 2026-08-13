#!/usr/bin/env bash
# new-projex.sh — Scaffold a new projex file with minimal common header
# Usage: new-projex.sh --repo-root <repo-root> --type <type> --title <title> --parent <parent> [--projex-dir <projex-dir>]
#   <type>: propose|plan|eval|review|redteam|stress|audit|interview|coach|log|memo|
#           patch|preplan|debug|define|navigate|map|scan|explore|guide|imagine|conclude|archive
#   <parent>: User|Orchestrator|{yymmddhhmm}-{name}-{type}.md
#   <projex-dir>: defaults to ".projex" (relative to repo-root)
# Prints the created file's path on success.
set -euo pipefail

usage() {
    echo "Usage: new-projex.sh --repo-root <repo-root> --type <type> --title <title> --parent <parent> [--projex-dir <projex-dir>]" >&2
    exit 2
}

repo_root=""
type=""
title=""
parent=""
projex_dir=".projex"
repo_root_set=false
type_set=false
title_set=false
parent_set=false
projex_dir_set=false

while [ "$#" -gt 0 ]; do
    case "$1" in
        --repo-root)
            $repo_root_set && usage
            [ "$#" -ge 2 ] && [[ "$2" != -* ]] || usage
            repo_root=$2
            repo_root_set=true
            shift 2
            ;;
        --type)
            $type_set && usage
            [ "$#" -ge 2 ] && [[ "$2" != -* ]] || usage
            type=$2
            type_set=true
            shift 2
            ;;
        --title)
            $title_set && usage
            [ "$#" -ge 2 ] && [[ "$2" != -* ]] || usage
            title=$2
            title_set=true
            shift 2
            ;;
        --parent)
            $parent_set && usage
            [ "$#" -ge 2 ] && [[ "$2" != -* ]] || usage
            parent=$2
            parent_set=true
            shift 2
            ;;
        --projex-dir)
            $projex_dir_set && usage
            [ "$#" -ge 2 ] && [[ "$2" != -* ]] || usage
            projex_dir=$2
            projex_dir_set=true
            shift 2
            ;;
        *)
            usage
            ;;
    esac
done

$repo_root_set && $type_set && $title_set && $parent_set || usage

# Normalize separators agents may mix (/, \\) — collapse to /, strip edge slashes.
repo_root=$(printf '%s' "$repo_root" | tr '\\' '/' | sed -E 's|/+$||')
projex_dir=$(printf '%s' "$projex_dir" | tr '\\' '/' | sed -E 's|^/+||; s|/+$||; s|/+|/|g')
[ -n "$repo_root" ] || { echo "repo-root required" >&2; exit 2; }
[ -n "$title" ] || { echo "title required" >&2; exit 2; }
[ -n "$parent" ] || { echo "parent required" >&2; exit 2; }
[ -n "$projex_dir" ] || projex_dir=".projex"
[ -d "$repo_root" ] || { echo "Repository root not found: $repo_root" >&2; exit 2; }

# suffix is authoritative per each *-projex.md spec and does NOT always match the type
# key (e.g. propose->proposal, define->def, navigate->nav).
case "$type" in
    propose)   suffix="proposal" ;;
    plan)      suffix="plan" ;;
    eval)      suffix="eval" ;;
    review)    suffix="review" ;;
    redteam)   suffix="redteam" ;;
    stress)    suffix="stress" ;;
    audit)     suffix="audit" ;;
    interview) suffix="interview" ;;
    coach)     suffix="coach" ;;
    log)       suffix="log" ;;
    memo)      suffix="memo" ;;
    patch)     suffix="patch" ;;
    preplan)   suffix="preplan" ;;
    debug)     suffix="debug" ;;
    define)    suffix="def" ;;
    navigate)  suffix="nav" ;;
    map)       suffix="map" ;;
    scan)      suffix="scan" ;;
    explore)   suffix="explore" ;;
    guide)     suffix="guide" ;;
    imagine)   suffix="imagine" ;;
    conclude)  suffix="conclude" ;;
    archive)   suffix="archive" ;;
    *) echo "Unknown type '$type'. Valid: propose plan eval review redteam stress audit interview coach log memo patch preplan debug define navigate map scan explore guide imagine conclude archive" >&2; exit 2 ;;
esac

if [[ "$parent" != User && "$parent" != Orchestrator ]]; then
    if [[ "$parent" == */* || "$parent" == *\\* || ! "$parent" =~ ^[0-9]{10}-[a-z0-9][a-z0-9-]*-[a-z0-9][a-z0-9-]*\.md$ ]]; then
        echo "Invalid parent: $parent (expected User, Orchestrator, or a projex filename)" >&2
        exit 2
    fi
fi

born_closed="log archive patch preplan scan guide conclude"
is_born_closed=false
for t in $born_closed; do
    [ "$type" = "$t" ] && is_born_closed=true && break
done
if $is_born_closed; then
    status="Closed"
    rel_dir="$projex_dir/closed"
else
    status="Draft"
    rel_dir="$projex_dir"
fi
dir="$repo_root/$rel_dir"

slug=$(printf '%s' "$title" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//')
if [ -z "$slug" ]; then
    echo "Title produces an empty slug" >&2
    exit 2
fi

stamp=$(date +%y%m%d%H%M)
file_name="${stamp}-${slug}-${suffix}.md"
path="$dir/$file_name"
if [ "$parent" = "$file_name" ]; then
    echo "Parent cannot equal generated filename: $file_name" >&2
    exit 2
fi

# Existing identity is repo-scoped across every discoverable .projex lifecycle folder.
collision=""
while IFS= read -r projex_root; do
    [ -n "$projex_root" ] || continue
    if [ -e "$projex_root/$file_name" ]; then
        collision="$projex_root/$file_name"
        break
    fi
    while IFS= read -r candidate; do
        [ "$(basename "$candidate")" = "$file_name" ] || continue
        collision="$candidate"
        break 2
    done < <(find "$projex_root" -type f -name '*.md' -print)
done < <(find "$repo_root" -type d \( -name .git -o -name .projexwt \) -prune -o -type d -name .projex -print)
if [ -n "$collision" ]; then
    echo "Filename collision: $file_name already discovered at $collision" >&2
    exit 2
fi

mkdir -p "$dir"
if ! cat > "$path" <<EOF
# ${title}

> **Status:** ${status}
> **Author:** [name or agent]
> **Parent:** ${parent}
> **Related Projex:** [none yet]

---
EOF
then
    echo "Failed to create file: $path" >&2
    exit 1
fi
if [ ! -f "$path" ]; then
    echo "Failed to create file: $path" >&2
    exit 1
fi

echo "$path"
echo "# next: scaffold contains header only — update the format, structure and content per ${type}-projex.md"
script_dir="$(cd "$(dirname "$0")" && pwd)"
echo "# commit: $script_dir/stage-n-commit.sh $repo_root \"projex($type): add $slug\" $rel_dir/$file_name"