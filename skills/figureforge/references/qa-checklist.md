# QA Checklist

Run this checklist before calling a FigureForge adaptation complete.

Start public adaptations with `Status: review_required`. Automated checks can
inspect file structure, dimensions, blank output, and reference dimensions,
but automated visual QA never grants verified status.

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

## QA Record Contract

The checklist becomes machine-verifiable only when a reviewer saves a
`qa.md` file in the case directory. Use this exact structure:

```markdown
# QA Record

Status: verified

## Data

Describe the source-data, schema, units, missing-value, and factor-order review.

## Visual Fidelity

Describe the comparison against the intended reference or reproduction.

## Reproducibility

Record the exact rendering command and required R packages.

## Export

Record the checked output path, format, dimensions, and resolution.

## Limits

State every unresolved visual, dependency, or source-data limitation.
```

Set `Status: verified` only after a human or explicitly authorized visual
review. A successful render cannot set this status automatically.

Before human review, generate an external automated report:

```bash
/usr/local/bin/Rscript skills/figureforge/scripts/visual_qa.R \
  --render "<adaptation_dir>/output.pdf" \
  --report "<external_report_dir>/visual-qa.json"
```

Its status remains `review_required`, `tool_check_failed`, or
`not_applicable`. Synthetic stress fixtures may exercise this workflow, but
they cannot establish scientific or visual correctness.

Distribution review is separate from visual QA. Record it in
`distribution.yml`:

```yaml
redistribution: allowed
reviewed_assets:
  - case.md
  - data.csv
  - plot.R
  - reproduction.pdf
```

If `distribution.yml` is missing, malformed, or does not explicitly allow
redistribution, the case remains `private_only`.
