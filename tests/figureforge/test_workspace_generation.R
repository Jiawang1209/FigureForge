#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
script_path <- if (length(file_arg) > 0L) {
  normalizePath(sub("^--file=", "", file_arg[[1L]]), mustWork = TRUE)
} else {
  normalizePath(
    "tests/figureforge/test_workspace_generation.R",
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
  "metadata.R"
))
source(file.path(
  repo_root,
  "skills",
  "figureforge",
  "lib",
  "workspace_generation.R"
))

public_cases_dir <- file.path(
  repo_root,
  "skills",
  "figureforge",
  "public-cases"
)
private_cases_dir <- file.path(
  repo_root,
  "skills",
  "figureforge",
  "cases"
)
case_dir <- file.path(public_cases_dir, "public-scatter-fit")
input_dir <- tempfile("figureforge-workspace-input-")
dir.create(input_dir, recursive = TRUE)
input_path <- file.path(input_dir, "observations.csv")
writeLines(
  c(
    "predictor,response,group,label",
    "1,2.1,A,S1",
    "2,3.2,A,S2"
  ),
  input_path,
  useBytes = TRUE
)

source_paths <- c(
  file.path(case_dir, "plot.R"),
  file.path(case_dir, "data.csv"),
  input_path
)
hashes_before <- tools::md5sum(source_paths)
mtimes_before <- file.info(source_paths)$mtime

expect_rejected <- function(workspace, force_empty = FALSE) {
  error <- tryCatch(
    {
      create_adaptation_workspace(
        case_dir,
        input_path,
        workspace,
        force_empty = force_empty,
        protected_roots = c(public_cases_dir, private_cases_dir)
      )
      NULL
    },
    error = identity
  )
  stopifnot(inherits(error, "error"))
}

expect_rejected(case_dir)
expect_rejected(file.path(case_dir, "child"))
expect_rejected(dirname(case_dir))
expect_rejected(public_cases_dir)
expect_rejected(private_cases_dir)

nonempty <- tempfile("figureforge-workspace-nonempty-")
dir.create(nonempty, recursive = TRUE)
writeLines("preserve", file.path(nonempty, "existing.txt"))
expect_rejected(nonempty)
stopifnot(file.exists(file.path(nonempty, "existing.txt")))

symlink_parent <- tempfile("figureforge-workspace-symlink-")
dir.create(symlink_parent, recursive = TRUE)
symlink_path <- file.path(symlink_parent, "case-link")
stopifnot(file.symlink(case_dir, symlink_path))
expect_rejected(file.path(symlink_path, "child"))

workspace <- tempfile("figureforge-workspace-valid-")
result <- create_adaptation_workspace(
  case_dir,
  input_path,
  workspace,
  protected_roots = c(public_cases_dir, private_cases_dir)
)
stopifnot(isTRUE(result$ok))
stopifnot(identical(
  sort(list.files(workspace)),
  sort(c("adaptation.yml", "input.csv", "mapping.md", "plot.R", "qa.md"))
))
stopifnot(identical(
  readLines(file.path(workspace, "input.csv"), warn = FALSE),
  readLines(input_path, warn = FALSE)
))
qa_text <- paste(
  readLines(file.path(workspace, "qa.md"), warn = FALSE),
  collapse = "\n"
)
stopifnot(grepl("Status: review_required", qa_text, fixed = TRUE))
stopifnot(!grepl("Status: verified", qa_text, fixed = TRUE))
provenance <- parse_simple_metadata(
  file.path(workspace, "adaptation.yml")
)
stopifnot(identical(provenance$source_case_id, "public-scatter-fit"))
stopifnot(grepl(
  "^[0-9a-f]{64}$",
  provenance$source_script_sha256,
  perl = TRUE
))
stopifnot(identical(provenance$qa_status, "review_required"))
stopifnot(!file.exists(file.path(workspace, "data.csv")))

empty_workspace <- tempfile("figureforge-workspace-empty-")
dir.create(empty_workspace, recursive = TRUE)
expect_rejected(empty_workspace)
forced <- create_adaptation_workspace(
  case_dir,
  input_path,
  empty_workspace,
  force_empty = TRUE,
  protected_roots = c(public_cases_dir, private_cases_dir)
)
stopifnot(isTRUE(forced$ok))
stopifnot(file.exists(file.path(empty_workspace, "adaptation.yml")))

missing_mapping_workspace <- tempfile("figureforge-workspace-rollback-")
rollback_error <- tryCatch(
  {
    create_adaptation_workspace(
      case_dir,
      input_path,
      missing_mapping_workspace,
      mapping_path = file.path(input_dir, "missing.csv"),
      protected_roots = c(public_cases_dir, private_cases_dir)
    )
    NULL
  },
  error = identity
)
stopifnot(inherits(rollback_error, "error"))
stopifnot(!dir.exists(missing_mapping_workspace))

stopifnot(identical(hashes_before, tools::md5sum(source_paths)))
stopifnot(identical(mtimes_before, file.info(source_paths)$mtime))

creator_cli <- file.path(
  repo_root,
  "skills",
  "figureforge",
  "scripts",
  "create_adaptation.R"
)
cli_workspace <- tempfile("figureforge-workspace-cli-")
cli_log <- tempfile("figureforge-workspace-cli-", fileext = ".log")
cli_status <- system2(
  "/usr/local/bin/Rscript",
  shQuote(c(
    creator_cli,
    "--case", "public-scatter-fit",
    "--input", input_path,
    "--workspace", cli_workspace
  )),
  stdout = cli_log,
  stderr = cli_log
)
stopifnot(identical(as.integer(cli_status), 0L))
stopifnot(file.exists(file.path(cli_workspace, "adaptation.yml")))

message("workspace generation tests: PASS")
