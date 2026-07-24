# FigureForge Case Audit Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a tested, read-only audit that classifies all private FigureForge cases by concrete completion evidence and produces local CSV/Markdown reports.

**Architecture:** Keep private cases outside Git. Implement a base-R audit library plus a thin CLI, exercise it with tracked sanitized fixtures, and write every generated artifact under ignored `outputs/`. The classifier uses independent evidence booleans so structural scaffolds cannot be mistaken for completed cases.

**Tech Stack:** R 4.6, base R, Markdown, CSV, POSIX shell, git.

---

## File Structure

- Create: `skills/figureforge/lib/case_audit.R`
  - Pure functions for file evidence, metadata markers, distribution records,
    render execution, classification, and report generation.
- Create: `skills/figureforge/scripts/audit_cases.R`
  - CLI parsing and orchestration only.
- Create: `tests/figureforge/test_case_audit.R`
  - Base-R assertions over temporary fixture copies.
- Create: `tests/fixtures/figureforge/cases/`
  - Sanitized cases for scaffold, authentic, failed-render, and public-ready
    behavior.
- Add: `skills/figureforge/cases/_template/`
  - Public tracked template used for independent checkout verification.
- Modify: `.gitignore`
  - Ignore `outputs/` while preserving tracked template files.
- Modify: `skills/figureforge/references/qa-checklist.md`
  - Define the machine-readable QA record required by the audit.
- Modify: `README.md`, `README.zh.md`
  - Document audit command and distinguish inventory from completed cases.

### Task 1: Establish Public Fixtures And RED Audit Tests

**Files:**

- Create: `tests/figureforge/test_case_audit.R`
- Create: `tests/fixtures/figureforge/cases/_template/case.md`
- Create: `tests/fixtures/figureforge/cases/scaffolded/case.md`
- Create: `tests/fixtures/figureforge/cases/scaffolded/data.csv`
- Create: `tests/fixtures/figureforge/cases/scaffolded/plot.R`
- Create: `tests/fixtures/figureforge/cases/authentic-private/*`
- Create: `tests/fixtures/figureforge/cases/authentic-public/*`
- Create: `tests/fixtures/figureforge/cases/render-fails/*`

- [ ] **Step 1: Write fixture cases**

Create minimal redistributable fixtures. Every `plot.R` accepts
`input_path` and `output_path`; successful fixtures write a small PDF with base
R. The scaffold fixture contains the exact generated marker
`This standardized case uses a compact reproducible data scaffold.` The public
fixture contains:

```yaml
redistribution: allowed
reviewed_assets:
  - case.md
  - data.csv
  - plot.R
  - reproduction.pdf
```

- [ ] **Step 2: Write failing base-R tests**

The test must source the not-yet-created library and assert:

```r
stopifnot(!"_template" %in% results$case_id)
stopifnot(results$scaffolded[results$case_id == "scaffolded"])
stopifnot(results$raw[results$case_id == "authentic-private"])
stopifnot(results$private_only[results$case_id == "authentic-private"])
stopifnot(results$public_ready[results$case_id == "authentic-public"])
stopifnot(results$reproduced[results$case_id == "authentic-public"])
stopifnot(results$qa_verified[results$case_id == "authentic-public"])
stopifnot(results$runnable[results$case_id == "authentic-public"])
stopifnot(!results$runnable[results$case_id == "render-fails"])
```

- [ ] **Step 3: Run tests and verify RED**

Run:

```bash
/usr/local/bin/Rscript tests/figureforge/test_case_audit.R
```

Expected: FAIL because `skills/figureforge/lib/case_audit.R` does not exist.

### Task 2: Implement Evidence Classification

**Files:**

- Create: `skills/figureforge/lib/case_audit.R`

- [ ] **Step 1: Implement pure evidence helpers**

Implement:

```r
is_nonempty_file <- function(path)
read_text_safely <- function(path)
detect_scaffold <- function(case_dir)
detect_source_assets <- function(case_dir)
detect_reproduction <- function(case_dir)
detect_qa_verified <- function(case_dir)
detect_distribution <- function(case_dir)
```

All helpers return explicit values and warnings without changing the case.

- [ ] **Step 2: Implement isolated rendering**

Implement:

```r
render_case_for_audit <- function(case_dir, output_path, rscript)
```

It invokes `plot.R data.csv output_path`, captures stdout/stderr, and returns
`ok`, `status`, and `log`. `ok` requires exit zero and a non-empty output.

- [ ] **Step 3: Implement corpus audit**

Implement:

```r
audit_case <- function(case_dir, render_dir = NULL, rscript = "/usr/local/bin/Rscript")
audit_cases <- function(cases_dir, render_dir = NULL, rscript = "/usr/local/bin/Rscript")
```

`audit_cases()` excludes `_template`, sorts case IDs, continues after failures,
and returns one row per directory with all evidence fields and reasons.

