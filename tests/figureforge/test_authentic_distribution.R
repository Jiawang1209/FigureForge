#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
script_path <- if (length(file_arg) > 0L) {
  normalizePath(sub("^--file=", "", file_arg[[1L]]), mustWork = TRUE)
} else {
  normalizePath(
    "tests/figureforge/test_authentic_distribution.R",
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
  "checksums.R"
))
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

fixture_root <- file.path(
  repo_root,
  "tests",
  "fixtures",
  "figureforge",
  "distribution"
)
valid <- validate_distribution(file.path(fixture_root, "authentic-valid"))
stopifnot(valid$ok)
stopifnot(!valid$synthetic_test_fixture)
stopifnot(identical(valid$source_type, "authentic_open_data"))
stopifnot(identical(valid$qa_status, "verified"))
authentic_metadata <- read_case_metadata(file.path(
  fixture_root,
  "authentic-valid"
))
stopifnot(validate_case_metadata(authentic_metadata)$ok)

synthetic <- validate_distribution(file.path(fixture_root, "valid"))
stopifnot(synthetic$ok)
stopifnot(synthetic$synthetic_test_fixture)
stopifnot(identical(synthetic$qa_status, "review_required"))

missing_root <- tempfile("figureforge-authentic-missing-")
dir.create(missing_root, recursive = TRUE)
fixture_files <- list.files(
  file.path(fixture_root, "authentic-valid"),
  full.names = TRUE
)
stopifnot(all(file.copy(fixture_files, missing_root)))
unlink(file.path(missing_root, "source.yml"))
missing <- validate_distribution(missing_root)
stopifnot(!missing$ok)
stopifnot("authentic source metadata" %in% missing$failed_checks)

wrong_hash_root <- tempfile("figureforge-authentic-hash-")
dir.create(wrong_hash_root, recursive = TRUE)
stopifnot(all(file.copy(fixture_files, wrong_hash_root)))
source_path <- file.path(wrong_hash_root, "source.yml")
source_lines <- readLines(source_path, warn = FALSE, encoding = "UTF-8")
source_lines <- sub(
  "^normalized_sha256: .*$",
  paste0("normalized_sha256: ", paste(rep("0", 64L), collapse = "")),
  source_lines
)
writeLines(source_lines, source_path, useBytes = TRUE)
wrong_hash <- validate_distribution(wrong_hash_root)
stopifnot(!wrong_hash$ok)
stopifnot("normalized data checksum" %in% wrong_hash$failed_checks)

message("authentic distribution tests: PASS")
