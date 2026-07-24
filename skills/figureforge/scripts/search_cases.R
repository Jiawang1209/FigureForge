#!/usr/bin/env Rscript

command_args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", command_args, value = TRUE)
script_path <- if (length(file_arg) > 0) {
  normalizePath(sub("^--file=", "", file_arg[[1]]), mustWork = TRUE)
} else {
  normalizePath(
    "skills/figureforge/scripts/search_cases.R",
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

usage <- function() {
  paste(
    "Usage: search_cases.R --query TEXT",
    "[--cases-dir PATH]",
    "[--limit N]",
    "[--completed-only]",
    "[--output PATH]"
  )
}

parse_cli <- function(args) {
  result <- list(
    query = NULL,
    cases_dir = file.path(repo_root, "skills", "figureforge", "cases"),
    limit = 10L,
    completed_only = FALSE,
    output = NULL
  )
  index <- 1L
  while (index <= length(args)) {
    argument <- args[[index]]
    if (argument == "--completed-only") {
      result$completed_only <- TRUE
      index <- index + 1L
      next
    }
    if (argument %in% c("--query", "--cases-dir", "--limit", "--output")) {
      if (index == length(args)) {
        stop("Missing value for ", argument, "\n", usage())
      }
      value <- args[[index + 1L]]
      if (argument == "--query") result$query <- value
      if (argument == "--cases-dir") result$cases_dir <- value
      if (argument == "--limit") result$limit <- as.integer(value)
      if (argument == "--output") result$output <- value
      index <- index + 2L
      next
    }
    stop("Unknown argument: ", argument, "\n", usage())
  }
  if (is.null(result$query) || !nzchar(trimws(result$query))) {
    stop("--query is required\n", usage())
  }
  if (is.na(result$limit) || result$limit < 1L) {
    stop("--limit must be a positive integer")
  }
  result
}

tryCatch(
  {
    options <- parse_cli(commandArgs(trailingOnly = TRUE))
    catalog <- build_case_catalog(options$cases_dir)
    results <- search_case_catalog(
      catalog,
      options$query,
      limit = options$limit,
      completed_only = options$completed_only
    )
    display_columns <- c(
      "score",
      "case_id",
      "title",
      "chart_type",
      "chart_type_zh",
      "required_columns",
      "completion_status",
      "distribution_status",
      "case_path"
    )
    display <- results[, display_columns, drop = FALSE]
    if (!is.null(options$output)) {
      dir.create(
        dirname(options$output),
        recursive = TRUE,
        showWarnings = FALSE
      )
      write.csv(
        display,
        options$output,
        row.names = FALSE,
        fileEncoding = "UTF-8"
      )
      message("Wrote search results: ", options$output)
    } else if (nrow(display) == 0) {
      message("No matching cases.")
    } else {
      write.table(
        display,
        row.names = FALSE,
        sep = "\t",
        quote = FALSE,
        file = stdout()
      )
    }
  },
  error = function(error) {
    message(conditionMessage(error))
    quit(status = 1L)
  }
)
