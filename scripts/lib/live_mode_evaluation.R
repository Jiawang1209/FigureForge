live_mode_read_metadata <- function(path) {
  if (!file.exists(path)) return(list())
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  lines <- trimws(lines)
  lines <- lines[nzchar(lines) & !startsWith(lines, "#")]
  separators <- regexpr(":", lines, fixed = TRUE)
  if (any(separators < 1L)) return(list())
  keys <- trimws(substr(lines, 1L, separators - 1L))
  values <- trimws(substr(lines, separators + 1L, nchar(lines)))
  if (any(!nzchar(keys)) || anyDuplicated(keys)) return(list())
  stats::setNames(as.list(values), keys)
}

live_mode_shell_words <- function(command) {
  matches <- gregexpr(
    "\"(?:\\\\.|[^\"])*\"|'[^']*'|[^[:space:]]+",
    command,
    perl = TRUE
  )
  words <- regmatches(command, matches)[[1L]]
  if (length(words) == 0L) return(character(0))
  vapply(words, function(word) {
    if (nchar(word) >= 2L) {
      first <- substr(word, 1L, 1L)
      last <- substr(word, nchar(word), nchar(word))
      if (first == last && first %in% c("\"", "'")) {
        return(substr(word, 2L, nchar(word) - 1L))
      }
    }
    word
  }, character(1L), USE.NAMES = FALSE)
}

live_mode_unwrap_shell <- function(command) {
  words <- live_mode_shell_words(trimws(command))
  if (length(words) == 3L &&
      words[[1L]] %in% c(
        "/bin/bash",
        "/bin/sh",
        "/bin/zsh",
        "/usr/bin/bash",
        "/usr/bin/sh",
        "/usr/bin/zsh"
      ) &&
      identical(words[[2L]], "-lc")) {
    return(words[[3L]])
  }
  if (
    length(words) > 0L &&
      basename(words[[1L]]) %in% c("bash", "sh", "zsh")
  ) {
    return(NA_character_)
  }
  trimws(command)
}

live_mode_successful_commands <- function(transcript_path) {
  if (!file.exists(transcript_path) ||
      !requireNamespace("jsonlite", quietly = TRUE)) {
    return(character(0))
  }
  lines <- readLines(transcript_path, warn = FALSE, encoding = "UTF-8")
  lines <- lines[nzchar(trimws(lines))]
  events <- lapply(lines, function(line) {
    tryCatch(
      jsonlite::fromJSON(line, simplifyVector = FALSE),
      error = function(error) NULL
    )
  })
  commands <- vapply(events, function(event) {
    if (is.null(event) ||
        !identical(event$type, "item.completed") ||
        !is.list(event$item) ||
        !identical(event$item$type, "command_execution") ||
        length(event$item$exit_code) != 1L ||
        is.na(event$item$exit_code) ||
        as.integer(event$item$exit_code) != 0L ||
        !is.character(event$item$command) ||
        length(event$item$command) != 1L) {
      return(NA_character_)
    }
    event$item$command
  }, character(1L))
  commands[!is.na(commands)]
}

live_mode_fixed_reader_allowlist <- function(name) {
  if (!name %in% c("cat", "sed")) return(character(0))
  candidates <- file.path(c("/bin", "/usr/bin"), name)
  candidates <- candidates[file.exists(candidates)]
  normalized <- unique(vapply(
    candidates,
    normalizePath,
    character(1L),
    mustWork = TRUE,
    USE.NAMES = FALSE
  ))
  normalized[vapply(normalized, function(path) {
    isTRUE(file_test("-f", path)) &&
      identical(Sys.readlink(path), "") &&
      identical(basename(path), name) &&
      identical(unname(file.access(path, mode = 1L)), 0L)
  }, logical(1L))]
}

live_mode_fixed_reader_paths <- function() {
  readers <- vapply(c("cat", "sed"), function(name) {
    allowed <- live_mode_fixed_reader_allowlist(name)
    if (length(allowed) < 1L) {
      stop("Trusted system reader is unavailable: ", name)
    }
    allowed[[1L]]
  }, character(1L))
  names(readers) <- c("cat", "sed")
  readers
}

live_mode_trusted_reader_paths <- function(paths) {
  if (
    !is.character(paths) ||
      !identical(names(paths), c("cat", "sed")) ||
      anyDuplicated(paths) ||
      any(!startsWith(paths, "/"))
  ) {
    return(FALSE)
  }
  all(vapply(seq_along(paths), function(index) {
    path <- paths[[index]]
    expected_name <- names(paths)[[index]]
    file.exists(path) &&
      identical(Sys.readlink(path), "") &&
      identical(
        normalizePath(path, mustWork = TRUE),
        path
      ) &&
      identical(basename(path), expected_name) &&
      identical(unname(file.access(path, mode = 1L)), 0L) &&
      path %in% live_mode_fixed_reader_allowlist(expected_name)
  }, logical(1L)))
}

