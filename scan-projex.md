---
description: This workflow guides the creation of **Scan** projex documents — comprehensive inventories of everything connected to a given subject, presented as a flat list optimized for precision and coverage. (This is part of @projex-framework skill. It is a MUST to load the skill first.)
---

## PURPOSE

Scans produce exhaustive lists. Given a subject — a concept, a dependency, a pattern, an API surface, a keyword — the agent systematically finds every occurrence, reference, or connection and records it. The output is a flat, precise inventory with no analysis or recommendations.

**Key characteristics:**
- **Coverage over insight** — find everything, explain nothing
- **Precision matters** — every entry must be real and accurately located (`file:ln`, or the medium-appropriate locator — see Format adaptation)
- **No purpose required** — the scan doesn't care what the result will be used for. It just finds things.
- **Adaptive format** — usually `file:ln` entries, but adapts to subject (e.g., a scan of API endpoints might list `METHOD /path → handler`)
- **Born closed** — scans are point-in-time snapshots

**Contrast with Exploration:**
- **Scan** — finds everything connected to X, lists it. No synthesis, no mental model, no "why"
- **Exploration** — investigates how something works, builds understanding, produces findings and answers

**When to use:**
- "Where is X used across the codebase?"
- "List every file that references Y"
- "Find all places where pattern Z appears"
- "Inventory all public API endpoints"
- "What depends on this module?"
- Before a Plan — to know the full blast radius of a change
- Before a Red Team — to map the attack surface
- Before a Review — to find everything that might be stale

---

## INVOCATION

```
/scan-projex <subject to scan for>
```

**Examples:**
- `/scan-projex All usages of the AuthToken class`
- `/scan-projex Every file that imports from the legacy/ directory`
- `/scan-projex All error handling patterns in src/api/`
- `/scan-projex Public methods on the Parser interface`
- `/scan-projex Every TODO and FIXME in the project`
- `/scan-projex All references to the pricing calculation`
- `/scan-projex Every unresolved citation across the manuscript`

---

## WORKFLOW STEPS

### 1. DEFINE THE SCAN TARGET

Clarify exactly what to look for:

- **What is the subject?** — A symbol, pattern, keyword, concept, dependency, file, module, API, etc.
- **What counts as a match?** — Direct usage, transitive reference, naming pattern, conceptual relation?
- **What is the scan boundary?** — Whole repo, specific directories, specific file types?

If the subject is ambiguous, ask the user before scanning. Precision of the target determines precision of the results.

### 2. SCAN

Search systematically. Use whatever combination of tools finds everything:

- **Grep/search** for direct references (names, imports, calls)
- **Trace dependencies** for transitive connections (what uses what uses X)
- **Read files** to confirm matches aren't false positives (string matches in comments, similarly-named but unrelated symbols)
- **Check multiple angles** — a class might be referenced by name, by import, by type annotation, by string literal, by reflection

**Precision rules:**
- Every entry in the final list must be verified — no "probably also used in..."
- False positives are worse than missing entries. If uncertain, check before listing
- Record the exact line number, not just the file

### 3. WRITE THE SCAN DOCUMENT

```bash
{projex-scripts}/new-projex.{sh|ps1} <repo-root> scan "{scan-name}" <projex-folder>
```

**Template:**

```markdown
# Scan: [Subject]

> **Author:** [name or agent]
> **Subject:** [exactly what was scanned for]
> **Boundary:** [scope of the scan — whole repo, specific dirs, etc.]
> **Match Criteria:** [what counted as a hit]
> **Related Projex:** [links, if this scan was prompted by another projex]

---

## Results

[Total: N matches across M files]

### [Group — by directory, by type, by relationship, or ungrouped if flat]

- `path/to/file.ext:42` — [brief annotation: what the match is]
- `path/to/file.ext:108` — [brief annotation]
- `path/to/other.ext:15` — [brief annotation]

### [Next Group]

- `path/to/another.ext:7` — [brief annotation]

---

## Coverage Notes

- [Areas that were scanned but had zero matches — confirms absence, not omission]
- [Areas excluded from the scan and why, if any]
- [Known limitations — e.g., "dynamic references via reflection not captured"]
```

**Format adaptation:**

The default is `file:ln — annotation`, but adapt to the subject:

| Subject | Format |
|---------|--------|
| Code references | `file:ln` — what the reference does |
| API endpoints | `METHOD /path` → `handler` (file:ln) |
| Dependencies | `package@version` — used by [list] |
| Config keys | `key = value` — in `file:ln` |
| Database references | `table.column` — queried in `file:ln` |
| Document/manuscript content | `doc § heading` or `page:para` — what the match is |
| Web/external sources | `URL#anchor` — what the match is |

### 4. PRESENT THE SCAN

Surface the scan file path and entry count summary to the user. **Do not commit.** Wait — commit only when the user explicitly requests it.

When the user requests a commit:

```bash
{projex-scripts}/stage-n-commit.{sh|ps1} <repo-root> "projex(scan): {subject}" .projex/closed/{yymmddhhmm}-{scan-name}-scan.md
```

---

## SCAN PRINCIPLES

- **Exhaustive** — the goal is zero misses. A scan that finds 47 of 50 references is a bad scan
- **Precise** — every listed entry must be real and correctly located. No guesses, no "likely also in..."
- **Unopinionated** — don't prioritize, don't recommend, don't analyze. Just list
- **Grouped for navigation** — group by directory, module, or relationship type so the consumer can find what they need. But grouping is for readability, not for analysis
- **Honest about limits** — if dynamic dispatch, reflection, or string-based references make exhaustive scanning impossible, say so in Coverage Notes

---

## FOLDER PLACEMENT

| State | Location |
|-------|----------|
| Complete (always) | `.projex/closed/` matching the relevant scope |

Scans are born closed. They are point-in-time snapshots — if the codebase changes, run a new scan rather than revising.

---

## OUTPUT

This workflow produces:
- A scan document at `.projex/closed/{yymmddhhmm}-{scan-name}-scan.md`
- A flat, precise inventory of everything matching the subject

---

## NOTES

- Scans are input to other workflows, not ends in themselves. A scan naturally feeds into Plans (blast radius), Red Teams (attack surface), Reviews (staleness check), or Evaluations (scope assessment)
- If you find yourself wanting to explain *why* something is referenced, you're drifting into Exploration territory. Record the *what* and stop
- Multiple scans can cover different facets of the same subject (e.g., one for imports, one for type annotations, one for test mocks)
- Use relative paths from the repo root
