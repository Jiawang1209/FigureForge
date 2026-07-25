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
skill_plain <- gsub("`", "", gsub("\\s+", " ", skill_text))
skill_plain_lower <- tolower(skill_plain)
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
frontmatter_end <- which(skill_lines[-1L] == "---")[[1L]] + 1L
frontmatter <- skill_lines[2L:(frontmatter_end - 1L)]
description <- sub(
  "^description:\\s*",
  "",
  frontmatter[grepl("^description:", frontmatter)]
)

stopifnot(length(description) == 1L)
stopifnot(startsWith(description, "Use when"))
stopifnot(grepl("R", description, fixed = TRUE))
stopifnot(grepl("scientific", description, ignore.case = TRUE))
stopifnot(grepl("plot", description, ignore.case = TRUE))
stopifnot(grepl("data-only", description, fixed = TRUE))
stopifnot(grepl("Chinese or English", description, fixed = TRUE))
stopifnot(length(strsplit(description, "\\s+")[[1L]]) <= 45L)
stopifnot(!grepl("then", description, ignore.case = TRUE))

assert_contains(skill_lower, "case-enhanced", "SKILL.md")
assert_contains(
  skill_lower,
  "rscript plot.r <input-file> <output-directory>",
  "SKILL.md"
)
assert_contains(
  skill_plain_lower,
  "return plot.r, plot.png, and plot.pdf.",
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
assert_contains(
  skill_text,
  "MCP is planned and unimplemented.",
  "SKILL.md"
)
stopifnot(!grepl(
  paste(
    "Read case.md, case.yml, data.csv, plot.R, qa.md, and",
    "distribution.yml before adapting a public case."
  ),
  skill_plain,
  fixed = TRUE
))

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
for (phrase in c(
  "mcp server",
  "external adaptation",
  "/usr/local/bin/rscript"
)) {
  assert_absent(default_prompt_lower, phrase, "default_prompt")
}

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

fake_root <- tempfile("figureforge-live-relative-")
dir.create(fake_root, recursive = TRUE)
fake_codex <- file.path(fake_root, "fake-codex")
writeLines(
  c(
    "#!/bin/sh",
    "set -eu",
    "final_message=",
    "while [ \"$#\" -gt 0 ]; do",
    "  if [ \"$1\" = \"-o\" ]; then",
    "    final_message=$2",
    "    shift 2",
    "  else",
    "    shift",
    "  fi",
    "done",
    "test -n \"$final_message\"",
    "printf '%s\\n' figureforge >\"$final_message\"",
    "printf '%s\\n' 'Rscript \".agents/skills/figureforge/scripts/doctor.R\"' >>\"$final_message\"",
    "printf '%s\\n' '{\"type\":\"item.completed\",\"item\":{\"type\":\"command_execution\",\"command\":\"sed -n 1,240p .agents/skills/figureforge/SKILL.md\"}}'"
  ),
  fake_codex,
  useBytes = TRUE
)
Sys.chmod(fake_codex, mode = "0755")
fake_output <- file.path(fake_root, "output")
fake_status <- system2(
  "bash",
  c(
    shQuote(live_eval_path),
    "--output-dir",
    shQuote(fake_output),
    "--codex",
    shQuote(fake_codex)
  ),
  stdout = TRUE,
  stderr = TRUE
)
stopifnot(identical(attr(fake_status, "status"), NULL))
fake_summary <- read.csv(
  file.path(fake_output, "summary.csv"),
  stringsAsFactors = FALSE
)
stopifnot(nrow(fake_summary) == 11L)
stopifnot(all(fake_summary$skill_loaded == "true"))
stopifnot(all(fake_summary$passed == "true"))

message("skill trigger contract tests: PASS")
