#!/usr/bin/env bash
set -euo pipefail
if [ "$#" -ne 2 ]; then
    echo "projex-tree: E_USAGE: invocation: expected <repo-root> <filename>" >&2
    exit 2
fi
repo_root=$1
filename=$2
script_dir=$(cd "$(dirname "$0")" && pwd)
exec python3 "$script_dir/.projex-tree.py" "$repo_root" "$filename"
