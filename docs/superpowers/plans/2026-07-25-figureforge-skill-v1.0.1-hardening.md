# FigureForge Skill v1.0.1 Hardening Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> `superpowers:subagent-driven-development` (recommended) or
> `superpowers:executing-plans` to implement this plan task-by-task. Steps use
> checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship FigureForge Skill v1.0.1 as a directly installable,
cross-platform, bilingual-evaluated standalone Skill with three authentic
open-data cases and reproducible release certification.

**Architecture:** Keep `skills/figureforge/` as source authority and map its
allowlisted runtime files to an installed `figureforge/` archive root. Add a
single Rscript resolver used by public CLIs, extend distribution validation
with a fail-closed authentic-source contract, and keep deterministic
evaluations separate from bounded live Codex trigger probes. Preserve the
v1.0.0 public API and private-corpus boundary.

**Tech Stack:** Base R, ggplot2, constrained YAML-like metadata, CSV,
POSIX shell, `/usr/bin/python3`, tar, Codex CLI 0.145 or newer, Git.

---

## File Map

```text
skills/figureforge/
├── VERSION                                      # 1.0.1 release version
├── SKILL.md                                     # trigger-tested workflow
├── agents/openai.yaml                           # trigger-tested UI metadata
├── lib/
│   ├── runtime_resolution.R                     # shared Rscript resolver
│   ├── skill_paths.R                            # source/install root resolver
│   ├── checksums.R                              # portable shared SHA-256
│   ├── dependency_doctor.R                      # resolved runtime reporting
│   ├── distribution_validation.R                # synthetic/authentic gate
│   ├── forward_evaluation.R                     # deterministic eval engine
│   └── release_packaging.R                      # install mapping/checksums
├── scripts/
│   ├── evaluate_skill.R                         # deterministic eval CLI
│   ├── verify_release.R                         # manifest/archive verifier
│   └── existing CLIs                            # --rscript integration
├── references/
│   ├── public-case-index.csv                    # 15-case catalog
│   └── trigger-evals-v1.csv                     # bilingual eval definitions
└── public-cases/
    ├── authentic-palmer-penguins-scatter/
    ├── authentic-usgs-earthquakes-bubble/
    └── authentic-world-bank-population-timeseries/
        ├── case.md
        ├── case.yml
        ├── data.csv
        ├── distribution.yml
        ├── plot.R
        ├── qa.md
        └── source.yml

tests/figureforge/
├── test_runtime_resolution.R
├── test_authentic_distribution.R
├── test_authentic_public_cases.R
├── test_forward_evaluation.R
├── test_release_packaging.R
├── test_install_smoke.R
├── test_upgrade_compatibility.R
└── test_v101_documentation.R

scripts/
├── verify_figureforge_v101.sh
└── run_figureforge_live_evals.sh

docs/
└── figureforge-skill-v1.0.1-release.md
```

All generated archives, manifests, rendered outputs, extracted installations,
live-evaluation transcripts, and logs go to temporary or ignored output
directories.

## Common Verification

After each GREEN step, run the focused test and:

```bash
for test_file in tests/figureforge/*.R; do
  /usr/local/bin/Rscript "$test_file"
done

find skills/figureforge tests/figureforge examples/public-demo \
  -type f -name '*.R' -print | sort |
while IFS= read -r r_file; do
  /usr/local/bin/Rscript -e "parse(file='$r_file')" >/dev/null
done

/usr/bin/python3 \
  /Users/liuyue/.codex/skills/.system/skill-creator/scripts/quick_validate.py \
  skills/figureforge

git diff --check
```

Expected: every test ends in `PASS`, parse and Skill validation exit zero,
and `git diff --check` prints nothing.

### Task 1: Installation-Shaped Release Package

**Files:**

- Modify: `skills/figureforge/lib/release_packaging.R`
- Create: `skills/figureforge/lib/skill_paths.R`
- Create: `skills/figureforge/lib/checksums.R`
- Modify: `skills/figureforge/scripts/build_release_manifest.R`
- Modify: `skills/figureforge/scripts/package_skill.R`
- Modify: installed runtime CLIs under `skills/figureforge/scripts/`
- Modify: `tests/figureforge/test_release_packaging.R`
- Create: `tests/figureforge/test_install_smoke.R`

- [ ] **Step 1: Write the failing source-to-package mapping test**

Append assertions that require manifest columns
`source_path`, `package_path`, `sha256`, and `bytes`, require every package
path to begin with `figureforge/`, and require:

