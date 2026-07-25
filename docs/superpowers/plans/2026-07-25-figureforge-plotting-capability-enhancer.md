# FigureForge Plotting Capability Enhancer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Release FigureForge Skill v1.1.0 as a case-enhanced R plotting capability that turns a natural-language request plus real data into a reusable `plot.R`, `plot.png`, and `plot.pdf`.

**Architecture:** Keep one installable `figureforge` Skill and the existing case/search/release infrastructure. Replace the user-facing nine-stage case-migration workflow with a concise plotting workflow, move corpus and release governance into a maintainer reference, and add a bounded live plotting evaluation that proves an installed Skill can create and independently rerender all three artifacts.

**Tech Stack:** Markdown Skill instructions, R/Rscript, ggplot2 and specialist R packages selected per case, POSIX shell, Codex CLI live evaluations, existing FigureForge R validation and packaging libraries.

---

## Execution Preconditions

- Use `/usr/local/bin/Rscript` for local R tests.
- Create an isolated worktree with `superpowers:using-git-worktrees` before
  implementation. Use a `codex/figureforge-v110` branch unless it already
  exists.
- Start from commit `dcb79b4` or a descendant containing
  `docs/superpowers/specs/2026-07-25-figureforge-plotting-capability-enhancer-design.md`.
- Preserve all existing private cases and ignored local outputs.
- Do not implement MCP.
- Do not rewrite the historical v1.0.0 or v1.0.1 release-evidence documents.

## Planned File Structure

### Create

- `skills/figureforge/references/plotting-workflow.md` — concise operational
  contract for data inspection, case use, artifact creation, rerendering, and
  conversational iteration.
- `skills/figureforge/references/maintainer-workflow.md` — entry point for the
  existing case, distribution, audit, evaluation, package, and release tools.
- `tests/fixtures/figureforge/plotting-eval/scatter.csv` — small real-input
  live-evaluation fixture with grouping and Chinese labels.
- `scripts/run_figureforge_plotting_eval.sh` — package, install, invoke Codex,
  verify `plot.R`/PNG/PDF, and independently rerender them.
- `tests/figureforge/test_plotting_eval_contract.R` — deterministic fake-Codex
  test for the new live plotting harness.
- `scripts/verify_figureforge_v110.sh` — v1.1.0 release verifier that preserves
  v1.0.1 platform gates and adds the plotting-artifact gate.
- `tests/figureforge/test_v110_documentation.R` — v1.1.0 product and release
  documentation contract.
- `docs/figureforge-skill-v1.1.0-release.md` — verified v1.1.0 evidence written
  after the release command passes.

### Modify

- `skills/figureforge/SKILL.md` — user-facing plotting enhancer entry point.
- `skills/figureforge/agents/openai.yaml` — natural plotting request default.
- `skills/figureforge/VERSION` — `1.1.0`.
- `tests/figureforge/test_v1_skill_contract.R` — new main-Skill and artifact
  contract.
- `tests/figureforge/test_skill_trigger_contract.R` — plotting-oriented
  discovery language without weakening installed-path checks.
- `tests/figureforge/test_skill_workflow.R` — maintainer commands belong in the
  maintainer reference, not every user document.
- `tests/figureforge/test_release_packaging.R` — current package version and
  inclusion of both new references.
- `tests/figureforge/test_v1_documentation.R` — current v1.1.0 README contract.
- `scripts/run_figureforge_live_evals.sh` — update trigger prompts from
  “return the first safety command” to “select the plotting capability and
  name its three artifacts”; keep this harness read-only.
- `README.md` — English plotting-enhancer quick start and maintainer boundary.
- `README.zh.md` — matching Chinese positioning.
- `docs/figureforge-skill-mvp-status.md` — current v1.1.0 outcome and separated
  user/platform evidence.
- `CHANGELOG.md` — v1.1.0 entry.

## Task 1: Lock the New User-Facing Skill Contract

**Files:**

- Modify: `tests/figureforge/test_v1_skill_contract.R`
- Modify: `tests/figureforge/test_skill_trigger_contract.R`
- Modify: `tests/figureforge/test_skill_workflow.R`
- Test: `tests/figureforge/test_v1_skill_contract.R`
- Test: `tests/figureforge/test_skill_trigger_contract.R`
- Test: `tests/figureforge/test_skill_workflow.R`

- [ ] **Step 1: Replace the old nine-stage assertions with the plotting contract**

In `tests/figureforge/test_v1_skill_contract.R`, change `reference_paths` to:

```r
reference_paths <- file.path(
  repo_root,
  "skills",
  "figureforge",
  "references",
  c(
    "plotting-workflow.md",
    "maintainer-workflow.md",
    "ggplot-patterns.md",
    "theme-and-export.md",
    "data-mapping.md"
  )
)
```

Replace the old command and safety-language assertions with:

