materialize_stress_mapping <- function(input, mapping, metadata) {
  required_roles <- metadata$required_roles$role
  mapped_roles <- mapping$role[
    nzchar(mapping$role) & nzchar(mapping$input_column)
  ]
  missing_roles <- setdiff(required_roles, mapped_roles)
  missing_columns <- setdiff(mapping$input_column, names(input))
  if (length(missing_roles) > 0L || length(missing_columns) > 0L) {
    return(list(
      ok = FALSE,
      failure_category = "missing_required_role",
      data = NULL
    ))
  }
  if (anyDuplicated(mapping$role)) {
    return(list(
      ok = FALSE,
      failure_category = "ambiguous_mapping",
      data = NULL
    ))
  }
  canonical <- data.frame(row.names = seq_len(nrow(input)))
  for (row_index in seq_len(nrow(mapping))) {
    role <- mapping$role[[row_index]]
    input_column <- mapping$input_column[[row_index]]
    canonical[[role]] <- input[[input_column]]
  }
  list(ok = TRUE, failure_category = "", data = canonical)
}

stress_invalid_value <- function(case_id, data) {
  if (case_id == "public-enrichment-bubble") {
    values <- suppressWarnings(as.numeric(data$adjusted_p))
    return(any(!is.finite(values)) || any(values <= 0 | values > 1))
  }
  if (case_id == "public-gene-structure") {
    starts <- suppressWarnings(as.numeric(data$start))
    ends <- suppressWarnings(as.numeric(data$end))
    return(
      any(!is.finite(starts)) ||
      any(!is.finite(ends)) ||
      any(starts < 0 | ends <= starts)
    )
  }
  if (case_id == "public-correlation-heatmap") {
    values <- suppressWarnings(as.numeric(data$correlation))
    return(any(!is.finite(values)) || any(values < -1 | values > 1))
  }
  if (case_id == "public-survival") {
    values <- lapply(
      data[c("time", "survival", "lower", "upper")],
      function(column) suppressWarnings(as.numeric(column))
    )
    time <- values$time
    survival <- values$survival
    lower <- values$lower
    upper <- values$upper
    return(
      any(!is.finite(unlist(values))) ||
      any(time < 0) ||
      any(lower < 0 | upper > 1) ||
      any(lower > survival | survival > upper)
    )
  }
  if (case_id == "public-volcano") {
    values <- suppressWarnings(as.numeric(data$adjusted_p))
    return(any(!is.finite(values)) || any(values <= 0 | values > 1))
  }
  FALSE
}

stress_duplicate_key <- function(case_id, data) {
  if (case_id == "public-timeseries-band") {
    return(anyDuplicated(data[c("group", "time")]) > 0L)
  }
  FALSE
}

stress_referential_failure <- function(case_id, data) {
  if (case_id == "public-network") {
    nodes <- data[data$record_type == "node", , drop = FALSE]
    edges <- data[data$record_type == "edge", , drop = FALSE]
    return(
      any(!edges$source %in% nodes$node_id) ||
      any(!edges$target %in% nodes$node_id)
    )
  }
  if (case_id == "public-phylogeny-annotation") {
    parent <- as.character(data$parent)
    non_root <- !is.na(parent) & nzchar(parent)
    return(any(!parent[non_root] %in% data$node))
  }
  FALSE
}

validate_stress_data <- function(case_id, data) {
  if (stress_duplicate_key(case_id, data)) {
    return("duplicate_key")
  }
  if (stress_referential_failure(case_id, data)) {
    return("referential_integrity")
  }
  if (stress_invalid_value(case_id, data)) {
    return("invalid_value")
  }
  ""
}

run_stress_fixture <- function(
  fixture_dir,
  public_cases_dir,
  output_dir,
  rscript = "/usr/local/bin/Rscript"
) {
  fixture <- parse_simple_metadata(file.path(fixture_dir, "fixture.yml"))
  case_id <- fixture$public_case_id
  case_dir <- file.path(public_cases_dir, case_id)
  metadata <- read_case_metadata(case_dir)
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
  fixture_output_dir <- file.path(output_dir, fixture$fixture_id)
  dir.create(fixture_output_dir, recursive = TRUE, showWarnings = FALSE)
  canonical_path <- file.path(fixture_output_dir, "input.csv")
  output_path <- file.path(fixture_output_dir, "output.pdf")

  mapped <- materialize_stress_mapping(input, mapping, metadata)
  failure_category <- mapped$failure_category
  if (mapped$ok) {
    failure_category <- validate_stress_data(case_id, mapped$data)
  }
  observed_outcome <- if (nzchar(failure_category)) "failure" else "success"

  if (observed_outcome == "success") {
    write.csv(
      mapped$data,
      canonical_path,
      row.names = FALSE,
      fileEncoding = "UTF-8",
      na = ""
    )
    log_path <- file.path(fixture_output_dir, "render.log")
    render_status <- system2(
      rscript,
      shQuote(c(
        file.path(case_dir, "plot.R"),
        canonical_path,
        output_path
      )),
      stdout = log_path,
      stderr = log_path
    )
    if (!identical(as.integer(render_status), 0L) ||
        !file.exists(output_path) ||
        file.info(output_path)$size <= 0L) {
      observed_outcome <- "failure"
      failure_category <- "render_error"
    }
  }

  expected_failure <- fixture$failure_category
  if (identical(expected_failure, "none")) expected_failure <- ""
  passed <- identical(observed_outcome, fixture$outcome) &&
    (
      observed_outcome == "success" ||
      identical(failure_category, expected_failure)
    )
  data.frame(
    fixture_id = fixture$fixture_id,
    public_case_id = case_id,
    chart_family = fixture$chart_family,
    synthetic_test_fixture = identical(
      fixture$synthetic_test_fixture,
      "true"
    ),
    expected_outcome = fixture$outcome,
    observed_outcome = observed_outcome,
    failure_category = failure_category,
    output_path = output_path,
    passed = passed,
    stringsAsFactors = FALSE
  )
}

run_stress_suite <- function(
  fixtures_dir,
  public_cases_dir,
  output_dir,
  rscript = "/usr/local/bin/Rscript"
) {
  if (!file.exists(file.path(fixtures_dir, "manifest.csv"))) {
    stop("Missing stress manifest: ", fixtures_dir)
  }
  if (dir.exists(output_dir) &&
      length(list.files(output_dir, all.files = TRUE, no.. = TRUE)) > 0L) {
    stop("Stress output directory must be empty: ", output_dir)
  }
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  manifest <- read.csv(
    file.path(fixtures_dir, "manifest.csv"),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  rows <- lapply(manifest$fixture_id, function(fixture_id) {
    run_stress_fixture(
      file.path(fixtures_dir, fixture_id),
      public_cases_dir,
      output_dir,
      rscript = rscript
    )
  })
  results <- do.call(rbind, rows)
  results[order(results$fixture_id), , drop = FALSE]
}
