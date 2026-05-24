# Case 20240109: One-Way ANOVA Group Comparison

## Chart Type

boxplot with jittered observations

## Chart Type Chinese

单因素方差分析箱线图

## Aliases

one-way ANOVA, boxplot, group comparison, jitter plot, 单因素方差分析, 箱线图, 分组比较, 显著性检验

## Best For

Comparing numeric values across multiple experimental groups and reporting the one-way ANOVA result alongside the distribution.

## Best For Chinese

适合展示多个实验组之间的数值差异，并配合单因素方差分析结果进行解释。

## Data Schema

- x: group identifier derived from column names such as `Group1_1`
- y: numeric measurement value
- group: group identifier such as `Group1`, `Group2`, or `Group12`
- facet: not used in the simplified plot
- label: not used
- value: observed numeric measurement

## Visual Encoding

- color: group
- size: fixed point size for observations
- shape: jittered points over boxplots
- line: boxplot median and whiskers
- annotation: ANOVA p-value in subtitle

## ggplot Components

- geom_*: `geom_boxplot()`, `geom_jitter()`
- scale_*: discrete x scale by group
- theme_*: `theme_bw()` with rotated x labels
- annotation_*: ANOVA p-value subtitle
- layout/composition: single-panel group comparison

## Adaptation Notes

The source data is wide, with replicate columns named like `Group1_1`. The plotting script converts it to long form, derives the group name before the underscore, runs `aov(Value ~ Group)`, and renders a boxplot with jittered observations. For user data already in long format, map the group column to `Group` and the measurement column to `Value`.

## Common Pitfalls

- ANOVA assumptions should be checked before interpreting significance.
- Group labels should be mapped to scientific names when the user needs publication labels.
- Wide data with inconsistent column naming will break group derivation.
- This simplified case does not draw post-hoc significance letters.
