#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
script_path <- if (length(file_arg) > 0L) {
  normalizePath(sub("^--file=", "", file_arg[[1L]]), mustWork = TRUE)
} else {
  normalizePath("tests/figureforge/test_v1_acceptance.R", mustWork = TRUE)
}
repo_root <- normalizePath(
  file.path(dirname(script_path), "..", ".."),
  mustWork = TRUE
)

clone_root <- tempfile("figureforge-v1-clone-")
clone_log <- tempfile("figureforge-v1-clone-", fileext = ".log")
clone_status <- system2(
  "git",
  c(
    "clone",
    "--quiet",
    "--local",
    shQuote(repo_root),
    shQuote(clone_root)
  ),
  stdout = clone_log,
  stderr = clone_log
)
stopifnot(identical(as.integer(clone_status), 0L))

branch <- system2(
  "git",
  c("-C", shQuote(repo_root), "branch", "--show-current"),
  stdout = TRUE
)
checkout_status <- system2(
  "git",
  c("-C", shQuote(clone_root), "checkout", "--quiet", shQuote(branch)),
  stdout = clone_log,
  stderr = clone_log
)
stopifnot(identical(as.integer(checkout_status), 0L))

private_entries <- list.files(
  file.path(clone_root, "skills", "figureforge", "cases"),
  recursive = TRUE,
  all.files = TRUE,
  no.. = TRUE
)
stopifnot(all(startsWith(private_entries, "_template")))

source_verifier <- file.path(
  repo_root,
  "scripts",
  "verify_figureforge_v1.sh"
)
clone_verifier <- file.path(
  clone_root,
  "scripts",
  "verify_figureforge_v1.sh"
)
stopifnot(file.exists(source_verifier))
if (!file.exists(clone_verifier)) {
  dir.create(dirname(clone_verifier), recursive = TRUE, showWarnings = FALSE)
  stopifnot(file.copy(source_verifier, clone_verifier))
}

verify_log <- tempfile("figureforge-v1-acceptance-", fileext = ".log")
verify_status <- system2(
  "sh",
  shQuote(clone_verifier),
  stdout = verify_log,
  stderr = verify_log
)
if (!identical(as.integer(verify_status), 0L)) {
  stop(paste(readLines(verify_log, warn = FALSE), collapse = "\n"))
}
lines <- readLines(verify_log, warn = FALSE)
stopifnot(identical(
  tail(lines[nzchar(lines)], 1L),
  "FigureForge Skill v1.0 acceptance: PASS"
))

message("v1 acceptance tests: PASS")
