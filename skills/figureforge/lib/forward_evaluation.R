forward_evaluation_columns <- function() {
  c(
    "eval_id",
    "language",
    "outcome",
    "query",
    "expected_top1",
    "fixture_id",
    "expected_rejection"
  )
}

forward_rejection_categories <- function() {
  c(
    "missing_required_role",
    "incompatible_type",
    "incompatible_cardinality",
    "protected_output",
    "private_asset",
    "unsafe_transformation"
  )
}

read_forward_evaluations <- function(path) {
  if (!file.exists(path)) stop("Evaluation catalog does not exist: ", path)
  catalog <- read.csv(
    path,
    stringsAsFactors = FALSE,
    check.names = FALSE,
    na.strings = character(0),
    fileEncoding = "UTF-8"
  )
  missing <- setdiff(forward_evaluation_columns(), names(catalog))
  if (length(missing) > 0L) {
    stop("Evaluation catalog is missing columns: ", paste(missing, collapse = ", "))
  }
  catalog <- catalog[, forward_evaluation_columns(), drop = FALSE]
  if (nrow(catalog) != 30L) stop("Evaluation catalog must contain exactly 30 rows")
  expected_ids <- c(
    sprintf("eval-en-%03d", 1:15),
    sprintf("eval-zh-%03d", 1:15)
  )
  if (!identical(catalog$eval_id, expected_ids)) {
    stop("Evaluation IDs must be stable, ordered bilingual IDs")
  }
  language_counts <- table(catalog$language)
  if (!identical(
    stats::setNames(as.integer(language_counts), names(language_counts)),
    c(en = 15L, zh = 15L)
  )) {
    stop("Evaluation catalog must contain 15 English and 15 Chinese rows")
  }
  if (!all(catalog$outcome %in% c("select", "map_render", "reject"))) {
    stop("Evaluation outcomes must be select, map_render, or reject")
  }
  reject_rows <- catalog$outcome == "reject"
  if (!all(
    catalog$expected_rejection[reject_rows] %in%
      forward_rejection_categories()
  )) {
    stop("Reject evaluations require an exact supported rejection category")
  }
  if (any(nzchar(catalog$expected_rejection[!reject_rows]))) {
    stop("Only reject evaluations may declare expected_rejection")
  }
  catalog
}

evaluation_role_specs <- function(metadata) {
  required <- metadata$required_roles
  required$required <- rep(TRUE, nrow(required))
  optional <- metadata$optional_roles
  optional$required <- rep(FALSE, nrow(optional))
  rbind(required, optional)
}

evaluation_mapping_failure <- function(input, mapping, metadata, request) {
  if (identical(request$source_scope, "private")) return("private_asset")
  if (identical(request$output_scope, "protected")) return("protected_output")
  if (!all(c("role", "input_column") %in% names(mapping))) {
    return("missing_required_role")
  }
  transformations <- if ("transformation" %in% names(mapping)) {
    trimws(mapping$transformation)
  } else {
    rep("identity", nrow(mapping))
  }
  safe_transformations <- c("", "identity")
  if (any(!transformations %in% safe_transformations)) {
    return("unsafe_transformation")
  }
  mapped <- mapping[
    nzchar(trimws(mapping$role)) & nzchar(trimws(mapping$input_column)),
    ,
    drop = FALSE
  ]
  available_roles <- mapped$role[mapped$input_column %in% names(input)]
  if (!all(metadata$required_roles$role %in% available_roles)) {
    return("missing_required_role")
  }
  if (anyDuplicated(mapped$role) || anyDuplicated(mapped$input_column)) {
    return("unsafe_transformation")
  }

  profile <- profile_data_frame(input)
  specs <- evaluation_role_specs(metadata)
  for (index in seq_len(nrow(mapped))) {
    spec_index <- match(mapped$role[[index]], specs$role)
    profile_index <- match(mapped$input_column[[index]], profile$column)
    if (is.na(spec_index) || is.na(profile_index)) next
    expected_type <- specs$type[[spec_index]]
    actual_type <- profile$inferred_type[[profile_index]]
    type_ok <- identical(expected_type, actual_type) ||
      (
        expected_type %in% c("numeric", "integer") &&
          actual_type == "numeric"
      )
    if (!type_ok) return("incompatible_type")

    expected_cardinality <- specs$cardinality[[spec_index]]
    actual_cardinality <- profile$cardinality[[profile_index]]
    cardinality_ok <- identical(expected_cardinality, actual_cardinality) ||
      (
        expected_cardinality == "temporal" &&
          actual_type == "numeric"
      )
    if (!cardinality_ok) return("incompatible_cardinality")
  }
  ""
}

materialize_forward_mapping <- function(input, mapping) {
  canonical <- data.frame(row.names = seq_len(nrow(input)))
  for (index in seq_len(nrow(mapping))) {
    role <- trimws(mapping$role[[index]])
    input_column <- trimws(mapping$input_column[[index]])
    if (!nzchar(role) || !nzchar(input_column)) next
    canonical[[role]] <- input[[input_column]]
  }
  canonical
}