```r
stopifnot(any(manifest$package_path == "figureforge/SKILL.md"))
stopifnot(any(manifest$package_path ==
  "figureforge/examples/public-demo/run_demo.sh"))
stopifnot(!any(startsWith(manifest$package_path, "skills/")))
stopifnot(!anyDuplicated(manifest$package_path))
```

The install smoke test must extract the archive beneath
`<temp>/.agents/skills` and assert:

```r
installed <- file.path(skill_root, "figureforge")
stopifnot(file.exists(file.path(installed, "SKILL.md")))
stopifnot(file.exists(file.path(installed, "agents", "openai.yaml")))
stopifnot(file.exists(file.path(
  installed, "examples", "public-demo", "run_demo.sh"
)))
stopifnot(!dir.exists(file.path(installed, "skills")))
```

- [ ] **Step 2: Write a failing installed-path execution test**

From the extracted package, run:

```r
run_installed <- function(script, args = character(0)) {
  system2(
    "/usr/local/bin/Rscript",
    c(shQuote(file.path(installed, "scripts", script)), shQuote(args)),
    stdout = TRUE,
    stderr = TRUE
  )
}
command_ok <- function(output) {
  status <- attr(output, "status")
  is.null(status) || identical(as.integer(status), 0L)
}
stopifnot(command_ok(run_installed("doctor.R", "--format text")))
stopifnot(command_ok(run_installed(
  "search_cases.R",
  c("--public", "--query", "scatter", "--limit", "1")
)))
```

The packaged demo must also exit zero and write two non-empty PDF files outside
the installed directory.

- [ ] **Step 3: Run RED**

```bash
/usr/local/bin/Rscript tests/figureforge/test_release_packaging.R
/usr/local/bin/Rscript tests/figureforge/test_install_smoke.R
```

Expected: the packaging test fails because `package_path` is absent; the
smoke test fails because extraction produces repository-relative paths and
installed scripts search for a source checkout.

- [ ] **Step 4: Implement explicit path mapping**

Add:

```r
release_package_path <- function(source_path) {
  source_path <- release_normalize_relative(source_path)
  if (startsWith(source_path, "skills/figureforge/")) {
    return(sub("^skills/figureforge/", "figureforge/", source_path))
  }
  if (startsWith(source_path, "examples/public-demo/")) {
    return(sub(
      "^examples/public-demo/",
      "figureforge/examples/public-demo/",
      source_path
    ))
  }
  stop("No install mapping for release source: ", source_path)
}
```

Limit candidate sources to Skill runtime files and the public demo. Build the
manifest as:

```r
data.frame(
  source_path = paths,
  package_path = vapply(paths, release_package_path, character(1)),
  sha256 = vapply(absolute, figureforge_sha256, character(1)),
  bytes = as.numeric(file.info(absolute)$size),
  stringsAsFactors = FALSE
)
```

Create a staging directory, copy each `source_path` to its `package_path`,
and tar from the staging root. Do not mutate source files.

Move portable hashing behind `figureforge_sha256(path)` in `checksums.R`.
Resolve `sha256sum`, then `shasum -a 256`, then `/usr/bin/python3` with
`hashlib.sha256`; require a lowercase 64-character result. Source this helper
from release packaging.

- [ ] **Step 5: Make runtime CLIs source/install location-independent**

Implement:

```r
figureforge_skill_root <- function(script_path) {
  candidate <- normalizePath(
    file.path(dirname(script_path), ".."),
    mustWork = TRUE
  )
  if (!file.exists(file.path(candidate, "SKILL.md"))) {
    stop("Unable to resolve FigureForge Skill root from: ", script_path)
  }
  candidate
}

figureforge_repo_root <- function(skill_root) {
  candidate <- normalizePath(
    file.path(skill_root, "..", ".."),
    mustWork = TRUE
  )
  if (identical(
    normalizePath(file.path(candidate, "skills", "figureforge")),
    normalizePath(skill_root)
  )) candidate else NULL
}
```

Each installed runtime CLI derives `skill_root` from its own
`skills/figureforge/scripts/<name>.R` path, sources libraries from
`file.path(skill_root, "lib", ...)`, and resolves public cases from
`file.path(skill_root, "public-cases")`. Repository-only commands may require
`figureforge_repo_root(skill_root)` and must fail clearly when invoked from an
installed package.

- [ ] **Step 6: Make the packaged demo location-independent**

