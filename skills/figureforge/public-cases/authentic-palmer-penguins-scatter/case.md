# Palmer Penguins Bill Measurements

## Chart Type

grouped scatter plot with descriptive linear fits

## Chart Type Chinese

带分组描述性线性拟合的散点图

## Aliases

penguins scatter, bill measurements, species fit, 企鹅散点图, 喙部测量

## Best For

Exploring association between two continuous morphology measurements across
species.

## Best For Chinese

探索不同物种之间两项连续形态测量的关联。

## Data Provenance

The fixed dataset is a normalized snapshot of the CC0 Palmer Penguins data.
It retains 333 complete observations and five declared fields. See
`source.yml` for the upstream URL, hashes, attribution, and normalization.
The plot is descriptive and does not establish causal or population-level
claims.

## Data Schema

- predictor: `bill_length_mm`, finite positive millimetres
- response: `bill_depth_mm`, finite positive millimetres
- group: `species`, non-empty category
- size: `body_mass_g`, finite positive grams
- sex: non-empty category

## Visual Encoding

Position encodes bill length and depth, color encodes species, and separate
linear fits summarize within-species association.

## ggplot Components

- `geom_point()`
- `geom_smooth(method = "lm")`
- color-blind-conscious manual palette

## Required R Packages

- ggplot2

## Adaptation Notes

Map two continuous measurements and a scientifically meaningful grouping
field. Retain fitted lines only when a linear descriptive summary is useful.

## Common Pitfalls

- Within-species fits do not imply causality.
- Removing incomplete rows changes the analyzed subset.
- Body mass and sex are retained in the data but not encoded in this figure.
