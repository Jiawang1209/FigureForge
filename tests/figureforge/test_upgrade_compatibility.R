#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
script_path <- if (length(file_arg) > 0L) {
  normalizePath(sub("^--file=", "", file_arg[[1L]]), mustWork = TRUE)
} else {
  normalizePath(
    "tests/figureforge/test_upgrade_compatibility.R",
    mustWork = TRUE
  )
}
repo_root <- normalizePath(
  file.path(dirname(script_path), "..", ".."),
  mustWork = TRUE
)
for (library_file in c(
  "distribution_validation.R",
  "checksums.R",
  "release_packaging.R"
)) {
  source(file.path(
    repo_root,
    "skills",
    "figureforge",
    "lib",
    library_file
  ))
}

target_version <- readLines(
  file.path(repo_root, "skills", "figureforge", "VERSION"),
  warn = FALSE,
  encoding = "UTF-8"
)
stopifnot(length(target_version) == 1L)
stopifnot(nzchar(target_version))

baseline_commit <- "fe00d2a"
fixture_path <- file.path(
  repo_root,
  "tests",
  "fixtures",
  "figureforge",
  "releases",
  "v1.0.0-manifest.csv"
)
baseline_manifest <- read.csv(
  fixture_path,
  stringsAsFactors = FALSE,
  check.names = FALSE
)
stopifnot(nrow(baseline_manifest) > 100L)
stopifnot(all(baseline_manifest$source_commit == baseline_commit))
stopifnot(!anyDuplicated(baseline_manifest$package_path))
stopifnot(all(startsWith(
  baseline_manifest$package_path,
  "figureforge/"
)))

test_root <- tempfile("figureforge-upgrade-")
dir.create(test_root, recursive = TRUE)
baseline_tar <- file.path(test_root, "v1.0.0-source.tar")
archive_status <- system2(
  "git",
  c(
    "-C", shQuote(repo_root),
    "archive",
    "--format=tar",
    paste0("--output=", shQuote(baseline_tar)),
    baseline_commit,
    "skills/figureforge"
  ),
  stdout = TRUE,
  stderr = TRUE
)
stopifnot(is.null(attr(archive_status, "status")))
baseline_export <- file.path(test_root, "baseline-export")
dir.create(baseline_export)
extract_status <- system2(
  "tar",
  c("-xf", shQuote(baseline_tar), "-C", shQuote(baseline_export))
)
stopifnot(identical(as.integer(extract_status), 0L))

baseline_sources <- file.path(
  baseline_export,
  baseline_manifest$source_path
)
stopifnot(all(file.exists(baseline_sources)))
stopifnot(identical(
  unname(vapply(baseline_sources, figureforge_sha256, character(1))),
  baseline_manifest$sha256
))
stopifnot(identical(
  as.numeric(file.info(baseline_sources)$size),
  as.numeric(baseline_manifest$bytes)
))

skill_root <- file.path(test_root, ".agents", "skills")
installed <- file.path(skill_root, "figureforge")
dir.create(installed, recursive = TRUE)
baseline_skill <- file.path(
  baseline_export,
  "skills",
  "figureforge"
)
copied <- file.copy(
  list.files(
    baseline_skill,
    full.names = TRUE,
    all.files = TRUE,
    no.. = TRUE
  ),
  installed,
  recursive = TRUE,
  copy.mode = TRUE,
  copy.date = TRUE
)
stopifnot(all(copied))
stopifnot(identical(
  readLines(
    file.path(installed, "VERSION"),
    warn = FALSE,
    encoding = "UTF-8"
  ),
  "1.0.0"
))

adaptation <- file.path(test_root, "external-adaptation")
dir.create(adaptation)
baseline_case <- file.path(
  installed,
  "public-cases",
  "public-timeseries-band"
)
stopifnot(file.copy(
  file.path(baseline_case, "data.csv"),
  file.path(adaptation, "input.csv")
))
stopifnot(file.copy(
  file.path(baseline_case, "plot.R"),
  file.path(adaptation, "plot.R")
))
writeLines(
  c(
    "# Preserved v1.0.0 Adaptation",
    "",
    "## Selected Case",
    "",
    "public-timeseries-band from FigureForge 1.0.0",
    "",
    "## Field Mapping",
    "",
    "- time -> time",
    "- estimate -> estimate",
    "- lower -> lower",
    "- upper -> upper",
    "- group -> group",
    "",
    "## Transformations",
    "",
    "- identity mappings only",
    "",
    "## Required R Packages",
    "",
    "- ggplot2",
    "",
    "## Run Command",
    "",
    "Rscript plot.R input.csv output.pdf"
  ),
  file.path(adaptation, "mapping.md"),
  useBytes = TRUE
)
writeLines(
  c(
    "# Preserved Adaptation QA",
    "",
    "Status: review_required",
    "",
    "## Data",
    "Preserved v1.0.0 fixture.",
    "",
    "## Visual Fidelity",
    "Requires human review.",
    "",
    "## Reproducibility",
    "Validated after upgrade.",
    "",
    "## Export",
    "PDF.",
    "",
    "## Limits",
    "Synthetic demonstration only."
  ),
  file.path(adaptation, "qa.md"),
  useBytes = TRUE
)
adaptation_input <- file.path(adaptation, "input.csv")
adaptation_mapping <- file.path(adaptation, "mapping.md")
before_input_hash <- figureforge_sha256(adaptation_input)
before_mapping_hash <- figureforge_sha256(adaptation_mapping)

