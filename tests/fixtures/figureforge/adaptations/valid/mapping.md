# Adaptation Mapping

## Selected Case

`authentic-public`

## Field Mapping

| Case role | Input column | Required | Transformation |
| --- | --- | --- | --- |
| category | category | yes | preserve input order |
| value | value | yes | numeric |

## Transformations

No derived fields.

## Required R Packages

- base

## Run Command

`/usr/local/bin/Rscript plot.R input.csv output.pdf`
