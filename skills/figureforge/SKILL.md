---
name: figureforge
description: Use when adapting, reproducing, or designing publication-ready scientific figures from FigureForge case examples, especially R/ggplot2 workflows.
---

# FigureForge

FigureForge is a case-based scientific visualization skillbase. Use it to adapt real reproducible figure cases to new scientific datasets.

## Core Rule

Prefer concrete case evidence over generic style prompts. Start from the closest available case, inspect its metadata and code, map the user's data to the case schema, then adapt the plotting script.

If no case matches well, say so. Recommend the closest case only with clear caveats, or propose creating a new case.

## Workflow

1. Clarify the user's plotting goal, scientific data type, target output, preferred ecosystem, and working language.
2. Search `references/gallery-index.md` and case metadata under `cases/` for matching chart types, Chinese/English aliases, keywords, data schemas, and visual encodings.
3. Open the selected case's `case.md`, `plot.R`, and data file before editing anything.
4. Create a data mapping table from the user's columns to the case schema.
5. Adapt the case-specific plotting script while preserving the useful visual structure.
6. Render the adapted figure.
7. Run the QA checklist in `references/qa-checklist.md`.
8. Report the selected case, mapping decisions, rendered outputs, verification performed, and remaining limits.

## References

- `references/gallery-index.md`: case navigation, metadata fields, Chinese/English aliases, and keywords.
- `references/data-mapping.md`: column mapping, Chinese field-name handling, and derived-variable rules.
- `references/ggplot-patterns.md`: recurring ggplot2 components.
- `references/theme-and-export.md`: publication export expectations.
- `references/qa-checklist.md`: final verification checklist.

## Case Expectations

Each real case should contain:

- `case.md`
- `data.csv` or another documented data file
- `plot.R`
- `original.png` when redistribution is allowed
- `reproduction.png` when available

Do not treat `_template` as a real curated case.

## Output Standard

An adapted figure is not complete until the data mapping, rendering command, exported files, and QA limits are stated clearly.