Derive the Skill root from the installed demo directory:

```sh
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
SKILL_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)
```

Replace source-tree paths with `$SKILL_ROOT/scripts/...` and
`$SKILL_ROOT/public-cases/...`. Accept runtime as:

```sh
RSCRIPT=${FIGUREFORGE_RSCRIPT:-Rscript}
```

The shared resolver in Task 2 will later replace this interim selection.

- [ ] **Step 7: Run GREEN and full verification**

Run both focused tests and Common Verification. Confirm archive members equal
sorted `manifest$package_path` and the installed demo writes only to its
external output argument.

- [ ] **Step 8: Commit**

```bash
git add skills/figureforge/lib/release_packaging.R \
  skills/figureforge/lib/skill_paths.R \
  skills/figureforge/lib/checksums.R \
  skills/figureforge/scripts/build_release_manifest.R \
  skills/figureforge/scripts/package_skill.R \
  skills/figureforge/scripts \
  examples/public-demo \
  tests/figureforge/test_release_packaging.R \
  tests/figureforge/test_install_smoke.R
git commit -m "feat: package FigureForge as an installable skill"
```

### Task 2: Shared Cross-Platform Rscript Resolution

**Files:**

- Create: `skills/figureforge/lib/runtime_resolution.R`
- Modify: `skills/figureforge/lib/dependency_doctor.R`
- Modify: `skills/figureforge/scripts/doctor.R`
- Modify: every public CLI that accepts or launches Rscript
- Modify: `examples/public-demo/run_demo.sh`
- Create: `tests/figureforge/test_runtime_resolution.R`
- Modify: `tests/figureforge/test_dependency_doctor.R`

- [ ] **Step 1: Write resolver priority and failure tests**

Use injected functions so tests do not alter the host:

```r
fake_probe <- function(path) {
  versions <- c(
    "/cli/Rscript" = "R scripting front-end version 4.5.0",
    "/env/Rscript" = "R scripting front-end version 4.4.2",
    "/usr/local/bin/Rscript" = "R scripting front-end version 4.3.3",
    "/path/Rscript" = "R scripting front-end version 4.2.1"
  )
  list(
    exists = path %in% names(versions),
    executable = path %in% names(versions),
    version_output = unname(versions[[path]] %||% ""),
    status = if (path %in% names(versions)) 0L else 1L
  )
}
```

Assert CLI wins over environment, environment wins over Homebrew compatibility,
Homebrew wins over PATH, and absent runtime fails with all attempted sources
named. Assert an explicitly invalid CLI or environment path does not fall
back.

- [ ] **Step 2: Run RED**

```bash
/usr/local/bin/Rscript tests/figureforge/test_runtime_resolution.R
```

Expected: FAIL because `runtime_resolution.R` does not exist.

- [ ] **Step 3: Implement the resolver**

Implement:

```r
resolve_rscript <- function(
  cli_path = NULL,
  env = Sys.getenv("FIGUREFORGE_RSCRIPT", unset = ""),
  homebrew_path = "/usr/local/bin/Rscript",
  path_lookup = function(name) unname(Sys.which(name)),
  probe = probe_rscript
)
```

Return:

```r
list(
  path = normalized_absolute_path,
  source = c("cli", "environment", "homebrew_compat", "path")[[1L]],
  version = "4.5.0",
  version_output = raw_version_line
)
```

Implement `probe_rscript()` with `file.exists`, access mode `1`, and
`system2(path, "--version")`. Reject versions below 4.1.

- [ ] **Step 4: Integrate doctor**

Extend `doctor_check()` and reports with `detected_path` and
`resolution_source`. Change:

```r
run_doctor <- function(
  case_dir = NULL,
  rscript = NULL,
  runtime_resolver = resolve_rscript,
  command_detector = default_command_detector,
  package_detector = default_package_detector
)
```

Add `--rscript` to `doctor.R` and pass the value to `run_doctor()`.

- [ ] **Step 5: Integrate public subprocess CLIs**

Source `runtime_resolution.R`, default CLI `rscript` to `NULL`, then call:

```r
runtime <- resolve_rscript(cli_path = options$rscript)
```

Pass `runtime$path` to every `system2` or nested render call. Preserve existing
`--rscript` syntax. Update shell entry points to resolve:

