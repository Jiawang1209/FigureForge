#!/usr/bin/env Rscript

command_args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", command_args, value = TRUE)
script_path <- if (length(file_arg) > 0) {
  normalizePath(sub("^--file=", "", file_arg[[1]]), mustWork = TRUE)
} else {
  normalizePath(
    "skills/figureforge/scripts/index_cases.R",
    mustWork = TRUE
  )
}
repo_root <- normalizePath(
  file.path(dirname(script_path), "..", "..", ".."),
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
  "case_catalog.R"
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

args <- commandArgs(trailingOnly = TRUE)
usage <- function() {
  paste(
    "Usage: index_cases.R [cases_dir] [output_csv]",
    "or index_cases.R --public-cases PATH --output PATH"
  )
}

parse_public_cli <- function(args) {
  result <- list(public_cases = NULL, output = NULL)
  index <- 1L
  while (index <= length(args)) {
    argument <- args[[index]]
    if (!argument %in% c("--public-cases", "--output") ||
        index == length(args)) {
      stop("Unknown or incomplete argument: ", argument, "\n", usage())
    }
    value <- args[[index + 1L]]
    if (argument == "--public-cases") result$public_cases <- value
    if (argument == "--output") result$output <- value
    index <- index + 2L
  }
  if (is.null(result$public_cases) || is.null(result$output)) {
    stop("--public-cases and --output are required together\n", usage())
  }
  result
}

if (length(args) > 0L && startsWith(args[[1L]], "--")) {
  options <- parse_public_cli(args)
  index <- build_public_catalog(options$public_cases)
  index$case_path <- NULL
  output_path <- options$output
} else {
  cases_dir <- if (length(args) >= 1L) {
    args[[1L]]
  } else {
    file.path(repo_root, "skills", "figureforge", "cases")
  }
  output_path <- if (length(args) >= 2L) {
    args[[2L]]
  } else {
    file.path(
      repo_root,
      "skills",
      "figureforge",
      "references",
      "case-index.csv"
    )
  }
  index <- build_case_catalog(cases_dir)
}

dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
write.csv(index, output_path, row.names = FALSE, fileEncoding = "UTF-8")
message(
  "Wrote ",
  nrow(index),
  " case(s) to index: ",
  normalizePath(output_path, mustWork = TRUE)
)
