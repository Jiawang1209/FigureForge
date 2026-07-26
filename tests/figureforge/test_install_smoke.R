#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
script_path <- if (length(file_arg) > 0L) {
  normalizePath(sub("^--file=", "", file_arg[[1L]]), mustWork = TRUE)
} else {
  normalizePath(
    "tests/figureforge/test_install_smoke.R",
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

output_root <- tempfile("figureforge-install-smoke-")
dir.create(output_root, recursive = TRUE)
archive_path <- file.path(output_root, "figureforge-skill.tar.gz")
manifest_path <- file.path(output_root, "manifest.csv")
package <- package_figureforge_skill(
  repo_root,
  archive_path,
  manifest_path
)
verifier <- file.path(
  repo_root,
  "skills",
  "figureforge",
  "scripts",
  "verify_release.R"
)
stopifnot(file.exists(verifier))
verified_extract <- file.path(output_root, "verified-extract")
verify_log <- system2(
  "/usr/local/bin/Rscript",
  shQuote(c(
    verifier,
    "--archive", archive_path,
    "--manifest", manifest_path,
    "--extract-dir", verified_extract
  )),
  stdout = TRUE,
  stderr = TRUE
)
verify_status <- attr(verify_log, "status")
stopifnot(is.null(verify_status) || identical(as.integer(verify_status), 0L))
stopifnot(dir.exists(file.path(verified_extract, "figureforge")))

tampered_root <- file.path(output_root, "tampered-root")
dir.create(tampered_root)
tampered_extract <- system2(
  "tar",
  c("-xzf", shQuote(archive_path), "-C", shQuote(tampered_root))
)
stopifnot(identical(as.integer(tampered_extract), 0L))
write(
  "tampered",
  file.path(tampered_root, "figureforge", "SKILL.md"),
  append = TRUE
)
file_list <- file.path(output_root, "tampered-files.txt")
writeLines(package$manifest$package_path, file_list, useBytes = TRUE)
tampered_archive <- file.path(output_root, "tampered.tar.gz")
tampered_status <- system2(
  "tar",
  c(
    "-czf", shQuote(tampered_archive),
    "-C", shQuote(tampered_root),
    "-T", shQuote(file_list)
  )
)
stopifnot(identical(as.integer(tampered_status), 0L))
writeLines(
  paste(
    figureforge_sha256(tampered_archive),
    basename(tampered_archive),
    sep = "  "
  ),
  paste0(tampered_archive, ".sha256"),
  useBytes = TRUE
)
tampered_log <- suppressWarnings(system2(
  "/usr/local/bin/Rscript",
  shQuote(c(
    verifier,
    "--archive", tampered_archive,
    "--manifest", manifest_path
  )),
  stdout = TRUE,
  stderr = TRUE
))
stopifnot(!is.null(attr(tampered_log, "status")))
stopifnot(grepl(
  "checksum mismatch",
  paste(tampered_log, collapse = "\n"),
  ignore.case = TRUE
))

skill_root <- file.path(output_root, ".agents", "skills")
dir.create(skill_root, recursive = TRUE)
extract_status <- system2(
  "tar",
  c("-xzf", shQuote(archive_path), "-C", shQuote(skill_root))
)
stopifnot(identical(as.integer(extract_status), 0L))

installed <- file.path(skill_root, "figureforge")
stopifnot(file.exists(file.path(installed, "SKILL.md")))
stopifnot(file.exists(file.path(installed, "agents", "openai.yaml")))
stopifnot(file.exists(file.path(
  installed,
  "examples",
  "public-demo",
  "run_demo.sh"
)))
stopifnot(file.exists(file.path(
  installed,
  "scripts",
  "validate_case_trace.R"
)))
stopifnot(file.exists(file.path(
  installed,
  "lib",
  "case_trace_validation.R"
)))
stopifnot(!dir.exists(file.path(installed, "skills")))
stopifnot(all(startsWith(package$manifest$package_path, "figureforge/")))

run_installed_r <- function(script, arguments = character(0)) {
  output <- system2(
    "/usr/local/bin/Rscript",
    c(
      shQuote(file.path(installed, "scripts", script)),
      shQuote(arguments)
    ),
    stdout = TRUE,
    stderr = TRUE
  )
  status <- attr(output, "status")
  list(
    ok = is.null(status) || identical(as.integer(status), 0L),
    output = paste(output, collapse = "\n")
  )
}

doctor <- run_installed_r("doctor.R", c("--format", "text"))
stopifnot(doctor$ok)
search <- run_installed_r(
  "search_cases.R",
  c("--public", "--query", "scatter", "--limit", "1")
)
stopifnot(search$ok)

installed_trace <- file.path(output_root, "case-trace.yml")
installed_search_receipt <- file.path(output_root, "case-search.csv")
write.csv(
  data.frame(
    case_id = character(0),
    score_total = numeric(0),
    stringsAsFactors = FALSE
  ),
  installed_search_receipt,
  row.names = FALSE,
  fileEncoding = "UTF-8"
)
writeLines(c(
  "schema_version: 1",
  "generation_mode: general_fallback",
  "figureforge_version: 1.1.0",
  paste0("generated_script_sha256: ", paste(rep("0", 64L), collapse = "")),
  "claim: general_method",
  "search_query: unmatched installation smoke plot",
  "search_receipt_file: case-search.csv",
  paste0(
    "search_receipt_sha256: ",
    figureforge_sha256(installed_search_receipt)
  ),
  "fallback_reason: no suitable public case"
), installed_trace, useBytes = TRUE)
installed_trace_validation <- run_installed_r(
  "validate_case_trace.R",
  installed_trace
)
stopifnot(installed_trace_validation$ok)
stopifnot(grepl(
  "Verification level: structural",
  installed_trace_validation$output,
  fixed = TRUE
))

validation_status <- system2(
  "/usr/bin/python3",
  c(
    shQuote(file.path(
      "/Users",
      "liuyue",
      ".codex",
      "skills",
      ".system",
      "skill-creator",
      "scripts",
      "quick_validate.py"
    )),
    shQuote(installed)
  )
)
stopifnot(identical(as.integer(validation_status), 0L))

demo_output <- file.path(output_root, "demo-output")
demo_log <- system2(
  "sh",
  c(
    shQuote(file.path(
      installed,
      "examples",
      "public-demo",
      "run_demo.sh"
    )),
    shQuote(demo_output)
  ),
  stdout = TRUE,
  stderr = TRUE
)
demo_status <- attr(demo_log, "status")
stopifnot(is.null(demo_status) || identical(as.integer(demo_status), 0L))
stopifnot(file.info(file.path(demo_output, "output.pdf"))$size > 0L)
stopifnot(file.info(file.path(
  demo_output,
  "validation-output.pdf"
))$size > 0L)

message("install smoke tests: PASS")
