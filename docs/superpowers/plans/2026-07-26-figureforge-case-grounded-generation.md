# FigureForge Case-Grounded Generation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make FigureForge distinguish auditable case-based plot generation from explicitly labelled general R fallback generation, then rebuild the Iris PCA demo with genuine `20230925_PCA` case evidence.

**Architecture:** Add a small flat-YAML trace contract and deterministic R validator beside the existing adaptation infrastructure. Keep the public three-artifact interface unchanged, teach the Skill when each generation mode is valid, and use a hidden `.figureforge/case-trace.yml` as task-level provenance. Merge the existing Iris demo branch only after the core contract is tested, then replace its unsupported provenance claims with a validated case-based trace and visible adaptation summary.

**Tech Stack:** Base R, existing FigureForge metadata/checksum utilities, shell verification scripts, Markdown Skill/reference files, ggplot2 Iris PCA demo, git worktrees.

---

## File Map

- Create `skills/figureforge/lib/case_trace_validation.R`: parse and validate task-level trace metadata.
- Create `skills/figureforge/scripts/validate_case_trace.R`: stable CLI for structural and strict evidence validation.
- Create `skills/figureforge/references/case-use-contract.md`: detailed mode, evidence, privacy, and claim rules.
- Modify `skills/figureforge/SKILL.md`: make case evidence and fallback disclosure part of the ordinary workflow.
- Modify `skills/figureforge/references/plotting-workflow.md`: add trace creation and validation checklist.
- Modify `skills/figureforge/agents/openai.yaml`: align the default prompt with the two-mode contract.
- Create `tests/figureforge/test_case_trace_validation.R`: validator RED/GREEN coverage.
- Modify `tests/figureforge/test_skill_trigger_contract.R`: enforce the new Skill behavior.
- Modify `tests/figureforge/test_v1_skill_contract.R`: enforce references, trace CLI, and concise Skill routing.
- Modify `tests/figureforge/test_install_smoke.R`: ensure new runtime files survive installation.
- Modify `tests/figureforge/test_release_packaging.R`: ensure new runtime files enter the release and private evidence does not.
- Merge `codex/iris-pca-demo`: bring the existing executable demo and its tests into this feature branch.
- Modify `examples/iris-pca/plot.R`: emit a deterministic case trace and accurate HTML adaptation summary.
- Modify `examples/iris-pca/README.md`: replace the unsupported case-consultation claim.
- Modify `examples/iris-pca/index.html`, `plot.png`, and `plot.pdf`: regenerate from the corrected script.
- Modify `tests/figureforge/test_iris_pca_demo.R`: require real case evidence, correct claims, and trace validation.
- Modify `README.md` and `README.zh.md`: explain case-based and fallback modes concisely.
- Modify `scripts/verify_figureforge_v110.sh`: include the new trace gate in installed-package verification.

### Task 1: Lock the trace validator contract

**Files:**
- Create: `tests/figureforge/test_case_trace_validation.R`
- Test: `tests/figureforge/test_case_trace_validation.R`

- [ ] **Step 1: Write the failing test**

Create fixtures entirely under a temporary directory. Source the not-yet-created
library and define a helper that writes flat trace metadata:

```r
source(file.path(
  repo_root,
  "skills",
  "figureforge",
  "lib",
  "distribution_validation.R"
))
source(file.path(
  repo_root,
  "skills",
  "figureforge",
  "lib",
  "checksums.R"
))
source(file.path(
  repo_root,
  "skills",
  "figureforge",
  "lib",
  "case_trace_validation.R"
))

write_trace <- function(path, values) {
  writeLines(
    paste(names(values), unname(values), sep = ": "),
    path,
    useBytes = TRUE
  )
}
```

Build a temporary case containing `case.md`, `plot.R`, and verified `qa.md`,
plus a generated `plot.R`. Assert:

