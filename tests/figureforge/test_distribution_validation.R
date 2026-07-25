#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
script_path <- if (length(file_arg) > 0L) {
  normalizePath(sub("^--file=", "", file_arg[[1L]]), mustWork = TRUE)
} else {
  normalizePath(
    "tests/figureforge/test_distribution_validation.R",
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

fixtures <- file.path(
  repo_root,
  "tests",
  "fixtures",
  "figureforge",
  "distribution"
)

valid <- validate_distribution(file.path(fixtures, "valid"))
stopifnot(isTRUE(valid$ok))
stopifnot(identical(valid$status, "public_ready"))
stopifnot(isTRUE(valid$synthetic_test_fixture))
stopifnot(length(valid$failed_checks) == 0L)

missing_asset <- validate_distribution(file.path(fixtures, "missing-asset"))
stopifnot(!isTRUE(missing_asset$ok))
stopifnot(
  "all distributed files allowlisted" %in% missing_asset$failed_checks
)

rights_unknown <- validate_distribution(file.path(fixtures, "rights-unknown"))
stopifnot(!isTRUE(rights_unknown$ok))
stopifnot(
  "recognized redistribution basis" %in% rights_unknown$failed_checks
)

validator_cli <- file.path(
  repo_root,
  "skills",
  "figureforge",
  "scripts",
  "validate_distribution.R"
)
run_cli <- function(case_dir, format = "text") {
  log_path <- tempfile("figureforge-distribution-", fileext = ".log")
  status <- system2(
    "/usr/local/bin/Rscript",
    shQuote(c(validator_cli, case_dir, "--format", format)),
    stdout = log_path,
    stderr = log_path
  )
  list(
    status = as.integer(status),
    output = paste(readLines(log_path, warn = FALSE), collapse = "\n")
  )
}

valid_cli <- run_cli(file.path(fixtures, "valid"))
stopifnot(identical(valid_cli$status, 0L))
stopifnot(grepl("Distribution validation OK", valid_cli$output, fixed = TRUE))

valid_csv_cli <- run_cli(file.path(fixtures, "valid"), format = "csv")
stopifnot(identical(valid_csv_cli$status, 0L))
stopifnot(grepl(
  "\"check\",\"status\"",
  valid_csv_cli$output,
  fixed = TRUE
))

invalid_cli <- run_cli(file.path(fixtures, "rights-unknown"))
stopifnot(!identical(invalid_cli$status, 0L))
stopifnot(grepl(
  "recognized redistribution basis: FAIL",
  invalid_cli$output,
  fixed = TRUE
))

message("distribution validation tests: PASS")
