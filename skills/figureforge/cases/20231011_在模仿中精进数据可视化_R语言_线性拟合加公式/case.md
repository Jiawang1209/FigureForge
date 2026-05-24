# Case 20231011: Linear Fit With Equation Labels

## Chart Type

scatter plot with linear fit

## Chart Type Chinese

线性拟合散点图

## Aliases

linear regression plot, fitted line, equation label, correlation plot, 线性拟合, 回归散点图, 公式标注, 相关性散点图

## Best For

Showing relationships between two numeric variables across groups, with linear model fits and equation or correlation annotations.

## Best For Chinese

适合展示两个数值变量之间的关系，并按分组绘制线性拟合线和相关统计信息。

## Data Schema

- x: `carat`
- y: `price`
- group: `cut`
- facet: not used
- label: not used
- value: numeric x and y measurements

## Visual Encoding

- color: group
- size: fixed point size
- shape: group
- line: linear model fit per group
- annotation: optional regression equation and R-squared labels

## ggplot Components

- geom_*: `geom_point()`, `geom_smooth()`
- scale_*: manual color and shape scales when adapting
- theme_*: `theme_bw()` with clean panel
- annotation_*: model summary text in subtitle for the simplified script
- layout/composition: single-panel grouped scatter plot

## Adaptation Notes

Map the user's predictor to `carat`, response to `price`, and grouping column to `cut`, or update the script variable names for the user's dataset. The source case used `ggpmisc::stat_poly_eq()` for equation labels; the simplified standard script keeps the grouped fit and reports the global adjusted R-squared in the subtitle.

## Common Pitfalls

- Regression equations depend on the chosen model formula.
- Group-wise fits can be misleading when groups have few observations.
- Dense scatter plots may need alpha, sampling, or smaller point sizes.
- Equation labels require extra package support when exact in-plot formulas are needed.
