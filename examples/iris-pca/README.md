# FigureForge Iris PCA demo

This public, reproducible demo turns R's built-in `datasets::iris` data into a polished PC1–PC2 biplot and a compact offline report.

From the repository root, run exactly:

```sh
Rscript examples/iris-pca/plot.R examples/iris-pca/iris.csv examples/iris-pca
```

The script validates the input, performs centered and scaled PCA with `stats::prcomp`, and writes `plot.png`, `plot.pdf`, `pca-variance.csv`, `pca-scores.csv`, `pca-loadings.csv`, and `index.html`. It does not modify `iris.csv`.

The private `20230925_PCA` case was consulted only as a visual grammar reference for composition and annotation. No private data or code is included in this demo.
