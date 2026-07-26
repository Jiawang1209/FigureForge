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

case_md_lines <- c(
  "# Verified scatter",
  "",
  "A reusable layered scatter-plot case.",
  "Overall composition supports a single explanatory panel.",
  "Generalized additive model is available for nonlinear response.",
  "分面布局按处理组组织图形。",
  "颜色映射区分处理组。"
)
writeLines(
  case_md_lines,
  file.path(case_dir, "case.md"),
  useBytes = TRUE
)
plot_r_lines <- c(
  "library(ggplot2)",
  "case_plot <- ggplot2::ggplot(data, ggplot2::aes(x, y)) +",
  "  ggplot2::geom_point() +",
  "  ggplot2::facet_wrap(~ treatment)",
  "print(case_plot)"
)
writeLines(
  plot_r_lines,
  file.path(case_dir, "plot.R"),
  useBytes = TRUE
)
qa_md_lines <- c(
  "# QA",
  "",
  "Status: verified",
  "Confidence ribbon checked against lower and upper bounds.",
  "置信区间带展示不确定性。"
)
writeLines(
  qa_md_lines,
  file.path(case_dir, "qa.md"),
  useBytes = TRUE
)
script_path <- file.path(output_dir, "plot.R")
generated_script_lines <- c(
  "library(ggplot2)",
  "smooth_method <- stats::loess",
  "facet_group_layout <- ggplot2::facet_wrap(~ treatment)",
  "confidence_alpha_mapping <- ggplot2::aes(alpha = confidence)",
  "lower_upper_bounds <- range(input$response, na.rm = TRUE)",
  "final_plot <- ggplot2::ggplot(",
  "  input,",
  "  ggplot2::aes(predictor, response)",
  ") +",
  "  ggplot2::geom_point(mapping = confidence_alpha_mapping) +",
  "  ggplot2::geom_smooth(method = smooth_method, se = FALSE) +",
  "  facet_group_layout +",
  "  ggplot2::coord_cartesian(ylim = lower_upper_bounds)",
  "ggplot2::ggsave(filename = \"figure.png\", plot = final_plot)"
)
generated_script_text <- paste(generated_script_lines, collapse = "\n")
for (active_symbol in c(
  "smooth_method",
  "facet_group_layout",
  "confidence_alpha_mapping",
  "lower_upper_bounds",
  "final_plot"
)) {
  matches <- gregexpr(
    active_symbol,
    generated_script_text,
    fixed = TRUE
  )[[1L]]
  stopifnot(matches[[1L]] >= 0L, length(matches) >= 2L)
}
stopifnot(grepl(
  "ggplot2::ggsave(filename = \"figure.png\", plot = final_plot)",
  generated_script_text,
  fixed = TRUE
))
writeLines(
  generated_script_lines,
  script_path,
  useBytes = TRUE
)
trace_path <- file.path(trace_dir, "case-trace.yml")
search_receipt_path <- file.path(trace_dir, "case-search.csv")
schema_path <- file.path(output_dir, "input.csv")
write.csv(
  data.frame(
    predictor = c(1, 2),
    response = c(3, 4),
    treatment = c("A", "B")
  ),
  schema_path,
  row.names = FALSE
)

write_search_receipt <- function(
  case_ids = c("verified-scatter", "other-case"),
  path = search_receipt_path,
  query = "verified grouped scatter treatment",
  search_intent = "relationship",
  scope = "public",
  schema_hash = figureforge_sha256(schema_path)
) {
  result_count <- max(1L, length(case_ids))
  write.csv(
    data.frame(
      receipt_schema_version = rep("2", result_count),
      receipt_generator = rep("figureforge-search_cases", result_count),
      search_query_sha256 = rep(
        figureforge_sha256_text(query),
        result_count
      ),
      search_intent = rep(search_intent, result_count),
      search_scope = rep(scope, result_count),
      schema_sha256 = rep(schema_hash, result_count),
      search_limit = rep(5L, result_count),
      completed_only = rep(FALSE, result_count),
      explain_scores = rep(TRUE, result_count),
      result_rank = if (length(case_ids)) seq_along(case_ids) else NA_integer_,
      case_id_sha256 = if (length(case_ids)) {
        vapply(case_ids, figureforge_sha256_text, character(1L))
      } else {
        ""
      },
      score = if (length(case_ids)) seq_along(case_ids) else NA_real_,
      stringsAsFactors = FALSE
    ),
    path,
    row.names = FALSE,
    fileEncoding = "UTF-8",
    na = ""
  )
  invisible(path)
}
write_search_receipt()

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
    search_query_sha256 = figureforge_sha256_text(
      "verified grouped scatter treatment"
    ),
    search_intent = "relationship",
    search_receipt_file = "case-search.csv",
    search_receipt_sha256 = figureforge_sha256(search_receipt_path),
    primary_case_id = "verified-scatter",
    case_md_file = "case.md",
    case_md_sha256 = figureforge_sha256(file.path(case_directory, "case.md")),
    plot_r_file = "plot.R",
    plot_r_sha256 = figureforge_sha256(file.path(case_directory, "plot.R")),
    schema_mapping = "predictor -> x | response -> y",
    adopted_patterns = paste(
      "case.md#overall composition => plot.R#ggplot2::geom_point",
      "plot.R#ggplot2::geom_point => plot.R#confidence_alpha_mapping",
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
    script_path = script_path,
    schema_path = schema_path
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
  script_path = script_path,
  schema_path = schema_path
)
expect_result_shape(valid)
stopifnot(isTRUE(valid$ok))
stopifnot(length(valid$failed_checks) == 0L)
stopifnot(identical(valid$evidence$generation_mode, "case_based"))

