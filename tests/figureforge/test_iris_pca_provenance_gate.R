#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
script_path <- if (length(file_arg) > 0L) {
  normalizePath(sub("^--file=", "", file_arg[[1L]]), mustWork = TRUE)
} else {
  normalizePath(
    "tests/figureforge/test_iris_pca_provenance_gate.R",
    mustWork = TRUE
  )
}
repo_root <- normalizePath(
  file.path(dirname(script_path), "..", ".."),
  mustWork = TRUE
)
demo_test <- file.path(
  repo_root,
  "tests",
  "figureforge",
  "test_iris_pca_demo.R"
)

assert_true <- function(condition, message) {
  if (!isTRUE(condition)) {
    stop(message, call. = FALSE)
  }
}

run_probe <- function(case_dir, require_private) {
  log_path <- tempfile("figureforge-iris-provenance-gate-", fileext = ".log")
  status <- system2(
    file.path(R.home("bin"), "Rscript"),
    c(
      shQuote(demo_test),
      "--figureforge-pca-trace-probe-only"
    ),
    stdout = log_path,
    stderr = log_path,
    env = c(
      paste0(
        "FIGUREFORGE_PCA_CASE_DIR=",
        shQuote(case_dir)
      ),
      paste0(
        "FIGUREFORGE_REQUIRE_PRIVATE_PCA_TRACE=",
        if (require_private) "1" else "0"
      )
    )
  )
  list(
    status = as.integer(status),
    output = paste(readLines(log_path, warn = FALSE), collapse = "\n")
  )
}

invalid_case_dir <- tempfile("figureforge-missing-private-pca-case-")
assert_true(
  !file.exists(invalid_case_dir),
  "Invalid case-dir probe path must not exist"
)
invalid_configured <- run_probe(invalid_case_dir, require_private = FALSE)
assert_true(
  !identical(invalid_configured$status, 0L),
  paste(
    "A configured but invalid FIGUREFORGE_PCA_CASE_DIR must fail, output:",
    invalid_configured$output
  )
)
assert_true(
  grepl(
    "FIGUREFORGE_PCA_CASE_DIR.*configured.*not.*directory",
    invalid_configured$output,
    ignore.case = TRUE,
    perl = TRUE
  ),
  paste(
    "Invalid configured case-dir failure must explain the problem, output:",
    invalid_configured$output
  )
)

required_without_path <- run_probe("", require_private = TRUE)
assert_true(
  !identical(required_without_path$status, 0L),
  paste(
    "FIGUREFORGE_REQUIRE_PRIVATE_PCA_TRACE=1 without a case dir must fail, output:",
    required_without_path$output
  )
)
assert_true(
  grepl(
    "FIGUREFORGE_REQUIRE_PRIVATE_PCA_TRACE=1.*requires.*FIGUREFORGE_PCA_CASE_DIR",
    required_without_path$output,
    ignore.case = TRUE,
    perl = TRUE
  ),
  paste(
    "Require-without-path failure must explain the required variable, output:",
    required_without_path$output
  )
)

public_probe <- run_probe("", require_private = FALSE)
assert_true(
  identical(public_probe$status, 0L),
  paste("Default public structural probe must pass, output:", public_probe$output)
)
assert_true(
  grepl("private strict skipped", public_probe$output, fixed = TRUE) &&
    grepl("structural", public_probe$output, ignore.case = TRUE),
  paste(
    "Default public probe must explicitly report private strict skipped and structural validation, output:",
    public_probe$output
  )
)

configured_case_dir <- Sys.getenv("FIGUREFORGE_PCA_CASE_DIR", unset = "")
require_configured <- identical(
  Sys.getenv("FIGUREFORGE_REQUIRE_PRIVATE_PCA_TRACE", unset = "0"),
  "1"
)
if (require_configured) {
  assert_true(
    dir.exists(configured_case_dir),
    "The active required provenance gate must provide a valid case directory"
  )
  strict_probe <- run_probe(configured_case_dir, require_private = TRUE)
  assert_true(
    identical(strict_probe$status, 0L) &&
      grepl("Verification level: strict", strict_probe$output, fixed = TRUE),
    paste(
      "Required provenance with a valid case dir must pass at exactly strict level, output:",
      strict_probe$output
    )
  )

  spaced_parent <- tempfile("figureforge private PCA case with spaces ")
  dir.create(spaced_parent)
  spaced_case_dir <- file.path(spaced_parent, "20230925_PCA")
  dir.create(spaced_case_dir)
  case_entries <- list.files(
    configured_case_dir,
    all.files = TRUE,
    full.names = TRUE,
    no.. = TRUE
  )
  assert_true(
    length(case_entries) > 0L &&
      all(file.copy(
        case_entries,
        spaced_case_dir,
        recursive = TRUE,
        copy.mode = TRUE,
        copy.date = TRUE
      )),
    "Could not copy the strict case into the spaced regression directory"
  )
  spaced_strict_probe <- run_probe(
    spaced_case_dir,
    require_private = TRUE
  )
  assert_true(
    identical(spaced_strict_probe$status, 0L) &&
      grepl(
        "Verification level: strict",
        spaced_strict_probe$output,
        fixed = TRUE
      ),
    paste(
      "A valid strict case dir containing spaces must pass, output:",
      spaced_strict_probe$output
    )
  )
}

message("Iris PCA provenance gate tests: PASS")
