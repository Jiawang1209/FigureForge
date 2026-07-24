#!/usr/bin/env Rscript

command_args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", command_args, value = TRUE)
script_path <- if (length(file_arg) > 0) {
  normalizePath(sub("^--file=", "", file_arg[[1]]), mustWork = TRUE)
} else {
  normalizePath(
    "skills/figureforge/scripts/validate_adaptation.R",
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
  "adaptation_validation.R"
))

usage <- function() {
  paste(
    "Usage: validate_adaptation.R <adaptation_dir>",
    "[--render --output PATH]",
    "[--rscript PATH]"
  )
}

parse_cli <- function(args) {
  if (length(args) == 0) {
    stop(usage())
  }
  result <- list(
    adaptation_dir = args[[1]],
    render = FALSE,
    output = NULL,
    rscript = "/usr/local/bin/Rscript"
  )
  index <- 2L
  while (index <= length(args)) {
    argument <- args[[index]]
    if (argument == "--render") {
      result$render <- TRUE
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
    if (!dir.exists(options$adaptation_dir)) {
      stop("Adaptation directory not found: ", options$adaptation_dir)
    }
    result <- validate_adaptation(
      options$adaptation_dir,
      render_output = if (options$render) options$output else NULL,
      rscript = options$rscript
    )
    print_checks(result)
    if (!result$ok) {
      stop(
        "Adaptation validation failed: ",
        paste(result$failed_checks, collapse = ", ")
      )
    }
    message("Adaptation validation OK: ", options$adaptation_dir)
  },
  error = function(error) {
    message(conditionMessage(error))
    quit(status = 1L)
  }
)