missing_search_query_hash <- case_based_fields()
missing_search_query_hash$search_query_sha256 <- NULL
expect_invalid(missing_search_query_hash, "required common metadata")

invalid_search_query_hash <- case_based_fields()
invalid_search_query_hash$search_query_sha256 <- "not-a-hash"
expect_invalid(invalid_search_query_hash, "search query hash format")

invalid_search_intent <- case_based_fields()
invalid_search_intent$search_intent <- "SSN 123-45-6789 password=secret"
expect_invalid(invalid_search_intent, "controlled search intent")

legacy_raw_query <- case_based_fields()
legacy_raw_query$search_query <-
  "source(user_identifier) password=secret SSN 123-45-6789"
expect_invalid(legacy_raw_query, "raw search query is not persisted")

missing_search_receipt_file <- case_based_fields()
missing_search_receipt_file$search_receipt_file <- NULL
expect_invalid(missing_search_receipt_file, "required common metadata")

unsafe_search_receipt <- case_based_fields()
unsafe_search_receipt$search_receipt_file <- "../case-search.csv"
expect_invalid(
  unsafe_search_receipt,
  "search receipt filename is safe"
)

absolute_search_receipt <- case_based_fields()
absolute_search_receipt$search_receipt_file <- "/tmp/case-search.csv"
expect_invalid(
  absolute_search_receipt,
  "search receipt filename is safe"
)

wrong_search_receipt_extension <- case_based_fields()
wrong_search_receipt_extension$search_receipt_file <- "case-search.tsv"
expect_invalid(
  wrong_search_receipt_extension,
  "search receipt filename is safe"
)

missing_search_receipt <- case_based_fields()
unlink(search_receipt_path)
expect_invalid(
  missing_search_receipt,
  "search receipt is regular non-empty CSV"
)
write_search_receipt()

empty_search_receipt <- case_based_fields()
writeLines(character(0), search_receipt_path)
expect_invalid(
  empty_search_receipt,
  "search receipt is regular non-empty CSV"
)
write_search_receipt()

external_search_receipt <- file.path(fixture_root, "external-search.csv")
write_search_receipt(path = external_search_receipt)
unlink(search_receipt_path)
stopifnot(file.symlink(external_search_receipt, search_receipt_path))
symlinked_search_receipt <- case_based_fields()
expect_invalid(
  symlinked_search_receipt,
  "search receipt is regular non-empty CSV"
)
unlink(search_receipt_path)
write_search_receipt()

bad_search_receipt_hash <- case_based_fields()
bad_search_receipt_hash$search_receipt_sha256 <- "not-a-hash"
expect_invalid(
  bad_search_receipt_hash,
  "search receipt hash format"
)

mismatched_search_receipt_hash <- case_based_fields()
mismatched_search_receipt_hash$search_receipt_sha256 <- paste(
  rep("0", 64L),
  collapse = ""
)
expect_invalid(
  mismatched_search_receipt_hash,
  "search receipt hash matches"
)

stale_query_receipt <- case_based_fields()
write_search_receipt(query = "a different stale query")
stale_query_receipt$search_receipt_sha256 <-
  figureforge_sha256(search_receipt_path)
expect_invalid(
  stale_query_receipt,
  "search receipt matches recorded query hash"
)
write_search_receipt()

case_receipt_without_schema <- case_based_fields()
write_search_receipt(schema_hash = "none")
case_receipt_without_schema$search_receipt_sha256 <-
  figureforge_sha256(search_receipt_path)
expect_invalid(
  case_receipt_without_schema,
  "search receipt binds input schema"
)
write_search_receipt()

minimal_handmade_receipt <- case_based_fields()
write.csv(
  data.frame(case_id = "verified-scatter"),
  search_receipt_path,
  row.names = FALSE
)
minimal_handmade_receipt$search_receipt_sha256 <-
  figureforge_sha256(search_receipt_path)
expect_invalid(
  minimal_handmade_receipt,
  "search receipt schema is supported"
)
write_search_receipt()

unsafe_content_receipt <- case_based_fields()
unsafe_receipt <- read.csv(
  search_receipt_path,
  stringsAsFactors = FALSE,
  check.names = FALSE
)
unsafe_receipt$case_path <- "/private/cases/verified-scatter"
write.csv(unsafe_receipt, search_receipt_path, row.names = FALSE)
unsafe_content_receipt$search_receipt_sha256 <-
  figureforge_sha256(search_receipt_path)
expect_invalid(
  unsafe_content_receipt,
  "search receipt content is privacy-safe"
)
write_search_receipt()

