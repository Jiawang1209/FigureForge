# FigureForge Complete Corpus Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> `superpowers:executing-plans` to implement this plan task-by-task. Steps use
> checkbox (`- [ ]`) syntax for tracking.

**Goal:** Process all 165 private FigureForge cases so every case is either an
authentically completed, freshly rendered, visually verified case or has a
validated evidence-backed blocker record.

**Architecture:** Extend the public R audit control plane with blocker parsing
and deterministic batch planning, then process private cases in evidence-first
waves recorded under ignored outputs. Public code, tests, aggregate docs, and
contracts are committed; private case data, images, indexes, audits, and
renders remain untracked.

**Tech Stack:** Base R, ggplot2 ecosystem, Markdown contracts,
`/usr/local/bin/Rscript`, Git, Poppler previews, official Skill validator.

---

### Task 1: Add Failing Blocker Contract Tests

**Files:**

- Create:
  `tests/figureforge/test_blocker_validation.R`
- Create:
  `tests/fixtures/figureforge/blockers/valid/blocker.md`
- Create:
  `tests/fixtures/figureforge/blockers/unsupported-status/blocker.md`
- Create:
  `tests/fixtures/figureforge/blockers/missing-evidence/blocker.md`
- Create:
  `tests/fixtures/figureforge/blockers/contradictory/blocker.md`
- Test:
  `tests/figureforge/test_blocker_validation.R`

- [ ] **Step 1: Create blocker fixtures**

The valid fixture must contain:

```markdown
# FigureForge Case Blocker

Status: blocked_source_missing

## Files Inspected

- `source-script.R`: contains plotting calls but no input values.

## Commands Run

- `Rscript source-script.R`: failed because `measurements.csv` is absent.

## Recovery Attempts

- Searched the fixture directory for CSV, TSV, XLSX, RDS, and RData inputs.

## Why Unsafe To Infer

The missing measurements determine every plotted value.

## Unblock Requirement

Provide the original `measurements.csv` or an equivalent documented table.
```

The unsupported fixture uses `Status: blocked_time_limit`. The missing-evidence
fixture keeps an empty `## Recovery Attempts` section. The contradictory
fixture includes the valid blocker plus a sibling `qa.md` containing
`Status: verified` and all five QA headings.

- [ ] **Step 2: Write the failing test**

The test must source the existing audit and validation libraries plus the
not-yet-created blocker library and assert:

```r
valid <- validate_blocker_record(file.path(fixtures, "valid"))
stopifnot(isTRUE(valid$ok))
stopifnot(identical(valid$status, "blocked_source_missing"))

unsupported <- validate_blocker_record(
  file.path(fixtures, "unsupported-status")
)
stopifnot(!isTRUE(unsupported$ok))
stopifnot("supported status" %in% unsupported$failed_checks)

missing <- validate_blocker_record(file.path(fixtures, "missing-evidence"))
stopifnot(!isTRUE(missing$ok))
stopifnot("non-empty evidence sections" %in% missing$failed_checks)

contradictory <- validate_blocker_record(
  file.path(fixtures, "contradictory")
)
stopifnot(!isTRUE(contradictory$ok))
stopifnot("not QA verified" %in% contradictory$failed_checks)
```

- [ ] **Step 3: Run the test and observe RED**

Run:

```bash
/usr/local/bin/Rscript tests/figureforge/test_blocker_validation.R
```

Expected: non-zero exit because
`skills/figureforge/lib/blocker_validation.R` does not exist.

- [ ] **Step 4: Commit only the RED fixtures and test**

```bash
git add tests/figureforge/test_blocker_validation.R \
  tests/fixtures/figureforge/blockers
git commit -m "test: define FigureForge blocker contract"
```

### Task 2: Implement Blocker Validation

**Files:**

- Create:
  `skills/figureforge/lib/blocker_validation.R`
- Create:
  `skills/figureforge/scripts/validate_blocker.R`
- Modify:
  `tests/figureforge/test_blocker_validation.R`
- Test:
  `tests/figureforge/test_blocker_validation.R`

