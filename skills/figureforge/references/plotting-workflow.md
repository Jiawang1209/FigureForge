# Plotting Workflow

This workflow governs ordinary FigureForge plotting tasks.

## Input Inspection

Inspect the real file before selecting a visual approach. Record column names,
types, missingness, groups, duplicate keys, relevant ranges, units, and any
requested or scientifically necessary transformations. Preserve the user's
input; do not rewrite the source file merely to match a case.

## Case Strategy

Choose one primary case by scientific relationship, data shape, visual grammar,
and dependency fit. Use secondary cases only for local palettes, annotations,
labels, panels, or specialist idioms. The library is knowledge, not a gate:
write the best plot for the real data even when no case is an exact match.

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
result, not case or release certification.

## Delivery

Deliver clickable paths for `plot.R`, `plot.png`, and `plot.pdf`. Add a short
note identifying the primary case, mappings, any specialist packages, and
remaining limits.
