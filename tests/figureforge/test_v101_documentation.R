#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
script_path <- if (length(file_arg) > 0L) {
  normalizePath(sub("^--file=", "", file_arg[[1L]]), mustWork = TRUE)
} else {
  normalizePath(
    "tests/figureforge/test_v101_documentation.R",
    mustWork = TRUE
  )
}
repo_root <- normalizePath(
  file.path(dirname(script_path), "..", ".."),
  mustWork = TRUE
)

read_document <- function(relative_path) {
  path <- file.path(repo_root, relative_path)
  stopifnot(file.exists(path))
  paste(
    readLines(path, warn = FALSE, encoding = "UTF-8"),
    collapse = "\n"
  )
}

english <- read_document("README.md")
chinese <- read_document("README.zh.md")
release <- read_document("docs/figureforge-skill-v1.0.1-release.md")
status <- read_document("docs/figureforge-skill-mvp-status.md")
changelog <- read_document("CHANGELOG.md")

shared_terms <- c(
  "1.0.1",
  "FIGUREFORGE_RSCRIPT",
  "--rscript",
  "verify_release.R",
  "evaluate_skill.R",
  "run_figureforge_live_evals.sh"
)
for (document in list(release)) {
  stopifnot(all(vapply(
    shared_terms,
    grepl,
    logical(1),
    x = document,
    fixed = TRUE
  )))
}

english_terms <- c(
  "15 public cases",
  "MCP is planned and unimplemented"
)
stopifnot(all(vapply(
  english_terms,
  grepl,
  logical(1),
  x = english,
  fixed = TRUE
)))

chinese_terms <- c(
  "15 个公开案例",
  "MCP 状态为 planned 且尚未实现"
)
stopifnot(all(vapply(
  chinese_terms,
  grepl,
  logical(1),
  x = chinese,
  fixed = TRUE
)))

release_terms <- c(
  "15 public cases",
  "3 authentic open-data cases",
  "12 synthetic demonstration cases",
  "30 deterministic bilingual forward evaluations",
  "1/1",
  "10/10",
  "authentic-palmer-penguins-scatter",
  "authentic-usgs-earthquakes-bubble",
  "authentic-world-bank-population-timeseries",
  "MCP is planned and unimplemented",
  "codex/figureforge-skill-mvp"
)
stopifnot(all(vapply(
  release_terms,
  grepl,
  logical(1),
  x = release,
  fixed = TRUE
)))

combined_status <- paste(status, changelog, sep = "\n")
stopifnot(grepl("1.0.1", combined_status, fixed = TRUE))
stopifnot(grepl("15", combined_status, fixed = TRUE))
stopifnot(grepl("MCP", combined_status, fixed = TRUE))
stopifnot(grepl("planned", tolower(combined_status), fixed = TRUE))

for (document in list(english, chinese)) {
  lower <- tolower(document)
  stopifnot(!grepl(
    "all shipped case datasets are generated examples",
    lower,
    fixed = TRUE
  ))
  stopifnot(!grepl(
    "所有随包数据均为生成的示例",
    document,
    fixed = TRUE
  ))
  stopifnot(!grepl(
    "mcp server is implemented",
    lower,
    fixed = TRUE
  ))
  stopifnot(!grepl(
    "已实现 mcp",
    lower,
    fixed = TRUE
  ))
  stopifnot(!grepl(
    "https?://[^[:space:]]*/mcp",
    lower,
    perl = TRUE
  ))
}

verifier_path <- file.path(
  repo_root,
  "scripts",
  "verify_figureforge_v101.sh"
)
stopifnot(file.exists(verifier_path))
stopifnot(identical(
  as.integer(system2("sh", c("-n", shQuote(verifier_path)))),
  0L
))
verifier <- paste(
  readLines(verifier_path, warn = FALSE, encoding = "UTF-8"),
  collapse = "\n"
)
verifier_terms <- c(
  "FIGUREFORGE_RSCRIPT",
  "test_v1_acceptance.R",
  "validate_public_case.R",
  "run_stress_tests.R",
  "evaluate_skill.R",
  "doctor.R",
  "package_skill.R",
  ".sha256",
  "verify_release.R",
  "quick_validate.py",
  "validate_adaptation.R",
  "test_upgrade_compatibility.R",
  "FIGUREFORGE_RUN_LIVE_EVALS",
  "git diff --check",
  "FigureForge Skill v1.0.1 acceptance: PASS"
)
stopifnot(all(vapply(
  verifier_terms,
  grepl,
  logical(1),
  x = verifier,
  fixed = TRUE
)))
stopifnot(grepl(
  "installed-project/.agents/skills",
  verifier,
  fixed = TRUE
))

message("v1.0.1 documentation tests: PASS")
