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
  if (length(words) >= 3L &&
      basename(words[[1L]]) %in% c("bash", "sh", "zsh") &&
      words[[2L]] %in% c("-c", "-lc")) {
    return(paste(words[3L:length(words)], collapse = " "))
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

live_mode_command_reads <- function(command, workspace_root, target_path) {
  read_commands <- c("awk", "cat", "head", "less", "more", "sed", "tail")
  inner <- live_mode_unwrap_shell(command)
  segments <- strsplit(
    inner,
    "[[:space:]]*(?:&&|\\|\\||;)[[:space:]]*",
    perl = TRUE
  )[[1L]]
  current_dir <- normalizePath(workspace_root, mustWork = TRUE)
  expected <- normalizePath(target_path, mustWork = TRUE)
  for (segment in segments) {
    words <- live_mode_shell_words(segment)
    if (length(words) == 0L) next
    executable <- basename(words[[1L]])
    if (identical(executable, "cd") && length(words) >= 2L) {
      candidate <- if (startsWith(words[[2L]], "/")) {
        words[[2L]]
      } else {
        file.path(current_dir, words[[2L]])
      }
      if (dir.exists(candidate)) {
        current_dir <- normalizePath(candidate, mustWork = TRUE)
      }
      next
    }
    if (!executable %in% read_commands || length(words) < 2L) next
    candidates <- words[-1L]
    for (candidate in candidates) {
      if (!nzchar(candidate) || startsWith(candidate, "-")) next
      resolved <- if (startsWith(candidate, "/")) {
        candidate
      } else {
        file.path(current_dir, candidate)
      }
      if (file.exists(resolved) &&
          identical(normalizePath(resolved, mustWork = TRUE), expected)) {
        return(TRUE)
      }
    }
  }
  FALSE
}

live_mode_transcript_reads <- function(
  transcript_path,
  workspace_root,
  target_path
) {
  commands <- live_mode_successful_commands(transcript_path)
  any(vapply(
    commands,
    live_mode_command_reads,
    logical(1L),
    workspace_root = workspace_root,
    target_path = target_path
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

live_mode_schema_bound_receipt <- function(metadata, trace_dir) {
  required <- c(
    "search_query",
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
    "search_query",
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
    all(receipt$receipt_schema_version == "1") &&
    all(receipt$receipt_generator == "figureforge-search_cases") &&
    all(receipt$search_query == metadata$search_query) &&
    length(unique(receipt$schema_sha256)) == 1L &&
    grepl("^[0-9a-f]{64}$", receipt$schema_sha256[[1L]], perl = TRUE)
}

evaluate_live_mode_probe <- function(
  expected_mode,
  workspace_root,
  installed_skill_root,
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

  case_md_read <- FALSE
  plot_r_read <- FALSE
  qa_md_read <- FALSE
  if (identical(expected_mode, "case_based") &&
      "primary_case_id" %in% names(metadata) &&
      grepl("^[A-Za-z0-9._-]+$", metadata$primary_case_id)) {
    case_dir <- file.path(
      installed_skill_root,
      "public-cases",
      metadata$primary_case_id
    )
    if (dir.exists(case_dir)) {
      case_md_read <- live_mode_transcript_reads(
        transcript_path,
        workspace_root,
        file.path(case_dir, "case.md")
      )
      plot_r_read <- live_mode_transcript_reads(
        transcript_path,
        workspace_root,
        file.path(case_dir, "plot.R")
      )
      qa_md_read <- live_mode_transcript_reads(
        transcript_path,
        workspace_root,
        file.path(case_dir, "qa.md")
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
    artifacts_present &&
    evidence_read

  data.frame(
    expected_mode = expected_mode,
    generation_mode = generation_mode,
    claim = claim,
    schema_bound_receipt = schema_bound_receipt,
    strict_validation = strict_validation,
    artifacts_present = artifacts_present,
    case_md_read = case_md_read,
    plot_r_read = plot_r_read,
    qa_md_read = qa_md_read,
    passed = passed,
    stringsAsFactors = FALSE
  )
}