```r
stopifnot(length(skill_lines) < 260L)
stopifnot(all(file.exists(reference_paths)))
stopifnot(grepl("plot.R", skill_text, fixed = TRUE))
stopifnot(grepl("plot.png", skill_text, fixed = TRUE))
stopifnot(grepl("plot.pdf", skill_text, fixed = TRUE))
stopifnot(grepl(
  "Rscript plot.R <input-file> <output-directory>",
  skill_text,
  fixed = TRUE
))
stopifnot(grepl("primary case", skill_lower, fixed = TRUE))
stopifnot(grepl("secondary cases", skill_lower, fixed = TRUE))
stopifnot(grepl("scientific meaning", skill_lower, fixed = TRUE))
stopifnot(grepl("ggplot2", skill_text, fixed = TRUE))
stopifnot(grepl("specialist R packages", skill_text, fixed = TRUE))
stopifnot(grepl("MCP is planned and unimplemented", skill_text, fixed = TRUE))

ordinary_flow_forbidden <- c(
  "Read `case.md`, `case.yml`, `data.csv`, `plot.R`, `qa.md`, and",
  "Write `mapping.md` before editing",
  "validate_blocker.R",
  "plan_case_batches.R"
)
stopifnot(!any(vapply(
  ordinary_flow_forbidden,
  grepl,
  logical(1),
  x = skill_text,
  fixed = TRUE
)))

plotting_reference <- paste(
  readLines(reference_paths[[1L]], warn = FALSE, encoding = "UTF-8"),
  collapse = "\n"
)
maintainer_reference <- paste(
  readLines(reference_paths[[2L]], warn = FALSE, encoding = "UTF-8"),
  collapse = "\n"
)
stopifnot(grepl("plot.R", plotting_reference, fixed = TRUE))
stopifnot(grepl("plot.png", plotting_reference, fixed = TRUE))
stopifnot(grepl("plot.pdf", plotting_reference, fixed = TRUE))
for (command in c(
  "validate_blocker.R",
  "plan_case_batches.R",
  "audit_cases.R",
  "package_skill.R",
  "verify_release.R"
)) {
  stopifnot(grepl(command, maintainer_reference, fixed = TRUE))
}

stopifnot(grepl("synthetic fixtures", maintainer_reference, fixed = TRUE))
stopifnot(grepl("review_required", maintainer_reference, fixed = TRUE))
stopifnot(grepl("Automated checks never", maintainer_reference, fixed = TRUE))

agent_lower <- tolower(agent_text)
stopifnot(grepl("real data", agent_lower, fixed = TRUE))
stopifnot(grepl("primary case", agent_lower, fixed = TRUE))
stopifnot(grepl("plot.r", agent_lower, fixed = TRUE))
stopifnot(grepl("plot.png", agent_lower, fixed = TRUE))
stopifnot(grepl("plot.pdf", agent_lower, fixed = TRUE))
stopifnot(!grepl("mcp server", agent_lower, fixed = TRUE))

referenced_paths <- c(
  "skills/figureforge/scripts/search_cases.R",
  "skills/figureforge/references/plotting-workflow.md",
  "skills/figureforge/references/maintainer-workflow.md",
  "skills/figureforge/references/ggplot-patterns.md",
  "skills/figureforge/references/theme-and-export.md",
  "skills/figureforge/references/data-mapping.md"
)
stopifnot(all(file.exists(file.path(repo_root, referenced_paths))))
```

Delete the old `public-cases`/`synthetic stress fixtures` aggregate-reference
assertions, the old `public`/`review_required` agent assertions, and the regex
command-path scan. The explicit assertions above replace them and keep the
main-Skill, maintainer, metadata, and referenced-path responsibilities
separate.

- [ ] **Step 2: Change trigger assertions to plotting-enhancer language**

In `tests/figureforge/test_skill_trigger_contract.R`, replace the description
and agent-prompt assertions with:

```r
stopifnot(length(description) == 1L)
stopifnot(startsWith(description, "Use when"))
stopifnot(grepl("R", description, fixed = TRUE))
stopifnot(grepl("scientific", description, ignore.case = TRUE))
stopifnot(grepl("plot", description, ignore.case = TRUE))
stopifnot(grepl("data-only", description, fixed = TRUE))
stopifnot(grepl("Chinese or English", description, fixed = TRUE))
stopifnot(length(strsplit(description, "\\s+")[[1L]]) <= 45L)
stopifnot(!grepl("then", description, ignore.case = TRUE))

stopifnot(grepl("case-enhanced", skill_lower, fixed = TRUE))
stopifnot(grepl(
  "rscript plot.r <input-file> <output-directory>",
  skill_lower,
  fixed = TRUE
))
stopifnot(grepl("scientific meaning", skill_lower, fixed = TRUE))
stopifnot(grepl("MCP is planned and unimplemented", skill_text, fixed = TRUE))
stopifnot(!grepl(
  "Read `case.md`, `case.yml`, `data.csv`, `plot.R`, `qa.md`, and",
  skill_text,
  fixed = TRUE
))

agent_lower <- tolower(agent_text)
stopifnot(grepl("\\$figureforge", agent_text))
stopifnot(grepl("inspect the real data", agent_lower, fixed = TRUE))
stopifnot(grepl("primary case", agent_lower, fixed = TRUE))
stopifnot(grepl("plot.r", agent_lower, fixed = TRUE))
stopifnot(grepl("plot.png", agent_lower, fixed = TRUE))
stopifnot(grepl("plot.pdf", agent_lower, fixed = TRUE))
stopifnot(!grepl("external adaptation", agent_lower, fixed = TRUE))
stopifnot(!grepl("/usr/local/bin/Rscript", agent_text, fixed = TRUE))
```

