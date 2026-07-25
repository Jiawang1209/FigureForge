#!/usr/bin/env Rscript

command_args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", command_args, value = TRUE)
script_path <- if (length(file_arg) > 0L) {
  normalizePath(sub("^--file=", "", file_arg[[1L]]), mustWork = TRUE)
} else {
  normalizePath(
    "skills/figureforge/scripts/create_adaptation.R",
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
  "distribution_validation.R"
))
source(file.path(
  repo_root,
  "skills",
  "figureforge",
  "lib",
  "metadata.R"
))
source(file.path(
  repo_root,
  "skills",
  "figureforge",
  "lib",
  "workspace_generation.R"
))

parse_cli <- function(args) {
  result <- list(
    case = NULL,
    input = NULL,
    workspace = NULL,
    mapping = NULL,
    force_empty = FALSE
  )
  index <- 1L
  while (index <= length(args)) {
    argument <- args[[index]]
    if (argument == "--force-empty") {
      result$force_empty <- TRUE
      index <- index + 1L
      next
    }
    if (argument %in% c("--case", "--input", "--workspace", "--mapping") &&
        index < length(args)) {
      key <- sub("^--", "", argument)
      result[[key]] <- args[[index + 1L]]
      index <- index + 2L
      next
    }
    stop("Unknown or incomplete argument: ", argument)
  }
  if (any(vapply(
    result[c("case", "input", "workspace")],
    is.null,
    logical(1)
  ))) {
    stop("Required: --case --input --workspace")
  }
  result
}

tryCatch(
  {
    options <- parse_cli(commandArgs(trailingOnly = TRUE))
    public_cases <- file.path(
      repo_root,
      "skills",
      "figureforge",
      "public-cases"
    )
    private_cases <- file.path(
      repo_root,
      "skills",
      "figureforge",
      "cases"
    )
    case_dir <- if (dir.exists(options$case)) {
      options$case
    } else {
      file.path(public_cases, options$case)
    }
    result <- create_adaptation_workspace(
      case_dir,
      options$input,
      options$workspace,
      mapping_path = options$mapping,
      force_empty = options$force_empty,
      protected_roots = c(public_cases, private_cases)
    )
    message("Created adaptation workspace: ", result$workspace)
  },
  error = function(error) {
    message(conditionMessage(error))
    quit(status = 1L)
  }
)
