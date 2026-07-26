#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
script_path <- if (length(file_arg) > 0L) {
  normalizePath(sub("^--file=", "", file_arg[[1L]]), mustWork = TRUE)
} else {
  normalizePath(
    "tests/figureforge/test_v110_certification_identity.R",
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
  "release_packaging.R"
))
source(file.path(
  repo_root,
  "scripts",
  "lib",
  "release_certification.R"
))

required_live_certification_paths <- c(
  "scripts/run_figureforge_live_evals.sh",
  "scripts/run_figureforge_plotting_eval.sh",
  "scripts/run_figureforge_mode_evals.sh",
  "scripts/evaluate_figureforge_mode_probe.R",
  "scripts/lib/live_mode_evaluation.R"
)
stopifnot(all(
  required_live_certification_paths %in%
    figureforge_certification_additional_source_paths()
))

valid_identity <- data.frame(
  schema_version = "2",
  release_version = "1.1.0",
  certified_source_commit = paste(rep("a", 40L), collapse = ""),
  certified_source_tree = paste(rep("b", 40L), collapse = ""),
  release_source_sha256 = paste(rep("c", 64L), collapse = ""),
  manifest_rows = 2L,
  manifest_bytes = 100L,
  manifest_sha256 = paste(rep("d", 64L), collapse = ""),
  archive_bytes = 200L,
  archive_sha256 = paste(rep("e", 64L), collapse = ""),
  live_trigger_summary_sha256 = paste(rep("1", 64L), collapse = ""),
  live_plotting_summary_sha256 = paste(rep("2", 64L), collapse = ""),
  live_mode_summary_sha256 = paste(rep("3", 64L), collapse = ""),
  certified_at = "2026-07-26T12:00:00+0800",
  stringsAsFactors = FALSE
)

same <- compare_figureforge_certification_identity(
  valid_identity,
  valid_identity
)
stopifnot(isTRUE(same$ok))
stopifnot(length(same$failures) == 0L)

stale_source <- valid_identity
stale_source$release_source_sha256 <- paste(rep("f", 64L), collapse = "")
source_result <- compare_figureforge_certification_identity(
  valid_identity,
  stale_source
)
stopifnot(!isTRUE(source_result$ok))
stopifnot("release_source_sha256" %in% source_result$failures)

stale_package <- valid_identity
stale_package$manifest_sha256 <- paste(rep("0", 64L), collapse = "")
package_result <- compare_figureforge_certification_identity(
  valid_identity,
  stale_package
)
stopifnot(!isTRUE(package_result$ok))
stopifnot("manifest_sha256" %in% package_result$failures)

stale_archive <- valid_identity
stale_archive$archive_sha256 <- paste(rep("1", 64L), collapse = "")
archive_result <- compare_figureforge_certification_identity(
  valid_identity,
  stale_archive,
  compare_archive = TRUE
)
stopifnot(!isTRUE(archive_result$ok))
stopifnot("archive_sha256" %in% archive_result$failures)

archive_ignored <- compare_figureforge_certification_identity(
  valid_identity,
  stale_archive,
  compare_archive = FALSE
)
stopifnot(isTRUE(archive_ignored$ok))

stale_live <- valid_identity
stale_live$live_mode_summary_sha256 <- paste(rep("4", 64L), collapse = "")
live_result <- compare_figureforge_certification_identity(
  valid_identity,
  stale_live
)
stopifnot(!isTRUE(live_result$ok))
stopifnot("live_mode_summary_sha256" %in% live_result$failures)

invalid <- valid_identity
invalid$certified_source_commit <- "not-a-commit"
invalid_error <- tryCatch(
  {
    validate_figureforge_certification_identity(invalid)
    NULL
  },
  error = identity
)
stopifnot(inherits(invalid_error, "error"))
stopifnot(grepl(
  "certified_source_commit",
  conditionMessage(invalid_error),
  fixed = TRUE
))