live_mode_command_reads <- function(
  command,
  workspace_root,
  target_path,
  trusted_reader_paths
) {
  if (!live_mode_trusted_reader_paths(trusted_reader_paths)) {
    return(FALSE)
  }
  inner <- live_mode_unwrap_shell(command)
  if (
    length(inner) != 1L ||
      is.na(inner) ||
      grepl("[;&|<>()`\\r\\n]", inner, perl = TRUE) ||
      grepl("\\$\\(", inner, perl = TRUE)
  ) {
    return(FALSE)
  }
  words <- live_mode_shell_words(inner)
  if (length(words) < 2L) return(FALSE)
  executable <- words[[1L]]
  candidate <- ""
  if (
    identical(executable, trusted_reader_paths[["cat"]]) &&
      length(words) == 2L
  ) {
    candidate <- words[[2L]]
  } else if (
    identical(executable, trusted_reader_paths[["sed"]]) &&
      length(words) == 4L &&
      identical(words[[2L]], "-n") &&
      grepl("^[0-9]+(?:,[0-9]+)?p$", words[[3L]], perl = TRUE)
  ) {
    candidate <- words[[4L]]
  } else {
    return(FALSE)
  }
  if (!nzchar(candidate) || startsWith(candidate, "-")) {
    return(FALSE)
  }
  current_dir <- normalizePath(workspace_root, mustWork = TRUE)
  expected <- normalizePath(target_path, mustWork = TRUE)
  resolved <- if (startsWith(candidate, "/")) {
    candidate
  } else {
    file.path(current_dir, candidate)
  }
  file.exists(resolved) &&
    identical(normalizePath(resolved, mustWork = TRUE), expected)
}

live_mode_transcript_reads <- function(
  transcript_path,
  workspace_root,
  target_path,
  trusted_reader_paths
) {
  commands <- live_mode_successful_commands(transcript_path)
  any(vapply(
    commands,
    live_mode_command_reads,
    logical(1L),
    workspace_root = workspace_root,
    target_path = target_path,
    trusted_reader_paths = trusted_reader_paths
  ))
}

live_mode_regular_nonempty <- function(path) {
  info <- file.info(path)
  file.exists(path) &&
    identical(Sys.readlink(path), "") &&
    isTRUE(info$isdir == FALSE) &&
    !is.na(info$size) &&
    info$size > 0
}

live_mode_path_is_within <- function(path, root) {
  normalized_path <- tryCatch(
    normalizePath(path, mustWork = TRUE),
    error = function(error) ""
  )
  normalized_root <- tryCatch(
    normalizePath(root, mustWork = TRUE),
    error = function(error) ""
  )
  nzchar(normalized_path) &&
    nzchar(normalized_root) &&
    (
      identical(normalized_path, normalized_root) ||
        startsWith(
          normalized_path,
          paste0(normalized_root, .Platform$file.sep)
        )
    )
}

live_mode_sha256 <- function(path) {
  if (!live_mode_regular_nonempty(path)) {
    stop("Cannot hash a missing, linked, or empty file")
  }
  tools <- c("sha256sum", "shasum")
  available <- unname(Sys.which(tools))
  output <- if (nzchar(available[[1L]])) {
    system2(
      available[[1L]],
      shQuote(path),
      stdout = TRUE,
      stderr = TRUE
    )
  } else if (nzchar(available[[2L]])) {
    system2(
      available[[2L]],
      c("-a", "256", shQuote(path)),
      stdout = TRUE,
      stderr = TRUE
    )
  } else {
    stop("No SHA-256 implementation is available")
  }
  status <- attr(output, "status")
  if (!is.null(status) && status != 0L) {
    stop("Unable to calculate SHA-256")
  }
  hash <- tolower(strsplit(
    output[[1L]],
    "\\s+",
    perl = TRUE
  )[[1L]][[1L]])
  if (!grepl("^[0-9a-f]{64}$", hash, perl = TRUE)) {
    stop("Invalid SHA-256 output")
  }
  hash
}

