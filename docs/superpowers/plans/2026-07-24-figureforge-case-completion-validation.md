# FigureForge Case Completion Validation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace structural-only case validation with a backward-compatible validator that can prove the completed-case contract through metadata, scaffold, package, render, reproduction, and QA evidence.

**Architecture:** Put reusable validation logic in a base-R library and keep `validate_case.R` as a CLI wrapper. Preserve the existing structural command while adding explicit `--complete` and `--render` gates. Use sanitized fixtures so validation never depends on the private corpus.

**Tech Stack:** R 4.6, base R, existing FigureForge audit library, Markdown, POSIX shell.

---

### Task 1: Define Validation Results With RED Tests

**Files:**

- Create: `tests/figureforge/test_case_validation.R`
- Modify: `tests/fixtures/figureforge/cases/authentic-public/case.md`
- Create: `tests/fixtures/figureforge/cases/incomplete-metadata/`
- Create: `tests/fixtures/figureforge/cases/missing-packages/`

- [ ] **Step 1: Complete the valid fixture metadata**

Add every required heading, authentic data provenance, and:

```markdown
## Required R Packages

- base
```

- [ ] **Step 2: Add invalid fixtures**

One fixture lacks package declarations and one retains a scaffold marker.

- [ ] **Step 3: Write failing tests**

Source `skills/figureforge/lib/case_validation.R` and assert:

```r
stopifnot(validate_case_structure(valid_dir)$ok)
stopifnot(validate_case_completion(valid_dir)$ok)
stopifnot(!validate_case_completion(scaffold_dir)$ok)
stopifnot("scaffold markers" %in% scaffold_result$failed_checks)
stopifnot("required R packages" %in% package_result$failed_checks)
```

- [ ] **Step 4: Verify RED**

Run:

```bash
/usr/local/bin/Rscript tests/figureforge/test_case_validation.R
```

Expected: FAIL because the validation library does not exist.

### Task 2: Implement Structural And Completion Checks

**Files:**

- Create: `skills/figureforge/lib/case_validation.R`

- [ ] **Step 1: Implement structured results**

Every validation returns:

```r
list(
  ok = logical(1),
  checks = named logical vector,
  failed_checks = character(),
  messages = character()
)
```

- [ ] **Step 2: Implement structural validation**

Check non-empty `case.md`, `data.csv`, and `plot.R`, plus the ten existing
metadata headings.

- [ ] **Step 3: Implement completion validation**

Require:

- structural validation;
- `## Data Provenance`;
- `## Required R Packages` with at least one non-empty list item;
- no scaffold markers;
- `commandArgs(trailingOnly = TRUE)`, `input_path`, and `output_path` in
  `plot.R`;
- non-empty reproduction evidence;
- verified QA evidence.

Distribution review is reported but is not required for a private completed
case.

- [ ] **Step 4: Verify GREEN**

Run validation tests and case-audit regression tests.

### Task 3: Add Optional Fresh Render Validation

**Files:**

- Modify: `skills/figureforge/lib/case_validation.R`
- Modify: `tests/figureforge/test_case_validation.R`

- [ ] **Step 1: Add RED render assertions**

Assert a successful fixture render sets `render succeeded` and a failing
fixture sets it false without writing under the source case.

- [ ] **Step 2: Implement render gate**

Call `render_case_for_audit()` with an explicit external output path. Require
exit zero and non-empty output.

- [ ] **Step 3: Verify GREEN**

Check output path, source timestamps, success result, and failure messages.

### Task 4: Replace The Validator CLI Without Breaking Existing Use

**Files:**

- Modify: `skills/figureforge/scripts/validate_case.R`
- Modify: `tests/figureforge/test_case_validation.R`

- [ ] **Step 1: Add CLI RED tests**

Run and assert:

```text
validate_case.R <case_dir>
validate_case.R <case_dir> --complete
validate_case.R <case_dir> --complete --render --output <path>
```

Also assert unknown flags and a missing output path exit non-zero.

- [ ] **Step 2: Implement CLI**

The default remains structural. `--complete` adds completion checks.
`--render` requires `--output` and implies `--complete`. Print each check and
exit one when any required check fails.

- [ ] **Step 3: Verify GREEN**

Run both test suites plus public template structural validation and rendering.

### Task 5: Update Skill Contract

**Files:**

- Modify: `skills/figureforge/SKILL.md`
- Modify: `skills/figureforge/references/qa-checklist.md`
- Modify: `README.md`
- Modify: `README.zh.md`

- [ ] **Step 1: Add RED documentation assertions**

Require the Skill and both READMEs to show the complete validation command and
the difference between structural, executable, visual-QA, and distribution
claims.

- [ ] **Step 2: Update documentation**

Document:

```bash
/usr/local/bin/Rscript skills/figureforge/scripts/validate_case.R \
  <case_dir> --complete --render --output <output_path>
```

- [ ] **Step 3: Verify and commit**

Run:

```bash
/usr/local/bin/Rscript tests/figureforge/test_case_audit.R
/usr/local/bin/Rscript tests/figureforge/test_case_validation.R
/usr/local/bin/Rscript skills/figureforge/scripts/validate_case.R \
  skills/figureforge/cases/_template
git diff --check
```

Commit public code, tests, and documentation locally. Do not push.
