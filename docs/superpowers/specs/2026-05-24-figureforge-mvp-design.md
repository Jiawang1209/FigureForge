# FigureForge MVP Design

Date: 2026-05-24

## Goal

Build the first usable repository shape for FigureForge as an AI-ready, bilingual-friendly, case-based scientific visualization skillbase.

The MVP should make the project understandable to a human contributor and usable by an AI coding agent before the full 100+ case library is cleaned. It should support the first curated batch of 12-20 R/ggplot2 cases without forcing all plotting code into an over-generalized framework.

## Scope

This first implementation should create:

- A project README that explains the positioning, repository layout, development workflow, and current status.
- A `skills/figureforge/SKILL.md` entrypoint that tells an AI agent how to select, inspect, adapt, render, and QA a figure case.
- A small `skills/figureforge/references/` knowledge base for gallery indexing, data mapping, ggplot patterns, theme/export guidance, and QA.
- Chinese-compatible keywords, aliases, and field-mapping guidance so Chinese users can search by terms such as `柱状图`, `箱线图`, `小提琴图`, `散点图`, `热图`, `分面图`, and `多面板`.
- A case folder convention under `skills/figureforge/cases/`, including a template or placeholder that does not pretend to be a real reproduction.
- Lightweight scripts or script stubs only where they clarify the workflow for future indexing, rendering, and validation.

This pass should not import or invent real publication cases. Real cases should be added later from the user's existing figure reproduction series.

## Non-Goals

- Do not build a generic plotting framework that hides case-specific code.
- Do not claim that a full case atlas already exists.
- Do not bind the project permanently to R only, even though the MVP focuses on R/ggplot2.
- Do not add synthetic example figures as if they were part of the curated corpus.
- Do not add a web application unless a later design explicitly chooses that direction.

## Repository Shape

The repository should start with this structure:

```text
FigureForge/
├── README.md
├── PROJECT_HANDOFF.md
├── docs/
│   └── superpowers/
│       └── specs/
│           └── 2026-05-24-figureforge-mvp-design.md
└── skills/
    └── figureforge/
        ├── SKILL.md
        ├── references/
        │   ├── gallery-index.md
        │   ├── data-mapping.md
        │   ├── ggplot-patterns.md
        │   ├── theme-and-export.md
        │   └── qa-checklist.md
        ├── cases/
        │   └── _template/
        │       ├── case.md
        │       ├── data.csv
        │       └── plot.R
        └── scripts/
            ├── index_cases.R
            ├── render_case.R
            └── validate_case.R
```

The `_template` case folder is intentionally a template. It should contain clear placeholder language and should not include `original.png` or `reproduction.png` until a real case is added.

## Skill Workflow

The `SKILL.md` should guide an agent through this sequence:

1. Understand the user's plotting goal, target journal or style constraints, data shape, preferred ecosystem, and working language.
2. Search `references/gallery-index.md` and available case metadata for matching chart types, Chinese/English aliases, keywords, and data schemas.
3. Open the chosen case's `case.md`, `plot.R`, and data file.
4. Map the user's data columns to the case schema before editing code.
5. Adapt the case-specific R/ggplot2 script while preserving the visual structure that made the case useful.
6. Render the figure and export publication-ready outputs.
7. Run the QA checklist for data mapping, visual fidelity, accessibility, reproducibility, and export quality.
8. Report what was adapted, what was verified, and any remaining limits.

The skill should prefer real case details over generic style prompts. If no case matches well, it should say so and either choose the closest case with caveats or propose adding a new case.

## Reference Documents

`gallery-index.md` should be the human-curated navigation layer. For now it can include the intended metadata columns, Chinese/English chart-type aliases, searchable keywords, and a short placeholder section for the MVP case set.

`data-mapping.md` should explain how to translate user data into a case schema, including required, optional, derived, and aesthetic columns. It should explicitly handle Chinese column names and Chinese scientific labels without forcing users to rename their source data prematurely.

`ggplot-patterns.md` should describe recurring ggplot2 building blocks that appear across cases without turning them into a rigid API.

`theme-and-export.md` should define publication-ready output expectations: dimensions, DPI, vector/raster choices, font handling, color, and file naming.

`qa-checklist.md` should provide the verification checklist an agent runs after adapting a case.

## Scripts

The initial R scripts should be lightweight and honest:

- `index_cases.R` should scan case metadata later, but can initially document the expected metadata path and output format.
- `render_case.R` should define the intended command shape for rendering a case.
- `validate_case.R` should define basic checks for required files and metadata sections.

If the scripts are implemented in this pass, they should work on the `_template` folder without pretending that template data is a real case. If implementation would add too much ceremony, script stubs with clear usage comments are acceptable for the first checkpoint.

## Error Handling

The workflow should make uncertainty visible:

- Missing real cases should be reported as "not yet populated", not treated as a failure.
- Missing required case files should fail validation with specific file names.
- Missing data columns during adaptation should be caught before rendering.
- Rendering failures should preserve the R error and point back to the case script.
- Export checks should distinguish structural verification from visual fidelity verification.

## Testing And Verification

For the repository skeleton:

- Verify that the expected files exist.
- Verify that Markdown files have no obvious placeholders outside intentional template sections.
- If R is available, run the validation script against the template case.
- Use `git status --short` to confirm the changed files before committing or handing off.

For later real cases:

- Render the adapted figure.
- Compare the result against the reproduction image when available.
- Confirm the exported file dimensions, format, and naming.
- Review the QA checklist before calling the figure publication-ready.

## Implementation Order

1. Create the repository skeleton and documentation files.
2. Write the FigureForge skill entrypoint.
3. Write the reference documents.
4. Add the case template folder.
5. Add lightweight script stubs or minimal working validation.
6. Run structural verification.
7. Commit the design and then proceed to an implementation plan after user review.

## Open Decisions For Later

- Which 12-20 real cases form the first curated MVP batch.
- Whether case metadata should remain Markdown-only or also be indexed as CSV/JSON/YAML.
- Whether Python support starts as references only or as parallel executable cases.
- Whether FigureForge later gains a gallery website or remains primarily a skillbase repository.
