#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
script_path <- if (length(file_arg) > 0L) {
  normalizePath(sub("^--file=", "", file_arg[[1L]]), mustWork = TRUE)
} else {
  normalizePath("tests/figureforge/test_public_demo.R", mustWork = TRUE)
}
repo_root <- normalizePath(
  file.path(dirname(script_path), "..", ".."),
  mustWork = TRUE
)

clean_root <- tempfile("figureforge-public-demo-clean-")
dir.create(clean_root, recursive = TRUE)
files <- system2(
  "git",
  c(
    "-C", shQuote(repo_root),
    "ls-files",
    "--cached",
    "--others",
    "--exclude-standard"
  ),
  stdout = TRUE,
  stderr = TRUE
)
stopifnot(is.null(attr(files, "status")))
files <- files[
  !startsWith(files, ".worktrees/") &
    !startsWith(files, "outputs/") &
    !grepl(
      "^skills/figureforge/cases/(?!_template/)",
      files,
      perl = TRUE
    )
]
for (relative in files) {
  source_path <- file.path(repo_root, relative)
  target_path <- file.path(clean_root, relative)
  dir.create(dirname(target_path), recursive = TRUE, showWarnings = FALSE)
  stopifnot(file.copy(source_path, target_path, overwrite = TRUE))
}

private_entries <- list.files(
  file.path(clean_root, "skills", "figureforge", "cases"),
  recursive = TRUE,
  all.files = TRUE,
  no.. = TRUE
)
stopifnot(all(startsWith(private_entries, "_template")))

demo_output <- tempfile("figureforge-public-demo-output-")
demo_script <- file.path(clean_root, "examples", "public-demo", "run_demo.sh")
demo_log <- tempfile("figureforge-public-demo-", fileext = ".log")
demo_status <- system2(
  "sh",
  c(shQuote(demo_script), shQuote(demo_output)),
  stdout = demo_log,
  stderr = demo_log
)
if (!identical(as.integer(demo_status), 0L)) {
  stop(paste(readLines(demo_log, warn = FALSE), collapse = "\n"))
}
demo_log_text <- paste(readLines(demo_log, warn = FALSE), collapse = "\n")
stopifnot(!grepl("conversion failure", demo_log_text, fixed = TRUE))

required <- c(
  "input.csv",
  "plot.R",
  "mapping.md",
  "qa.md",
  "adaptation.yml",
  "output.pdf",
  "visual-qa.json",
  "validation-output.pdf"
)
stopifnot(all(file.exists(file.path(demo_output, required))))
stopifnot(all(file.info(file.path(demo_output, required))$size > 0L))

qa_text <- paste(
  readLines(file.path(demo_output, "qa.md"), warn = FALSE),
  collapse = "\n"
)
stopifnot(grepl("Status: review_required", qa_text, fixed = TRUE))
stopifnot(!grepl("Status: verified", qa_text, fixed = TRUE))

visual_text <- paste(
  readLines(file.path(demo_output, "visual-qa.json"), warn = FALSE),
  collapse = "\n"
)
stopifnot(grepl('"status":"review_required"', visual_text, fixed = TRUE))
stopifnot(!grepl("verified", tolower(visual_text), fixed = TRUE))

input <- read.csv(
  file.path(demo_output, "input.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
stopifnot(identical(
  names(input),
  c("time", "estimate", "lower", "upper", "group")
))

message("public demo tests: PASS")
