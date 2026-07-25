#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
script_path <- if (length(file_arg) > 0L) {
  normalizePath(sub("^--file=", "", file_arg[[1L]]), mustWork = TRUE)
} else {
  normalizePath(
    "tests/figureforge/test_authentic_public_cases.R",
    mustWork = TRUE
  )
}
repo_root <- normalizePath(
  file.path(dirname(script_path), "..", ".."),
  mustWork = TRUE
)
for (library_file in c(
  "checksums.R",
  "distribution_validation.R",
  "metadata.R",
  "case_audit.R",
  "case_validation.R"
)) {
  source(file.path(
    repo_root,
    "skills",
    "figureforge",
    "lib",
    library_file
  ))
}

case_ids <- c(
  "authentic-palmer-penguins-scatter",
  "authentic-usgs-earthquakes-bubble",
  "authentic-world-bank-population-timeseries"
)
public_root <- file.path(
  repo_root,
  "skills",
  "figureforge",
  "public-cases"
)
output_root <- tempfile("figureforge-authentic-renders-")
dir.create(output_root, recursive = TRUE)
required_files <- c(
  "case.md",
  "case.yml",
  "data.csv",
  "distribution.yml",
  "plot.R",
  "qa.md",
  "source.yml"
)

for (case_id in case_ids) {
  case_dir <- file.path(public_root, case_id)
  stopifnot(dir.exists(case_dir))
  stopifnot(all(file.exists(file.path(case_dir, required_files))))

  metadata <- read_case_metadata(case_dir)
  stopifnot(identical(metadata$case_id, case_id))
  stopifnot(!metadata$synthetic_test_fixture)
  stopifnot(identical(metadata$qa_status, "verified"))
  stopifnot(validate_case_metadata(metadata)$ok)

  distribution <- validate_distribution(case_dir)
  stopifnot(distribution$ok)
  stopifnot(identical(
    distribution$source_type,
    "authentic_open_data"
  ))
  stopifnot(identical(distribution$qa_status, "verified"))
  stopifnot(validate_case_structure(case_dir)$ok)

  source_metadata <- parse_simple_metadata(file.path(case_dir, "source.yml"))
  stopifnot(identical(
    figureforge_sha256(file.path(case_dir, "data.csv")),
    source_metadata$normalized_sha256
  ))

  output_path <- file.path(output_root, paste0(case_id, ".pdf"))
  render_status <- system2(
    "/usr/local/bin/Rscript",
    shQuote(c(
      file.path(case_dir, "plot.R"),
      file.path(case_dir, "data.csv"),
      output_path
    ))
  )
  stopifnot(identical(as.integer(render_status), 0L))
  stopifnot(file.info(output_path)$size > 0L)
}

message("authentic public case tests: PASS")
