#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
script_path <- if (length(file_arg) > 0L) {
  normalizePath(sub("^--file=", "", file_arg[[1L]]), mustWork = TRUE)
} else {
  normalizePath(
    "tests/figureforge/test_case_trace_validation.R",
    mustWork = TRUE
  )
}
repo_root <- normalizePath(
  file.path(dirname(script_path), "..", ".."),
  mustWork = TRUE
)
source(file.path(
  repo_root,
  "skills",
  "figureforge",
  "lib",
  "distribution_validation.R"
))
source(file.path(
  repo_root,
  "skills",
  "figureforge",
  "lib",
  "checksums.R"
))
source(file.path(
  repo_root,
  "skills",
  "figureforge",
  "lib",
  "case_trace_validation.R"
))

fixture_root <- tempfile("figureforge-case-trace-")
case_dir <- file.path(fixture_root, "cases", "verified-scatter")
output_dir <- file.path(fixture_root, "figureforge-output")
trace_dir <- file.path(output_dir, ".figureforge")
dir.create(case_dir, recursive = TRUE)
dir.create(trace_dir, recursive = TRUE)

writeLines(
  c(
    "# Verified scatter",
    "",
    "A reusable layered scatter-plot case."
  ),
  file.path(case_dir, "case.md"),
  useBytes = TRUE
)
writeLines(
  c(
    "library(ggplot2)",
    "ggplot(data, aes(x, y)) + geom_point()"
  ),
  file.path(case_dir, "plot.R"),
  useBytes = TRUE
)
writeLines(
  c("# QA", "", "Status: verified"),
  file.path(case_dir, "qa.md"),
  useBytes = TRUE
)
script_path <- file.path(output_dir, "plot.R")
writeLines(
  c(
    "library(ggplot2)",
    "ggplot(input, aes(predictor, response)) + geom_point()"
  ),
  script_path,
  useBytes = TRUE
)
trace_path <- file.path(trace_dir, "case-trace.yml")

write_trace <- function(fields, path = trace_path) {
  stopifnot(!is.null(names(fields)), all(nzchar(names(fields))))
  lines <- sprintf(
    "%s: %s",
    names(fields),
    vapply(fields, as.character, character(1L))
  )
  writeLines(lines, path, useBytes = TRUE)
  invisible(path)
}

case_based_fields <- function(case_directory = case_dir) {
  fields <- list(
    schema_version = "1",
    generation_mode = "case_based",
    figureforge_version = "1.1.0",
    generated_script_sha256 = figureforge_sha256(script_path),
    claim = "case_grounded",
    primary_case_id = "verified-scatter",
    case_md_file = "case.md",
    case_md_sha256 = figureforge_sha256(file.path(case_directory, "case.md")),
    plot_r_file = "plot.R",
    plot_r_sha256 = figureforge_sha256(file.path(case_directory, "plot.R")),
    qa_md_file = "qa.md",
    qa_md_sha256 = figureforge_sha256(file.path(case_directory, "qa.md")),
    qa_status = "verified",
    schema_mapping = "predictor -> x | response -> y",
    adopted_patterns = paste(
      "layered point composition",
      "validated geom_point implementation",
      sep = " | "
    ),
    departures = "renamed source columns"
  )
  fields
}

expect_result_shape <- function(result) {
  stopifnot(is.list(result))
  stopifnot(all(c(
    "ok",
    "checks",
    "failed_checks",
    "messages",
    "evidence"
  ) %in% names(result)))
  stopifnot(is.logical(result$ok), length(result$ok) == 1L)
  stopifnot(is.logical(result$checks), !is.null(names(result$checks)))
  stopifnot(is.character(result$failed_checks))
  stopifnot(is.character(result$messages))
  stopifnot(is.list(result$evidence))
  invisible(result)
}

expect_invalid <- function(fields, failed_check, case_directory = case_dir) {
  write_trace(fields)
  result <- validate_case_trace(
    trace_path,
    case_dir = case_directory,
    script_path = script_path
  )
  expect_result_shape(result)
  stopifnot(!isTRUE(result$ok))
  stopifnot(failed_check %in% result$failed_checks)
  result
}

valid_fields <- case_based_fields()
write_trace(valid_fields)
valid <- validate_case_trace(
  trace_path,
  case_dir = case_dir,
  script_path = script_path
)
expect_result_shape(valid)
stopifnot(isTRUE(valid$ok))
stopifnot(length(valid$failed_checks) == 0L)
stopifnot(identical(valid$evidence$generation_mode, "case_based"))
stopifnot(identical(valid$evidence$primary_case_id, "verified-scatter"))
stopifnot(identical(
  valid$evidence$generated_script_sha256,
  figureforge_sha256(script_path)
))

missing_case_md <- valid_fields[
  !names(valid_fields) %in% c("case_md_file", "case_md_sha256")
]
expect_invalid(missing_case_md, "case.md evidence")

