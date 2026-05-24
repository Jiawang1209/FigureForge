# Case 20240614: Correlation Bubble Heatmap

## Chart Type

correlation heatmap

## Chart Type Chinese

相关性热图

## Aliases

correlation heatmap, bubble heatmap, correlation matrix, upper triangle heatmap, lower triangle heatmap, 相关性热图, 相关矩阵, 气泡热图, 上三角热图, 下三角热图

## Best For

Showing pairwise correlations among numeric variables with both color and point size encoding correlation strength.

## Best For Chinese

适合展示多个数值变量之间的两两相关关系，并用颜色和点大小表达相关强度。

## Data Schema

- x: first variable in the correlation matrix
- y: second variable in the correlation matrix
- group: not used
- facet: not used
- label: variable names from the input data
- value: Pearson correlation coefficient

## Visual Encoding

- color: correlation coefficient
- size: absolute correlation magnitude
- shape: filled circular points over a tile grid
- line: diagonal reference line
- annotation: not used in the simplified plot

## ggplot Components

- geom_*: `geom_tile()`, `geom_point()`, `geom_abline()`
- scale_*: diverging fill scale and point-size scale
- theme_*: `theme_minimal()` with square aspect ratio
- annotation_*: diagonal line
- layout/composition: single-panel correlation matrix

## Adaptation Notes

Use a numeric matrix or data frame. Non-numeric columns should be removed or converted before rendering. The plotting script computes Pearson correlations with pairwise complete observations, removes the diagonal, and renders the full matrix as a bubble heatmap.

## Common Pitfalls

- Correlation heatmaps are only meaningful for numeric variables.
- Strong visual patterns may be driven by duplicated or derived variables.
- Variable ordering can change interpretation and should be chosen deliberately.
- Missing values should be reviewed before correlation calculation.
