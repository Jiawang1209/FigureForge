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
case_use_path <- file.path(
  repo_root,
  "skills",
  "figureforge",
  "references",
  "case-use-contract.md"
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
assert_artifact_return_block(skill_text, "SKILL.md")
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
assert_contains(
  skill_text,
  "MCP is planned and unimplemented.",
  "SKILL.md"
)
stopifnot(file.exists(case_use_path))
case_use_text <- paste(
  readLines(case_use_path, warn = FALSE, encoding = "UTF-8"),
  collapse = "\n"
)
for (phrase in c(
  "case_based",
  "general_fallback",
  "case.md",
  "plot.R",
  "qa.md",
  ".figureforge/case-trace.yml",
  "schema_mapping",
  "adopted_patterns",
  "departures",
  "<case evidence>#source anchor => plot.R#generated executable anchor",
  "validate_case_trace.R",
  "--case-dir",
  "--script",
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
  assert_contains(case_use_text, phrase, "case-use-contract.md")
}
for (phrase in c(
  "Choose exactly one generation mode after search",
  "actually read `case.md` and `plot.R`",
  "read `qa.md` when it exists",
  "Only a successful strict validation authorizes a case-grounded claim",
  "Structural or partial validation never authorizes that claim",
  "Never describe `general_fallback` output as case-grounded",
  "Do not ask the user to inspect, select, or operate the case library",
  "The trace is hidden workflow state, not a fourth visible deliverable"
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
stopifnot(grepl("artifact_contract", live_eval_text, fixed = TRUE))
stopifnot(!grepl("installed_path", live_eval_text, fixed = TRUE))
stopifnot(!grepl("FIGUREFORGE_SKILL_ROOT", live_eval_text, fixed = TRUE))
stopifnot(!grepl("first command", live_eval_text, fixed = TRUE))
for (artifact_name in c("plot.R", "plot.png", "plot.pdf")) {
  stopifnot(grepl(artifact_name, live_eval_text, fixed = TRUE))
}
stopifnot(grepl(
  paste(
    "Use $figureforge with a CSV to create a publication-ready R",
    "scatter plot."
  ),
  live_eval_text,
  fixed = TRUE
))
response_contract <- paste(
  "Return only the selected capability and the three artifact names",
  "it would create. Do not execute the plotting task."
)
response_contract_matches <- gregexpr(
  response_contract,
  live_eval_text,
  fixed = TRUE
)[[1L]]
stopifnot(sum(response_contract_matches >= 0L) == 11L)
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
    "printf '%s\\n' plot.R plot.png plot.pdf >>\"$final_message\"",
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
stopifnot(identical(
  names(fake_summary),
  c(
    "kind",
    "probe_id",
    "exit_status",
    "skill_loaded",
    "capability_selected",
    "artifact_contract",
    "passed"
  )
))
stopifnot(nrow(fake_summary) == 11L)
stopifnot(sum(fake_summary$kind == "explicit") == 1L)
stopifnot(sum(fake_summary$kind == "implicit") == 10L)
stopifnot(all(fake_summary$skill_loaded == "true"))
stopifnot(all(fake_summary$artifact_contract == "true"))
stopifnot(all(fake_summary$passed == "true"))

missing_artifact_codex <- file.path(fake_root, "missing-artifact-codex")
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
    "printf '%s\\n' figureforge plot.R plot.png >\"$final_message\"",
    "printf '%s\\n' '{\"type\":\"item.completed\",\"item\":{\"type\":\"command_execution\",\"command\":\"sed -n 1,240p .agents/skills/figureforge/SKILL.md\"}}'"
  ),
  missing_artifact_codex,
  useBytes = TRUE
)
Sys.chmod(missing_artifact_codex, mode = "0755")
missing_artifact_output <- file.path(fake_root, "missing-artifact-output")
missing_artifact_status <- suppressWarnings(system2(
  "bash",
  c(
    shQuote(live_eval_path),
    "--output-dir",
    shQuote(missing_artifact_output),
    "--codex",
    shQuote(missing_artifact_codex)
  ),
  stdout = TRUE,
  stderr = TRUE
))
stopifnot(!identical(attr(missing_artifact_status, "status"), NULL))
missing_artifact_summary <- read.csv(
  file.path(missing_artifact_output, "summary.csv"),
  stringsAsFactors = FALSE
)
stopifnot(nrow(missing_artifact_summary) == 11L)
stopifnot(all(missing_artifact_summary$artifact_contract == "false"))
stopifnot(all(missing_artifact_summary$passed == "false"))

message("skill trigger contract tests: PASS")
