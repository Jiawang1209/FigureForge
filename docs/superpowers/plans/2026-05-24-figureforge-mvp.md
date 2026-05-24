# FigureForge MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create the first usable FigureForge repository skeleton: README, skill entrypoint, reference docs, case template, and lightweight validation scripts.

**Architecture:** FigureForge starts as a skillbase repository, not an app or plotting framework. The `skills/figureforge/` directory contains the AI skill, human-readable references, case folders, and R helper scripts. Cases remain independently understandable so real reproductions can be imported later without premature abstraction.

**Tech Stack:** Markdown, R scripts runnable with `Rscript`, POSIX shell checks, git.

---

## File Structure

- Create `README.md`: public-facing project overview, positioning, layout, setup, roadmap, and current status.
- Create `skills/figureforge/SKILL.md`: AI-agent workflow for selecting, adapting, rendering, and QA-checking scientific visualization cases.
- Create `skills/figureforge/references/gallery-index.md`: case index schema and initial empty MVP inventory notes.
- Create `skills/figureforge/references/data-mapping.md`: column mapping rules for adapting user data into case schemas.
- Create `skills/figureforge/references/ggplot-patterns.md`: reusable ggplot2 pattern notes without creating a rigid plotting API.
- Create `skills/figureforge/references/theme-and-export.md`: publication output and export guidance.
- Create `skills/figureforge/references/qa-checklist.md`: final verification checklist for adapted figures.
- Create `skills/figureforge/cases/_template/case.md`: canonical case metadata template.
- Create `skills/figureforge/cases/_template/data.csv`: tiny explicit template dataset for validation and example rendering.
- Create `skills/figureforge/cases/_template/plot.R`: minimal R plotting template that reads the template data and writes an output figure.
- Create `skills/figureforge/scripts/validate_case.R`: structural validator for required case files and metadata headings.
- Create `skills/figureforge/scripts/render_case.R`: wrapper that runs a case `plot.R` with input/output arguments.
- Create `skills/figureforge/scripts/index_cases.R`: scanner that extracts key metadata headings into a simple CSV index.

## Task 1: Create Documentation Skeleton

**Files:**
- Create: `README.md`
- Create: `skills/figureforge/SKILL.md`
- Create: `skills/figureforge/references/gallery-index.md`
- Create: `skills/figureforge/references/data-mapping.md`
- Create: `skills/figureforge/references/ggplot-patterns.md`
- Create: `skills/figureforge/references/theme-and-export.md`
- Create: `skills/figureforge/references/qa-checklist.md`

- [ ] **Step 1: Write failing structural check**

Run:

```bash
test -f README.md && \
test -f skills/figureforge/SKILL.md && \
test -f skills/figureforge/references/gallery-index.md && \
test -f skills/figureforge/references/data-mapping.md && \
test -f skills/figureforge/references/ggplot-patterns.md && \
test -f skills/figureforge/references/theme-and-export.md && \
test -f skills/figureforge/references/qa-checklist.md
```

Expected: FAIL because the files do not exist yet.

- [ ] **Step 2: Create documentation directories**

Run:

```bash
mkdir -p skills/figureforge/references
```

Expected: directory exists at `skills/figureforge/references`.

- [ ] **Step 3: Write `README.md`**

Create `README.md` with:

```markdown
# FigureForge

FigureForge is an AI-ready, reproducible case-based skillbase for publication-ready scientific visualization in R and Python. The first version focuses on R and ggplot2 cases built from real figure reproductions.

FigureForge is designed around a simple idea: from reproduction to adaptation. Each curated case should connect a visual example, reproducible plotting data, plotting code, adaptation notes, and QA rules so an AI agent or human contributor can reuse the workflow on new scientific data.

## Current Status

This repository is in the MVP skeleton stage. The project structure, skill workflow, references, and case template are being prepared before the first curated batch of real cases is imported.

The repository does not yet contain the full 100+ case library. Real cases should be added from the existing figure reproduction series after the workflow has been verified on a small representative set.

## MVP Scope

The first milestone focuses on:

- A FigureForge skill entrypoint for AI-assisted visualization adaptation.
- Reference documents for case selection, data mapping, ggplot2 patterns, export, and QA.
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
2. Document the chart type, data schema, visual encodings, ggplot2 components, adaptation notes, and pitfalls in `case.md`.
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
```

- [ ] **Step 4: Write `skills/figureforge/SKILL.md`**

Create `skills/figureforge/SKILL.md` with:

```markdown
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

1. Clarify the user's plotting goal, scientific data type, target output, and preferred ecosystem.
2. Search `references/gallery-index.md` and case metadata under `cases/` for matching chart types, data schemas, and visual encodings.
3. Open the selected case's `case.md`, `plot.R`, and data file before editing anything.
4. Create a data mapping table from the user's columns to the case schema.
5. Adapt the case-specific plotting script while preserving the useful visual structure.
6. Render the adapted figure.
7. Run the QA checklist in `references/qa-checklist.md`.
8. Report the selected case, mapping decisions, rendered outputs, verification performed, and remaining limits.

## References

- `references/gallery-index.md`: case navigation and metadata fields.
- `references/data-mapping.md`: column mapping and derived-variable rules.
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
```

- [ ] **Step 5: Write reference documents**

Create the five files with concise, useful content:

`skills/figureforge/references/gallery-index.md`

```markdown
# Gallery Index

This file is the curated navigation layer for FigureForge cases.

## Index Fields

| Field | Meaning |
| --- | --- |
| case_id | Stable folder prefix such as `001` |
| title | Human-readable case title |
| chart_type | Primary chart family |
| best_for | Scientific scenario where the case is useful |
| required_columns | Columns needed to adapt the case |
| optional_columns | Columns that improve the figure but are not required |
| visual_features | Labels, annotations, facets, color scales, layouts, or other notable features |
| ecosystem | R/ggplot2, Python, or both |
| status | template, draft, verified |

## MVP Inventory

No real curated cases have been imported yet.

Start the MVP with 12-20 representative R/ggplot2 cases covering bars, boxplots, violin plots, scatter plots with labels, trend lines, heatmaps, facets, multi-panel layouts, and complex annotations.
```

`skills/figureforge/references/data-mapping.md`

```markdown
# Data Mapping

Data mapping translates a user's dataset into the schema expected by a FigureForge case.

## Mapping Table

Before editing a plotting script, write a mapping table:

| Case role | User column | Required | Transformation |
| --- | --- | --- | --- |
| x |  | yes |  |
| y |  | yes |  |
| group |  | no |  |
| facet |  | no |  |
| label |  | no |  |
| value |  | no |  |

## Rules

- Required case roles must map to existing user columns or explicit derived columns.
- Derived columns must be created before plotting and described in the report.
- Aesthetic mappings such as color, shape, size, and alpha should preserve the case's visual intent.
- Factor order should be set deliberately when order affects interpretation.
- Missing values should be handled before rendering, not hidden silently by geoms.
```

`skills/figureforge/references/ggplot-patterns.md`

```markdown
# ggplot2 Patterns

These notes describe recurring ggplot2 building blocks used across FigureForge cases. They are guidance, not a mandatory plotting framework.

## Common Components

- `geom_col()` and `geom_bar()` for categorical comparisons.
- `geom_boxplot()` and `geom_violin()` for distributions.
- `geom_point()` with `geom_text()` or `ggrepel::geom_text_repel()` for labeled scatter plots.
- `geom_line()` and `geom_smooth()` for trajectories and trends.
- `geom_tile()` for heatmaps and matrix-like summaries.
- `facet_wrap()` and `facet_grid()` for small multiples.
- `patchwork` or `cowplot` for multi-panel composition.

## Adaptation Guidance

- Keep case-specific details visible in `plot.R`.
- Extract only small helpers when they reduce duplication inside one case.
- Prefer explicit scales and labels over relying on defaults.
- Check whether coordinate transforms, factor ordering, or annotations encode scientific meaning.
```

`skills/figureforge/references/theme-and-export.md`

```markdown
# Theme And Export

Publication-ready figures need predictable dimensions, typography, color, and file formats.

## Export Defaults

- Use vector formats such as PDF or SVG for line art and text-heavy figures.
- Use high-resolution PNG or TIFF for raster-heavy figures.
- Use at least 300 DPI for raster publication outputs unless a journal asks otherwise.
- Store exported files in a case-specific output folder or a clearly named target path.

## Theme Checks

- Axis labels and legends must be readable at final print size.
- Color palettes should remain interpretable when printed or viewed with common color-vision deficiencies.
- Panel spacing and margins should support the final layout, not only the local preview.
- Font choices should be reproducible on the target machine or embedded by the export workflow.
```

`skills/figureforge/references/qa-checklist.md`