```sh
if [ -n "${FIGUREFORGE_RSCRIPT:-}" ]; then
  RSCRIPT=$FIGUREFORGE_RSCRIPT
elif [ -x /usr/local/bin/Rscript ]; then
  RSCRIPT=/usr/local/bin/Rscript
else
  RSCRIPT=$(command -v Rscript)
fi
```

- [ ] **Step 6: Run GREEN, host compatibility, and full verification**

```bash
/usr/local/bin/Rscript tests/figureforge/test_runtime_resolution.R
/usr/local/bin/Rscript tests/figureforge/test_dependency_doctor.R
FIGUREFORGE_RSCRIPT=/usr/local/bin/Rscript \
  /usr/local/bin/Rscript skills/figureforge/scripts/doctor.R --strict
```

Confirm doctor prints the normalized host path and
`resolution_source=environment` in the configured run.

- [ ] **Step 7: Commit**

```bash
git add skills/figureforge/lib/runtime_resolution.R \
  skills/figureforge/lib/dependency_doctor.R \
  skills/figureforge/scripts examples/public-demo/run_demo.sh \
  tests/figureforge/test_runtime_resolution.R \
  tests/figureforge/test_dependency_doctor.R
git commit -m "feat: resolve FigureForge Rscript portably"
```

### Task 3: Fail-Closed Authentic Distribution Contract

**Files:**

- Modify: `skills/figureforge/lib/distribution_validation.R`
- Modify: `skills/figureforge/lib/checksums.R`
- Modify: `skills/figureforge/lib/metadata.R`
- Modify: `skills/figureforge/scripts/validate_distribution.R`
- Create: `tests/fixtures/figureforge/distribution/authentic-valid/`
- Create: `tests/fixtures/figureforge/distribution/authentic-missing-source/`
- Create: `tests/figureforge/test_authentic_distribution.R`

- [ ] **Step 1: Write authentic fixture tests**

The valid fixture declares:

```yaml
schema_version: 2
distribution_status: public_ready
source_type: authentic_open_data
synthetic_test_fixture: false
scientific_claims: descriptive_only
license: CC0-1.0
assets: case.md|case.yml|data.csv|plot.R|qa.md|distribution.yml|source.yml
```

Its `source.yml` contains all source contract keys and 64-character lowercase
upstream and normalized hashes. Assert it passes. Remove `source.yml` in the
negative fixture and assert failure check `authentic source metadata`.
Assert a synthetic v1 case still passes unchanged.

- [ ] **Step 2: Run RED**

```bash
/usr/local/bin/Rscript tests/figureforge/test_authentic_distribution.R
```

Expected: valid authentic fixture fails because the current validator requires
synthetic data and `scientific_claims: none`.

- [ ] **Step 3: Implement schema-2 branching**

Add `CC-BY-4.0` to supported licenses. Implement:

```r
authentic_source_required_keys <- function() c(
  "schema_version", "source_type", "publisher", "dataset_title",
  "canonical_url", "retrieval_url", "retrieval_date", "upstream_version",
  "upstream_sha256", "normalized_sha256", "license", "license_url",
  "attribution", "selected_fields", "normalization",
  "synthetic_test_fixture", "scientific_claims"
)
```

For synthetic cases, preserve v1 checks exactly. For authentic cases require:

```r
identical(metadata$source_type, "authentic_open_data")
!metadata_flag(metadata$synthetic_test_fixture)
identical(metadata$scientific_claims, "descriptive_only")
identical(source$synthetic_test_fixture, "false")
identical(source$scientific_claims, "descriptive_only")
identical(source$license, metadata$license)
grepl("^[0-9a-f]{64}$", source$upstream_sha256)
grepl("^[0-9a-f]{64}$", source$normalized_sha256)
identical(figureforge_sha256(file.path(case_dir, "data.csv")),
          source$normalized_sha256)
```

Keep the QA rule conditional: authentic may be verified; synthetic must remain
review-required.

`figureforge_sha256()` lives in `checksums.R` and resolves `sha256sum`,
`shasum -a 256`, then `/usr/bin/python3` with `hashlib`. Both distribution and
release packaging source this helper; neither library sources the other.

- [ ] **Step 4: Run GREEN and regression**

Run the focused test, distribution tests, all 12 current public-case tests, and
Common Verification.

- [ ] **Step 5: Commit**

```bash
git add skills/figureforge/lib/distribution_validation.R \
  skills/figureforge/lib/checksums.R \
  skills/figureforge/lib/metadata.R \
  skills/figureforge/scripts/validate_distribution.R \
  tests/fixtures/figureforge/distribution \
  tests/figureforge/test_authentic_distribution.R
git commit -m "feat: validate authentic public case provenance"
```