Delete the old main-Skill assertions for authentic/synthetic provenance,
mandatory case metadata, and the Rscript-resolution sentence; those concerns
remain tested by the public-case, dependency-doctor, and packaging suites.
Keep all existing shell syntax, installed-path, stdin, fake-Codex, and
threshold assertions until Task 4 deliberately updates those prompts.

- [ ] **Step 3: Move maintainer-command expectations out of user documents**

At the bottom of `tests/figureforge/test_skill_workflow.R`, read the new
maintainer reference:

```r
maintainer_reference <- read_repo_text(
  "skills/figureforge/references/maintainer-workflow.md"
)
```

Replace the assertions that require blocker and batch commands in
`SKILL.md`/README files with:

```r
for (command in c("validate_blocker.R", "plan_case_batches.R")) {
  stopifnot(grepl(command, maintainer_reference, fixed = TRUE))
  stopifnot(!grepl(command, skill_text, fixed = TRUE))
}
for (document in list(gallery_reference, blocker_reference, maintainer_reference)) {
  stopifnot(grepl("terminal_outcome", document, fixed = TRUE))
  stopifnot(grepl("blocked_source_missing", document, fixed = TRUE))
}
for (document in list(blocker_reference, maintainer_reference)) {
  stopifnot(grepl(
    "verified QA and a valid blocker cannot coexist",
    document,
    fixed = TRUE
  ))
}
```

- [ ] **Step 4: Run the three tests and verify they fail for the intended reasons**

Run:

```bash
/usr/local/bin/Rscript tests/figureforge/test_v1_skill_contract.R
/usr/local/bin/Rscript tests/figureforge/test_skill_trigger_contract.R
/usr/local/bin/Rscript tests/figureforge/test_skill_workflow.R
```

Expected: each command exits non-zero. Failures must mention missing
`plotting-workflow.md`/`maintainer-workflow.md`, missing three-artifact
language, or the old maintainer commands still present in `SKILL.md`. Fix the
test if it fails for an unrelated syntax or path error.

- [ ] **Step 5: Commit the red tests**

```bash
git add \
  tests/figureforge/test_v1_skill_contract.R \
  tests/figureforge/test_skill_trigger_contract.R \
  tests/figureforge/test_skill_workflow.R
git commit -m "test: define FigureForge plotting enhancer contract"
```

## Task 2: Rewrite the Main Skill and Separate Maintainer Guidance

**Files:**

- Modify: `skills/figureforge/SKILL.md`
- Modify: `skills/figureforge/agents/openai.yaml`
- Create: `skills/figureforge/references/plotting-workflow.md`
- Create: `skills/figureforge/references/maintainer-workflow.md`
- Test: `tests/figureforge/test_v1_skill_contract.R`
- Test: `tests/figureforge/test_skill_trigger_contract.R`
- Test: `tests/figureforge/test_skill_workflow.R`

- [ ] **Step 1: Replace the Skill frontmatter and opening contract**

Use this frontmatter and product definition in `skills/figureforge/SKILL.md`:

```markdown
---
name: figureforge
description: Use when a user needs an R-based scientific plot from real data, including explicit or data-only Chinese or English requests, reusable R scripts, rendering, or visual refinement.
---

# FigureForge

FigureForge is a case-enhanced scientific plotting capability for R. Read the
user's real data, understand the scientific relationship, use the gallery as
visual and code experience, write and run a standalone R script, and return:

- `plot.R`
- `plot.png`
- `plot.pdf`

Use ggplot2 by default and specialist R packages when the chart family benefits
from them. MCP is planned and unimplemented.
```

- [ ] **Step 2: Replace the ordinary workflow with the approved concise flow**

The main body must contain these sections in this order:

```markdown
## Default Workflow

1. Inspect the real input file and its actual columns, types, missingness,
   groups, duplicate keys, and values relevant to the requested comparison.
2. Interpret the scientific intent. Honor an explicit chart family when the
   data can support it.
3. Search the installed gallery in the background. Choose one primary case for
   overall composition and use secondary cases only for useful local patterns.
4. Ask the user only when unresolved ambiguity would change the scientific
   meaning. Choose professional defaults for presentation details.
5. Write a standalone `plot.R` for the user's data.
6. Run it to generate `plot.png` and `plot.pdf`, inspect both outputs, fix
   failures or visible defects, and rerun.
7. Return all three paths plus a short explanation of field mappings and
   material design choices.

## Data and Case Use

Resolve `FIGUREFORGE_SKILL_ROOT` to the installed directory containing this
`SKILL.md`. Search with the user's scientific intent, chart family, and schema:

```bash
Rscript "$FIGUREFORGE_SKILL_ROOT/scripts/search_cases.R" \
  --public \
  --query "<scientific intent and chart terms>" \
  --schema "<input-file>" \
  --explain-scores \
  --limit 5