```r
valid <- validate_case_trace(
  trace_path,
  case_dir = case_dir,
  script_path = generated_script
)
stopifnot(isTRUE(valid$ok))
```

Then mutate one property at a time and assert the named failed check:

```r
expect_failed <- function(values, expected_check, case = case_dir) {
  write_trace(trace_path, values)
  result <- validate_case_trace(
    trace_path,
    case_dir = case,
    script_path = generated_script
  )
  stopifnot(!result$ok, expected_check %in% result$failed_checks)
}
```

Cover missing `case.md` evidence, missing `plot.R` evidence, evidence hash
changes, generated-script hash changes, empty schema mapping, empty/generic
adopted patterns, missing QA evidence when `qa.md` exists, valid missing QA,
valid fallback, fallback without a reason, fallback with
`claim: case_grounded`, and absolute private paths.

- [ ] **Step 2: Run the test to verify RED**

Run:

```bash
/usr/local/bin/Rscript tests/figureforge/test_case_trace_validation.R
```

Expected: FAIL because
`skills/figureforge/lib/case_trace_validation.R` does not exist.

- [ ] **Step 3: Commit the RED test**

```bash
git add tests/figureforge/test_case_trace_validation.R
git commit -m "test: define FigureForge case trace contract"
```

### Task 2: Implement trace parsing and validation

**Files:**
- Create: `skills/figureforge/lib/case_trace_validation.R`
- Test: `tests/figureforge/test_case_trace_validation.R`

- [ ] **Step 1: Implement the minimal validator**

Define these public functions:

```r
case_trace_required_common_keys <- function() {
  c(
    "schema_version",
    "generation_mode",
    "figureforge_version",
    "generated_script_sha256",
    "claim"
  )
}

case_trace_case_based_keys <- function() {
  c(
    "primary_case_id",
    "case_markdown_file",
    "case_markdown_sha256",
    "case_script_file",
    "case_script_sha256",
    "qa_status",
    "schema_mapping",
    "adopted_patterns",
    "departures"
  )
}

case_trace_fallback_keys <- function() {
  "fallback_reason"
}

validate_case_trace <- function(
  trace_path,
  case_dir = NULL,
  script_path = NULL
) {
  # Return make_validation_result(checks, messages, evidence).
}
```

Use `parse_simple_metadata()` for the flat YAML-compatible file and
`figureforge_sha256()` for strict evidence checks. Treat pipe-separated
`schema_mapping` and `adopted_patterns` values as nonempty lists. Reject
adopted entries equal to generic phrases such as `used colors`,
`scientific plot`, `参考案例`, or `美化图片`.

For `case_based`, require `claim: case_grounded`. When the selected case has
`qa.md`, require `qa_file`, `qa_sha256`, and a matching hash. When it does not,
require `qa_status: missing`. For `general_fallback`, require
`claim: general_method`, a nonempty `fallback_reason`, and no primary-case
evidence.

Reject values containing Unix absolute paths, Windows drive-rooted paths, or
newlines. Return stable named checks so the CLI and tests can report precise
failures.

- [ ] **Step 2: Run the unit test to verify GREEN**

Run:

```bash
/usr/local/bin/Rscript tests/figureforge/test_case_trace_validation.R
```

Expected: `case trace validation tests: PASS`.

- [ ] **Step 3: Run adjacent regression tests**

Run:

```bash
/usr/local/bin/Rscript tests/figureforge/test_skill_workflow.R
/usr/local/bin/Rscript tests/figureforge/test_workspace_generation.R
```

Expected: both PASS.

- [ ] **Step 4: Commit**

```bash
git add \
  skills/figureforge/lib/case_trace_validation.R \
  tests/figureforge/test_case_trace_validation.R
git commit -m "feat: validate FigureForge case traces"
```

### Task 3: Add the installed trace-validation CLI

**Files:**
- Create: `skills/figureforge/scripts/validate_case_trace.R`
- Modify: `tests/figureforge/test_case_trace_validation.R`
- Modify: `tests/figureforge/test_install_smoke.R`
- Modify: `tests/figureforge/test_release_packaging.R`