### Task 4: Three Authentic Open-Data Cases

**Files:**

- Create: three case directories listed in File Map
- Modify: `skills/figureforge/references/public-case-index.csv`
- Modify: `tests/figureforge/test_public_cases.R`
- Create: `tests/figureforge/test_authentic_public_cases.R`

- [ ] **Step 1: Write missing-case and source-hash tests**

Assert the exact case IDs exist, each has seven files, uses
`synthetic_test_fixture: false`, has `source_type:
authentic_open_data`, has `Status: verified`, passes distribution validation,
and renders to an external PDF. Assert all normalized CSV hashes equal the
recorded `normalized_sha256`.

- [ ] **Step 2: Run RED**

```bash
/usr/local/bin/Rscript tests/figureforge/test_authentic_public_cases.R
```

Expected: FAIL because all three case directories are absent.

- [ ] **Step 3: Normalize Palmer Penguins**

Use the reviewed upstream CSV with SHA-256
`f204db2c753b0937caac3cb35258562c14f073e4bbc76be24b4c51ce22767a93`.
Keep complete rows for:

```text
species,bill_length_mm,bill_depth_mm,body_mass_g,sex
```

Write a case-specific `plot.R` that validates those columns and finite numeric
values, then renders points by species with `geom_smooth(method = "lm")`.

- [ ] **Step 4: Normalize USGS earthquakes**

Use the reviewed fixed-query snapshot with SHA-256
`39d0e2be2a0c36784fd7ff8b9335e43fa7583b65dbb3db79ddda65423c55148d`.
Keep:

```text
time,depth,mag,place
```

Parse UTC time, require non-negative depth and finite magnitude, and render
time versus depth with point size and color mapped to magnitude.

- [ ] **Step 5: Normalize World Bank population**

Use the reviewed API response with SHA-256
`0c516b92077b8cb39972a34a3be14230a84adcbed3db921023b9182e9068e9d0`.
Keep:

```text
country_code,country,year,population
```

Require integer years, positive population, and unique country-year keys.
Render population time series by country with readable scientific notation.

- [ ] **Step 6: Record source and human QA**

Each `source.yml` records the exact URLs, hash, license, attribution, selected
fields, and ordered transformations. Each `qa.md` uses:

```markdown
Status: verified

## Data
## Visual Fidelity
## Reproducibility
## Export
## Limits
```

Inspect each fresh PDF for labels, scale direction, legend, clipping,
representative records, and descriptive-only limits before retaining verified
status.

- [ ] **Step 7: Rebuild and validate the 15-case index**

```bash
/usr/local/bin/Rscript skills/figureforge/scripts/index_cases.R \
  skills/figureforge/public-cases \
  skills/figureforge/references/public-case-index.csv
```

Run focused tests and independently render all three cases to a temporary
directory.

- [ ] **Step 8: Commit**

```bash
git add skills/figureforge/public-cases/authentic-* \
  skills/figureforge/references/public-case-index.csv \
  tests/figureforge/test_public_cases.R \
  tests/figureforge/test_authentic_public_cases.R
git commit -m "feat: add authentic public visualization cases"
```

### Task 5: Deterministic Bilingual Forward Evaluations

**Files:**

- Create: `skills/figureforge/references/trigger-evals-v1.csv`
- Create: `skills/figureforge/lib/forward_evaluation.R`
- Create: `skills/figureforge/scripts/evaluate_skill.R`
- Create: `tests/fixtures/figureforge/evaluations/`
- Create: `tests/figureforge/test_forward_evaluation.R`

- [ ] **Step 1: Write evaluator contract tests**

Require exactly 30 rows spanning `zh` and `en`, all three outcomes
`select`, `map_render`, `reject`, and rejection categories:

```text
missing_required_role
incompatible_type
incompatible_cardinality
protected_output
private_asset
unsafe_transformation
```

Assert report fields:

```r
c(
  "eval_id", "language", "outcome", "expected_top1", "actual_top1",
  "top1_pass", "top3_pass", "mapping_pass", "render_pass",
  "rejection_pass", "passed", "details"
)
```

Assert threshold calculation rejects Top-1 below 0.80 or any Top-3, valid
mapping/render, or safe-rejection miss.

- [ ] **Step 2: Run RED**

