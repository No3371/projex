#!/usr/bin/env python3
import os
import re
import sys
from collections import defaultdict

NAME_RE = re.compile(r'^[0-9]{10}-[a-z0-9][a-z0-9-]*-[a-z0-9][a-z0-9-]*\.md$')


def fail(code, locator, detail):
    return (code, locator.replace(os.sep, '/'), detail)


def discover(repo):
    roots = []
    for base, dirs, files in os.walk(repo):
        dirs[:] = sorted(d for d in dirs if d not in {'.git', '.projexwt'})
        if base != repo and '.git' in dirs:
            dirs[:] = []
            continue
        if os.path.basename(base) == '.projex':
            roots.append(base)
    docs = []
    for root in roots:
        for base, dirs, files in os.walk(root):
            dirs[:] = sorted(d for d in dirs if d not in {'.git', '.projexwt'})
            if '.git' in dirs:
                dirs[:] = []
                continue
            for name in sorted(files):
                if name.endswith('.md'):
                    path = os.path.join(base, name)
                    rel = os.path.relpath(path, repo).replace(os.sep, '/')
                    try:
                        with open(path, 'rb') as fh:
                            raw = fh.read()
                    except OSError as exc:
                        raise OSError(rel, str(exc))
                    try:
                        text = raw.decode('utf-8-sig')
                    except UnicodeDecodeError:
                        raise OSError(rel, 'invalid UTF-8')
                    lines = text.splitlines()
                    parents = []
                    started = False
                    for idx, line in enumerate(lines):
                        if idx == 0 and line.startswith('#'):
                            started = True
                            continue
                        if line.strip() == '---':
                            break
                        if line.startswith('> '):
                            started = True
                            if line.startswith('> **Parent:**'):
                                parents.append(line[len('> **Parent:**'):].strip())
                            continue
                        if line.strip() == '':
                            continue
                        if started:
                            break
                    docs.append({'name': name, 'path': path, 'rel': rel, 'parents': parents})
    return docs


def main(argv):
    if len(argv) != 3:
        print('projex-tree: E_USAGE: invocation: expected <repo-root> <filename>', file=sys.stderr)
        return 2
    repo, target = argv[1:]
    if not os.path.isdir(repo):
        print(f'projex-tree: E_REPO: {repo}: repository root not found', file=sys.stderr)
        return 2
    if not target or os.path.basename(target) != target:
        print(f'projex-tree: E_TARGET_NAME: {target or "<empty>"}: filename basename required', file=sys.stderr)
        return 2
    try:
        docs = discover(os.path.abspath(repo))
    except OSError as exc:
        loc, detail = exc.args
        print(f'projex-tree: E_IO: {loc}: {detail}', file=sys.stderr)
        return 4
    by_name = defaultdict(list)
    for doc in docs:
        by_name[doc['name']].append(doc)
    if target not in by_name:
        print(f'projex-tree: E_TARGET_NOT_FOUND: {target}: document not found', file=sys.stderr)
        return 2
    if len(by_name[target]) != 1:
        print(f'projex-tree: E_TARGET_AMBIGUOUS: {target}: filename resolves to multiple documents', file=sys.stderr)
        return 2

    errors = []
    target_doc = by_name[target][0]
    chain = []
    current = target_doc
    seen = set()
    while True:
        name = current['name']
        if name in seen:
            errors.append(fail('E_CYCLE', current['rel'], 'Parent chain cycles'))
            break
        seen.add(name)
        chain.append(current)
        parents = current['parents']
        if len(parents) > 1:
            errors.append(fail('E_PARENT_DUPLICATE', current['rel'], 'multiple Parent headers'))
            break
        if not parents:
            break
        parent = parents[0]
        if parent in {'User', 'Orchestrator'}:
            break
        if not NAME_RE.fullmatch(parent):
            errors.append(fail('E_PARENT_MALFORMED', current['rel'], f'Parent is not a projex filename: {parent}'))
            break
        if parent == name:
            errors.append(fail('E_PARENT_SELF', current['rel'], 'Parent names the document itself'))
            break
        if parent not in by_name:
            errors.append(fail('E_PARENT_DANGLING', current['rel'], f'Parent not discovered: {parent}'))
            break
        if len(by_name[parent]) != 1:
            errors.append(fail('E_IDENTITY_DUPLICATE', parent, 'Parent identity resolves to multiple documents'))
            break
        current = by_name[parent][0]

    if errors:
        for code, loc, detail in sorted(set(errors)):
            print(f'projex-tree: {code}: {loc}: {detail}', file=sys.stderr)
        return 3

    root_name = chain[-1]['name']
    members = {doc['name']: doc for doc in chain}
    children = defaultdict(list)
    for child, parent in zip(chain, chain[1:]):
        children[parent['name']].append(child)
    queue = [doc['name'] for doc in reversed(chain)]
    while queue:
        parent_name = queue.pop(0)
        for doc in docs:
            parents = doc['parents']
            if len(parents) > 1:
                if parent_name in parents:
                    errors.append(fail('E_PARENT_DUPLICATE', doc['rel'], 'multiple Parent headers'))
                continue
            if len(parents) != 1 or parents[0] in {'User', 'Orchestrator'}:
                continue
            parent = parents[0]
            if not NAME_RE.fullmatch(parent) or parent != parent_name:
                continue
            if len(by_name[doc['name']]) != 1:
                errors.append(fail('E_IDENTITY_DUPLICATE', doc['name'], 'child identity resolves to multiple documents'))
                continue
            if len(children[parent_name]) and doc['name'] in [c['name'] for c in children[parent_name]]:
                continue
            if doc['name'] in members:
                continue
            members[doc['name']] = doc
            children[parent_name].append(doc)
            queue.append(doc['name'])
    for doc in docs:
        if len(doc['parents']) > 1 and doc['name'] in members:
            errors.append(fail('E_PARENT_DUPLICATE', doc['rel'], 'multiple Parent headers'))
        elif doc['name'] in members and doc['parents'] and not (doc['parents'][0] in {'User', 'Orchestrator'} or NAME_RE.fullmatch(doc['parents'][0])):
            errors.append(fail('E_PARENT_MALFORMED', doc['rel'], f'Parent is not a projex filename: {doc["parents"][0]}'))
    visiting, visited = set(), set()
    def check_cycle(name):
        if name in visiting:
            errors.append(fail('E_CYCLE', name, 'descendant Parent edges cycle'))
            return
        if name in visited:
            return
        visiting.add(name)
        for child in children.get(name, []):
            check_cycle(child['name'])
        visiting.remove(name)
        visited.add(name)
    check_cycle(root_name)
    if errors:
        for code, loc, detail in sorted(set(errors)):
            print(f'projex-tree: {code}: {loc}: {detail}', file=sys.stderr)
        return 3

    def render(doc_name, prefix='', root=False):
        out = [doc_name] if root else []
        child_docs = sorted(children.get(doc_name, []), key=lambda d: d['name'])
        for idx, child in enumerate(child_docs):
            last = idx == len(child_docs) - 1
            out.append(prefix + ('└── ' if last else '├── ') + child['name'])
            out.extend(render(child['name'], prefix + ('    ' if last else '│   ')))
        return out
    print('\n'.join(render(root_name, root=True)))
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))
