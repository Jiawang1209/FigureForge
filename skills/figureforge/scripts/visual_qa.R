#!/usr/bin/env Rscript

command_args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", command_args, value = TRUE)
script_path <- if (length(file_arg) > 0L) {
  normalizePath(sub("^--file=", "", file_arg[[1L]]), mustWork = TRUE)
} else {
  normalizePath("skills/figureforge/scripts/visual_qa.R", mustWork = TRUE)
}
repo_root <- normalizePath(
  file.path(dirname(script_path), "..", "..", ".."),
  mustWork = TRUE
)
source(file.path(repo_root, "skills", "figureforge", "lib", "visual_qa.R"))

parse_cli <- function(args) {
  result <- list(render = NULL, reference = NULL, report = NULL)
  index <- 1L
  while (index <= length(args)) {
    argument <- args[[index]]
    if (!argument %in% c("--render", "--reference", "--report") ||
        index == length(args)) {
      stop("Unknown or incomplete argument: ", argument)
    }
    result[[sub("^--", "", argument)]] <- args[[index + 1L]]
    index <- index + 2L
  }
  if (is.null(result$render) || is.null(result$report)) {
    stop("Required: --render --report")
  }
  result
}

tryCatch(
  {
    options <- parse_cli(commandArgs(trailingOnly = TRUE))
    report_parent <- dirname(options$report)
    dir.create(report_parent, recursive = TRUE, showWarnings = FALSE)
    report_path <- file.path(
      normalizePath(report_parent, mustWork = TRUE),
      basename(options$report)
    )
    public_cases <- normalizePath(
      file.path(repo_root, "skills", "figureforge", "public-cases"),
      mustWork = TRUE
    )
    if (identical(report_path, public_cases) ||
        startsWith(report_path, paste0(public_cases, .Platform$file.sep))) {
      stop("Visual QA report must be outside public case directories")
    }
    report <- inspect_visual_output(
      options$render,
      reference_path = options$reference
    )
    write_visual_qa_report(report, report_path)
    message("Visual QA status: ", report$status)
    message("Wrote visual QA report: ", report_path)
    if (identical(report$status, "tool_check_failed")) quit(status = 1L)
  },
  error = function(error) {
    message(conditionMessage(error))
    quit(status = 1L)
  }
)
