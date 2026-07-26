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

case_trace_fallback_only_keys <- function() {
  c("fallback_reason", "considered_cases")
}

case_trace_nonempty_keys <- function(metadata, keys) {
  all(keys %in% names(metadata)) &&
    all(nzchar(vapply(metadata[keys], as.character, character(1L))))
}

case_trace_sha256 <- function(value) {
  length(value) == 1L &&
    grepl("^[0-9a-f]{64}$", value, perl = TRUE)
}

case_trace_verification_level <- function(
  generation_mode,
  case_dir,
  script_path
) {
  has_case_dir <- !is.null(case_dir)
  has_script_path <- !is.null(script_path)
  if (identical(generation_mode, "case_based")) {
    if (has_case_dir && has_script_path) {
      return("strict")
    }
    if (has_case_dir || has_script_path) {
      return("partial")
    }
    return("structural")
  }
  if (identical(generation_mode, "general_fallback")) {
    return(if (has_script_path) "strict" else "structural")
  }
  "structural"
}

case_trace_has_absolute_path <- function(value) {
  token_boundary <- "(^|[^[:alnum:]_./-])"
  network_boundary <- "(^|[^[:alnum:]_./:-])"
  grepl(
    paste(
      "(^|[^[:alnum:]_])file://",
      paste0(network_boundary, "//[^/[:space:]]+(?:/|$)"),
      paste0(token_boundary, "/(?!/)"),
      paste0(token_boundary, "[A-Za-z]:[\\\\/]"),
      paste0(token_boundary, "\\\\\\\\[^\\\\/]+[\\\\/]"),
      sep = "|"
    ),
    value,
    perl = TRUE,
    ignore.case = TRUE
  )
}

parse_adopted_pattern <- function(pattern) {
  pattern <- trimws(pattern)
  if (!nzchar(pattern) || grepl("|", pattern, fixed = TRUE)) {
    return(NULL)
  }
  separators <- gregexpr("=>", pattern, fixed = TRUE)[[1L]]
  if (separators[[1L]] < 0L || length(separators) != 1L) {
    return(NULL)
  }

  separator <- separators[[1L]]
  evidence_reference <- trimws(substr(pattern, 1L, separator - 1L))
  applied_decision <- trimws(substr(pattern, separator + 2L, nchar(pattern)))
  hashes <- gregexpr("#", evidence_reference, fixed = TRUE)[[1L]]
  if (hashes[[1L]] < 0L || length(hashes) != 1L) {
    return(NULL)
  }
  hash <- hashes[[1L]]
  evidence_file <- trimws(substr(evidence_reference, 1L, hash - 1L))
  source_anchor <- trimws(substr(
    evidence_reference,
    hash + 1L,
    nchar(evidence_reference)
  ))
  list(
    evidence_file = evidence_file,
    source_anchor = source_anchor,
    applied_decision = applied_decision
  )
}

adopted_pattern_is_auditable <- function(pattern, qa_available = TRUE) {
  parsed <- parse_adopted_pattern(pattern)
  if (is.null(parsed)) {
    return(FALSE)
  }
  if (
    !parsed$evidence_file %in% c("case.md", "plot.R", "qa.md") ||
      (!qa_available && identical(parsed$evidence_file, "qa.md")) ||
      nchar(parsed$source_anchor, type = "bytes") < 4L ||
      nchar(parsed$applied_decision, type = "bytes") < 8L ||
      identical(
        tolower(parsed$source_anchor),
        tolower(parsed$applied_decision)
      )
  ) {
    return(FALSE)
  }

  disallowed_generic_language <- c(
    "used colors",
    "used nice colors",
    "scientific plot",
    "nice aesthetics",
    "good figure",
    "pretty plot",
    "beautiful chart",
    "generic",
    "general",
    "使用漂亮颜色",
    "用了漂亮颜色",
    "漂亮颜色",
    "科学绘图",
    "科学图形",
    "制作科学图形",
    "漂亮美学",
    "好看图形",
    "好看的图",
    "漂亮",
    "好看",
    "通用"
  )
  normalized_values <- tolower(c(
    parsed$source_anchor,
    parsed$applied_decision
  ))
  generic_language <- vapply(
    disallowed_generic_language,
    function(term) any(grepl(
      tolower(term),
      normalized_values,
      fixed = TRUE
    )),
    logical(1L)
  )
  if (any(generic_language)) {
    return(FALSE)
  }

  !case_trace_has_absolute_path(parsed$source_anchor) &&
    !case_trace_has_absolute_path(parsed$applied_decision)
}

case_trace_adopted_pattern_items <- function(value) {
  if (grepl("^\\s*\\||\\|\\s*$|\\|\\s*\\|", value, perl = TRUE)) {
    return(character(0))
  }
  trimws(strsplit(value, "|", fixed = TRUE)[[1L]])
}

