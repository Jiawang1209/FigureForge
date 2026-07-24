# Authentic Public Fixture

## Chart Type

bar chart

## Chart Type Chinese

柱形图

## Aliases

bar chart, column chart, 柱形图

## Best For

Comparing values across a small set of categories.

## Best For Chinese

适合比较少量类别之间的数值。

## Data Provenance

The normalized fixture data was derived from the included source table.

## Data Schema

- category: category label
- value: numeric measurement

## Visual Encoding

Bar height encodes value and position encodes category.

## ggplot Components

Base R `barplot()` is used to keep this fixture dependency-free.

## Required R Packages

- base

## Adaptation Notes

Map one categorical column and one numeric column.

## Common Pitfalls

Check category ordering before rendering.