case_absent_from_search_receipt <- case_based_fields()
write_search_receipt("other-case")
case_absent_from_search_receipt$search_receipt_sha256 <-
  figureforge_sha256(search_receipt_path)
expect_invalid(
  case_absent_from_search_receipt,
  "search receipt matches generation mode"
)
write_search_receipt()
write_trace(valid_fields)
stopifnot(identical(valid$evidence$primary_case_id, "verified-scatter"))
stopifnot(identical(
  valid$evidence$generated_script_sha256,
  figureforge_sha256(script_path)
))
stopifnot(identical(valid$evidence$verification_level, "strict"))
stopifnot("generated script hash matches" %in% names(valid$checks))
stopifnot("case evidence hashes match" %in% names(valid$checks))
stopifnot("source anchors match case evidence" %in% names(valid$checks))
stopifnot("generated anchors match script" %in% names(valid$checks))
stopifnot("input schema hash matches search receipt" %in% names(valid$checks))

other_schema_path <- file.path(output_dir, "other-input.csv")
write.csv(data.frame(other = 1), other_schema_path, row.names = FALSE)
wrong_schema <- validate_case_trace(
  trace_path,
  case_dir = case_dir,
  script_path = script_path,
  schema_path = other_schema_path
)
expect_result_shape(wrong_schema)
stopifnot(!isTRUE(wrong_schema$ok))
stopifnot(
  "input schema hash matches search receipt" %in%
    wrong_schema$failed_checks
)

case_trace_cli <- file.path(
  repo_root,
  "skills",
  "figureforge",
  "scripts",
  "validate_case_trace.R"
)
stopifnot(file.exists(case_trace_cli))

run_case_trace_cli <- function(arguments) {
  run_case_trace_cli_at(case_trace_cli, arguments)
}

run_case_trace_cli_at <- function(cli_path, arguments) {
  output <- suppressWarnings(system2(
    "/usr/local/bin/Rscript",
    c(shQuote(cli_path), shQuote(arguments)),
    stdout = TRUE,
    stderr = TRUE
  ))
  list(
    status = attr(output, "status"),
    output = paste(output, collapse = "\n")
  )
}

vendor_project <- file.path(fixture_root, "vendor-layout-project")
vendor_skill_root <- file.path(vendor_project, "vendor", "figureforge")
vendor_script_dir <- file.path(vendor_skill_root, "scripts")
vendor_lib_dir <- file.path(vendor_skill_root, "lib")
poison_lib_dir <- file.path(
  vendor_project,
  "skills",
  "figureforge",
  "lib"
)
dir.create(vendor_script_dir, recursive = TRUE)
dir.create(vendor_lib_dir, recursive = TRUE)
dir.create(poison_lib_dir, recursive = TRUE)
file.copy(case_trace_cli, vendor_script_dir, overwrite = TRUE)
for (library_file in c(
  "distribution_validation.R",
  "checksums.R",
  "case_trace_validation.R"
)) {
  file.copy(
    file.path(
      repo_root,
      "skills",
      "figureforge",
      "lib",
      library_file
    ),
    vendor_lib_dir,
    overwrite = TRUE
  )
}
writeLines(
  'stop("poison sibling skill root loaded")',
  file.path(poison_lib_dir, "distribution_validation.R"),
  useBytes = TRUE
)
vendor_cli <- run_case_trace_cli_at(
  file.path(vendor_script_dir, "validate_case_trace.R"),
  trace_path
)
stopifnot(is.null(vendor_cli$status))
stopifnot(grepl(
  "Verification level: structural",
  vendor_cli$output,
  fixed = TRUE
))
stopifnot(grepl(
  paste0("Case trace validation OK: ", trace_path),
  vendor_cli$output,
  fixed = TRUE
))
stopifnot(!grepl("poison sibling", vendor_cli$output, fixed = TRUE))

shell_quote <- function(value) {
  paste0("'", gsub("'", "'\"'\"'", value, fixed = TRUE), "'")
}

spaced_install_root <- file.path(
  fixture_root,
  "installed Skill path with space and 'quote' literal~tilde+plus"
)
spaced_install_scripts <- file.path(spaced_install_root, "scripts")
spaced_install_lib <- file.path(spaced_install_root, "lib")
dir.create(spaced_install_scripts, recursive = TRUE)
dir.create(spaced_install_lib, recursive = TRUE)
file.copy(case_trace_cli, spaced_install_scripts, overwrite = TRUE)
for (library_file in c(
  "distribution_validation.R",
  "checksums.R",
  "case_trace_validation.R"
)) {
  file.copy(
    file.path(
      repo_root,
      "skills",
      "figureforge",
      "lib",
      library_file
    ),
    spaced_install_lib,
    overwrite = TRUE
  )
}
spaced_install_cli <- file.path(
  spaced_install_scripts,
  "validate_case_trace.R"
)
spaced_install_runner <- file.path(
  fixture_root,
  "run-spaced-installed-cli.sh"
)
writeLines(
  c(
    "#!/bin/sh",
    "set -eu",
    paste(
      "exec",
      shell_quote("/usr/local/bin/Rscript"),
      shell_quote(spaced_install_cli),
      shell_quote(trace_path),
      "--case-dir",
      shell_quote(case_dir),
      "--script",
      shell_quote(script_path),
      "--schema",
      shell_quote(schema_path)
    )
  ),
  spaced_install_runner,
  useBytes = TRUE
)
spaced_install_output <- suppressWarnings(system2(
  "sh",
  shQuote(spaced_install_runner),
  stdout = TRUE,
  stderr = TRUE
))
stopifnot(is.null(attr(spaced_install_output, "status")))
spaced_install_text <- paste(spaced_install_output, collapse = "\n")
stopifnot(grepl(
  "Verification level: strict",
  spaced_install_text,
  fixed = TRUE
))
stopifnot(grepl(
  paste0("Case trace validation OK: ", trace_path),
  spaced_install_text,
  fixed = TRUE
))

