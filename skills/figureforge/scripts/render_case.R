#!/usr/bin/env Rscript

command_args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", command_args, value = TRUE)
script_path <- if (length(file_arg) > 0) {
  normalizePath(sub("^--file=", "", file_arg[[1]]), mustWork = TRUE)
} else {
  normalizePath(
    "skills/figureforge/scripts/render_case.R",
    mustWork = TRUE
  )
}
repo_root <- normalizePath(
  file.path(dirname(script_path), "..", "..", ".."),
  mustWork = TRUE
)
source(file.path(repo_root, "skills", "figureforge", "lib", "case_audit.R"))

usage <- function() {
  paste(
    "Usage: render_case.R <case_dir> [output_path]",
    "[--input PATH]",
    "[--output PATH]",
    "[--rscript PATH]",
    "[--overwrite]"
  )
}

parse_cli <- function(args) {
  if (length(args) == 0) {
    stop(usage())
  }
  result <- list(
    case_dir = args[[1]],
    input = NULL,
    output = NULL,
    rscript = "/usr/local/bin/Rscript",
    overwrite = FALSE
  )
  index <- 2L
  if (index <= length(args) && !startsWith(args[[index]], "--")) {
    result$output <- args[[index]]
    index <- index + 1L
  }
  while (index <= length(args)) {
    argument <- args[[index]]
    if (argument == "--overwrite") {
      result$overwrite <- TRUE
      index <- index + 1L
      next
    }
    if (argument %in% c("--input", "--output", "--rscript")) {
      if (index == length(args)) {
        stop("Missing value for ", argument, "\n", usage())
      }
      value <- args[[index + 1L]]
      if (argument == "--input") result$input <- value
      if (argument == "--output") result$output <- value
      if (argument == "--rscript") result$rscript <- value
      index <- index + 2L
      next
    }
    stop("Unknown argument: ", argument, "\n", usage())
  }
  result
}

tryCatch(
  {
    options <- parse_cli(commandArgs(trailingOnly = TRUE))
    case_dir <- normalizePath(options$case_dir, mustWork = TRUE)
    input_path <- if (is.null(options$input)) {
      file.path(case_dir, "data.csv")
    } else {
      normalizePath(options$input, mustWork = TRUE)
    }
    output_path <- if (is.null(options$output)) {
      file.path(
        repo_root,
        "outputs",
        "figureforge-renders",
        paste0(basename(case_dir), ".pdf")
      )
    } else {
      path.expand(options$output)
    }
    if (file.exists(output_path) && !options$overwrite) {
      stop(
        "Output already exists; choose another path or pass --overwrite: ",
        output_path
      )
    }

    result <- render_case_for_audit(
      case_dir,
      output_path,
      rscript = options$rscript,
      input_path = input_path
    )
    if (!isTRUE(result$ok)) {
      stop(
        "Case rendering failed",
        if (is.na(result$status)) "" else paste0(" with status ", result$status),
        if (nzchar(result$log)) paste0(":\n", result$log) else ""
      )
    }
    message(
      "Render succeeded: ",
      normalizePath(output_path, mustWork = TRUE)
    )
  },
  error = function(error) {
    message(conditionMessage(error))
    quit(status = 1L)
  }
)
