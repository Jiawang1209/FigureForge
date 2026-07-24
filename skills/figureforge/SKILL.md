---
name: figureforge
description: Use when selecting, reproducing, adapting, or QA-checking publication-ready scientific figures from FigureForge R/ggplot2 cases, including Chinese or English chart requests and new-data column mapping.
---

# FigureForge

FigureForge turns verified scientific-figure reproductions into evidence-based
new-data adaptations. Select the closest real case, inspect its actual
metadata, code, and data, map the user's fields explicitly, migrate the
case-specific script, render, and record QA.

## Non-Negotiable Rules

- Prefer a verified real case over a generic plotting scaffold.
- Read `case.md`, `data.csv`, `plot.R`, and `qa.md` before adapting a case.
- Never infer completion from file presence or a successful render alone.
- Work outside the source case directory; do not overwrite private inputs,
  original figures, reproductions, or source scripts.
- Treat a case as `private_only` unless `distribution.yml` explicitly allows
  redistribution of named assets.
- Use `/usr/local/bin/Rscript` for all R workflows in this repository.
- If no case matches the scientific intent and schema closely enough, state
  the mismatch and either select the nearest case with caveats or author a new
  real case.

## Required Inputs

Establish these before selecting a case:

1. scientific question and comparison being shown;
2. input file and actual column names;
3. desired chart family or reference appearance;
4. required labels, statistics, annotations, panels, and factor order;
5. target format, dimensions, language, and publication context.

Inspect the user's data directly. Record units, missing values, category
levels, duplicate keys, and derived fields. Do not ask the user to rename
Chinese columns merely to fit a case.

## End-to-End Workflow

### 1. Find candidate cases

Search English and Chinese metadata, schema roles, aliases, and dependencies:

```bash
/usr/local/bin/Rscript skills/figureforge/scripts/search_cases.R \
  --cases-dir skills/figureforge/cases \
  --query "<chart, science, or schema terms>" \
  --completed-only \
  --limit 5
```

If no completed case matches, repeat without `--completed-only`, but do not
present a scaffolded or structurally incomplete case as verified.

Rank candidates by:

1. scientific comparison and visual encoding;
2. data shape and required fields;
3. annotation, statistics, and layout;
4. fresh reproducibility and QA evidence;
5. dependency availability;
6. distribution boundary.

### 2. Inspect the selected case

Read the selected `case.md`, `data.csv`, `plot.R`, `qa.md`, and any authentic
source files needed to understand transformations. Compare the reference and
reproduction visually when available.

Check dependencies before migration:

```bash
/usr/local/bin/Rscript skills/figureforge/scripts/check_dependencies.R \
  --case-dir "<case_dir>" \
  --strict
```

Do not silently replace a missing package. If a compatible native
implementation is used, document the visible differences and verify them.

### 3. Create an isolated adaptation workspace

Create a new directory outside `skills/figureforge/cases/`. It must contain:

```text
input.csv
plot.R
mapping.md
qa.md
output.pdf or output.png
```

Use `references/adaptation-contract.md` for exact file and heading contracts.
Copy only code that may be used locally; never redistribute private case data,
reference images, or reproductions.

### 4. Map fields before changing code

Write `mapping.md` before editing the plotting logic. For every case role,
record the input column, whether it is required, units, factor order, and any
transformation. Derived variables must have explicit formulas and assumptions.

Use `references/data-mapping.md`. Reject the mapping if required roles are
missing, keys are ambiguous, or a statistical transformation cannot be
justified.

### 5. Migrate the real plotting script

Start from the selected case's actual `plot.R`, retaining the useful visual
grammar rather than rebuilding a generic chart. Adapt:

- schema validation and field aliases;
- factor order and grouping;
- summaries, confidence intervals, or tests;
- scales, palettes, labels, and annotations;
- facet or multi-panel geometry;
- dimensions and export format.

The adapted script must accept the standard contract:

```r
args <- commandArgs(trailingOnly = TRUE)
input_path <- args[[1]]
output_path <- args[[2]]
```

It must fail clearly for missing files, columns, invalid values, or missing
packages. Set deterministic seeds whenever layout or label placement is
stochastic.

### 6. Render and validate

Render with explicit paths:

```bash
/usr/local/bin/Rscript "<adaptation_dir>/plot.R" \
  "<adaptation_dir>/input.csv" \
  "<adaptation_dir>/output.pdf"
```

Then perform a fresh machine-verifiable render:

```bash
/usr/local/bin/Rscript skills/figureforge/scripts/validate_adaptation.R \
  "<adaptation_dir>" \
  --render \
  --output "<separate_validation_output>" \
  --rscript /usr/local/bin/Rscript
```

### 7. Perform visual QA

Use `references/qa-checklist.md`. Verify:

- data coverage, units, missingness, derived values, and factor order;
- scientific meaning of every aesthetic and annotation;
- fidelity to the selected case's useful structure;
- legibility, clipping, overlaps, scales, legends, and panel alignment;
- output format, dimensions, and resolution;
- every remaining limitation.

Only a human or explicitly authorized visual review may set
`Status: verified`.

### 8. Report the result

Return:

- selected case and why it matched;
- field-mapping decisions and transformations;
- exact render and validation commands;
- output paths;
- dependency and QA results;
- distribution status and unresolved limits.

## Developing a Real Case

Use `cases/_template/` only as a format guide. A completed case needs authentic
data provenance, normalized `data.csv`, a case-specific standard-argument
`plot.R`, reproduction evidence, and a verified `qa.md`.

Validate structure during authoring:

```bash
/usr/local/bin/Rscript skills/figureforge/scripts/validate_case.R "<case_dir>"
```

Validate completion and render outside the source case:

```bash
/usr/local/bin/Rscript skills/figureforge/scripts/validate_case.R \
  "<case_dir>" \
  --complete \
  --render \
  --output "<external_output>" \
  --rscript /usr/local/bin/Rscript
```

The compact form is
`validate_case.R <case_dir> --complete --render --output <external_output>`.

Rebuild the ignored local index after metadata changes:

```bash
/usr/local/bin/Rscript skills/figureforge/scripts/index_cases.R \
  skills/figureforge/cases \
  skills/figureforge/references/case-index.csv
```

Audit the full local corpus when readiness evidence changes:

```bash
/usr/local/bin/Rscript skills/figureforge/scripts/audit_cases.R \
  --cases-dir skills/figureforge/cases \
  --output-dir outputs/figureforge-audit \
  --rscript /usr/local/bin/Rscript \
  --render
```

## Completion Gates

Keep these claims separate:

- **structural evidence**: required files and metadata exist;
- **execution evidence**: a fresh render exits successfully and writes a
  non-empty output;
- **visual QA evidence**: an explicit reviewer checked data, fidelity,
  reproducibility, export, and limits;
- **distribution evidence**: redistribution is allowed for exact named assets.

A scaffolded case is never complete. A completed case may still be
`private_only`.

## References

- `references/gallery-index.md`: discovery fields, ranking, and local index.
- `references/data-mapping.md`: schema mapping and derived-field rules.
- `references/adaptation-contract.md`: adaptation workspace and report format.
- `references/ggplot-patterns.md`: reusable ggplot2 components.
- `references/theme-and-export.md`: publication export expectations.
- `references/qa-checklist.md`: visual and reproducibility QA contract.
