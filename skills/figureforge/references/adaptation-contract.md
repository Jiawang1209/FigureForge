# Adaptation Contract

An adaptation tests whether a public case can migrate to different data. Keep
the workspace outside every source case directory. Public gallery data and
synthetic stress fixtures are examples only; user input is copied into the
external workspace.

## Required Files

```text
adaptation-name/
├── input.csv
├── mapping.md
├── plot.R
├── qa.md
├── adaptation.yml
└── output.pdf or output.png
```

- `input.csv`: new data, not the selected case's example table.
- `mapping.md`: selected case, role-to-column mapping, transformations,
  dependencies, and exact run command.
- `plot.R`: migrated case code accepting input and output paths.
- `qa.md`: starts at `Status: review_required`; it records data, visual,
  reproducibility, export, and limit review.
- `adaptation.yml`: source case ID, script hash, FigureForge version, input
  origin, and QA state.
- output: a fresh non-empty render.

## mapping.md Headings

```markdown
# Adaptation Mapping

## Selected Case

## Field Mapping

## Transformations

## Required R Packages

## Run Command
```

The field mapping must state required roles, source columns, units or types,
factor order, and transformations. Name every derived field.

## plot.R Contract

```r
args <- commandArgs(trailingOnly = TRUE)
input_path <- args[[1]]
output_path <- args[[2]]
```

The script must validate files, columns, values, and packages and must write
only to `output_path`.

## qa.md Headings

```markdown
# Adaptation QA

Status: review_required

## Data

## Visual Fidelity

## Reproducibility

## Export

## Limits
```

Automated checks never grant verified status. Do not set `Status: verified`
until a human has visually reviewed the output and its scientific mapping.
Record any intentional departure from the selected case.

Create the protected workspace with:

```bash
/usr/local/bin/Rscript skills/figureforge/scripts/create_adaptation.R \
  --case "<public-case-id>" \
  --input "<user_input.csv>" \
  --workspace "<external_adaptation_dir>"
```

## Validation

```bash
/usr/local/bin/Rscript skills/figureforge/scripts/validate_adaptation.R \
  "<adaptation_dir>" \
  --render \
  --output "<external_validation_output>" \
  --rscript /usr/local/bin/Rscript
```

Validation checks required files and headings, declared packages, the standard
argument contract, human-reviewed QA, fresh execution, and a non-empty output.
The fresh render is independent execution evidence, not a substitute for the
human visual review.
