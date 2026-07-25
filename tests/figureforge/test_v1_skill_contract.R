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
    "maintainer-workflow.md",
    "ggplot-patterns.md",
    "theme-and-export.md",
    "data-mapping.md"
  )
)
names(reference_paths) <- c(
  "plotting",
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

assert_contains(
  skill_plain,
  "Return plot.R, plot.png, and plot.pdf.",
  "SKILL.md"
)
assert_contains(
  skill_text,
  "Rscript plot.R <input-file> <output-directory>",
  "SKILL.md"
)
assert_contains(
  skill_plain_lower,
  paste(
    "choose one primary case for overall composition;",
    "use secondary cases only for optional local patterns."
  ),
  "SKILL.md"
)
assert_contains(
  skill_plain_lower,
  "ask only when unresolved ambiguity changes scientific meaning.",
  "SKILL.md"
)
stopifnot(grepl("ggplot2", skill_text, fixed = TRUE))
stopifnot(grepl("specialist R packages", skill_text, fixed = TRUE))
stopifnot(grepl(
  "MCP is planned and unimplemented",
  skill_text,
  fixed = TRUE
))
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
  "choose one primary case",
  "optional secondary patterns",
  "write and run a standalone plot.r",
  "return plot.r, plot.png, and plot.pdf"
)
for (phrase in agent_prompt_requirements) {
  assert_contains(default_prompt_lower, phrase, "default_prompt")
}
assert_absent(default_prompt_lower, "mcp server", "default_prompt")

message("v1 skill contract tests: PASS")
