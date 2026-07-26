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

run_tests <- function() {
fixture_root <- tempfile("figureforge-case-trace-")
on.exit(unlink(fixture_root, recursive = TRUE, force = TRUE), add = TRUE)
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
  qa_path <- file.path(case_directory, "qa.md")
  qa_exists <- file.exists(qa_path)
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
    schema_mapping = "predictor -> x | response -> y",
    adopted_patterns = paste(
      "layered point composition",
      "validated geom_point implementation",
      sep = " | "
    ),
    departures = "renamed source columns"
  )
  if (qa_exists) {
    fields$qa_md_file <- "qa.md"
    fields$qa_md_sha256 <- figureforge_sha256(qa_path)
  }
  fields$qa_status <- if (qa_exists) "verified" else "missing"
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
  stopifnot(!anyNA(result$ok))
  stopifnot(!anyNA(result$checks))
  stopifnot(!anyNA(result$failed_checks))
  stopifnot(!anyNA(result$messages))
  stopifnot(!anyNA(result$evidence, recursive = TRUE))
  stopifnot(identical(result$ok, all(result$checks)))
  stopifnot(identical(
    result$failed_checks,
    names(result$checks)[!result$checks]
  ))
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
  stopifnot(identical(result$ok, FALSE))
  stopifnot(failed_check %in% result$failed_checks)
  result
}

normalized_checks <- case_trace_result(
  list(
    pass = TRUE,
    missing = NA,
    numeric_truthy = 1
  ),
  messages = character(0),
  evidence = list()
)
expect_result_shape(normalized_checks)
stopifnot(identical(
  normalized_checks$checks,
  c(
    pass = TRUE,
    missing = FALSE,
    numeric_truthy = FALSE
  )
))

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
stopifnot(identical(valid$evidence$verification_level, "strict"))
stopifnot("generated script hash matches" %in% names(valid$checks))
stopifnot("case evidence hashes match" %in% names(valid$checks))

write_trace(valid_fields)
structural <- validate_case_trace(trace_path)
expect_result_shape(structural)
stopifnot(isTRUE(structural$ok))
stopifnot(identical(
  structural$evidence$verification_level,
  "structural"
))
stopifnot("generated script hash format" %in% names(structural$checks))
stopifnot("case.md evidence declared" %in% names(structural$checks))
stopifnot("plot.R evidence declared" %in% names(structural$checks))
stopifnot(!any(c(
  "generated script hash matches",
  "case evidence hashes match",
  "QA evidence matches case"
) %in% names(structural$checks)))

case_only <- validate_case_trace(
  trace_path,
  case_dir = case_dir
)
expect_result_shape(case_only)
stopifnot(isTRUE(case_only$ok))
stopifnot(identical(case_only$evidence$verification_level, "partial"))
stopifnot("case evidence hashes match" %in% names(case_only$checks))
stopifnot(!"generated script hash matches" %in% names(case_only$checks))

script_only <- validate_case_trace(
  trace_path,
  script_path = script_path
)
expect_result_shape(script_only)
stopifnot(isTRUE(script_only$ok))
stopifnot(identical(script_only$evidence$verification_level, "partial"))
stopifnot("generated script hash matches" %in% names(script_only$checks))
stopifnot(!"case evidence hashes match" %in% names(script_only$checks))
stopifnot(!"QA evidence matches case" %in% names(script_only$checks))

missing_case_md <- valid_fields[
  !names(valid_fields) %in% c("case_md_file", "case_md_sha256")
]
expect_invalid(missing_case_md, "case.md evidence declared")

missing_plot_r <- valid_fields[
  !names(valid_fields) %in% c("plot_r_file", "plot_r_sha256")
]
expect_invalid(missing_plot_r, "plot.R evidence declared")

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
stopifnot("case evidence hashes match" %in% changed_evidence$failed_checks)
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

generic_pattern_variant <- case_based_fields()
generic_pattern_variant$adopted_patterns <- "used nice colors"
expect_invalid(generic_pattern_variant, "concrete adopted patterns")

generic_pattern_chinese <- case_based_fields()
generic_pattern_chinese$adopted_patterns <- "使用漂亮颜色"
expect_invalid(generic_pattern_chinese, "concrete adopted patterns")

superficial_aesthetics <- case_based_fields()
superficial_aesthetics$adopted_patterns <- "nice aesthetics"
expect_invalid(superficial_aesthetics, "concrete adopted patterns")

