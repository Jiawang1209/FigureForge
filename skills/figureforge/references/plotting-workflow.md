# Plotting Workflow

This workflow governs ordinary FigureForge plotting tasks.

## Input Inspection

Inspect the real file before selecting a visual approach. Record column names,
types, missingness, groups, duplicate keys, relevant ranges, units, and any
requested or scientifically necessary transformations. Preserve the user's
input; do not rewrite the source file merely to match a case.

## Case Strategy

Search by scientific relationship, data shape, visual grammar, schema, and
dependency fit. Run `search_cases.R` with `--output` to
`.figureforge/case-search.csv` before choosing a mode; record the query
SHA-256, controlled abstract intent, receipt filename, and receipt SHA-256 in
`case-trace.yml`. Never persist the raw query. Then choose exactly one mode:

- `case_based`: choose one readable primary case; actually read `case.md`,
  `plot.R`, and `qa.md` when present. Use secondary cases only for local
  palettes, annotations, labels, panels, or specialist idioms.
- `general_fallback`: when there is no sufficiently relevant/readable primary
  case, record the reason and use sound general R plotting methods without a
  case-grounded claim.

Follow the [Case Use Contract](case-use-contract.md) for schema mapping,
adopted patterns, departures, `.figureforge/case-trace.yml`, and the strict
claim gate. Do not make the user inspect or operate the case library.

## Output

Create `plot.R`, `plot.png`, and `plot.pdf` outside the installed Skill and all
case directories. `plot.R` must accept an input file and an output directory,
then create both image formats there:

```bash
Rscript plot.R <input-file> <output-directory>
```

## Script Requirements

Validate arguments, input existence, required columns, and relevant values.
Declare required packages explicitly and use deterministic seeds for stochastic
layouts or label placement. Preserve the user's input, create or validate a safe
output directory, and fail with actionable errors. Use publication-appropriate
dimensions and readable text, and produce a vector PDF alongside the PNG.

## Task-Level Review

Perform an independent fresh rerun. Confirm that all outputs are nonempty and
open successfully. Review data coverage, mappings, groups, labels, legends,
scales, panels, clipping, overlap, and readability. This is review of the task
result, not case or release certification. For `case_based`, run
`validate_case_trace.R` with `--case-dir`, `--script`, and `--schema`; only successful
`strict` validation permits `claim: case_grounded`. `structural` or `partial`
validation cannot authorize that claim. For `general_fallback`, use
`claim: general_method` and never imply case-grounded generation.

## Delivery

Deliver clickable paths for `plot.R`, `plot.png`, and `plot.pdf`. The hidden
trace and search receipt are not visible artifacts. Add a short note identifying the mode,
the primary case and mappings when case-based or the fallback reason otherwise,
plus specialist packages and remaining limits.
