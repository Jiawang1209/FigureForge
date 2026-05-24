# Case 20230723: Fold-Change Scatter Volcano-Style Plot

## Chart Type

volcano-style scatter

## Chart Type Chinese

火山图 / 双条件差异散点图

## Aliases

volcano plot, fold-change scatter, differential expression scatter, 火山图, 差异表达散点图, 双条件log2FoldChange

## Best For

Comparing two log2 fold-change measurements and labeling genes that move consistently up or down across both conditions.

## Best For Chinese

适合比较两个条件下的 log2FoldChange，并突出两个条件中一致上调或下调的基因。

## Data Schema

- x: first log2 fold-change column, here `log2FoldChange1`
- y: second log2 fold-change column, here `log2FoldChange2`
- group: derived change class, `Up`, `Down`, or `Normal`
- facet: not used
- label: gene label column, here `Gene`
- value: derived mean fold-change score

## Visual Encoding

- color: derived change class
- size: fixed point size
- shape: point marks
- line: dashed reference lines at zero
- annotation: top up/down genes labeled with repelled text

## ggplot Components

- geom_*: `geom_point()`, `geom_hline()`, `geom_vline()`, `ggrepel::geom_text_repel()`
- scale_*: manual color scale for up, down, and normal classes
- theme_*: `theme_bw()` with a clean panel
- annotation_*: repelled gene labels
- layout/composition: single-panel scatter plot

## Adaptation Notes

Map the user's first contrast to `log2FoldChange1`, second contrast to `log2FoldChange2`, and gene label to `Gene`. The current threshold classifies genes as `Up` when both fold changes are greater than 0.25 and `Down` when both are less than -0.25. Adjust this threshold for datasets with different effect-size scales.

## Common Pitfalls

- This case is volcano-style, but it does not use p-values on the y-axis.
- Labeling too many genes will make the plot unreadable.
- The `Up` and `Down` thresholds should be documented when adapted.
- Axis limits should be checked after replacing the dataset.
- Rows with missing gene labels or fold-change values are removed before plotting.
