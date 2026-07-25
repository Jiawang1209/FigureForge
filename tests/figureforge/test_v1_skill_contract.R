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

skill_lines <- readLines(skill_path, warn = FALSE, encoding = "UTF-8")
skill_text <- paste(skill_lines, collapse = "\n")
skill_lower <- tolower(skill_text)
skill_plain <- gsub("`", "", gsub("\\s+", " ", skill_text))
agent_text <- paste(
  readLines(agent_path, warn = FALSE, encoding = "UTF-8"),
  collapse = "\n"
)

stopifnot(length(skill_lines) < 260L)
stopifnot(all(file.exists(reference_paths)))
stopifnot(all(file.exists(referenced_paths)))

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
stopifnot(!grepl("validate_blocker.R", skill_text, fixed = TRUE))
stopifnot(!grepl("plan_case_batches.R", skill_text, fixed = TRUE))

plotting_text <- paste(
  readLines(reference_paths[["plotting"]], warn = FALSE, encoding = "UTF-8"),
  collapse = "\n"
)
stopifnot(grepl("plot.R", plotting_text, fixed = TRUE))
stopifnot(grepl("plot.png", plotting_text, fixed = TRUE))
stopifnot(grepl("plot.pdf", plotting_text, fixed = TRUE))

maintainer_text <- paste(
  readLines(
    reference_paths[["maintainer"]],
    warn = FALSE,
    encoding = "UTF-8"
  ),
  collapse = "\n"
)
maintainer_requirements <- c(
  "validate_blocker.R",
  "plan_case_batches.R",
  "audit_cases.R",
  "package_skill.R",
  "verify_release.R",
  "synthetic fixtures",
  "review_required",
  "Automated checks never"
)
stopifnot(all(vapply(
  maintainer_requirements,
  grepl,
  logical(1),
  x = maintainer_text,
  fixed = TRUE
)))

agent_lower <- tolower(agent_text)
stopifnot(grepl("real data", agent_lower, fixed = TRUE))
stopifnot(grepl("primary case", agent_lower, fixed = TRUE))
stopifnot(grepl("plot.r", agent_lower, fixed = TRUE))
stopifnot(grepl("plot.png", agent_lower, fixed = TRUE))
stopifnot(grepl("plot.pdf", agent_lower, fixed = TRUE))
stopifnot(!grepl("mcp server", agent_lower, fixed = TRUE))

message("v1 skill contract tests: PASS")