- [ ] **Step 1: Implement the blocker library**

Define:

```r
supported_blocker_statuses <- function() {
  c(
    "blocked_source_missing",
    "blocked_dependency",
    "blocked_visual_reference",
    "blocked_corrupt_asset",
    "blocked_ambiguous_mapping",
    "blocked_rights"
  )
}
```

Define `required_blocker_headings()` with:

```r
c(
  "## Files Inspected",
  "## Commands Run",
  "## Recovery Attempts",
  "## Why Unsafe To Infer",
  "## Unblock Requirement"
)
```

Define `validate_blocker_record(case_dir)` to return:

```r
list(
  ok = logical(1),
  status = character(1),
  summary = character(1),
  checks = named_logical_vector,
  failed_checks = character(),
  evidence = named_list
)
```

Required checks:

- non-empty `blocker.md`;
- one supported `Status: ...` line;
- every required heading exists;
- every required section contains non-template evidence;
- `detect_qa_verified(case_dir)` is false.

Use the first non-empty line of `## Why Unsafe To Infer` as `summary`.

- [ ] **Step 2: Implement the CLI**

`validate_blocker.R <case_dir>` must:

- resolve its library paths relative to the script;
- reject a missing case directory;
- print each named check as PASS or FAIL;
- print the parsed blocker status;
- exit non-zero on invalid records.

- [ ] **Step 3: Run focused tests and observe GREEN**

```bash
/usr/local/bin/Rscript tests/figureforge/test_blocker_validation.R
```

Expected: `blocker validation tests: PASS`.

- [ ] **Step 4: Run the existing FigureForge tests**

```bash
for test_file in tests/figureforge/*.R; do
  /usr/local/bin/Rscript "$test_file" || exit 1
done
```

Expected: every test exits zero.

- [ ] **Step 5: Commit**

```bash
git add skills/figureforge/lib/blocker_validation.R \
  skills/figureforge/scripts/validate_blocker.R
git commit -m "feat: validate FigureForge blocker evidence"
```

### Task 3: Extend Corpus Audit With Terminal Outcomes

**Files:**

- Modify:
  `skills/figureforge/lib/case_audit.R`
- Modify:
  `skills/figureforge/scripts/audit_cases.R`
- Modify:
  `tests/figureforge/test_case_audit.R`
- Create:
  `tests/fixtures/figureforge/cases/blocked-valid/case.md`
- Create:
  `tests/fixtures/figureforge/cases/blocked-valid/data.csv`
- Create:
  `tests/fixtures/figureforge/cases/blocked-valid/plot.R`
- Create:
  `tests/fixtures/figureforge/cases/blocked-valid/blocker.md`
- Create:
  `tests/fixtures/figureforge/cases/blocked-invalid/case.md`
- Create:
  `tests/fixtures/figureforge/cases/blocked-invalid/data.csv`
- Create:
  `tests/fixtures/figureforge/cases/blocked-invalid/plot.R`
- Create:
  `tests/fixtures/figureforge/cases/blocked-invalid/blocker.md`
- Test:
  `tests/figureforge/test_case_audit.R`

- [ ] **Step 1: Extend audit assertions before production code**

Add assertions:

```r
valid_blocked <- row_for("blocked-valid")
stopifnot(isTRUE(valid_blocked$blocked))
stopifnot(isTRUE(valid_blocked$processed))
stopifnot(identical(
  valid_blocked$terminal_outcome,
  "blocked"
))

invalid_blocked <- row_for("blocked-invalid")
stopifnot(!isTRUE(invalid_blocked$blocked))
stopifnot(!isTRUE(invalid_blocked$processed))
stopifnot(identical(
  invalid_blocked$terminal_outcome,
  "pending"
))
```

Also assert that `authentic-public` is `completed` and `scaffolded` is
`pending`.

- [ ] **Step 2: Run audit tests and observe RED**

```bash
/usr/local/bin/Rscript tests/figureforge/test_case_audit.R
```

Expected: failure because terminal outcome columns are absent.

- [ ] **Step 3: Implement terminal fields**

