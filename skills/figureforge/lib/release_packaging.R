release_normalize_relative <- function(path) {
  gsub("\\\\", "/", path)
}

release_list_files <- function(root) {
  if (!dir.exists(root)) return(character(0))
  paths <- list.files(
    root,
    recursive = TRUE,
    all.files = TRUE,
    no.. = TRUE,
    include.dirs = FALSE,
    full.names = TRUE
  )
  paths[file.exists(paths) & !dir.exists(paths)]
}

release_sha256 <- function(path) {
  output <- system2(
    "shasum",
    c("-a", "256", shQuote(path)),
    stdout = TRUE,
    stderr = TRUE
  )
  status <- attr(output, "status")
  if (!is.null(status) && status != 0L) {
    stop("Unable to calculate SHA-256 for: ", path)
  }
  hash <- strsplit(output[[1L]], "\\s+", perl = TRUE)[[1L]][[1L]]
  if (!grepl("^[0-9a-f]{64}$", hash, perl = TRUE)) {
    stop("Invalid SHA-256 output for: ", path)
  }
  hash
}

release_public_case_files <- function(repo_root) {
  public_root <- file.path(
    repo_root,
    "skills",
    "figureforge",
    "public-cases"
  )
  case_dirs <- list.dirs(public_root, recursive = FALSE, full.names = TRUE)
  case_dirs <- sort(case_dirs[nzchar(basename(case_dirs))])
  files <- character(0)
  for (case_dir in case_dirs) {
    result <- validate_distribution(case_dir)
    if (!isTRUE(result$ok)) {
      stop(
        "Public case failed distribution validation: ",
        basename(case_dir),
        " (",
        paste(result$failed_checks, collapse = ", "),
        ")"
      )
    }
    files <- c(files, file.path(case_dir, result$assets))
  }
  files
}

release_candidate_files <- function(repo_root) {
  repo_root <- normalizePath(repo_root, mustWork = TRUE)
  fixed <- file.path(
    repo_root,
    c(
      "README.md",
      "README.zh.md",
      "CHANGELOG.md",
      "LICENSE",
      "skills/figureforge/VERSION",
      "skills/figureforge/SKILL.md"
    )
  )
  recursive_roots <- file.path(
    repo_root,
    "skills",
    "figureforge",
    c("agents", "lib", "references", "schemas", "scripts")
  )
  template <- file.path(
    repo_root,
    "skills",
    "figureforge",
    "cases",
    "_template",
    c("case.md", "data.csv", "plot.R")
  )
  candidates <- c(
    fixed,
    unlist(lapply(recursive_roots, release_list_files), use.names = FALSE),
    release_public_case_files(repo_root),
    template
  )
  candidates <- unique(candidates[file.exists(candidates)])
  candidates <- candidates[!dir.exists(candidates)]
  relative <- release_normalize_relative(sub(
    paste0("^", gsub(
      "([][{}()+*^$|\\\\?.])",
      "\\\\\\1",
      repo_root
    ), "/"),
    "",
    candidates,
    perl = TRUE
  ))
  excluded <- grepl(
    "(^|/)case-index\\.csv$|(^|/)case-status\\.csv$|(^|/)(reproduction|original)\\.",
    relative,
    perl = TRUE
  ) |
    grepl("^outputs/|\\.log$", relative, perl = TRUE) |
    grepl("^skills/figureforge/cases/(?!_template/)", relative, perl = TRUE)
  sort(relative[!excluded])
}

build_release_manifest <- function(repo_root, output_path = NULL) {
  repo_root <- normalizePath(repo_root, mustWork = TRUE)
  paths <- release_candidate_files(repo_root)
  if (length(paths) == 0L) stop("Release allowlist resolved to no files")
  absolute <- file.path(repo_root, paths)
  symlinks <- nzchar(Sys.readlink(absolute))
  if (any(symlinks)) {
    stop("Release files must not be symlinks: ", paths[which(symlinks)[[1L]]])
  }
  manifest <- data.frame(
    path = paths,
    sha256 = vapply(absolute, release_sha256, character(1)),
    bytes = as.numeric(file.info(absolute)$size),
    stringsAsFactors = FALSE
  )
  if (any(!is.finite(manifest$bytes) | manifest$bytes <= 0)) {
    stop("Release files must be non-empty")
  }
  if (!is.null(output_path)) {
    dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
    write.csv(
      manifest,
      output_path,
      row.names = FALSE,
      fileEncoding = "UTF-8"
    )
  }
  manifest
}

package_figureforge_skill <- function(
  repo_root,
  archive_path,
  manifest_path = NULL
) {
  repo_root <- normalizePath(repo_root, mustWork = TRUE)
  manifest <- build_release_manifest(repo_root, manifest_path)
  archive_parent <- dirname(archive_path)
  dir.create(archive_parent, recursive = TRUE, showWarnings = FALSE)
  archive_path <- file.path(
    normalizePath(archive_parent, mustWork = TRUE),
    basename(archive_path)
  )
  if (file.exists(archive_path)) unlink(archive_path)
  file_list <- tempfile("figureforge-release-files-", fileext = ".txt")
  on.exit(unlink(file_list), add = TRUE)
  writeLines(manifest$path, file_list, useBytes = TRUE)
  output <- system2(
    "tar",
    c(
      "-czf",
      shQuote(archive_path),
      "-C",
      shQuote(repo_root),
      "-T",
      shQuote(file_list)
    ),
    stdout = TRUE,
    stderr = TRUE
  )
  status <- attr(output, "status")
  if (!is.null(status) && status != 0L) {
    stop("Release archive failed: ", paste(output, collapse = "\n"))
  }
  if (!file.exists(archive_path) || file.info(archive_path)$size <= 0L) {
    stop("Release archive is missing or empty")
  }
  list(
    archive_path = archive_path,
    manifest = manifest,
    manifest_path = manifest_path
  )
}
