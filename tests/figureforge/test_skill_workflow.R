#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
script_path <- if (length(file_arg) > 0) {
  normalizePath(sub("^--file=", "", file_arg[[1]]), mustWork = TRUE)
} else {
  normalizePath("tests/figureforge/test_skill_workflow.R", mustWork = TRUE)
}
repo_root <- normalizePath(file.path(dirname(script_path), "..", ".."), mustWork = TRUE)

source(file.path(repo_root, "skills", "figureforge", "lib", "case_audit.R"))
source(file.path(repo_root, "skills", "figureforge", "lib", "case_validation.R"))
source(file.path(repo_root, "skills", "figureforge", "lib", "case_catalog.R"))
source(file.path(
  repo_root,
  "skills",
  "figureforge",
  "lib",
  "adaptation_validation.R"
))
source(file.path(
  repo_root,
  "tests",
  "figureforge",
  "helpers",
  "materialize_case_fixtures.R"
))

fixtures_dir <- materialize_case_fixtures(repo_root)
catalog <- build_case_catalog(fixtures_dir)

stopifnot(!"_template" %in% catalog$case_id)
stopifnot(nrow(catalog) == 6L)
for (field in c(
  "case_id",
  "title",
  "chart_type",
  "chart_type_zh",
  "aliases",
  "best_for",
  "required_columns",
  "required_r_packages",
  "completion_status",
  "distribution_status",
  "search_text"
)) {
  stopifnot(field %in% names(catalog))
}

public_row <- catalog[catalog$case_id == "authentic-public", , drop = FALSE]
stopifnot(identical(public_row$required_columns, "category, value"))
stopifnot(identical(public_row$required_r_packages, "base"))
stopifnot(identical(public_row$completion_status, "qa_verified"))
stopifnot(identical(public_row$distribution_status, "public_ready"))

private_row <- catalog[catalog$case_id == "authentic-private", , drop = FALSE]
stopifnot(identical(private_row$distribution_status, "private_only"))

zh_results <- search_case_catalog(catalog, "柱形图", limit = 3L)
stopifnot(nrow(zh_results) >= 1L)
stopifnot(identical(zh_results$case_id[[1]], "authentic-public"))

schema_results <- search_case_catalog(catalog, "category value", limit = 3L)
stopifnot(nrow(schema_results) >= 1L)
stopifnot(identical(schema_results$case_id[[1]], "authentic-public"))

verified_results <- search_case_catalog(
  catalog,
  "bar",
  limit = 3L,
  completed_only = TRUE
)
stopifnot(nrow(verified_results) == 1L)
stopifnot(identical(verified_results$case_id[[1]], "authentic-public"))

dependency_report <- check_case_dependencies(
  file.path(fixtures_dir, "authentic-public")
)
stopifnot(dependency_report$package[[1]] == "base")
stopifnot(isTRUE(dependency_report$installed[[1]]))

missing_dependency <- check_r_packages("figureforgeDefinitelyMissingPackage")
stopifnot(!isTRUE(missing_dependency$installed[[1]]))

index_path <- tempfile("figureforge-case-index-", fileext = ".csv")
index_script <- file.path(
  repo_root,
  "skills",
  "figureforge",
  "scripts",
  "index_cases.R"
)
index_status <- system2(
  "/usr/local/bin/Rscript",
  shQuote(c(index_script, fixtures_dir, index_path))
)
stopifnot(identical(as.integer(index_status), 0L))
written_catalog <- read.csv(
  index_path,
  stringsAsFactors = FALSE,
  check.names = FALSE
)
stopifnot(identical(written_catalog$case_id, sort(written_catalog$case_id)))
stopifnot("completion_status" %in% names(written_catalog))

search_script <- file.path(
  repo_root,
  "skills",
  "figureforge",
  "scripts",
  "search_cases.R"
)
search_log <- tempfile("figureforge-search-", fileext = ".log")
search_status <- system2(
  "/usr/local/bin/Rscript",
  shQuote(c(
    search_script,
    "--cases-dir", fixtures_dir,
    "--query", "柱形图",
    "--limit", "2"
  )),
  stdout = search_log,
  stderr = search_log
)
stopifnot(identical(as.integer(search_status), 0L))
search_output <- paste(readLines(search_log, warn = FALSE), collapse = "\n")
stopifnot(grepl("authentic-public", search_output, fixed = TRUE))

