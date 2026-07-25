# FigureForge Skill v1.0 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> `superpowers:executing-plans` to implement this plan task-by-task. Steps use
> checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship a public, independently usable FigureForge Skill v1.0 with 12
redistributable synthetic cases, at least 20 adaptation stress fixtures, safe
workspace generation, dependency diagnostics, bilingual schema-aware search,
non-authoritative visual QA, packaging, and clean-clone acceptance.

**Architecture:** Keep the private 165-case corpus outside the public release.
Build a self-contained public gallery under `skills/figureforge/public-cases/`
and use fail-closed metadata validators before any asset can enter the release
manifest. Add small base-R libraries behind stable Rscript CLIs, exercise them
with tracked synthetic fixtures, and generate all runtime output outside source
and fixture directories.

**Tech Stack:** Base R, ggplot2, YAML-like constrained metadata, CSV, Markdown,
JSON emitted by base R helpers, `/usr/local/bin/Rscript`, Poppler command-line
tools when available, Python official Skill validator, Git.

---

## File Map

New production files are divided by responsibility:

```text
skills/figureforge/
├── VERSION
├── public-cases/<12 case IDs>/
│   ├── case.md
│   ├── case.yml
│   ├── data.csv
│   ├── plot.R
│   ├── qa.md
│   └── distribution.yml
├── schemas/
│   ├── case-schema-v1.md
│   ├── public-case-taxonomy.csv
│   └── visual-qa-report-v1.md
├── references/
│   └── public-case-index.csv
├── lib/
│   ├── distribution_validation.R
│   ├── metadata.R
│   ├── schema_matching.R
│   ├── workspace_generation.R
│   ├── dependency_doctor.R
│   ├── visual_qa.R
│   └── release_packaging.R
└── scripts/
    ├── validate_distribution.R
    ├── validate_public_case.R
    ├── generate_stress_fixtures.R
    ├── run_stress_tests.R
    ├── create_adaptation.R
    ├── doctor.R
    ├── match_schema.R
    ├── visual_qa.R
    ├── build_release_manifest.R
    └── package_skill.R
```

New tests use one focused file per public boundary:

```text
tests/figureforge/
├── test_distribution_validation.R
├── test_public_cases.R
├── test_stress_fixtures.R
├── test_workspace_generation.R
├── test_dependency_doctor.R
├── test_schema_matching.R
├── test_visual_qa.R
├── test_release_packaging.R
└── test_v1_acceptance.R
```

Tracked fixtures contain only generated data, minimal metadata, and scripts.
Rendered images, reports, archives, and clean-clone directories are never
tracked.

## Common Verification Commands

Run these after every GREEN step:

```bash
for test_file in tests/figureforge/*.R; do
  /usr/local/bin/Rscript "$test_file" || exit 1
done

for r_file in $(find skills/figureforge tests/figureforge \
  -type f -name '*.R' | sort); do
  /usr/local/bin/Rscript -e "parse(file='$r_file')" >/dev/null || exit 1
done

python3 /Users/liuyue/.codex/skills/.system/skill-creator/scripts/quick_validate.py \
  skills/figureforge

git diff --check
```

Expected: every R test prints its `PASS` message, every parse exits zero,
`quick_validate.py` prints `Skill is valid!`, and `git diff --check` is silent.

### Task 1: Define the Fail-Closed Distribution Contract

**Files:**

- Create: `tests/figureforge/test_distribution_validation.R`
- Create: `tests/fixtures/figureforge/distribution/valid/distribution.yml`
- Create: `tests/fixtures/figureforge/distribution/valid/case.md`
- Create: `tests/fixtures/figureforge/distribution/valid/case.yml`
- Create: `tests/fixtures/figureforge/distribution/valid/data.csv`
- Create: `tests/fixtures/figureforge/distribution/valid/plot.R`
- Create: `tests/fixtures/figureforge/distribution/valid/qa.md`
- Create: `tests/fixtures/figureforge/distribution/missing-asset/distribution.yml`
- Create: `tests/fixtures/figureforge/distribution/missing-asset/case.md`
- Create: `tests/fixtures/figureforge/distribution/missing-asset/case.yml`
- Create: `tests/fixtures/figureforge/distribution/missing-asset/data.csv`
- Create: `tests/fixtures/figureforge/distribution/missing-asset/plot.R`
- Create: `tests/fixtures/figureforge/distribution/missing-asset/qa.md`
- Create: `tests/fixtures/figureforge/distribution/rights-unknown/distribution.yml`
- Create: `tests/fixtures/figureforge/distribution/rights-unknown/case.md`
- Create: `tests/fixtures/figureforge/distribution/rights-unknown/case.yml`
- Create: `tests/fixtures/figureforge/distribution/rights-unknown/data.csv`
- Create: `tests/fixtures/figureforge/distribution/rights-unknown/plot.R`
- Create: `tests/fixtures/figureforge/distribution/rights-unknown/qa.md`
- Create: `skills/figureforge/lib/distribution_validation.R`
- Create: `skills/figureforge/scripts/validate_distribution.R`

- [ ] **Step 1: Write the valid fixture**

Use this exact distribution metadata:

```yaml
schema_version: 1
distribution_status: public_ready
synthetic_test_fixture: true
scientific_claims: none
origin: generated-by-FigureForge
copyright_holder: FigureForge contributors
license: CC0-1.0
review_date: 2026-07-25
reviewer: FigureForge release review
assets: case.md|case.yml|data.csv|plot.R|qa.md|distribution.yml
```

Use `Status: review_required` in `qa.md`. The missing-asset fixture omits
`plot.R` from `assets`. The rights-unknown fixture uses
`license: unreviewed`.

- [ ] **Step 2: Write the failing contract test**

The test sources the not-yet-created library and asserts:

```r
valid <- validate_distribution(file.path(fixtures, "valid"))
stopifnot(isTRUE(valid$ok))
stopifnot(identical(valid$status, "public_ready"))
stopifnot(isTRUE(valid$synthetic_test_fixture))

missing_asset <- validate_distribution(file.path(fixtures, "missing-asset"))
stopifnot(!isTRUE(missing_asset$ok))
stopifnot("all distributed files allowlisted" %in% missing_asset$failed_checks)

rights_unknown <- validate_distribution(file.path(fixtures, "rights-unknown"))
stopifnot(!isTRUE(rights_unknown$ok))
stopifnot("recognized redistribution basis" %in% rights_unknown$failed_checks)
```

