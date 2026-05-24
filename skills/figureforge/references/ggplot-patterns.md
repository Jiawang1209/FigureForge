# ggplot2 Patterns

These notes describe recurring ggplot2 building blocks used across FigureForge cases. They are guidance, not a mandatory plotting framework.

## Common Components

- `geom_col()` and `geom_bar()` for categorical comparisons.
- `geom_boxplot()` and `geom_violin()` for distributions.
- `geom_point()` with `geom_text()` or `ggrepel::geom_text_repel()` for labeled scatter plots.
- `geom_line()` and `geom_smooth()` for trajectories and trends.
- `geom_tile()` for heatmaps and matrix-like summaries.
- `facet_wrap()` and `facet_grid()` for small multiples.
- `patchwork` or `cowplot` for multi-panel composition.

## Adaptation Guidance

- Keep case-specific details visible in `plot.R`.
- Extract only small helpers when they reduce duplication inside one case.
- Prefer explicit scales and labels over relying on defaults.
- Check whether coordinate transforms, factor ordering, or annotations encode scientific meaning.
