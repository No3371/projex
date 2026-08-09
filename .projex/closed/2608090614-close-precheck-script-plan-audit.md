# Audit: close-precheck Script

> **Status:** Complete (Superseded by resumed audit)
> **Audit Date:** 2026-08-09
> **Auditor:** depth-1 audit delegate
> **Subject:** 2608081953-close-precheck-script-plan.md
> **Related:** 2608090541-close-precheck-script-plan-log.md | 2607291729-close-projex-modernization-proposal.md
> **Audited Tip:** 5229d5a
> **Base:** main
> **Close Disposition:** Superseded by 2608090754-close-precheck-script-resume-audit.md. Runner registration and Bash coverage were subsequently corrected; PowerShell evidence remains deferred in the partial-success walkthrough.

## Summary

**Claim:** Add report-only `close-precheck.{sh,ps1}`, independent behavioral suites, runner registration, and documentation without changing close/finalizer behavior.

**Verdict:** Partial. Initial Bash evidence was positive, but PowerShell parity was unrun, the PowerShell runner omitted its suite, the full Bash runner required a temporary executable-mode workaround, and the required safety matrix was incomplete.

## Claims vs Evidence

| Claim | Evidence at audit | Result |
| --- | --- | --- |
| Bash implementation and suite | `close-precheck.sh`; direct suite `PASS=38 FAIL=0`; `bash -n` passed | Verified |
| Full Bash aggregation | `PASS=293 FAIL=0` only after temporary `+x`; clean modes produced status-126 failures | Conditional |
| PowerShell parity | Script and suite present; `pwsh` unavailable | Not run |
| PowerShell runner registration | `tests/run-all.ps1` omitted `close-precheck.test.ps1` while requiring its execution count | Failed |
| Scope/no mutation | Diff stayed within A1; no finalizer/workflow implementation changed | Verified |

## Findings

- Register `close-precheck.test.ps1` exactly once in `tests/run-all.ps1`; run parser, direct suite, and aggregate on a supported host.
- Complete fixtures for drift, symlink/path containment, invalid refs, encoding/control values, stashes, `NONE`, scale/output budget, and fail-closed runner behavior.
- Resolve or explicitly automate the legacy executable-mode prerequisite before treating the full Bash runner as reproducible.

## Resolution Record

`bdde857` registered the PowerShell suite. `5e1cd72` and `ffe3868` expanded the Bash and PowerShell matrix source; `50fb939` discarded unrelated formatting drift. The resumed audit records `PASS=62 FAIL=0` for Bash and accepts the remaining PowerShell condition as deferred; see 2608090754-close-precheck-script-resume-audit.md and 2608090821-close-precheck-script-plan-walkthrough.md.

## Final Verdict

**Status:** Complete (Superseded by resumed audit)

Initial sign-off was withheld. This audit remains a historical record; its live dispositions are superseded by the resumed audit and partial-success close.