superficial_axis_use <- case_based_fields()
superficial_axis_use$adopted_patterns <- "used an axis"
expect_invalid(superficial_axis_use, "concrete adopted patterns")

superficial_axis_use_chinese <- case_based_fields()
superficial_axis_use_chinese$adopted_patterns <- "使用坐标轴"
expect_invalid(
  superficial_axis_use_chinese,
  "concrete adopted patterns"
)

generic_technical_noun_patterns <- c(
  "use labels",
  "using labels",
  "used axis labels",
  "used labels",
  "used bars",
  "used lines",
  "used annotations",
  "used points",
  "adopted axis labels",
  "adopting points",
  "applied bars",
  "applying annotations",
  "added lines",
  "adding points",
  "made lines",
  "making annotations",
  "created bars",
  "creating labels",
  "使用坐标轴标签",
  "使用散点",
  "采用图例",
  "运用散点",
  "添加标注",
  "创建柱形",
  "制作折线",
  "用了散点"
)
for (generic_technical_noun in generic_technical_noun_patterns) {
  generic_technical_pattern <- case_based_fields()
  generic_technical_pattern$adopted_patterns <- generic_technical_noun
  expect_invalid(
    generic_technical_pattern,
    "concrete adopted patterns"
  )
}

mixed_concrete_and_generic_patterns <- case_based_fields()
mixed_concrete_and_generic_patterns$adopted_patterns <-
  "validated geom_point implementation | used nice colors"
expect_invalid(
  mixed_concrete_and_generic_patterns,
  "concrete adopted patterns"
)

design_category_patterns <- case_based_fields()
design_category_patterns$adopted_patterns <- paste(
  "overall composition",
  "validated implementation technique",
  "specialist PCA biplot idiom",
  sep = " | "
)
write_trace(design_category_patterns)
valid_design_categories <- validate_case_trace(
  trace_path,
  case_dir = case_dir,
  script_path = script_path
)
expect_result_shape(valid_design_categories)
stopifnot(isTRUE(valid_design_categories$ok))

specific_adaptation_patterns <- case_based_fields()
specific_adaptation_patterns$adopted_patterns <- paste(
  "variance in axis labels",
  "group color and shape",
  "zero reference lines",
  sep = " | "
)
write_trace(specific_adaptation_patterns)
valid_specific_adaptations <- validate_case_trace(
  trace_path,
  case_dir = case_dir,
  script_path = script_path
)
expect_result_shape(valid_specific_adaptations)
stopifnot(isTRUE(valid_specific_adaptations$ok))

missing_qa <- case_based_fields()
missing_qa <- missing_qa[
  !names(missing_qa) %in% c("qa_md_file", "qa_md_sha256")
]
expect_invalid(missing_qa, "QA evidence matches case")

writeLines(
  c(
    "# QA",
    "",
    "Status: verified",
    "Status: review_required"
  ),
  file.path(case_dir, "qa.md"),
  useBytes = TRUE
)
conflicting_qa_fields <- case_based_fields()
expect_invalid(
  conflicting_qa_fields,
  "QA evidence matches case"
)
writeLines(
  c("# QA", "", "Status: verified"),
  file.path(case_dir, "qa.md"),
  useBytes = TRUE
)

case_without_qa <- file.path(fixture_root, "cases", "unverified-scatter")
dir.create(case_without_qa, recursive = TRUE)
file.copy(
  file.path(case_dir, c("case.md", "plot.R")),
  case_without_qa,
  overwrite = TRUE
)
missing_qa_fields <- case_based_fields(case_without_qa)
missing_qa_fields$primary_case_id <- "unverified-scatter"
write_trace(missing_qa_fields)
valid_missing_qa <- validate_case_trace(
  trace_path,
  case_dir = case_without_qa,
  script_path = script_path
)
expect_result_shape(valid_missing_qa)
stopifnot(isTRUE(valid_missing_qa$ok))
stopifnot(identical(valid_missing_qa$evidence$qa_status, "missing"))

case_with_fallback_reason <- case_based_fields()
case_with_fallback_reason$fallback_reason <- "A fallback was considered."
expect_invalid(
  case_with_fallback_reason,
  "no fallback-only evidence"
)

case_with_considered_cases <- case_based_fields()
case_with_considered_cases$considered_cases <- "other-case"
expect_invalid(
  case_with_considered_cases,
  "no fallback-only evidence"
)

