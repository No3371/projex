---
description: This workflow guides the creation and maintenance of **Map** projex documents — living structural indexes that describe what each directory and key file is about, so agents can orient quickly without exploring from scratch. (This is part of @projex-framework skill. It is a MUST to load the skill first.)
---

## PURPOSE

Map documents are orientation tools. They maintain a high-level description of a scope's file and directory structure — what each path contains and why it exists — so that any agent starting work can skip the costly "explore everything" phase and jump to the relevant area.

**Key characteristics:**
- Living document — continuously revised and appended, never "closed"
- High-level descriptions, not exhaustive file listings — enough to know where to look, not a substitute for reading the code
- Incrementally built — does not need to be fully mapped in one pass; grows as the project grows
- Scope-flexible — can map an entire workspace, a single repo, or a specific module/area
- Structural, not directional — describes what IS, not what SHOULD BE (contrast with Navigation)

**Contrast with Navigation:**
- **Map** — structural index; answers "what lives where and what is it about?"
- **Navigation** — directional roadmap; answers "what should we work on next?"

**Contrast with Exploration:**
- **Map** — maintained artifact; high-level index that persists and evolves across sessions
- **Exploration** — point-in-time investigation; deep-dive into how something works, then closed

---

## INVOCATION

```
/map-projex.md <scope description>
/map-projex.md @{existing-map-document}
```

**First invocation** (create new map):
- `/map-projex.md Whole project structure` — project-level, lives in root `projex/`
- `/map-projex.md Parser module layout` — module-level, lives in `src/parser/projex/`
- `/map-projex.md Documentation structure` — area-level, lives in `docs/projex/`

**Subsequent invocations** (revise and extend):
- `/map-projex.md @20260208-engine-structure-map.md`
- `/map-projex.md @20260208-engine-structure-map.md We added a new plugin system`

---

## WORKFLOW STEPS

### CREATING A NEW MAP

#### 1. SURVEY THE SCOPE

Explore the target scope's file and directory structure:

1. **List top-level directories** — What are the major areas?
2. **Identify key files at each level** — Entry points, configs, READMEs, manifests
3. **Read existing documentation** — READMEs, inline comments, doc headers that describe purpose
4. **Note conventions** — Naming patterns, folder organization principles, file type groupings
5. **Check for existing maps** — Is there already a map for this scope or a parent/child scope?

> **Depth guidance:** Start broad. Map the top 1-2 levels of directories with descriptions. Go deeper only for areas that are non-obvious or structurally important. Deeper levels can be added in future revisions.

#### 2. DISCUSS WITH USER (if needed)

For ambiguous structures or large scopes:

- "I see these major areas: [list]. Does this grouping make sense, or am I missing something?"
- "What is `src/legacy/` — is it actively used or scheduled for removal?"
- "Should this map cover `vendor/` and `third_party/`, or skip external code?"

For straightforward structures, proceed directly to drafting.

#### 3. DRAFT THE MAP

Create file in the appropriate `projex/` folder: `{yyyymmdd}-{map-name}-map.md`

- Project-level → root `projex/`
- Module-level → `src/{module}/projex/`
- Area-level → `{area}/projex/`

**Template Structure:**

```markdown
# [Map Title]

> **Created:** YYYY-MM-DD | **Last Revised:** YYYY-MM-DD
> **Author:** [name or agent]
> **Scope:** [what this map covers — repo root, specific module, etc.]
> **Parent Map:** [link to broader-scope map, if any]

---

## Overview

[2-4 sentences: What this project/module/area is and its general organization principle]

---

## Structure

### `src/`
[1-2 sentence description of what this directory contains overall]

- `parser/` — [What the parser module does and contains]
  - `lexer/` — [Tokenization, token types]
  - `ast/` — [AST node definitions, builder]
- `runtime/` — [Runtime engine purpose]
- `cli/` — [CLI entry point, argument handling]

### `docs/`
[Description]

- `spec/` — [Language specification documents]
- `guides/` — [User-facing guides and tutorials]

### `tests/`
[Description]

- `unit/` — [Unit test organization]
- `integration/` — [Integration test setup]

### Key Root Files

| File | Purpose |
|------|---------|
| `README.md` | [What it covers] |
| `Cargo.toml` / `package.json` / etc. | [Build config, dependencies] |
| `.env.example` | [Environment variable template] |

---

## Conventions

- [Observed pattern, e.g. "Each module has its own `types.ts` exporting public interfaces"]
- [Naming convention, e.g. "Test files mirror source paths: `src/foo/bar.ts` → `tests/foo/bar.test.ts`"]
- [Organization rule, e.g. "Feature code is grouped by domain, not by layer"]

---

## Unmapped Areas

- `path/to/area/` — [Not yet explored; noted for future revision]

---

## Revision Log

| Date | Summary of Changes |
|------|--------------------|
| YYYY-MM-DD | Initial map created |
```

