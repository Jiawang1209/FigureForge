#!/usr/bin/env Rscript

command_args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", command_args, value = TRUE)
script_path <- if (length(file_arg) > 0L) {
  normalizePath(sub("^--file=", "", file_arg[[1L]]), mustWork = TRUE)
} else {
  normalizePath("skills/figureforge/scripts/match_schema.R", mustWork = TRUE)
}
repo_root <- normalizePath(
  file.path(dirname(script_path), "..", "..", ".."),
  mustWork = TRUE
)
source(file.path(repo_root, "skills", "figureforge", "lib", "distribution_validation.R"))
source(file.path(repo_root, "skills", "figureforge", "lib", "metadata.R"))
source(file.path(repo_root, "skills", "figureforge", "lib", "schema_matching.R"))

parse_cli <- function(args) {
  result <- list(case = NULL, input = NULL, mapping = NULL, output = NULL)
  index <- 1L
  while (index <= length(args)) {
    argument <- args[[index]]
    if (!argument %in% c("--case", "--input", "--mapping", "--output") ||
        index == length(args)) {
      stop("Unknown or incomplete argument: ", argument)
    }
    result[[sub("^--", "", argument)]] <- args[[index + 1L]]
    index <- index + 2L
  }
  if (any(vapply(result[c("case", "input", "output")], is.null, logical(1)))) {
    stop("Required: --case --input --output")
  }
  result
}

tryCatch(
  {
    options <- parse_cli(commandArgs(trailingOnly = TRUE))
    public_cases <- file.path(repo_root, "skills", "figureforge", "public-cases")
    case_dir <- if (dir.exists(options$case)) {
      options$case
    } else {
      file.path(public_cases, options$case)
    }
    metadata <- read_case_metadata(case_dir)
    input <- read.csv(options$input, stringsAsFactors = FALSE, check.names = FALSE)
    profile <- profile_data_frame(input)
    mapping <- if (is.null(options$mapping)) {
      common <- intersect(
        c(metadata$required_roles$role, metadata$optional_roles$role),
        names(input)
      )
      stats::setNames(common, common)
    } else {
      read.csv(
        options$mapping,
        stringsAsFactors = FALSE,
        check.names = FALSE
      )
    }
    result <- match_case_schema(metadata, profile, mapping)
    report <- result$field_mappings
    if (nrow(report) == 0L) {
      report <- data.frame(
        role = "",
        input_column = "",
        stringsAsFactors = FALSE
      )
    }
    report$status <- result$status
    report$missing_required_roles <- paste(
      result$missing_required_roles,
      collapse = "|"
    )
    report$type_conflicts <- paste(result$type_conflicts, collapse = "|")
    report$allowed_transformations <- paste(
      result$allowed_transformations,
      collapse = "|"
    )
    report$assumptions <- paste(result$assumptions, collapse = "|")
    dir.create(dirname(options$output), recursive = TRUE, showWarnings = FALSE)
    write.csv(
      report,
      options$output,
      row.names = FALSE,
      fileEncoding = "UTF-8",
      na = ""
    )
    message("Schema match: ", result$status)
    if (identical(result$status, "incompatible")) quit(status = 1L)
  },
  error = function(error) {
    message(conditionMessage(error))
    quit(status = 1L)
  }
)