```

Use a case's explanation, `plot.R`, and relevant schema as working knowledge.
The final script is newly adapted to the user's data and may combine compatible
ideas from multiple cases. Do not mechanically copy one case or require the
user to operate case metadata.

## Artifact Contract

The delivered script supports:

```bash
Rscript plot.R <input-file> <output-directory>
```

It validates the input and required columns, declares package dependencies,
uses deterministic settings when needed, preserves supported Chinese names and
labels, and creates non-empty `plot.png` and `plot.pdf` in the output
directory. It must not depend on temporary agent-session state.

## When to Ask

Ask before choosing among plausible x/y fields, group meanings, aggregation,
normalization, repeated-measure handling, statistical tests, or units when the
choice changes the scientific meaning. Do not interrupt for theme, palette,
font size, legend position, point size, or initial dimensions.

## Render, Inspect, and Repair

Run the script before delivery. Confirm the three artifacts exist, rerun the
script independently, open or render both images, and check expected rows,
groups, labels, legends, clipping, overlap, empty panels, and readability.
Diagnose and repair code or render failures instead of delivering unexecuted
example code.

Use `references/plotting-workflow.md` for the detailed task-level checklist.
Use `references/ggplot-patterns.md`, `references/theme-and-export.md`, and
`references/data-mapping.md` only as needed.

## Iteration

Follow-up requests modify the existing `plot.R` and regenerate both images.
Preserve confirmed mappings and design decisions unless the user changes them.

## Maintainer Boundary

Case authoring, corpus auditing, blockers, provenance, distribution, stress
fixtures, packaging, and release certification are maintainer concerns. They
are not required ceremony for an ordinary plotting request. Maintainers use
`references/maintainer-workflow.md`.
```

- [ ] **Step 3: Add the detailed plotting reference**

Create `skills/figureforge/references/plotting-workflow.md` with:

```markdown
# Plotting Workflow

## Input inspection

Read the real file before selecting a case. Record the actual names and types,
missing values, group levels, duplicate keys, relevant ranges, units when
available, and transformations required by the scientific question.

## Case strategy

Choose one primary case by scientific comparison, data shape, visual grammar,
and dependency availability. Use secondary cases only for local patterns such
as palettes, annotations, labels, panels, or specialist package idioms. The
case library is working knowledge, not a mandatory one-case migration gate.

## Output

Create `plot.R`, `plot.png`, and `plot.pdf` outside the installed Skill and
outside every source case. `plot.R` accepts the input file and output directory
as its first two arguments and generates both images.

## Script requirements

- validate argument count, input existence, required columns, and critical
  values;
- declare and check packages explicitly;
- set deterministic seeds for stochastic layouts or label placement;
- preserve user data and never overwrite the input;
- create the output directory when safe;
- use publication-appropriate dimensions, text sizes, and vector PDF output;
- fail with a specific, actionable message.

## Task-level review

Rerun the delivered script in a fresh output directory. Confirm all artifacts
are non-empty and both images open. Inspect data coverage, mappings, groups,
labels, legends, scales, panels, clipping, overlap, and readability. This
review checks the user's result; it does not certify a source case or release.

## Delivery

Return clickable paths for `plot.R`, `plot.png`, and `plot.pdf`, followed by a
short note naming the primary case, important field mappings, specialist R
packages, and any unresolved scientific limitation.
```

- [ ] **Step 4: Add the maintainer entry point without duplicating manuals**

Create `skills/figureforge/references/maintainer-workflow.md` with exact
sections for:

```markdown
# Maintainer Workflow

This reference owns case and release governance. It is not the ordinary
user-facing plotting workflow.

## Case lifecycle

- Validate a case: `scripts/validate_case.R`
- Validate public metadata and distribution: `scripts/validate_public_case.R`
  and `scripts/validate_distribution.R`
- Rebuild indexes: `scripts/index_cases.R`
- Audit the corpus: `scripts/audit_cases.R`

## Terminal outcomes

Use `scripts/validate_blocker.R` and `scripts/plan_case_batches.R`. Every
record carries `terminal_outcome`; supported outcomes include
`blocked_source_missing`. A verified QA and a valid blocker cannot coexist.

## Evaluation

Use `scripts/run_stress_tests.R` and `scripts/evaluate_skill.R`. Synthetic
fixtures test software behavior and never make scientific claims. Automated
checks never promote `review_required` to verified.

## Release

Use `scripts/package_skill.R` to create the allowlisted archive and manifest,
then `scripts/verify_release.R` to validate the sidecar, members, sizes, and
hashes. Private cases, source figures, reproductions, generated renders, and
raw transcripts stay outside the public package.

## Detailed contracts

Use `adaptation-contract.md`, `blocker-contract.md`, `qa-checklist.md`, the
schemas directory, and the version-specific release evidence for detailed
rules.
```

- [ ] **Step 5: Change the installed agent prompt**

Replace `skills/figureforge/agents/openai.yaml` with:

```yaml
interface:
  display_name: "FigureForge"
  short_description: "Create publication-ready R plots from real data"
  default_prompt: "Use $figureforge to inspect the real data, choose a primary case and optional secondary patterns, write and run a standalone plot.R, and return plot.R, plot.png, and plot.pdf."
```

- [ ] **Step 6: Run the focused contract tests**

```bash
/usr/local/bin/Rscript tests/figureforge/test_v1_skill_contract.R
/usr/local/bin/Rscript tests/figureforge/test_skill_trigger_contract.R
/usr/local/bin/Rscript tests/figureforge/test_skill_workflow.R
```

Expected:

```text
v1 skill contract tests: PASS
skill trigger contract tests: PASS
skill workflow tests: PASS
```

- [ ] **Step 7: Commit the Skill boundary**

```bash
git add \
  skills/figureforge/SKILL.md \
  skills/figureforge/agents/openai.yaml \
  skills/figureforge/references/plotting-workflow.md \
  skills/figureforge/references/maintainer-workflow.md
git commit -m "feat: refocus FigureForge on plotting delivery"
```

