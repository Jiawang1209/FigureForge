# FigureForge

FigureForge is an AI-ready, reproducible case-based skillbase for publication-ready scientific visualization in R and Python. The first version focuses on R and ggplot2 cases built from real figure reproductions.

FigureForge is designed around a simple idea: from reproduction to adaptation. Each curated case should connect a visual example, reproducible plotting data, plotting code, adaptation notes, and QA rules so an AI agent or human contributor can reuse the workflow on new scientific data.

FigureForge should support both English and Chinese users. Case metadata and search keywords should include Chinese chart names and aliases such as `柱状图`, `箱线图`, `小提琴图`, `散点图`, `折线图`, `热图`, `分面图`, and `多面板`.

## Current Status

This repository is in the MVP skeleton stage. The project structure, skill workflow, references, and case template are being prepared before the first curated batch of real cases is imported.

The repository does not yet contain the full 100+ case library. Real cases should be added from the existing figure reproduction series after the workflow has been verified on a small representative set.

## MVP Scope

The first milestone focuses on:

- A FigureForge skill entrypoint for AI-assisted visualization adaptation.
- Reference documents for case selection, data mapping, ggplot2 patterns, export, and QA.
- Chinese and English keywords for chart-type discovery.
- A case folder template for future real reproductions.
- Lightweight R scripts for case validation, rendering, and indexing.
- A roadmap toward a 12-20 case R/ggplot2 MVP.

## Repository Layout

```text
FigureForge/
├── README.md
├── PROJECT_HANDOFF.md
├── docs/
│   └── superpowers/
│       ├── specs/
│       └── plans/
└── skills/
    └── figureforge/
        ├── SKILL.md
        ├── references/
        ├── cases/
        └── scripts/
```

## Case Layout

Real cases should use this shape:

```text
skills/figureforge/cases/001-case-name/
├── original.png
├── reproduction.png
├── data.csv
├── plot.R
└── case.md
```

The `_template` case is a format guide, not a curated figure reproduction.

## Development Workflow

1. Add or select a real figure reproduction case.
2. Document the chart type, data schema, visual encodings, ggplot2 components, adaptation notes, pitfalls, and Chinese/English aliases in `case.md`.
3. Keep the plotting script case-specific and reproducible.
4. Render the case with `skills/figureforge/scripts/render_case.R`.
5. Validate the case structure with `skills/figureforge/scripts/validate_case.R`.
6. Update the gallery index with `skills/figureforge/scripts/index_cases.R`.
7. Run the QA checklist before calling an adapted figure publication-ready.

## Roadmap

- Import 12-20 representative R/ggplot2 cases.
- Verify that an AI agent can select and adapt one case to a new dataset.
- Expand the curated gallery after the adaptation workflow proves useful.
- Add Python examples after the R-first workflow stabilizes.
- Explore a paper, data descriptor, or software/resource publication.

## License

License information has not been selected yet. Add a license before public reuse or publication.