Source `blocker_validation.R` in the audit CLI. For every case calculate:

```r
completed <- runnable && reproduced && qa_verified && !scaffolded
blocked <- blocker_result$ok
processed <- completed || blocked
terminal_outcome <- if (completed) {
  "completed"
} else if (blocked) {
  "blocked"
} else {
  "pending"
}
```

Add `blocked`, `blocked_status`, `blocked_summary`, `processed`, and
`terminal_outcome` to empty, success, and error result frames.

Extend `summary.md` with completed, blocked, pending, and processed counts.

- [ ] **Step 4: Run focused and full tests**

```bash
/usr/local/bin/Rscript tests/figureforge/test_case_audit.R
for test_file in tests/figureforge/*.R; do
  /usr/local/bin/Rscript "$test_file" || exit 1
done
```

Expected: all tests pass.

- [ ] **Step 5: Commit**

```bash
git add skills/figureforge/lib/case_audit.R \
  skills/figureforge/scripts/audit_cases.R \
  tests/figureforge/test_case_audit.R \
  tests/fixtures/figureforge/cases/blocked-valid \
  tests/fixtures/figureforge/cases/blocked-invalid
git commit -m "feat: audit terminal case outcomes"
```

### Task 4: Add Deterministic Batch Planning

**Files:**

- Create:
  `skills/figureforge/lib/batch_planning.R`
- Create:
  `skills/figureforge/scripts/plan_case_batches.R`
- Create:
  `tests/figureforge/test_batch_planning.R`
- Test:
  `tests/figureforge/test_batch_planning.R`

- [ ] **Step 1: Write the failing batch test**

Construct a six-row in-memory readiness frame and assert:

```r
plan <- plan_case_batches(readiness, batch_size = 2L)
stopifnot(!any(plan$case_id == "already-completed"))
stopifnot(!any(plan$case_id == "already-blocked"))
stopifnot(identical(plan$case_id[[1]], "reproduced-source-rich"))
stopifnot(identical(plan$wave, c(1L, 1L, 2L, 2L)))
stopifnot(all(c(
  "priority_score",
  "priority_reason",
  "wave"
) %in% names(plan)))
```

Scoring must prefer, in order:

- `reproduced`: +100;
- authentic source script detected: +40;
- non-canonical source data detected: +30;
- `runnable`: +20;
- each missing dependency: -10;
- scaffolded: no bonus or penalty because it describes work remaining.

- [ ] **Step 2: Run and observe RED**

```bash
/usr/local/bin/Rscript tests/figureforge/test_batch_planning.R
```

Expected: failure because `batch_planning.R` is absent.

- [ ] **Step 3: Implement planning and CLI**

`plan_case_batches(readiness, batch_size)` must:

- reject a non-positive batch size;
- exclude `processed == TRUE`;
- calculate deterministic scores;
- break ties by `case_id`;
- assign `wave <- ceiling(seq_len(nrow(plan)) / batch_size)`;
- return an empty frame with stable columns for an empty pending set.

The CLI must accept:

```text
plan_case_batches.R
  --readiness PATH
  --output PATH
  [--batch-size 20]
```

- [ ] **Step 4: Run focused and full tests**

```bash
/usr/local/bin/Rscript tests/figureforge/test_batch_planning.R
for test_file in tests/figureforge/*.R; do
  /usr/local/bin/Rscript "$test_file" || exit 1
done
```

Expected: all tests pass.

- [ ] **Step 5: Commit**

```bash
git add skills/figureforge/lib/batch_planning.R \
  skills/figureforge/scripts/plan_case_batches.R \
  tests/figureforge/test_batch_planning.R
git commit -m "feat: plan FigureForge case waves"
```

### Task 5: Document Blockers And Batch Operations

**Files:**

- Create:
  `skills/figureforge/references/blocker-contract.md`
- Modify:
  `skills/figureforge/SKILL.md`
- Modify:
  `skills/figureforge/references/gallery-index.md`
- Modify:
  `README.md`
- Modify:
  `README.zh.md`
- Modify:
  `docs/figureforge-skill-mvp-status.md`