```markdown
# QA Checklist

Run this checklist before calling a FigureForge adaptation complete.

## Data

- Required columns are present or explicitly derived.
- Units, group labels, and factor order are correct.
- Missing values and outliers were reviewed.

## Visual Fidelity

- The adapted figure preserves the selected case's useful visual structure.
- Scales, legends, annotations, and facets match the intended mapping.
- Text is legible at final output size.

## Reproducibility

- The rendering command is recorded.
- Input data path and output path are clear.
- Required R packages are named.

## Export

- Output dimensions and format match the target use.
- Vector or raster choice is appropriate.
- File names are descriptive and stable.

## Limits

- Any unverified visual comparison is stated.
- Any missing original or reproduction image is stated.
```

- [ ] **Step 6: Verify documentation skeleton passes**

Run:

```bash
test -f README.md && \
test -f skills/figureforge/SKILL.md && \
test -f skills/figureforge/references/gallery-index.md && \
test -f skills/figureforge/references/data-mapping.md && \
test -f skills/figureforge/references/ggplot-patterns.md && \
test -f skills/figureforge/references/theme-and-export.md && \
test -f skills/figureforge/references/qa-checklist.md
```

Expected: PASS with no output.

- [ ] **Step 7: Commit documentation skeleton**

Run:

```bash
git add README.md skills/figureforge/SKILL.md skills/figureforge/references
git commit -m "docs: add FigureForge skill documentation"
```

Expected: commit succeeds.

## Task 2: Add Case Template

**Files:**
- Create: `skills/figureforge/cases/_template/case.md`
- Create: `skills/figureforge/cases/_template/data.csv`
- Create: `skills/figureforge/cases/_template/plot.R`

- [ ] **Step 1: Write failing template check**

Run:

```bash
test -f skills/figureforge/cases/_template/case.md && \
test -f skills/figureforge/cases/_template/data.csv && \
test -f skills/figureforge/cases/_template/plot.R
```

Expected: FAIL because the template files do not exist yet.

- [ ] **Step 2: Create template directory**

Run:

```bash
mkdir -p skills/figureforge/cases/_template
```

Expected: directory exists.

- [ ] **Step 3: Write `case.md` template**

Create `skills/figureforge/cases/_template/case.md` with:

```markdown
# Case Template: Replace With Case Title

This folder is a template for future real FigureForge cases. It is not a curated reproduction case.

## Chart Type

scatter

## Best For

Use this section to describe the scientific data scenario where the case is useful.

## Data Schema

- x: numeric or ordered categorical position
- y: numeric response value
- group: optional grouping variable
- facet: optional small-multiple variable
- label: optional point or annotation label
- value: optional general measured value

## Visual Encoding

- color: optional group encoding
- size: optional magnitude encoding
- shape: optional category encoding
- line: optional trend or connection encoding
- annotation: optional labels or callouts

## ggplot Components

- geom_*: `geom_point()`
- scale_*: explicit x, y, and color scales when needed
- theme_*: publication-readable theme settings
- annotation_*: labels or callouts when needed
- layout/composition: single panel unless a real case requires facets or patchwork

## Adaptation Notes

Replace this template with notes explaining how user data should map into the case.

## Common Pitfalls

- Do not leave template language in real cases.
- Do not add `original.png` unless redistribution is allowed.
- Do not call a case verified until rendering and QA have been completed.
```

- [ ] **Step 4: Write `data.csv` template**

Create `skills/figureforge/cases/_template/data.csv` with:

```csv
x,y,group,label
1,2.1,A,Sample 1
2,2.8,A,Sample 2
3,3.4,B,Sample 3
4,3.9,B,Sample 4
```

- [ ] **Step 5: Write `plot.R` template**

Create `skills/figureforge/cases/_template/plot.R` with:

```r
#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
input_path <- if (length(args) >= 1) args[[1]] else "data.csv"
output_path <- if (length(args) >= 2) args[[2]] else "template-output.png"

if (!file.exists(input_path)) {
  stop("Input data file not found: ", input_path)
}

required_packages <- c("ggplot2")
missing_packages <- required_packages[!vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing_packages) > 0) {
  stop("Missing required R package(s): ", paste(missing_packages, collapse = ", "))
}

data <- read.csv(input_path, stringsAsFactors = FALSE)
required_columns <- c("x", "y", "group", "label")
missing_columns <- setdiff(required_columns, names(data))
if (length(missing_columns) > 0) {
  stop("Missing required column(s): ", paste(missing_columns, collapse = ", "))
}

plot <- ggplot2::ggplot(data, ggplot2::aes(x = x, y = y, color = group)) +
  ggplot2::geom_point(size = 2.8) +
  ggplot2::geom_line(ggplot2::aes(group = group), linewidth = 0.6) +
  ggplot2::labs(x = "Template x", y = "Template y", color = "Group") +
  ggplot2::theme_minimal(base_size = 11) +
  ggplot2::theme(panel.grid.minor = ggplot2::element_blank())

ggplot2::ggsave(output_path, plot = plot, width = 5, height = 3.5, dpi = 300)
message("Wrote figure: ", output_path)
```

