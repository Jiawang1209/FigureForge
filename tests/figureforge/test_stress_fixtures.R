#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
script_path <- if (length(file_arg) > 0L) {
  normalizePath(sub("^--file=", "", file_arg[[1L]]), mustWork = TRUE)
} else {
  normalizePath(
    "tests/figureforge/test_stress_fixtures.R",
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
  "stress_fixtures.R"
))
source(file.path(
  repo_root,
  "skills",
  "figureforge",
  "lib",
  "metadata.R"
))
source(file.path(
  repo_root,
  "skills",
  "figureforge",
  "lib",
  "stress_runner.R"
))

public_cases_dir <- file.path(
  repo_root,
  "skills",
  "figureforge",
  "public-cases"
)
tracked_dir <- file.path(
  repo_root,
  "tests",
  "fixtures",
  "figureforge",
  "stress"
)

validate_fixture_root <- function(root) {
  manifest_path <- file.path(root, "manifest.csv")
  stopifnot(file.exists(manifest_path))
  manifest <- read.csv(
    manifest_path,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  stopifnot(nrow(manifest) == 24L)
  stopifnot(all(manifest$synthetic_test_fixture))
  stopifnot(all(nzchar(manifest$seed)))
  public_dirs <- list.dirs(
    public_cases_dir,
    recursive = FALSE,
    full.names = TRUE
  )
  synthetic_case_ids <- basename(public_dirs[vapply(
    public_dirs,
    function(case_dir) {
      isTRUE(read_case_metadata(case_dir)$synthetic_test_fixture)
    },
    logical(1)
  )])
  stopifnot(all(
    synthetic_case_ids %in% manifest$public_case_id
  ))
  stopifnot(all(table(manifest$public_case_id) == 2L))
  stopifnot(setequal(unique(manifest$outcome), c("success", "failure")))
  stopifnot(length(unique(manifest$chart_family)) == 12L)
  stopifnot(identical(manifest$fixture_id, sort(manifest$fixture_id)))

  for (fixture_id in manifest$fixture_id) {
    fixture_dir <- file.path(root, fixture_id)
    stopifnot(all(file.exists(file.path(
      fixture_dir,
      c("fixture.yml", "input.csv", "mapping.csv")
    ))))
    metadata <- parse_simple_metadata(file.path(fixture_dir, "fixture.yml"))
    stopifnot(identical(metadata$synthetic_test_fixture, "true"))
    stopifnot(identical(metadata$scientific_claims, "none"))
    stopifnot(identical(metadata$fixture_id, fixture_id))
  }
  manifest
}

first_dir <- tempfile("figureforge-stress-first-")
second_dir <- tempfile("figureforge-stress-second-")
generate_stress_fixtures(first_dir, public_cases_dir)
generate_stress_fixtures(second_dir, public_cases_dir)
first_manifest <- validate_fixture_root(first_dir)
second_manifest <- validate_fixture_root(second_dir)
stopifnot(identical(first_manifest, second_manifest))

relative_hashes <- function(root) {
  paths <- sort(list.files(root, recursive = TRUE, full.names = TRUE))
  relative <- substring(paths, nchar(root) + 2L)
  hashes <- unname(tools::md5sum(paths))
  stats::setNames(hashes, relative)
}
stopifnot(identical(
  relative_hashes(first_dir),
  relative_hashes(second_dir)
))

nonempty_dir <- tempfile("figureforge-stress-nonempty-")
dir.create(nonempty_dir, recursive = TRUE)
writeLines("preserve", file.path(nonempty_dir, "existing.txt"))
nonempty_error <- tryCatch(
  {
    generate_stress_fixtures(nonempty_dir, public_cases_dir)
    NULL
  },
  error = identity
)
stopifnot(inherits(nonempty_error, "error"))
stopifnot(file.exists(file.path(nonempty_dir, "existing.txt")))

tracked_manifest <- validate_fixture_root(tracked_dir)
stopifnot(identical(first_manifest, tracked_manifest))
stopifnot(identical(
  relative_hashes(first_dir),
  relative_hashes(tracked_dir)
))

generator_cli <- file.path(
  repo_root,
  "skills",
  "figureforge",
  "scripts",
  "generate_stress_fixtures.R"
)
cli_dir <- tempfile("figureforge-stress-cli-")
cli_log <- tempfile("figureforge-stress-cli-", fileext = ".log")
cli_status <- system2(
  "/usr/local/bin/Rscript",
  shQuote(c(generator_cli, "--output", cli_dir)),
  stdout = cli_log,
  stderr = cli_log
)
stopifnot(identical(as.integer(cli_status), 0L))
stopifnot(identical(
  relative_hashes(first_dir),
  relative_hashes(cli_dir)
))

source_paths <- sort(c(
  list.files(
    public_cases_dir,
    recursive = TRUE,
    full.names = TRUE
  ),
  list.files(
    tracked_dir,
    recursive = TRUE,
    full.names = TRUE
  )
))
source_hashes_before <- tools::md5sum(source_paths)
source_mtimes_before <- file.info(source_paths)$mtime

run_output_dir <- tempfile("figureforge-stress-run-")
results <- run_stress_suite(
  tracked_dir,
  public_cases_dir,
  run_output_dir,
  rscript = "/usr/local/bin/Rscript"
)
stopifnot(nrow(results) == 24L)
stopifnot(all(results$observed_outcome == results$expected_outcome))
stopifnot(all(results$passed))
stopifnot(all(results$synthetic_test_fixture))
success_rows <- results$observed_outcome == "success"
stopifnot(all(file.exists(results$output_path[success_rows])))
stopifnot(all(file.info(results$output_path[success_rows])$size > 0L))
failure_rows <- results$observed_outcome == "failure"
stopifnot(all(nzchar(results$failure_category[failure_rows])))
stopifnot(all(!file.exists(results$output_path[failure_rows])))
stopifnot(identical(
  source_hashes_before,
  tools::md5sum(source_paths)
))
stopifnot(identical(
  source_mtimes_before,
  file.info(source_paths)$mtime
))

runner_cli <- file.path(
  repo_root,
  "skills",
  "figureforge",
  "scripts",
  "run_stress_tests.R"
)
cli_output_dir <- tempfile("figureforge-stress-run-cli-")
cli_report <- tempfile("figureforge-stress-run-cli-", fileext = ".csv")
runner_log <- tempfile("figureforge-stress-run-cli-", fileext = ".log")
runner_status <- system2(
  "/usr/local/bin/Rscript",
  shQuote(c(
    runner_cli,
    "--fixtures", tracked_dir,
    "--public-cases", public_cases_dir,
    "--output-dir", cli_output_dir,
    "--report", cli_report
  )),
  stdout = runner_log,
  stderr = runner_log
)
stopifnot(identical(as.integer(runner_status), 0L))
cli_results <- read.csv(
  cli_report,
  stringsAsFactors = FALSE,
  check.names = FALSE
)
stopifnot(nrow(cli_results) == 24L)
stopifnot(all(cli_results$passed))

message("stress fixture tests: PASS")
