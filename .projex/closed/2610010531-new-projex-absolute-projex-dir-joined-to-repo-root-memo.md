# Memo: new-projex joins an absolute --projex-dir onto the repo root

> **Status:** Complete (Resolved)
> **Author:** Opus 5.5 (orchestrator)
> **Parent:** 2610010520-projex-tree-native-port-plan-stress.md
> **Source Type:** Issue
> **Origin:** Noticed by the stress subagent while scaffolding 2610010520-projex-tree-native-port-plan-stress.md (orchestrate-projex chain `plan<<opus>>, stress, [revise]`)
> **Related Projex:** 2610010520-projex-tree-native-port-plan-stress.md | 2610010506-projex-tree-native-port-plan.md | 2610020012-new-projex-reject-absolute-projex-dir-patch.md

---

## Source

Stress subagent report, verbatim: "`new-projex.sh` joins an absolute `--projex-dir` onto the repo root instead of using it as-is. My first scaffold landed at `<repo>/s/Repos/projex/.projex/…`; I deleted it and re-ran with `.projex`, and the repo is back to how it was."

Orchestrator summary to user: "`new-projex.sh` mishandles an absolute `--projex-dir`. It appends the path to the repo root instead of using it as given."

---

## Context

- Symptom: `--projex-dir` given as an absolute path (Git Bash form, e.g. `/s/Repos/projex/.projex`) → scaffold written under `<repo-root>/s/Repos/projex/.projex/` rather than at that path. Workaround: pass a repo-relative dir (`.projex`).
- Observed in `new-projex.sh` only; `new-projex.ps1` behaviour with `-ProjexDir <absolute>` not checked. Whether an absolute path outside `<repo-root>` should be rejected, accepted, or resolved is undecided.
- Stray directory was removed by the stress subagent; orchestrator confirmed `s/` no longer exists at repo root.
- Every workflow spec scaffolds via `new-projex --projex-dir <projex-folder>`; agents resolving `<projex-folder>` to an absolute path hit this silently — the script prints the wrong path but reports success.
- Out of scope for 2610010506-projex-tree-native-port-plan.md. Existing suite `tests/new-projex.test.{sh,ps1}` covers the named-parameter matrix; unknown whether it has an absolute-dir case.
- Not investigated further (memo — no research).

---

## Resolution

Resolved by 2610020012-new-projex-reject-absolute-projex-dir-patch.md — both scaffolds reject an absolute projex dir (POSIX, backslash-root, UNC, drive forms) with exit 2 before any write.