empty_forward_result <- function(row, actual_top1) {
  data.frame(
    eval_id = row$eval_id[[1L]],
    language = row$language[[1L]],
    outcome = row$outcome[[1L]],
    expected_top1 = row$expected_top1[[1L]],
    actual_top1 = actual_top1,
    top1_pass = NA,
    top3_pass = NA,
    mapping_pass = NA,
    render_pass = NA,
    rejection_pass = NA,
    passed = FALSE,
    details = "",
    stringsAsFactors = FALSE
  )
}

run_forward_evaluation <- function(
  row,
  repo_root,
  output_root,
  rscript
) {
  public_cases <- file.path(
    repo_root,
    "skills",
    "figureforge",
    "public-cases"
  )
  catalog <- build_public_catalog(public_cases)
  ranked <- rank_public_cases(catalog, row$query[[1L]], limit = 3L)
  top_ids <- ranked$case_id
  actual_top1 <- if (length(top_ids) > 0L) top_ids[[1L]] else ""
  result <- empty_forward_result(row, actual_top1)
  outcome <- row$outcome[[1L]]

  if (outcome != "reject") {
    expected <- row$expected_top1[[1L]]
    result$top1_pass <- identical(actual_top1, expected)
    result$top3_pass <- expected %in% top_ids
  }
  if (outcome == "select") {
    result$passed <- isTRUE(result$top1_pass) && isTRUE(result$top3_pass)
    result$details <- paste("top3:", paste(top_ids, collapse = "|"))
    return(result)
  }

  fixture_dir <- file.path(
    repo_root,
    "tests",
    "fixtures",
    "figureforge",
    "evaluations",
    row$fixture_id[[1L]]
  )
  request <- parse_simple_metadata(file.path(fixture_dir, "request.yml"))
  input <- read.csv(
    file.path(fixture_dir, "input.csv"),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  mapping <- read.csv(
    file.path(fixture_dir, "mapping.csv"),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  requested_case <- request$expected_case_id
  case_dir <- file.path(public_cases, requested_case)
  metadata <- if (dir.exists(case_dir)) {
    read_case_metadata(case_dir)
  } else {
    list(
      required_roles = data.frame(
        role = character(0),
        type = character(0),
        cardinality = character(0)
      ),
      optional_roles = data.frame(
        role = character(0),
        type = character(0),
        cardinality = character(0)
      )
    )
  }
  rejection <- evaluation_mapping_failure(
    input,
    mapping,
    metadata,
    request
  )

  if (outcome == "reject") {
    expected_rejection <- row$expected_rejection[[1L]]
    result$rejection_pass <- identical(rejection, expected_rejection)
    result$passed <- isTRUE(result$rejection_pass)
    result$details <- paste0(
      "expected_rejection=", expected_rejection,
      "; observed_rejection=", rejection
    )
    return(result)
  }

  result$mapping_pass <- !nzchar(rejection)
  evaluation_dir <- file.path(output_root, row$eval_id[[1L]])
  dir.create(evaluation_dir, recursive = TRUE, showWarnings = FALSE)
  canonical_path <- file.path(evaluation_dir, "input.csv")
  output_path <- file.path(evaluation_dir, "output.pdf")
  render_log <- file.path(evaluation_dir, "render.log")
  if (result$mapping_pass) {
    canonical <- materialize_forward_mapping(input, mapping)
    write.csv(
      canonical,
      canonical_path,
      row.names = FALSE,
      fileEncoding = "UTF-8",
      na = ""
    )
    render_status <- system2(
      rscript,
      shQuote(c(file.path(case_dir, "plot.R"), canonical_path, output_path)),
      stdout = render_log,
      stderr = render_log
    )
    result$render_pass <- identical(as.integer(render_status), 0L) &&
      file.exists(output_path) &&
      file.info(output_path)$size > 0L
  } else {
    result$render_pass <- FALSE
  }
  result$passed <- isTRUE(result$top1_pass) &&
    isTRUE(result$top3_pass) &&
    isTRUE(result$mapping_pass) &&
    isTRUE(result$render_pass)
  result$details <- paste0(
    "top3=", paste(top_ids, collapse = "|"),
    "; mapping_rejection=", rejection,
    "; output=", output_path
  )
  result
}

forward_rate <- function(values) {
  applicable <- !is.na(values)
  if (!any(applicable)) return(1)
  mean(values[applicable])
}

summarize_forward_evaluations <- function(report) {
  list(
    total = as.integer(nrow(report)),
    passed = as.integer(sum(report$passed)),
    top1_rate = forward_rate(report$top1_pass),
    top3_rate = forward_rate(report$top3_pass),
    mapping_rate = forward_rate(report$mapping_pass),
    render_rate = forward_rate(report$render_pass),
    rejection_rate = forward_rate(report$rejection_pass)
  )
}

forward_thresholds_pass <- function(summary) {
  identical(summary$total, 30L) &&
    summary$top1_rate >= 0.80 &&
    identical(summary$top3_rate, 1) &&
    identical(summary$mapping_rate, 1) &&
    identical(summary$render_rate, 1) &&
    identical(summary$rejection_rate, 1)
}