## Task 3: Add an Executable Three-Artifact Live Evaluation

**Files:**

- Create: `tests/fixtures/figureforge/plotting-eval/scatter.csv`
- Create: `scripts/run_figureforge_plotting_eval.sh`
- Create: `tests/figureforge/test_plotting_eval_contract.R`
- Test: `tests/figureforge/test_plotting_eval_contract.R`

- [ ] **Step 1: Add the real-input fixture**

Create `tests/fixtures/figureforge/plotting-eval/scatter.csv`:

```csv
样本,喙长_mm,喙深_mm,物种
S01,39.1,18.7,Adelie
S02,39.5,17.4,Adelie
S03,40.3,18.0,Adelie
S04,36.7,19.3,Adelie
S05,46.5,17.9,Chinstrap
S06,50.0,19.5,Chinstrap
S07,51.3,19.2,Chinstrap
S08,45.4,14.6,Gentoo
S09,46.1,13.2,Gentoo
S10,48.7,14.1,Gentoo
S11,49.6,16.0,Gentoo
S12,50.5,15.9,Gentoo
```

- [ ] **Step 2: Write the harness contract test first**

Create `tests/figureforge/test_plotting_eval_contract.R`. The test must:

1. assert `bash -n scripts/run_figureforge_plotting_eval.sh` succeeds;
2. assert the shell source contains `--sandbox workspace-write`,
   `plot.R`, `plot.png`, `plot.pdf`, and `independent-rerender`;
3. create a fake Codex executable that parses `-C` and `-o`, writes a valid
   base-R `figureforge-output/plot.R`, runs it once, and writes a final message;
4. run the harness with `--codex <fake>` and a temporary output directory;
5. assert all three delivered artifacts and both independent-rerender images
   are non-empty;
6. assert `summary.csv` contains one row with every gate equal to `true`.

Use this exact plotting body in the fake Codex script so the deterministic
contract does not require ggplot2:

```r
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2L) stop("Usage: Rscript plot.R <input-file> <output-directory>")
input <- read.csv(args[[1L]], check.names = FALSE, fileEncoding = "UTF-8")
required <- c("喙长_mm", "喙深_mm", "物种")
missing <- setdiff(required, names(input))
if (length(missing) > 0L) stop("Missing columns: ", paste(missing, collapse = ", "))
dir.create(args[[2L]], recursive = TRUE, showWarnings = FALSE)
draw <- function(path, device) {
  device(path)
  on.exit(dev.off(), add = TRUE)
  groups <- as.integer(factor(input[["物种"]]))
  plot(
    input[["喙长_mm"]],
    input[["喙深_mm"]],
    col = groups,
    pch = 19,
    xlab = "Bill length (mm)",
    ylab = "Bill depth (mm)"
  )
  legend("topright", legend = levels(factor(input[["物种"]])), col = seq_along(unique(groups)), pch = 19)
}
draw(file.path(args[[2L]], "plot.png"), function(path) png(path, width = 1600, height = 1200, res = 180))
draw(file.path(args[[2L]], "plot.pdf"), function(path) pdf(path, width = 8, height = 6))
```

- [ ] **Step 3: Run the contract test and verify the missing-harness failure**

```bash
/usr/local/bin/Rscript tests/figureforge/test_plotting_eval_contract.R
```

Expected: FAIL because `scripts/run_figureforge_plotting_eval.sh` does not yet
exist.

- [ ] **Step 4: Implement the bounded plotting harness**

Create `scripts/run_figureforge_plotting_eval.sh` using
`set -euo pipefail`. It must:

- resolve `REPO_ROOT`, `CODEX_BIN`, and Rscript using
  `FIGUREFORGE_RSCRIPT`, `/usr/local/bin/Rscript`, then `PATH`;
- accept `--output-dir`, `--codex`, and optional `--model`;
- reject a non-empty output directory;
- package the current Skill and install it under a temporary
  `.agents/skills/figureforge`;
- copy the fixture to `<install-root>/scatter.csv`;
- invoke Codex with `--sandbox workspace-write`, `-C <install-root>`, JSON
  output, and this prompt:

```text
Use $figureforge with scatter.csv. Draw a publication-ready scatter plot of
喙长_mm versus 喙深_mm colored by 物种. Work without asking about presentation
details. Create figureforge-output/plot.R, plot.png, and plot.pdf, execute the
script, inspect the outputs, and return the three paths. Before acting, read
the installed Skill.
```

- assert the installed Skill was read in the transcript;
- assert `figureforge-output/plot.R`, `plot.png`, and `plot.pdf` are non-empty;
- rerun:

```bash
"$RSCRIPT" \
  "$INSTALL_ROOT/figureforge-output/plot.R" \
  "$INSTALL_ROOT/scatter.csv" \
  "$OUTPUT_DIR/independent-rerender"
```

- assert the independent PNG and PDF are non-empty;
- write a one-row `summary.csv` with columns:

```text
exit_status,skill_loaded,script_exists,png_exists,pdf_exists,rerender_png,rerender_pdf,passed
```

- exit non-zero unless every gate is true.

- [ ] **Step 5: Run the fake-Codex contract**

```bash
/usr/local/bin/Rscript tests/figureforge/test_plotting_eval_contract.R
```

Expected:

```text
plotting eval contract tests: PASS
```

- [ ] **Step 6: Commit the executable evaluation**