```bash
/usr/local/bin/Rscript tests/figureforge/test_forward_evaluation.R
```

Expected: FAIL because the evaluation catalog and engine do not exist.

- [ ] **Step 3: Add the 30-row catalog and fixtures**

Use stable IDs `eval-en-001` through `eval-en-015` and `eval-zh-001` through
`eval-zh-015`. Pair equivalent intents where possible. Store only small
synthetic evaluation inputs and mappings under test fixtures; do not duplicate
authentic case data.

- [ ] **Step 4: Implement evaluation layers**

Implement:

```r
read_forward_evaluations <- function(path)
run_forward_evaluation <- function(row, repo_root, output_root, rscript)
summarize_forward_evaluations <- function(report)
forward_thresholds_pass <- function(summary)
```

Call the existing search, schema-matching, adaptation, render, and protected
path functions directly where possible. Require exact rejection categories,
not generic non-zero status.

- [ ] **Step 5: Add CLI**

Support:

```text
evaluate_skill.R
  --catalog PATH
  --output-dir PATH
  --report PATH
  [--rscript PATH]
```

Exit zero only when all hard thresholds pass.

- [ ] **Step 6: Run GREEN and full deterministic suite**

```bash
/usr/local/bin/Rscript skills/figureforge/scripts/evaluate_skill.R \
  --catalog skills/figureforge/references/trigger-evals-v1.csv \
  --output-dir "$(mktemp -d /tmp/figureforge-evals.XXXXXX)" \
  --report /tmp/figureforge-forward-evals.csv \
  --rscript /usr/local/bin/Rscript
```

Expected: 30 rows; Top-1 at least 80%; all hard rates 100%.

- [ ] **Step 7: Commit**

```bash
git add skills/figureforge/references/trigger-evals-v1.csv \
  skills/figureforge/lib/forward_evaluation.R \
  skills/figureforge/scripts/evaluate_skill.R \
  tests/fixtures/figureforge/evaluations \
  tests/figureforge/test_forward_evaluation.R
git commit -m "test: add bilingual FigureForge forward evaluations"
```

### Task 6: Trigger-Test the Skill Instructions

**Files:**

- Create: `scripts/run_figureforge_live_evals.sh`
- Create: `tests/figureforge/test_skill_trigger_contract.R`
- Modify only after RED: `skills/figureforge/SKILL.md`
- Modify only after RED: `skills/figureforge/agents/openai.yaml`

- [ ] **Step 1: Record v1.0.0 trigger baseline before editing the Skill**

Run bounded isolated Codex prompts against an installed v1.0.0 copy:

```text
Explicit: Use $figureforge to inspect this dataset and choose a safe public
case. Return the selected Skill name and the first command you would run.

Implicit: I have a CSV with time, group, estimate, lower, and upper columns.
Help me choose and safely adapt a publication-ready scientific visualization.
Return the capability you selected and the first command you would run.
```

Store raw transcripts under ignored `outputs/figureforge-v101/live-evals/`.
Record whether the Skill was loaded and whether the answer used the installed
path rather than the source worktree.

- [ ] **Step 2: Write the failing trigger-contract test**

Assert the description starts with `Use when`, names data-only scientific
visualization requests and bilingual chart requests, and does not summarize
the full workflow. Assert SKILL.md no longer says every public dataset is
synthetic and does not require a fixed `/usr/local/bin/Rscript`.

- [ ] **Step 3: Run RED**

```bash
/usr/local/bin/Rscript tests/figureforge/test_skill_trigger_contract.R
```

Expected: FAIL on the v1.0.0 all-synthetic and fixed-runtime wording.

- [ ] **Step 4: Make the minimal Skill wording change**

Use frontmatter:

```yaml
---
name: figureforge
description: Use when a user needs to select, reproduce, adapt, render, or QA-check a publication-ready scientific visualization from R/ggplot2 data, including Chinese or English chart requests, ambiguous chart names, data-only prompts, and new-data column mapping.
---
```

State that public cases may be authentic open data or synthetic demonstrations,
that case metadata controls claims and QA, and that commands resolve Rscript
through `--rscript`, `FIGUREFORGE_RSCRIPT`, compatibility path, then `PATH`.
Keep MCP planned and unimplemented.

Regenerate only the required `agents/openai.yaml` interface fields if the
current prompt conflicts with authentic-case or runtime behavior.

- [ ] **Step 5: Run GREEN, official validation, and live probes**

