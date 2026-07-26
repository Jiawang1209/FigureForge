# FigureForge Iris PCA Demo Design

**Date:** 2026-07-26  
**Status:** Approved

## Goal

Create a complete, browser-viewable demonstration of using the FigureForge
Skill with the R `iris` data set. The demo must show the user request, the
analysis method, the generated FigureForge artifacts, and the PCA results in a
single HTML report.

## Location and files

The demo will live in `examples/iris-pca/` and contain:

- `iris.csv` — materialized input data from R's built-in `iris` data set;
- `plot.R` — standalone FigureForge delivery script;
- `plot.png` — browser-friendly rendered figure;
- `plot.pdf` — vector figure;
- `pca-variance.csv` — explained-variance summary;
- `pca-scores.csv` — sample scores with species labels;
- `pca-loadings.csv` — variable loadings;
- `index.html` — the human-facing report;
- `README.md` — the exact run command and artifact description.

## FigureForge workflow

The demo will follow the shipped Skill rather than merely using the name:

1. inspect the materialized `iris.csv` input;
2. interpret the request as a grouped PCA ordination/biplot;
3. use private case `20230925_PCA` only as the primary visual-grammar
   reference, without copying private data or private corpus files;
4. write a new standalone script for the real input;
5. run and independently rerun the script;
6. inspect the rendered PNG and PDF;
7. return the three default artifacts plus the HTML report.

## Analysis

`plot.R` will:

- accept `Rscript plot.R <input-file> <output-directory>`;
- require the four standard iris measurement columns and `Species`;
- reject missing, nonnumeric, nonfinite, or zero-variance measurement data with
  actionable errors;
- standardize the four measurements and run deterministic `stats::prcomp`;
- write PC scores, loadings, and explained variance as CSV files;
- plot PC1 versus PC2 with species color and shape;
- include group ellipses and scaled loading arrows with readable labels;
- write nonempty `plot.png` and `plot.pdf`.

The script will use R/ggplot2 and lightweight installed dependencies only. It
will not use Python.

## HTML report

`index.html` will be a portable local report using relative paths. It will show:

- the natural-language FigureForge request;
- a short explanation of how FigureForge selected and adapted the PCA visual
  approach;
- analysis settings and input dimensions;
- PC1 and PC2 explained variance;
- the generated PCA figure;
- compact explained-variance and loading tables;
- links to `plot.R`, `plot.png`, `plot.pdf`, and all CSV results;
- the exact rerun command.

The report will use a clean responsive layout and remain readable on desktop
and mobile. It will not require a JavaScript framework or remote assets.

## README integration

The concise English and Chinese root READMEs will include the Iris PCA demo as
the primary concrete usage example and link to `examples/iris-pca/index.html`
and its source directory.

## Validation

Completion requires:

- a clean run and an independent second run of `plot.R`;
- nonempty, decodable PNG and renderable one-page PDF outputs;
- internally consistent variance, score, and loading tables;
- a browser-level check of the HTML on desktop and mobile widths;
- all local links in `index.html` resolving;
- relevant documentation tests and `git diff --check` passing;
- no private corpus data, raw case files, or generated temporary state being
  added to the demo.
