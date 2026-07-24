#!/usr/bin/env Rscript

command_args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", command_args, value = TRUE)
script_path <- if (length(file_arg) > 0) {
  normalizePath(sub("^--file=", "", file_arg[[1]]), mustWork = TRUE)
} else {
  normalizePath(
    "skills/figureforge/scripts/plan_case_batches.R",
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
  "batch_planning.R"
))

usage <- function() {
  paste(
    "Usage: plan_case_batches.R",
    "--readiness PATH",
    "--output PATH",
    "[--batch-size 20]"
  )
}

parse_cli <- function(args) {
  result <- list(readiness = NULL, output = NULL, batch_size = 20L)
  index <- 1L
  while (index <= length(args)) {
    argument <- args[[index]]
    if (argument %in% c("--readiness", "--output", "--batch-size")) {
      if (index == length(args)) {
        stop("Missing value for ", argument, "\n", usage())
      }
      value <- args[[index + 1L]]
      if (argument == "--readiness") result$readiness <- value
      if (argument == "--output") result$output <- value
      if (argument == "--batch-size") {
        result$batch_size <- as.integer(value)
      }
      index <- index + 2L
      next
    }
    stop("Unknown argument: ", argument, "\n", usage())
  }
  if (is.null(result$readiness) || is.null(result$output)) {
    stop("--readiness and --output are required\n", usage())
  }
  result
}

tryCatch(
  {
    options <- parse_cli(commandArgs(trailingOnly = TRUE))
    if (!file.exists(options$readiness)) {
      stop("Readiness file not found: ", options$readiness)
    }
    readiness <- read.csv(
      options$readiness,
      stringsAsFactors = FALSE,
      check.names = FALSE
    )
    plan <- plan_case_batches(
      readiness,
      batch_size = options$batch_size
    )
    dir.create(
      dirname(options$output),
      recursive = TRUE,
      showWarnings = FALSE
    )
    write.csv(
      plan,
      options$output,
      row.names = FALSE,
      fileEncoding = "UTF-8"
    )
    message(
      "Planned ",
      nrow(plan),
      " pending case(s) across ",
      if (nrow(plan) == 0L) 0L else max(plan$wave),
      " wave(s): ",
      normalizePath(options$output, mustWork = TRUE)
    )
  },
  error = function(error) {
    message(conditionMessage(error))
    quit(status = 1L)
  }
)
