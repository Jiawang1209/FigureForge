#!/usr/bin/env Rscript

command_args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", command_args, value = TRUE)
script_path <- if (length(file_arg) > 0L) {
  normalizePath(sub("^--file=", "", file_arg[[1L]]), mustWork = TRUE)
} else {
  normalizePath(
    "skills/figureforge/scripts/verify_release.R",
    mustWork = TRUE
  )
}
repo_root <- normalizePath(
  file.path(dirname(script_path), "..", "..", ".."),
  mustWork = TRUE
)
for (library_file in c(
  "distribution_validation.R",
  "checksums.R",
  "release_packaging.R"
)) {
  source(file.path(
    repo_root,
    "skills",
    "figureforge",
    "lib",
    library_file
  ))
}

parse_cli <- function(args) {
  result <- list(
    archive = NULL,
    manifest = NULL,
    extract_dir = NULL
  )
  allowed <- c("--archive", "--manifest", "--extract-dir")
  index <- 1L
  while (index <= length(args)) {
    argument <- args[[index]]
    if (!argument %in% allowed || index == length(args)) {
      stop(
        "Usage: verify_release.R --archive PATH --manifest PATH ",
        "[--extract-dir PATH]"
      )
    }
    key <- gsub("-", "_", sub("^--", "", argument), fixed = TRUE)
    result[[key]] <- args[[index + 1L]]
    index <- index + 2L
  }
  if (is.null(result$archive) || is.null(result$manifest)) {
    stop(
      "Usage: verify_release.R --archive PATH --manifest PATH ",
      "[--extract-dir PATH]"
    )
  }
  result
}

tryCatch(
  {
    options <- parse_cli(commandArgs(trailingOnly = TRUE))
    result <- verify_figureforge_release(
      options$archive,
      options$manifest,
      extract_dir = options$extract_dir
    )
    message(
      "Release verification OK: ",
      nrow(result$manifest),
      " files; archive=",
      result$archive_path
    )
  },
  error = function(error) {
    message(conditionMessage(error))
    quit(status = 1L)
  }
)