- [ ] **Step 1: Extend tests before creating the CLI**

Add a CLI invocation:

```r
cli_status <- system2(
  "/usr/local/bin/Rscript",
  shQuote(c(
    validator_cli,
    trace_path,
    "--case-dir", case_dir,
    "--script", generated_script
  )),
  stdout = cli_log,
  stderr = cli_log
)
stopifnot(identical(as.integer(cli_status), 0L))
stopifnot(grepl(
  "Case trace validation OK",
  paste(readLines(cli_log, warn = FALSE), collapse = "\n"),
  fixed = TRUE
))
```

Add `validate_case_trace.R` and `case_trace_validation.R` to installed-file and
release-manifest expectations.

- [ ] **Step 2: Verify RED**

Run:

```bash
/usr/local/bin/Rscript tests/figureforge/test_case_trace_validation.R
```

Expected: FAIL because `validate_case_trace.R` is missing.

- [ ] **Step 3: Implement the CLI**

Support:

```text
Usage: validate_case_trace.R <trace.yml> [--case-dir PATH] [--script PATH]
```

Resolve the repository or installed Skill root from the script location,
source `distribution_validation.R`, `checksums.R`, and
`case_trace_validation.R`, print every named check as `PASS` or `FAIL`, and
exit nonzero with:

```text
Case trace validation failed: <comma-separated failed checks>
```

Print `Case trace validation OK: <trace path>` on success.

- [ ] **Step 4: Verify GREEN and packaging coverage**

Run:

```bash
/usr/local/bin/Rscript tests/figureforge/test_case_trace_validation.R
/usr/local/bin/Rscript tests/figureforge/test_install_smoke.R
/usr/local/bin/Rscript tests/figureforge/test_release_packaging.R
```

Expected: all PASS.

- [ ] **Step 5: Commit**

```bash
git add \
  skills/figureforge/scripts/validate_case_trace.R \
  tests/figureforge/test_case_trace_validation.R \
  tests/figureforge/test_install_smoke.R \
  tests/figureforge/test_release_packaging.R
git commit -m "feat: add case trace validation CLI"
```

### Task 4: Teach the Skill the two generation modes

**Files:**
- Create: `skills/figureforge/references/case-use-contract.md`
- Modify: `skills/figureforge/SKILL.md`
- Modify: `skills/figureforge/references/plotting-workflow.md`
- Modify: `skills/figureforge/agents/openai.yaml`
- Modify: `tests/figureforge/test_skill_trigger_contract.R`
- Modify: `tests/figureforge/test_v1_skill_contract.R`

- [ ] **Step 1: Add failing Skill contract assertions**

Require the Skill and default prompt to contain the concepts:

```r
required_case_grounding <- c(
  "case_based",
  "general_fallback",
  "case.md",
  "plot.R",
  "qa.md",
  "adopted patterns",
  "departures",
  "validate_case_trace.R",
  "do not claim case-grounded generation"
)
```

Require the reference file to exist and include:

```r
c(
  "Searching for a case is not evidence",
  "case_grounded",
  "general_method",
  ".figureforge/case-trace.yml",
  "absolute paths",
  "SHA-256"
)
```

Keep the existing three-artifact return contract and the Skill length below
260 lines.

- [ ] **Step 2: Verify RED**

Run:

```bash
/usr/local/bin/Rscript tests/figureforge/test_skill_trigger_contract.R
/usr/local/bin/Rscript tests/figureforge/test_v1_skill_contract.R
```

Expected: FAIL on the missing two-mode contract and reference.

- [ ] **Step 3: Write the minimal Skill and reference changes**

In `SKILL.md`, replace the informal case-use paragraphs with these mandatory
decisions:

```markdown
After search, choose exactly one mode:

- `case_based`: read the primary case's `case.md`, `plot.R`, and `qa.md` when
  present; record schema mapping, adopted patterns, and departures; validate
  `.figureforge/case-trace.yml` before claiming case-grounded generation.
- `general_fallback`: use general R plotting when no case is sufficiently
  relevant or readable; record the reason and do not claim case-grounded
  generation.
```

Route field-level details to `references/case-use-contract.md`. Update the
ordinary plotting workflow to write and validate the trace after the fresh
render. Update `openai.yaml` without removing the three visible artifact names.

- [ ] **Step 4: Verify GREEN and official Skill validation**

Run:

```bash
/usr/local/bin/Rscript tests/figureforge/test_skill_trigger_contract.R
/usr/local/bin/Rscript tests/figureforge/test_v1_skill_contract.R
/usr/bin/python3 \
  /Users/liuyue/.codex/skills/.system/skill-creator/scripts/quick_validate.py \
  skills/figureforge
```

Expected: both R tests PASS and `Skill is valid!`.

- [ ] **Step 5: Commit**

```bash
git add \
  skills/figureforge/SKILL.md \
  skills/figureforge/agents/openai.yaml \
  skills/figureforge/references/case-use-contract.md \
  skills/figureforge/references/plotting-workflow.md \
  tests/figureforge/test_skill_trigger_contract.R \
  tests/figureforge/test_v1_skill_contract.R
git commit -m "feat: require grounded FigureForge case use"
```

### Task 5: Bring in the existing Iris PCA demo baseline

**Files:**
- Merge: branch `codex/iris-pca-demo`
- Test: `tests/figureforge/test_iris_pca_demo.R`

- [ ] **Step 1: Merge the existing reviewed demo branch**

Run:

```bash
git merge --no-ff codex/iris-pca-demo \
  -m "merge: add iris PCA demo baseline"
```

Expected: the existing executable demo, HTML, README integration, and demo tests
enter the feature branch without private case files.

- [ ] **Step 2: Run the demo baseline**

Run:

```bash
/usr/local/bin/Rscript tests/figureforge/test_iris_pca_demo.R
```

Expected: existing demo tests PASS. This establishes that the statistical and
artifact behavior is preserved before provenance changes.

### Task 6: Require genuine PCA case grounding

**Files:**
- Modify: `tests/figureforge/test_iris_pca_demo.R`
- Modify: `examples/iris-pca/plot.R`
- Modify: `examples/iris-pca/README.md`
- Create: `examples/iris-pca/.figureforge/case-trace.yml`
- Regenerate: `examples/iris-pca/index.html`
- Regenerate: `examples/iris-pca/plot.png`
- Regenerate: `examples/iris-pca/plot.pdf`

- [ ] **Step 1: Add failing provenance assertions**

Require:

```r
trace_path <- file.path(demo_dir, ".figureforge", "case-trace.yml")
stopifnot(file.exists(trace_path))
trace <- parse_simple_metadata(trace_path)
stopifnot(identical(trace$generation_mode, "case_based"))
stopifnot(identical(trace$claim, "case_grounded"))
stopifnot(identical(trace$primary_case_id, "20230925_PCA"))
```

Validate it structurally in every environment. When
`FIGUREFORGE_PCA_CASE_DIR` is set, additionally validate the evidence hashes
against that private case directory. Require HTML and README language that
names adopted and departed patterns, and reject the old unsupported sentence:

```r
stopifnot(!grepl(
  "was consulted only as a visual grammar reference",
  read_text,
  fixed = TRUE
))
```

- [ ] **Step 2: Verify RED**

Run:

```bash
FIGUREFORGE_PCA_CASE_DIR=/Users/liuyue/Desktop/Github_repos/FigureForge/skills/figureforge/cases/20230925_PCA \
  /usr/local/bin/Rscript tests/figureforge/test_iris_pca_demo.R
```

Expected: FAIL because `.figureforge/case-trace.yml` is missing.

- [ ] **Step 3: Update the case-derived generator and create its trace**

