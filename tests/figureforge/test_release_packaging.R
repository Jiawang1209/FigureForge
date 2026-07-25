#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
script_path <- if (length(file_arg) > 0L) {
  normalizePath(sub("^--file=", "", file_arg[[1L]]), mustWork = TRUE)
} else {
  normalizePath(
    "tests/figureforge/test_release_packaging.R",
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
  "checksums.R"
))
source(file.path(
  repo_root,
  "skills",
  "figureforge",
  "lib",
  "release_packaging.R"
))

version_path <- file.path(
  repo_root,
  "skills",
  "figureforge",
  "VERSION"
)
stopifnot(identical(
  readLines(version_path, warn = FALSE, encoding = "UTF-8"),
  "1.0.0"
))

output_dir <- tempfile("figureforge-package-test-")
dir.create(output_dir, recursive = TRUE)
manifest_path <- file.path(output_dir, "manifest.csv")
manifest <- build_release_manifest(repo_root, manifest_path)

stopifnot(file.exists(manifest_path))
stopifnot(all(c(
  "source_path",
  "package_path",
  "sha256",
  "bytes"
) %in% names(manifest)))
stopifnot(nrow(manifest) > 0L)
stopifnot(identical(manifest$package_path, sort(manifest$package_path)))
stopifnot(!anyDuplicated(manifest$source_path))
stopifnot(!anyDuplicated(manifest$package_path))
stopifnot(all(grepl("^[0-9a-f]{64}$", manifest$sha256, perl = TRUE)))
stopifnot(all(manifest$bytes > 0))
stopifnot(all(startsWith(manifest$package_path, "figureforge/")))
stopifnot(!any(startsWith(manifest$package_path, "skills/")))
stopifnot(!any(grepl(
  "^skills/figureforge/cases/(?!_template/)",
  manifest$source_path,
  perl = TRUE
)))
stopifnot(any(
  manifest$package_path == "figureforge/cases/_template/case.md"
))
stopifnot(!any(grepl(
  "reproduction\\.|original\\.",
  manifest$source_path,
  perl = TRUE
)))
stopifnot(!any(grepl(
  "^outputs/|\\.log$|(^|/)case-index\\.csv$",
  manifest$source_path,
  perl = TRUE
)))
stopifnot(any(
  manifest$package_path == "figureforge/references/public-case-index.csv"
))
stopifnot(any(manifest$package_path == "figureforge/SKILL.md"))
stopifnot(any(
  manifest$package_path == "figureforge/examples/public-demo/run_demo.sh"
))
stopifnot(sum(grepl(
  "^figureforge/public-cases/[^/]+/distribution.yml$",
  manifest$package_path,
  perl = TRUE
)) == 12L)

tracked <- system2(
  "git",
  c("-C", shQuote(repo_root), "ls-files"),
  stdout = TRUE,
  stderr = TRUE
)
stopifnot(is.null(attr(tracked, "status")))
tracked <- tracked[file.exists(file.path(repo_root, tracked))]
stopifnot(!any(grepl(
  "(^|/)(reproduction|original)\\.",
  tracked,
  perl = TRUE
)))

archive_path <- file.path(output_dir, "figureforge-skill-1.0.0.tar.gz")
package <- package_figureforge_skill(
  repo_root,
  archive_path,
  manifest_path = file.path(output_dir, "archive-manifest.csv")
)
stopifnot(file.exists(archive_path))
stopifnot(file.info(archive_path)$size > 0L)
archive_files <- system2(
  "tar",
  c("-tzf", shQuote(archive_path)),
  stdout = TRUE,
  stderr = TRUE
)
stopifnot(is.null(attr(archive_files, "status")))
archive_files <- sort(sub("^\\./", "", archive_files))
stopifnot(identical(archive_files, sort(package$manifest$package_path)))

message("release packaging tests: PASS")
