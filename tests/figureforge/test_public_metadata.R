#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
script_path <- if (length(file_arg) > 0L) {
  normalizePath(sub("^--file=", "", file_arg[[1L]]), mustWork = TRUE)
} else {
  normalizePath(
    "tests/figureforge/test_public_metadata.R",
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
  "metadata.R"
))

fixtures <- file.path(
  repo_root,
  "tests",
  "fixtures",
  "figureforge",
  "metadata"
)

metadata <- read_case_metadata(file.path(fixtures, "valid"))
stopifnot(identical(metadata$case_id, "public-scatter-fit"))
stopifnot(identical(metadata$chart_family, "scatter"))
stopifnot(nrow(metadata$required_roles) == 2L)
stopifnot(identical(
  metadata$required_roles$role,
  c("x", "y")
))

valid_result <- validate_case_metadata(metadata)
stopifnot(isTRUE(valid_result$ok))
stopifnot(length(valid_result$failed_checks) == 0L)

invalid_metadata <- read_case_metadata(file.path(fixtures, "invalid"))
invalid_result <- validate_case_metadata(invalid_metadata)
stopifnot(!isTRUE(invalid_result$ok))
stopifnot("known chart taxonomy" %in% invalid_result$failed_checks)
stopifnot("QA remains review required" %in% invalid_result$failed_checks)

duplicate_roles <- metadata
duplicate_roles$optional_roles <- data.frame(
  role = "x",
  type = "numeric",
  cardinality = "continuous",
  stringsAsFactors = FALSE
)
duplicate_result <- validate_case_metadata(duplicate_roles)
stopifnot(!isTRUE(duplicate_result$ok))
stopifnot("unique schema roles" %in% duplicate_result$failed_checks)

message("public metadata tests: PASS")
