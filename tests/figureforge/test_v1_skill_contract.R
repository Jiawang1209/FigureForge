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
  c("gallery-index.md", "adaptation-contract.md", "qa-checklist.md")
)

skill_lines <- readLines(skill_path, warn = FALSE, encoding = "UTF-8")
skill_text <- paste(skill_lines, collapse = "\n")
skill_lower <- tolower(skill_text)
agent_text <- paste(
  readLines(agent_path, warn = FALSE, encoding = "UTF-8"),
  collapse = "\n"
)
references_text <- paste(
  unlist(lapply(
    reference_paths,
    readLines,
    warn = FALSE,
    encoding = "UTF-8"
  )),
  collapse = "\n"
)

stopifnot(length(skill_lines) < 500L)
stopifnot(all(file.exists(reference_paths)))
stopifnot(grepl("skills/figureforge/public-cases", skill_text, fixed = TRUE))
stopifnot(grepl("--public", skill_text, fixed = TRUE))

required_commands <- c(
  "doctor.R",
  "search_cases.R",
  "match_schema.R",
  "create_adaptation.R",
  "visual_qa.R",
  "validate_adaptation.R"
)
stopifnot(all(vapply(
  required_commands,
  grepl,
  logical(1),
  x = skill_text,
  fixed = TRUE
)))

required_safety_language <- c(
  "synthetic_test_fixture",
  "status: review_required",
  "never grants verified status",
  "private cases are optional local extensions",
  "mcp is planned and unimplemented"
)
stopifnot(all(vapply(
  required_safety_language,
  grepl,
  logical(1),
  x = skill_lower,
  fixed = TRUE
)))

stopifnot(grepl("public-cases", references_text, fixed = TRUE))
stopifnot(grepl("synthetic stress fixtures", tolower(references_text), fixed = TRUE))
stopifnot(grepl("automated", tolower(references_text), fixed = TRUE))
stopifnot(grepl("human", tolower(references_text), fixed = TRUE))
stopifnot(grepl("review_required", references_text, fixed = TRUE))

agent_lower <- tolower(agent_text)
stopifnot(grepl("public", agent_lower, fixed = TRUE))
stopifnot(grepl("review_required", agent_lower, fixed = TRUE))
stopifnot(!grepl("mcp server", agent_lower, fixed = TRUE))

command_paths <- unique(regmatches(
  paste(skill_text, agent_text, references_text),
  gregexpr(
    "skills/figureforge/(scripts|references)/[a-z0-9_-]+\\.(R|md)",
    paste(skill_text, agent_text, references_text),
    perl = TRUE
  )
)[[1L]])
stopifnot(length(command_paths) > 0L)
stopifnot(all(file.exists(file.path(repo_root, command_paths))))

message("v1 skill contract tests: PASS")