dependency_script <- file.path(
  repo_root,
  "skills",
  "figureforge",
  "scripts",
  "check_dependencies.R"
)
dependency_log <- tempfile("figureforge-dependencies-", fileext = ".log")
dependency_status <- system2(
  "/usr/local/bin/Rscript",
  shQuote(c(
    dependency_script,
    "--case-dir",
    file.path(fixtures_dir, "authentic-public"),
    "--strict"
  )),
  stdout = dependency_log,
  stderr = dependency_log
)
stopifnot(identical(as.integer(dependency_status), 0L))
dependency_output <- paste(
  readLines(dependency_log, warn = FALSE),
  collapse = "\n"
)
stopifnot(grepl("base", dependency_output, fixed = TRUE))
stopifnot(grepl("installed", dependency_output, fixed = TRUE))

render_script <- file.path(
  repo_root,
  "skills",
  "figureforge",
  "scripts",
  "render_case.R"
)
render_output <- file.path(
  tempfile("figureforge-render-output-"),
  "adapted.pdf"
)
render_log <- tempfile("figureforge-render-", fileext = ".log")
render_status <- system2(
  "/usr/local/bin/Rscript",
  shQuote(c(
    render_script,
    file.path(fixtures_dir, "authentic-public"),
    "--input",
    file.path(fixtures_dir, "authentic-public", "data.csv"),
    "--output",
    render_output,
    "--rscript",
    "/usr/local/bin/Rscript"
  )),
  stdout = render_log,
  stderr = render_log
)
stopifnot(identical(as.integer(render_status), 0L))
stopifnot(is_nonempty_file(render_output))
render_message <- paste(readLines(render_log, warn = FALSE), collapse = "\n")
stopifnot(grepl("Render succeeded", render_message, fixed = TRUE))
stopifnot(grepl(normalizePath(render_output), render_message, fixed = TRUE))

adaptation_dir <- file.path(
  repo_root,
  "tests",
  "fixtures",
  "figureforge",
  "adaptations",
  "valid"
)
adaptation_output <- file.path(
  tempfile("figureforge-adaptation-output-"),
  "output.pdf"
)
adaptation_result <- validate_adaptation(
  adaptation_dir,
  render_output = adaptation_output,
  rscript = "/usr/local/bin/Rscript"
)
stopifnot(isTRUE(adaptation_result$ok))
stopifnot(is_nonempty_file(adaptation_output))

adaptation_script <- file.path(
  repo_root,
  "skills",
  "figureforge",
  "scripts",
  "validate_adaptation.R"
)
adaptation_cli_output <- file.path(
  tempfile("figureforge-adaptation-cli-"),
  "output.pdf"
)
adaptation_log <- tempfile("figureforge-adaptation-", fileext = ".log")
adaptation_status <- system2(
  "/usr/local/bin/Rscript",
  shQuote(c(
    adaptation_script,
    adaptation_dir,
    "--render",
    "--output",
    adaptation_cli_output,
    "--rscript",
    "/usr/local/bin/Rscript"
  )),
  stdout = adaptation_log,
  stderr = adaptation_log
)
stopifnot(identical(as.integer(adaptation_status), 0L))
stopifnot(is_nonempty_file(adaptation_cli_output))
adaptation_message <- paste(
  readLines(adaptation_log, warn = FALSE),
  collapse = "\n"
)
stopifnot(grepl("Adaptation validation OK", adaptation_message, fixed = TRUE))

read_repo_text <- function(relative_path) {
  paste(
    readLines(file.path(repo_root, relative_path), warn = FALSE),
    collapse = "\n"
  )
}
skill_text <- read_repo_text("skills/figureforge/SKILL.md")
readme_en <- read_repo_text("README.md")
readme_zh <- read_repo_text("README.zh.md")
gallery_reference <- read_repo_text(
  "skills/figureforge/references/gallery-index.md"
)
blocker_reference <- read_repo_text(
  "skills/figureforge/references/blocker-contract.md"
)

for (document in list(skill_text, readme_en, readme_zh)) {
  stopifnot(grepl("validate_blocker.R", document, fixed = TRUE))
  stopifnot(grepl("plan_case_batches.R", document, fixed = TRUE))
  stopifnot(grepl("terminal_outcome", document, fixed = TRUE))
  stopifnot(grepl("blocked_source_missing", document, fixed = TRUE))
}
for (document in list(gallery_reference, blocker_reference)) {
  stopifnot(grepl("terminal_outcome", document, fixed = TRUE))
  stopifnot(grepl("blocked_source_missing", document, fixed = TRUE))
}
for (document in list(skill_text, blocker_reference)) {
  stopifnot(grepl(
    "verified QA and a valid blocker cannot coexist",
    document,
    fixed = TRUE
  ))
}

message("skill workflow tests: PASS")
