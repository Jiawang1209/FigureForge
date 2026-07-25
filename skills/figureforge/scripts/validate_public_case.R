#!/usr/bin/env Rscript

command_args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", command_args, value = TRUE)
script_path <- if (length(file_arg) > 0L) {
  normalizePath(sub("^--file=", "", file_arg[[1L]]), mustWork = TRUE)
} else {
  normalizePath(
    "skills/figureforge/scripts/validate_public_case.R",
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
  "runtime_resolution.R"
))
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
  "distribution_validation.R"
))
source(file.path(
  repo_root,
  "skills",
  "figureforge",
  "lib",
  "metadata.R"
))

usage <- function() {
  paste(
    "Usage: validate_public_case.R <case_dir>",
    "[--render --output PATH]",
    "[--rscript PATH]"
  )
}

parse_cli <- function(args) {
  if (length(args) < 1L) stop(usage())
  result <- list(
    case_dir = args[[1L]],
    render = FALSE,
    output = NULL,
    rscript = NULL
  )
  index <- 2L
  while (index <= length(args)) {
    argument <- args[[index]]
    if (argument == "--render") {
      result$render <- TRUE
      index <- index + 1L
      next
    }
    if (argument %in% c("--output", "--rscript") && index < length(args)) {
      value <- args[[index + 1L]]
      if (argument == "--output") result$output <- value
      if (argument == "--rscript") result$rscript <- value
      index <- index + 2L
      next
    }
    stop("Unknown or incomplete argument: ", argument, "\n", usage())
  }
  if (result$render && is.null(result$output)) {
    stop("--output is required with --render")
  }
  result
}

canonical_output_path <- function(path) {
  parent <- dirname(path)
  if (!dir.exists(parent)) {
    dir.create(parent, recursive = TRUE, showWarnings = FALSE)
  }
  file.path(
    normalizePath(parent, mustWork = TRUE),
    basename(path)
  )
}

path_is_same_or_within <- function(path, root) {
  identical(path, root) ||
    startsWith(path, paste0(root, .Platform$file.sep))
}

tryCatch(
  {
    options <- parse_cli(commandArgs(trailingOnly = TRUE))
    case_dir <- normalizePath(options$case_dir, mustWork = TRUE)
    metadata <- read_case_metadata(case_dir)
    metadata_result <- validate_case_metadata(metadata)
    distribution_result <- validate_distribution(case_dir)
    structure_result <- validate_case_structure(case_dir)
    checks <- c(
      "public metadata" = metadata_result$ok,
      "distribution" = distribution_result$ok,
      "case structure" = structure_result$ok
    )

    if (options$render) {
      runtime <- resolve_rscript(cli_path = options$rscript)
      output_path <- canonical_output_path(options$output)
      if (path_is_same_or_within(output_path, case_dir)) {
        stop("Render output must be outside the source case directory")
      }
      log_path <- tempfile("figureforge-public-render-", fileext = ".log")
      render_status <- system2(
        runtime$path,
        shQuote(c(
          file.path(case_dir, "plot.R"),
          file.path(case_dir, "data.csv"),
          output_path
        )),
        stdout = log_path,
        stderr = log_path
      )
      render_ok <- identical(as.integer(render_status), 0L) &&
        is_nonempty_file(output_path)
      checks <- c(checks, "fresh external render" = render_ok)
      if (!render_ok) {
        render_log <- paste(
          readLines(log_path, warn = FALSE),
          collapse = "\n"
        )
        message(render_log)
      }
    }

    for (check_name in names(checks)) {
      message(check_name, ": ", if (checks[[check_name]]) "PASS" else "FAIL")
    }
    if (!all(checks)) {
      stop(
        "Public case validation failed: ",
        paste(names(checks)[!checks], collapse = ", ")
      )
    }
    message("Public case validation OK: ", metadata$case_id)
  },
  error = function(error) {
    message(conditionMessage(error))
    quit(status = 1L)
  }
)
