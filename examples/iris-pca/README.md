# FigureForge Iris PCA demo

This public, reproducible demo turns R's built-in `datasets::iris` data into a polished PC1–PC2 biplot and a compact offline report.

From the repository root, run exactly:

```sh
Rscript examples/iris-pca/plot.R examples/iris-pca/iris.csv examples/iris-pca
```

The script validates the input, performs centered and scaled PCA with `stats::prcomp`, and writes `plot.png`, `plot.pdf`, `pca-variance.csv`, `pca-scores.csv`, `pca-loadings.csv`, and `index.html`. It does not modify `iris.csv`.

## Case-grounded provenance

At the generation stage, FigureForge read the primary `20230925_PCA` case's `case.md`, `plot.R`, and verified `qa.md`. The hidden generation trace passed strict validation against those evidence files and this demo's generated `plot.R`. Public reruns remain standalone: `plot.R` reads only the supplied Iris CSV, does not access the private case, and does not create or rewrite generation-time trace state.

The user-visible README and HTML do not display private paths, private source code, private data, or hashes. The hidden trace retains SHA-256 hashes for provenance auditing.

### Schema mapping

- The case's feature-by-sample value matrix maps to row-wise Iris measurement columns.
- The case's sample group maps to `Species`.
- The case's `Dim.1`/`Dim.2` roles map to `PC1`/`PC2`.

### Adopted patterns

- A PC1-PC2 ordination composition with variance explained in both axis labels.
- Group encoding through points, color, and shape.
- Group-boundary ellipses layered with zero reference axes.

### Departures

- Feature-by-sample input became row-wise Iris observations.
- Four panels became a single biplot.
- `FactoMineR` became `stats::prcomp`.
- Fixed limits became data-aware limits.
- Loading arrows were added as an explanatory extension.