- Test:
  `tests/figureforge/test_skill_workflow.R`

- [ ] **Step 1: Add failing documentation assertions**

Require all user-facing workflow documents to name:

- `validate_blocker.R`;
- `plan_case_batches.R`;
- `terminal_outcome`;
- `blocked_source_missing`;
- the rule that a valid blocker and verified QA cannot coexist.

- [ ] **Step 2: Run and observe RED**

```bash
/usr/local/bin/Rscript tests/figureforge/test_skill_workflow.R
```

Expected: documentation assertion failure.

- [ ] **Step 3: Write the public blocker reference and update workflows**

Document exact blocker headings, supported statuses, validation command, audit
columns, and conservative interpretation. Keep MCP explicitly planned and
unimplemented.

- [ ] **Step 4: Run all tests and official Skill validation**

```bash
for test_file in tests/figureforge/*.R; do
  /usr/local/bin/Rscript "$test_file" || exit 1
done

PYTHONPATH=/Users/liuyue/.cache/uv/archive-v0/APofJF0GSt0PJz1f \
  python3 \
  /Users/liuyue/.codex/skills/.system/skill-creator/scripts/quick_validate.py \
  skills/figureforge
```

Expected: all R tests pass and `Skill is valid!`.

- [ ] **Step 5: Commit**

```bash
git add README.md README.zh.md docs/figureforge-skill-mvp-status.md \
  skills/figureforge/SKILL.md \
  skills/figureforge/references/blocker-contract.md \
  skills/figureforge/references/gallery-index.md \
  tests/figureforge/test_skill_workflow.R
git commit -m "docs: define complete corpus operations"
```

### Task 6: Refresh The Baseline And Create The Authoritative Wave Manifest

**Files:**

- Write ignored:
  `outputs/figureforge-complete-corpus/baseline/`
- Write ignored:
  `outputs/figureforge-complete-corpus/batch-manifest.csv`
- Write ignored:
  `outputs/figureforge-complete-corpus/wave-progress.md`

- [ ] **Step 1: Run the full 165-case audit**

```bash
/usr/local/bin/Rscript skills/figureforge/scripts/audit_cases.R \
  --cases-dir \
  /Users/liuyue/Desktop/Github_repos/FigureForge/skills/figureforge/cases \
  --output-dir \
  outputs/figureforge-complete-corpus/baseline \
  --rscript /usr/local/bin/Rscript \
  --render
```

Expected: exactly 165 rows, 15 completed, 0 blocked, and 150 pending.

- [ ] **Step 2: Generate 20-case waves**

```bash
/usr/local/bin/Rscript skills/figureforge/scripts/plan_case_batches.R \
  --readiness \
  outputs/figureforge-complete-corpus/baseline/case-readiness.csv \
  --output \
  outputs/figureforge-complete-corpus/batch-manifest.csv \
  --batch-size 20
```

Expected: exactly 150 rows assigned deterministically to waves 1–8.

- [ ] **Step 3: Record source integrity**

For every Wave 1 case, save file path, byte size, mtime, and SHA-256 for all
pre-existing files to:

```text
outputs/figureforge-complete-corpus/wave-01/source-integrity-before.csv
```

Use `find`, `stat`, and `shasum -a 256`; do not alter case sources.

- [ ] **Step 4: Write the Wave 1 progress document**

Create an ignored Markdown table with exact case IDs from `wave == 1`,
priority evidence, selected source inputs, authentic reference, dependency
state, current action, validation output, and terminal outcome.

### Task 7: Execute Each Evidence-First Wave

**Files:**

- Modify privately for each manifest row:
  `/Users/liuyue/Desktop/Github_repos/FigureForge/skills/figureforge/cases/<case_id>/case.md`
- Modify privately for each manifest row:
  `/Users/liuyue/Desktop/Github_repos/FigureForge/skills/figureforge/cases/<case_id>/data.csv`
- Modify privately for each manifest row:
  `/Users/liuyue/Desktop/Github_repos/FigureForge/skills/figureforge/cases/<case_id>/plot.R`
