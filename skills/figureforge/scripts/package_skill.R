#!/usr/bin/env Rscript

command_args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", command_args, value = TRUE)
script_path <- if (length(file_arg) > 0L) {
  normalizePath(sub("^--file=", "", file_arg[[1L]]), mustWork = TRUE)
} else {
  normalizePath("skills/figureforge/scripts/package_skill.R", mustWork = TRUE)
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
  "release_packaging.R"
))

parse_package_cli <- function(args) {
  result <- list(archive = NULL, manifest = NULL)
  index <- 1L
  while (index <= length(args)) {
    argument <- args[[index]]
    if (!argument %in% c("--archive", "--manifest") ||
        index == length(args)) {
      stop("Usage: package_skill.R --archive PATH [--manifest PATH]")
    }
    result[[sub("^--", "", argument)]] <- args[[index + 1L]]
    index <- index + 2L
  }
  if (is.null(result$archive)) {
    stop("Usage: package_skill.R --archive PATH [--manifest PATH]")
  }
  result
}

options <- parse_package_cli(commandArgs(trailingOnly = TRUE))
result <- package_figureforge_skill(
  repo_root,
  options$archive,
  manifest_path = options$manifest
)
message("Release archive files: ", nrow(result$manifest))
message("Wrote release archive: ", result$archive_path)
message("Wrote release checksum: ", result$checksum_path)
