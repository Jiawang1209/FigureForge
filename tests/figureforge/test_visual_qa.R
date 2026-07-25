#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
script_path <- if (length(file_arg) > 0L) {
  normalizePath(sub("^--file=", "", file_arg[[1L]]), mustWork = TRUE)
} else {
  normalizePath(
    "tests/figureforge/test_visual_qa.R",
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
  "visual_qa.R"
))

fixtures <- file.path(
  repo_root,
  "tests",
  "fixtures",
  "figureforge",
  "visual-qa"
)
blank_svg <- file.path(fixtures, "blank.svg")
nonblank_svg <- file.path(fixtures, "nonblank.svg")

report <- inspect_visual_output(nonblank_svg)
stopifnot(identical(report$status, "review_required"))
stopifnot(!any(tolower(unlist(report)) == "verified"))
stopifnot(identical(report$render$format, "svg"))
stopifnot(identical(report$render$width, 200))
stopifnot(identical(report$render$height, 120))
stopifnot(any(
  report$checks$check_id == "non_blank" &
    report$checks$status == "pass"
))

blank <- inspect_visual_output(blank_svg)
stopifnot(identical(blank$status, "review_required"))
stopifnot(any(
  blank$checks$check_id == "non_blank" &
    blank$checks$status == "warning"
))

missing <- inspect_visual_output(file.path(fixtures, "missing.svg"))
stopifnot(identical(missing$status, "tool_check_failed"))

qa_path <- file.path(
  repo_root,
  "skills",
  "figureforge",
  "public-cases",
  "public-scatter-fit",
  "qa.md"
)
qa_before <- tools::md5sum(qa_path)
json_path <- tempfile("figureforge-visual-qa-", fileext = ".json")
write_visual_qa_report(report, json_path)
qa_after <- tools::md5sum(qa_path)
stopifnot(identical(qa_before, qa_after))
python_status <- system2(
  "/usr/bin/python3",
  c(
    "-c",
    shQuote(paste(
      "import json,sys;",
      "x=json.load(open(sys.argv[1], encoding='utf-8'));",
      "assert x['schema_version']==1;",
      "assert x['status']=='review_required';",
      "assert 'verified' not in open(sys.argv[1], encoding='utf-8').read().lower()"
    )),
    shQuote(json_path)
  )
)
stopifnot(identical(as.integer(python_status), 0L))

pdf_path <- tempfile("figureforge-visual-qa-", fileext = ".pdf")
grDevices::pdf(pdf_path, width = 4, height = 3)
graphics::plot(1:3, 1:3, type = "b")
grDevices::dev.off()
pdf_report <- inspect_visual_output(pdf_path)
stopifnot(identical(pdf_report$status, "review_required"))
stopifnot(identical(pdf_report$render$format, "pdf"))
stopifnot(pdf_report$render$pages >= 1L)

production_paths <- c(
  file.path(repo_root, "skills", "figureforge", "lib", "visual_qa.R"),
  file.path(repo_root, "skills", "figureforge", "scripts", "visual_qa.R")
)
production_text <- tolower(paste(
  unlist(lapply(production_paths, readLines, warn = FALSE)),
  collapse = "\n"
))
stopifnot(!grepl("status: verified", production_text, fixed = TRUE))

visual_cli <- file.path(
  repo_root,
  "skills",
  "figureforge",
  "scripts",
  "visual_qa.R"
)
cli_report <- tempfile("figureforge-visual-qa-cli-", fileext = ".json")
cli_log <- tempfile("figureforge-visual-qa-cli-", fileext = ".log")
cli_status <- system2(
  "/usr/local/bin/Rscript",
  shQuote(c(
    visual_cli,
    "--render", nonblank_svg,
    "--reference", nonblank_svg,
    "--report", cli_report
  )),
  stdout = cli_log,
  stderr = cli_log
)
stopifnot(identical(as.integer(cli_status), 0L))
stopifnot(file.exists(cli_report))

forbidden_report <- file.path(
  repo_root,
  "skills",
  "figureforge",
  "public-cases",
  "public-scatter-fit",
  "forbidden-qa.json"
)
forbidden_log <- tempfile("figureforge-visual-qa-forbidden-", fileext = ".log")
forbidden_status <- system2(
  "/usr/local/bin/Rscript",
  shQuote(c(
    visual_cli,
    "--render", nonblank_svg,
    "--report", forbidden_report
  )),
  stdout = forbidden_log,
  stderr = forbidden_log
)
stopifnot(!identical(as.integer(forbidden_status), 0L))
stopifnot(!file.exists(forbidden_report))

message("visual QA tests: PASS")
