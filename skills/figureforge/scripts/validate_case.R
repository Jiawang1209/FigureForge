#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
case_dir <- if (length(args) >= 1) args[[1]] else stop("Usage: validate_case.R <case_dir>")

required_files <- c("case.md", "data.csv", "plot.R")
missing_files <- required_files[!file.exists(file.path(case_dir, required_files))]

case_md <- file.path(case_dir, "case.md")
required_headings <- c(
  "## Chart Type",
  "## Best For",
  "## Data Schema",
  "## Visual Encoding",
  "## ggplot Components",
  "## Adaptation Notes",
  "## Common Pitfalls"
)

missing_headings <- character(0)
if (file.exists(case_md)) {
  case_text <- readLines(case_md, warn = FALSE)
  missing_headings <- required_headings[!vapply(required_headings, function(heading) any(trimws(case_text) == heading), logical(1))]
}

if (length(missing_files) > 0 || length(missing_headings) > 0) {
  if (length(missing_files) > 0) {
    message("Missing required file(s): ", paste(missing_files, collapse = ", "))
  }
  if (length(missing_headings) > 0) {
    message("Missing required heading(s): ", paste(missing_headings, collapse = ", "))
  }
  quit(status = 1)
}

message("Case structure OK: ", case_dir)