```bash
git add \
  tests/fixtures/figureforge/plotting-eval/scatter.csv \
  scripts/run_figureforge_plotting_eval.sh \
  tests/figureforge/test_plotting_eval_contract.R
git commit -m "test: add FigureForge plotting artifact evaluation"
```

## Task 4: Align Trigger Evaluations with the New Mental Model

**Files:**

- Modify: `scripts/run_figureforge_live_evals.sh`
- Modify: `tests/figureforge/test_skill_trigger_contract.R`
- Test: `tests/figureforge/test_skill_trigger_contract.R`

- [ ] **Step 1: Change the bounded trigger prompts**

Keep the existing one explicit and ten implicit probes, packaging, read-only
sandbox, thresholds, and installed-Skill-read evidence. Rewrite prompt endings
so they ask for:

```text
Return only the selected capability and the three artifact names it would
create. Do not execute the plotting task.
```

The explicit probe must begin:

```text
Use $figureforge with a CSV to create a publication-ready R scatter plot.
```

The ten implicit probes retain the same chart/data diversity but replace
“first safety command” with the three-artifact response.

- [ ] **Step 2: Change result gates**

Replace the `installed_path` summary column and check with
`artifact_contract`. Set it true only when the final message contains all of:

```bash
grep -Fq 'plot.R' "$final_message"
grep -Fq 'plot.png' "$final_message"
grep -Fq 'plot.pdf' "$final_message"
```

Keep `skill_loaded`, `capability_selected`, explicit `1.0`, and implicit
`>= 0.90` gates.

- [ ] **Step 3: Update the fake Codex and contract assertions**

In `tests/figureforge/test_skill_trigger_contract.R`, make the fake Codex final
message contain:

```text
figureforge
plot.R
plot.png
plot.pdf
```

Replace checks for “first command” and `FIGUREFORGE_SKILL_ROOT` with checks for
`artifact_contract`, `plot.R`, `plot.png`, and `plot.pdf`. Keep the expected
11-row summary and all-true assertions.

- [ ] **Step 4: Verify the trigger harness**

```bash
/usr/local/bin/Rscript tests/figureforge/test_skill_trigger_contract.R
```

Expected:

```text
skill trigger contract tests: PASS
```

- [ ] **Step 5: Commit trigger behavior**

```bash
git add \
  scripts/run_figureforge_live_evals.sh \
  tests/figureforge/test_skill_trigger_contract.R
git commit -m "test: align FigureForge triggers with plotting delivery"
```

## Task 5: Reposition the Bilingual Product Documentation

**Files:**

- Modify: `README.md`
- Modify: `README.zh.md`
- Modify: `tests/figureforge/test_v1_documentation.R`
- Modify: `docs/figureforge-skill-mvp-status.md`
- Test: `tests/figureforge/test_v1_documentation.R`

- [ ] **Step 1: Write failing bilingual product assertions**

In `tests/figureforge/test_v1_documentation.R`, change current-version terms
to `1.1.0` and require the English README to contain:

```r
english_terms <- c(
  "plotting capability enhancer",
  "real data",
  "primary case",
  "secondary cases",
  "plot.R",
  "plot.png",
  "plot.pdf",
  "Rscript plot.R <input-file> <output-directory>",
  "maintainer workflow",
  "MCP is planned and unimplemented"
)
```

Require matching Chinese terms:

```r
chinese_terms <- c(
  "绘图能力增强器",
  "真实数据",
  "主案例",
  "辅助案例",
  "plot.R",
  "plot.png",
  "plot.pdf",
  "Rscript plot.R <input-file> <output-directory>",
  "维护者工作流",
  "MCP 状态为 planned 且尚未实现"
)
```

Also assert neither README describes opening every case file as a mandatory
ordinary-user step:

```r
stopifnot(!grepl(
  "Open the case's `case.md`, `data.csv`, `plot.R`, and `qa.md`",
  english,
  fixed = TRUE
))
stopifnot(!grepl(
  "打开案例的 `case.md`、`data.csv`、`plot.R` 和",
  chinese,
  fixed = TRUE
))
```

- [ ] **Step 2: Run the documentation test and verify it fails**

```bash
/usr/local/bin/Rscript tests/figureforge/test_v1_documentation.R
```

Expected: FAIL because the READMEs still lead with v1.0.1 case migration.

- [ ] **Step 3: Rewrite the top-level English experience**

Update `README.md` so its title block says:

```markdown
**A case-enhanced R scientific plotting capability for AI agents.**

> Real data in; reusable R code and publication-ready figures out.
```

Add a `FigureForge Skill 1.1.0` quick start before maintainer commands:

```markdown
Ask your agent:

> Use `xxx.csv` with FigureForge to draw a scatter plot and give me the R
> script.

FigureForge inspects the real data, selects one primary case and optional
secondary cases, writes and runs a standalone script, and returns:

- `plot.R`
- `plot.png`
- `plot.pdf`

The script reruns as:

```bash
Rscript plot.R <input-file> <output-directory>
```
```

Describe case search and task-level QA as background behavior. Move detailed
case validation, auditing, packaging, release, and private-corpus material
under a clearly labeled `Maintainer workflow` section without deleting the
commands.

- [ ] **Step 4: Mirror the positioning in Chinese**

Update `README.zh.md` with the equivalent heading:

