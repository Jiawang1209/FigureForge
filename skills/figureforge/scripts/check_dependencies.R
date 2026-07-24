#!/usr/bin/env Rscript

command_args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", command_args, value = TRUE)
script_path <- if (length(file_arg) > 0) {
  normalizePath(sub("^--file=", "", file_arg[[1]]), mustWork = TRUE)
} else {
  normalizePath(
    "skills/figureforge/scripts/check_dependencies.R",
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

usage <- function() {
  paste(
    "Usage: check_dependencies.R",
    "(--case-dir PATH | --cases-dir PATH)",
    "[--strict]"
  )
}

parse_cli <- function(args) {
  result <- list(case_dir = NULL, cases_dir = NULL, strict = FALSE)
  index <- 1L
  while (index <= length(args)) {
    argument <- args[[index]]
    if (argument == "--strict") {
      result$strict <- TRUE
      index <- index + 1L
      next
    }
    if (argument %in% c("--case-dir", "--cases-dir")) {
      if (index == length(args)) {
        stop("Missing value for ", argument, "\n", usage())
      }
      value <- args[[index + 1L]]
      if (argument == "--case-dir") result$case_dir <- value
      if (argument == "--cases-dir") result$cases_dir <- value
      index <- index + 2L
      next
    }
    stop("Unknown argument: ", argument, "\n", usage())
  }
  if (sum(!vapply(
    list(result$case_dir, result$cases_dir),
    is.null,
    logical(1)
  )) != 1L) {
    stop("Specify exactly one of --case-dir or --cases-dir\n", usage())
  }
  result
}

tryCatch(
  {
    options <- parse_cli(commandArgs(trailingOnly = TRUE))
    packages <- if (!is.null(options$case_dir)) {
      check_case_dependencies(options$case_dir)$package
    } else {
      catalog <- build_case_catalog(options$cases_dir)
      unique(trimws(unlist(strsplit(
        catalog$required_r_packages[
          nzchar(catalog$required_r_packages)
        ],
        ",",
        fixed = TRUE
      ))))
    }
    report <- check_r_packages(packages)
    report$status <- ifelse(report$installed, "installed", "missing")
    write.table(
      report[, c("package", "status"), drop = FALSE],
      row.names = FALSE,
      sep = "\t",
      quote = FALSE,
      file = stdout()
    )
    missing <- report$package[!report$installed]
    message(
      "Dependency check: ",
      sum(report$installed),
      " installed, ",
      length(missing),
      " missing."
    )
    if (options$strict && length(missing) > 0) {
      quit(status = 1L)
    }
  },
  error = function(error) {
    message(conditionMessage(error))
    quit(status = 1L)
  }
)