live_mode_installed_skill_integrity <- function(
  installed_skill_root,
  manifest_path,
  workspace_root
) {
  tryCatch({
    if (
      !dir.exists(installed_skill_root) ||
        !identical(Sys.readlink(installed_skill_root), "") ||
        live_mode_path_is_within(installed_skill_root, workspace_root) ||
        !live_mode_regular_nonempty(manifest_path) ||
        live_mode_path_is_within(manifest_path, workspace_root)
    ) {
      return(FALSE)
    }
    manifest <- read.csv(
      manifest_path,
      stringsAsFactors = FALSE,
      check.names = FALSE,
      na.strings = character(0)
    )
    required <- c("source_path", "package_path", "sha256", "bytes")
    if (
      !identical(names(manifest), required) ||
        nrow(manifest) < 1L ||
        anyDuplicated(manifest$package_path) ||
        any(!startsWith(manifest$package_path, "figureforge/")) ||
        any(!grepl("^[0-9a-f]{64}$", manifest$sha256, perl = TRUE))
    ) {
      return(FALSE)
    }
    expected_relative <- sub(
      "^figureforge/",
      "",
      gsub("\\\\", "/", manifest$package_path)
    )
    components <- strsplit(expected_relative, "/", fixed = TRUE)
    if (any(vapply(
      components,
      function(parts) any(parts %in% c("", ".", "..")),
      logical(1L)
    ))) {
      return(FALSE)
    }
    entries <- list.files(
      installed_skill_root,
      recursive = TRUE,
      all.files = TRUE,
      no.. = TRUE,
      include.dirs = TRUE,
      full.names = TRUE
    )
    link_targets <- Sys.readlink(entries)
    if (any(!is.na(link_targets) & nzchar(link_targets))) {
      return(FALSE)
    }
    actual_files <- entries[vapply(
      entries,
      function(path) isTRUE(file_test("-f", path)),
      logical(1L)
    )]
    prefix_length <- nchar(normalizePath(
      installed_skill_root,
      mustWork = TRUE
    )) + 2L
    actual_relative <- gsub(
      "\\\\",
      "/",
      substring(
        normalizePath(actual_files, mustWork = TRUE),
        prefix_length
      )
    )
    if (!setequal(actual_relative, expected_relative)) {
      return(FALSE)
    }
    order_index <- match(expected_relative, actual_relative)
    ordered_files <- actual_files[order_index]
    actual_bytes <- as.numeric(file.info(ordered_files)$size)
    actual_hashes <- vapply(
      ordered_files,
      live_mode_sha256,
      character(1L)
    )
    identical(actual_bytes, as.numeric(manifest$bytes)) &&
      identical(unname(actual_hashes), as.character(manifest$sha256))
  }, error = function(error) FALSE)
}

live_mode_trusted_case_evidence <- function(
  installed_skill_root,
  primary_case_id
) {
  if (
    length(primary_case_id) != 1L ||
      primary_case_id %in% c(".", "..") ||
      !grepl("^[A-Za-z0-9._-]+$", primary_case_id)
  ) {
    return(FALSE)
  }
  case_dir <- file.path(
    installed_skill_root,
    "public-cases",
    primary_case_id
  )
  evidence <- file.path(case_dir, c("case.md", "plot.R", "qa.md"))
  if (
    !dir.exists(case_dir) ||
      !identical(Sys.readlink(case_dir), "") ||
      !live_mode_path_is_within(case_dir, installed_skill_root) ||
      !all(vapply(evidence, live_mode_regular_nonempty, logical(1L))) ||
      !all(vapply(
        evidence,
        live_mode_path_is_within,
        logical(1L),
        root = installed_skill_root
      ))
  ) {
    return(FALSE)
  }
  TRUE
}

live_mode_schema_bound_receipt <- function(metadata, trace_dir) {
  required <- c(
    "search_query_sha256",
    "search_intent",
    "search_receipt_file",
    "search_receipt_sha256"
  )
  if (!all(required %in% names(metadata))) return(FALSE)
  receipt_file <- metadata$search_receipt_file
  if (length(receipt_file) != 1L ||
      !identical(receipt_file, basename(receipt_file)) ||
      !grepl("\\.csv$", receipt_file, ignore.case = TRUE)) {
    return(FALSE)
  }
  receipt_path <- file.path(trace_dir, receipt_file)
  if (!live_mode_regular_nonempty(receipt_path)) return(FALSE)
  receipt <- tryCatch(
    read.csv(
      receipt_path,
      stringsAsFactors = FALSE,
      check.names = FALSE,
      colClasses = "character",
      na.strings = character(0)
    ),
    error = function(error) NULL
  )
  required_columns <- c(
    "receipt_schema_version",
    "receipt_generator",
    "search_query_sha256",
    "search_intent",
    "search_scope",
    "schema_sha256",
    "search_limit",
    "completed_only",
    "explain_scores",
    "result_rank",
    "case_id_sha256",
    "score"
  )
  !is.null(receipt) &&
    nrow(receipt) >= 1L &&
    identical(names(receipt), required_columns) &&
    all(receipt$receipt_schema_version == "2") &&
    all(receipt$receipt_generator == "figureforge-search_cases") &&
    all(
      receipt$search_query_sha256 ==
        metadata$search_query_sha256
    ) &&
    grepl(
      "^[0-9a-f]{64}$",
      metadata$search_query_sha256,
      perl = TRUE
    ) &&
    all(receipt$search_intent == metadata$search_intent) &&
    metadata$search_intent %in% c(
      "relationship",
      "comparison",
      "distribution",
      "composition",
      "trend",
      "ordination",
      "network",
      "spatial",
      "uncertainty",
      "other"
    ) &&
    length(unique(receipt$schema_sha256)) == 1L &&
    grepl("^[0-9a-f]{64}$", receipt$schema_sha256[[1L]], perl = TRUE)
}