missing_plot_r <- valid_fields[
  !names(valid_fields) %in% c("plot_r_file", "plot_r_sha256")
]
expect_invalid(missing_plot_r, "plot.R evidence")

write_trace(valid_fields)
writeLines(
  c("# Changed case", "", "The evidence changed after tracing."),
  file.path(case_dir, "case.md"),
  useBytes = TRUE
)
changed_evidence <- validate_case_trace(
  trace_path,
  case_dir = case_dir,
  script_path = script_path
)
expect_result_shape(changed_evidence)
stopifnot(!isTRUE(changed_evidence$ok))
stopifnot("evidence hashes match" %in% changed_evidence$failed_checks)
writeLines(
  c(
    "# Verified scatter",
    "",
    "A reusable layered scatter-plot case."
  ),
  file.path(case_dir, "case.md"),
  useBytes = TRUE
)

write_trace(valid_fields)
writeLines(
  c(
    "library(ggplot2)",
    "ggplot(input, aes(predictor, response)) + geom_point() + theme_minimal()"
  ),
  script_path,
  useBytes = TRUE
)
changed_script <- validate_case_trace(
  trace_path,
  case_dir = case_dir,
  script_path = script_path
)
expect_result_shape(changed_script)
stopifnot(!isTRUE(changed_script$ok))
stopifnot(
  "generated script hash matches" %in% changed_script$failed_checks
)
writeLines(
  c(
    "library(ggplot2)",
    "ggplot(input, aes(predictor, response)) + geom_point()"
  ),
  script_path,
  useBytes = TRUE
)

empty_mapping <- case_based_fields()
empty_mapping$schema_mapping <- ""
expect_invalid(empty_mapping, "non-empty schema mapping")

empty_patterns <- case_based_fields()
empty_patterns$adopted_patterns <- ""
expect_invalid(empty_patterns, "concrete adopted patterns")

generic_patterns <- case_based_fields()
generic_patterns$adopted_patterns <- "used colors | made a scientific plot"
expect_invalid(generic_patterns, "concrete adopted patterns")

missing_qa <- case_based_fields()
missing_qa <- missing_qa[
  !names(missing_qa) %in% c("qa_md_file", "qa_md_sha256")
]
expect_invalid(missing_qa, "QA evidence matches case")

case_without_qa <- file.path(fixture_root, "cases", "unverified-scatter")
dir.create(case_without_qa, recursive = TRUE)
file.copy(
  file.path(case_dir, c("case.md", "plot.R")),
  case_without_qa,
  overwrite = TRUE
)
missing_qa_fields <- case_based_fields(case_without_qa)
missing_qa_fields$primary_case_id <- "unverified-scatter"
missing_qa_fields <- missing_qa_fields[
  !names(missing_qa_fields) %in% c("qa_md_file", "qa_md_sha256")
]
missing_qa_fields$qa_status <- "missing"
write_trace(missing_qa_fields)
valid_missing_qa <- validate_case_trace(
  trace_path,
  case_dir = case_without_qa,
  script_path = script_path
)
expect_result_shape(valid_missing_qa)
stopifnot(isTRUE(valid_missing_qa$ok))
stopifnot(identical(valid_missing_qa$evidence$qa_status, "missing"))

fallback_fields <- list(
  schema_version = "1",
  generation_mode = "general_fallback",
  figureforge_version = "1.1.0",
  generated_script_sha256 = figureforge_sha256(script_path),
  claim = "general_generation",
  fallback_reason = "No case matched the requested schema and figure type."
)
write_trace(fallback_fields)
fallback <- validate_case_trace(trace_path, script_path = script_path)
expect_result_shape(fallback)
stopifnot(isTRUE(fallback$ok))
stopifnot(length(fallback$failed_checks) == 0L)
stopifnot(identical(
  fallback$evidence$generation_mode,
  "general_fallback"
))

fallback_without_reason <- fallback_fields[
  names(fallback_fields) != "fallback_reason"
]
expect_invalid(
  fallback_without_reason,
  "non-empty fallback reason",
  case_directory = NULL
)

contradictory_fallback <- fallback_fields
contradictory_fallback$claim <- "case_grounded"
expect_invalid(
  contradictory_fallback,
  "claim matches generation mode",
  case_directory = NULL
)

unix_absolute_path <- case_based_fields()
unix_absolute_path$departures <- "/private/cases/verified-scatter/data.csv"
expect_invalid(unix_absolute_path, "no absolute paths")

windows_absolute_path <- fallback_fields
windows_absolute_path$fallback_reason <-
  "No usable case under C:\\private\\figureforge\\cases"
expect_invalid(
  windows_absolute_path,
  "no absolute paths",
  case_directory = NULL
)

message("case trace validation tests: PASS")