fixture_root <- tempfile("figureforge-certification-source-")
dir.create(file.path(fixture_root, "skills", "figureforge"), recursive = TRUE)
dir.create(file.path(fixture_root, "scripts"), recursive = TRUE)
trigger_summary_path <- file.path(fixture_root, "live-trigger-summary.csv")
plotting_summary_path <- file.path(fixture_root, "live-plotting-summary.csv")
mode_summary_path <- file.path(fixture_root, "live-mode-summary.csv")
write.csv(
  data.frame(
    kind = c("explicit", rep("implicit", 10L)),
    passed = rep(TRUE, 11L)
  ),
  trigger_summary_path,
  row.names = FALSE
)
write.csv(
  data.frame(
    script_exists = TRUE,
    png_exists = TRUE,
    pdf_exists = TRUE,
    passed = TRUE
  ),
  plotting_summary_path,
  row.names = FALSE
)
write.csv(
  data.frame(
    expected_mode = c("case_based", "general_fallback"),
    generation_mode = c("case_based", "general_fallback"),
    claim = c("case_grounded", "general_method"),
    case_md_read = c(TRUE, FALSE),
    plot_r_read = c(TRUE, FALSE),
    qa_md_read = c(TRUE, FALSE),
    passed = c(TRUE, TRUE)
  ),
  mode_summary_path,
  row.names = FALSE
)
validate_figureforge_live_certification_summaries(
  trigger_summary_path,
  plotting_summary_path,
  mode_summary_path
)
invalid_mode <- read.csv(mode_summary_path)
invalid_mode$case_md_read[[1L]] <- FALSE
write.csv(invalid_mode, mode_summary_path, row.names = FALSE)
invalid_live_error <- tryCatch(
  {
    validate_figureforge_live_certification_summaries(
      trigger_summary_path,
      plotting_summary_path,
      mode_summary_path
    )
    NULL
  },
  error = identity
)
stopifnot(inherits(invalid_live_error, "error"))
write.csv(
  transform(invalid_mode, case_md_read = c(TRUE, FALSE)),
  mode_summary_path,
  row.names = FALSE
)
writeLines(
  "skill",
  file.path(fixture_root, "skills", "figureforge", "SKILL.md")
)
writeLines(
  "verifier",
  file.path(fixture_root, "scripts", "verify_figureforge_v110.sh")
)
fixture_manifest <- data.frame(
  source_path = "skills/figureforge/SKILL.md",
  package_path = "figureforge/SKILL.md",
  sha256 = figureforge_sha256(file.path(
    fixture_root,
    "skills",
    "figureforge",
    "SKILL.md"
  )),
  bytes = file.info(file.path(
    fixture_root,
    "skills",
    "figureforge",
    "SKILL.md"
  ))$size,
  stringsAsFactors = FALSE
)
manifest_with_source_rows <- fixture_manifest
rownames(manifest_with_source_rows) <- manifest_with_source_rows$source_path
manifest_roundtrip_path <- file.path(fixture_root, "release-manifest.csv")
write.csv(
  manifest_with_source_rows,
  manifest_roundtrip_path,
  row.names = FALSE,
  quote = TRUE
)
manifest_after_roundtrip <- read.csv(
  manifest_roundtrip_path,
  stringsAsFactors = FALSE,
  check.names = FALSE
)
stopifnot(figureforge_manifest_identical(
  manifest_with_source_rows,
  manifest_after_roundtrip
))
fixture_digest <- figureforge_release_source_sha256(
  fixture_root,
  fixture_manifest,
  additional_paths = "scripts/verify_figureforge_v110.sh"
)
stopifnot(grepl("^[0-9a-f]{64}$", fixture_digest, perl = TRUE))

writeLines(
  "changed verifier",
  file.path(fixture_root, "scripts", "verify_figureforge_v110.sh")
)
changed_digest <- figureforge_release_source_sha256(
  fixture_root,
  fixture_manifest,
  additional_paths = "scripts/verify_figureforge_v110.sh"
)
stopifnot(!identical(fixture_digest, changed_digest))