Run the focused contract and official Skill validator. Install the new archive
under an isolated `.agents/skills/`, then run at least one explicit and ten
implicit prompts. Require explicit 100% and implicit at least 90%.

- [ ] **Step 6: Commit**

```bash
git add skills/figureforge/SKILL.md \
  skills/figureforge/agents/openai.yaml \
  scripts/run_figureforge_live_evals.sh \
  tests/figureforge/test_skill_trigger_contract.R
git commit -m "feat: harden FigureForge skill triggering"
```

Do not commit raw live transcripts.

### Task 7: Archive Checksum and Installed Release Verification

**Files:**

- Modify: `skills/figureforge/lib/release_packaging.R`
- Modify: `skills/figureforge/scripts/package_skill.R`
- Create: `skills/figureforge/scripts/verify_release.R`
- Modify: `tests/figureforge/test_release_packaging.R`
- Modify: `tests/figureforge/test_install_smoke.R`

- [ ] **Step 1: Write failing checksum and extracted-byte tests**

Require package output:

```r
stopifnot(file.exists(paste0(archive_path, ".sha256")))
line <- readLines(paste0(archive_path, ".sha256"), warn = FALSE)
stopifnot(grepl(
  paste0("^[0-9a-f]{64}  ", basename(archive_path), "$"),
  line
))
```

Extract the archive, independently hash every `package_path`, and compare it
to the manifest. Add one tampered-file test that must fail verification with
`checksum mismatch`.

- [ ] **Step 2: Run RED**

Run the two focused release tests. Expected: checksum sidecar and verifier are
missing.

- [ ] **Step 3: Implement portable SHA-256 and verifier**

Reuse `figureforge_sha256()` from `checksums.R`; do not implement a second
hashing path. Emit lowercase hashes.

Implement verifier CLI:

```text
verify_release.R
  --archive PATH
  --manifest PATH
  [--extract-dir PATH]
```

Reject missing, extra, duplicate, absolute, parent-traversal, symlink, empty,
or checksum-mismatched members.

- [ ] **Step 4: Run GREEN and clean installed demo**

Build the archive, verify it, extract under a temporary Skill root, run
official validation, doctor, public search, and the packaged demo.

- [ ] **Step 5: Commit**

```bash
git add skills/figureforge/lib/release_packaging.R \
  skills/figureforge/scripts/package_skill.R \
  skills/figureforge/scripts/verify_release.R \
  tests/figureforge/test_release_packaging.R \
  tests/figureforge/test_install_smoke.R
git commit -m "feat: verify FigureForge release archives"
```

### Task 8: v1.0.0-to-v1.0.1 Upgrade Compatibility

**Files:**

- Create: `tests/figureforge/test_upgrade_compatibility.R`
- Create: `tests/fixtures/figureforge/releases/v1.0.0-manifest.csv`
- Modify only after compatibility GREEN: `skills/figureforge/VERSION`

- [ ] **Step 1: Write the failing upgrade test**

Create a v1.0.0 installation from Git commit `fe00d2a` in a temporary export,
create an external adaptation, record its hashes, then install the current
archive over the Skill folder. Assert:

```r
stopifnot(readLines(file.path(installed, "VERSION")) == "1.0.1")
stopifnot(identical(before_input_hash, figureforge_sha256(adaptation_input)))
stopifnot(identical(before_mapping_hash, figureforge_sha256(adaptation_mapping)))
stopifnot(!any(setdiff(v100_package_paths, v101_package_paths) %in%
  installed_relative_files))
```

Rerun doctor, search, adaptation validation, and independent render.

- [ ] **Step 2: Run RED**

```bash
/usr/local/bin/Rscript tests/figureforge/test_upgrade_compatibility.R
```

Expected: FAIL because VERSION is still `1.0.0` and no upgrade cleanup
contract exists.

- [ ] **Step 3: Implement safe replacement in the temporary Skill target**

Stage v1.0.1 beside the installed `figureforge/` directory, validate it, rename
the old directory to a target-specific backup, rename the stage into place,
then remove only that exact backup after success. Roll back on validation
failure. Never target the Skill root, repository root, home directory, or an
unresolved path.

- [ ] **Step 4: Set VERSION and run GREEN**

Change VERSION to exactly:

```text
1.0.1
```

Run the upgrade test, all v1.0 compatibility tests, and Common Verification.

- [ ] **Step 5: Commit**

