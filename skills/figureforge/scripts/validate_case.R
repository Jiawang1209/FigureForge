#!/usr/bin/env Rscript

command_args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", command_args, value = TRUE)
script_path <- if (length(file_arg) > 0) {
  normalizePath(sub("^--file=", "", file_arg[[1]]), mustWork = TRUE)
} else {
  normalizePath(
    "skills/figureforge/scripts/validate_case.R",
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

usage <- function() {
  paste(
    "Usage: validate_case.R <case_dir>",
    "[--complete]",
    "[--render --output PATH]",
    "[--rscript PATH]"
  )
}

parse_cli <- function(args) {
  if (length(args) == 0) {
    stop(usage())
  }
  result <- list(
    case_dir = args[[1]],
    complete = FALSE,
    render = FALSE,
    output = NULL,
    rscript = NULL
  )
  index <- 2L
  while (index <= length(args)) {
    argument <- args[[index]]
    if (argument == "--complete") {
      result$complete <- TRUE
      index <- index + 1L
      next
    }
    if (argument == "--render") {
      result$render <- TRUE
      result$complete <- TRUE
      index <- index + 1L
      next
    }
    if (argument %in% c("--output", "--rscript")) {
      if (index == length(args)) {
        stop("Missing value for ", argument, "\n", usage())
      }
      value <- args[[index + 1L]]
      if (argument == "--output") result$output <- value
      if (argument == "--rscript") result$rscript <- value
      index <- index + 2L
      next
    }
    stop("Unknown argument: ", argument, "\n", usage())
  }
  if (result$render && is.null(result$output)) {
    stop("--render requires --output PATH\n", usage())
  }
  result
}

print_checks <- function(result) {
  for (check_name in names(result$checks)) {
    message(
      check_name,
      ": ",
      if (isTRUE(result$checks[[check_name]])) "PASS" else "FAIL"
    )
  }
  for (detail in result$messages) {
    message("Note: ", detail)
  }
}

tryCatch(
  {
    options <- parse_cli(commandArgs(trailingOnly = TRUE))
    if (!dir.exists(options$case_dir)) {
      stop("Case directory not found: ", options$case_dir)
    }

    if (options$complete) {
      runtime <- if (options$render) {
        resolve_rscript(cli_path = options$rscript)
      } else {
        NULL
      }
      result <- validate_case_completion(
        options$case_dir,
        render_output = if (options$render) options$output else NULL,
        rscript = if (is.null(runtime)) NULL else runtime$path
      )
      print_checks(result)
      if (!result$ok) {
        stop(
          "Case completion validation failed: ",
          paste(result$failed_checks, collapse = ", ")
        )
      }
      message("Case completion OK: ", options$case_dir)
    } else {
      result <- validate_case_structure(options$case_dir)
      if (!result$ok) {
        stop(
          "Case structure validation failed: ",
          paste(result$failed_checks, collapse = ", ")
        )
      }
      message("Case structure OK: ", options$case_dir)
    }
  },
  error = function(error) {
    message(conditionMessage(error))
    quit(status = 1L)
  }
)
