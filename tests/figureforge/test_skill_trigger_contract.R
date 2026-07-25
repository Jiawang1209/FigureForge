#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
script_path <- if (length(file_arg) > 0L) {
  normalizePath(sub("^--file=", "", file_arg[[1L]]), mustWork = TRUE)
} else {
  normalizePath(
    "tests/figureforge/test_skill_trigger_contract.R",
    mustWork = TRUE
  )
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
live_eval_path <- file.path(
  repo_root,
  "scripts",
  "run_figureforge_live_evals.sh"
)

skill_lines <- readLines(skill_path, warn = FALSE, encoding = "UTF-8")
skill_text <- paste(skill_lines, collapse = "\n")
skill_lower <- tolower(skill_text)
frontmatter_end <- which(skill_lines[-1L] == "---")[[1L]] + 1L
frontmatter <- skill_lines[2L:(frontmatter_end - 1L)]
description <- sub(
  "^description:\\s*",
  "",
  frontmatter[grepl("^description:", frontmatter)]
)

stopifnot(length(description) == 1L)
stopifnot(startsWith(description, "Use when"))
stopifnot(grepl("data-only", description, fixed = TRUE))
stopifnot(grepl("Chinese or English chart requests", description, fixed = TRUE))
stopifnot(length(strsplit(description, "\\s+")[[1L]]) <= 45L)
stopifnot(!grepl("then", description, ignore.case = TRUE))

stopifnot(!grepl(
  "Every shipped dataset declares `synthetic_test_fixture: true`",
  skill_text,
  fixed = TRUE
))
stopifnot(!grepl(
  "Public data are synthetic fixtures",
  skill_text,
  fixed = TRUE
))
stopifnot(grepl("authentic open data", skill_lower, fixed = TRUE))
stopifnot(grepl("synthetic demonstrations", skill_lower, fixed = TRUE))
stopifnot(grepl("case metadata controls", skill_lower, fixed = TRUE))
stopifnot(grepl(
  "--rscript`, `figureforge_rscript`, compatibility path, then `path`",
  skill_lower,
  fixed = TRUE
))
stopifnot(!grepl("/usr/local/bin/Rscript", skill_text, fixed = TRUE))
stopifnot(grepl("MCP is planned and unimplemented", skill_text, fixed = TRUE))

agent_text <- paste(
  readLines(agent_path, warn = FALSE, encoding = "UTF-8"),
  collapse = "\n"
)
agent_lower <- tolower(agent_text)
stopifnot(grepl("\\$figureforge", agent_text))
stopifnot(grepl("inspect", agent_lower, fixed = TRUE))
stopifnot(grepl("external adaptation", agent_lower, fixed = TRUE))
stopifnot(!grepl("all public data", agent_lower, fixed = TRUE))
stopifnot(!grepl("/usr/local/bin/Rscript", agent_text, fixed = TRUE))

stopifnot(file.exists(live_eval_path))
stopifnot(identical(
  as.integer(system2("bash", c("-n", shQuote(live_eval_path)))),
  0L
))
live_eval_text <- paste(
  readLines(live_eval_path, warn = FALSE, encoding = "UTF-8"),
  collapse = "\n"
)
stopifnot(grepl("explicit_total", live_eval_text, fixed = TRUE))
stopifnot(grepl("implicit_total", live_eval_text, fixed = TRUE))
stopifnot(grepl("implicit >= 0.90", live_eval_text, fixed = TRUE))
stopifnot(grepl(".agents/skills/figureforge", live_eval_text, fixed = TRUE))
stopifnot(grepl("</dev/null", live_eval_text, fixed = TRUE))
stopifnot(grepl(
  "selected capability's installed SKILL.md",
  live_eval_text,
  fixed = TRUE
))

message("skill trigger contract tests: PASS")