**Formatting guidelines:**
- Use nested lists for the directory tree — scannable and easy to diff
- Descriptions should be **what it is and why**, not how it works internally
- Mark directories with trailing `/` to distinguish from files
- Keep descriptions to one line where possible; use two lines for genuinely complex areas
- Include the `Unmapped Areas` section honestly — partial maps are expected and useful

#### 4. VALIDATE AND COMMIT

**Check:**
- [ ] Top-level structure accurately reflects the scope
- [ ] Descriptions are high-level and orientation-focused (not implementation details)
- [ ] No paths are fabricated — every listed path actually exists
- [ ] Key entry points and config files are called out
- [ ] Unmapped areas are acknowledged, not silently omitted
- [ ] Placed in the correct `projex/` folder for its scope

```bash
git add projex/{yyyymmdd}-{map-name}-map.md
git commit -m "projex(map): create structure map - {map-name}"
```

---

### REVISITING AN EXISTING MAP

This is the primary mode — maps are revisited as the project evolves.

#### 1. DETECT STRUCTURAL CHANGES

1. **Read the existing map** — Understand what's currently documented
2. **Survey the actual structure** — List current directories and key files in the scope
3. **Diff against the map** — Identify:
   - **New paths** — Directories/files that exist but aren't in the map
   - **Removed paths** — Entries in the map for paths that no longer exist
   - **Renamed/moved paths** — Paths that shifted location
   - **Changed purpose** — Directories whose contents have evolved beyond their description
4. **Check unmapped areas** — Are any previously-unmapped areas now worth documenting?

#### 2. UPDATE THE MAP

Update the document in-place:

1. **Update "Last Revised" date**
2. **Add new entries** — Describe newly discovered directories/files
3. **Remove stale entries** — Delete entries for paths that no longer exist
4. **Revise descriptions** — Update descriptions that no longer accurately reflect contents
5. **Promote from Unmapped** — Move areas from "Unmapped" to the structure section as they're documented
6. **Add new Unmapped entries** — Note newly discovered areas not yet fully explored
7. **Update Conventions** — Add newly observed patterns; remove conventions that no longer hold
8. **Append to revision log** — Summarize what changed

#### 3. COMMIT REVISION

```bash
git add projex/{yyyymmdd}-{map-name}-map.md
git commit -m "projex(map): revise structure map - {map-name}"
```

---

## MAP PRINCIPLES

- **Orientation, not documentation** — A map tells you where to look, not how things work. If a description exceeds two sentences, it's too detailed for a map — that depth belongs in an Exploration or the code's own documentation
- **Honest about gaps** — A partial map that admits its gaps is more useful than a complete-looking map that's wrong. Use the Unmapped Areas section freely
- **Living, not archived** — Map documents stay in their `projex/` folder for their entire active lifetime. They are never moved to `closed/`
- **One per scope** — Each scope should have at most one active map in its `projex/` folder. If a scope grows too large, split into separate maps at the appropriate level with cross-references
- **Nestable** — A project-level map can reference module-level maps for detail. A module-level map can reference its parent for broader context. Avoid duplicating descriptions across levels — link instead
- **Structure over content** — Describe what a directory *is about*, not what every file in it does. Agents can read the files themselves once they know where to look
- **Verifiable** — Every path listed in the map must actually exist. Stale entries erode trust in the whole document

---

## FOLDER PLACEMENT

| State | Location |
|-------|----------|
| Active (always) | The `projex/` folder matching the map's scope |
| Superseded by new map | `projex/archived/` within the same scope |

Map documents are **never** placed in `projex/closed/` — they are living documents that persist until their scope's structure stabilizes or a new map supersedes them.

**Examples:**
- Project-level: `projex/20260208-project-structure-map.md`
- Module-level: `src/parser/projex/20260208-parser-layout-map.md`
- Area-level: `docs/projex/20260208-docs-structure-map.md`

---

## NOTES

- Maps are the fastest way to onboard a new agent or resume work after a long break
- A map revision can be triggered naturally during any other workflow — if an agent notices structural drift while planning or executing, suggest a map revision
- Do not list every file — focus on directories and only call out individual files when they are key entry points, configs, or otherwise non-obvious
- Use relative paths from the scope root when referencing repository files
- When a map grows unwieldy, split by domain into separate maps at the appropriate folder level