missing_lib_root <- file.path(fixture_root, "missing-lib-skill")
missing_lib_script_dir <- file.path(missing_lib_root, "scripts")
dir.create(missing_lib_script_dir, recursive = TRUE)
file.copy(case_trace_cli, missing_lib_script_dir, overwrite = TRUE)
missing_lib_cli <- run_case_trace_cli_at(
  file.path(missing_lib_script_dir, "validate_case_trace.R"),
  trace_path
)
stopifnot(!is.null(missing_lib_cli$status))
stopifnot(identical(as.integer(missing_lib_cli$status), 1L))
stopifnot(grepl(
  "Verification level: unavailable",
  missing_lib_cli$output,
  fixed = TRUE
))
stopifnot(grepl(
  "Case trace validation failed:",
  missing_lib_cli$output,
  fixed = TRUE
))
stopifnot(grepl(
  "Required Skill library is unavailable: distribution_validation.R",
  missing_lib_cli$output,
  fixed = TRUE
))
stopifnot(!grepl("Warning message:", missing_lib_cli$output, fixed = TRUE))
stopifnot(!grepl("Calls:", missing_lib_cli$output, fixed = TRUE))
stopifnot(!grepl(
  normalizePath(missing_lib_root, mustWork = TRUE),
  missing_lib_cli$output,
  fixed = TRUE
))
missing_lib_output_lines <- strsplit(
  missing_lib_cli$output,
  "\n",
  fixed = TRUE
)[[1L]]
stopifnot(identical(
  tail(missing_lib_output_lines, 1L),
  paste(
    "Case trace validation failed:",
    "Required Skill library is unavailable: distribution_validation.R"
  )
))

expect_cli_input_failure <- function(arguments, detail) {
  result <- run_case_trace_cli(arguments)
  stopifnot(!is.null(result$status))
  stopifnot(identical(as.integer(result$status), 1L))
  stopifnot(grepl(
    "Case trace validation failed:",
    result$output,
    fixed = TRUE
  ))
  stopifnot(grepl(
    "Verification level: unavailable",
    result$output,
    fixed = TRUE
  ))
  stopifnot(grepl(detail, result$output, fixed = TRUE))
  stopifnot(grepl("Usage: validate_case_trace.R", result$output, fixed = TRUE))
  invisible(result)
}

expect_cli_input_failure(character(0), "Usage: validate_case_trace.R")
expect_cli_input_failure(
  c(trace_path, "--unknown"),
  "Unknown or incomplete argument: --unknown"
)
expect_cli_input_failure(
  c(trace_path, "--case-dir"),
  "Unknown or incomplete argument: --case-dir"
)

strict_cli <- run_case_trace_cli(c(
  trace_path,
  "--case-dir", case_dir,
  "--script", script_path,
  "--schema", schema_path
))
stopifnot(is.null(strict_cli$status))
stopifnot(grepl(
  "generated script hash matches: PASS",
  strict_cli$output,
  fixed = TRUE
))
stopifnot(grepl(
  "Verification level: strict",
  strict_cli$output,
  fixed = TRUE
))
stopifnot(grepl(
  paste0("Case trace validation OK: ", trace_path),
  strict_cli$output,
  fixed = TRUE
))

partial_cli <- run_case_trace_cli(c(
  trace_path,
  "--case-dir", case_dir
))
stopifnot(is.null(partial_cli$status))
stopifnot(grepl(
  "Verification level: partial",
  partial_cli$output,
  fixed = TRUE
))

case_and_script_without_schema_cli <- run_case_trace_cli(c(
  trace_path,
  "--case-dir", case_dir,
  "--script", script_path
))
stopifnot(is.null(case_and_script_without_schema_cli$status))
stopifnot(grepl(
  "Verification level: partial",
  case_and_script_without_schema_cli$output,
  fixed = TRUE
))

structural_cli <- run_case_trace_cli(trace_path)
stopifnot(is.null(structural_cli$status))
stopifnot(grepl(
  "Verification level: structural",
  structural_cli$output,
  fixed = TRUE
))

