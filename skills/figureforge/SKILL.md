---
name: figureforge
description: Use when selecting, reproducing, adapting, or QA-checking publication-ready scientific figures from FigureForge R/ggplot2 cases, including Chinese or English chart requests and new-data column mapping.
---

# FigureForge

FigureForge turns public scientific-figure patterns into auditable new-data
adaptations. Select the closest public case, inspect its metadata, code, and
synthetic data, map the user's fields explicitly, migrate the case-specific
script, render, and record QA.

The installed public gallery is the default and is independently usable.
Every shipped dataset declares `synthetic_test_fixture: true`; it demonstrates
software behavior and carries no scientific claim. `Status: review_required`
is the safe initial QA state, and automated visual QA never grants verified
status. Private cases are optional local extensions.
MCP is planned and unimplemented.

## Non-Negotiable Rules

- Prefer a schema-compatible public case over a generic plotting scaffold.
- Read `case.md`, `case.yml`, `data.csv`, `plot.R`, `qa.md`, and
  `distribution.yml` before adapting a public case.
- Never infer completion from file presence or a successful render alone.
- Work outside the source case directory; do not overwrite private inputs,
  original figures, reproductions, or source scripts.
- Treat every local extension as `private_only` unless `distribution.yml`
  explicitly allows redistribution of named assets.
- A verified QA and a valid blocker cannot coexist.
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

Start by checking the runtime and public gallery:

```bash
/usr/local/bin/Rscript skills/figureforge/scripts/doctor.R

/usr/local/bin/Rscript skills/figureforge/scripts/search_cases.R \
  --public \
  --query "<chart, science, or schema terms>" \
  --explain-scores \
  --limit 5
```

Search accepts English or Chinese scientific intent, family, alias, or role
terms. Add `--schema "<input.csv>"` to include input-column compatibility in
the score. The canonical tracked catalog is
`references/public-case-index.csv`; the default public case root is
`skills/figureforge/public-cases`.

Private cases are optional local extensions. Use an explicit root only when
the user has authorized access:

```bash
/usr/local/bin/Rscript skills/figureforge/scripts/search_cases.R \
  --cases-dir "<private_cases_dir>" \
  --query "<chart, science, or schema terms>" \
  --completed-only \
  --limit 5
```

Never present a scaffolded, structurally incomplete, or private case as a
distributed public asset.

Rank candidates by:

1. scientific comparison and visual encoding;
2. data shape and required fields;
3. annotation, statistics, and layout;
4. fresh reproducibility and QA evidence;
5. dependency availability;
6. distribution boundary.

### 2. Inspect the selected case

Read the selected `case.md`, `case.yml`, `data.csv`, `plot.R`, `qa.md`, and
`distribution.yml`. Public data are synthetic fixtures; inspect them as schema
examples, not scientific evidence.

Check dependencies before migration:

```bash
/usr/local/bin/Rscript skills/figureforge/scripts/doctor.R \
  --case "<public-case-id>" \
  --strict
```

Do not silently replace a missing package. If a compatible native
implementation is used, document the visible differences and verify them.

### 3. Create an isolated adaptation workspace

First generate a schema-match report:

```bash
/usr/local/bin/Rscript skills/figureforge/scripts/match_schema.R \
  --case "<public-case-id>" \
  --input "<user_input.csv>" \
  --output "<external_workspace_parent>/schema-match.csv"
```

Then create a protected adaptation workspace outside the Skill:

```bash
/usr/local/bin/Rscript skills/figureforge/scripts/create_adaptation.R \
  --case "<public-case-id>" \
  --input "<user_input.csv>" \
  --workspace "<external_adaptation_dir>"
```

The generator rejects any workspace overlapping public or private source roots
and refuses a non-empty destination. Use
`references/adaptation-contract.md` for the exact files and headings.

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

### 7. Perform visual QA

Create a non-authoritative machine report outside source case directories:

```bash
/usr/local/bin/Rscript skills/figureforge/scripts/visual_qa.R \
  --render "<adaptation_dir>/output.pdf" \
  --report "<external_report_dir>/visual-qa.json"
```

Add `--reference "<trusted_reference>"` only when redistribution and access
permit it. The report status remains `review_required`,
`tool_check_failed`, or `not_applicable`; it never grants verified status and
never edits `qa.md`.

Then use `references/qa-checklist.md` for human review. Verify:

- data coverage, units, missingness, derived values, and factor order;
- scientific meaning of every aesthetic and annotation;
- fidelity to the selected case's useful structure;
- legibility, clipping, overlaps, scales, legends, and panel alignment;
- output format, dimensions, and resolution;
- every remaining limitation.

Only a human or explicitly authorized visual review may replace
`Status: review_required` with `Status: verified`.

### 8. Independently re-render

After the human QA record is complete, validate with a separate output:

```bash
/usr/local/bin/Rscript skills/figureforge/scripts/validate_adaptation.R \
  "<adaptation_dir>" \
  --render \
  --output "<separate_validation_output>" \
  --rscript /usr/local/bin/Rscript
```

This fresh render is reproducibility evidence; it does not perform or replace
human visual review.

### 9. Report the result

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

Plan the remaining cases in deterministic evidence-first waves:

```bash
/usr/local/bin/Rscript skills/figureforge/scripts/plan_case_batches.R \
  --readiness outputs/figureforge-audit/case-readiness.csv \
  --output outputs/figureforge-audit/batch-manifest.csv \
  --batch-size 20
```

If authentic completion remains unsafe after concrete recovery attempts, use
the exact `references/blocker-contract.md` structure and validate it:

```bash
/usr/local/bin/Rscript skills/figureforge/scripts/validate_blocker.R \
  "<case_dir>"
```

Supported categories begin with `blocked_source_missing` and cover only source,
dependency, visual-reference, corruption, ambiguous-mapping, and rights
failures. Time or workload is not a blocker.

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

At corpus scale, `terminal_outcome` is:

- `completed` only for a non-scaffolded runnable, reproduced, QA-verified case;
- `blocked` only for a valid evidence-backed blocker record;
- `pending` for every other case.

## References

- `references/gallery-index.md`: discovery fields, ranking, and local index.
- `references/data-mapping.md`: schema mapping and derived-field rules.
- `references/adaptation-contract.md`: adaptation workspace and report format.
- `references/blocker-contract.md`: evidence-backed terminal blockers.
- `references/ggplot-patterns.md`: reusable ggplot2 components.
- `references/theme-and-export.md`: publication export expectations.
- `references/qa-checklist.md`: visual and reproducibility QA contract.
