#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
script_path <- if (length(file_arg) > 0) {
  normalizePath(sub("^--file=", "", file_arg[[1]]), mustWork = TRUE)
} else {
  normalizePath(
    "tests/figureforge/test_blocker_validation.R",
    mustWork = TRUE
  )
}
repo_root <- normalizePath(
  file.path(dirname(script_path), "..", ".."),
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
  "blocker_validation.R"
))

fixtures <- file.path(
  repo_root,
  "tests",
  "fixtures",
  "figureforge",
  "blockers"
)

valid <- validate_blocker_record(file.path(fixtures, "valid"))
stopifnot(isTRUE(valid$ok))
stopifnot(identical(valid$status, "blocked_source_missing"))

unsupported <- validate_blocker_record(
  file.path(fixtures, "unsupported-status")
)
stopifnot(!isTRUE(unsupported$ok))
stopifnot("supported status" %in% unsupported$failed_checks)

missing <- validate_blocker_record(file.path(fixtures, "missing-evidence"))
stopifnot(!isTRUE(missing$ok))
stopifnot("non-empty evidence sections" %in% missing$failed_checks)

contradictory <- validate_blocker_record(
  file.path(fixtures, "contradictory")
)
stopifnot(!isTRUE(contradictory$ok))
stopifnot("not QA verified" %in% contradictory$failed_checks)

message("blocker validation tests: PASS")
