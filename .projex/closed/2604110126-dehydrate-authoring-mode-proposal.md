# Dehydrate: Extreme-Concise Authoring Mode for Projex Documents

> **Status:** Accepted
> **Created:** 2026-04-11
> **Author:** Claude (agent)
> **Related Projex:** None

---

## Summary

Add a "Dehydrate" section to SKILL.md's Authoring block — a standing principle (not opt-in mode) that all projex output uses maximally compressed form while fully preserving semantic and technical content. Unlike De-slop (which strips filler from normal prose), Dehydrate is a fundamentally different output register: dense shorthand from the start, not cleaned-up prose.

> **Accepted with modification (2026-04-11):** Dehydrate is always-on — no activation mechanism, no header flags, no per-document opt-in. It is how projex documents are written.

---

## Problem Statement

### Current State

SKILL.md's Authoring section has one output-quality mechanism:

- **De-slop** — optional post-hoc cleanup. Strips agent self-talk, throat-clearing, redundancy, hollow hedging, unfilled template artifacts. Output remains full prose — just tighter.

### Gap / Need / Opportunity

Projex documents are consumed by two audiences: humans and agents. For agent consumption (re-reading a plan during execution, referencing an eval during planning, loading context for a review), full prose wastes tokens without adding value. An agent doesn't need "The authentication subsystem currently handles session management through a middleware layer that intercepts incoming requests." It needs "Auth subsystem: session mgmt via middleware, intercepts incoming requests."

Even for human consumption, some projex types are reference artifacts (Scans, Logs, Maps) where density serves readability — a tighter document scans faster.

No mechanism currently exists to signal "write this compressed." De-slop doesn't fill this role — it still produces normal prose, just without the filler. The gap is between "clean prose" and "dense shorthand."

### Why Now?

As projex documents accumulate in a project, they become context that future sessions load. Every unnecessary token in a plan or eval is a token unavailable for the actual work. The framework has matured enough (21 types, stable conventions) that a density mode can be specified without ambiguity about what's being compressed.

---

## Proposed Change

### Overview

Add a `Dehydrate` section to SKILL.md under Authoring, as a sibling to De-slop. It defines a set of compression techniques agents apply when the mode is active. It is opt-in — triggered by user request, document header flag, or workflow-specific default.

### Approach Options

#### Option A: Technique Catalog in SKILL.md

Add a section that defines specific compression techniques with before/after examples. Agents apply them when dehydrate mode is active.

**Techniques:**

1. **Drop filler words** — articles, prepositions, and connectives where meaning survives without them
   - Before: "The parser module is responsible for converting the input stream into an AST"
   - After: "Parser module: converts input stream → AST"

2. **Key-value shorthand** — replace narrative descriptions with structured `key: value` pairs
   - Before: "The status of the migration is currently blocked because the schema validator has not been updated"
   - After: "Migration status: Blocked — schema validator not updated"

3. **Symbolic compression** — use symbols for common relationships and states
   - `→` (leads to, becomes, produces), `←` (from, sourced by), `✓/✗` (pass/fail), `|` (or, alternatives), `~` (approximately), `⊃` (contains/includes), `∅` (none/empty)

4. **Inline lists over bullet lists** — for items under ~5 words each
   - Before:
     ```
     Affected:
     - auth module
     - session store
     - token validator
     ```
   - After: "Affected: auth module | session store | token validator"

5. **Collapse tables to dense rows** — drop header borders, use compact separators
   
6. **Omit narrative transitions** — no "Moving on to the next area..." or "Now that we've covered X, let's look at Y"

7. **Compressed headers** — strip filler words from section titles
   - Before: "## Analysis of the Current Authentication State"
   - After: "## Auth Current State"

8. **Abbreviate when unambiguous** — use established abbreviations within the document (define on first use if not standard)
   - impl, config, auth, repo, fn, param, dep, req, spec

- **Pros:** Concrete, teachable, consistent results across agents and sessions. Before/after examples make the target density unambiguous.
- **Cons:** Needs maintenance as new patterns emerge. Could feel prescriptive.
- **Effort:** Low — one section addition to SKILL.md.

#### Option B: Single Principle + Examples

Instead of a technique catalog, state a single principle ("preserve all semantic and technical content in minimum tokens") and provide 2-3 before/after example blocks showing full paragraphs compressed to dense shorthand. Let the agent infer techniques from examples.

- **Pros:** Shorter spec. Flexible — agents adapt to novel patterns.
- **Cons:** Inconsistent results. Different agents or sessions may compress differently. Harder to review whether dehydration was applied correctly.
- **Effort:** Low.

#### Option C: Two Levels (Light + Full)

