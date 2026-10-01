#!/usr/bin/env bash
# Read-only Parent lineage tree for one projex document: follows the target's Parent chain to its
# root, then prints every current-corpus descendant of that root as a box-drawing tree. A well-formed
# Parent naming no discovered document (deleted by archive or conclude) ends the chain: that filename
# becomes the root, printed as "<filename> (missing)", and the tree renders beneath it.
# Usage: projex-tree.sh <repo-root> <filename>
# Exit: 0 tree on stdout | 2 usage, repo, or target error | 3 lineage errors | 4 unreadable or non-UTF-8 document.
# Error lines on stderr: "projex-tree: <code>: <locator>: <detail>". All output is UTF-8 with LF line ends.
# Assumes no file or directory name contains a newline, \001, or \002 byte (used as sort-key separators).
set -euo pipefail
die() { printf 'projex-tree: %s\n' "$1" >&2; exit "$2"; }

[ "$#" -eq 2 ] || die 'E_USAGE: invocation: expected <repo-root> <filename>' 2
repo=$1
target=$2
# "cd -" would jump to OLDPWD and a bare relative name may resolve through CDPATH
dir=$repo
[ "$dir" = - ] && dir=./-
if [ ! -d "$repo" ] || ! CDPATH='' cd -P -- "$dir" 2>/dev/null; then
    die "E_REPO: $repo: repository root not found" 2
