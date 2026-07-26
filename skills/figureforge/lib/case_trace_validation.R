case_trace_required_common_keys <- function() {
  c(
    "schema_version",
    "generation_mode",
    "figureforge_version",
    "generated_script_sha256",
    "claim",
    "search_query",
    "search_receipt_file",
    "search_receipt_sha256"
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

case_trace_safe_search_receipt_file <- function(value) {
  length(value) == 1L &&
    nzchar(trimws(value)) &&
    identical(value, basename(value)) &&
    !value %in% c(".", "..") &&
    !grepl("[/\\\\]", value, perl = TRUE) &&
    grepl("\\.csv$", value, perl = TRUE, ignore.case = TRUE)
}

case_trace_read_search_receipt <- function(path) {
  if (!case_trace_regular_nonempty_file(path)) {
    return(NULL)
  }
  tryCatch(
    read.csv(
      path,
      stringsAsFactors = FALSE,
      check.names = FALSE,
      fileEncoding = "UTF-8",
      na.strings = character(0),
      colClasses = "character"
    ),
    error = function(error) NULL
  )
}

case_trace_search_receipt_columns <- function() {
  c(
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
}

case_trace_search_receipt_schema_supported <- function(receipt) {
  if (
    is.null(receipt) ||
      nrow(receipt) < 1L ||
      !identical(
        names(receipt),
        case_trace_search_receipt_columns()
      )
  ) {
    return(FALSE)
  }
  case_hashes <- as.character(receipt$case_id_sha256)
  populated <- nzchar(case_hashes)
  ranks <- suppressWarnings(as.integer(receipt$result_rank))
  limits <- suppressWarnings(as.integer(receipt$search_limit))
  schema_hashes <- as.character(receipt$schema_sha256)
  base_ok <-
    all(as.character(receipt$receipt_schema_version) == "1") &&
    all(receipt$receipt_generator == "figureforge-search_cases") &&
    length(unique(receipt$search_query)) == 1L &&
    nzchar(trimws(receipt$search_query[[1L]])) &&
    length(unique(receipt$search_scope)) == 1L &&
    receipt$search_scope[[1L]] %in% c("public", "private") &&
    length(unique(schema_hashes)) == 1L &&
    (
      identical(schema_hashes[[1L]], "none") ||
        case_trace_sha256(schema_hashes[[1L]])
    ) &&
    length(unique(limits)) == 1L &&
    !is.na(limits[[1L]]) &&
    limits[[1L]] >= 1L &&
    length(unique(receipt$completed_only)) == 1L &&
    receipt$completed_only[[1L]] %in% c("TRUE", "FALSE") &&
    length(unique(receipt$explain_scores)) == 1L &&
    receipt$explain_scores[[1L]] %in% c("TRUE", "FALSE")
  if (!base_ok) {
    return(FALSE)
  }
  if (!any(populated)) {
    return(
      nrow(receipt) == 1L &&
        is.na(ranks[[1L]]) &&
        !nzchar(receipt$score[[1L]])
    )
  }
  all(populated) &&
    all(vapply(case_hashes, case_trace_sha256, logical(1L))) &&
    identical(ranks, seq_len(nrow(receipt))) &&
    !anyNA(suppressWarnings(as.numeric(receipt$score)))
}

case_trace_search_receipt_is_privacy_safe <- function(receipt) {
  if (
    !case_trace_search_receipt_schema_supported(receipt) ||
      any(c(
        "case_id",
        "title",
        "title_en",
        "title_zh",
        "case_path"
      ) %in% names(receipt))
  ) {
    return(FALSE)
  }
  values <- unlist(receipt, use.names = FALSE)
  !any(vapply(
    as.character(values),
    case_trace_has_absolute_path,
    logical(1L)
  ))
}

case_trace_search_receipt_matches_query <- function(receipt, query) {
  case_trace_search_receipt_schema_supported(receipt) &&
    length(query) == 1L &&
    !is.na(query) &&
    identical(receipt$search_query[[1L]], query)
}

case_trace_search_receipt_matches_mode <- function(
  receipt,
  generation_mode,
  primary_case_id = ""
) {
  if (
    is.null(receipt) ||
      !case_trace_search_receipt_schema_supported(receipt)
  ) {
    return(FALSE)
  }
  case_hashes <- as.character(receipt$case_id_sha256)
  if (identical(generation_mode, "case_based")) {
    return(
      nzchar(primary_case_id) &&
        figureforge_sha256_text(primary_case_id) %in% case_hashes
    )
  }
  identical(generation_mode, "general_fallback")
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
  source_reference <- trimws(substr(pattern, 1L, separator - 1L))
  generated_reference <- trimws(substr(
    pattern,
    separator + 2L,
    nchar(pattern)
  ))
  source_hashes <- gregexpr("#", source_reference, fixed = TRUE)[[1L]]
  generated_hashes <- gregexpr("#", generated_reference, fixed = TRUE)[[1L]]
  if (
    source_hashes[[1L]] < 0L ||
      length(source_hashes) != 1L ||
      generated_hashes[[1L]] < 0L ||
      length(generated_hashes) != 1L
  ) {
    return(NULL)
  }
  source_hash <- source_hashes[[1L]]
  generated_hash <- generated_hashes[[1L]]
  source_file <- trimws(substr(source_reference, 1L, source_hash - 1L))
  source_anchor <- trimws(substr(
    source_reference,
    source_hash + 1L,
    nchar(source_reference)
  ))
  generated_file <- trimws(substr(
    generated_reference,
    1L,
    generated_hash - 1L
  ))
  generated_anchor <- trimws(substr(
    generated_reference,
    generated_hash + 1L,
    nchar(generated_reference)
  ))
  list(
    source_file = source_file,
    source_anchor = source_anchor,
    generated_file = generated_file,
    generated_anchor = generated_anchor
  )
}

source_anchor_is_substantive <- function(anchor) {
  anchor <- trimws(anchor)
  code_points <- tryCatch(
    utf8ToInt(enc2utf8(anchor)),
    error = function(error) integer(0)
  )
  cjk_count <- sum(
    (code_points >= 0x3400L & code_points <= 0x4DBFL) |
      (code_points >= 0x4E00L & code_points <= 0x9FFFL) |
      (code_points >= 0xF900L & code_points <= 0xFAFFL)
  )
  if (cjk_count > 0L) {
    return(cjk_count >= 4L)
  }
  minimum_length <- if (grepl("::|_|\\(", anchor, perl = TRUE)) {
    4L
  } else {
    12L
  }
  nzchar(anchor) && nchar(anchor, type = "chars") >= minimum_length
}

generated_anchor_is_substantive <- function(anchor) {
  anchor <- gsub("\\s+", "", trimws(anchor), perl = TRUE)
  identifier <- "[A-Za-z.][A-Za-z0-9._]*"
  namespace_identifier <- sprintf("^%s::%s$", identifier, identifier)
  underscored_identifier <- sprintf("^%s$", identifier)
  function_call <- sprintf("^%s\\($", identifier)

  nchar(anchor, type = "chars") >= 4L && (
    grepl(namespace_identifier, anchor, perl = TRUE) ||
      (grepl("_", anchor, fixed = TRUE) &&
        grepl(underscored_identifier, anchor, perl = TRUE)) ||
      grepl(function_call, anchor, perl = TRUE)
  )
}

adopted_pattern_is_auditable <- function(pattern, qa_available = TRUE) {
  parsed <- parse_adopted_pattern(pattern)
  if (is.null(parsed)) {
    return(FALSE)
  }
  if (
    !parsed$source_file %in% c("case.md", "plot.R", "qa.md") ||
      (!qa_available && identical(parsed$source_file, "qa.md")) ||
      !identical(parsed$generated_file, "plot.R") ||
      !source_anchor_is_substantive(parsed$source_anchor) ||
      !generated_anchor_is_substantive(parsed$generated_anchor)
  ) {
    return(FALSE)
  }

  !case_trace_has_absolute_path(parsed$source_anchor) &&
    !case_trace_has_absolute_path(parsed$generated_anchor)
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

case_trace_regular_nonempty_file <- function(path) {
  regular <- tryCatch(
    isTRUE(file_test("-f", path)),
    error = function(error) FALSE
  )
  if (!regular) {
    return(FALSE)
  }
  size <- tryCatch(file.info(path)$size[[1L]], error = function(error) NA_real_)
  is.finite(size) && size > 0
}

case_trace_file_contains_anchor <- function(path, anchor) {
  if (!case_trace_regular_nonempty_file(path)) {
    return(FALSE)
  }
  lines <- suppressWarnings(
    tryCatch(
      readLines(path, warn = FALSE, encoding = "UTF-8"),
      error = function(error) NULL
    )
  )
  if (is.null(lines)) {
    return(FALSE)
  }
  grepl(
    tolower(anchor),
    tolower(paste(lines, collapse = "\n")),
    fixed = TRUE
  )
}

case_trace_r_code_tokens <- function(path) {
  if (!case_trace_regular_nonempty_file(path)) {
    return(NULL)
  }
  parsed_script <- suppressWarnings(
    tryCatch(
      parse(file = path, keep.source = TRUE),
      error = function(error) NULL
    )
  )
  if (is.null(parsed_script)) {
    return(NULL)
  }
  parse_data <- tryCatch(
    getParseData(parsed_script),
    error = function(error) NULL
  )
  if (is.null(parse_data) || nrow(parse_data) < 1L) {
    return(NULL)
  }
  parse_data <- parse_data[order(
    parse_data$line1,
    parse_data$col1,
    parse_data$id
  ), , drop = FALSE]
  code_tokens <- parse_data[
    parse_data$terminal %in% TRUE & parse_data$token != "COMMENT",
    c("token", "text"),
    drop = FALSE
  ]
  tolower(gsub(
    "\\s+",
    "",
    code_tokens$text,
    perl = TRUE
  ))
}

case_trace_r_code_contains_anchor <- function(normalized_tokens, anchor) {
  if (is.null(normalized_tokens)) {
    return(FALSE)
  }
  normalized_anchor <- tolower(gsub(
    "\\s+",
    "",
    trimws(anchor),
    perl = TRUE
  ))
  token_width <- if (grepl("::", normalized_anchor, fixed = TRUE)) {
    3L
  } else if (grepl("\\($", normalized_anchor, perl = TRUE)) {
    2L
  } else {
    1L
  }
  if (length(normalized_tokens) < token_width) {
    return(FALSE)
  }
  candidates <- vapply(
    seq_len(length(normalized_tokens) - token_width + 1L),
    function(index) paste0(
      normalized_tokens[index:(index + token_width - 1L)],
      collapse = ""
    ),
    character(1L)
  )
  normalized_anchor %in% candidates
}

case_trace_source_anchors_match <- function(value, case_dir) {
  patterns <- case_trace_adopted_pattern_items(value)
  parsed_patterns <- lapply(patterns, parse_adopted_pattern)
  if (
    length(parsed_patterns) < 1L ||
      any(vapply(parsed_patterns, is.null, logical(1L)))
  ) {
    return(FALSE)
  }
  plot_tokens <- case_trace_r_code_tokens(file.path(case_dir, "plot.R"))
  all(vapply(
    parsed_patterns,
    function(parsed) {
      if (identical(parsed$source_file, "plot.R")) {
        return(case_trace_r_code_contains_anchor(
          plot_tokens,
          parsed$source_anchor
        ))
      }
      case_trace_file_contains_anchor(
        file.path(case_dir, parsed$source_file),
        parsed$source_anchor
      )
    },
    logical(1L)
  ))
}

case_trace_generated_anchors_match <- function(value, script_path) {
  patterns <- case_trace_adopted_pattern_items(value)
  if (
    length(patterns) < 1L ||
      !case_trace_regular_nonempty_file(script_path)
  ) {
    return(FALSE)
  }
  normalized_tokens <- case_trace_r_code_tokens(script_path)
  length(patterns) > 0L && all(vapply(
    patterns,
    function(pattern) {
      parsed <- parse_adopted_pattern(pattern)
      !is.null(parsed) &&
        identical(basename(script_path), parsed$generated_file) &&
        case_trace_r_code_contains_anchor(
          normalized_tokens,
          parsed$generated_anchor
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
  search_receipt_file <- if (
    "search_receipt_file" %in% names(metadata)
  ) {
    metadata$search_receipt_file
  } else {
    ""
  }
  recorded_search_query <- if (
    "search_query" %in% names(metadata)
  ) {
    metadata$search_query
  } else {
    ""
  }
  recorded_search_receipt_hash <- if (
    "search_receipt_sha256" %in% names(metadata)
  ) {
    metadata$search_receipt_sha256
  } else {
    ""
  }
  search_receipt_file_safe <-
    case_trace_safe_search_receipt_file(search_receipt_file)
  search_receipt_path <- if (search_receipt_file_safe) {
    file.path(dirname(trace_path), search_receipt_file)
  } else {
    ""
  }
  search_receipt_hash_format_ok <-
    case_trace_sha256(recorded_search_receipt_hash)
  search_receipt_regular <- search_receipt_file_safe &&
    identical(Sys.readlink(search_receipt_path), "") &&
    case_trace_regular_nonempty_file(search_receipt_path)
  search_receipt_hash_matches <- search_receipt_regular &&
    search_receipt_hash_format_ok &&
    identical(
      suppressWarnings(
        tryCatch(
          figureforge_sha256(search_receipt_path),
          error = function(error) ""
        )
      ),
      recorded_search_receipt_hash
    )
  search_receipt <- if (search_receipt_regular) {
    case_trace_read_search_receipt(search_receipt_path)
  } else {
    NULL
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
      case_trace_regular_nonempty_file(script_path) &&
      identical(
        suppressWarnings(
          tryCatch(
            figureforge_sha256(script_path),
            error = function(error) ""
          )
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
    "search receipt filename is safe" = search_receipt_file_safe,
    "search receipt is regular non-empty CSV" =
      search_receipt_regular && !is.null(search_receipt),
    "search receipt schema is supported" =
      case_trace_search_receipt_schema_supported(search_receipt),
    "search receipt matches recorded query" =
      case_trace_search_receipt_matches_query(
        search_receipt,
        recorded_search_query
      ),
    "search receipt binds input schema" =
      case_trace_search_receipt_schema_supported(search_receipt) &&
        case_trace_sha256(search_receipt$schema_sha256[[1L]]),
    "search receipt content is privacy-safe" =
      case_trace_search_receipt_is_privacy_safe(search_receipt),
    "search receipt hash format" = search_receipt_hash_format_ok,
    "search receipt hash matches" = search_receipt_hash_matches,
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
    source_anchors_match <- FALSE
    generated_anchors_match <- FALSE
    if (!is.null(case_dir)) {
      directory_ok <- dir.exists(case_dir) &&
        identical(basename(normalizePath(case_dir)), primary_case_id)
      case_md_path <- file.path(case_dir, "case.md")
      plot_r_path <- file.path(case_dir, "plot.R")
      evidence_hashes_match <- directory_ok &&
        case_trace_regular_nonempty_file(case_md_path) &&
        case_trace_regular_nonempty_file(plot_r_path) &&
        identical(
          suppressWarnings(
            tryCatch(
              figureforge_sha256(case_md_path),
              error = function(error) ""
            )
          ),
          metadata$case_md_sha256
        ) &&
        identical(
          suppressWarnings(
            tryCatch(
              figureforge_sha256(plot_r_path),
              error = function(error) ""
            )
          ),
          metadata$plot_r_sha256
        )
      source_anchors_match <- patterns_ok &&
        directory_ok &&
        case_trace_source_anchors_match(
          metadata$adopted_patterns,
          case_dir
        )

      qa_path <- file.path(case_dir, "qa.md")
      if (case_trace_regular_nonempty_file(qa_path)) {
        qa_lines <- tryCatch(
          trimws(readLines(
            qa_path,
            warn = FALSE,
            encoding = "UTF-8"
          )),
          error = function(error) character(0)
        )
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
            suppressWarnings(
              tryCatch(
                figureforge_sha256(qa_path),
                error = function(error) ""
              )
            ),
            metadata$qa_md_sha256
          )
      } else {
        qa_matches <- qa_declared_ok &&
          identical(qa_status, "missing")
      }
    }
    if (!is.null(script_path)) {
      generated_anchors_match <- patterns_ok &&
        case_trace_generated_anchors_match(
          metadata$adopted_patterns,
          script_path
        )
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
      "QA evidence declared" = qa_declared_ok,
      "search receipt matches generation mode" =
        case_trace_search_receipt_matches_mode(
          search_receipt,
          mode,
          primary_case_id
        )
    )
    if (!is.null(case_dir)) {
      checks <- c(
        checks,
        "case evidence hashes match" = evidence_hashes_match,
        "source anchors match case evidence" =
          source_anchors_match,
        "QA evidence matches case" = qa_matches
      )
    }
    if (!is.null(script_path)) {
      checks <- c(
        checks,
        "generated anchors match script" =
          generated_anchors_match
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
      "search receipt matches generation mode" =
        case_trace_search_receipt_matches_mode(
          search_receipt,
          mode
        ),
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
      search_query = recorded_search_query,
      search_receipt_file = search_receipt_file,
      search_receipt_sha256 = recorded_search_receipt_hash,
      qa_status = qa_status,
      verification_level = verification_level,
      anchor_validation = if (identical(mode, "case_based")) {
        "anchor_presence"
      } else {
        "not_applicable"
      }
    )
  )
}