- [ ] **Step 6: Verify template files exist**

Run:

```bash
test -f skills/figureforge/cases/_template/case.md && \
test -f skills/figureforge/cases/_template/data.csv && \
test -f skills/figureforge/cases/_template/plot.R
```

Expected: PASS with no output.

- [ ] **Step 7: Commit case template**

Run:

```bash
git add skills/figureforge/cases/_template
git commit -m "docs: add FigureForge case template"
```

Expected: commit succeeds.

## Task 3: Add R Helper Scripts

**Files:**
- Create: `skills/figureforge/scripts/validate_case.R`
- Create: `skills/figureforge/scripts/render_case.R`
- Create: `skills/figureforge/scripts/index_cases.R`

- [ ] **Step 1: Write failing script check**

Run:

```bash
test -f skills/figureforge/scripts/validate_case.R && \
test -f skills/figureforge/scripts/render_case.R && \
test -f skills/figureforge/scripts/index_cases.R
```

Expected: FAIL because scripts do not exist yet.

- [ ] **Step 2: Create scripts directory**

Run:

```bash
mkdir -p skills/figureforge/scripts
```

Expected: directory exists.

- [ ] **Step 3: Write `validate_case.R`**

Create `skills/figureforge/scripts/validate_case.R` with:

```r
#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
case_dir <- if (length(args) >= 1) args[[1]] else stop("Usage: validate_case.R <case_dir>")

required_files <- c("case.md", "data.csv", "plot.R")
missing_files <- required_files[!file.exists(file.path(case_dir, required_files))]

case_md <- file.path(case_dir, "case.md")
required_headings <- c(
  "## Chart Type",
  "## Best For",
  "## Data Schema",
  "## Visual Encoding",
  "## ggplot Components",
  "## Adaptation Notes",
  "## Common Pitfalls"
)

missing_headings <- character(0)
if (file.exists(case_md)) {
  case_text <- readLines(case_md, warn = FALSE)
  missing_headings <- required_headings[!vapply(required_headings, function(heading) any(trimws(case_text) == heading), logical(1))]
}

if (length(missing_files) > 0 || length(missing_headings) > 0) {
  if (length(missing_files) > 0) {
    message("Missing required file(s): ", paste(missing_files, collapse = ", "))
  }
  if (length(missing_headings) > 0) {
    message("Missing required heading(s): ", paste(missing_headings, collapse = ", "))
  }
  quit(status = 1)
}

message("Case structure OK: ", case_dir)
```

- [ ] **Step 4: Write `render_case.R`**

Create `skills/figureforge/scripts/render_case.R` with:

```r
#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 1) {
  stop("Usage: render_case.R <case_dir> [output_path]")
}

case_dir <- normalizePath(args[[1]], mustWork = TRUE)
plot_script <- file.path(case_dir, "plot.R")
input_path <- file.path(case_dir, "data.csv")
output_path <- if (length(args) >= 2) args[[2]] else file.path(case_dir, "output.png")

if (!file.exists(plot_script)) {
  stop("Missing plot script: ", plot_script)
}
if (!file.exists(input_path)) {
  stop("Missing data file: ", input_path)
}

command_args <- c(plot_script, input_path, output_path)
status <- system2("Rscript", command_args)
if (!identical(status, 0L)) {
  stop("Case rendering failed with status: ", status)
}

message("Rendered case output: ", output_path)
```

- [ ] **Step 5: Write `index_cases.R`**

Create `skills/figureforge/scripts/index_cases.R` with:

```r
#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
cases_dir <- if (length(args) >= 1) args[[1]] else "skills/figureforge/cases"
output_path <- if (length(args) >= 2) args[[2]] else "skills/figureforge/references/case-index.csv"

case_dirs <- list.dirs(cases_dir, recursive = FALSE, full.names = TRUE)
case_dirs <- case_dirs[basename(case_dirs) != "_template"]

extract_section <- function(lines, heading) {
  start <- which(trimws(lines) == heading)
  if (length(start) == 0) {
    return("")
  }
  start <- start[[1]] + 1
  end_candidates <- which(seq_along(lines) > start & grepl("^## ", lines))
  end <- if (length(end_candidates) == 0) length(lines) else end_candidates[[1]] - 1
  paste(trimws(lines[start:end]), collapse = " ")
}

rows <- lapply(case_dirs, function(case_dir) {
  case_md <- file.path(case_dir, "case.md")
  if (!file.exists(case_md)) {
    return(NULL)
  }
  lines <- readLines(case_md, warn = FALSE)
  data.frame(
    case_id = basename(case_dir),
    title = sub("^#\\s+", "", lines[[1]]),
    chart_type = extract_section(lines, "## Chart Type"),
    best_for = extract_section(lines, "## Best For"),
    stringsAsFactors = FALSE
  )
})

index <- do.call(rbind, rows[!vapply(rows, is.null, logical(1))])
if (is.null(index)) {
  index <- data.frame(case_id = character(0), title = character(0), chart_type = character(0), best_for = character(0))
}

dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
write.csv(index, output_path, row.names = FALSE)
message("Wrote case index: ", output_path)
```

- [ ] **Step 6: Verify scripts exist**

Run:

```bash
test -f skills/figureforge/scripts/validate_case.R && \
test -f skills/figureforge/scripts/render_case.R && \
test -f skills/figureforge/scripts/index_cases.R
```

Expected: PASS with no output.

- [ ] **Step 7: Commit scripts**

Run:

```bash
git add skills/figureforge/scripts
git commit -m "feat: add FigureForge case helper scripts"
```

Expected: commit succeeds.

## Task 4: Verify MVP Skeleton

**Files:**
- Modify only if verification finds concrete issues in files created by Tasks 1-3.

- [ ] **Step 1: Run placeholder scan**

Run:

```bash
rg -n "T[B]D|T[O]DO|F[I]XME|\\?\\?" README.md skills/figureforge docs/superpowers
```

Expected: exit status 1 with no matches.

- [ ] **Step 2: Run structural file check**

Run:

```bash
test -f README.md && \
test -f PROJECT_HANDOFF.md && \
test -f skills/figureforge/SKILL.md && \
test -f skills/figureforge/references/gallery-index.md && \
test -f skills/figureforge/references/data-mapping.md && \
test -f skills/figureforge/references/ggplot-patterns.md && \
test -f skills/figureforge/references/theme-and-export.md && \
test -f skills/figureforge/references/qa-checklist.md && \
test -f skills/figureforge/cases/_template/case.md && \
test -f skills/figureforge/cases/_template/data.csv && \
test -f skills/figureforge/cases/_template/plot.R && \
test -f skills/figureforge/scripts/validate_case.R && \
test -f skills/figureforge/scripts/render_case.R && \
test -f skills/figureforge/scripts/index_cases.R
```

Expected: PASS with no output.

- [ ] **Step 3: Run case validation if R is available**

Run:

```bash
if command -v Rscript >/dev/null 2>&1; then
  Rscript skills/figureforge/scripts/validate_case.R skills/figureforge/cases/_template
else
  echo "Rscript not available; skipped R validation"
fi
```

Expected if R is available: `Case structure OK: skills/figureforge/cases/_template`.

Expected if R is unavailable: `Rscript not available; skipped R validation`.

- [ ] **Step 4: Run case index generation if R is available**

Run:

```bash
if command -v Rscript >/dev/null 2>&1; then
  Rscript skills/figureforge/scripts/index_cases.R skills/figureforge/cases /tmp/figureforge-case-index.csv
else
  echo "Rscript not available; skipped case indexing"
fi
```

Expected if R is available: `Wrote case index: /tmp/figureforge-case-index.csv`.

Expected if R is unavailable: `Rscript not available; skipped case indexing`.

- [ ] **Step 5: Run template render if R and ggplot2 are available**

Run:

```bash
if command -v Rscript >/dev/null 2>&1; then
  Rscript skills/figureforge/scripts/render_case.R skills/figureforge/cases/_template /tmp/figureforge-template-output.png
else
  echo "Rscript not available; skipped template render"
fi
```

Expected if R and ggplot2 are available: output includes `Rendered case output: /tmp/figureforge-template-output.png`.

Expected if R is unavailable: `Rscript not available; skipped template render`.

Expected if ggplot2 is unavailable: fail with `Missing required R package(s): ggplot2`; report this as a dependency gap, not a repository failure.

- [ ] **Step 6: Check git status**

Run:

```bash
git status --short
```

Expected: no uncommitted files except the plan itself if it has not been committed yet.

- [ ] **Step 7: Commit implementation plan if not already committed**

Run:

```bash
git add docs/superpowers/plans/2026-05-24-figureforge-mvp.md
git commit -m "docs: add FigureForge MVP implementation plan"
```

Expected: commit succeeds.