invalid_cli_fields <- valid_fields
invalid_cli_fields$claim <- "general_method"
write_trace(invalid_cli_fields)
invalid_cli <- run_case_trace_cli(trace_path)
stopifnot(!is.null(invalid_cli$status))
stopifnot(identical(as.integer(invalid_cli$status), 1L))
stopifnot(grepl(
  "claim matches generation mode: FAIL",
  invalid_cli$output,
  fixed = TRUE
))
stopifnot(grepl(
  "Case trace validation failed: claim matches generation mode",
  invalid_cli$output,
  fixed = TRUE
))
write_trace(valid_fields)

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
  "QA evidence matches case",
  "source anchors match case evidence",
  "generated anchors match script"
) %in% names(structural$checks)))

case_only <- validate_case_trace(
  trace_path,
  case_dir = case_dir
)
expect_result_shape(case_only)
stopifnot(isTRUE(case_only$ok))
stopifnot(identical(case_only$evidence$verification_level, "partial"))
stopifnot("case evidence hashes match" %in% names(case_only$checks))
stopifnot("source anchors match case evidence" %in% names(case_only$checks))
stopifnot(!"generated anchors match script" %in% names(case_only$checks))
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
stopifnot(!"source anchors match case evidence" %in% names(script_only$checks))
stopifnot("generated anchors match script" %in% names(script_only$checks))

case_and_script_without_schema <- validate_case_trace(
  trace_path,
  case_dir = case_dir,
  script_path = script_path
)
expect_result_shape(case_and_script_without_schema)
stopifnot(isTRUE(case_and_script_without_schema$ok))
stopifnot(identical(
  case_and_script_without_schema$evidence$verification_level,
  "partial"
))

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
  case_md_lines,
  file.path(case_dir, "case.md"),
  useBytes = TRUE
)

directory_case_fields <- case_based_fields()
write_trace(directory_case_fields)
unlink(file.path(case_dir, "case.md"))
dir.create(file.path(case_dir, "case.md"))
directory_case_result <- validate_case_trace(
  trace_path,
  case_dir = case_dir,
  script_path = script_path
)
expect_result_shape(directory_case_result)
stopifnot(!isTRUE(directory_case_result$ok))
stopifnot(
  "source anchors match case evidence" %in%
    directory_case_result$failed_checks
)
unlink(file.path(case_dir, "case.md"), recursive = TRUE, force = TRUE)
writeLines(
  case_md_lines,
  file.path(case_dir, "case.md"),
  useBytes = TRUE
)

for (linked_evidence in c("case.md", "plot.R", "qa.md")) {
  evidence_path <- file.path(case_dir, linked_evidence)
  evidence_bytes <- readBin(
    evidence_path,
    "raw",
    n = file.info(evidence_path)$size
  )
  external_evidence <- file.path(
    fixture_root,
    paste0("external-", linked_evidence)
  )
  writeBin(evidence_bytes, external_evidence)
  linked_fields <- case_based_fields()
  write_trace(linked_fields)
  unlink(evidence_path)
  stopifnot(file.symlink(external_evidence, evidence_path))
  linked_result <- validate_case_trace(
    trace_path,
    case_dir = case_dir,
    script_path = script_path,
    schema_path = schema_path
  )
  expect_result_shape(linked_result)
  stopifnot(!isTRUE(linked_result$ok))
  expected_failure <- if (identical(linked_evidence, "qa.md")) {
    "QA evidence matches case"
  } else {
    "case evidence hashes match"
  }
  stopifnot(expected_failure %in% linked_result$failed_checks)
  unlink(evidence_path)
  writeBin(evidence_bytes, evidence_path)
}

linked_case_parent <- file.path(fixture_root, "linked-cases")
dir.create(linked_case_parent)
linked_case_dir <- file.path(linked_case_parent, "verified-scatter")
stopifnot(file.symlink(case_dir, linked_case_dir))
write_trace(case_based_fields())
linked_case_result <- validate_case_trace(
  trace_path,
  case_dir = linked_case_dir,
  script_path = script_path,
  schema_path = schema_path
)
expect_result_shape(linked_case_result)
stopifnot(!isTRUE(linked_case_result$ok))
stopifnot(
  "case evidence hashes match" %in% linked_case_result$failed_checks
)

unreadable_case_fields <- case_based_fields()
write_trace(unreadable_case_fields)
Sys.chmod(file.path(case_dir, "case.md"), mode = "0000")
if (file.access(file.path(case_dir, "case.md"), mode = 4L) != 0L) {
  unreadable_case_result <- validate_case_trace(
    trace_path,
    case_dir = case_dir,
    script_path = script_path
  )
  expect_result_shape(unreadable_case_result)
  stopifnot(!isTRUE(unreadable_case_result$ok))
  stopifnot(
    "source anchors match case evidence" %in%
      unreadable_case_result$failed_checks
  )
}
Sys.chmod(file.path(case_dir, "case.md"), mode = "0644")

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
  generated_script_lines,
  script_path,
  useBytes = TRUE
)

