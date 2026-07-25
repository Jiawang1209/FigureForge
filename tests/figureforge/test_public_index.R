#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
script_path <- if (length(file_arg) > 0L) {
  normalizePath(sub("^--file=", "", file_arg[[1L]]), mustWork = TRUE)
} else {
  normalizePath(
    "tests/figureforge/test_public_index.R",
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

public_cases_dir <- file.path(
  repo_root,
  "skills",
  "figureforge",
  "public-cases"
)
catalog <- build_public_catalog(public_cases_dir)
stopifnot(nrow(catalog) == 12L)
stopifnot(identical(catalog$case_id, sort(catalog$case_id)))
stopifnot(all(catalog$distribution_status == "public_ready"))
stopifnot(all(catalog$synthetic_test_fixture))
stopifnot(!any(grepl("/cases/", catalog$case_path, fixed = TRUE)))

index_script <- file.path(
  repo_root,
  "skills",
  "figureforge",
  "scripts",
  "index_cases.R"
)
run_index <- function(output_path) {
  log_path <- tempfile("figureforge-public-index-", fileext = ".log")
  status <- system2(
    "/usr/local/bin/Rscript",
    shQuote(c(
      index_script,
      "--public-cases",
      public_cases_dir,
      "--output",
      output_path
    )),
    stdout = log_path,
    stderr = log_path
  )
  list(
    status = as.integer(status),
    log = paste(readLines(log_path, warn = FALSE), collapse = "\n")
  )
}

first_path <- tempfile("figureforge-public-index-", fileext = ".csv")
second_path <- tempfile("figureforge-public-index-", fileext = ".csv")
first <- run_index(first_path)
second <- run_index(second_path)
stopifnot(identical(first$status, 0L))
stopifnot(identical(second$status, 0L))

sha256 <- function(path) {
  output <- system2(
    "shasum",
    c("-a", "256", shQuote(path)),
    stdout = TRUE
  )
  strsplit(output[[1L]], "\\s+", perl = TRUE)[[1L]][[1L]]
}
stopifnot(identical(sha256(first_path), sha256(second_path)))

written <- read.csv(
  first_path,
  stringsAsFactors = FALSE,
  check.names = FALSE
)
stopifnot(nrow(written) == 12L)
stopifnot(!"case_path" %in% names(written))
stopifnot(identical(written$case_id, sort(written$case_id)))

tracked_path <- file.path(
  repo_root,
  "skills",
  "figureforge",
  "references",
  "public-case-index.csv"
)
stopifnot(file.exists(tracked_path))
stopifnot(identical(sha256(first_path), sha256(tracked_path)))

message("public index tests: PASS")