Define two compression tiers:
- **Light** — Drop filler words, use key-value shorthand, omit transitions. Output is still readable prose, just telegraphic.
- **Full** — All of Light plus symbolic compression, inline lists, abbreviated terms, collapsed tables. Output is reference-grade shorthand.

- **Pros:** Granularity — human-targeted documents can use Light, agent-targeted documents can use Full.
- **Cons:** More spec to maintain. Ambiguity about which level to pick. Added decision burden.
- **Effort:** Medium.

### Recommended Approach

**Option A** — Technique Catalog. The techniques are concrete enough to produce consistent results, and the catalog is extensible. Levels (Option C) add decision overhead without proportional value — in practice the user either wants compression or doesn't, and the agent can calibrate density within the techniques based on the document type.

---

## Impact Analysis

### Affected Areas

- **SKILL.md § Authoring** — New section added after De-slop
- **All workflow specs** — None need modification. Dehydrate is opt-in and workflow-agnostic. Individual workflow specs may later add defaults (e.g., Scan and Log could default to dehydrated mode) but that's a separate change.
- **Existing projex documents** — Unaffected. Dehydrate applies to new output only.

### Interaction with De-slop

De-slop and Dehydrate are complementary, not competing:
- De-slop removes filler from normal prose → output is clean prose
- Dehydrate compresses from the start → output is dense shorthand
- Both can apply (dehydrate first, de-slop as safety net), but in practice dehydrated output has nothing for de-slop to strip

### Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Over-compression loses critical nuance | Medium | Medium | Principle: "preserve all semantic and technical content" — compression targets form, not substance |
| Human readers find dehydrated docs hard to read | Low | Low | Opt-in only; human-facing types (Guide, Interview) unlikely to be dehydrated |
| Inconsistent application across sessions | Low | Low | Technique catalog with examples provides concrete target |

### Breaking Changes

None. Purely additive. All existing behavior unchanged.

---

## Open Questions

- [x] ~~Should any projex types default to dehydrated?~~ — Resolved: always-on for all types.
- [x] ~~Should dehydrated output include a header flag?~~ — Resolved: no flags, always-on.
- [ ] Should the spec prescribe a minimum set of symbols (→, ✓/✗, |) or let agents choose freely?

---

## Next Steps

If accepted:
1. Draft the Dehydrate section for SKILL.md (plan-projex or patch-projex)
2. Add 2-3 before/after examples covering different document densities
3. Optionally: update Scan, Log, Map workflow specs to mention dehydrate as a natural fit

---

## Appendix

### Before / After: Plan Summary (Full Example)

**Normal prose (post-de-slop):**
```markdown
## Summary

This plan refactors the token validation pipeline to support multiple token formats.
Currently, the validator only handles JWT tokens, but the new auth provider requires
opaque token support. The refactor extracts format-specific logic into strategy classes
and adds a resolver that selects the correct strategy based on token structure.

**Scope:** Token validation layer in `src/auth/`
**Estimated Changes:** 4 files, 2 new classes
```

**Dehydrated:**
```markdown
## Summary

Refactor token validation → multi-format support. Current: JWT-only. Need: opaque tokens (new auth provider). Approach: extract format logic → strategy classes + resolver (selects strategy by token structure).

**Scope:** `src/auth/` token validation | **Changes:** 4 files, 2 new classes
```

### Before / After: Eval Finding

**Normal prose:**
```markdown
### Finding 3: Cache Invalidation Race Condition

**Confidence:** High

When a user updates their profile, the cache invalidation message is published
to the event bus before the database transaction commits. If the cache refreshes
before the commit completes, it reads stale data and re-caches the old value.
This has been observed in production logs approximately 2-3 times per week,
correlating with high-traffic periods.

**Evidence:** Production logs show cache-refresh events preceding commit-complete
events by 50-200ms during peak hours (source: Datadog dashboard "cache-timing",
last 30 days). Code path: `ProfileService.update()` → `EventBus.publish()` at
line 142, before `tx.commit()` at line 158.

**Implication:** Profile updates appear to "not stick" for some users until the
next natural cache expiry (5 minutes).
```

**Dehydrated:**
```markdown
### Finding 3: Cache Invalidation Race

**Confidence:** High

Profile update publishes cache-invalidation before DB tx commits → cache refresh reads stale data, re-caches old value. Observed 2-3x/week in prod, correlates w/ high traffic.

**Evidence:** Datadog "cache-timing" (30d): cache-refresh precedes commit-complete by 50-200ms at peak. Code: `ProfileService.update()` → `EventBus.publish()` :142, before `tx.commit()` :158.

**Implication:** Profile updates "don't stick" until cache expiry (5min).
```
