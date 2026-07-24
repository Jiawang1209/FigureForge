#!/usr/bin/env Rscript

command_args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", command_args, value = TRUE)
script_path <- if (length(file_arg) > 0) {
  normalizePath(sub("^--file=", "", file_arg[[1]]), mustWork = TRUE)
} else {
  normalizePath(
    "skills/figureforge/scripts/index_cases.R",
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

args <- commandArgs(trailingOnly = TRUE)
cases_dir <- if (length(args) >= 1) {
  args[[1]]
} else {
  file.path(repo_root, "skills", "figureforge", "cases")
}
output_path <- if (length(args) >= 2) {
  args[[2]]
} else {
  file.path(
    repo_root,
    "skills",
    "figureforge",
    "references",
    "case-index.csv"
  )
}

index <- build_case_catalog(cases_dir)

dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
write.csv(index, output_path, row.names = FALSE, fileEncoding = "UTF-8")
message(
  "Wrote ",
  nrow(index),
  " case(s) to index: ",
  normalizePath(output_path, mustWork = TRUE)
)
