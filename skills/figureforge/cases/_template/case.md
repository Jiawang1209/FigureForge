# Case Template: Replace With Case Title

This directory is a template for future real FigureForge cases. It is not a
curated reproduction case and must never be counted as one.

## Chart Type

scatter

## Chart Type Chinese

散点图

## Aliases

scatter plot, labeled scatter, 散点图, 带标签散点图

## Best For

Describe the scientific data scenario where this case is useful.

## Best For Chinese

用中文描述这个案例适合的科学数据场景。

## Data Provenance

Document the authentic source files and every normalization step used to create
`data.csv`. Do not claim completion when `data.csv` is synthetic scaffold data.

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

## Required R Packages

- ggplot2

## Adaptation Notes

Replace this text with exact notes explaining how user data maps into the case.

## Common Pitfalls

- Do not leave template language in a real case.
- Do not add `original.png` unless redistribution is allowed.
- Do not call a case verified until rendering and QA have been completed.
- Absence of `distribution.yml` means the case is private-only.
