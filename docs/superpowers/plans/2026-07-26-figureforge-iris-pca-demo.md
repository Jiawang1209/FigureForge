# FigureForge Iris PCA Demo Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a reproducible Iris PCA FigureForge demo with the standard R/PNG/PDF delivery and a browser-viewable HTML report, then use it as the primary example in the concise bilingual root READMEs.

**Architecture:** A standalone `examples/iris-pca/plot.R` owns input validation, PCA calculation, CSV export, ggplot rendering, and deterministic HTML generation. A documentation contract test verifies the demo, install instructions, bilingual parity, artifact links, and private-corpus boundary. Generated demo artifacts are checked into the example directory so the HTML opens immediately after cloning.

**Tech Stack:** R 4.x, base `stats::prcomp`, ggplot2, grid, HTML/CSS, R contract tests, Poppler/browser validation.

---

### Task 1: Define the demo and README contracts

**Files:**
- Create: `tests/figureforge/test_iris_pca_demo.R`
- Modify: `tests/figureforge/test_v110_documentation.R`

- [ ] **Step 1: Write the failing demo contract test**

Create assertions that require:

```r
demo_dir <- file.path(repo_root, "examples", "iris-pca")
required <- c(
  "iris.csv", "plot.R", "plot.png", "plot.pdf", "pca-variance.csv",
  "pca-scores.csv", "pca-loadings.csv", "index.html", "README.md"
)
stopifnot(all(file.exists(file.path(demo_dir, required))))
```

The test must also:

- read `iris.csv` and require 150 rows, four numeric measurement columns, and
  three species;
- parse `plot.R` and require the two-argument contract, `prcomp`, scaling,
  explicit required-column validation, PNG/PDF/CSV/HTML output names, and no
  private case path;
- read output CSVs and require explained variance to sum to approximately 100%,
  150 score rows, four loading rows, and finite values;
- verify PNG signature/dimensions and PDF page/renderability using the existing
  repository test helpers or Poppler;
- parse `index.html` for the FigureForge request, PC1/PC2 values, image, result
  links, rerun command, responsive viewport, and no absolute local path;
- require both root READMEs to contain installation commands, the Iris PCA
  example, `plot.R`, `plot.png`, and `plot.pdf`.

- [ ] **Step 2: Run the new test and observe RED**

Run:

```bash
/usr/local/bin/Rscript tests/figureforge/test_iris_pca_demo.R
```

Expected: failure because `examples/iris-pca/` does not exist.

- [ ] **Step 3: Add concise README expectations to the v1.1 documentation test**

Require matching English/Chinese top-level sections for installation, use,
default outputs, Iris PCA demo, maintainer links, scope, and license. Reject the
old root-level maintainer walkthrough headings such as `Case Readiness Audit`
and `案例完成度审计`, while continuing to require release evidence and private
corpus boundary links.

- [ ] **Step 4: Commit the RED contract**

```bash
git add tests/figureforge/test_iris_pca_demo.R tests/figureforge/test_v110_documentation.R
git commit -m "test: define FigureForge iris PCA demo"
```

### Task 2: Implement the standalone PCA delivery

**Files:**
- Create: `examples/iris-pca/iris.csv`
- Create: `examples/iris-pca/plot.R`
- Create: `examples/iris-pca/README.md`

- [ ] **Step 1: Materialize the external input**

Run:

```bash
mkdir -p examples/iris-pca
/usr/local/bin/Rscript -e 'write.csv(datasets::iris, "examples/iris-pca/iris.csv", row.names = FALSE)'
```

Confirm the file contains the columns:

```text
Sepal.Length,Sepal.Width,Petal.Length,Petal.Width,Species
```

- [ ] **Step 2: Implement argument and input validation in `plot.R`**

The script must use this interface:

```r
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2L) {
  stop("Usage: Rscript plot.R <input-file> <output-directory>", call. = FALSE)
}
input_file <- normalizePath(args[[1]], mustWork = TRUE)
output_dir <- args[[2]]
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
```

Require `Sepal.Length`, `Sepal.Width`, `Petal.Length`, `Petal.Width`, and
`Species`; reject missing/nonfinite numeric values, empty species labels,
fewer than three rows per group, or zero-variance measurements.

- [ ] **Step 3: Implement deterministic PCA and result tables**

Use:

```r
pca <- stats::prcomp(measurements, center = TRUE, scale. = TRUE)
variance_pct <- 100 * pca$sdev^2 / sum(pca$sdev^2)
```

Write:

- `pca-variance.csv` with component, eigenvalue, explained percent, and
  cumulative percent;
- `pca-scores.csv` with sample id, species, and all PC scores;
- `pca-loadings.csv` with variable and all component loadings.

- [ ] **Step 4: Implement the PCA biplot**

Use ggplot2 for PC1/PC2 scores, the Okabe-Ito three-color palette, species
shapes, 95% normal ellipses, zero reference lines, equal coordinates, and
scaled loading arrows. Use `grid::unit` for arrowheads and `geom_text` for
loading labels. Axis titles must include the calculated explained variance.

Save:

```r
ggplot2::ggsave(file.path(output_dir, "plot.png"), plot, width = 10, height = 7.2, dpi = 300)
ggplot2::ggsave(file.path(output_dir, "plot.pdf"), plot, width = 10, height = 7.2, device = grDevices::cairo_pdf)
```

- [ ] **Step 5: Generate `index.html` from the same results**