Read and hash the private case during this development task, before editing the
demo. Update `plot.R` using the documented case knowledge, but keep its public
runtime contract independent of the private corpus. Create
`.figureforge/case-trace.yml` as generation-time evidence containing:

```text
generation_mode: case_based
claim: case_grounded
primary_case_id: 20230925_PCA
schema_mapping: feature matrix -> four Iris measurements|sample group -> Species|Dim.1 -> PC1|Dim.2 -> PC2
adopted_patterns: centered and scaled PCA|variance in axis labels|group color and shape|zero reference lines|group boundary ellipses
departures: feature-by-sample transpose -> row-wise Iris observations|four boundary panels -> single explanatory biplot|FactoMineR -> stats::prcomp|fixed limits -> data-aware limits|no loadings -> scaled loading arrows
```

Do not store the source directory. Use the trace validator before publishing
the final output directory. The delivered `plot.R` must continue to rerun from
the documented public command without `FIGUREFORGE_PCA_CASE_DIR`; it does not
recreate or rewrite the generation-time trace.

Update the HTML method section to show the adopted patterns, departures, and
successful mode. Update the demo README with accurate provenance language.

- [ ] **Step 4: Regenerate and verify GREEN**

Run:

```bash
FIGUREFORGE_PCA_CASE_DIR=/Users/liuyue/Desktop/Github_repos/FigureForge/skills/figureforge/cases/20230925_PCA \
  /usr/local/bin/Rscript \
  examples/iris-pca/plot.R \
  examples/iris-pca/iris.csv \
  examples/iris-pca

FIGUREFORGE_PCA_CASE_DIR=/Users/liuyue/Desktop/Github_repos/FigureForge/skills/figureforge/cases/20230925_PCA \
  /usr/local/bin/Rscript tests/figureforge/test_iris_pca_demo.R
```

Expected: demo tests PASS and the trace validates against the private case
without containing its absolute path or source content.

Then prove public portability independently:

```bash
unset FIGUREFORGE_PCA_CASE_DIR
public_rerun=$(mktemp -d /tmp/figureforge-iris-public.XXXXXX)
/usr/local/bin/Rscript \
  examples/iris-pca/plot.R \
  examples/iris-pca/iris.csv \
  "$public_rerun"
test -s "$public_rerun/plot.png"
test -s "$public_rerun/plot.pdf"
```

- [ ] **Step 5: Visually inspect the regenerated PNG and HTML**

Open `examples/iris-pca/plot.png` and serve `examples/iris-pca/index.html`
locally. Verify desktop and mobile layout, links, provenance wording, labels,
ellipses, loadings, and clipping.

- [ ] **Step 6: Commit**

```bash
git add \
  examples/iris-pca \
  tests/figureforge/test_iris_pca_demo.R
git commit -m "feat: ground iris PCA demo in FigureForge case knowledge"
```

### Task 7: Align documentation and installed verification

**Files:**
- Modify: `README.md`
- Modify: `README.zh.md`
- Modify: `tests/figureforge/test_v110_documentation.R`
- Modify: `scripts/verify_figureforge_v110.sh`

- [ ] **Step 1: Add failing bilingual documentation assertions**

Require both READMEs to explain:

- case-based generation requires actual case evidence;
- general fallback remains available;
- fallback must not claim case knowledge;
- default visible outputs remain `plot.R`, `plot.png`, and `plot.pdf`.

Require the v1.1.0 verifier's installed stage to run
`validate_case_trace.R` on a generated fixture.

- [ ] **Step 2: Verify RED**

Run:

```bash
/usr/local/bin/Rscript tests/figureforge/test_v110_documentation.R
```

Expected: FAIL on missing two-mode documentation or installed trace gate.

- [ ] **Step 3: Update documentation and verifier**

Keep the quick start concise. Add a short English/Chinese subsection describing
the two modes and point maintainers to the case-use contract. In the verifier,
create a temporary public-case trace using `public-scatter-fit`, calculate
hashes with the packaged files, and validate it through the installed CLI.

