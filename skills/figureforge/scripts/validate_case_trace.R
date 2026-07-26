#!/usr/bin/env Rscript

command_args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", command_args, value = TRUE)
launcher_path <- if (length(file_arg) > 0L) {
  normalizePath(sub("^--file=", "", file_arg[[1L]]), mustWork = TRUE)
} else {
  normalizePath(
    "skills/figureforge/scripts/validate_case_trace.R",
    mustWork = TRUE
  )
}
skill_root <- normalizePath(
  file.path(dirname(launcher_path), ".."),
  mustWork = TRUE
)
repo_root <- normalizePath(
  file.path(skill_root, "..", ".."),
  mustWork = TRUE
)
repo_skill_root <- file.path(repo_root, "skills", "figureforge")
if (dir.exists(repo_skill_root)) {
  skill_root <- normalizePath(repo_skill_root, mustWork = TRUE)
}

source(file.path(skill_root, "lib", "distribution_validation.R"))
source(file.path(skill_root, "lib", "checksums.R"))
source(file.path(skill_root, "lib", "case_trace_validation.R"))

usage <- function() {
  paste(
    "Usage: validate_case_trace.R <trace.yml>",
    "[--case-dir PATH]",
    "[--script PATH]"
  )
}

parse_cli <- function(args) {
  if (length(args) < 1L) {
    stop(usage())
  }
  result <- list(
    trace_path = args[[1L]],
    case_dir = NULL,
    script_path = NULL
  )
  index <- 2L
  while (index <= length(args)) {
    argument <- args[[index]]
    if (!argument %in% c("--case-dir", "--script") ||
        index == length(args)) {
      stop("Unknown or incomplete argument: ", argument, "\n", usage())
    }
    value <- args[[index + 1L]]
    if (identical(argument, "--case-dir")) {
      result$case_dir <- value
    } else {
      result$script_path <- value
    }
    index <- index + 2L
  }
  result
}

print_case_trace_result <- function(result) {
  for (check_name in names(result$checks)) {
    message(
      check_name,
      ": ",
      if (isTRUE(result$checks[[check_name]])) "PASS" else "FAIL"
    )
  }
  for (detail in result$messages) {
    message("Message: ", detail)
  }
  message(
    "Verification level: ",
    result$evidence$verification_level
  )
}

tryCatch(
  {
    options <- parse_cli(commandArgs(trailingOnly = TRUE))
    result <- validate_case_trace(
      options$trace_path,
      case_dir = options$case_dir,
      script_path = options$script_path
    )
    print_case_trace_result(result)
    if (!isTRUE(result$ok)) {
      message(
        "Case trace validation failed: ",
        paste(result$failed_checks, collapse = ", ")
      )
      quit(status = 1L)
    }
    message("Case trace validation OK: ", options$trace_path)
  },
  error = function(error) {
    detail <- conditionMessage(error)
    message(detail)
    message("Verification level: unavailable")
    message(
      "Case trace validation failed: ",
      strsplit(detail, "\n", fixed = TRUE)[[1L]][[1L]]
    )
    quit(status = 1L)
  }
)
