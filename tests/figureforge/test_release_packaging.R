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
current_version <- readLines(
  version_path,
  warn = FALSE,
  encoding = "UTF-8"
)
stopifnot(identical(current_version, "1.1.0"))

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
stopifnot(any(
  manifest$package_path == "figureforge/references/plotting-workflow.md"
))
stopifnot(any(
  manifest$package_path == "figureforge/references/maintainer-workflow.md"
))
stopifnot(any(manifest$package_path == "figureforge/SKILL.md"))
stopifnot(any(
  manifest$package_path == "figureforge/examples/public-demo/run_demo.sh"
))
stopifnot(any(
  manifest$package_path == "figureforge/scripts/validate_case_trace.R"
))
stopifnot(any(
  manifest$package_path == "figureforge/lib/case_trace_validation.R"
))
stopifnot(sum(grepl(
  "^figureforge/public-cases/[^/]+/distribution.yml$",
  manifest$package_path,
  perl = TRUE
)) == 15L)

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

expect_release_error <- function(expression, pattern) {
  error <- tryCatch(
    {
      force(expression)
      NULL
    },
    error = identity
  )
  stopifnot(inherits(error, "error"))
  stopifnot(grepl(
    pattern,
    conditionMessage(error),
    ignore.case = TRUE
  ))
}

member_fixture <- c(
  "figureforge/SKILL.md",
  "figureforge/VERSION"
)
expect_release_error(
  validate_release_archive_members(
    member_fixture[[1L]],
    member_fixture,
    "-"
  ),
  "missing"
)
expect_release_error(
  validate_release_archive_members(
    c(member_fixture, "figureforge/extra.txt"),
    member_fixture,
    rep("-", 3L)
  ),
  "extra"
)
expect_release_error(
  validate_release_archive_members(
    c(member_fixture, member_fixture[[1L]]),
    member_fixture,
    rep("-", 3L)
  ),
  "duplicate"
)
expect_release_error(
  validate_release_archive_members(
    c("/absolute/SKILL.md", member_fixture[[2L]]),
    member_fixture,
    rep("-", 2L)
  ),
  "absolute"
)
expect_release_error(
  validate_release_archive_members(
    c("figureforge/../outside", member_fixture[[2L]]),
    member_fixture,
    rep("-", 2L)
  ),
  "parent-traversal"
)
expect_release_error(
  validate_release_archive_members(
    member_fixture,
    member_fixture,
    c("l", "-")
  ),
  "symlink"
)

archive_path <- file.path(
  output_dir,
  paste0("figureforge-skill-", current_version, ".tar.gz")
)
package <- package_figureforge_skill(
  repo_root,
  archive_path,
  manifest_path = file.path(output_dir, "archive-manifest.csv")
)
stopifnot(file.exists(archive_path))
stopifnot(file.info(archive_path)$size > 0L)
sidecar_path <- paste0(archive_path, ".sha256")
stopifnot(file.exists(sidecar_path))
sidecar <- readLines(sidecar_path, warn = FALSE, encoding = "UTF-8")
stopifnot(length(sidecar) == 1L)
stopifnot(grepl(
  paste0("^[0-9a-f]{64}  ", basename(archive_path), "$"),
  sidecar
))
stopifnot(identical(
  sub("  .*$", "", sidecar),
  figureforge_sha256(archive_path)
))
archive_files <- system2(
  "tar",
  c("-tzf", shQuote(archive_path)),
  stdout = TRUE,
  stderr = TRUE
)
stopifnot(is.null(attr(archive_files, "status")))
archive_files <- sort(sub("^\\./", "", archive_files))
stopifnot(identical(archive_files, sort(package$manifest$package_path)))

extracted_root <- file.path(output_dir, "extracted")
dir.create(extracted_root)
extract_status <- system2(
  "tar",
  c("-xzf", shQuote(archive_path), "-C", shQuote(extracted_root))
)
stopifnot(identical(as.integer(extract_status), 0L))
extracted_paths <- file.path(
  extracted_root,
  package$manifest$package_path
)
stopifnot(all(file.exists(extracted_paths)))
stopifnot(identical(
  unname(vapply(extracted_paths, figureforge_sha256, character(1))),
  package$manifest$sha256
))
stopifnot(identical(
  as.numeric(file.info(extracted_paths)$size),
  package$manifest$bytes
))

message("release packaging tests: PASS")