case_trace_patterns_are_concrete <- function(value, qa_available = TRUE) {
  patterns <- case_trace_adopted_pattern_items(value)
  length(patterns) > 0L &&
    all(nzchar(patterns)) &&
    all(vapply(
      patterns,
      adopted_pattern_is_auditable,
      logical(1L),
      qa_available = qa_available
    ))
}

case_trace_adopted_anchors_match <- function(value, case_dir) {
  patterns <- case_trace_adopted_pattern_items(value)
  length(patterns) > 0L && all(vapply(
    patterns,
    function(pattern) {
      parsed <- parse_adopted_pattern(pattern)
      if (is.null(parsed)) {
        return(FALSE)
      }
      evidence_path <- file.path(case_dir, parsed$evidence_file)
      if (!file.exists(evidence_path)) {
        return(FALSE)
      }
      evidence_text <- paste(
        readLines(evidence_path, warn = FALSE, encoding = "UTF-8"),
        collapse = "\n"
      )
      grepl(
        tolower(parsed$source_anchor),
        tolower(evidence_text),
        fixed = TRUE
      )
    },
    logical(1L)
  ))
}

case_trace_result <- function(checks, messages, evidence) {
  check_names <- names(checks)
  checks <- vapply(checks, isTRUE, logical(1L))
  names(checks) <- check_names
  if (exists("make_validation_result", mode = "function", inherits = TRUE)) {
    return(make_validation_result(
      checks,
      messages = messages,
      evidence = evidence
    ))
  }
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

  verification_level <- case_trace_verification_level(
    mode,
    case_dir,
    script_path
  )
  script_hash_format_ok <- case_trace_sha256(recorded_script_hash)
  script_hash_matches <- FALSE
  if (!is.null(script_path)) {
    script_hash_matches <- script_hash_format_ok &&
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
          identical(claim, "general_method"))
    ),
    "generated script hash format" = script_hash_format_ok,
    "no absolute paths" = path_ok,
    "no embedded newlines" = newline_ok
  )
  if (!is.null(script_path)) {
    checks <- c(
      checks,
      "generated script hash matches" = script_hash_matches
    )
  }

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
      case_trace_patterns_are_concrete(
        metadata$adopted_patterns,
        qa_available = !identical(qa_status, "missing")
      )
    departures_ok <- case_keys_ok && nzchar(trimws(metadata$departures))
    no_fallback_evidence <- !any(
      case_trace_fallback_only_keys() %in% names(metadata)
    )

    qa_declared_ok <- if (qa_status %in% c("verified", "review_required")) {
      identical(metadata$qa_md_file, "qa.md") &&
        case_trace_sha256(metadata$qa_md_sha256)
    } else {
      identical(qa_status, "missing") &&
        !any(c("qa_md_file", "qa_md_sha256") %in% names(metadata))
    }
    evidence_hashes_match <- FALSE
    qa_matches <- FALSE
    adopted_anchors_match <- FALSE
    if (!is.null(case_dir)) {
      directory_ok <- dir.exists(case_dir) &&
        identical(basename(normalizePath(case_dir)), primary_case_id)
      case_md_path <- file.path(case_dir, "case.md")
      plot_r_path <- file.path(case_dir, "plot.R")
      evidence_hashes_match <- directory_ok &&
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
      adopted_anchors_match <- patterns_ok &&
        directory_ok &&
        case_trace_adopted_anchors_match(
          metadata$adopted_patterns,
          case_dir
        )

      qa_path <- file.path(case_dir, "qa.md")
      if (file.exists(qa_path)) {
        qa_lines <- trimws(readLines(qa_path, warn = FALSE))
        qa_markers <- unique(tolower(qa_lines)[
          tolower(qa_lines) %in% c(
            "status: verified",
            "status: review_required"
          )
        ])
        actual_qa_status <- if (length(qa_markers) == 1L) {
          sub("^status:\\s*", "", qa_markers[[1L]], perl = TRUE)
        } else {
          ""
        }
        qa_matches <- qa_declared_ok &&
          identical(qa_status, actual_qa_status) &&
          identical(
            tryCatch(
              figureforge_sha256(qa_path),
              error = function(error) ""
            ),
            metadata$qa_md_sha256
          )
      } else {
        qa_matches <- qa_declared_ok &&
          identical(qa_status, "missing")
      }
    }

    checks <- c(
      checks,
      "required case-based metadata" = case_keys_ok,
      "case.md evidence declared" = case_md_ok,
      "plot.R evidence declared" = plot_r_ok,
      "non-empty schema mapping" = mapping_ok,
      "auditable adopted pattern format" = patterns_ok,
      "non-empty departures" = departures_ok,
      "no fallback-only evidence" = no_fallback_evidence,
      "QA evidence declared" = qa_declared_ok
    )
    if (!is.null(case_dir)) {
      checks <- c(
        checks,
        "case evidence hashes match" = evidence_hashes_match,
        "adopted pattern anchors match evidence" =
          adopted_anchors_match,
        "QA evidence matches case" = qa_matches
      )
    }
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
      qa_status = qa_status,
      verification_level = verification_level
    )
  )
}