```markdown
**面向 AI 智能体、由案例增强的 R 科研绘图能力。**

> 输入真实数据，输出可复用 R 代码与出版级图形。
```

Use this quick-start request:

```markdown
> 使用 `xxx.csv` 数据，基于 FigureForge 帮我绘制一个散点图，并给我一份
> R 脚本。
```

Explain “一个主案例 + 可选辅助案例” and the same three artifacts and rerun
contract. Keep the maintainer information under `维护者工作流`.

- [ ] **Step 5: Update the current status document**

Change `docs/figureforge-skill-mvp-status.md` to lead with v1.1.0's user
outcome:

```markdown
FigureForge Skill 1.1.0 is a case-enhanced R plotting capability. Its ordinary
user flow accepts real data and a natural-language plotting request, then
returns a standalone `plot.R`, `plot.png`, and `plot.pdf`. The existing case,
distribution, stress, packaging, and private-corpus evidence remains the
maintainer reliability layer. MCP remains planned and unimplemented.
```

Split the evidence table into `User plotting behavior` and `Maintainer and
release reliability`. Preserve all factual v1.0.1 corpus counts as historical
platform evidence.

- [ ] **Step 6: Run bilingual documentation and contract tests**

```bash
/usr/local/bin/Rscript tests/figureforge/test_v1_documentation.R
/usr/local/bin/Rscript tests/figureforge/test_v101_documentation.R
/usr/local/bin/Rscript tests/figureforge/test_v1_skill_contract.R
```

Expected: all three pass. The v1.0.1 test must continue proving that the
historical release document and compatibility statements were not erased.

- [ ] **Step 7: Commit bilingual repositioning**

```bash
git add \
  README.md \
  README.zh.md \
  docs/figureforge-skill-mvp-status.md \
  tests/figureforge/test_v1_documentation.R
git commit -m "docs: position FigureForge as a plotting enhancer"
```

## Task 6: Bump v1.1.0 and Extend the Release Gate

**Files:**

- Modify: `skills/figureforge/VERSION`
- Modify: `tests/figureforge/test_release_packaging.R`
- Modify: `CHANGELOG.md`
- Create: `scripts/verify_figureforge_v110.sh`
- Create: `tests/figureforge/test_v110_documentation.R`
- Test: `tests/figureforge/test_release_packaging.R`
- Test: `tests/figureforge/test_v110_documentation.R`

- [ ] **Step 1: Write the v1.1.0 packaging assertions**

In `tests/figureforge/test_release_packaging.R`, change:

```r
stopifnot(identical(current_version, "1.1.0"))
```

Add:

```r
for (member in c(
  "figureforge/references/plotting-workflow.md",
  "figureforge/references/maintainer-workflow.md"
)) {
  stopifnot(any(manifest$package_path == member))
}
```

- [ ] **Step 2: Set the package version and verify the focused package test**

Write exactly `1.1.0` plus a trailing newline to
`skills/figureforge/VERSION`, then run:

```bash
/usr/local/bin/Rscript tests/figureforge/test_release_packaging.R
```

Expected:

```text
release packaging tests: PASS
```

- [ ] **Step 3: Add the v1.1.0 changelog entry**

Prepend under `# Changelog`:

```markdown
## 1.1.0 - 2026-07-25

- Reframed FigureForge as a case-enhanced R plotting capability for natural
  requests using real data.
- Added the default `plot.R`, `plot.png`, and `plot.pdf` delivery contract with
  independent rerendering.
- Changed case use to one primary case plus optional secondary visual and code
  patterns.
- Moved case, corpus, distribution, audit, packaging, and release governance
  into a maintainer workflow.
- Added bounded installed-Skill trigger and executable plotting-artifact
  evaluations.
- Preserved the v1.0.1 public gallery, safety, package integrity, upgrade
  history, private-corpus boundary, and planned/unimplemented MCP status.
```

- [ ] **Step 4: Create the v1.1.0 verifier from the existing v1.0.1 gate**

Copy `scripts/verify_figureforge_v101.sh` to
`scripts/verify_figureforge_v110.sh`, then make these bounded changes:

- change variables and artifact names from `V101`/`v101`/`1.0.1` to
  `V110`/`v110`/`1.1.0`;
- expect installed `VERSION` to equal `1.1.0`;
- retain every R test, 15-case render, 24-stress, 30-forward, doctor, archive,
  installed smoke, parsing, boundary, official validator, and diff gate;
- retain `tests/figureforge/test_upgrade_compatibility.R` as historical
  v1.0.0-to-v1.0.1 evidence;
- when `FIGUREFORGE_RUN_LIVE_EVALS=1`, run both:

```bash
bash "$REPO_ROOT/scripts/run_figureforge_live_evals.sh" \
  --output-dir "$VERIFY_ROOT/live-trigger-evals"
bash "$REPO_ROOT/scripts/run_figureforge_plotting_eval.sh" \
  --output-dir "$VERIFY_ROOT/live-plotting-eval"
```

- finish with:

```text
FigureForge Skill v1.1.0 acceptance: PASS
```

- [ ] **Step 5: Write the verifier/documentation contract**

Create `tests/figureforge/test_v110_documentation.R`. It must read README.md,
README.zh.md, CHANGELOG.md, `docs/figureforge-skill-mvp-status.md`, the new
verifier, both live-eval scripts, `SKILL.md`, and both new references. Assert:

- all current user documents say `1.1.0`;
- English contains `plotting capability enhancer`;
- Chinese contains `绘图能力增强器`;
- the three artifact names appear in both languages, the Skill, and plotting
  reference;
- the maintainer reference contains blocker, audit, package, and release
  commands;
- the verifier contains the old platform gates plus both live harnesses;
- `sh -n`/`bash -n` succeeds for all three shell scripts;
- no document claims an implemented MCP server;
- the verifier ends with the exact v1.1.0 PASS phrase.

- [ ] **Step 6: Run the v1.1.0 focused tests**

```bash
/usr/local/bin/Rscript tests/figureforge/test_release_packaging.R
/usr/local/bin/Rscript tests/figureforge/test_v110_documentation.R
```

Expected:

```text
release packaging tests: PASS
v1.1.0 documentation tests: PASS
```

- [ ] **Step 7: Commit version and release gate**

```bash
git add \
  skills/figureforge/VERSION \
  tests/figureforge/test_release_packaging.R \
  CHANGELOG.md \
  scripts/verify_figureforge_v110.sh \
  tests/figureforge/test_v110_documentation.R
git commit -m "test: add FigureForge v1.1.0 release gate"
```

## Task 7: Verify, Record Evidence, and Certify v1.1.0

**Files:**

- Create: `docs/figureforge-skill-v1.1.0-release.md`
- Modify: `tests/figureforge/test_v110_documentation.R`
- Test: all `tests/figureforge/*.R`
- Test: `scripts/verify_figureforge_v110.sh`

- [ ] **Step 1: Run all R tests before the wrapper**

```bash
for test_file in tests/figureforge/*.R; do
  /usr/local/bin/Rscript "$test_file"
done
```

Expected: every file exits zero and prints its `PASS` message. Do not proceed
past a failure.

- [ ] **Step 2: Run the complete deterministic v1.1.0 verifier**

```bash
FIGUREFORGE_RUN_LIVE_EVALS=0 \
  /bin/sh scripts/verify_figureforge_v110.sh
```

Expected final line:

```text
FigureForge Skill v1.1.0 acceptance: PASS
```

Capture the printed verification-artifact directory.

- [ ] **Step 3: Run the bounded live gates**

Use a new empty output directory:

```bash
VERIFY_LIVE_ROOT=$(mktemp -d /tmp/figureforge-v110-live.XXXXXX)
bash scripts/run_figureforge_live_evals.sh \
  --output-dir "$VERIFY_LIVE_ROOT/triggers"
bash scripts/run_figureforge_plotting_eval.sh \
  --output-dir "$VERIFY_LIVE_ROOT/plotting"
```

Expected:

- explicit trigger rate `1/1`;
- implicit trigger rate at least `9/10`;
- plotting summary has one row with `passed=true`;
- `plot.R`, `plot.png`, `plot.pdf`, and both independent-rerender images are
  non-empty.

If a live gate fails because of agent behavior, inspect its transcript and
improve `SKILL.md` or the evaluation prompt without weakening the artifact or
rerender requirements. Rerun all affected contract tests.

- [ ] **Step 4: Write the release evidence**

Create `docs/figureforge-skill-v1.1.0-release.md` with:

- date, branch, version, and local-only release policy;
- the new plotting-enhancer product definition;
- the exact three-artifact contract;
- deterministic test and full-verifier outcomes;
- actual explicit and implicit trigger counts from Step 3;
- actual plotting-eval and independent-rerender outcomes;
- unchanged 15 public case, 24 stress fixture, and 30 forward-evaluation
  platform counts;
- package archive, manifest, sidecar, installed validation, and private
  boundary results;
- MCP planned and unimplemented;
- the exact commands used and the actual artifact directories.

Do not record a PASS result that was not observed in Steps 1–3.

- [ ] **Step 5: Make the documentation test require the release evidence**

Extend `tests/figureforge/test_v110_documentation.R` to read the new release
document and require:

```r
release_terms <- c(
  "FigureForge Skill 1.1.0",
  "plot.R",
  "plot.png",
  "plot.pdf",
  "independent rerender",
  "15 public cases",
  "24 synthetic stress fixtures",
  "30 deterministic bilingual forward evaluations",
  "MCP is planned and unimplemented",
  "FigureForge Skill v1.1.0 acceptance: PASS"
)
stopifnot(all(vapply(
  release_terms,
  grepl,
  logical(1),
  x = release,
  fixed = TRUE
)))
```

- [ ] **Step 6: Run final documentation and repository checks**

```bash
/usr/local/bin/Rscript tests/figureforge/test_v110_documentation.R
git diff --check
git status --short
```

Expected:

```text
v1.1.0 documentation tests: PASS
```

`git diff --check` must be silent. `git status --short` may list only the new
release document and its test update.

- [ ] **Step 7: Commit certification evidence**

```bash
git add \
  docs/figureforge-skill-v1.1.0-release.md \
  tests/figureforge/test_v110_documentation.R
git commit -m "test: certify FigureForge Skill v1.1.0"
```

- [ ] **Step 8: Perform the final clean-state verification**

```bash
git status --short
git log -7 --oneline
```

Expected: clean status and a commit chain containing the contract, Skill,
artifact evaluation, trigger, documentation, v1.1.0 gate, and certification
commits. Do not push, tag, or create a pull request unless the user separately
requests it.
