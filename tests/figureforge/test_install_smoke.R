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
