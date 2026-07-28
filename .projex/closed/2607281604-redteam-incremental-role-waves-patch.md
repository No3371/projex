# Patch: Redteam Incremental Role Waves

> **Date:** 2026-07-28
> **Author:** agent
> **Directive:** "redteam-projex: I want the agent to incrementally spawn roles for 3 times instead of spawn all roles in one pass"
> **Source Plan:** Direct
> **Result:** Success

---

## Summary

`redteam-projex.md` step 1 required enumerating ALL stakeholder roles up front, then attacking each. Replaced with three sequential waves: each wave attacks its own roles, and the next wave's roles are derived from the findings the previous wave produced. Wave 3 is terminal.

---

## Changes

### `redteam-projex.md`

**Change Type:** Modified

**What Changed:**

- Step 1 retitled `IDENTIFY STAKEHOLDER ROLES` → `SPAWN STAKEHOLDER ROLES — THREE WAVES` (line 37). Replaced "List ALL roles involved" with the three-wave protocol:
  - **Wave 1 — Direct:** roles the subject names/serves outright (~2–4)
  - **Wave 2 — Implicated:** roles appearing inside wave 1 findings — failure-path participants, blast-radius absorbers, unnamed dependencies
  - **Wave 3 — Adversarial & accountable:** who profits from the findings, who answers for them
- Per-wave loop stated explicitly: spawn → steps 2–4 for those roles only → record findings → re-read → derive next wave. Waves sequential; no pre-spawning ahead of an open wave.
- Wave 3 declared terminal — later roles go to `## Roles Not Attacked`, no fourth wave.
- Empty-wave rule: declare it, don't pad with generic roles; nothing derivable ⇒ wave 1 was shallow, return to it.
- `Common roles to consider` → `Role pool`, placed by evidence rather than by listed order (line 53).
- Adversarial-roles callout marked wave-3 by construction (line 65) — they weaponize *known* weaknesses, so spawning them first wastes the wave.
- Steps 2 and 3 scoped to "the current wave" (lines 75, 88); earlier waves not re-attacked.
- Step 4 gains a post-wave-3 cross-wave pass — cascades spanning waves (wave-1 failure reached by a wave-3 attacker through a wave-2 role) are invisible until all waves exist.
- Step 5: report scaffolded at start of wave 1, appended per wave. Derivation reads from the document, not memory — an unrecorded wave cannot spawn its successor.
- Template: `Wave` column added to Stakeholder Roles; new `### Wave Derivation` (finding → role, per hop) and `## Roles Not Attacked` sections.
- Step 6 validation: 6 wave checks added (three waves run, derivation traceable, ordering respected, empty wave declared, cross-wave pass run, post-wave-3 roles logged).
- Principles: `Waves, not a census`.

**Why:**

One-pass enumeration produces the roles the agent can name before looking — the generic list. Roles that carry real findings are implied by earlier findings, so they cannot be enumerated in advance. Fixing the count at three bounds the cost: without a cap, derivation recurses indefinitely; with one pass, it never starts.

---

## Verification

**Method:** Read-back of edited regions; internal consistency check across steps 1–6 and template (wave references, section names, numbering).

**Result:**

```
Step 1 waves table + per-wave loop + terminal rule ✓
Steps 2/3 scoped to current wave ✓
Step 4 cross-wave pass ✓
Step 5 scaffold-at-wave-1 ✓
Template: Wave column, Wave Derivation, Roles Not Attacked ✓ (names match step 1 references)
Step 6: 6 wave checks ✓
No spec other than redteam-projex.md references role enumeration
```

**Status:** PASS

---

## Impact on Related Projex

| Document | Relationship | Update Made |
|----------|-------------|-------------|
| — | No projex references redteam's role-enumeration step | None needed |

---

## Notes

- Three waves is a hard cap, not a target — the workflow forbids a fourth rather than encouraging one.
- Wave count is fixed; wave *size* is not. Wave 1 at 2–4 roles is guidance, not a gate.
- Untested against a real subject. First live redteam run is the real check on whether wave-2 derivation produces non-generic roles.
