parse_rscript_version <- function(output) {
  match <- regexpr(
    "[0-9]+\\.[0-9]+(?:\\.[0-9]+)?",
    output,
    perl = TRUE
  )
  if (match[[1L]] < 1L) return("")
  regmatches(output, match)[[1L]]
}

probe_rscript <- function(path) {
  exists <- file.exists(path) && !dir.exists(path)
  executable <- exists && isTRUE(unname(file.access(path, mode = 1L)) == 0L)
  if (!executable) {
    return(list(
      path = path,
      exists = exists,
      executable = executable,
      version_output = "",
      status = 1L
    ))
  }
  output <- suppressWarnings(system2(
    path,
    "--version",
    stdout = TRUE,
    stderr = TRUE
  ))
  status <- attr(output, "status")
  list(
    path = path,
    exists = TRUE,
    executable = TRUE,
    version_output = paste(output, collapse = "\n"),
    status = if (is.null(status)) 0L else as.integer(status)
  )
}

validate_rscript_candidate <- function(
  path,
  source,
  probe,
  normalize,
  configured = FALSE
) {
  result <- probe(path)
  label <- if (source == "cli") {
    "CLI --rscript"
  } else if (source == "environment") {
    "FIGUREFORGE_RSCRIPT"
  } else {
    source
  }
  if (!isTRUE(result$exists)) {
    if (configured) stop(label, " does not exist: ", path)
    return(NULL)
  }
  if (!isTRUE(result$executable)) {
    stop(label, " is not an executable file: ", path)
  }
  if (!identical(as.integer(result$status), 0L)) {
    stop(label, " failed to execute --version: ", path)
  }
  version <- parse_rscript_version(result$version_output)
  if (!nzchar(version)) {
    stop(label, " returned an unrecognized R version: ", path)
  }
  if (utils::compareVersion(version, "4.1.0") < 0L) {
    stop(label, " must provide R 4.1 or newer: ", path)
  }
  list(
    path = normalize(path),
    source = source,
    version = version,
    version_output = result$version_output
  )
}

resolve_rscript <- function(
  cli_path = NULL,
  env = Sys.getenv("FIGUREFORGE_RSCRIPT", unset = ""),
  homebrew_path = "/usr/local/bin/Rscript",
  path_lookup = function(name) unname(Sys.which(name)),
  probe = probe_rscript,
  normalize = function(path) normalizePath(path, mustWork = TRUE)
) {
  if (!is.null(cli_path) && nzchar(trimws(cli_path))) {
    return(validate_rscript_candidate(
      path.expand(cli_path),
      "cli",
      probe,
      normalize,
      configured = TRUE
    ))
  }
  if (nzchar(trimws(env))) {
    return(validate_rscript_candidate(
      path.expand(env),
      "environment",
      probe,
      normalize,
      configured = TRUE
    ))
  }

  attempted <- c(
    paste0("homebrew_compat=", homebrew_path),
    "path=Rscript"
  )
  homebrew <- validate_rscript_candidate(
    homebrew_path,
    "homebrew_compat",
    probe,
    normalize
  )
  if (!is.null(homebrew)) return(homebrew)

  path_candidate <- path_lookup("Rscript")
  if (nzchar(path_candidate)) {
    path_result <- validate_rscript_candidate(
      path_candidate,
      "path",
      probe,
      normalize
    )
    if (!is.null(path_result)) return(path_result)
  }

  stop(
    "Unable to resolve Rscript. Attempted ",
    paste(attempted, collapse = ", "),
    ". Set FIGUREFORGE_RSCRIPT or pass --rscript."
  )
}
