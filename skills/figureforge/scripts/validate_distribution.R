#!/usr/bin/env Rscript

command_args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", command_args, value = TRUE)
script_path <- if (length(file_arg) > 0L) {
  normalizePath(sub("^--file=", "", file_arg[[1L]]), mustWork = TRUE)
} else {
  normalizePath(
    "skills/figureforge/scripts/validate_distribution.R",
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

usage <- function() {
  "Usage: validate_distribution.R <case_dir> [--format text|csv]"
}

parse_cli <- function(args) {
  if (length(args) < 1L) {
    stop(usage())
  }
  result <- list(case_dir = args[[1L]], format = "text")
  index <- 2L
  while (index <= length(args)) {
    argument <- args[[index]]
    if (argument != "--format" || index == length(args)) {
      stop("Unknown or incomplete argument: ", argument, "\n", usage())
    }
    result$format <- args[[index + 1L]]
    index <- index + 2L
  }
  if (!result$format %in% c("text", "csv")) {
    stop("--format must be text or csv")
  }
  result
}

tryCatch(
  {
    options <- parse_cli(commandArgs(trailingOnly = TRUE))
    result <- validate_distribution(options$case_dir)
    report <- data.frame(
      check = names(result$checks),
      status = ifelse(result$checks, "PASS", "FAIL"),
      stringsAsFactors = FALSE
    )
    if (options$format == "csv") {
      write.csv(
        report,
        stdout(),
        row.names = FALSE,
        quote = TRUE,
        fileEncoding = "UTF-8"
      )
    } else {
      for (row_index in seq_len(nrow(report))) {
        message(
          report$check[[row_index]],
          ": ",
          report$status[[row_index]]
        )
      }
      if (isTRUE(result$ok)) {
        message("Distribution validation OK: ", options$case_dir)
      } else {
        message(
          "Distribution validation failed: ",
          paste(result$failed_checks, collapse = ", ")
        )
      }
    }
    if (!isTRUE(result$ok)) {
      quit(status = 1L)
    }
  },
  error = function(error) {
    message(conditionMessage(error))
    quit(status = 1L)
  }
)
