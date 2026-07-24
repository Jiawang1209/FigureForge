#!/usr/bin/env Rscript

command_args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", command_args, value = TRUE)
script_path <- if (length(file_arg) > 0) {
  normalizePath(sub("^--file=", "", file_arg[[1]]), mustWork = TRUE)
} else {
  normalizePath(
    "skills/figureforge/scripts/validate_blocker.R",
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
  "blocker_validation.R"
))

usage <- function() {
  "Usage: validate_blocker.R <case_dir>"
}

tryCatch(
  {
    args <- commandArgs(trailingOnly = TRUE)
    if (length(args) != 1L) {
      stop(usage())
    }
    case_dir <- args[[1]]
    if (!dir.exists(case_dir)) {
      stop("Case directory not found: ", case_dir)
    }
    result <- validate_blocker_record(case_dir)
    for (check_name in names(result$checks)) {
      message(
        check_name,
        ": ",
        if (isTRUE(result$checks[[check_name]])) "PASS" else "FAIL"
      )
    }
    message("blocked status: ", result$status)
    if (!result$ok) {
      stop(
        "Blocker validation failed: ",
        paste(result$failed_checks, collapse = ", ")
      )
    }
    message("Blocker validation OK: ", case_dir)
  },
  error = function(error) {
    message(conditionMessage(error))
    quit(status = 1L)
  }
)