fi
case $target in
    '') die 'E_TARGET_NAME: <empty>: filename basename required' 2 ;;
    */* | *\\* | *:*) die "E_TARGET_NAME: $target: filename basename required" 2 ;;
esac

# A repository root that is itself a .projex directory makes every .md below it a document
under='*/.projex/*'
[ "$(basename -- "$(pwd -P)")" = .projex ] && under='*'

# Directories holding a .git entry (dir, or gitdir file) below the root are other repositories
nested=$(find . \( -path ./.git -o -name .projexwt \) -prune -o -name .git -print -prune 2>/dev/null || true)

# Walk-order key: each directory component followed by \002, the file name prefixed by \001.
# Byte-sorting the keys yields a pre-order walk with a directory's files before its subdirectories
# and "x" before "x-y"; sorting raw paths would instead put "x-y/" before "x/" ("-" < "/").
keys='
BEGIN {
    n = split(ENVIRON["PT_NESTED"], nested, "\n")
    for (i = 1; i <= n; i++) { sub(/^\.\//, "", nested[i]); sub(/\.git$/, "", nested[i]) }
}
{
    rel = substr($0, 3)
    for (i = 1; i <= n; i++) if (nested[i] != "" && index(rel, nested[i]) == 1) next
    name = rel; sub(/.*\//, "", name)
    dirs = substr(rel, 1, length(rel) - length(name))
    gsub(/\//, "\002", dirs)
    print dirs "\001" name
}'

# Reads every document in walk order, parses its header, resolves the lineage, and prints either the
# tree (exit 0), one error line (exit 2 or 4), or "code\001locator\001detail" records (exit 3).
engine='
function fail(line, code) { print "projex-tree: " line; exit code }
function err(code, loc, detail) { print code "\001" loc "\001" detail; nerr++ }
function strip(s) {
    while (sub(WS_HEAD, "", s)) { }
    while (sub(WS_TAIL, "", s)) { }
    return s
}
function load(d, path,   r, line, n, i, t, s, m, k, parts, idx, started, sp) {
    n = 0
    while ((r = (getline line < path)) > 0) buf[++n] = line
    # getline keeps the file open until close(); without it BWK awk and mawk run out of file descriptors on a large corpus
    close(path)
    if (r < 0) fail("E_IO: " rel[d] ": read failed", 4)
    for (i = 1; i <= n; i++) {
        t = buf[i]
        # NUL is valid UTF-8 but the UTF8 byte regex starts at \001, so it is removed from the copy before the match
        gsub(/\000/, "", t)
        if (t !~ UTF8) fail("E_IO: " rel[d] ": invalid UTF-8", 4)
    }
    if (n > 0 && substr(buf[1], 1, 3) == "\357\273\277") buf[1] = substr(buf[1], 4)
    np[d] = 0; idx = 0; started = 0
    for (i = 1; i <= n; i++) {
        s = buf[i]
        gsub(/\015|\013|\014|\034|\035|\036|\302\205|\342\200\250|\342\200\251/, "\n", s)
        m = split(s, parts, "\n")
        if (m == 0) { m = 1; parts[1] = "" }
        for (k = 1; k <= m; k++) {
            s = parts[k]
            if (idx++ == 0 && substr(s, 1, 1) == "#") { started = 1; continue }
            sp = strip(s)
            if (sp == "---") return
            if (substr(s, 1, 2) == "> ") {
                started = 1
                if (substr(s, 1, 13) == "> **Parent:**") par[d, ++np[d]] = strip(substr(s, 14))
                continue
            }
            if (sp == "") continue
            if (started) return
        }
    }
}
function render(nm, prefix,   n, i, j, v, kid, last) {
    n = nk[nm]
    for (i = 1; i <= n; i++) kid[i] = kids[nm, i]
    for (i = 2; i <= n; i++) {
        v = kid[i]
        for (j = i - 1; j >= 1 && kid[j] > v; j--) kid[j + 1] = kid[j]
        kid[j + 1] = v
    }
    for (i = 1; i <= n; i++) {
        last = i == n
        print prefix (last ? ELBOW : TEE) kid[i]
        render(kid[i], prefix (last ? "    " : PIPE))
    }
}
BEGIN {
    UTF8 = "^([\001-\177]|[\302-\337][\200-\277]|\340[\240-\277][\200-\277]|[\341-\354\356\357][\200-\277][\200-\277]"
    UTF8 = UTF8 "|\355[\200-\237][\200-\277]|\360[\220-\277][\200-\277][\200-\277]|[\361-\363][\200-\277][\200-\277][\200-\277]"
    UTF8 = UTF8 "|\364[\200-\217][\200-\277][\200-\277])*$"
    WS = "([\011-\015\034-\040]|\302\205|\302\240|\341\232\200|\342\200[\200-\212]|\342\200\250|\342\200\251|\342\200\257|\342\201\237|\343\200\200)"
    WS_HEAD = "^" WS
    WS_TAIL = WS "$"
    NAME = "^[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-[a-z0-9][a-z0-9-]*-[a-z0-9][a-z0-9-]*[.]md$"
    TEE = "\342\224\234\342\224\200\342\224\200 "
    ELBOW = "\342\224\224\342\224\200\342\224\200 "
    PIPE = "\342\224\202   "
    target = ENVIRON["PT_TARGET"] ""
}
{ key[++D] = $0 }
END {
    for (d = 1; d <= D; d++) {
        r = key[d]
        gsub(/\002/, "/", r)
        sub(/\001/, "", r)
        rel[d] = r
        nm = key[d]; sub(/.*\001/, "", nm)
        name[d] = nm
        load(d, "./" r)
        cnt[nm]++
        if (cnt[nm] == 1) first[nm] = d
    }
    if (!(target in cnt)) fail("E_TARGET_NOT_FOUND: " target ": document not found", 2)
    if (cnt[target] != 1) fail("E_TARGET_AMBIGUOUS: " target ": filename resolves to multiple documents", 2)

    cur = first[target]; nc = 0
    while (1) {
        nm = name[cur]
        if (nm in seen) { err("E_CYCLE", rel[cur], "Parent chain cycles"); break }
        seen[nm] = 1
        chain[++nc] = cur
        if (np[cur] > 1) { err("E_PARENT_DUPLICATE", rel[cur], "multiple Parent headers"); break }
        if (np[cur] == 0) break
        p = par[cur, 1]
        if (p == "User" || p == "Orchestrator") break
        if (p !~ NAME) { err("E_PARENT_MALFORMED", rel[cur], "Parent is not a projex filename: " p); break }
        if (p == nm) { err("E_PARENT_SELF", rel[cur], "Parent names the document itself"); break }
        if (!(p in cnt)) { missing = p; break }
        if (cnt[p] != 1) { err("E_IDENTITY_DUPLICATE", p, "Parent identity resolves to multiple documents"); break }
        cur = first[p]
    }
    if (nerr) exit 3

    # Members admitted below each holder have exactly one well-formed Parent and enter once, so the
    # member set is a tree: a descendant cycle check or a member multi-Parent re-scan after this
    # loop could never fire, so neither exists.
    for (i = 1; i <= nc; i++) member[name[chain[i]]] = 1
    for (i = 1; i < nc; i++) { pn = name[chain[i + 1]]; kids[pn, ++nk[pn]] = name[chain[i]] }
    root = name[chain[nc]]
    if (missing != "") { kids[missing, ++nk[missing]] = root; root = missing }
    qt = 0
    if (missing != "") queue[++qt] = missing
    for (i = nc; i >= 1; i--) queue[++qt] = name[chain[i]]
    for (qh = 1; qh <= qt; qh++) {
        pn = queue[qh]
        for (d = 1; d <= D; d++) {
            if (np[d] > 1) {
                for (k = 1; k <= np[d]; k++) if (par[d, k] == pn) { err("E_PARENT_DUPLICATE", rel[d], "multiple Parent headers"); break }
                continue
            }
            if (np[d] != 1) continue
            p = par[d, 1]
            if (p != pn || p == "User" || p == "Orchestrator" || p !~ NAME) continue
            if (cnt[name[d]] != 1) { err("E_IDENTITY_DUPLICATE", name[d], "child identity resolves to multiple documents"); continue }
            if (name[d] in member) continue
            member[name[d]] = 1
            kids[pn, ++nk[pn]] = name[d]
            queue[++qt] = name[d]
        }
    }
    if (nerr) exit 3

    print root (missing != "" ? " (missing)" : "")
    render(root, "")
}'

# Engine output goes to a file, not $(...): command substitution drops NUL bytes, which a Parent value may hold
out=$(mktemp)
trap 'rm -f "$out"' EXIT
rc=0
# PT_NESTED / PT_TARGET reach awk through ENVIRON: awk -v processes backslash escapes and would mangle a path or name holding "\"
{ find . \( -name .git -o -name .projexwt \) -prune -o -type f -name '*.md' -path "$under" -print 2>/dev/null || true; } |
    PT_NESTED=$nested LC_ALL=C awk "$keys" |
    LC_ALL=C sort |
    PT_TARGET=$target LC_ALL=C awk "$engine" > "$out" || rc=$?
case $rc in
    0) cat "$out" ;;
    3) LC_ALL=C sort -u "$out" | LC_ALL=C awk '{ sub(/\001/, ": "); sub(/\001/, ": "); print "projex-tree: " $0 }' >&2 ;;
    *) cat "$out" >&2 ;;
esac
exit "$rc"