identity_path <- file.path(fixture_root, "certification-identity.tsv")
write_figureforge_certification_identity(valid_identity, identity_path)
roundtrip <- read_figureforge_certification_identity(identity_path)
stopifnot(identical(
  as.character(roundtrip[1L, names(valid_identity)]),
  as.character(valid_identity[1L, ])
))

head_commit <- system2(
  "git",
  c("-C", shQuote(repo_root), "rev-parse", "HEAD"),
  stdout = TRUE
)
head_tree <- system2(
  "git",
  c("-C", shQuote(repo_root), "rev-parse", "HEAD^{tree}"),
  stdout = TRUE
)
stopifnot(
  is.null(attr(head_commit, "status")),
  is.null(attr(head_tree, "status"))
)
git_bound <- valid_identity
git_bound$certified_source_commit <- head_commit[[1L]]
git_bound$certified_source_tree <- head_tree[[1L]]
binding_result <- validate_figureforge_certified_git_binding(
  repo_root,
  git_bound
)
stopifnot(isTRUE(binding_result$ok))

wrong_tree <- git_bound
wrong_tree$certified_source_tree <- paste(rep("0", 40L), collapse = "")
wrong_tree_result <- validate_figureforge_certified_git_binding(
  repo_root,
  wrong_tree
)
stopifnot(!isTRUE(wrong_tree_result$ok))
stopifnot("certified_source_tree" %in% wrong_tree_result$failures)

portable_identity_path <- file.path(
  repo_root,
  "docs",
  "figureforge-skill-v1.1.0-evidence",
  "certification-identity.tsv"
)
stopifnot(file.exists(portable_identity_path))
portable_identity <- read_figureforge_certification_identity(
  portable_identity_path
)
current_certification <- check_figureforge_current_certification(
  repo_root,
  portable_identity_path
)
stopifnot(isTRUE(current_certification$ok))
stopifnot(length(current_certification$failures) == 0L)
portable_check_root <- tempfile("figureforge-portable-certification-")
dir.create(portable_check_root)
portable_files <- c(
  "certification-identity.tsv",
  "live-trigger-summary.csv",
  "live-plotting-summary.csv",
  "live-mode-summary.csv"
)
stopifnot(all(file.copy(
  file.path(dirname(portable_identity_path), portable_files),
  file.path(portable_check_root, portable_files)
)))
copied_identity_path <- file.path(
  portable_check_root,
  "certification-identity.tsv"
)
stopifnot(isTRUE(check_figureforge_current_certification(
  repo_root,
  copied_identity_path
)$ok))
write(
  "tampered",
  file.path(portable_check_root, "live-mode-summary.csv"),
  append = TRUE
)
tampered_live_result <- check_figureforge_current_certification(
  repo_root,
  copied_identity_path
)
stopifnot(!isTRUE(tampered_live_result$ok))
stopifnot(any(c(
  "live_certification_summaries",
  "live_mode_summary_sha256"
) %in% tampered_live_result$failures))
latest_release_input_commit <- system2(
  "git",
  c(
    "-C",
    shQuote(repo_root),
    "rev-list",
    "--max-count=1",
    "HEAD",
    "--",
    "skills/figureforge",
    "scripts/run_figureforge_live_evals.sh",
    "scripts/run_figureforge_plotting_eval.sh",
    "scripts/run_figureforge_mode_evals.sh",
    "scripts/evaluate_figureforge_mode_probe.R",
    "scripts/lib/live_mode_evaluation.R",
    "scripts/verify_figureforge_v110.sh",
    "scripts/lib/release_certification.R",
    "scripts/check_figureforge_v110_certification.R",
    "scripts/write_figureforge_v110_certification_identity.R"
  ),
  stdout = TRUE
)
stopifnot(is.null(attr(latest_release_input_commit, "status")))
stopifnot(identical(
  as.character(portable_identity$certified_source_commit),
  latest_release_input_commit[[1L]]
))

message("v1.1.0 certification identity tests: PASS")
