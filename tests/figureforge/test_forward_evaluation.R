#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
script_path <- if (length(file_arg) > 0L) {
  normalizePath(sub("^--file=", "", file_arg[[1L]]), mustWork = TRUE)
} else {
  normalizePath(
    "tests/figureforge/test_forward_evaluation.R",
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
  "schema_matching.R"
))
source(file.path(
  repo_root,
  "skills",
  "figureforge",
  "lib",
  "forward_evaluation.R"
))

catalog_path <- file.path(
  repo_root,
  "skills",
  "figureforge",
  "references",
  "trigger-evals-v1.csv"
)
catalog <- read_forward_evaluations(catalog_path)

stopifnot(nrow(catalog) == 30L)
stopifnot(identical(
  catalog$eval_id,
  c(
    sprintf("eval-en-%03d", 1:15),
    sprintf("eval-zh-%03d", 1:15)
  )
))
language_counts <- table(catalog$language)
stopifnot(identical(
  stats::setNames(as.integer(language_counts), names(language_counts)),
  c(en = 15L, zh = 15L)
))
stopifnot(setequal(
  unique(catalog$outcome),
  c("select", "map_render", "reject")
))
stopifnot(setequal(
  catalog$expected_rejection[nzchar(catalog$expected_rejection)],
  c(
    "missing_required_role",
    "incompatible_type",
    "incompatible_cardinality",
    "protected_output",
    "private_asset",
    "unsafe_transformation"
  )
))
stopifnot(all(table(
  catalog$expected_rejection[nzchar(catalog$expected_rejection)]
) == 2L))

report_fields <- c(
  "eval_id",
  "language",
  "outcome",
  "expected_top1",
  "actual_top1",
  "top1_pass",
  "top3_pass",
  "mapping_pass",
  "render_pass",
  "rejection_pass",
  "passed",
  "details"
)
result_root <- tempfile("figureforge-forward-evaluation-")
dir.create(result_root, recursive = TRUE)
rows <- lapply(seq_len(nrow(catalog)), function(index) {
  run_forward_evaluation(
    catalog[index, , drop = FALSE],
    repo_root,
    result_root,
    "/usr/local/bin/Rscript"
  )
})
report <- do.call(rbind, rows)
stopifnot(identical(names(report), report_fields))
stopifnot(nrow(report) == 30L)
stopifnot(all(report$passed))

map_rows <- report$outcome == "map_render"
stopifnot(all(report$mapping_pass[map_rows]))
stopifnot(all(report$render_pass[map_rows]))
rendered <- list.files(
  result_root,
  pattern = "\\.pdf$",
  recursive = TRUE,
  full.names = TRUE
)
stopifnot(length(rendered) == sum(map_rows))
stopifnot(all(file.info(rendered)$size > 0L))

reject_rows <- report$outcome == "reject"
stopifnot(all(report$rejection_pass[reject_rows]))

summary <- summarize_forward_evaluations(report)
stopifnot(identical(summary$total, 30L))
stopifnot(summary$top1_rate >= 0.80)
stopifnot(identical(summary$top3_rate, 1))
stopifnot(identical(summary$mapping_rate, 1))
stopifnot(identical(summary$render_rate, 1))
stopifnot(identical(summary$rejection_rate, 1))
stopifnot(forward_thresholds_pass(summary))

top1_failure <- summary
top1_failure$top1_rate <- 0.79
stopifnot(!forward_thresholds_pass(top1_failure))
for (field in c(
  "top3_rate",
  "mapping_rate",
  "render_rate",
  "rejection_rate"
)) {
  hard_failure <- summary
  hard_failure[[field]] <- 0.99
  stopifnot(!forward_thresholds_pass(hard_failure))
}

message("forward evaluation tests: PASS")
