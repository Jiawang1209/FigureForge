#!/usr/bin/env Rscript

command_args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", command_args, value = TRUE)
script_path <- if (length(file_arg) > 0) {
  normalizePath(sub("^--file=", "", file_arg[[1]]), mustWork = TRUE)
} else {
  normalizePath(
    "skills/figureforge/scripts/audit_cases.R",
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
  "case_audit.R"
))
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
  "blocker_validation.R"
))

usage <- function() {
  paste(
    "Usage: audit_cases.R",
    "--cases-dir PATH",
    "--output-dir PATH",
    "[--rscript PATH]",
    "[--render]"
  )
}

parse_cli <- function(args) {
  result <- list(
    cases_dir = NULL,
    output_dir = NULL,
    rscript = "/usr/local/bin/Rscript",
    render = FALSE
  )
  index <- 1L
  while (index <= length(args)) {
    argument <- args[[index]]
    if (argument == "--render") {
      result$render <- TRUE
      index <- index + 1L
      next
    }
    if (argument %in% c("--cases-dir", "--output-dir", "--rscript")) {
      if (index == length(args)) {
        stop("Missing value for ", argument, "\n", usage())
      }
      value <- args[[index + 1L]]
      if (argument == "--cases-dir") result$cases_dir <- value
      if (argument == "--output-dir") result$output_dir <- value
      if (argument == "--rscript") result$rscript <- value
      index <- index + 2L
      next
    }
    stop("Unknown argument: ", argument, "\n", usage())
  }

  if (is.null(result$cases_dir) || is.null(result$output_dir)) {
    stop("--cases-dir and --output-dir are required\n", usage())
  }
  result
}

tryCatch(
  {
    options <- parse_cli(commandArgs(trailingOnly = TRUE))
    render_dir <- if (options$render) {
      file.path(options$output_dir, "rendered")
    } else {
      NULL
    }
    results <- audit_cases(
      options$cases_dir,
      render_dir = render_dir,
      rscript = options$rscript
    )
    write_audit_reports(results, options$output_dir)
    message(
      "Audited ",
      nrow(results),
      " case(s): ",
      normalizePath(options$output_dir, mustWork = TRUE)
    )
  },
  error = function(error) {
    message(conditionMessage(error))
    quit(status = 1L)
  }
)
