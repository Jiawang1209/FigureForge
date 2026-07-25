parse_simple_metadata <- function(path) {
  if (!file.exists(path)) {
    stop("Metadata file does not exist: ", path)
  }
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  lines <- trimws(lines)
  lines <- lines[nzchar(lines) & !startsWith(lines, "#")]
  separators <- regexpr(":", lines, fixed = TRUE)
  invalid <- separators < 1L
  if (any(invalid)) {
    stop("Invalid metadata line: ", lines[which(invalid)[[1L]]])
  }
  keys <- trimws(substr(lines, 1L, separators - 1L))
  values <- trimws(substr(lines, separators + 1L, nchar(lines)))
  if (any(!nzchar(keys))) {
    stop("Metadata keys must not be empty")
  }
  if (anyDuplicated(keys)) {
    stop("Duplicate metadata key")
  }
  stats::setNames(as.list(values), keys)
}

supported_public_licenses <- function() {
  c(
    "CC0-1.0",
    "MIT",
    "BSD-3-Clause",
    "public-domain",
    "CC-BY-4.0",
    "generated-by-FigureForge"
  )
}

authentic_source_required_keys <- function() {
  c(
    "schema_version",
    "source_type",
    "publisher",
    "dataset_title",
    "canonical_url",
    "retrieval_url",
    "retrieval_date",
    "upstream_version",
    "upstream_sha256",
    "normalized_sha256",
    "license",
    "license_url",
    "attribution",
    "selected_fields",
    "normalization",
    "synthetic_test_fixture",
    "scientific_claims"
  )
}

distribution_required_keys <- function() {
  c(
    "schema_version",
    "distribution_status",
    "synthetic_test_fixture",
    "scientific_claims",
    "origin",
    "copyright_holder",
    "license",
    "review_date",
    "reviewer",
    "assets"
  )
}

metadata_flag <- function(value) {
  identical(tolower(trimws(value %||% "")), "true")
}

`%||%` <- function(value, fallback) {
  if (is.null(value) || length(value) == 0L) fallback else value
}

distribution_regular_files <- function(case_dir) {
  relative_paths <- list.files(
    case_dir,
    all.files = TRUE,
    no.. = TRUE,
    recursive = TRUE,
    include.dirs = FALSE
  )
  relative_paths <- gsub("\\\\", "/", relative_paths)
  sort(relative_paths[file.exists(file.path(case_dir, relative_paths))])
}

validate_distribution <- function(case_dir) {
  if (!dir.exists(case_dir)) {
    stop("Case directory does not exist: ", case_dir)
  }
  case_dir <- normalizePath(case_dir, mustWork = TRUE)
  distribution_path <- file.path(case_dir, "distribution.yml")

  metadata <- tryCatch(
    parse_simple_metadata(distribution_path),
    error = function(error) structure(
      list(),
      parse_error = conditionMessage(error)
    )
  )
  parse_ok <- is.null(attr(metadata, "parse_error"))
  required_keys <- distribution_required_keys()
  keys_present <- parse_ok &&
    all(required_keys %in% names(metadata)) &&
    all(nzchar(vapply(
      metadata[required_keys],
      as.character,
      character(1)
    )))

  assets <- if (keys_present) {
    unique(trimws(strsplit(metadata$assets, "|", fixed = TRUE)[[1L]]))
  } else {
    character(0)
  }
  assets <- sort(assets[nzchar(assets)])
  actual_files <- distribution_regular_files(case_dir)
  source_type <- if (keys_present &&
      identical(metadata$source_type %||% "", "authentic_open_data")) {
    "authentic_open_data"
  } else {
    "synthetic_test_fixture"
  }
  authentic <- identical(source_type, "authentic_open_data")

  source_path <- file.path(case_dir, "source.yml")
  source <- if (authentic && file.exists(source_path)) {
    tryCatch(
      parse_simple_metadata(source_path),
      error = function(error) structure(
        list(),
        parse_error = conditionMessage(error)
      )
    )
  } else {
    structure(list(), parse_error = "source.yml is missing")
  }
  source_parse_ok <- authentic && is.null(attr(source, "parse_error"))
  source_keys <- authentic_source_required_keys()
  source_metadata_ok <- source_parse_ok &&
    all(source_keys %in% names(source)) &&
    all(nzchar(vapply(source[source_keys], as.character, character(1)))) &&
    identical(source$schema_version, "1") &&
    identical(source$source_type, "authentic_open_data") &&
    identical(tolower(source$synthetic_test_fixture), "false") &&
    identical(source$scientific_claims, "descriptive_only") &&
    identical(source$license, metadata$license %||% "") &&
    grepl("^[0-9a-f]{64}$", source$upstream_sha256, perl = TRUE) &&
    grepl("^[0-9a-f]{64}$", source$normalized_sha256, perl = TRUE)
  checksum_ok <- source_metadata_ok &&
    file.exists(file.path(case_dir, "data.csv")) &&
    identical(
      figureforge_sha256(file.path(case_dir, "data.csv")),
      source$normalized_sha256
    )

  qa_path <- file.path(case_dir, "qa.md")
  qa_lines <- if (file.exists(qa_path)) {
    trimws(readLines(qa_path, warn = FALSE))
  } else {
    character(0)
  }
  qa_status <- if (any(tolower(qa_lines) == "status: verified")) {
    "verified"
  } else if (any(tolower(qa_lines) == "status: review_required")) {
    "review_required"
  } else {
    ""
  }

  checks <- c(
    "distribution metadata parses" = parse_ok,
    "required distribution metadata" = keys_present,
    "supported distribution schema" = keys_present && (
      (!authentic && identical(metadata$schema_version, "1")) ||
        (authentic && identical(metadata$schema_version, "2"))
    ),
    "public distribution status" = keys_present &&
      identical(metadata$distribution_status, "public_ready"),
    "recognized redistribution basis" = keys_present &&
      metadata$license %in% supported_public_licenses(),
    "data source disclosure" = keys_present && (
      (!authentic &&
        metadata_flag(metadata$synthetic_test_fixture) &&
        identical(tolower(metadata$scientific_claims), "none")) ||
        (authentic &&
          !metadata_flag(metadata$synthetic_test_fixture) &&
          identical(
            tolower(metadata$scientific_claims),
            "descriptive_only"
          ))
    ),
    "authentic source metadata" = !authentic || source_metadata_ok,
    "normalized data checksum" = !authentic || checksum_ok,
    "all distributed files allowlisted" = keys_present &&
      setequal(actual_files, assets),
    "all allowlisted files exist" = keys_present &&
      all(file.exists(file.path(case_dir, assets))),
    "QA status matches source type" = file.exists(qa_path) && (
      (!authentic && identical(qa_status, "review_required")) ||
        (authentic && identical(qa_status, "verified"))
    )
  )

  list(
    ok = all(checks),
    status = if (keys_present) metadata$distribution_status else "",
    synthetic_test_fixture = keys_present &&
      metadata_flag(metadata$synthetic_test_fixture),
    source_type = source_type,
    qa_status = qa_status,
    checks = checks,
    failed_checks = names(checks)[!checks],
    assets = assets,
    metadata = metadata
  )
}