Write a UTF-8 HTML document with inline responsive CSS and relative links. The
report must contain:

```html
<meta name="viewport" content="width=device-width, initial-scale=1">
<blockquote>Use iris.csv with the FigureForge Skill to run PCA...</blockquote>
<img src="plot.png" alt="Iris PCA biplot">
<code>Rscript plot.R iris.csv .</code>
```

Generate the variance and loading table rows from the live R objects, HTML
escape all dynamic text, and link every artifact.

- [ ] **Step 6: Document the example**

`examples/iris-pca/README.md` must identify private case `20230925_PCA` only as
the visual-grammar reference, state that no private data/code is included, and
show:

```bash
Rscript plot.R iris.csv .
```

- [ ] **Step 7: Run the script and make the contract GREEN**

Run:

```bash
cd examples/iris-pca
/usr/local/bin/Rscript plot.R iris.csv .
cd ../..
/usr/local/bin/Rscript tests/figureforge/test_iris_pca_demo.R
```

Expected: all artifacts generated and `iris PCA demo tests: PASS`.

- [ ] **Step 8: Independently rerun into a temporary directory**

Run:

```bash
demo_out="$(mktemp -d /tmp/figureforge-iris-pca.XXXXXX)"
/usr/local/bin/Rscript examples/iris-pca/plot.R examples/iris-pca/iris.csv "$demo_out"
cmp examples/iris-pca/pca-variance.csv "$demo_out/pca-variance.csv"
cmp examples/iris-pca/pca-scores.csv "$demo_out/pca-scores.csv"
cmp examples/iris-pca/pca-loadings.csv "$demo_out/pca-loadings.csv"
```

Expected: exit 0 and byte-identical numeric CSV outputs.

- [ ] **Step 9: Commit the executable demo**

```bash
git add examples/iris-pca
git commit -m "feat: add FigureForge iris PCA demo"
```

### Task 3: Rewrite the bilingual root READMEs

**Files:**
- Modify: `README.md`
- Modify: `README.zh.md`
- Test: `tests/figureforge/test_v110_documentation.R`
- Test: `tests/figureforge/test_iris_pca_demo.R`

- [ ] **Step 1: Replace `README.md` with the approved concise structure**

Keep only:

```text
FigureForge
What it is
Install
Use
Iris PCA demo
Default output
Documentation
Scope
License
```

Installation must show cloning and copying:

```bash
git clone https://github.com/Jiawang1209/FigureForge.git
mkdir -p .agents/skills
cp -R FigureForge/skills/figureforge .agents/skills/figureforge
test -s .agents/skills/figureforge/SKILL.md
```

The primary request must be:

```text
Use data.csv with the FigureForge Skill to draw a scatter plot and give me the R script.
```

- [ ] **Step 2: Replace `README.zh.md` with the aligned Chinese structure**

Use the same sections and commands, with the primary request:

```text
使用 data.csv 数据，基于 FigureForge Skill 帮我绘制一个散点图，并给我一份 R 脚本。
```

Both READMEs must link the Iris PCA HTML/source and the existing plotting,
maintainer, certification, and status documents.

- [ ] **Step 3: Run documentation tests**

Run:

```bash
/usr/local/bin/Rscript tests/figureforge/test_iris_pca_demo.R
/usr/local/bin/Rscript tests/figureforge/test_v110_documentation.R
/usr/local/bin/Rscript tests/figureforge/test_v1_documentation.R
/usr/local/bin/Rscript tests/figureforge/test_v101_documentation.R
git diff --check
```

Expected: all tests PASS and no whitespace errors.

- [ ] **Step 4: Commit the README rewrite**

```bash
git add README.md README.zh.md tests/figureforge/test_v110_documentation.R
git commit -m "docs: add FigureForge install and iris PCA quickstart"
```

### Task 4: Browser and release-level verification

**Files:**
- Verify: `examples/iris-pca/index.html`
- Verify: `examples/iris-pca/plot.png`
- Verify: `examples/iris-pca/plot.pdf`

- [ ] **Step 1: Validate image and PDF rendering**

Run:

```bash
file examples/iris-pca/plot.png examples/iris-pca/plot.pdf
pdfinfo examples/iris-pca/plot.pdf
render_dir="$(mktemp -d /tmp/figureforge-iris-pdf.XXXXXX)"
pdftoppm -png -f 1 -singlefile examples/iris-pca/plot.pdf "$render_dir/page"
file "$render_dir/page.png"
```

Expected: decodable PNG, one-page PDF, and decodable PDF render.

- [ ] **Step 2: Open the HTML in a real browser**

Serve the repository on localhost, open
`examples/iris-pca/index.html`, and check:

- desktop and mobile widths;
- figure visibility and aspect ratio;
- table overflow behavior;
- all artifact links;
- no missing resources or console errors.

- [ ] **Step 3: Run the full v1.1 verifier**

Run:

```bash
./scripts/verify_figureforge_v110.sh
```

Expected final line:

```text
FigureForge Skill v1.1.0 acceptance: PASS
```

- [ ] **Step 4: Commit any verification-driven corrections**

If browser or full-verifier checks require corrections, update only the
relevant demo/README/test files, rerun the failed check and the focused
contracts, then commit:

```bash
git add README.md README.zh.md examples/iris-pca tests/figureforge
git commit -m "fix: polish FigureForge iris PCA demo"
```