- [ ] **Step 4: Run tests and verify GREEN**

Run:

```bash
/usr/local/bin/Rscript tests/figureforge/test_case_audit.R
```

Expected: PASS and print `case audit tests: PASS`.

### Task 3: Add Deterministic Reports And CLI

**Files:**

- Modify: `skills/figureforge/lib/case_audit.R`
- Create: `skills/figureforge/scripts/audit_cases.R`
- Modify: `tests/figureforge/test_case_audit.R`

- [ ] **Step 1: Add failing report tests**

Assert that report generation creates `case-readiness.csv` and `summary.md`,
that CSV rows are sorted, and that the summary reports the exact fixture counts.

- [ ] **Step 2: Verify RED**

Run the test command and confirm failure because report functions are absent.

- [ ] **Step 3: Implement report writers**

Implement:

```r
write_audit_reports <- function(results, output_dir)
summarize_audit <- function(results)
```

The summary must explain that `reproduced` proves file presence, not visual
fidelity, and that missing distribution review defaults to private-only.

- [ ] **Step 4: Implement CLI**

Support:

```text
--cases-dir PATH
--output-dir PATH
--rscript PATH
--render
```

Unknown or missing required arguments exit non-zero with usage text.

- [ ] **Step 5: Verify GREEN**

Run tests and a fixture CLI audit. Expected: exit zero and deterministic output.

### Task 4: Restore A Trackable Public Template

**Files:**

- Modify: `.gitignore`
- Add: `skills/figureforge/cases/_template/case.md`
- Add: `skills/figureforge/cases/_template/data.csv`
- Add: `skills/figureforge/cases/_template/plot.R`

- [ ] **Step 1: Add a failing checkout-contract test**

Extend the test runner to assert that the three repository template files exist
and that the template is excluded from audit results.

- [ ] **Step 2: Verify RED in the isolated worktree**

Expected: FAIL because the template is currently absent from Git.

- [ ] **Step 3: Narrow `.gitignore` exceptions**

Keep all real case content ignored, but explicitly unignore only:

```gitignore
!skills/figureforge/cases/_template/
!skills/figureforge/cases/_template/case.md
!skills/figureforge/cases/_template/data.csv
!skills/figureforge/cases/_template/plot.R
outputs/
```

- [ ] **Step 4: Add the sanitized template**

Copy the public-safe template content into the tracked worktree. Do not copy
any real case.

- [ ] **Step 5: Verify GREEN**

Run audit tests, structural validation, and template rendering.

### Task 5: Run The Private 165-Case Audit

**Files:**

- Generate locally only:
  `/Users/liuyue/Desktop/Github_repos/FigureForge/outputs/figureforge-audit/`

- [ ] **Step 1: Verify source identity**

Confirm the source is the main checkout private corpus, contains 165 real
directories excluding `_template`, and is not a symlink.

- [ ] **Step 2: Run structural audit**

Run the CLI without render first and confirm exactly 165 rows.

- [ ] **Step 3: Run render audit**

Run with `--render`. Continue across dependency failures and store logs only in
the ignored output directory.

- [ ] **Step 4: Inspect report consistency**

Check row count, boolean columns, count totals, missing evidence, and that no
file timestamp under `cases/` changed during the audit.

### Task 6: Document The Contract

**Files:**

- Modify: `skills/figureforge/references/qa-checklist.md`
- Modify: `README.md`
- Modify: `README.zh.md`

- [ ] **Step 1: Add failing documentation checks**

Assert both READMEs include the audit command, seven classifications, and the
statement that scaffolded is not completed.

- [ ] **Step 2: Verify RED**

Run documentation checks and confirm missing text causes failure.

- [ ] **Step 3: Update English and Chinese docs**

Document the same behavior in both languages and keep MCP explicitly planned.

- [ ] **Step 4: Run full verification**

Run:

```bash
/usr/local/bin/Rscript tests/figureforge/test_case_audit.R
/usr/local/bin/Rscript skills/figureforge/scripts/validate_case.R skills/figureforge/cases/_template
tmp_dir=$(mktemp -d)
/usr/local/bin/Rscript skills/figureforge/scripts/render_case.R \
  skills/figureforge/cases/_template "$tmp_dir/template.png"
test -s "$tmp_dir/template.png"
git diff --check
git status --short
```

Expected: all commands exit zero; only public code, fixtures, template, and
documentation appear in Git status.

### Task 7: Commit Stage A

- [ ] **Step 1: Review private boundary**

Run:

```bash
git status --short
git diff --name-only
git check-ignore outputs/figureforge-audit/case-readiness.csv
```

Confirm no real case directory or audit output is staged.

- [ ] **Step 2: Create local commits**

Create focused local commits for:

1. audit tool and tests;
2. public template restoration;
3. documentation and Stage A report contract.

Do not push.