```bash
git add skills/figureforge/VERSION \
  tests/figureforge/test_upgrade_compatibility.R \
  tests/fixtures/figureforge/releases/v1.0.0-manifest.csv
git commit -m "test: preserve FigureForge v1 upgrade compatibility"
```

### Task 9: Bilingual Documentation and Final v1.0.1 Certification

**Files:**

- Modify: `README.md`
- Modify: `README.zh.md`
- Modify: `CHANGELOG.md`
- Create: `docs/figureforge-skill-v1.0.1-release.md`
- Create: `tests/figureforge/test_v101_documentation.R`
- Create: `scripts/verify_figureforge_v101.sh`

- [ ] **Step 1: Write documentation contract tests**

Require both READMEs and release evidence to agree on:

```text
1.0.1
.agents/skills/figureforge
FIGUREFORGE_RSCRIPT
--rscript
15 public cases
3 authentic open-data cases
12 synthetic demonstration cases
MCP planned and unimplemented
```

Assert neither README advertises an MCP endpoint or says all public data are
synthetic.

- [ ] **Step 2: Run RED**

```bash
/usr/local/bin/Rscript tests/figureforge/test_v101_documentation.R
```

Expected: FAIL because current documents describe v1.0.0, 12 public cases, and
fixed `/usr/local/bin/Rscript`.

- [ ] **Step 3: Update bilingual documentation**

Document direct archive extraction, repository/user Skill roots, discovery,
runtime priority, authentic/synthetic boundaries, evaluation commands,
upgrade behavior, archive verification, and local-only release policy.
Describe MCP only as planned and unimplemented.

- [ ] **Step 4: Build the final verifier**

`verify_figureforge_v101.sh` must:

1. resolve Rscript through `FIGUREFORGE_RSCRIPT`, compatibility path, or PATH;
2. run all FigureForge R tests except its recursive acceptance wrapper;
3. render and validate all 15 public cases externally;
4. run all 24 existing stress fixtures;
5. run all 30 deterministic forward evaluations;
6. run doctor text and JSON;
7. build the archive, manifest, and SHA-256 sidecar;
8. verify and extract the archive;
9. run official Skill validation against the installed copy;
10. run installed doctor, search, demo, and independent rerender;
11. run the v1.0.0 upgrade test;
12. run bounded live trigger probes when
    `FIGUREFORGE_RUN_LIVE_EVALS=1`;
13. parse every public R file;
14. run `git diff --check`;
15. prove private and generated files are absent; and
16. end with `FigureForge Skill v1.0.1 acceptance: PASS`.

- [ ] **Step 5: Run complete acceptance**

```bash
FIGUREFORGE_RSCRIPT=/usr/local/bin/Rscript \
  sh scripts/verify_figureforge_v101.sh
```

Then run the live release gate:

```bash
FIGUREFORGE_RSCRIPT=/usr/local/bin/Rscript \
FIGUREFORGE_RUN_LIVE_EVALS=1 \
  sh scripts/verify_figureforge_v101.sh
```

Do not claim completion unless both deterministic and live thresholds pass.

- [ ] **Step 6: Inspect repository and package boundaries**

```bash
git status --short --branch
git diff --check
git ls-files | rg \
  'skills/figureforge/cases/[^_]|reproduction\.|original\.|outputs/' || true
```

Inspect the archive listing and manifest. Confirm no private corpus, output,
log, raw transcript, or render is tracked or packaged.

- [ ] **Step 7: Commit release certification**

```bash
git add README.md README.zh.md CHANGELOG.md \
  docs/figureforge-skill-v1.0.1-release.md \
  tests/figureforge/test_v101_documentation.R \
  scripts/verify_figureforge_v101.sh
git commit -m "test: certify FigureForge Skill v1.0.1"
```

Do not push, tag, create a PR, or implement MCP.

## Final Requirement Audit

- [ ] Map every section of the approved design to a passing test, command, or
  inspected artifact in `docs/figureforge-skill-v1.0.1-release.md`.
- [ ] List all v1.0.1 local commits and confirm the branch is
  `codex/figureforge-skill-mvp`.
- [ ] Record the three authentic case IDs, upstream hashes, normalized hashes,
  licenses, attribution, and human-QA status.
- [ ] Record deterministic and live evaluation row counts and threshold
  results.
- [ ] Record archive, manifest, and checksum paths outside the repository.
- [ ] Confirm the final worktree is clean and the goal has no unmet contract.
- [ ] Keep MCP planned and unimplemented and do not push.
