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
source(file.path(repo_root, "skills", "figureforge", "lib", "distribution_validation.R"))
source(file.path(repo_root, "skills", "figureforge", "lib", "metadata.R"))
source(file.path(repo_root, "skills", "figureforge", "lib", "schema_matching.R"))

usage <- function() {
  paste(
    "Usage: search_cases.R --query TEXT",
    "[--cases-dir PATH]",
    "[--limit N]",
    "[--completed-only]",
    "[--public]",
    "[--schema INPUT.csv]",
    "[--explain-scores]",
    "[--output PATH]"
  )
}

parse_cli <- function(args) {
  result <- list(
    query = NULL,
    cases_dir = file.path(repo_root, "skills", "figureforge", "cases"),
    limit = 10L,
    completed_only = FALSE,
    public = FALSE,
    schema = NULL,
    explain_scores = FALSE,
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
    if (argument == "--public") {
      result$public <- TRUE
      index <- index + 1L
      next
    }
    if (argument == "--explain-scores") {
      result$explain_scores <- TRUE
      index <- index + 1L
      next
    }
    if (argument %in% c(
      "--query",
      "--cases-dir",
      "--limit",
      "--schema",
      "--output"
    )) {
      if (index == length(args)) {
        stop("Missing value for ", argument, "\n", usage())
      }
      value <- args[[index + 1L]]
      if (argument == "--query") result$query <- value
      if (argument == "--cases-dir") result$cases_dir <- value
      if (argument == "--limit") result$limit <- as.integer(value)
      if (argument == "--schema") result$schema <- value
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
    if (options$public) {
      default_private <- file.path(
        repo_root,
        "skills",
        "figureforge",
        "cases"
      )
      public_cases <- if (identical(options$cases_dir, default_private)) {
        file.path(repo_root, "skills", "figureforge", "public-cases")
      } else {
        options$cases_dir
      }
      catalog <- build_public_catalog(public_cases)
      profile <- if (is.null(options$schema)) {
        NULL
      } else {
        profile_data_frame(read.csv(
          options$schema,
          stringsAsFactors = FALSE,
          check.names = FALSE
        ))
      }
      results <- rank_public_cases(
        catalog,
        options$query,
        profile = profile,
        limit = options$limit
      )
      score_columns <- c(
        "score_id",
        "score_alias",
        "score_family",
        "score_schema",
        "score_intent",
        "score_layout",
        "score_readiness",
        "score_total"
      )
      display_columns <- c(
        "case_id",
        "title_en",
        "title_zh",
        "chart_family",
        "chart_subfamily",
        "required_roles",
        "qa_status",
        "distribution_status",
        "case_path",
        if (options$explain_scores) score_columns else "score_total"
      )
    } else {
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
    }
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
