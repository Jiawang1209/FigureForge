#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
script_path <- if (length(file_arg) > 0L) {
  normalizePath(sub("^--file=", "", file_arg[[1L]]), mustWork = TRUE)
} else {
  normalizePath(
    "tests/figureforge/test_v1_documentation.R",
    mustWork = TRUE
  )
}
repo_root <- normalizePath(
  file.path(dirname(script_path), "..", ".."),
  mustWork = TRUE
)

read_repo_document <- function(path) {
  paste(
    readLines(file.path(repo_root, path), warn = FALSE, encoding = "UTF-8"),
    collapse = "\n"
  )
}

english <- read_repo_document("README.md")
chinese <- read_repo_document("README.zh.md")
status <- read_repo_document("docs/figureforge-skill-mvp-status.md")
release_path <- file.path(
  repo_root,
  "docs",
  "figureforge-skill-v1-release.md"
)
stopifnot(file.exists(release_path))
release <- read_repo_document("docs/figureforge-skill-v1-release.md")

english_terms <- c(
  "1.0.1",
  "15 public cases",
  "24 synthetic stress fixtures",
  "doctor.R",
  "create_adaptation.R",
  "match_schema.R",
  "visual_qa.R",
  "package_skill.R",
  "review_required",
  "private corpus",
  "MCP",
  "planned"
)
stopifnot(all(vapply(
  english_terms,
  grepl,
  logical(1),
  x = english,
  fixed = TRUE
)))

chinese_terms <- c(
  "1.0.1",
  "15 个公开案例",
  "24 个合成压力测试夹具",
  "doctor.R",
  "create_adaptation.R",
  "match_schema.R",
  "visual_qa.R",
  "package_skill.R",
  "review_required",
  "私有案例库",
  "MCP",
  "planned"
)
stopifnot(all(vapply(
  chinese_terms,
  grepl,
  logical(1),
  x = chinese,
  fixed = TRUE
)))

combined <- paste(english, chinese, status, release, sep = "\n")
stopifnot(grepl("public-bar-grouped", release, fixed = TRUE))
stopifnot(grepl("public-multipanel", release, fixed = TRUE))
stopifnot(grepl("1.0.0", release, fixed = TRUE))
stopifnot(grepl("12", release, fixed = TRUE))
stopifnot(grepl("24", release, fixed = TRUE))
stopifnot(grepl("165", release, fixed = TRUE))
stopifnot(grepl("MCP", release, fixed = TRUE))

command_paths <- unique(regmatches(
  combined,
  gregexpr(
    "(skills/figureforge/scripts/[a-z0-9_-]+\\.R|examples/public-demo/run_demo\\.sh)",
    combined,
    perl = TRUE
  )
)[[1L]])
stopifnot(length(command_paths) >= 8L)
stopifnot(all(file.exists(file.path(repo_root, command_paths))))

message("v1 documentation tests: PASS")
