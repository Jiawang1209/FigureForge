figureforge_certification_identity_fields <- function() {
  c(
    "schema_version",
    "release_version",
    "certified_source_commit",
    "certified_source_tree",
    "release_source_sha256",
    "manifest_rows",
    "manifest_bytes",
    "manifest_sha256",
    "archive_bytes",
    "archive_sha256",
    "certified_at"
  )
}

validate_figureforge_certification_identity <- function(identity) {
  required <- figureforge_certification_identity_fields()
  if (!is.data.frame(identity) || nrow(identity) != 1L) {
    stop("Certification identity must contain exactly one row")
  }
  missing <- setdiff(required, names(identity))
  extra <- setdiff(names(identity), required)
  if (length(missing) > 0L || length(extra) > 0L) {
    stop(
      "Certification identity columns differ; missing=",
      paste(missing, collapse = ","),
      "; extra=",
      paste(extra, collapse = ",")
    )
  }
  if (!identical(as.character(identity$schema_version), "1")) {
    stop("schema_version must be 1")
  }
  if (!grepl(
    "^[0-9]+\\.[0-9]+\\.[0-9]+$",
    as.character(identity$release_version),
    perl = TRUE
  )) {
    stop("release_version must use semantic version form")
  }
  for (field in c("certified_source_commit", "certified_source_tree")) {
    if (!grepl(
      "^[0-9a-f]{40}$",
      as.character(identity[[field]]),
      perl = TRUE
    )) {
      stop(field, " must be a lowercase 40-character Git object ID")
    }
  }
  for (field in c(
    "release_source_sha256",
    "manifest_sha256",
    "archive_sha256"
  )) {
    if (!grepl(
      "^[0-9a-f]{64}$",
      as.character(identity[[field]]),
      perl = TRUE
    )) {
      stop(field, " must be a lowercase SHA-256")
    }
  }
  for (field in c("manifest_rows", "manifest_bytes", "archive_bytes")) {
    value <- suppressWarnings(as.numeric(identity[[field]]))
    if (length(value) != 1L || !is.finite(value) || value <= 0 ||
        value != floor(value)) {
      stop(field, " must be one positive integer")
    }
  }
  if (!grepl(
    "^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}[+-][0-9]{4}$",
    as.character(identity$certified_at),
    perl = TRUE
  )) {
    stop("certified_at must include a numeric timezone offset")
  }
  invisible(identity)
}

compare_figureforge_certification_identity <- function(
  certified,
  observed,
  compare_archive = FALSE
) {
  validate_figureforge_certification_identity(certified)
  validate_figureforge_certification_identity(observed)
  compared_fields <- c(
    "schema_version",
    "release_version",
    "release_source_sha256",
    "manifest_rows",
    "manifest_bytes",
    "manifest_sha256"
  )
  if (isTRUE(compare_archive)) {
    compared_fields <- c(
      compared_fields,
      "archive_bytes",
      "archive_sha256"
    )
  }
  failures <- compared_fields[!vapply(
    compared_fields,
    function(field) {
      identical(
        as.character(certified[[field]]),
        as.character(observed[[field]])
      )
    },
    logical(1)
  )]
  list(ok = length(failures) == 0L, failures = failures)
}

figureforge_certification_additional_source_paths <- function() {
  c(
    "scripts/run_figureforge_live_evals.sh",
    "scripts/run_figureforge_plotting_eval.sh",
    "scripts/run_figureforge_mode_evals.sh",
    "scripts/evaluate_figureforge_mode_probe.R",
    "scripts/lib/live_mode_evaluation.R",
    "scripts/verify_figureforge_v110.sh",
    "scripts/lib/release_certification.R",
    "scripts/check_figureforge_v110_certification.R",
    "scripts/write_figureforge_v110_certification_identity.R"
  )
}