release_archive <- file.path(
  test_root,
  paste0("figureforge-skill-", target_version, ".tar.gz")
)
release_manifest <- file.path(
  test_root,
  paste0("figureforge-skill-", target_version, "-manifest.csv")
)
current_package <- package_figureforge_skill(
  repo_root,
  release_archive,
  release_manifest
)
staging_root <- file.path(
  skill_root,
  paste0(".figureforge-stage-v", target_version)
)
verified <- verify_figureforge_release(
  release_archive,
  release_manifest,
  extract_dir = staging_root
)
staged_skill <- file.path(staging_root, "figureforge")

replace_installed_skill <- function(target, stage, expected_version) {
  parent <- normalizePath(dirname(target), mustWork = TRUE)
  target <- normalizePath(target, mustWork = TRUE)
  stage <- normalizePath(stage, mustWork = TRUE)
  if (!identical(basename(target), "figureforge") ||
      !identical(dirname(target), parent)) {
    stop("Upgrade target must be the exact figureforge Skill directory")
  }
  if (nzchar(Sys.readlink(target)) || nzchar(Sys.readlink(stage))) {
    stop("Upgrade target and stage must not be symlinks")
  }
  stage_version <- readLines(
    file.path(stage, "VERSION"),
    warn = FALSE,
    encoding = "UTF-8"
  )
  if (!identical(stage_version, expected_version)) {
    stop("Staged FigureForge VERSION must be ", expected_version)
  }
  validator <- file.path(
    "/Users",
    "liuyue",
    ".codex",
    "skills",
    ".system",
    "skill-creator",
    "scripts",
    "quick_validate.py"
  )
  validation <- system2(
    "/usr/bin/python3",
    c(shQuote(validator), shQuote(stage)),
    stdout = TRUE,
    stderr = TRUE
  )
  validation_status <- attr(validation, "status")
  if (!is.null(validation_status) && validation_status != 0L) {
    stop("Staged FigureForge failed official validation")
  }

  backup <- file.path(parent, ".figureforge-backup-v1.0.0")
  if (file.exists(backup) || dir.exists(backup)) {
    stop("Target-specific upgrade backup already exists")
  }
  if (!file.rename(target, backup)) {
    stop("Unable to move current FigureForge installation to backup")
  }
  installed_stage <- FALSE
  on.exit({
    if (!installed_stage && !dir.exists(target) && dir.exists(backup)) {
      file.rename(backup, target)
    }
  }, add = TRUE)
  if (!file.rename(stage, target)) {
    stop("Unable to move staged FigureForge installation into place")
  }
  installed_stage <- TRUE
  if (!identical(
    readLines(
      file.path(target, "VERSION"),
      warn = FALSE,
      encoding = "UTF-8"
    ),
    expected_version
  )) {
    file.rename(target, stage)
    installed_stage <- FALSE
    stop("Installed FigureForge version check failed")
  }
  unlink(backup, recursive = TRUE)
  if (dir.exists(backup)) {
    stop("Target-specific upgrade backup cleanup failed")
  }
  invisible(target)
}

replace_installed_skill(installed, staged_skill, target_version)
stopifnot(identical(
  readLines(
    file.path(installed, "VERSION"),
    warn = FALSE,
    encoding = "UTF-8"
  ),
  target_version
))
stopifnot(identical(
  before_input_hash,
  figureforge_sha256(adaptation_input)
))
stopifnot(identical(
  before_mapping_hash,
  figureforge_sha256(adaptation_mapping)
))

installed_relative_files <- paste0(
  "figureforge/",
  release_normalize_relative(list.files(
    installed,
    recursive = TRUE,
    all.files = TRUE,
    no.. = TRUE,
    include.dirs = FALSE
  ))
)
v100_package_paths <- baseline_manifest$package_path
current_package_paths <- current_package$manifest$package_path
stopifnot(!any(
  setdiff(v100_package_paths, current_package_paths) %in%
    installed_relative_files
))
stopifnot(setequal(installed_relative_files, current_package_paths))

run_installed <- function(script, arguments = character(0)) {
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

doctor <- run_installed("doctor.R", c("--format", "text"))
stopifnot(doctor$ok)
search <- run_installed(
  "search_cases.R",
  c("--public", "--query", "time series", "--limit", "1")
)
stopifnot(search$ok)
stopifnot(grepl("public-timeseries-band", search$output, fixed = TRUE))

validation_output <- file.path(
  test_root,
  "preserved-adaptation-validation.pdf"
)
adaptation_validation <- run_installed(
  "validate_adaptation.R",
  c(
    adaptation,
    "--render",
    "--output", validation_output,
    "--rscript", "/usr/local/bin/Rscript"
  )
)
stopifnot(adaptation_validation$ok)
stopifnot(file.exists(validation_output))
stopifnot(file.info(validation_output)$size > 0L)
stopifnot(!startsWith(normalizePath(validation_output), normalizePath(installed)))
stopifnot(!dir.exists(file.path(
  skill_root,
  ".figureforge-backup-v1.0.0"
)))

message("upgrade compatibility tests: PASS")
