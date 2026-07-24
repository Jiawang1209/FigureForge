#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
script_path <- if (length(file_arg) > 0) {
  normalizePath(sub("^--file=", "", file_arg[[1]]), mustWork = TRUE)
} else {
  normalizePath(
    "tests/figureforge/test_batch_planning.R",
    mustWork = TRUE
  )
}
repo_root <- normalizePath(
  file.path(dirname(script_path), "..", ".."),
  mustWork = TRUE
)
source(file.path(
  repo_root,
  "skills",
  "figureforge",
  "lib",
  "batch_planning.R"
))

readiness <- data.frame(
  case_id = c(
    "already-completed",
    "already-blocked",
    "reproduced-source-rich",
    "reproduced-no-source",
    "source-only",
    "plain-pending"
  ),
  processed = c(TRUE, TRUE, FALSE, FALSE, FALSE, FALSE),
  reproduced = c(TRUE, FALSE, TRUE, TRUE, FALSE, FALSE),
  runnable = c(TRUE, FALSE, TRUE, TRUE, TRUE, TRUE),
  scaffolded = c(FALSE, TRUE, TRUE, TRUE, TRUE, TRUE),
  source_assets = c(
    "source-script.R|measurements.csv",
    "",
    "source-script.R|measurements.csv",
    "",
    "R.R|observations.tsv",
    ""
  ),
  missing_dependencies = c(0L, 0L, 0L, 0L, 1L, 0L),
  stringsAsFactors = FALSE
)

plan <- plan_case_batches(readiness, batch_size = 2L)
stopifnot(!any(plan$case_id == "already-completed"))
stopifnot(!any(plan$case_id == "already-blocked"))
stopifnot(identical(plan$case_id[[1]], "reproduced-source-rich"))
stopifnot(identical(
  plan$case_id,
  c(
    "reproduced-source-rich",
    "reproduced-no-source",
    "source-only",
    "plain-pending"
  )
))
stopifnot(identical(plan$wave, c(1L, 1L, 2L, 2L)))
stopifnot(all(c(
  "priority_score",
  "priority_reason",
  "wave"
) %in% names(plan)))
stopifnot(plan$priority_score[[1]] == 190)
stopifnot(plan$priority_score[[3]] == 80)

empty <- plan_case_batches(
  readiness[readiness$processed, , drop = FALSE],
  batch_size = 2L
)
stopifnot(nrow(empty) == 0L)
stopifnot(identical(names(empty), names(plan)))

invalid_batch <- tryCatch(
  {
    plan_case_batches(readiness, batch_size = 0L)
    NULL
  },
  error = identity
)
stopifnot(inherits(invalid_batch, "error"))

message("batch planning tests: PASS")
