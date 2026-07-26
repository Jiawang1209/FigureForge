case_trace_required_common_keys <- function() {
  c(
    "schema_version",
    "generation_mode",
    "figureforge_version",
    "generated_script_sha256",
    "claim"
  )
}

case_trace_case_based_keys <- function() {
  c(
    "primary_case_id",
    "case_md_file",
    "case_md_sha256",
    "plot_r_file",
    "plot_r_sha256",
    "schema_mapping",
    "adopted_patterns",
    "departures",
    "qa_status"
  )
}

case_trace_fallback_keys <- function() {
  "fallback_reason"
}

case_trace_nonempty_keys <- function(metadata, keys) {
  all(keys %in% names(metadata)) &&
    all(nzchar(vapply(metadata[keys], as.character, character(1L))))
}

case_trace_sha256 <- function(value) {
  length(value) == 1L &&
    grepl("^[0-9a-f]{64}$", value, perl = TRUE)
}

case_trace_has_absolute_path <- function(value) {
  grepl(
    "(^|[[:space:]\"'(=])/(?!/)|(^|[[:space:]\"'(=])[A-Za-z]:[\\\\/]",
    value,
    perl = TRUE
  )
}

case_trace_patterns_are_concrete <- function(value) {
  patterns <- trimws(strsplit(value, "|", fixed = TRUE)[[1L]])
  generic <- grepl(
    paste(
      "^used colou?rs?$",
      "^made (a )?scientific plot$",
      "^made (a )?plot$",
      "^created (a )?plot$",
      "^generated (a )?plot$",
      "^adapted (a )?plot$",
      "^nice plot$",
      "^good plot$",
      sep = "|"
    ),
    tolower(patterns),
    perl = TRUE
  )
  length(patterns) > 0L &&
    all(nzchar(patterns)) &&
    all(nchar(patterns) >= 5L) &&
    !any(generic)
}

case_trace_result <- function(checks, messages, evidence) {
  if (exists("make_validation_result", mode = "function", inherits = TRUE)) {
    return(make_validation_result(
      checks,
      messages = messages,
      evidence = evidence
    ))
  }
  check_names <- names(checks)
  checks <- as.logical(checks)
  names(checks) <- check_names
  failed <- names(checks)[!checks]
  list(
    ok = length(failed) == 0L,
    checks = checks,
    failed_checks = failed,
    messages = as.character(messages),
    evidence = evidence
  )
}

