#!/usr/bin/env Rscript

command_args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", command_args, value = TRUE)
script_path <- if (length(file_arg) > 0L) {
  normalizePath(sub("^--file=", "", file_arg[[1L]]), mustWork = TRUE)
} else {
  normalizePath("skills/figureforge/scripts/doctor.R", mustWork = TRUE)
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
  "dependency_doctor.R"
))

parse_cli <- function(args) {
  result <- list(
    case = NULL,
    format = "text",
    strict = FALSE,
    rscript = NULL
  )
  index <- 1L
  while (index <= length(args)) {
    argument <- args[[index]]
    if (argument == "--strict") {
      result$strict <- TRUE
      index <- index + 1L
      next
    }
    if (argument %in% c("--case", "--format", "--rscript") &&
        index < length(args)) {
      key <- sub("^--", "", argument)
      result[[key]] <- args[[index + 1L]]
      index <- index + 2L
      next
    }
    stop("Unknown or incomplete argument: ", argument)
  }
  if (!result$format %in% c("text", "json")) {
    stop("--format must be text or json")
  }
  result
}

tryCatch(
  {
    options <- parse_cli(commandArgs(trailingOnly = TRUE))
    case_dir <- NULL
    if (!is.null(options$case)) {
      case_dir <- if (dir.exists(options$case)) {
        options$case
      } else {
        file.path(
          repo_root,
          "skills",
          "figureforge",
          "public-cases",
          options$case
        )
      }
      if (!dir.exists(case_dir)) stop("Unknown public case: ", options$case)
    }
    report <- run_doctor(
      case_dir = case_dir,
      rscript = options$rscript
    )
    if (options$format == "json") {
      write_doctor_json(report, stdout())
    } else {
      write_doctor_text(report, stdout())
    }
    quit(status = doctor_exit_status(report, strict = options$strict))
  },
  error = function(error) {
    message(conditionMessage(error))
    quit(status = 1L)
  }
)