- [ ] **Step 4: Verify GREEN**

Run:

```bash
/usr/local/bin/Rscript tests/figureforge/test_v110_documentation.R
/usr/local/bin/Rscript tests/figureforge/test_v101_documentation.R
/usr/local/bin/Rscript tests/figureforge/test_v1_documentation.R
```

Expected: all PASS.

- [ ] **Step 5: Commit**

```bash
git add \
  README.md \
  README.zh.md \
  scripts/verify_figureforge_v110.sh \
  tests/figureforge/test_v110_documentation.R
git commit -m "docs: explain FigureForge generation modes"
```

### Task 8: Forward-test the revised Skill

**Files:**
- Create: temporary evaluation workspaces outside the repository
- Modify if needed: `skills/figureforge/SKILL.md`
- Modify if needed: `skills/figureforge/references/case-use-contract.md`
- Modify if needed: tests covering any discovered loophole

- [ ] **Step 1: Run the strong-match scenario with a fresh agent**

Use the installed Skill artifact and a PCA request without exposing the
expected answer. The evaluator checks its raw tool trace for reads of
`case.md`, `plot.R`, and available `qa.md`, plus a valid `case_based` trace.

- [ ] **Step 2: Run the no-match scenario with a fresh agent**

Provide a scientifically valid request with no sufficient gallery match. The
evaluator checks that the agent completes the plot through
`general_fallback`, records a reason, and does not claim case grounding.

- [ ] **Step 3: Close any discovered loophole test-first**

For each failure, add a focused failing contract test, update the minimal Skill
or reference language, rerun both scenarios, and retain only generalized
lessons. Do not commit raw private paths, case content, or session transcripts.

- [ ] **Step 4: Commit any required hardening**

```bash
git add \
  skills/figureforge/SKILL.md \
  skills/figureforge/references/case-use-contract.md \
  tests/figureforge
git commit -m "test: harden case-grounded generation behavior"
```

Skip this commit only when the first GREEN behavior tests expose no loophole.

### Task 9: Complete verification and handoff

**Files:**
- Verify all changed files

- [ ] **Step 1: Run focused tests**

```bash
/usr/local/bin/Rscript tests/figureforge/test_case_trace_validation.R
/usr/local/bin/Rscript tests/figureforge/test_skill_trigger_contract.R
/usr/local/bin/Rscript tests/figureforge/test_v1_skill_contract.R
FIGUREFORGE_PCA_CASE_DIR=/Users/liuyue/Desktop/Github_repos/FigureForge/skills/figureforge/cases/20230925_PCA \
  /usr/local/bin/Rscript tests/figureforge/test_iris_pca_demo.R
```

Expected: all PASS.

- [ ] **Step 2: Run the full non-live v1.1.0 gate**

```bash
FIGUREFORGE_RUN_LIVE_EVALS=0 \
  FIGUREFORGE_PCA_CASE_DIR=/Users/liuyue/Desktop/Github_repos/FigureForge/skills/figureforge/cases/20230925_PCA \
  sh scripts/verify_figureforge_v110.sh
```

Expected final line:

```text
FigureForge Skill v1.1.0 acceptance: PASS
```

- [ ] **Step 3: Inspect repository integrity**

```bash
git diff --check
git status --short
git log --oneline --decorate main..
```

Expected: no whitespace errors, no uncommitted files, and only scoped feature
commits.

- [ ] **Step 4: Request code review**

Use `superpowers:requesting-code-review` to review the implementation against
`docs/superpowers/specs/2026-07-26-figureforge-case-grounded-generation-design.md`.
Resolve findings test-first and rerun the affected gates.

- [ ] **Step 5: Finish the development branch**

Use `superpowers:finishing-a-development-branch` and present integration
options. Do not merge, push, or delete the worktree without the user's choice.
