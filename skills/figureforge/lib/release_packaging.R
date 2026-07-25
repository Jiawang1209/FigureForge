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
  figureforge_sha256(path)
}

release_package_path <- function(source_path) {
  source_path <- release_normalize_relative(source_path)
  if (startsWith(source_path, "skills/figureforge/")) {
    return(sub("^skills/figureforge/", "figureforge/", source_path))
  }
  if (startsWith(source_path, "examples/public-demo/")) {
    return(sub(
      "^examples/public-demo/",
      "figureforge/examples/public-demo/",
      source_path
    ))
  }
  stop("No install mapping for release source: ", source_path)
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
  public_demo <- release_list_files(file.path(
    repo_root,
    "examples",
    "public-demo"
  ))
  candidates <- c(
    fixed,
    unlist(lapply(recursive_roots, release_list_files), use.names = FALSE),
    release_public_case_files(repo_root),
    template,
    public_demo
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
    source_path = paths,
    package_path = vapply(paths, release_package_path, character(1)),
    sha256 = vapply(absolute, release_sha256, character(1)),
    bytes = as.numeric(file.info(absolute)$size),
    stringsAsFactors = FALSE
  )
  manifest <- manifest[
    order(manifest$package_path, manifest$source_path),
    ,
    drop = FALSE
  ]
  if (anyDuplicated(manifest$package_path)) {
    stop("Release package paths must be unique")
  }
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

release_validate_member_paths <- function(paths, label = "archive") {
  normalized <- release_normalize_relative(paths)
  if (any(!nzchar(normalized))) {
    stop("Release ", label, " contains an empty member path")
  }
  if (anyDuplicated(normalized)) {
    stop("Release ", label, " contains duplicate member paths")
  }
  absolute <- startsWith(normalized, "/") |
    grepl("^[A-Za-z]:/", normalized, perl = TRUE)
  if (any(absolute)) {
    stop("Release ", label, " contains an absolute member path")
  }
  components <- strsplit(normalized, "/", fixed = TRUE)
  traversal <- vapply(
    components,
    function(parts) any(parts %in% c("", ".", "..")),
    logical(1)
  )
  if (any(traversal)) {
    stop("Release ", label, " contains parent-traversal or invalid paths")
  }
  if (any(!startsWith(normalized, "figureforge/"))) {
    stop("Release ", label, " members must be rooted at figureforge/")
  }
  normalized
}

read_release_manifest <- function(path) {
  if (!file.exists(path)) stop("Release manifest does not exist: ", path)
  manifest <- read.csv(
    path,
    stringsAsFactors = FALSE,
    check.names = FALSE,
    na.strings = character(0),
    fileEncoding = "UTF-8"
  )
  required <- c("source_path", "package_path", "sha256", "bytes")
  missing <- setdiff(required, names(manifest))
  if (length(missing) > 0L) {
    stop("Release manifest is missing columns: ", paste(missing, collapse = ", "))
  }
  manifest <- manifest[, required, drop = FALSE]
  manifest$package_path <- release_validate_member_paths(
    manifest$package_path,
    "manifest"
  )
  if (any(!grepl("^[0-9a-f]{64}$", manifest$sha256, perl = TRUE))) {
    stop("Release manifest contains invalid SHA-256 values")
  }
  if (any(!is.finite(manifest$bytes) | manifest$bytes <= 0)) {
    stop("Release manifest contains missing or empty members")
  }
  manifest
}

verify_release_sidecar <- function(archive_path) {
  sidecar_path <- paste0(archive_path, ".sha256")
  if (!file.exists(sidecar_path)) {
    stop("Release archive checksum sidecar is missing: ", sidecar_path)
  }
  line <- readLines(
    sidecar_path,
    warn = FALSE,
    encoding = "UTF-8"
  )
  expected_pattern <- paste0(
    "^([0-9a-f]{64})  ",
    gsub(
      "([][{}()+*^$|\\\\?.])",
      "\\\\\\1",
      basename(archive_path)
    ),
    "$"
  )
  if (length(line) != 1L || !grepl(expected_pattern, line, perl = TRUE)) {
    stop("Release archive checksum sidecar has an invalid format")
  }
  expected <- sub("  .*$", "", line)
  actual <- figureforge_sha256(archive_path)
  if (!identical(expected, actual)) {
    stop("Release archive checksum mismatch")
  }
  sidecar_path
}

validate_release_archive_members <- function(
  archive_members,
  expected_members,
  member_types
) {
  archive_members <- release_validate_member_paths(
    archive_members,
    "archive"
  )
  expected_members <- release_validate_member_paths(
    expected_members,
    "manifest"
  )
  missing <- setdiff(expected_members, archive_members)
  extra <- setdiff(archive_members, expected_members)
  if (length(missing) > 0L) {
    stop("Release archive has missing members: ", paste(missing, collapse = ", "))
  }
  if (length(extra) > 0L) {
    stop("Release archive has extra members: ", paste(extra, collapse = ", "))
  }
  if (length(member_types) != length(archive_members) ||
      any(member_types != "-")) {
    stop("Release archive contains a symlink or non-regular member")
  }
  archive_members
}

verify_figureforge_release <- function(
  archive_path,
  manifest_path,
  extract_dir = NULL
) {
  if (!file.exists(archive_path) || dir.exists(archive_path)) {
    stop("Release archive does not exist: ", archive_path)
  }
  if (file.info(archive_path)$size <= 0L) {
    stop("Release archive is empty: ", archive_path)
  }
  archive_path <- normalizePath(archive_path, mustWork = TRUE)
  manifest <- read_release_manifest(manifest_path)
  sidecar_path <- verify_release_sidecar(archive_path)

  archive_members <- system2(
    "tar",
    c("-tzf", shQuote(archive_path)),
    stdout = TRUE,
    stderr = TRUE
  )
  list_status <- attr(archive_members, "status")
  if (!is.null(list_status) && list_status != 0L) {
    stop("Unable to list release archive: ", paste(archive_members, collapse = "\n"))
  }
  verbose <- system2(
    "tar",
    c("-tvzf", shQuote(archive_path)),
    stdout = TRUE,
    stderr = TRUE
  )
  verbose_status <- attr(verbose, "status")
  if (!is.null(verbose_status) && verbose_status != 0L) {
    stop("Unable to inspect release archive member types")
  }
  member_types <- substr(trimws(verbose), 1L, 1L)
  archive_members <- validate_release_archive_members(
    archive_members,
    manifest$package_path,
    member_types
  )

  temporary_extract <- is.null(extract_dir)
  if (temporary_extract) {
    extract_dir <- tempfile("figureforge-release-verify-")
  } else if (dir.exists(extract_dir) &&
      length(list.files(
        extract_dir,
        all.files = TRUE,
        no.. = TRUE
      )) > 0L) {
    stop("Release extraction directory must be empty: ", extract_dir)
  }
  dir.create(extract_dir, recursive = TRUE, showWarnings = FALSE)
  if (temporary_extract) {
    on.exit(unlink(extract_dir, recursive = TRUE), add = TRUE)
  }
  extract_status <- system2(
    "tar",
    c("-xzf", shQuote(archive_path), "-C", shQuote(extract_dir)),
    stdout = TRUE,
    stderr = TRUE
  )
  status <- attr(extract_status, "status")
  if (!is.null(status) && status != 0L) {
    stop("Unable to extract release archive: ", paste(extract_status, collapse = "\n"))
  }

  extracted <- file.path(extract_dir, manifest$package_path)
  if (any(!file.exists(extracted) | dir.exists(extracted))) {
    stop("Release archive has missing extracted members")
  }
  if (any(nzchar(Sys.readlink(extracted)))) {
    stop("Release archive contains a symlink member")
  }
  actual_bytes <- as.numeric(file.info(extracted)$size)
  if (any(!is.finite(actual_bytes) | actual_bytes <= 0L)) {
    stop("Release archive contains an empty member")
  }
  actual_hashes <- unname(vapply(
    extracted,
    figureforge_sha256,
    character(1)
  ))
  if (!identical(actual_bytes, as.numeric(manifest$bytes)) ||
      !identical(actual_hashes, manifest$sha256)) {
    stop("Release member checksum mismatch")
  }
  list(
    ok = TRUE,
    archive_path = archive_path,
    manifest_path = normalizePath(manifest_path, mustWork = TRUE),
    sidecar_path = sidecar_path,
    extract_dir = normalizePath(extract_dir, mustWork = TRUE),
    manifest = manifest
  )
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
  staging_root <- tempfile("figureforge-release-stage-")
  dir.create(staging_root, recursive = TRUE)
  on.exit(unlink(staging_root, recursive = TRUE), add = TRUE)
  for (row_index in seq_len(nrow(manifest))) {
    source <- file.path(repo_root, manifest$source_path[[row_index]])
    destination <- file.path(
      staging_root,
      manifest$package_path[[row_index]]
    )
    dir.create(dirname(destination), recursive = TRUE, showWarnings = FALSE)
    copied <- file.copy(
      source,
      destination,
      overwrite = FALSE,
      copy.mode = TRUE,
      copy.date = TRUE
    )
    if (!isTRUE(copied)) {
      stop("Unable to stage release file: ", manifest$source_path[[row_index]])
    }
  }
  file_list <- tempfile("figureforge-release-files-", fileext = ".txt")
  on.exit(unlink(file_list), add = TRUE)
  writeLines(manifest$package_path, file_list, useBytes = TRUE)
  output <- system2(
    "tar",
    c(
      "-czf",
      shQuote(archive_path),
      "-C",
      shQuote(staging_root),
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
  checksum_path <- paste0(archive_path, ".sha256")
  if (file.exists(checksum_path)) unlink(checksum_path)
  writeLines(
    paste(
      figureforge_sha256(archive_path),
      basename(archive_path),
      sep = "  "
    ),
    checksum_path,
    useBytes = TRUE
  )
  list(
    archive_path = archive_path,
    checksum_path = checksum_path,
    manifest = manifest,
    manifest_path = manifest_path
  )
}
