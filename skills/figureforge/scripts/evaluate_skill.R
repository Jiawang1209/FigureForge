#!/usr/bin/env Rscript

command_args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", command_args, value = TRUE)
script_path <- if (length(file_arg) > 0L) {
  normalizePath(sub("^--file=", "", file_arg[[1L]]), mustWork = TRUE)
} else {
  normalizePath(
    "skills/figureforge/scripts/evaluate_skill.R",
    mustWork = TRUE
  )
}
repo_root <- normalizePath(
  file.path(dirname(script_path), "..", "..", ".."),
  mustWork = TRUE
)
for (library_file in c(
  "runtime_resolution.R",
  "distribution_validation.R",
  "metadata.R",
  "schema_matching.R",
  "forward_evaluation.R"
)) {
  source(file.path(
    repo_root,
    "skills",
    "figureforge",
    "lib",
    library_file
  ))
}

parse_cli <- function(args) {
  result <- list(
    catalog = NULL,
    output_dir = NULL,
    report = NULL,
    rscript = NULL
  )
  allowed <- c("--catalog", "--output-dir", "--report", "--rscript")
  index <- 1L
  while (index <= length(args)) {
    argument <- args[[index]]
    if (!argument %in% allowed || index == length(args)) {
      stop("Unknown or incomplete argument: ", argument)
    }
    key <- gsub("-", "_", sub("^--", "", argument), fixed = TRUE)
    result[[key]] <- args[[index + 1L]]
    index <- index + 2L
  }
  required <- c("catalog", "output_dir", "report")
  if (any(vapply(result[required], is.null, logical(1)))) {
    stop("Required: --catalog --output-dir --report [--rscript PATH]")
  }
  result
}

tryCatch(
  {
    options <- parse_cli(commandArgs(trailingOnly = TRUE))
    if (dir.exists(options$output_dir) &&
        length(list.files(
          options$output_dir,
          all.files = TRUE,
          no.. = TRUE
        )) > 0L) {
      stop("Evaluation output directory must be empty: ", options$output_dir)
    }
    dir.create(options$output_dir, recursive = TRUE, showWarnings = FALSE)
    runtime <- resolve_rscript(cli_path = options$rscript)
    catalog <- read_forward_evaluations(options$catalog)
    rows <- lapply(seq_len(nrow(catalog)), function(index) {
      run_forward_evaluation(
        catalog[index, , drop = FALSE],
        repo_root,
        options$output_dir,
        runtime$path
      )
    })
    report <- do.call(rbind, rows)
    dir.create(dirname(options$report), recursive = TRUE, showWarnings = FALSE)
    write.csv(
      report,
      options$report,
      row.names = FALSE,
      fileEncoding = "UTF-8",
      na = ""
    )
    summary <- summarize_forward_evaluations(report)
    message(
      "Forward evaluations: ", summary$passed, "/", summary$total,
      " passed; Top-1=", sprintf("%.1f%%", 100 * summary$top1_rate),
      "; Top-3=", sprintf("%.1f%%", 100 * summary$top3_rate),
      "; mapping=", sprintf("%.1f%%", 100 * summary$mapping_rate),
      "; render=", sprintf("%.1f%%", 100 * summary$render_rate),
      "; safe rejection=", sprintf("%.1f%%", 100 * summary$rejection_rate)
    )
    if (!forward_thresholds_pass(summary)) quit(status = 1L)
  },
  error = function(error) {
    message(conditionMessage(error))
    quit(status = 1L)
  }
)