figureforge_release_source_sha256 <- function(
  repo_root,
  manifest,
  additional_paths = figureforge_certification_additional_source_paths()
) {
  if (!exists("figureforge_sha256", mode = "function")) {
    stop("figureforge_sha256() must be loaded before release certification")
  }
  repo_root <- normalizePath(repo_root, mustWork = TRUE)
  if (!is.data.frame(manifest) ||
      !"source_path" %in% names(manifest) ||
      nrow(manifest) == 0L) {
    stop("Release manifest must contain nonempty source_path rows")
  }
  paths <- unique(c(
    as.character(manifest$source_path),
    as.character(additional_paths)
  ))
  paths <- sort(gsub("\\\\", "/", paths))
  if (any(!nzchar(paths)) ||
      any(startsWith(paths, "/")) ||
      any(grepl("(^|/)\\.\\.($|/)", paths, perl = TRUE))) {
    stop("Certification source paths must be nonempty repository-relative paths")
  }
  absolute <- file.path(repo_root, paths)
  regular <- file.exists(absolute) &
    !dir.exists(absolute) &
    !nzchar(Sys.readlink(absolute))
  if (!all(regular)) {
    stop("Certification source is missing or non-regular: ", paths[!regular][[1L]])
  }
  rows <- paste(
    paths,
    vapply(absolute, figureforge_sha256, character(1)),
    sep = "\t"
  )
  figureforge_sha256_text(paste(rows, collapse = "\n"))
}

read_figureforge_certification_identity <- function(path) {
  if (!file.exists(path) || dir.exists(path)) {
    stop("Certification identity does not exist: ", path)
  }
  identity <- read.delim(
    path,
    sep = "\t",
    quote = "",
    comment.char = "",
    stringsAsFactors = FALSE,
    check.names = FALSE,
    na.strings = character(0),
    colClasses = "character",
    fileEncoding = "UTF-8"
  )
  validate_figureforge_certification_identity(identity)
  identity
}

write_figureforge_certification_identity <- function(identity, path) {
  validate_figureforge_certification_identity(identity)
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  write.table(
    identity[, figureforge_certification_identity_fields(), drop = FALSE],
    path,
    sep = "\t",
    quote = FALSE,
    row.names = FALSE,
    col.names = TRUE,
    fileEncoding = "UTF-8"
  )
  invisible(normalizePath(path, mustWork = TRUE))
}

figureforge_git_output <- function(repo_root, args) {
  output <- system2(
    "git",
    c("-C", shQuote(repo_root), args),
    stdout = TRUE,
    stderr = TRUE
  )
  list(
    ok = is.null(attr(output, "status")),
    output = output
  )
}

validate_figureforge_certified_git_binding <- function(repo_root, identity) {
  validate_figureforge_certification_identity(identity)
  repo_root <- normalizePath(repo_root, mustWork = TRUE)
  commit <- as.character(identity$certified_source_commit)
  expected_tree <- as.character(identity$certified_source_tree)
  resolved <- figureforge_git_output(
    repo_root,
    c("rev-parse", paste0(commit, "^{tree}"))
  )
  failures <- character(0)
  if (!isTRUE(resolved$ok) ||
      length(resolved$output) != 1L ||
      !identical(resolved$output[[1L]], expected_tree)) {
    failures <- c(failures, "certified_source_tree")
  }
  ancestor_status <- suppressWarnings(system2(
    "git",
    c(
      "-C",
      shQuote(repo_root),
      "merge-base",
      "--is-ancestor",
      commit,
      "HEAD"
    ),
    stdout = FALSE,
    stderr = FALSE
  ))
  if (!identical(as.integer(ancestor_status), 0L)) {
    failures <- c(failures, "certified_source_commit")
  }
  list(ok = length(failures) == 0L, failures = unique(failures))
}

figureforge_release_paths_clean <- function(repo_root, paths) {
  status <- system2(
    "git",
    c(
      "-C",
      shQuote(repo_root),
      "status",
      "--porcelain",
      "--",
      vapply(paths, shQuote, character(1))
    ),
    stdout = TRUE,
    stderr = TRUE
  )
  list(
    ok = is.null(attr(status, "status")) && length(status) == 0L,
    changes = status
  )
}

figureforge_manifest_identical <- function(left, right) {
  fields <- c("source_path", "package_path", "sha256", "bytes")
  if (!all(fields %in% names(left)) || !all(fields %in% names(right))) {
    return(FALSE)
  }
  left <- left[, fields, drop = FALSE]
  right <- right[, fields, drop = FALSE]
  left$bytes <- as.numeric(left$bytes)
  right$bytes <- as.numeric(right$bytes)
  identical(left, right)
}

