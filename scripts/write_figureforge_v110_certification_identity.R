#!/usr/bin/env Rscript

command_args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", command_args, value = TRUE)
script_path <- if (length(file_arg) > 0L) {
  normalizePath(sub("^--file=", "", file_arg[[1L]]), mustWork = TRUE)
} else {
  normalizePath(
    "scripts/write_figureforge_v110_certification_identity.R",
    mustWork = TRUE
  )
}
repo_root <- normalizePath(file.path(dirname(script_path), ".."), mustWork = TRUE)

for (library_path in c(
  "skills/figureforge/lib/distribution_validation.R",
  "skills/figureforge/lib/checksums.R",
  "skills/figureforge/lib/release_packaging.R",
  "scripts/lib/release_certification.R"
)) {
  source(file.path(repo_root, library_path))
}

parse_cli <- function(args) {
  result <- list(
    manifest = NULL,
    archive = NULL,
    live_trigger_summary = NULL,
    live_plotting_summary = NULL,
    live_mode_summary = NULL,
    output = NULL,
    certified_at = NULL
  )
  allowed <- c(
    "--manifest",
    "--archive",
    "--live-trigger-summary",
    "--live-plotting-summary",
    "--live-mode-summary",
    "--output",
    "--certified-at"
  )
  index <- 1L
  while (index <= length(args)) {
    argument <- args[[index]]
    if (!argument %in% allowed || index == length(args)) {
      stop(
        "Usage: write_figureforge_v110_certification_identity.R ",
        "--manifest PATH --archive PATH ",
        "--live-trigger-summary PATH --live-plotting-summary PATH ",
        "--live-mode-summary PATH --output PATH ",
        "[--certified-at TIMESTAMP]"
      )
    }
    key <- gsub("-", "_", sub("^--", "", argument), fixed = TRUE)
    result[[key]] <- args[[index + 1L]]
    index <- index + 2L
  }
  if (any(vapply(
    result[c(
      "manifest",
      "archive",
      "live_trigger_summary",
      "live_plotting_summary",
      "live_mode_summary",
      "output"
    )],
    is.null,
    logical(1)
  ))) {
    stop(
      "Usage: write_figureforge_v110_certification_identity.R ",
      "--manifest PATH --archive PATH ",
      "--live-trigger-summary PATH --live-plotting-summary PATH ",
      "--live-mode-summary PATH --output PATH ",
      "[--certified-at TIMESTAMP]"
    )
  }
  result
}

tryCatch(
  {
    options <- parse_cli(commandArgs(trailingOnly = TRUE))
    certified_at <- if (is.null(options$certified_at)) {
      format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z")
    } else {
      options$certified_at
    }
    identity <- build_figureforge_certification_identity(
      repo_root,
      options$manifest,
      options$archive,
      options$live_trigger_summary,
      options$live_plotting_summary,
      options$live_mode_summary,
      certified_at = certified_at
    )
    output <- write_figureforge_certification_identity(
      identity,
      options$output
    )
    message("Wrote certification identity: ", output)
  },
  error = function(error) {
    message(conditionMessage(error))
    quit(status = 1L)
  }
)
