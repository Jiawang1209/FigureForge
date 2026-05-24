# Case 20231010: Differential Expression Volcano Plot

## Chart Type

volcano plot

## Chart Type Chinese

火山图

## Aliases

volcano plot, differential expression, RNA-seq, p-value plot, 火山图, 差异表达, 显著性散点图

## Best For

Showing differential-expression results with log2 fold change on the x-axis and adjusted p-value significance on the y-axis.

## Best For Chinese

适合展示差异表达分析结果，用横轴表示 log2FoldChange，用纵轴表示校正后 p 值的显著性。

## Data Schema

- x: `log2FoldChange`
- y: derived `-log10(padj)`
- group: `change`, usually `Up`, `Down`, or `Normal`
- facet: not used
- label: `SYMBOL`
- value: adjusted p-value and effect size

## Visual Encoding

- color: continuous log2 fold-change gradient
- size: `-log10(padj)`
- shape: highlighted top genes use outlined points
- line: fold-change and p-value threshold lines
- annotation: selected up/down genes and p-value threshold text

## ggplot Components

- geom_*: `geom_point()`, `geom_vline()`, `geom_hline()`, `ggrepel::geom_text_repel()`
- scale_*: gradient color scale and size range
- theme_*: `theme_bw()` with panel grid removed
- annotation_*: p-value label and repelled gene names
- layout/composition: single-panel volcano plot

## Adaptation Notes

Map the user's gene symbol column to `SYMBOL`, effect size to `log2FoldChange`, adjusted p-value to `padj`, and optional class label to `change`. If `change` is absent, derive it from fold-change and p-value thresholds before plotting.

## Common Pitfalls

- Zero adjusted p-values must be handled before `-log10()` transformation.
- Thresholds should match the analysis method and be stated in the report.
- Gene labels should be limited to avoid clutter.
- The `SYMBOL` column may contain comma-separated aliases and should be cleaned.