- Create privately for completed cases:
  `/Users/liuyue/Desktop/Github_repos/FigureForge/skills/figureforge/cases/<case_id>/qa.md`
- Create privately only for exhausted blockers:
  `/Users/liuyue/Desktop/Github_repos/FigureForge/skills/figureforge/cases/<case_id>/blocker.md`
- Write ignored:
  `outputs/figureforge-complete-corpus/wave-<NN>/`
- Modify publicly after each wave:
  `docs/figureforge-skill-mvp-status.md`

For each wave number present in `batch-manifest.csv`, execute every checklist
step below for every row before advancing.

- [ ] **Step 1: Inventory the exact case**

Read `case.md`, `plot.R`, `source-script.R`, original R scripts, authentic data
files, reproductions, references, and helper functions. Record every inspected
file in the ignored wave progress report.

- [ ] **Step 2: Establish source-to-canonical transformations**

Record exact source files, row counts, columns, units, factor levels, joins,
derived fields, missing-value behavior, and normalization commands. Reject
synthetic scaffold values.

- [ ] **Step 3: Normalize authentic `data.csv`**

Generate only from authentic case sources. Preserve original files. Verify row
counts, IDs, numeric ranges, and a reproducible transform description in
`## Data Provenance`.

- [ ] **Step 4: Refactor authentic plotting logic**

Ensure `plot.R`:

```r
args <- commandArgs(trailingOnly = TRUE)
input_path <- args[[1]]
output_path <- args[[2]]
```

It must check files, columns, values, and declared packages; preserve the
case-specific visual grammar; and write only to `output_path`.

- [ ] **Step 5: Render externally**

```bash
/usr/local/bin/Rscript "<case_dir>/plot.R" \
  "<case_dir>/data.csv" \
  "outputs/figureforge-complete-corpus/wave-<NN>/renders/<case_id>.pdf"
```

Expected: exit zero and a non-empty output.

- [ ] **Step 6: Perform visual QA**

Render reference and fresh PDF previews with Poppler, inspect them, compare
data coverage, geometry, scales, color, annotations, legends, panels, export
dimensions, and visible deviations. Only then create `qa.md` with
`Status: verified`.

- [ ] **Step 7: Run complete validation**

```bash
/usr/local/bin/Rscript skills/figureforge/scripts/validate_case.R \
  "<case_dir>" \
  --complete \
  --render \
  --output \
  "outputs/figureforge-complete-corpus/wave-<NN>/validation/<case_id>.pdf" \
  --rscript /usr/local/bin/Rscript
```

Expected for completed cases: every check PASS.

- [ ] **Step 8: Use blocker records only after exhausted recovery**

If authentic completion remains impossible after source, dependency,
reference, corruption, mapping, and rights investigation, write the exact
`blocker.md` contract and run:

```bash
/usr/local/bin/Rscript skills/figureforge/scripts/validate_blocker.R \
  "<case_dir>"
```

Expected: all blocker checks PASS. Never create blocker evidence for workload
or time.

- [ ] **Step 9: Verify source integrity**

Compare all pre-existing source files against the wave's before-work hashes.
Only intentional canonical `case.md`, `data.csv`, and `plot.R` changes plus new
`qa.md` or `blocker.md` may differ.

- [ ] **Step 10: Refresh the full corpus audit**

```bash
/usr/local/bin/Rscript skills/figureforge/scripts/audit_cases.R \
  --cases-dir \
  /Users/liuyue/Desktop/Github_repos/FigureForge/skills/figureforge/cases \
  --output-dir \
  outputs/figureforge-complete-corpus/wave-<NN>/audit \
  --rscript /usr/local/bin/Rscript \
  --render
```

Expected: exactly 165 rows and no regression among earlier processed cases.

- [ ] **Step 11: Run public verification**

```bash
for test_file in tests/figureforge/*.R; do
  /usr/local/bin/Rscript "$test_file" || exit 1
done
git diff --check
```

Expected: all tests pass and no whitespace errors.

- [ ] **Step 12: Update aggregate status and commit public changes**