- [ ] **Step 3: Run RED**

```bash
/usr/local/bin/Rscript tests/figureforge/test_distribution_validation.R
```

Expected: non-zero exit because `distribution_validation.R` is absent.

- [ ] **Step 4: Implement the constrained metadata parser and validator**

Define these public functions:

```r
parse_simple_metadata <- function(path) {
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  lines <- trimws(lines)
  lines <- lines[nzchar(lines) & !startsWith(lines, "#")]
  pairs <- strsplit(lines, ":", fixed = TRUE)
  invalid <- lengths(pairs) < 2L
  if (any(invalid)) stop("Invalid metadata line: ", lines[which(invalid)[1]])
  keys <- trimws(vapply(pairs, `[[`, character(1), 1L))
  values <- trimws(vapply(
    pairs,
    function(parts) paste(parts[-1L], collapse = ":"),
    character(1)
  ))
  if (anyDuplicated(keys)) stop("Duplicate metadata key")
  stats::setNames(as.list(values), keys)
}

supported_public_licenses <- function() {
  c("CC0-1.0", "MIT", "BSD-3-Clause", "public-domain",
    "generated-by-FigureForge")
}
```

`validate_distribution(case_dir)` returns `ok`, `status`,
`synthetic_test_fixture`, `checks`, `failed_checks`, and `assets`. It checks
all required keys, exact `public_ready`, recognized license, every regular file
in the case directory in the pipe-separated allowlist, no allowlisted file
missing, generated data disclosure, `scientific_claims: none`, and
`qa.md` not containing `Status: verified`.

- [ ] **Step 5: Implement and test the CLI**

`validate_distribution.R <case_dir> [--format text|csv]` prints every check and
exits non-zero on failure. Extend the test to invoke the CLI for the valid and
rights-unknown fixtures.

Run:

```bash
/usr/local/bin/Rscript tests/figureforge/test_distribution_validation.R
```

Expected: `distribution validation tests: PASS`.

- [ ] **Step 6: Run common verification and commit**

```bash
git add tests/figureforge/test_distribution_validation.R \
  tests/fixtures/figureforge/distribution \
  skills/figureforge/lib/distribution_validation.R \
  skills/figureforge/scripts/validate_distribution.R
git commit -m "feat: enforce public asset distribution contract"
```

### Task 2: Define Machine-Readable Public Case Metadata

**Files:**

- Create: `skills/figureforge/schemas/case-schema-v1.md`
- Create: `skills/figureforge/schemas/public-case-taxonomy.csv`
- Create: `skills/figureforge/lib/metadata.R`
- Create: `tests/figureforge/test_public_metadata.R`
- Create: `tests/fixtures/figureforge/metadata/valid/case.yml`
- Create: `tests/fixtures/figureforge/metadata/invalid/case.yml`

- [ ] **Step 1: Write the failing metadata test**

The valid fixture uses:

```yaml
schema_version: 1
case_id: public-scatter-fit
title_en: Scatter plot with fitted trend
title_zh: 带拟合趋势的散点图
chart_family: scatter
chart_subfamily: fitted_scatter
aliases_en: scatter|regression|trend
aliases_zh: 散点图|拟合图|回归趋势
scientific_intents: association|trend
required_roles: x:numeric:continuous|y:numeric:continuous
optional_roles: group:character:categorical|label:character:categorical
annotations: fitted_line|confidence_band
layouts: single_panel|faceted
required_packages: ggplot2
optional_packages: ggrepel
qa_status: review_required
distribution_status: public_ready
synthetic_test_fixture: true
```

Assert:

```r
metadata <- read_case_metadata(file.path(fixtures, "valid"))
stopifnot(identical(metadata$case_id, "public-scatter-fit"))
stopifnot(identical(metadata$chart_family, "scatter"))
stopifnot(length(metadata$required_roles) == 2L)
stopifnot(isTRUE(validate_case_metadata(metadata)$ok))
stopifnot(!isTRUE(validate_case_metadata(
  read_case_metadata(file.path(fixtures, "invalid"))
)$ok))
```

- [ ] **Step 2: Run RED**

```bash
/usr/local/bin/Rscript tests/figureforge/test_public_metadata.R
```

Expected: non-zero because `metadata.R` is absent.

- [ ] **Step 3: Implement metadata parsing**

Define:

```r
read_case_metadata <- function(case_dir)
parse_role_spec <- function(value)
validate_case_metadata <- function(metadata)
build_public_catalog <- function(public_cases_dir)
```

`parse_role_spec()` converts
`x:numeric:continuous|group:character:categorical` into a data frame with
`role`, `type`, and `cardinality`. Validation rejects an unknown taxonomy
family, schema versions other than `1`, missing bilingual fields, duplicate
roles, `verified` QA, non-public distribution, or missing synthetic
disclosure.

- [ ] **Step 4: Write the schema and taxonomy**

`public-case-taxonomy.csv` contains:

```csv
family,subfamily,title_en,title_zh
bar,grouped_stacked,Grouped or stacked bar,分组或堆积柱状图
distribution,box_violin_raincloud,Distribution comparison,箱线小提琴或雨云图
scatter,fitted_scatter,Fitted scatter,散点拟合图
time_series,uncertainty_band,Time series with uncertainty,带不确定性的时序图
heatmap,correlation,Correlation heatmap,相关性热图
enrichment,bubble,Enrichment bubble,富集气泡图
omics,volcano,Volcano plot,火山图
network,node_edge,Node edge network,节点边网络图
survival,kaplan_meier,Kaplan Meier curve,生存曲线
tree,phylogeny_annotation,Annotated phylogeny,带注释进化树
gene_structure,feature_track,Gene feature track,基因结构图
composition,multi_panel,Multi panel composition,多面板组合图
```

`case-schema-v1.md` documents the exact keys, separators, value types, and
forward-compatibility rule: unknown schema versions fail closed.

- [ ] **Step 5: Run GREEN, common verification, and commit**

```bash
/usr/local/bin/Rscript tests/figureforge/test_public_metadata.R
git add skills/figureforge/schemas \
  skills/figureforge/lib/metadata.R \
  tests/figureforge/test_public_metadata.R \
  tests/fixtures/figureforge/metadata
git commit -m "feat: define public case metadata schema"
```

### Task 3: Author the First Six Public Cases

**Files:**

- Create: `skills/figureforge/public-cases/public-bar-grouped/*`
- Create: `skills/figureforge/public-cases/public-distribution-raincloud/*`
- Create: `skills/figureforge/public-cases/public-scatter-fit/*`
- Create: `skills/figureforge/public-cases/public-timeseries-band/*`
- Create: `skills/figureforge/public-cases/public-correlation-heatmap/*`
- Create: `skills/figureforge/public-cases/public-enrichment-bubble/*`
- Create: `skills/figureforge/scripts/validate_public_case.R`
- Create: `tests/figureforge/test_public_cases.R`

- [ ] **Step 1: Write failing public-case assertions**

The test defines the expected IDs:

```r
first_wave <- c(
  "public-bar-grouped",
  "public-distribution-raincloud",
  "public-scatter-fit",
  "public-timeseries-band",
  "public-correlation-heatmap",
  "public-enrichment-bubble"
)
```

For every ID, assert that metadata and distribution validation pass, QA is
`review_required`, `data.csv` is non-empty, the script contains the standard
two-argument contract, a fresh PDF render outside the case directory is
non-empty, and source file checksums and mtimes remain unchanged.

- [ ] **Step 2: Run RED**

```bash
/usr/local/bin/Rscript tests/figureforge/test_public_cases.R
```

Expected: failure listing the six absent public cases.

- [ ] **Step 3: Author deterministic generated datasets**

Use seeds `1101` through `1106`. Each `data.csv` is tracked and each
`case.md` states:

```markdown
## Data Provenance

This dataset was generated by FigureForge for demonstration and adaptation
testing. It is not an observation from a real study and supports no scientific
claim.
```

Use these schemas:

```text
public-bar-grouped: treatment, response, condition
public-distribution-raincloud: group, value, sample_id
public-scatter-fit: predictor, response, group, label
public-timeseries-band: time, estimate, lower, upper, group
public-correlation-heatmap: variable_x, variable_y, correlation
public-enrichment-bubble: term, gene_ratio, adjusted_p, count, category
```

- [ ] **Step 4: Author case-specific ggplot2 scripts**

Every script begins with:

```r
args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 2L) stop("Usage: plot.R <input.csv> <output>")
input_path <- args[[1]]
output_path <- args[[2]]
if (!file.exists(input_path)) stop("Input file does not exist: ", input_path)
if (!requireNamespace("ggplot2", quietly = TRUE)) {
  stop("Required R package is missing: ggplot2")
}
```

Each script validates its declared columns and values, creates the output
parent directory, uses only its generated input, and calls `ggplot2::ggsave()`
with explicit width, height, units, and device inferred from the extension.
Implement the six distinct geometries rather than a shared generic scaffold.

- [ ] **Step 5: Implement `validate_public_case.R`**

The CLI composes metadata, distribution, existing structural validation, and
fresh-render checks:

```bash
/usr/local/bin/Rscript skills/figureforge/scripts/validate_public_case.R \
  "<case_dir>" --render --output "<external.pdf>"
```

It must reject outputs inside the case directory. It must not call the
existing completion validator because a distributable public case remains
`review_required` until a human records visual review.

- [ ] **Step 6: Run GREEN, common verification, and commit**

```bash
/usr/local/bin/Rscript tests/figureforge/test_public_cases.R
git add skills/figureforge/public-cases \
  skills/figureforge/scripts/validate_public_case.R \
  tests/figureforge/test_public_cases.R
git commit -m "feat: add first public FigureForge gallery wave"
```

### Task 4: Author the Remaining Six Public Cases

**Files:**

- Create: `skills/figureforge/public-cases/public-volcano/*`
- Create: `skills/figureforge/public-cases/public-network/*`
- Create: `skills/figureforge/public-cases/public-survival/*`
- Create: `skills/figureforge/public-cases/public-phylogeny-annotation/*`
- Create: `skills/figureforge/public-cases/public-gene-structure/*`
- Create: `skills/figureforge/public-cases/public-multipanel/*`
- Modify: `tests/figureforge/test_public_cases.R`

- [ ] **Step 1: Extend the expected IDs and run RED**

Add:

```r
second_wave <- c(
  "public-volcano",
  "public-network",
  "public-survival",
  "public-phylogeny-annotation",
  "public-gene-structure",
  "public-multipanel"
)
stopifnot(setequal(
  basename(list.dirs(public_cases_dir, recursive = FALSE)),
  c(first_wave, second_wave)
))
```

Run the public-case test and expect failure for all six absent IDs.

- [ ] **Step 2: Author generated data with seeds 1107 through 1112**

Use these schemas:

```text
public-volcano: feature, log2_fold_change, adjusted_p, class
public-network: node_id, node_label, x, y, group plus edge rows source,target
public-survival: group, time, survival, lower, upper
public-phylogeny-annotation: node,parent,x,y,label,clade,is_tip
public-gene-structure: gene, feature, start, end, strand, track
public-multipanel: panel, x, y, group, lower, upper
```

For the network case, store nodes and edges in one CSV with a `record_type`
column so the standard single-input contract remains true.

- [ ] **Step 3: Author six distinct scripts**

Implement network and phylogeny using supplied deterministic coordinates and
`geom_segment()` plus `geom_point()`/`geom_text()`. Implement survival from
precomputed synthetic step estimates, gene structure with segments and
rectangles, volcano with threshold classification, and multi-panel composition
with facets. Do not require igraph, ape, survival, patchwork, or other optional
packages for core rendering.

- [ ] **Step 4: Run GREEN, render all 12, and commit**

```bash
/usr/local/bin/Rscript tests/figureforge/test_public_cases.R
git add skills/figureforge/public-cases \
  tests/figureforge/test_public_cases.R
git commit -m "feat: complete public FigureForge gallery"
```

Expected: 12 metadata validations, 12 distribution validations, and 12 fresh
renders pass.

### Task 5: Build the Tracked Public Index

**Files:**

- Modify: `skills/figureforge/lib/metadata.R`
- Modify: `skills/figureforge/scripts/index_cases.R`
- Create: `skills/figureforge/references/public-case-index.csv`
- Create: `tests/figureforge/test_public_index.R`

- [ ] **Step 1: Write failing deterministic-index assertions**

Assert:

```r
catalog <- build_public_catalog(public_cases_dir)
stopifnot(nrow(catalog) == 12L)
stopifnot(identical(catalog$case_id, sort(catalog$case_id)))
stopifnot(all(catalog$distribution_status == "public_ready"))
stopifnot(all(catalog$synthetic_test_fixture))
stopifnot(!any(grepl("/cases/", catalog$case_path, fixed = TRUE)))
```

Run the index CLI twice into two temporary files and assert identical SHA-256
hashes and equality to the tracked `public-case-index.csv`.

- [ ] **Step 2: Run RED**

Expected: failure because the public-mode index and tracked index do not exist.

- [ ] **Step 3: Add explicit public mode**

Extend the CLI:

```bash
/usr/local/bin/Rscript skills/figureforge/scripts/index_cases.R \
  --public-cases skills/figureforge/public-cases \
  --output skills/figureforge/references/public-case-index.csv
```

Private positional compatibility stays intact. Public mode loads only
`case.yml`, includes schema and distribution fields, excludes absolute
`case_path`, sorts by case ID, and writes UTF-8 deterministically.

- [ ] **Step 4: Generate the tracked index, run GREEN, and commit**

```bash
/usr/local/bin/Rscript skills/figureforge/scripts/index_cases.R \
  --public-cases skills/figureforge/public-cases \
  --output skills/figureforge/references/public-case-index.csv
/usr/local/bin/Rscript tests/figureforge/test_public_index.R
git add skills/figureforge/lib/metadata.R \
  skills/figureforge/scripts/index_cases.R \
  skills/figureforge/references/public-case-index.csv \
  tests/figureforge/test_public_index.R
git commit -m "feat: publish deterministic public case index"
```

### Task 6: Define and Generate 24 Synthetic Stress Fixtures

**Files:**

- Create: `skills/figureforge/lib/stress_fixtures.R`
- Create: `skills/figureforge/scripts/generate_stress_fixtures.R`
- Create: `tests/figureforge/test_stress_fixtures.R`
- Create: `tests/fixtures/figureforge/stress/manifest.csv`
- Create: `tests/fixtures/figureforge/stress/<24 fixture directories>/*`

- [ ] **Step 1: Write the failing manifest test**

Assert:

```r
manifest <- read.csv(manifest_path, stringsAsFactors = FALSE)
stopifnot(nrow(manifest) >= 20L)
stopifnot(all(manifest$synthetic_test_fixture))
stopifnot(all(nzchar(manifest$seed)))
stopifnot(all(unique(public_case_ids) %in% manifest$public_case_id))
stopifnot(all(c("success", "failure") %in% unique(manifest$outcome)))
stopifnot(length(unique(manifest$chart_family)) >= 10L)
```

Also assert every fixture has `fixture.yml`, `input.csv`, and `mapping.csv`,
and that `fixture.yml` contains `scientific_claims: none`.

- [ ] **Step 2: Run RED**

Expected: failure because the stress manifest and generator are absent.

- [ ] **Step 3: Implement the deterministic generator**

Define 24 stable fixtures, two per public case:

```text
bar-renamed-en, bar-chinese-columns
distribution-missing-values, distribution-outliers
scatter-long-labels, scatter-missing-required
timeseries-irregular-dates, timeseries-duplicate-key
heatmap-reordered-factors, heatmap-invalid-correlation
enrichment-sparse-groups, enrichment-zero-p
volcano-large-input, volcano-negative-p
network-chinese-labels, network-unknown-node
survival-imbalanced-groups, survival-invalid-probability
phylogeny-reordered-nodes, phylogeny-missing-parent
gene-negative-coordinate, gene-overlapping-features
multipanel-many-facets, multipanel-missing-optional
```

Seeds are `2101` through `2124`. Expected-success fixtures include their
field mapping. Expected-failure fixtures include one stable failure category:
`missing_required_role`, `duplicate_key`, `invalid_value`,
`ambiguous_mapping`, or `referential_integrity`.

The generator refuses a non-empty output directory and writes only under its
explicit target.

- [ ] **Step 4: Generate fixtures twice and prove determinism**

Generate into two temporary roots and compare recursive file hashes. Then
generate the tracked fixtures once:

```bash
/usr/local/bin/Rscript \
  skills/figureforge/scripts/generate_stress_fixtures.R \
  --output tests/fixtures/figureforge/stress
```

- [ ] **Step 5: Run GREEN, common verification, and commit**

```bash
/usr/local/bin/Rscript tests/figureforge/test_stress_fixtures.R
git add skills/figureforge/lib/stress_fixtures.R \
  skills/figureforge/scripts/generate_stress_fixtures.R \
  tests/figureforge/test_stress_fixtures.R \
  tests/fixtures/figureforge/stress
git commit -m "test: add synthetic adaptation stress corpus"
```

### Task 7: Execute Stress Adaptations Without Mutating Sources

**Files:**

- Create: `skills/figureforge/lib/stress_runner.R`
- Create: `skills/figureforge/scripts/run_stress_tests.R`
- Modify: `tests/figureforge/test_stress_fixtures.R`

- [ ] **Step 1: Write failing runner assertions**

Capture checksums and mtimes for `public-cases/` and `stress/`, run all 24
scenarios into a temporary output root, and assert:

```r
stopifnot(nrow(results) == 24L)
stopifnot(all(results$observed_outcome == results$expected_outcome))
stopifnot(all(results$passed))
stopifnot(all(results$synthetic_test_fixture))
stopifnot(all(success_outputs_are_nonempty))
stopifnot(identical(source_hashes_before, source_hashes_after))
stopifnot(identical(source_mtimes_before, source_mtimes_after))
```

- [ ] **Step 2: Run RED**

Expected: non-zero because `stress_runner.R` is absent.

- [ ] **Step 3: Implement exact mapping and failure categories**

`run_stress_fixture()` reads `mapping.csv`, rewrites a temporary copy of the
case input into canonical role names, validates declared types and special
constraints, invokes the public `plot.R`, and returns:

```r
data.frame(
  fixture_id,
  public_case_id,
  chart_family,
  synthetic_test_fixture,
  expected_outcome,
  observed_outcome,
  failure_category,
  output_path,
  passed,
  stringsAsFactors = FALSE
)
```

The CLI accepts:

```bash
/usr/local/bin/Rscript skills/figureforge/scripts/run_stress_tests.R \
  --fixtures tests/fixtures/figureforge/stress \
  --public-cases skills/figureforge/public-cases \
  --output-dir "<temporary-output>" \
  --report "<temporary-report.csv>"
```

- [ ] **Step 4: Run GREEN, common verification, and commit**

```bash
/usr/local/bin/Rscript tests/figureforge/test_stress_fixtures.R
git add skills/figureforge/lib/stress_runner.R \
  skills/figureforge/scripts/run_stress_tests.R \
  tests/figureforge/test_stress_fixtures.R
git commit -m "feat: run synthetic adaptation stress suite"
```

### Task 8: Build the Safe External Workspace Generator

**Files:**

- Create: `skills/figureforge/lib/workspace_generation.R`
- Create: `skills/figureforge/scripts/create_adaptation.R`
- Create: `tests/figureforge/test_workspace_generation.R`

- [ ] **Step 1: Write protected-path tests first**

Assert that `create_adaptation_workspace()` rejects:

```r
c(
  selected_case_dir,
  file.path(selected_case_dir, "child"),
  dirname(selected_case_dir),
  public_cases_dir,
  file.path(repo_root, "skills", "figureforge", "cases")
)
```

Also assert it rejects a non-empty target, accepts a new external target,
copies only `plot.R` plus user `input.csv`, writes `mapping.md`, `qa.md`, and
`adaptation.yml`, leaves `Status: review_required`, records a script SHA-256,
and preserves source/input hashes and mtimes.

- [ ] **Step 2: Run RED**

```bash
/usr/local/bin/Rscript tests/figureforge/test_workspace_generation.R
```

Expected: failure because `workspace_generation.R` is absent.

- [ ] **Step 3: Implement canonical path safety**

Define:

```r
canonical_candidate_path <- function(path)
path_is_same_or_within <- function(path, root)
validate_workspace_target <- function(
  workspace,
  case_dir,
  protected_roots,
  force_empty = FALSE
)
create_adaptation_workspace <- function(
  case_dir,
  input_path,
  workspace,
  mapping_path = NULL,
  force_empty = FALSE,
  protected_roots = character()
)
```

Resolve existing ancestors before appending non-existing suffixes so `..`,
symlinks, and absent child paths cannot bypass containment checks. Create into
a sibling temporary directory and rename only after all files succeed. Cleanup
may remove only that invocation's temporary directory.

- [ ] **Step 4: Implement CLI and JSON-free provenance**

`adaptation.yml` contains:

```yaml
schema_version: 1
source_case_id: <resolved public case ID>
source_script_sha256: <64 lowercase hex characters>
figureforge_version: <VERSION contents>
qa_status: review_required
input_origin: user-supplied-copy
```

The CLI matches the approved specification. Resolve case IDs only from
`skills/figureforge/public-cases/`.

- [ ] **Step 5: Run GREEN, common verification, and commit**

```bash
/usr/local/bin/Rscript tests/figureforge/test_workspace_generation.R
git add skills/figureforge/lib/workspace_generation.R \
  skills/figureforge/scripts/create_adaptation.R \
  tests/figureforge/test_workspace_generation.R
git commit -m "feat: create protected adaptation workspaces"
```

### Task 9: Add Layered Dependency Doctor

**Files:**

- Create: `skills/figureforge/lib/dependency_doctor.R`
- Create: `skills/figureforge/scripts/doctor.R`
- Create: `tests/figureforge/test_dependency_doctor.R`

- [ ] **Step 1: Write failing classification tests**

Inject detectors so tests do not depend on the host:

```r
fake_runtime <- function() list(found = TRUE, version = "4.5.0")
fake_command <- function(name) name %in% c("sh", "git")
fake_package <- function(name) name %in% c("base", "ggplot2")
report <- run_doctor(
  case_dir = fixture_case,
  runtime_detector = fake_runtime,
  command_detector = fake_command,
  package_detector = fake_package
)
stopifnot(setequal(
  unique(report$layer),
  c("runtime", "system", "required_r_package", "optional_r_package")
))
stopifnot(all(c(
  "check_id", "requirement", "detected_version", "status",
  "remediation", "capability"
) %in% names(report)))
```

Assert a missing optional package is `warning`, a missing required package is
`error`, and strict exit status depends only on errors.

- [ ] **Step 2: Run RED**

Expected: missing dependency doctor library.

- [ ] **Step 3: Implement doctor rows and stable JSON**

Define `doctor_check()`, `run_doctor()`, `doctor_exit_status()`,
`write_doctor_text()`, and `write_doctor_json()`. JSON emission escapes
backslash, quote, newline, carriage return, and tab; rows are ordered by layer
then check ID and include `schema_version: 1`.

Core checks are R >= 4.1, `sh`, `git`, and required packages. `pdfinfo` and
`pdftoppm` are optional visual-QA capabilities. Package installation is never
attempted.

- [ ] **Step 4: Test the CLI**

Run text and JSON modes:

```bash
/usr/local/bin/Rscript skills/figureforge/scripts/doctor.R --format text
/usr/local/bin/Rscript skills/figureforge/scripts/doctor.R \
  --case public-scatter-fit --format json
```

Parse JSON with Python's standard library in the R test via `system2()` and
assert schema version and stable fields.

- [ ] **Step 5: Run GREEN, common verification, and commit**

```bash
/usr/local/bin/Rscript tests/figureforge/test_dependency_doctor.R
git add skills/figureforge/lib/dependency_doctor.R \
  skills/figureforge/scripts/doctor.R \
  tests/figureforge/test_dependency_doctor.R
git commit -m "feat: diagnose layered FigureForge dependencies"
```

### Task 10: Implement Schema Matching and Bilingual Ranking

**Files:**

- Create: `skills/figureforge/lib/schema_matching.R`
- Create: `skills/figureforge/scripts/match_schema.R`
- Modify: `skills/figureforge/lib/case_catalog.R`
- Modify: `skills/figureforge/scripts/search_cases.R`
- Create: `tests/figureforge/test_schema_matching.R`

- [ ] **Step 1: Write failing schema-match tests**

Use a data profile with Chinese columns:

```r
profile <- data.frame(
  column = c("处理组", "时间", "均值", "下限", "上限"),
  inferred_type = c("character", "numeric", "numeric", "numeric", "numeric"),
  cardinality = c("categorical", rep("continuous", 4)),
  stringsAsFactors = FALSE
)
mapping <- c(
  group = "处理组", time = "时间", estimate = "均值",
  lower = "下限", upper = "上限"
)
match <- match_case_schema(timeseries_metadata, profile, mapping)
stopifnot(identical(match$status, "compatible"))
stopifnot(length(match$missing_required_roles) == 0L)
```

Assert missing required roles are `incompatible`; safe type conversions yield
`partially_compatible`; assumptions are explicit strings.

- [ ] **Step 2: Write bilingual ranking tests**

For paired queries:

```r
paired <- list(
  c("correlation heatmap", "相关性热图"),
  c("time series uncertainty", "时序图 不确定性"),
  c("gene structure", "基因结构图"),
  c("survival curve", "生存曲线")
)
```

Assert each pair returns the same top case, every result includes
`score_id`, `score_alias`, `score_family`, `score_schema`, `score_intent`,
`score_layout`, and `score_readiness`, ties use case ID, and
`distribution_status` is filtered rather than scored.

- [ ] **Step 3: Run RED**

Expected: missing schema matching and score-breakdown APIs.

- [ ] **Step 4: Implement deterministic score components**

Use exact weights:

```r
c(
  exact_id = 100,
  exact_title_or_alias = 80,
  chart_family = 40,
  schema_role = 8,
  scientific_intent = 6,
  annotation_or_layout = 4,
  readiness = 2
)
```

Token matches are Unicode-safe exact normalized tokens. Return all component
scores and `score_total`; do not add a distribution bonus.

- [ ] **Step 5: Add CLI contracts**

`search_cases.R` gains `--public`, `--schema <csv>`, and
`--explain-scores`. `match_schema.R` accepts `--case`, `--input`, optional
`--mapping`, and `--output`, returning a deterministic CSV report.

- [ ] **Step 6: Run GREEN, common verification, and commit**

```bash
/usr/local/bin/Rscript tests/figureforge/test_schema_matching.R
git add skills/figureforge/lib/schema_matching.R \
  skills/figureforge/scripts/match_schema.R \
  skills/figureforge/lib/case_catalog.R \
  skills/figureforge/scripts/search_cases.R \
  tests/figureforge/test_schema_matching.R
git commit -m "feat: rank bilingual schema-aware case matches"
```

### Task 11: Add Non-Authoritative Visual QA

**Files:**

- Create: `skills/figureforge/schemas/visual-qa-report-v1.md`
- Create: `skills/figureforge/lib/visual_qa.R`
- Create: `skills/figureforge/scripts/visual_qa.R`
- Create: `tests/figureforge/test_visual_qa.R`
- Create: `tests/fixtures/figureforge/visual-qa/blank.svg`
- Create: `tests/fixtures/figureforge/visual-qa/nonblank.svg`

- [ ] **Step 1: Write status-safety tests**

Assert:

```r
report <- inspect_visual_output(nonblank_svg)
stopifnot(identical(report$status, "review_required"))
stopifnot(!any(tolower(unlist(report)) == "verified"))

failed <- inspect_visual_output(missing_path)
stopifnot(identical(failed$status, "tool_check_failed"))

qa_before <- tools::md5sum(source_qa)
write_visual_qa_report(report, output_report)
qa_after <- tools::md5sum(source_qa)
stopifnot(identical(qa_before, qa_after))
```

Recursively scan the production visual-QA library and CLI to assert they never
write `Status: verified`.

- [ ] **Step 2: Run RED**

Expected: visual QA library missing.

- [ ] **Step 3: Implement format and structural checks**

Support PDF, PNG, and SVG. Return:

```r
list(
  schema_version = 1L,
  status = "review_required",
  render = list(path, format, bytes, width, height, pages),
  checks = list(),
  reference_comparison = list(),
  manual_review_prompts = character()
)
```

Use `pdfinfo` and `pdftoppm` only when available. SVG blank detection counts
visible drawing elements. PNG checks use dimensions if a decoder is available;
otherwise record `not_applicable`. Tool absence never becomes verified.

- [ ] **Step 4: Implement deterministic JSON report output**

The CLI writes only to the explicit `--report` path, rejects a report inside a
source public case, and never edits `qa.md`. Its only statuses are
`review_required`, `tool_check_failed`, and `not_applicable`.

- [ ] **Step 5: Run GREEN, common verification, and commit**

```bash
/usr/local/bin/Rscript tests/figureforge/test_visual_qa.R
git add skills/figureforge/schemas/visual-qa-report-v1.md \
  skills/figureforge/lib/visual_qa.R \
  skills/figureforge/scripts/visual_qa.R \
  tests/figureforge/test_visual_qa.R \
  tests/fixtures/figureforge/visual-qa
git commit -m "feat: add review-required visual QA assistant"
```

### Task 12: Update the Skill Workflow and Agent Metadata

**Files:**

- Modify: `skills/figureforge/SKILL.md`
- Modify: `skills/figureforge/agents/openai.yaml`
- Modify: `skills/figureforge/references/gallery-index.md`
- Modify: `skills/figureforge/references/adaptation-contract.md`
- Modify: `skills/figureforge/references/qa-checklist.md`
- Create: `tests/figureforge/test_v1_skill_contract.R`

- [ ] **Step 1: Write failing documentation contract tests**

Assert that `SKILL.md` contains the public clean-install flow and commands for
`doctor.R`, public search, `create_adaptation.R`, `match_schema.R`,
`visual_qa.R`, and independent adaptation validation. Assert it states:

```text
synthetic_test_fixture
Status: review_required
never grants verified status
private cases are optional local extensions
MCP is planned and unimplemented
```

Assert `openai.yaml` points only to existing public commands and contains no
MCP Server claim.

- [ ] **Step 2: Run RED**

Expected: missing v1.0 public commands and safety language.

- [ ] **Step 3: Rewrite the primary workflow concisely**

Keep `SKILL.md` under 500 lines. Make the default search root
`skills/figureforge/public-cases`, document an optional explicit private root,
and preserve the sequence: inspect data, search, schema match, doctor, external
workspace, mapping, render, assisted checks, human QA, independent re-render,
report.

- [ ] **Step 4: Align the supporting references**

Update command examples and explicitly distinguish public gallery cases,
synthetic stress fixtures, local private cases, automated checks, and human
verification.

- [ ] **Step 5: Run GREEN, common verification, and commit**

```bash
/usr/local/bin/Rscript tests/figureforge/test_v1_skill_contract.R
git add skills/figureforge/SKILL.md \
  skills/figureforge/agents/openai.yaml \
  skills/figureforge/references/gallery-index.md \
  skills/figureforge/references/adaptation-contract.md \
  skills/figureforge/references/qa-checklist.md \
  tests/figureforge/test_v1_skill_contract.R
git commit -m "docs: teach the public FigureForge v1 workflow"
```

### Task 13: Add Versioning and Public-Only Packaging

**Files:**

- Create: `skills/figureforge/VERSION`
- Create: `LICENSE`
- Create: `CHANGELOG.md`
- Create: `skills/figureforge/lib/release_packaging.R`
- Create: `skills/figureforge/scripts/build_release_manifest.R`
- Create: `skills/figureforge/scripts/package_skill.R`
- Create: `tests/figureforge/test_release_packaging.R`

- [ ] **Step 1: Write failing package-content tests**

Assert version is exactly `1.0.0`. Build a manifest into a temporary directory
and assert:

```r
stopifnot(all(c("path", "sha256", "bytes") %in% names(manifest)))
stopifnot(!any(grepl("skills/figureforge/cases/", manifest$path, fixed = TRUE)))
stopifnot(!any(grepl("reproduction\\.|original\\.", manifest$path)))
stopifnot(!any(grepl("^outputs/|\\.log$|case-index\\.csv$", manifest$path)))
stopifnot(any(manifest$path == "skills/figureforge/SKILL.md"))
stopifnot(sum(grepl(
  "^skills/figureforge/public-cases/[^/]+/distribution.yml$",
  manifest$path
)) == 12L)
```

Build an archive and compare the archive file list exactly with the manifest.

- [ ] **Step 2: Run RED**

Expected: version and packaging APIs are absent.

- [ ] **Step 3: Implement allowlist-based packaging**

Include only:

```text
README.md
README.zh.md
CHANGELOG.md
LICENSE
skills/figureforge/VERSION
skills/figureforge/SKILL.md
skills/figureforge/agents/**
skills/figureforge/lib/**
skills/figureforge/public-cases/**
skills/figureforge/references/**
skills/figureforge/schemas/**
skills/figureforge/scripts/**
skills/figureforge/cases/_template/**
```

Before including a public case, rerun distribution validation and include only
its allowlisted assets. Exclude `references/case-index.csv` because it is a
local private index; include `references/public-case-index.csv`.

- [ ] **Step 4: Write version and changelog**

`VERSION` contains one newline-terminated line:

```text
1.0.0
```

Create a top-level MIT license for the public framework:

```text
MIT License

Copyright (c) 2026 FigureForge contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

`CHANGELOG.md` has a `## 1.0.0 - 2026-07-25` entry listing the public gallery,
synthetic stress suite, workspace safety, doctor, matching/search, visual QA,
and packaging boundaries.

- [ ] **Step 5: Run GREEN, common verification, and commit**

```bash
/usr/local/bin/Rscript tests/figureforge/test_release_packaging.R
git add skills/figureforge/VERSION LICENSE CHANGELOG.md \
  skills/figureforge/lib/release_packaging.R \
  skills/figureforge/scripts/build_release_manifest.R \
  skills/figureforge/scripts/package_skill.R \
  tests/figureforge/test_release_packaging.R
git commit -m "feat: package FigureForge Skill v1.0 safely"
```

### Task 14: Add a Clean Public Demo

**Files:**

- Create: `examples/public-demo/README.md`
- Create: `examples/public-demo/generate_input.R`
- Create: `examples/public-demo/run_demo.sh`
- Create: `tests/figureforge/test_public_demo.R`

- [ ] **Step 1: Write the failing demo test**

Copy the repository to a temporary clean tree without private cases or ignored
outputs, run:

```bash
sh examples/public-demo/run_demo.sh "<external-demo-output>"
```

Assert the output contains `input.csv`, `plot.R`, `mapping.md`, `qa.md`,
`adaptation.yml`, `output.pdf`, and `visual-qa.json`; QA remains
`review_required`; validation independently produces a second non-empty PDF.

- [ ] **Step 2: Run RED**

Expected: demo files are absent.

- [ ] **Step 3: Implement the public demo**

`generate_input.R` produces deterministic Chinese-column time-series data with
seed `3101`. `run_demo.sh` uses only repository-relative public commands,
creates `public-timeseries-band` adaptation outside the Skill, renders it,
runs visual QA, and validates the adaptation.

- [ ] **Step 4: Run GREEN, common verification, and commit**

```bash
/usr/local/bin/Rscript tests/figureforge/test_public_demo.R
git add examples/public-demo tests/figureforge/test_public_demo.R
git commit -m "feat: add clean public FigureForge demo"
```

### Task 15: Align English and Chinese Release Documentation

**Files:**

- Modify: `README.md`
- Modify: `README.zh.md`
- Modify: `docs/figureforge-skill-mvp-status.md`
- Create: `docs/figureforge-skill-v1-release.md`
- Create: `tests/figureforge/test_v1_documentation.R`

- [ ] **Step 1: Write failing bilingual documentation assertions**

For both README files, assert the presence of:

```text
1.0.0
12 public cases
24 synthetic stress fixtures
doctor.R
create_adaptation.R
match_schema.R
visual_qa.R
package_skill.R
review_required
private corpus
MCP
planned
```

Use the corresponding Chinese phrases in the Chinese README and assert every
copyable command references an existing file.

- [ ] **Step 2: Run RED**

Expected: v1.0 install, upgrade, demo, and package text is absent.

- [ ] **Step 3: Update documentation**

Document installation by copying `skills/figureforge` into a Codex Skill
directory or using the packaged archive; show upgrade as replacing the whole
versioned directory after preserving user adaptations outside it. Include
doctor, bilingual search, schema match, workspace generation, rendering,
visual QA, validation, demo, and package commands.

State clearly that all shipped datasets are synthetic fixtures, the private
165-case corpus is not distributed, automated QA cannot verify a figure, and
MCP remains planned and absent.

- [ ] **Step 4: Write the release status**

`docs/figureforge-skill-v1-release.md` records the 12 case IDs, 24 fixture IDs,
family coverage, public/private boundary, test commands, archive contents, and
future MCP input contracts. Do not include generated local paths that cannot
exist in a clean clone.

- [ ] **Step 5: Run GREEN, common verification, and commit**

```bash
/usr/local/bin/Rscript tests/figureforge/test_v1_documentation.R
git add README.md README.zh.md docs/figureforge-skill-mvp-status.md \
  docs/figureforge-skill-v1-release.md \
  tests/figureforge/test_v1_documentation.R
git commit -m "docs: publish FigureForge Skill v1.0 guidance"
```

### Task 16: Prove Clean-Clone End-to-End Acceptance

**Files:**

- Create: `tests/figureforge/test_v1_acceptance.R`
- Create: `scripts/verify_figureforge_v1.sh`
- Modify: `docs/figureforge-skill-v1-release.md`

- [ ] **Step 1: Write the acceptance test before the verifier**

The test creates a temporary local clone from the current repository, checks
out the current branch, confirms the private corpus is absent, and invokes the
not-yet-created verifier. It asserts a zero exit and the final line:

```text
FigureForge Skill v1.0 acceptance: PASS
```

- [ ] **Step 2: Run RED**

```bash
/usr/local/bin/Rscript tests/figureforge/test_v1_acceptance.R
```

Expected: failure because `scripts/verify_figureforge_v1.sh` is absent.

- [ ] **Step 3: Implement the end-to-end verifier**

The script runs, in order:

```text
all FigureForge R tests
all public case distribution validations
all 12 external renders
all 24 stress scenarios
doctor text and JSON
paired bilingual searches
one schema match
one protected-path negative test
the public demo
visual QA status checks
independent adaptation validation
release manifest generation
archive packaging and file-list comparison
R parsing for every public R file
official quick_validate.py
git diff --check
```

All generated files go under a `mktemp -d` root removed by a shell trap. The
script reads `/usr/local/bin/Rscript` explicitly and fails on the first
unexpected result.

- [ ] **Step 4: Run acceptance in the working tree**

```bash
sh scripts/verify_figureforge_v1.sh
```

Expected final line: `FigureForge Skill v1.0 acceptance: PASS`.

- [ ] **Step 5: Run the test from a clean local clone**

```bash
/usr/local/bin/Rscript tests/figureforge/test_v1_acceptance.R
```

Expected: `v1 acceptance tests: PASS`.

- [ ] **Step 6: Record exact acceptance evidence**

Update `docs/figureforge-skill-v1-release.md` with the verifier command,
date, case count, fixture count, test count, archive manifest count, and final
PASS line. Do not commit the archive, renders, or temporary clone.

- [ ] **Step 7: Run final verification and inspect the candidate commit**

```bash
sh scripts/verify_figureforge_v1.sh
git diff --check
git status --short
git diff --name-only
```

Confirm no path under the private corpus, `outputs/`, temporary roots, or local
case index appears.

- [ ] **Step 8: Commit locally without pushing**

```bash
git add scripts/verify_figureforge_v1.sh \
  tests/figureforge/test_v1_acceptance.R \
  docs/figureforge-skill-v1-release.md
git commit -m "test: certify FigureForge Skill v1.0 release"
```

### Task 17: Final Requirement-by-Requirement Audit

**Files:**

- Modify only if evidence differs:
  `docs/figureforge-skill-v1-release.md`

- [ ] **Step 1: Build an acceptance matrix**

For every explicit item in the approved design, record the authoritative file
or command output proving it. Mark missing or indirect evidence as incomplete
and return to the owning task.

- [ ] **Step 2: Inspect repository truth**

```bash
git status --short --branch
git log --oneline d5934f4..HEAD
git ls-files skills/figureforge/public-cases
git ls-files tests/fixtures/figureforge/stress
git ls-files | rg \
  'skills/figureforge/cases/[^_]|reproduction\\.|original\\.|outputs/'
```

Expected: clean branch; clear local stage commits; 12 public cases; 24 stress
fixtures; no private, reproduction, original, or generated-output files.

- [ ] **Step 3: Re-run the clean-clone verifier**

```bash
sh scripts/verify_figureforge_v1.sh
```

Do not claim completion unless it exits zero and every row in the acceptance
matrix has direct evidence.

- [ ] **Step 4: Create the final local documentation commit only if needed**

```bash
git add docs/figureforge-skill-v1-release.md
git commit -m "docs: finalize FigureForge Skill v1.0 release evidence"
```

Do not push. Report all local commit IDs, public case IDs, stress fixture IDs,
coverage, verification results, ignored evidence locations, and the planned
MCP input boundary.