validate_case_trace <- function(trace_path, case_dir = NULL, script_path = NULL) {
  metadata <- tryCatch(
    parse_simple_metadata(trace_path),
    error = function(error) structure(
      list(),
      parse_error = conditionMessage(error)
    )
  )
  parse_error <- attr(metadata, "parse_error")
  parse_ok <- is.null(parse_error)
  common_keys <- case_trace_required_common_keys()
  common_ok <- parse_ok && case_trace_nonempty_keys(metadata, common_keys)
  mode <- if (common_ok) metadata$generation_mode else ""
  claim <- if (common_ok) metadata$claim else ""
  recorded_script_hash <- if (
    "generated_script_sha256" %in% names(metadata)
  ) {
    metadata$generated_script_sha256
  } else {
    ""
  }

  script_hash_ok <- case_trace_sha256(recorded_script_hash)
  if (!is.null(script_path)) {
    script_hash_ok <- script_hash_ok &&
      file.exists(script_path) &&
      identical(
        tryCatch(
          figureforge_sha256(script_path),
          error = function(error) ""
        ),
        recorded_script_hash
      )
  }

  metadata_values <- if (parse_ok && length(metadata) > 0L) {
    vapply(metadata, as.character, character(1L))
  } else {
    character(0)
  }
  path_ok <- parse_ok && !any(vapply(
    metadata_values,
    case_trace_has_absolute_path,
    logical(1L)
  ))
  newline_ok <- parse_ok && !any(grepl(
    "[\r\n]",
    c(names(metadata), metadata_values),
    perl = TRUE
  ))

  checks <- c(
    "case trace metadata parses" = parse_ok,
    "required common metadata" = common_ok,
    "supported schema" = common_ok &&
      identical(metadata$schema_version, "1"),
    "supported generation mode" = common_ok &&
      mode %in% c("case_based", "general_fallback"),
    "claim matches generation mode" = common_ok && (
      (identical(mode, "case_based") &&
        identical(claim, "case_grounded")) ||
        (identical(mode, "general_fallback") &&
          claim %in% c("general_generation", "general_method"))
    ),
    "generated script hash matches" = script_hash_ok,
    "no absolute paths" = path_ok,
    "no embedded newlines" = newline_ok
  )

  primary_case_id <- ""
  qa_status <- ""
  if (identical(mode, "case_based")) {
    case_keys <- case_trace_case_based_keys()
    case_keys_ok <- case_trace_nonempty_keys(metadata, case_keys)
    primary_case_id <- if ("primary_case_id" %in% names(metadata)) {
      metadata$primary_case_id
    } else {
      ""
    }
    qa_status <- if ("qa_status" %in% names(metadata)) {
      metadata$qa_status
    } else {
      ""
    }
    case_md_ok <- case_keys_ok &&
      identical(metadata$case_md_file, "case.md") &&
      case_trace_sha256(metadata$case_md_sha256)
    plot_r_ok <- case_keys_ok &&
      identical(metadata$plot_r_file, "plot.R") &&
      case_trace_sha256(metadata$plot_r_sha256)
    mapping_ok <- case_keys_ok && nzchar(trimws(metadata$schema_mapping))
    patterns_ok <- case_keys_ok &&
      case_trace_patterns_are_concrete(metadata$adopted_patterns)
    departures_ok <- case_keys_ok && nzchar(trimws(metadata$departures))

    evidence_hashes_ok <- case_md_ok && plot_r_ok
    qa_ok <- qa_status %in% c("verified", "review_required", "missing")
    if (!is.null(case_dir)) {
      directory_ok <- dir.exists(case_dir) &&
        identical(basename(normalizePath(case_dir)), primary_case_id)
      case_md_path <- file.path(case_dir, "case.md")
      plot_r_path <- file.path(case_dir, "plot.R")
      evidence_hashes_ok <- directory_ok &&
        file.exists(case_md_path) &&
        file.exists(plot_r_path) &&
        identical(
          tryCatch(
            figureforge_sha256(case_md_path),
            error = function(error) ""
          ),
          metadata$case_md_sha256
        ) &&
        identical(
          tryCatch(
            figureforge_sha256(plot_r_path),
            error = function(error) ""
          ),
          metadata$plot_r_sha256
        )

      qa_path <- file.path(case_dir, "qa.md")
      if (file.exists(qa_path)) {
        qa_lines <- trimws(readLines(qa_path, warn = FALSE))
        actual_qa_status <- if (
          any(tolower(qa_lines) == "status: verified")
        ) {
          "verified"
        } else if (
          any(tolower(qa_lines) == "status: review_required")
        ) {
          "review_required"
        } else {
          ""
        }
        qa_ok <- identical(qa_status, actual_qa_status) &&
          identical(metadata$qa_md_file, "qa.md") &&
          case_trace_sha256(metadata$qa_md_sha256) &&
          identical(
            tryCatch(
              figureforge_sha256(qa_path),
              error = function(error) ""
            ),
            metadata$qa_md_sha256
          )
      } else {
        qa_ok <- identical(qa_status, "missing") &&
          !any(c("qa_md_file", "qa_md_sha256") %in% names(metadata))
      }
    } else if (identical(qa_status, "missing")) {
      qa_ok <- !any(c("qa_md_file", "qa_md_sha256") %in% names(metadata))
    } else {
      qa_ok <- qa_ok &&
        identical(metadata$qa_md_file, "qa.md") &&
        case_trace_sha256(metadata$qa_md_sha256)
    }

    checks <- c(
      checks,
      "required case-based metadata" = case_keys_ok,
      "case.md evidence" = case_md_ok,
      "plot.R evidence" = plot_r_ok,
      "non-empty schema mapping" = mapping_ok,
      "concrete adopted patterns" = patterns_ok,
      "non-empty departures" = departures_ok,
      "evidence hashes match" = evidence_hashes_ok,
      "QA evidence matches case" = qa_ok
    )
  } else if (identical(mode, "general_fallback")) {
    fallback_ok <- case_trace_nonempty_keys(
      metadata,
      case_trace_fallback_keys()
    )
    forbidden_keys <- c(
      case_trace_case_based_keys(),
      "qa_md_file",
      "qa_md_sha256",
      "case_md_file",
      "case_md_sha256",
      "plot_r_file",
      "plot_r_sha256"
    )
    checks <- c(
      checks,
      "required fallback metadata" = fallback_ok,
      "non-empty fallback reason" = fallback_ok &&
        nzchar(trimws(metadata$fallback_reason)),
      "no primary case evidence" =
        !any(forbidden_keys %in% names(metadata))
    )
  }

  case_trace_result(
    checks,
    messages = if (parse_ok) character(0) else parse_error,
    evidence = list(
      generation_mode = mode,
      primary_case_id = primary_case_id,
      generated_script_sha256 = recorded_script_hash,
      qa_status = qa_status
    )
  )
}
