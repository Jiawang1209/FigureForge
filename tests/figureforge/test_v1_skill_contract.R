#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
script_path <- if (length(file_arg) > 0L) {
  normalizePath(sub("^--file=", "", file_arg[[1L]]), mustWork = TRUE)
} else {
  normalizePath("tests/figureforge/test_v1_skill_contract.R", mustWork = TRUE)
}
repo_root <- normalizePath(
  file.path(dirname(script_path), "..", ".."),
  mustWork = TRUE
)

skill_path <- file.path(repo_root, "skills", "figureforge", "SKILL.md")
agent_path <- file.path(
  repo_root,
  "skills",
  "figureforge",
  "agents",
  "openai.yaml"
)
reference_paths <- file.path(
  repo_root,
  "skills",
  "figureforge",
  "references",
  c(
    "plotting-workflow.md",
    "case-use-contract.md",
    "maintainer-workflow.md",
    "ggplot-patterns.md",
    "theme-and-export.md",
    "data-mapping.md"
  )
)
names(reference_paths) <- c(
  "plotting",
  "case_use",
  "maintainer",
  "ggplot_patterns",
  "theme_and_export",
  "data_mapping"
)
referenced_paths <- c(
  file.path(
    repo_root,
    "skills",
    "figureforge",
    "scripts",
    "search_cases.R"
  ),
  unname(reference_paths)
)

assert_path_exists <- function(path) {
  if (!file.exists(path)) {
    stop("Missing required path: ", path, call. = FALSE)
  }
}
assert_contains <- function(text, phrase, label) {
  if (!grepl(phrase, text, fixed = TRUE)) {
    stop(label, " is missing required phrase: ", phrase, call. = FALSE)
  }
}
assert_absent <- function(text, phrase, label) {
  if (grepl(phrase, text, fixed = TRUE)) {
    stop(label, " contains forbidden phrase: ", phrase, call. = FALSE)
  }
}
assert_artifact_return_block <- function(text, label) {
  artifact_block <- paste0(
    "return:[[:blank:]]*(?:\\r?\\n[[:blank:]]*)+",
    "-[[:blank:]]*`?plot\\.r`?[[:blank:]]*",
    "(?:\\r?\\n[[:blank:]]*)+-[[:blank:]]*`?plot\\.png`?[[:blank:]]*",
    "(?:\\r?\\n[[:blank:]]*)+-[[:blank:]]*`?plot\\.pdf`?"
  )
  if (!grepl(artifact_block, text, ignore.case = TRUE, perl = TRUE)) {
    stop(
      label,
      " must couple return: with plot.R, plot.png, and plot.pdf bullets",
      call. = FALSE
    )
  }
}
for (path in referenced_paths) {
  assert_path_exists(path)
}

skill_lines <- readLines(skill_path, warn = FALSE, encoding = "UTF-8")
skill_text <- paste(skill_lines, collapse = "\n")
skill_plain <- gsub("`", "", gsub("\\s+", " ", skill_text))
skill_plain_lower <- tolower(skill_plain)
agent_lines <- readLines(agent_path, warn = FALSE, encoding = "UTF-8")
default_prompt_lines <- grep(
  "^\\s*default_prompt:\\s*",
  agent_lines,
  value = TRUE
)
if (length(default_prompt_lines) != 1L) {
  stop("openai.yaml must contain exactly one anchored default_prompt", call. = FALSE)
}
default_prompt <- trimws(sub(
  "^\\s*default_prompt:\\s*",
  "",
  default_prompt_lines[[1L]]
))
default_prompt <- gsub("^['\"]|['\"]$", "", default_prompt)
default_prompt_lower <- tolower(default_prompt)

stopifnot(length(skill_lines) < 260L)