Update only aggregate counts and coverage in
`docs/figureforge-skill-mvp-status.md`. Confirm private case files and ignored
outputs are absent from `git status --short`, then commit:

```bash
git add docs/figureforge-skill-mvp-status.md
git commit -m "docs: record FigureForge corpus wave <NN>"
```

Do not push.

### Task 8: Resolve The Final Pending Set

**Files:**

- Read ignored:
  `outputs/figureforge-complete-corpus/wave-*/audit/case-readiness.csv`
- Modify privately:
  remaining pending case directories
- Write ignored:
  `outputs/figureforge-complete-corpus/final-recovery/`

- [ ] **Step 1: Generate the final pending list**

Read the latest audit and require each pending row to show which completion or
blocker evidence is absent.

- [ ] **Step 2: Perform one evidence-backed recovery pass per pending case**

Run dependency checks, search preserved local assets, inspect archives and
RData without destructive extraction into case sources, test authentic scripts
externally, and record exact findings.

- [ ] **Step 3: Complete or validly block every remaining case**

Use the completed-case or blocker contracts. Do not accept pending rows in the
final audit.

- [ ] **Step 4: Verify zero pending cases**

Run the full 165-case audit and assert:

```r
stopifnot(nrow(readiness) == 165L)
stopifnot(sum(readiness$processed) == 165L)
stopifnot(sum(readiness$terminal_outcome == "pending") == 0L)
```

### Task 9: Final Documentation And Clean-Clone Verification

**Files:**

- Modify:
  `README.md`
- Modify:
  `README.zh.md`
- Modify:
  `skills/figureforge/SKILL.md`
- Modify:
  `skills/figureforge/references/gallery-index.md`
- Modify:
  `docs/figureforge-skill-mvp-status.md`
- Write ignored:
  `outputs/figureforge-complete-corpus/final-report.md`

- [ ] **Step 1: Synchronize final aggregate documentation**

Record final completed, blocked, pending, scaffolded, reproduced, public-ready,
and private-only counts; chart-family coverage; commands; limitations; and MCP
boundary. Do not publish private case data or images.

- [ ] **Step 2: Run all public tests and parse all R files**

```bash
for test_file in tests/figureforge/*.R; do
  /usr/local/bin/Rscript "$test_file" || exit 1
done

for script_file in skills/figureforge/lib/*.R \
  skills/figureforge/scripts/*.R; do
  /usr/local/bin/Rscript -e \
    'parse(file=commandArgs(trailingOnly=TRUE)[1])' \
    "$script_file" >/dev/null || exit 1
done
```

Expected: every command exits zero.

- [ ] **Step 3: Run official Skill validation**

```bash
PYTHONPATH=/Users/liuyue/.cache/uv/archive-v0/APofJF0GSt0PJz1f \
  python3 \
  /Users/liuyue/.codex/skills/.system/skill-creator/scripts/quick_validate.py \
  skills/figureforge
```

Expected: `Skill is valid!`.

- [ ] **Step 4: Verify a clean local clone**

Clone the current branch to a temporary directory and run:

- all FigureForge tests;
- official Skill validation;
- template dependency check;
- template render;
- adaptation fixture render;
- index generation and search.

Expected: all commands exit zero and generated outputs remain ignored.

- [ ] **Step 5: Confirm distribution and MCP boundaries**

Assert:

- no private case file is staged or tracked;
- no generated audit, index, preview, or render is staged;
- `mcp/figureforge` does not exist;
- README files describe MCP as planned only.

- [ ] **Step 6: Create the final local commit**

```bash
git add README.md README.zh.md docs/figureforge-skill-mvp-status.md \
  skills/figureforge
git diff --cached --check
git commit -m "docs: finalize complete FigureForge Skill corpus"
```

Do not push.

- [ ] **Step 7: Write the ignored final report**

Include:

- final 165-case classification counts;
- every newly completed case ID;
- every blocked case and status;
- chart-family coverage;
- verification commands and outputs;
- local commit hashes;
- private artifact locations;
- the exact public interfaces available to future MCP work.
