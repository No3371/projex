# Projex

"Projex" is a workflow framework to organize objectives any type of tasks of any sizes, all by file/folder management in filesystem.

Implementing Projex revolves around authoring/maintenance/executing self-contained unit markdown documents in folders named "projex". There are several types of unit documents: 

- Proposal
    - Exploratory documentation for new ideas, changes, decisions
    - Captures reasoning, trade-offs, potential changes or approaches and impact analysis
    - Focuses on "what if" exploration vs "do this" instructions
    - Progresses from Draft → Review → Accepted/Rejected
    - WORKFLOW SPECIFICATION -> @./propose-projex.md 
- Plan
    - Actionable task documents capturing a specifc problem/gap/need, with clear objectives backed by rich context and rationale
    - WHAT needs to be done, and HOW to implement it, exact what changes to what files
    - Easy to parse, understood, followed and executed by any LLM or human
    - Granular split and derivation with clear scopes and boundaries
    - Closed ended with clear acceptance/success criteria or actionable outcomes
    - WORKFLOW SPECIFICATION -> @./plan-projex.md
    - EXECUTION WORKFLOW -> @./execute-projex.md
- Evaluation
    - Systematic analysis and scrutinzation of status quo vs new ideas, changes or proposals
    - Research the essense, paradigm, value and scope before and after the idea
    - Explore the principles or theories of the idea, and assumptions or previous work it's built upon
    - Evaluate what and why does the idea address, why prior appoaches did not the problem, and how/why the idea will address it now, and the potential challenges
    - Adapt depth and focus based on context. Emphasize rigor, clarity, and intellectual honesty
    - WORKFLOW SPECIFICATION -> @./eval-projex.md 
- Review
    - Inspection report against prior made projex documents, ensuring they are up-to-date, comaptible with status quo, still valid, complete, accurate and valuable
    - As projex unit documents can be created, read, or executed in any order and any time, they can become outdated or invalid over time or after new changes. Review projex answers these important questions:
        - When was the projex authored? What happened after that? What is the status quo?
        - Does the idea or the plan still stands? Is it still compliant to latest spec or design?
        - Should we expand the projex, for status quo now has additions that should be covered by the projex? Or should we modify the projex, for it's no longer correct, complete or accurate?
    - Examine the projex from high level, bigger picture without being misled by the original content/entities/subjects, explore status quo and ask open quesiton
    - Challenge the idea. Challenge the projex. Ask extra challenge questions against the projex in question.
    - WORKFLOW SPECIFICATION -> @./review-projex.md 
- Walkthrough
    - Followup projex authored after EVERY Plan execution
    - Complete list of whatever happened for each objectives of the Plan projex, each with extremely details down to file changes and line numbers
    - Acceptance/Success criteria checklist and proof of verification measure taken
    - Additional key insights for future references, such as lessions learned, pattern discoveries, gotchas/pitfalls encounters
    - WORKFLOW SPECIFICATION -> @./close-projex.md 

## Authoring

Projex documents should be named in this format: `{yyyymmdd}-{projex-name}-{projex-type}.md`

While each type of projex have different characteristics therefore need to be formatted differently, some common patterns are applied to most, if not all types:
- Projexs often relates to other ones. A project may be directly or indirectly related to existing projects, or derive or split into multiple projects. These relationships must be added/maintained in all involve projex documents.
- Once a projex is authored, it should be refined once to put the general important info (that helps quick assessment at a glance) to the beginning of the file.

## Organizing

Projex files are always nested inside folders named "projex", but actual file location depends on projex states.

A pending projex usually just resides in the parent "projex" folder, regardless the type; Closed projex and the walkthrough should be placed in "projex/closed" folder; If a projex is archived (unlikely to continue), it should be in "projex/archived". Abandoned projexs usually just get deleted by the user, but would be in "projex/abandoned" if any.

Furthermore, a repo/project may have multiple "projex" folders in different path, each dedicated to individual module/component/domain/areas, etc. For example, a language design project, may have separate path to store language spec, implementation spec (general description and pseudo code for any implementing language, derived from langauge spec), poc runtime implementation (derived from and constantly reflects impl specs); These should be decoupled and their Projex files should be individually managed. New Projex files should not cover more than 1 area or violate dependencies.

**Examples**
```
your-repo/
├── projex/           # Master projexs
│   ├── closed/
│   │   └── closed_project.md
│   ├── project.md
│   └── ...
├── docs/              # Specifications and documentation
│   ├── projex/ # doc projexs
│   │   ├── abandoned/
│   │   │   └── ... 
│   │   ├── project.md
│   │   └── ... 
│   └── ...
├── src/               # Source code
│   └── projex/ # src projexs
│       ├── project.md
│       └── ... 
└── projex-framework.md

```

## Workflow

Workflow spec files are the "actions", containing clear instruction to work with projex files. They are referenced in verb sense.

Workflow usages/invocations examples:
- `/propose-projex.md I want to add XXX feature.`
- `/eval-projex.md Does current spec compatible with this proposal?` or `/eval-projex.md What can be improved in the current implementation?`
- `/plan-projex.md Update current impl to keep up with latest specs.` or `/plan-projex.md @20260731-database-service-refactor-proposal.md`
- `/review-projex.md @20260731-language-macro-syntax-change-proposal.md` or `/review-projex.md the project we just made`
- `/execute-projex.md @20260731-language-macro-syntax-change-plan.md`
- `/close-projex.md` after the user reviewed the result of execute-project. 

## NOTES

### AVOID ABSOLUTE PATHS
USE file paths RELATIVE to project root to reference files in the repo. REDACT paths to files external to the repo.

