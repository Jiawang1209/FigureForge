# FigureForge Case Blocker

Status: blocked_source_missing

## Files Inspected

- `source-script.R`: contains plotting calls but no input values.

## Commands Run

- `Rscript source-script.R`: failed because `measurements.csv` is absent.

## Recovery Attempts

- Searched the fixture directory for CSV, TSV, XLSX, RDS, and RData inputs.

## Why Unsafe To Infer

The missing measurements determine every plotted value.

## Unblock Requirement

Provide the original `measurements.csv` or an equivalent documented table.
