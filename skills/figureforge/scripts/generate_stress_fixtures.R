#!/usr/bin/env Rscript

command_args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", command_args, value = TRUE)
script_path <- if (length(file_arg) > 0L) {
  normalizePath(sub("^--file=", "", file_arg[[1L]]), mustWork = TRUE)
} else {
  normalizePath(
    "skills/figureforge/scripts/generate_stress_fixtures.R",
    mustWork = TRUE
  )
}
repo_root <- normalizePath(
  file.path(dirname(script_path), "..", "..", ".."),
  mustWork = TRUE
)
source(file.path(
  repo_root,
  "skills",
  "figureforge",
  "lib",
  "stress_fixtures.R"
))

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2L || args[[1L]] != "--output") {
  stop("Usage: generate_stress_fixtures.R --output PATH")
}
output_dir <- args[[2L]]
public_cases_dir <- file.path(
  repo_root,
  "skills",
  "figureforge",
  "public-cases"
)
specs <- generate_stress_fixtures(output_dir, public_cases_dir)
message(
  "Generated ",
  nrow(specs),
  " synthetic stress fixtures: ",
  normalizePath(output_dir, mustWork = TRUE)
)