directory_script_fields <- case_based_fields()
write_trace(directory_script_fields)
unlink(script_path)
dir.create(script_path)
directory_script_result <- validate_case_trace(
  trace_path,
  script_path = script_path
)
expect_result_shape(directory_script_result)
stopifnot(!isTRUE(directory_script_result$ok))
stopifnot(
  "generated anchors match script" %in%
    directory_script_result$failed_checks
)
unlink(script_path, recursive = TRUE, force = TRUE)
writeLines(generated_script_lines, script_path, useBytes = TRUE)

empty_mapping <- case_based_fields()
empty_mapping$schema_mapping <- ""
expect_invalid(empty_mapping, "non-empty schema mapping")

empty_patterns <- case_based_fields()
empty_patterns$adopted_patterns <- ""
expect_invalid(empty_patterns, "auditable adopted pattern format")

auditable_pattern_examples <- c(
  "plot.R#ggplot2::geom_point => plot.R#confidence_alpha_mapping",
  "case.md#overall composition => plot.R#ggplot2::geom_point",
  "qa.md#confidence ribbon => plot.R#lower_upper_bounds",
  "plot.R#ggplot2::facet_wrap => plot.R#facet_group_layout",
  paste(
    "case.md#generalized additive model",
    "plot.R#stats::loess",
    sep = " => "
  ),
  "case.md#分面布局 => plot.R#facet_group_layout",
  "case.md#颜色映射区分处理组 => plot.R#confidence_alpha_mapping",
  "qa.md#lower and upper bounds => plot.R#range("
)
auditable_patterns <- case_based_fields()
auditable_patterns$adopted_patterns <- paste(
  auditable_pattern_examples,
  collapse = " | "
)
write_trace(auditable_patterns)
valid_auditable_patterns <- validate_case_trace(
  trace_path,
  case_dir = case_dir,
  script_path = script_path,
  schema_path = schema_path
)
expect_result_shape(valid_auditable_patterns)
stopifnot(isTRUE(valid_auditable_patterns$ok))
stopifnot(all(vapply(
  auditable_pattern_examples,
  adopted_pattern_is_auditable,
  logical(1L)
)))

invalid_pattern_examples <- c(
  "overall composition => plot.R#stats::loess",
  "data.csv#overall composition => plot.R#stats::loess",
  "case.md# => plot.R#stats::loess",
  "case.md#made plot => plot.R#stats::loess",
  "case.md#drew chart => plot.R#stats::loess",
  "case.md#made figure => plot.R#stats::loess",
  "case.md#colors => plot.R#stats::loess",
  "case.md#plot => plot.R#stats::loess",
  "case.md#分面布 => plot.R#facet_group_layout",
  "case.md#overall composition => case.md#stats::loess",
  "case.md#overall composition => data.csv#stats::loess",
  "case.md#overall composition => plot.R#plot",
  "case.md#overall composition => plot.R#twelve letters",
  "case.md#/private/case => plot.R#stats::loess",
  "plot.R#geom_point => plot.R#C:\\private\\decision",
  "plot.R#geom_point => plot.R#decision => extra",
  "plot.R#geom_point => plot.R#confidence_alpha_mapping |",
  "| plot.R#geom_point => plot.R#confidence_alpha_mapping"
)
for (invalid_pattern in invalid_pattern_examples) {
  invalid_adopted_pattern <- case_based_fields()
  invalid_adopted_pattern$adopted_patterns <- invalid_pattern
  expect_invalid(
    invalid_adopted_pattern,
    "auditable adopted pattern format"
  )
  stopifnot(!isTRUE(adopted_pattern_is_auditable(invalid_pattern)))
}

mixed_auditable_and_invalid <- case_based_fields()
mixed_auditable_and_invalid$adopted_patterns <- paste(
  auditable_pattern_examples[[1L]],
  "case.md#made plot => plot.R#stats::loess",
  sep = " | "
)
expect_invalid(
  mixed_auditable_and_invalid,
  "auditable adopted pattern format"
)

nonexistent_source_anchor <- case_based_fields()
nonexistent_source_anchor$adopted_patterns <-
  "plot.R#nonexistent source anchor => plot.R#confidence_alpha_mapping"
write_trace(nonexistent_source_anchor)
nonexistent_source_structural <- validate_case_trace(trace_path)
expect_result_shape(nonexistent_source_structural)
stopifnot(isTRUE(nonexistent_source_structural$ok))
nonexistent_source_script_only <- validate_case_trace(
  trace_path,
  script_path = script_path
)
expect_result_shape(nonexistent_source_script_only)
stopifnot(isTRUE(nonexistent_source_script_only$ok))
nonexistent_source_case_only <- validate_case_trace(
  trace_path,
  case_dir = case_dir
)
expect_result_shape(nonexistent_source_case_only)
stopifnot(!isTRUE(nonexistent_source_case_only$ok))
stopifnot(
  "source anchors match case evidence" %in%
    nonexistent_source_case_only$failed_checks
)
nonexistent_source_strict <- validate_case_trace(
  trace_path,
  case_dir = case_dir,
  script_path = script_path,
  schema_path = schema_path
)
expect_result_shape(nonexistent_source_strict)
stopifnot(!isTRUE(nonexistent_source_strict$ok))
stopifnot(
  "source anchors match case evidence" %in%
    nonexistent_source_strict$failed_checks
)