build_figureforge_certification_identity <- function(
  repo_root,
  manifest_path,
  archive_path,
  certified_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z")
) {
  required_functions <- c(
    "build_release_manifest",
    "read_release_manifest",
    "verify_figureforge_release",
    "figureforge_sha256"
  )
  missing_functions <- required_functions[!vapply(
    required_functions,
    exists,
    logical(1),
    mode = "function"
  )]
  if (length(missing_functions) > 0L) {
    stop(
      "Release certification dependencies are not loaded: ",
      paste(missing_functions, collapse = ", ")
    )
  }
  repo_root <- normalizePath(repo_root, mustWork = TRUE)
  manifest_path <- normalizePath(manifest_path, mustWork = TRUE)
  archive_path <- normalizePath(archive_path, mustWork = TRUE)
  supplied_manifest <- read_release_manifest(manifest_path)
  current_manifest <- build_release_manifest(repo_root)
  if (!figureforge_manifest_identical(supplied_manifest, current_manifest)) {
    stop("Supplied manifest is stale for the current release inputs")
  }
  verify_figureforge_release(archive_path, manifest_path)

  source_paths <- unique(c(
    current_manifest$source_path,
    figureforge_certification_additional_source_paths()
  ))
  cleanliness <- figureforge_release_paths_clean(repo_root, source_paths)
  if (!isTRUE(cleanliness$ok)) {
    stop(
      "Release certification requires clean committed inputs",
      if (length(cleanliness$changes) > 0L) {
        paste0(": ", paste(cleanliness$changes, collapse = "; "))
      } else {
        ""
      }
    )
  }
  commit <- figureforge_git_output(repo_root, c("rev-parse", "HEAD"))
  tree <- figureforge_git_output(repo_root, c("rev-parse", "HEAD^{tree}"))
  if (!isTRUE(commit$ok) || length(commit$output) != 1L ||
      !isTRUE(tree$ok) || length(tree$output) != 1L) {
    stop("Unable to resolve the committed certification source")
  }
  version_path <- file.path(repo_root, "skills", "figureforge", "VERSION")
  version <- readLines(
    version_path,
    warn = FALSE,
    encoding = "UTF-8"
  )
  if (length(version) != 1L ||
      !grepl("^[0-9]+\\.[0-9]+\\.[0-9]+$", version, perl = TRUE)) {
    stop("Release VERSION must contain one semantic version")
  }
  identity <- data.frame(
    schema_version = "1",
    release_version = version,
    certified_source_commit = commit$output[[1L]],
    certified_source_tree = tree$output[[1L]],
    release_source_sha256 = figureforge_release_source_sha256(
      repo_root,
      current_manifest
    ),
    manifest_rows = nrow(current_manifest),
    manifest_bytes = as.numeric(file.info(manifest_path)$size),
    manifest_sha256 = figureforge_sha256(manifest_path),
    archive_bytes = as.numeric(file.info(archive_path)$size),
    archive_sha256 = figureforge_sha256(archive_path),
    certified_at = certified_at,
    stringsAsFactors = FALSE
  )
  validate_figureforge_certification_identity(identity)
  identity
}

check_figureforge_current_certification <- function(
  repo_root,
  identity_path
) {
  if (!file.exists(identity_path) || dir.exists(identity_path)) {
    return(list(
      ok = FALSE,
      failures = "certification_identity_missing",
      certified = NULL,
      observed = NULL
    ))
  }
  certified <- read_figureforge_certification_identity(identity_path)
  git_binding <- validate_figureforge_certified_git_binding(
    repo_root,
    certified
  )
  current_manifest_path <- tempfile(
    "figureforge-current-manifest-",
    fileext = ".csv"
  )
  on.exit(unlink(current_manifest_path, force = TRUE), add = TRUE)
  current_manifest <- build_release_manifest(
    repo_root,
    current_manifest_path
  )
  observed <- certified
  version <- readLines(
    file.path(repo_root, "skills", "figureforge", "VERSION"),
    warn = FALSE,
    encoding = "UTF-8"
  )
  observed$release_version <- version
  observed$release_source_sha256 <- figureforge_release_source_sha256(
    repo_root,
    current_manifest
  )
  observed$manifest_rows <- nrow(current_manifest)
  observed$manifest_bytes <- as.numeric(file.info(current_manifest_path)$size)
  observed$manifest_sha256 <- figureforge_sha256(current_manifest_path)
  comparison <- compare_figureforge_certification_identity(
    certified,
    observed,
    compare_archive = FALSE
  )
  failures <- unique(c(comparison$failures, git_binding$failures))
  list(
    ok = length(failures) == 0L,
    failures = failures,
    certified = certified,
    observed = observed
  )
}