fallback_fields <- list(
  schema_version = "1",
  generation_mode = "general_fallback",
  figureforge_version = "1.1.0",
  generated_script_sha256 = figureforge_sha256(script_path),
  claim = "general_method",
  fallback_reason = "No case matched the requested schema and figure type."
)
write_trace(fallback_fields)
fallback <- validate_case_trace(trace_path, script_path = script_path)
expect_result_shape(fallback)
stopifnot(isTRUE(fallback$ok))
stopifnot(length(fallback$failed_checks) == 0L)
stopifnot(identical(fallback$evidence$verification_level, "strict"))
stopifnot(identical(
  fallback$evidence$generation_mode,
  "general_fallback"
))

write_trace(fallback_fields)
fallback_structural <- validate_case_trace(trace_path)
expect_result_shape(fallback_structural)
stopifnot(isTRUE(fallback_structural$ok))
stopifnot(identical(
  fallback_structural$evidence$verification_level,
  "structural"
))
stopifnot(
  !"generated script hash matches" %in% names(fallback_structural$checks)
)

fallback_case_only <- validate_case_trace(
  trace_path,
  case_dir = case_dir
)
expect_result_shape(fallback_case_only)
stopifnot(isTRUE(fallback_case_only$ok))
stopifnot(identical(
  fallback_case_only$evidence$verification_level,
  "structural"
))
stopifnot(
  !"generated script hash matches" %in% names(fallback_case_only$checks)
)

fallback_both_paths <- validate_case_trace(
  trace_path,
  case_dir = case_dir,
  script_path = script_path
)
expect_result_shape(fallback_both_paths)
stopifnot(isTRUE(fallback_both_paths$ok))
stopifnot(identical(
  fallback_both_paths$evidence$verification_level,
  "strict"
))
stopifnot(
  "generated script hash matches" %in% names(fallback_both_paths$checks)
)
stopifnot(
  !"case evidence hashes match" %in% names(fallback_both_paths$checks)
)

fallback_without_script_hash <- fallback_fields[
  names(fallback_fields) != "generated_script_sha256"
]
expect_invalid(
  fallback_without_script_hash,
  "generated script hash matches",
  case_directory = NULL
)

fallback_wrong_script_hash <- fallback_fields
fallback_wrong_script_hash$generated_script_sha256 <- paste(
  rep("0", 64L),
  collapse = ""
)
expect_invalid(
  fallback_wrong_script_hash,
  "generated script hash matches",
  case_directory = NULL
)

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

legacy_fallback_claim <- fallback_fields
legacy_fallback_claim$claim <- "general_generation"
expect_invalid(
  legacy_fallback_claim,
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

unc_absolute_path <- fallback_fields
unc_absolute_path$fallback_reason <-
  "No usable case under \\\\server\\share\\case.md"
expect_invalid(
  unc_absolute_path,
  "no absolute paths",
  case_directory = NULL
)

embedded_absolute_paths <- c(
  "path:/private/x",
  "[/private/x]",
  "x,/private/x",
  "path:C:\\private\\x",
  "path:\\\\server\\share\\x",
  "file:///private/x",
  "file://server/share/x",
  "file://localhost/private/x",
  "FILE://SERVER/share/x",
  "FiLe://localhost/private/x",
  "//server/share/x"
)
for (absolute_path_token in embedded_absolute_paths) {
  embedded_absolute_path <- fallback_fields
  embedded_absolute_path$fallback_reason <- absolute_path_token
  expect_invalid(
    embedded_absolute_path,
    "no absolute paths",
    case_directory = NULL
  )
}

https_url <- fallback_fields
https_url$fallback_reason <-
  "No matching case; see https://example.com/x for the method."
write_trace(https_url)
valid_https_url <- validate_case_trace(
  trace_path,
  script_path = script_path
)
expect_result_shape(valid_https_url)
stopifnot(isTRUE(valid_https_url$ok))

role_mapping_text <- case_based_fields()
role_mapping_text$departures <- "role -> column"
write_trace(role_mapping_text)
valid_role_mapping_text <- validate_case_trace(
  trace_path,
  case_dir = case_dir,
  script_path = script_path
)
expect_result_shape(valid_role_mapping_text)
stopifnot(isTRUE(valid_role_mapping_text$ok))

message("case trace validation tests: PASS")
}

run_tests()