source_comment_only_lines <- c(
  plot_r_lines,
  "# source_comment_only_anchor"
)
writeLines(
  source_comment_only_lines,
  file.path(case_dir, "plot.R"),
  useBytes = TRUE
)
source_comment_only_fields <- case_based_fields()
source_comment_only_fields$adopted_patterns <-
  "plot.R#source_comment_only_anchor => plot.R#ggplot2::geom_point"
write_trace(source_comment_only_fields)
source_comment_only_result <- validate_case_trace(
  trace_path,
  case_dir = case_dir
)
expect_result_shape(source_comment_only_result)
stopifnot(!isTRUE(source_comment_only_result$ok))
stopifnot(
  "source anchors match case evidence" %in%
    source_comment_only_result$failed_checks
)
writeLines(
  plot_r_lines,
  file.path(case_dir, "plot.R"),
  useBytes = TRUE
)

nonexistent_generated_anchor <- case_based_fields()
nonexistent_generated_anchor$adopted_patterns <-
  "case.md#overall composition => plot.R#nonexistent_generated_anchor"
write_trace(nonexistent_generated_anchor)
nonexistent_generated_structural <- validate_case_trace(trace_path)
expect_result_shape(nonexistent_generated_structural)
stopifnot(isTRUE(nonexistent_generated_structural$ok))
nonexistent_generated_case_only <- validate_case_trace(
  trace_path,
  case_dir = case_dir
)
expect_result_shape(nonexistent_generated_case_only)
stopifnot(isTRUE(nonexistent_generated_case_only$ok))
nonexistent_generated_script_only <- validate_case_trace(
  trace_path,
  script_path = script_path
)
expect_result_shape(nonexistent_generated_script_only)
stopifnot(!isTRUE(nonexistent_generated_script_only$ok))
stopifnot(
  "generated anchors match script" %in%
    nonexistent_generated_script_only$failed_checks
)
nonexistent_generated_strict <- validate_case_trace(
  trace_path,
  case_dir = case_dir,
  script_path = script_path,
  schema_path = schema_path
)
expect_result_shape(nonexistent_generated_strict)
stopifnot(!isTRUE(nonexistent_generated_strict$ok))
stopifnot(
  "generated anchors match script" %in%
    nonexistent_generated_strict$failed_checks
)

comment_only_lines <- c(
  generated_script_lines,
  "# comment_only_anchor"
)
writeLines(comment_only_lines, script_path, useBytes = TRUE)
comment_only_fields <- case_based_fields()
comment_only_fields$adopted_patterns <-
  "case.md#overall composition => plot.R#comment_only_anchor"
write_trace(comment_only_fields)
comment_only_result <- validate_case_trace(
  trace_path,
  script_path = script_path
)
expect_result_shape(comment_only_result)
stopifnot(!isTRUE(comment_only_result$ok))
stopifnot(
  "generated anchors match script" %in%
    comment_only_result$failed_checks
)
writeLines(generated_script_lines, script_path, useBytes = TRUE)

dead_symbol_lines <- append(
  generated_script_lines,
  "dead_provenance_symbol <- 1",
  after = 1L
)
writeLines(dead_symbol_lines, script_path, useBytes = TRUE)
dead_symbol_fields <- case_based_fields()
dead_symbol_fields$adopted_patterns <-
  "case.md#overall composition => plot.R#dead_provenance_symbol"
write_trace(dead_symbol_fields)
dead_symbol_result <- validate_case_trace(
  trace_path,
  script_path = script_path
)
expect_result_shape(dead_symbol_result)
stopifnot(isTRUE(
  dead_symbol_result$checks[["generated anchors match script"]]
))
stopifnot(identical(
  dead_symbol_result$evidence$anchor_validation,
  "anchor_presence"
))
writeLines(generated_script_lines, script_path, useBytes = TRUE)

writeLines(
  "invalid_parse_anchor <- function(",
  script_path,
  useBytes = TRUE
)
invalid_parse_fields <- case_based_fields()
invalid_parse_fields$adopted_patterns <-
  "case.md#overall composition => plot.R#invalid_parse_anchor"
write_trace(invalid_parse_fields)
invalid_parse_result <- validate_case_trace(
  trace_path,
  script_path = script_path
)
expect_result_shape(invalid_parse_result)
stopifnot(!isTRUE(invalid_parse_result$ok))
stopifnot(
  "generated anchors match script" %in%
    invalid_parse_result$failed_checks
)
writeLines(generated_script_lines, script_path, useBytes = TRUE)

wrong_script_path <- file.path(output_dir, "not-plot.R")
writeLines(generated_script_lines, wrong_script_path, useBytes = TRUE)
write_trace(case_based_fields())
wrong_script_name_partial <- validate_case_trace(
  trace_path,
  script_path = wrong_script_path
)
expect_result_shape(wrong_script_name_partial)
stopifnot(!isTRUE(wrong_script_name_partial$ok))
stopifnot(
  "generated anchors match script" %in%
    wrong_script_name_partial$failed_checks
)
wrong_script_name_result <- validate_case_trace(
  trace_path,
  case_dir = case_dir,
  script_path = wrong_script_path,
  schema_path = schema_path
)
expect_result_shape(wrong_script_name_result)
stopifnot(!isTRUE(wrong_script_name_result$ok))
stopifnot(
  "generated anchors match script" %in%
    wrong_script_name_result$failed_checks
)

