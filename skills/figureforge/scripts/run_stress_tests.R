#!/usr/bin/env Rscript

command_args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", command_args, value = TRUE)
script_path <- if (length(file_arg) > 0L) {
  normalizePath(sub("^--file=", "", file_arg[[1L]]), mustWork = TRUE)
} else {
  normalizePath(
    "skills/figureforge/scripts/run_stress_tests.R",
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
  "stress_runner.R"
))

parse_cli <- function(args) {
  result <- list(
    fixtures = NULL,
    public_cases = NULL,
    output_dir = NULL,
    report = NULL,
    rscript = NULL
  )
  index <- 1L
  allowed <- c(
    "--fixtures",
    "--public-cases",
    "--output-dir",
    "--report",
    "--rscript"
  )
  while (index <= length(args)) {
    argument <- args[[index]]
    if (!argument %in% allowed || index == length(args)) {
      stop("Unknown or incomplete argument: ", argument)
    }
    key <- sub("^--", "", argument)
    key <- gsub("-", "_", key, fixed = TRUE)
    result[[key]] <- args[[index + 1L]]
    index <- index + 2L
  }
  required <- c("fixtures", "public_cases", "output_dir", "report")
  if (any(vapply(result[required], is.null, logical(1)))) {
    stop(
      "Required: --fixtures --public-cases --output-dir --report"
    )
  }
  result
}

tryCatch(
  {
    options <- parse_cli(commandArgs(trailingOnly = TRUE))
    runtime <- resolve_rscript(cli_path = options$rscript)
    results <- run_stress_suite(
      options$fixtures,
      options$public_cases,
      options$output_dir,
      rscript = runtime$path
    )
    dir.create(
      dirname(options$report),
      recursive = TRUE,
      showWarnings = FALSE
    )
    write.csv(
      results,
      options$report,
      row.names = FALSE,
      fileEncoding = "UTF-8",
      na = ""
    )
    message(
      "Stress suite: ",
      sum(results$passed),
      "/",
      nrow(results),
      " passed"
    )
    if (!all(results$passed)) quit(status = 1L)
  },
  error = function(error) {
    message(conditionMessage(error))
    quit(status = 1L)
  }
)