assert_artifact_return_block(skill_text, "SKILL.md")
assert_contains(
  skill_text,
  "Rscript plot.R <input-file> <output-directory>",
  "SKILL.md"
)
assert_contains(
  skill_plain_lower,
  paste(
    "choose one primary case for overall composition and",
    "use secondary cases only for useful local patterns."
  ),
  "SKILL.md"
)
assert_contains(
  skill_plain_lower,
  paste(
    "ask the user only when unresolved ambiguity would change",
    "the scientific meaning."
  ),
  "SKILL.md"
)
stopifnot(grepl("ggplot2", skill_text, fixed = TRUE))
stopifnot(grepl("specialist R packages", skill_text, fixed = TRUE))
stopifnot(grepl(
  "MCP is planned and unimplemented",
  skill_text,
  fixed = TRUE
))
for (phrase in c(
  "Choose exactly one generation mode after search",
  "Run `search_cases.R` with `--output` before choosing the generation mode",
  "`case_based`",
  "`general_fallback`",
  "actually read `case.md` and `plot.R`",
  "read `qa.md` when it exists",
  ".figureforge/case-trace.yml",
  "case-search.csv",
  "--output",
  "schema mapping",
  "adopted patterns",
  "departures",
  "validate_case_trace.R",
  "Only a successful strict validation authorizes a case-grounded claim",
  "Structural or partial validation never authorizes that claim",
  "Never describe `general_fallback` output as case-grounded",
  "The trace is hidden workflow state, not a fourth visible deliverable",
  "Do not ask the user to inspect, select, or operate the case library"
)) {
  assert_contains(skill_text, phrase, "SKILL.md")
}
stopifnot(!grepl(
  paste(
    "Read case.md, case.yml, data.csv, plot.R, qa.md, and",
    "distribution.yml before adapting a public case."
  ),
  skill_plain,
  fixed = TRUE
))
stopifnot(!grepl(
  "Write mapping.md before editing",
  skill_plain,
  fixed = TRUE
))
maintainer_commands <- c(
  "validate_blocker.R",
  "plan_case_batches.R",
  "audit_cases.R",
  "package_skill.R",
  "verify_release.R"
)
for (command in maintainer_commands) {
  assert_absent(skill_text, command, "SKILL.md")
}

plotting_text <- paste(
  readLines(reference_paths[["plotting"]], warn = FALSE, encoding = "UTF-8"),
  collapse = "\n"
)
for (artifact in c("plot.R", "plot.png", "plot.pdf")) {
  assert_contains(plotting_text, artifact, "plotting-workflow.md")
}
for (phrase in c(
  "case_based",
  "general_fallback",
  "case.md",
  "plot.R",
  "qa.md",
  ".figureforge/case-trace.yml",
  "search_query_sha256",
  "search_intent",
  "search_receipt_file",
  "search_receipt_sha256",
  "case-search.csv",
  "--output",
  "schema_mapping",
  "adopted_patterns",
  "departures",
  "<case evidence>#source anchor => plot.R#generated executable anchor",
  "validate_case_trace.R",
  "--case-dir",
  "--script",
  "--schema",
  "strict",
  "case_grounded",
  "general_method",
  "structural",
  "partial",
  "`qa_status: verified`",
  "`qa_status: review_required`",
  "`qa_status: missing`",
  "Read the unique `Status:` marker",
  "record that status unchanged",
  "Strict validation fails when the declared status conflicts with `qa.md`"
)) {
  assert_contains(
    paste(
      readLines(
        reference_paths[["case_use"]],
        warn = FALSE,
        encoding = "UTF-8"
      ),
      collapse = "\n"
    ),
    phrase,
    "case-use-contract.md"
  )
}

maintainer_text <- paste(
  readLines(
    reference_paths[["maintainer"]],
    warn = FALSE,
    encoding = "UTF-8"
  ),
  collapse = "\n"
)
maintainer_requirements <- c(
  maintainer_commands,
  "synthetic fixtures",
  "review_required",
  "Automated checks never"
)
for (phrase in maintainer_requirements) {
  assert_contains(maintainer_text, phrase, "maintainer-workflow.md")
}

agent_prompt_requirements <- c(
  "$figureforge",
  "inspect the real data",
  "choose a primary case",
  "optional secondary patterns",
  "choose exactly one generation mode",
  "strict case-grounded claim gate",
  "general fallback",
  "write and run a standalone plot.r",
  "return plot.r, plot.png, and plot.pdf"
)
for (phrase in agent_prompt_requirements) {
  assert_contains(default_prompt_lower, phrase, "default_prompt")
}
assert_absent(default_prompt_lower, "mcp server", "default_prompt")

message("v1 skill contract tests: PASS")
