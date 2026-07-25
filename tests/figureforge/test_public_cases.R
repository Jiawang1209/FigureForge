#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
script_path <- if (length(file_arg) > 0L) {
  normalizePath(sub("^--file=", "", file_arg[[1L]]), mustWork = TRUE)
} else {
  normalizePath(
    "tests/figureforge/test_public_cases.R",
    mustWork = TRUE
  )
}
repo_root <- normalizePath(
  file.path(dirname(script_path), "..", ".."),
  mustWork = TRUE
)

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
  "checksums.R"
))
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
first_wave <- c(
  "public-bar-grouped",
  "public-distribution-raincloud",
  "public-scatter-fit",
  "public-timeseries-band",
  "public-correlation-heatmap",
  "public-enrichment-bubble"
)
second_wave <- c(
  "public-volcano",
  "public-network",
  "public-survival",
  "public-phylogeny-annotation",
  "public-gene-structure",
  "public-multipanel"
)
expected_cases <- c(first_wave, second_wave)
expected_cases <- c(
  expected_cases,
  "authentic-palmer-penguins-scatter",
  "authentic-usgs-earthquakes-bubble",
  "authentic-world-bank-population-timeseries"
)

stopifnot(dir.exists(public_cases_dir))
stopifnot(all(dir.exists(file.path(public_cases_dir, expected_cases))))
stopifnot(setequal(
  basename(list.dirs(public_cases_dir, recursive = FALSE)),
  expected_cases
))

validator_cli <- file.path(
  repo_root,
  "skills",
  "figureforge",
  "scripts",
  "validate_public_case.R"
)
stopifnot(file.exists(validator_cli))

for (case_id in expected_cases) {
  case_dir <- file.path(public_cases_dir, case_id)
  source_files <- sort(list.files(
    case_dir,
    recursive = TRUE,
    full.names = TRUE
  ))
  hashes_before <- tools::md5sum(source_files)
  mtimes_before <- file.info(source_files)$mtime

  metadata <- read_case_metadata(case_dir)
  metadata_result <- validate_case_metadata(metadata)
  stopifnot(isTRUE(metadata_result$ok))
  stopifnot(identical(metadata$case_id, case_id))
  if (isTRUE(metadata$synthetic_test_fixture)) {
    stopifnot(identical(metadata$qa_status, "review_required"))
  } else {
    stopifnot(identical(metadata$qa_status, "verified"))
  }

  distribution_result <- validate_distribution(case_dir)
  stopifnot(isTRUE(distribution_result$ok))

  structure_result <- validate_case_structure(case_dir)
  stopifnot(isTRUE(structure_result$ok))

  data_path <- file.path(case_dir, "data.csv")
  plot_path <- file.path(case_dir, "plot.R")
  stopifnot(file.info(data_path)$size > 0L)
  plot_lines <- readLines(plot_path, warn = FALSE)
  stopifnot(any(grepl(
    "commandArgs\\s*\\(\\s*trailingOnly\\s*=\\s*TRUE\\s*\\)",
    plot_lines,
    perl = TRUE
  )))
  stopifnot(any(grepl("\\binput_path\\b", plot_lines, perl = TRUE)))
  stopifnot(any(grepl("\\boutput_path\\b", plot_lines, perl = TRUE)))

  render_dir <- tempfile(paste0("figureforge-public-", case_id, "-"))
  dir.create(render_dir, recursive = TRUE)
  render_path <- file.path(render_dir, "output.pdf")
  render_log <- file.path(render_dir, "render.log")
  render_status <- system2(
    "/usr/local/bin/Rscript",
    shQuote(c(plot_path, data_path, render_path)),
    stdout = render_log,
    stderr = render_log
  )
  stopifnot(identical(as.integer(render_status), 0L))
  stopifnot(file.exists(render_path))
  stopifnot(file.info(render_path)$size > 0L)

  cli_render_path <- file.path(render_dir, "validated.pdf")
  cli_log <- file.path(render_dir, "validator.log")
  cli_status <- system2(
    "/usr/local/bin/Rscript",
    shQuote(c(
      validator_cli,
      case_dir,
      "--render",
      "--output",
      cli_render_path
    )),
    stdout = cli_log,
    stderr = cli_log
  )
  stopifnot(identical(as.integer(cli_status), 0L))
  stopifnot(file.exists(cli_render_path))
  stopifnot(file.info(cli_render_path)$size > 0L)

  hashes_after <- tools::md5sum(source_files)
  mtimes_after <- file.info(source_files)$mtime
  stopifnot(identical(hashes_before, hashes_after))
  stopifnot(identical(mtimes_before, mtimes_after))

  inside_log <- file.path(render_dir, "inside.log")
  inside_status <- system2(
    "/usr/local/bin/Rscript",
    shQuote(c(
      validator_cli,
      case_dir,
      "--render",
      "--output",
      file.path(case_dir, "forbidden.pdf")
    )),
    stdout = inside_log,
    stderr = inside_log
  )
  stopifnot(!identical(as.integer(inside_status), 0L))
  stopifnot(!file.exists(file.path(case_dir, "forbidden.pdf")))
}

message("public case tests: PASS")
