#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
script_path <- if (length(file_arg) > 0) {
  normalizePath(sub("^--file=", "", file_arg[[1]]), mustWork = TRUE)
} else {
  normalizePath("tests/figureforge/test_case_validation.R", mustWork = TRUE)
}
repo_root <- normalizePath(file.path(dirname(script_path), "..", ".."), mustWork = TRUE)

source(file.path(repo_root, "skills", "figureforge", "lib", "case_audit.R"))
source(file.path(
  repo_root,
  "skills",
  "figureforge",
  "lib",
  "case_validation.R"
))

fixtures_dir <- file.path(repo_root, "tests", "fixtures", "figureforge", "cases")
valid_dir <- file.path(fixtures_dir, "authentic-public")
scaffold_dir <- file.path(fixtures_dir, "scaffolded")

structure_result <- validate_case_structure(valid_dir)
stopifnot(isTRUE(structure_result$ok))

complete_result <- validate_case_completion(valid_dir)
stopifnot(isTRUE(complete_result$ok))

scaffold_result <- validate_case_completion(scaffold_dir)
stopifnot(!isTRUE(scaffold_result$ok))
stopifnot("scaffold markers" %in% scaffold_result$failed_checks)

missing_packages_dir <- tempfile("figureforge-missing-packages-")
dir.create(missing_packages_dir, recursive = TRUE)
fixture_files <- list.files(valid_dir, full.names = TRUE)
stopifnot(file.copy(fixture_files, missing_packages_dir))
case_path <- file.path(missing_packages_dir, "case.md")
case_lines <- readLines(case_path, warn = FALSE)
package_start <- which(trimws(case_lines) == "## Required R Packages")
next_heading <- which(
  seq_along(case_lines) > package_start &
    grepl("^## ", case_lines)
)[[1]]
case_lines <- case_lines[-seq(package_start, next_heading - 1L)]
writeLines(case_lines, case_path, useBytes = TRUE)

package_result <- validate_case_completion(missing_packages_dir)
stopifnot(!isTRUE(package_result$ok))
stopifnot("required R packages" %in% package_result$failed_checks)

source_files <- list.files(valid_dir, full.names = TRUE)
source_mtimes_before <- file.info(source_files)$mtime
render_output <- file.path(
  tempfile("figureforge-validation-render-"),
  "valid.pdf"
)
render_result <- validate_case_completion(
  valid_dir,
  render_output = render_output,
  rscript = "/usr/local/bin/Rscript"
)
stopifnot(isTRUE(render_result$checks[["render succeeded"]]))
stopifnot(isTRUE(render_result$ok))
stopifnot(is_nonempty_file(render_output))
stopifnot(identical(
  source_mtimes_before,
  file.info(source_files)$mtime
))

failed_render_result <- validate_case_completion(
  file.path(fixtures_dir, "render-fails"),
  render_output = file.path(
    tempfile("figureforge-failed-render-"),
    "failed.pdf"
  ),
  rscript = "/usr/local/bin/Rscript"
)
stopifnot(!isTRUE(failed_render_result$checks[["render succeeded"]]))
stopifnot("render succeeded" %in% failed_render_result$failed_checks)

validator_cli <- file.path(
  repo_root,
  "skills",
  "figureforge",
  "scripts",
  "validate_case.R"
)
run_cli <- function(arguments) {
  log_path <- tempfile("figureforge-validator-cli-", fileext = ".log")
  status <- system2(
    "/usr/local/bin/Rscript",
    shQuote(c(validator_cli, arguments)),
    stdout = log_path,
    stderr = log_path
  )
  list(
    status = as.integer(status),
    output = paste(readLines(log_path, warn = FALSE), collapse = "\n")
  )
}

structural_cli <- run_cli(valid_dir)
stopifnot(identical(structural_cli$status, 0L))
stopifnot(grepl("Case structure OK", structural_cli$output, fixed = TRUE))

complete_cli <- run_cli(c(valid_dir, "--complete"))
stopifnot(identical(complete_cli$status, 0L))
stopifnot(grepl("Case completion OK", complete_cli$output, fixed = TRUE))

cli_render_output <- file.path(
  tempfile("figureforge-validator-cli-render-"),
  "valid.pdf"
)
render_cli <- run_cli(c(
  valid_dir,
  "--complete",
  "--render",
  "--output",
  cli_render_output,
  "--rscript",
  "/usr/local/bin/Rscript"
))
stopifnot(identical(render_cli$status, 0L))
stopifnot(is_nonempty_file(cli_render_output))
stopifnot(grepl("render succeeded: PASS", render_cli$output, fixed = TRUE))

unknown_cli <- run_cli(c(valid_dir, "--unknown"))
stopifnot(!identical(unknown_cli$status, 0L))

missing_output_cli <- run_cli(c(valid_dir, "--render"))
stopifnot(!identical(missing_output_cli$status, 0L))

read_repo_text <- function(relative_path) {
  paste(
    readLines(file.path(repo_root, relative_path), warn = FALSE),
    collapse = "\n"
  )
}
skill_text <- read_repo_text("skills/figureforge/SKILL.md")
readme_en <- read_repo_text("README.md")
readme_zh <- read_repo_text("README.zh.md")

for (document in list(skill_text, readme_en, readme_zh)) {
  stopifnot(grepl("--complete --render", document, fixed = TRUE))
  stopifnot(grepl("--output", document, fixed = TRUE))
}
stopifnot(grepl("## Completion Gates", skill_text, fixed = TRUE))
for (boundary in c(
  "structural evidence",
  "execution evidence",
  "visual QA evidence",
  "distribution evidence"
)) {
  stopifnot(grepl(boundary, skill_text, fixed = TRUE))
}

message("case validation tests: PASS")
