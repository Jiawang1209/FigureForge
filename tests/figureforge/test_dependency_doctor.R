#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
script_path <- if (length(file_arg) > 0L) {
  normalizePath(sub("^--file=", "", file_arg[[1L]]), mustWork = TRUE)
} else {
  normalizePath(
    "tests/figureforge/test_dependency_doctor.R",
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
  "runtime_resolution.R"
))
source(file.path(
  repo_root,
  "skills",
  "figureforge",
  "lib",
  "dependency_doctor.R"
))

fixture_case <- file.path(
  repo_root,
  "tests",
  "fixtures",
  "figureforge",
  "metadata",
  "valid"
)
fake_runtime <- function(cli_path = NULL) {
  list(
    path = if (is.null(cli_path)) "/fake/Rscript" else cli_path,
    source = if (is.null(cli_path)) "path" else "cli",
    version = "4.5.0",
    version_output = "R scripting front-end version 4.5.0"
  )
}
fake_command <- function(name) name %in% c("sh", "git")
fake_package <- function(name) name %in% c("base", "ggplot2")

report <- run_doctor(
  case_dir = fixture_case,
  runtime_resolver = fake_runtime,
  command_detector = fake_command,
  package_detector = fake_package
)
stopifnot(setequal(
  unique(report$layer),
  c("runtime", "system", "required_r_package", "optional_r_package")
))
stopifnot(all(c(
  "check_id",
  "requirement",
  "detected_version",
  "detected_path",
  "resolution_source",
  "status",
  "remediation",
  "capability"
) %in% names(report)))
stopifnot(any(
  report$layer == "optional_r_package" &
    report$check_id == "r-package-ggrepel" &
    report$status == "warning"
))
stopifnot(doctor_exit_status(report, strict = TRUE) == 0L)

missing_required <- run_doctor(
  case_dir = fixture_case,
  runtime_resolver = fake_runtime,
  command_detector = fake_command,
  package_detector = function(name) identical(name, "base")
)
stopifnot(any(
  missing_required$layer == "required_r_package" &
    missing_required$status == "error"
))
stopifnot(doctor_exit_status(missing_required, strict = TRUE) == 1L)
stopifnot(doctor_exit_status(missing_required, strict = FALSE) == 0L)

json_path <- tempfile("figureforge-doctor-", fileext = ".json")
write_doctor_json(report, json_path)
python_status <- system2(
  "/usr/bin/python3",
  c(
    "-c",
    shQuote(paste(
      "import json,sys;",
      "x=json.load(open(sys.argv[1], encoding='utf-8'));",
      "assert x['schema_version']==1;",
      "assert len(x['checks'])>0"
    )),
    shQuote(json_path)
  )
)
stopifnot(identical(as.integer(python_status), 0L))

doctor_cli <- file.path(
  repo_root,
  "skills",
  "figureforge",
  "scripts",
  "doctor.R"
)
text_log <- tempfile("figureforge-doctor-", fileext = ".log")
text_status <- system2(
  "/usr/local/bin/Rscript",
  shQuote(c(doctor_cli, "--format", "text")),
  stdout = text_log,
  stderr = text_log
)
stopifnot(identical(as.integer(text_status), 0L))
stopifnot(grepl(
  "required_r_package",
  paste(readLines(text_log, warn = FALSE), collapse = "\n"),
  fixed = TRUE
))

json_log <- tempfile("figureforge-doctor-cli-", fileext = ".json")
json_status <- system2(
  "/usr/local/bin/Rscript",
  shQuote(c(
    doctor_cli,
    "--case", "public-scatter-fit",
    "--format", "json",
    "--rscript", "/usr/local/bin/Rscript"
  )),
  stdout = json_log,
  stderr = FALSE
)
stopifnot(identical(as.integer(json_status), 0L))
python_cli_status <- system2(
  "/usr/bin/python3",
  c(
    "-c",
    shQuote(paste(
      "import json,sys;",
      "x=json.load(open(sys.argv[1], encoding='utf-8'));",
      "assert x['schema_version']==1;",
      "runtime=[r for r in x['checks'] if r['check_id']=='runtime-rscript'][0];",
      "assert runtime['resolution_source']=='cli';",
      "assert runtime['detected_path'].startswith('/');"
    )),
    shQuote(json_log)
  )
)
stopifnot(identical(as.integer(python_cli_status), 0L))

message("dependency doctor tests: PASS")