qa_missing_reference <- case_based_fields()
qa_missing_reference <- qa_missing_reference[
  !names(qa_missing_reference) %in% c("qa_md_file", "qa_md_sha256")
]
qa_missing_reference$qa_status <- "missing"
qa_missing_reference$adopted_patterns <-
  "qa.md#confidence ribbon => plot.R#lower_upper_bounds"
write_trace(qa_missing_reference)
qa_missing_structural <- validate_case_trace(trace_path)
expect_result_shape(qa_missing_structural)
stopifnot(!isTRUE(qa_missing_structural$ok))
stopifnot(
  "auditable adopted pattern format" %in%
    qa_missing_structural$failed_checks
)
stopifnot(!isTRUE(adopted_pattern_is_auditable(
  qa_missing_reference$adopted_patterns,
  qa_available = FALSE
)))

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
  qa_md_lines,
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
write_search_receipt(c("verified-scatter", "unverified-scatter"))
missing_qa_fields$search_receipt_sha256 <-
  figureforge_sha256(search_receipt_path)
write_trace(missing_qa_fields)
valid_missing_qa <- validate_case_trace(
  trace_path,
  case_dir = case_without_qa,
  script_path = script_path,
  schema_path = schema_path
)
expect_result_shape(valid_missing_qa)
stopifnot(isTRUE(valid_missing_qa$ok))
stopifnot(identical(valid_missing_qa$evidence$qa_status, "missing"))
write_search_receipt()

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

fallback_query <- "PCA biplot with loading arrows"
write_search_receipt(
  character(0),
  query = fallback_query,
  search_intent = "ordination"
)
fallback_fields <- list(
  schema_version = "1",
  generation_mode = "general_fallback",
  figureforge_version = "1.1.0",
  generated_script_sha256 = figureforge_sha256(script_path),
  claim = "general_method",
  search_query_sha256 = figureforge_sha256_text(fallback_query),
  search_intent = "ordination",
  search_receipt_file = "case-search.csv",
  search_receipt_sha256 = figureforge_sha256(search_receipt_path),
  fallback_reason = "No case matched the requested schema and figure type."
)
write_trace(fallback_fields)
fallback <- validate_case_trace(
  trace_path,
  script_path = script_path,
  schema_path = schema_path
)
expect_result_shape(fallback)
stopifnot(isTRUE(fallback$ok))
stopifnot(length(fallback$failed_checks) == 0L)
stopifnot(identical(fallback$evidence$verification_level, "strict"))
stopifnot(identical(
  fallback$evidence$generation_mode,
  "general_fallback"
))

fallback_without_schema_path <- validate_case_trace(
  trace_path,
  script_path = script_path
)
expect_result_shape(fallback_without_schema_path)
stopifnot(isTRUE(fallback_without_schema_path$ok))
stopifnot(identical(
  fallback_without_schema_path$evidence$verification_level,
  "partial"
))

fallback_receipt_without_schema <- fallback_fields
write_search_receipt(
  character(0),
  query = fallback_query,
  search_intent = "ordination",
  schema_hash = "none"
)
fallback_receipt_without_schema$search_receipt_sha256 <-
  figureforge_sha256(search_receipt_path)
expect_invalid(
  fallback_receipt_without_schema,
  "search receipt binds input schema",
  case_directory = NULL
)
write_search_receipt(
  character(0),
  query = fallback_query,
  search_intent = "ordination"
)
fallback_fields$search_receipt_sha256 <-
  figureforge_sha256(search_receipt_path)

malformed_fallback_receipt <- fallback_fields
writeLines("not_case_id,not_a_search_receipt", search_receipt_path)
malformed_fallback_receipt$search_receipt_sha256 <-
  figureforge_sha256(search_receipt_path)
expect_invalid(
  malformed_fallback_receipt,
  "search receipt matches generation mode",
  case_directory = NULL
)
write_search_receipt(
  character(0),
  query = fallback_query,
  search_intent = "ordination"
)
fallback_fields$search_receipt_sha256 <-
  figureforge_sha256(search_receipt_path)

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
  script_path = script_path,
  schema_path = schema_path
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
  script_path = script_path,
  schema_path = schema_path
)
expect_result_shape(valid_https_url)
stopifnot(isTRUE(valid_https_url$ok))

write_search_receipt()
role_mapping_text <- case_based_fields()
role_mapping_text$departures <- "role -> column"
write_trace(role_mapping_text)
valid_role_mapping_text <- validate_case_trace(
  trace_path,
  case_dir = case_dir,
  script_path = script_path,
  schema_path = schema_path
)
expect_result_shape(valid_role_mapping_text)
stopifnot(isTRUE(valid_role_mapping_text$ok))

message("case trace validation tests: PASS")
}

run_tests()