evaluate_live_mode_probe <- function(
  expected_mode,
  workspace_root,
  installed_skill_root,
  manifest_path,
  trusted_reader_paths,
  transcript_path,
  validator_log,
  validator_status
) {
  stopifnot(expected_mode %in% c("case_based", "general_fallback"))
  output_dir <- file.path(workspace_root, "figureforge-output")
  trace_dir <- file.path(output_dir, ".figureforge")
  trace_path <- file.path(trace_dir, "case-trace.yml")
  metadata <- live_mode_read_metadata(trace_path)
  generation_mode <- if ("generation_mode" %in% names(metadata)) {
    metadata$generation_mode
  } else {
    ""
  }
  claim <- if ("claim" %in% names(metadata)) metadata$claim else ""
  expected_claim <- if (identical(expected_mode, "case_based")) {
    "case_grounded"
  } else {
    "general_method"
  }
  artifacts_present <- all(vapply(
    file.path(output_dir, c("plot.R", "plot.png", "plot.pdf")),
    live_mode_regular_nonempty,
    logical(1L)
  ))
  validator_lines <- if (file.exists(validator_log)) {
    readLines(validator_log, warn = FALSE, encoding = "UTF-8")
  } else {
    character(0)
  }
  strict_validation <-
    identical(as.integer(validator_status), 0L) &&
    any(grepl("Verification level: strict", validator_lines, fixed = TRUE)) &&
    any(grepl("Case trace validation OK:", validator_lines, fixed = TRUE))
  schema_bound_receipt <- live_mode_schema_bound_receipt(metadata, trace_dir)
  installed_skill_integrity <- live_mode_installed_skill_integrity(
    installed_skill_root,
    manifest_path,
    workspace_root
  )
  trusted_readers <- live_mode_trusted_reader_paths(
    trusted_reader_paths
  )

  case_md_read <- FALSE
  plot_r_read <- FALSE
  qa_md_read <- FALSE
  trusted_case_evidence <- identical(
    expected_mode,
    "general_fallback"
  )
  if (identical(expected_mode, "case_based") &&
      "primary_case_id" %in% names(metadata) &&
      !metadata$primary_case_id %in% c(".", "..") &&
      grepl("^[A-Za-z0-9._-]+$", metadata$primary_case_id)) {
    case_dir <- file.path(
      installed_skill_root,
      "public-cases",
      metadata$primary_case_id
    )
    trusted_case_evidence <- live_mode_trusted_case_evidence(
      installed_skill_root,
      metadata$primary_case_id
    )
    if (
      installed_skill_integrity &&
        trusted_case_evidence &&
        trusted_readers
    ) {
      case_md_read <- live_mode_transcript_reads(
        transcript_path,
        workspace_root,
        file.path(case_dir, "case.md"),
        trusted_reader_paths
      )
      plot_r_read <- live_mode_transcript_reads(
        transcript_path,
        workspace_root,
        file.path(case_dir, "plot.R"),
        trusted_reader_paths
      )
      qa_md_read <- live_mode_transcript_reads(
        transcript_path,
        workspace_root,
        file.path(case_dir, "qa.md"),
        trusted_reader_paths
      )
    }
  }
  evidence_read <- if (identical(expected_mode, "case_based")) {
    case_md_read && plot_r_read && qa_md_read
  } else {
    TRUE
  }
  passed <-
    identical(generation_mode, expected_mode) &&
    identical(claim, expected_claim) &&
    schema_bound_receipt &&
    strict_validation &&
    installed_skill_integrity &&
    trusted_readers &&
    trusted_case_evidence &&
    artifacts_present &&
    evidence_read

  data.frame(
    expected_mode = expected_mode,
    generation_mode = generation_mode,
    claim = claim,
    schema_bound_receipt = schema_bound_receipt,
    strict_validation = strict_validation,
    installed_skill_integrity = installed_skill_integrity,
    trusted_readers = trusted_readers,
    trusted_case_evidence = trusted_case_evidence,
    artifacts_present = artifacts_present,
    case_md_read = case_md_read,
    plot_r_read = plot_r_read,
    qa_md_read = qa_md_read,
    passed = passed,
    stringsAsFactors = FALSE
  )
}
