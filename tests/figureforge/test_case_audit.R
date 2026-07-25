#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
script_path <- if (length(file_arg) > 0) {
  normalizePath(sub("^--file=", "", file_arg[[1]]), mustWork = TRUE)
} else {
  normalizePath("tests/figureforge/test_case_audit.R", mustWork = TRUE)
}
repo_root <- normalizePath(file.path(dirname(script_path), "..", ".."), mustWork = TRUE)

public_template <- file.path(
  repo_root,
  "skills",
  "figureforge",
  "cases",
  "_template"
)
stopifnot(file.exists(file.path(public_template, "case.md")))
stopifnot(file.exists(file.path(public_template, "data.csv")))
stopifnot(file.exists(file.path(public_template, "plot.R")))

source(file.path(repo_root, "skills", "figureforge", "lib", "case_audit.R"))
source(file.path(
  repo_root,
  "skills",
  "figureforge",
  "lib",
  "case_validation.R"
))
source(file.path(
  repo_root,
  "skills",
  "figureforge",
  "lib",
  "blocker_validation.R"
))
source(file.path(
  repo_root,
  "tests",
  "figureforge",
  "helpers",
  "materialize_case_fixtures.R"
))

fixtures_dir <- materialize_case_fixtures(repo_root)
render_dir <- tempfile("figureforge-audit-renders-")
dir.create(render_dir, recursive = TRUE)

results <- audit_cases(
  fixtures_dir,
  render_dir = render_dir,
  rscript = "/usr/local/bin/Rscript"
)

row_for <- function(case_id) {
  row <- results[results$case_id == case_id, , drop = FALSE]
  stopifnot(nrow(row) == 1)
  row
}

stopifnot(!"_template" %in% results$case_id)
stopifnot(isTRUE(row_for("scaffolded")$scaffolded))
stopifnot(isTRUE(row_for("authentic-private")$raw))
stopifnot(isTRUE(row_for("authentic-private")$private_only))
stopifnot(isTRUE(row_for("authentic-public")$public_ready))
stopifnot(isTRUE(row_for("authentic-public")$reproduced))
stopifnot(isTRUE(row_for("authentic-public")$qa_verified))
stopifnot(isTRUE(row_for("authentic-public")$runnable))
stopifnot(!isTRUE(row_for("render-fails")$runnable))

valid_blocked <- row_for("blocked-valid")
stopifnot(isTRUE(valid_blocked$blocked))
stopifnot(isTRUE(valid_blocked$processed))
stopifnot(identical(
  valid_blocked$terminal_outcome,
  "blocked"
))
stopifnot(identical(
  valid_blocked$blocked_status,
  "blocked_visual_reference"
))

invalid_blocked <- row_for("blocked-invalid")
stopifnot(!isTRUE(invalid_blocked$blocked))
stopifnot(!isTRUE(invalid_blocked$processed))
stopifnot(identical(
  invalid_blocked$terminal_outcome,
  "pending"
))

completed <- row_for("authentic-public")
stopifnot(isTRUE(completed$processed))
stopifnot(identical(completed$terminal_outcome, "completed"))
pending <- row_for("scaffolded")
stopifnot(!isTRUE(pending$processed))
stopifnot(identical(pending$terminal_outcome, "pending"))

report_dir <- tempfile("figureforge-audit-report-")
write_audit_reports(results, report_dir)

csv_path <- file.path(report_dir, "case-readiness.csv")
summary_path <- file.path(report_dir, "summary.md")
stopifnot(file.exists(csv_path))
stopifnot(file.exists(summary_path))

reported <- read.csv(csv_path, stringsAsFactors = FALSE, check.names = FALSE)
stopifnot(identical(reported$case_id, sort(reported$case_id)))

summary_text <- paste(readLines(summary_path, warn = FALSE), collapse = "\n")
stopifnot(grepl("Cases audited: 6", summary_text, fixed = TRUE))
stopifnot(grepl("Scaffolded: 1", summary_text, fixed = TRUE))
stopifnot(grepl("Runnable: 5", summary_text, fixed = TRUE))
stopifnot(grepl("Public-ready: 1", summary_text, fixed = TRUE))
stopifnot(grepl("Completed: 1", summary_text, fixed = TRUE))
stopifnot(grepl("Blocked: 1", summary_text, fixed = TRUE))
stopifnot(grepl("Pending: 4", summary_text, fixed = TRUE))
stopifnot(grepl(
  "Reproduced means that a non-empty reproduction artifact exists",
  summary_text,
  fixed = TRUE
))
stopifnot(grepl(
  "Missing distribution review defaults to private-only",
  summary_text,
  fixed = TRUE
))

read_repo_text <- function(relative_path) {
  paste(
    readLines(file.path(repo_root, relative_path), warn = FALSE),
    collapse = "\n"
  )
}

readme_en <- read_repo_text("README.md")
readme_zh <- read_repo_text("README.zh.md")
qa_reference <- read_repo_text(
  "skills/figureforge/references/qa-checklist.md"
)

for (document in list(readme_en, readme_zh)) {
  stopifnot(grepl("audit_cases.R", document, fixed = TRUE))
  for (classification in c(
    "raw",
    "scaffolded",
    "runnable",
    "reproduced",
    "qa_verified",
    "public_ready",
    "private_only"
  )) {
    stopifnot(grepl(classification, document, fixed = TRUE))
  }
}
stopifnot(grepl(
  "Scaffolded cases are not completed cases.",
  readme_en,
  fixed = TRUE
))
stopifnot(grepl(
  "scaffolded（脚手架化）案例不等于已完成案例。",
  readme_zh,
  fixed = TRUE
))
stopifnot(grepl("Status: verified", qa_reference, fixed = TRUE))
stopifnot(grepl("distribution.yml", qa_reference, fixed = TRUE))

message("case audit tests: PASS")
