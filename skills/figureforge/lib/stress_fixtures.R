stress_fixture_specs <- function() {
  data.frame(
    fixture_id = c(
      "bar-chinese-columns",
      "bar-renamed-en",
      "distribution-missing-values",
      "distribution-outliers",
      "enrichment-sparse-groups",
      "enrichment-zero-p",
      "gene-negative-coordinate",
      "gene-overlapping-features",
      "heatmap-invalid-correlation",
      "heatmap-reordered-factors",
      "multipanel-many-facets",
      "multipanel-missing-optional",
      "network-chinese-labels",
      "network-unknown-node",
      "phylogeny-missing-parent",
      "phylogeny-reordered-nodes",
      "scatter-long-labels",
      "scatter-missing-required",
      "survival-imbalanced-groups",
      "survival-invalid-probability",
      "timeseries-duplicate-key",
      "timeseries-irregular-dates",
      "volcano-large-input",
      "volcano-negative-p"
    ),
    public_case_id = c(
      "public-bar-grouped",
      "public-bar-grouped",
      "public-distribution-raincloud",
      "public-distribution-raincloud",
      "public-enrichment-bubble",
      "public-enrichment-bubble",
      "public-gene-structure",
      "public-gene-structure",
      "public-correlation-heatmap",
      "public-correlation-heatmap",
      "public-multipanel",
      "public-multipanel",
      "public-network",
      "public-network",
      "public-phylogeny-annotation",
      "public-phylogeny-annotation",
      "public-scatter-fit",
      "public-scatter-fit",
      "public-survival",
      "public-survival",
      "public-timeseries-band",
      "public-timeseries-band",
      "public-volcano",
      "public-volcano"
    ),
    chart_family = c(
      "bar", "bar",
      "distribution", "distribution",
      "enrichment", "enrichment",
      "gene_structure", "gene_structure",
      "heatmap", "heatmap",
      "composition", "composition",
      "network", "network",
      "tree", "tree",
      "scatter", "scatter",
      "survival", "survival",
      "time_series", "time_series",
      "omics", "omics"
    ),
    outcome = c(
      "success", "success",
      "success", "success",
      "success", "failure",
      "failure", "success",
      "failure", "success",
      "success", "success",
      "success", "failure",
      "failure", "success",
      "success", "failure",
      "success", "failure",
      "failure", "success",
      "success", "failure"
    ),
    failure_category = c(
      "", "",
      "", "",
      "", "invalid_value",
      "invalid_value", "",
      "invalid_value", "",
      "", "",
      "", "referential_integrity",
      "referential_integrity", "",
      "", "missing_required_role",
      "", "invalid_value",
      "duplicate_key", "",
      "", "invalid_value"
    ),
    seed = 2101:2124,
    synthetic_test_fixture = TRUE,
    stringsAsFactors = FALSE
  )
}

identity_mapping <- function(data) {
  data.frame(
    role = names(data),
    input_column = names(data),
    required = TRUE,
    stringsAsFactors = FALSE
  )
}

rename_fixture_columns <- function(data, replacements) {
  mapping <- identity_mapping(data)
  for (role in names(replacements)) {
    names(data)[names(data) == role] <- replacements[[role]]
    mapping$input_column[mapping$role == role] <- replacements[[role]]
  }
  list(data = data, mapping = mapping)
}

transform_stress_fixture <- function(fixture_id, data) {
  result <- list(data = data, mapping = identity_mapping(data))
  if (fixture_id == "bar-chinese-columns") {
    return(rename_fixture_columns(
      data,
      c(treatment = "处理", response = "响应值", condition = "条件")
    ))
  }
  if (fixture_id == "bar-renamed-en") {
    return(rename_fixture_columns(
      data,
      c(treatment = "arm", response = "measurement", condition = "state")
    ))
  }
  if (fixture_id == "distribution-missing-values") {
    data$sample_id[[1L]] <- ""
  }
  if (fixture_id == "distribution-outliers") {
    data$value[[nrow(data)]] <- 50
  }
  if (fixture_id == "enrichment-sparse-groups") {
    data$category <- paste0("Category_", seq_len(nrow(data)))
  }
  if (fixture_id == "enrichment-zero-p") {
    data$adjusted_p[[1L]] <- 0
  }
  if (fixture_id == "gene-negative-coordinate") {
    data$start[[1L]] <- -10
  }
  if (fixture_id == "gene-overlapping-features") {
    data$start[[2L]] <- 120
  }
  if (fixture_id == "heatmap-invalid-correlation") {
    data$correlation[[1L]] <- 1.5
  }
  if (fixture_id == "heatmap-reordered-factors") {
    data <- data[nrow(data):1L, , drop = FALSE]
  }
  if (fixture_id == "multipanel-many-facets") {
    copies <- lapply(seq_len(6L), function(index) {
      copy <- data[data$panel == "Panel_A", , drop = FALSE]
      copy$panel <- paste0("Panel_", LETTERS[[index]])
      copy$y <- copy$y + index / 3
      copy$lower <- copy$lower + index / 3
      copy$upper <- copy$upper + index / 3
      copy
    })
    data <- do.call(rbind, copies)
    rownames(data) <- NULL
  }
  if (fixture_id == "network-chinese-labels") {
    node_rows <- data$record_type == "node"
    data$node_label[node_rows] <- c("甲", "乙", "丙", "丁")
  }
  if (fixture_id == "network-unknown-node") {
    edge_row <- which(data$record_type == "edge")[[1L]]
    data$target[[edge_row]] <- "UNKNOWN"
  }
  if (fixture_id == "phylogeny-missing-parent") {
    data$parent[[2L]] <- "UNKNOWN"
  }
  if (fixture_id == "phylogeny-reordered-nodes") {
    data <- data[c(7L, 3L, 1L, 5L, 2L, 6L, 4L), , drop = FALSE]
  }
  if (fixture_id == "scatter-long-labels") {
    data$label <- paste0(
      data$label,
      "_a_deliberately_long_synthetic_observation_label"
    )
  }
  if (fixture_id == "scatter-missing-required") {
    data$response <- NULL
  }
  if (fixture_id == "survival-imbalanced-groups") {
    treatment_rows <- which(data$group == "Treatment")
    data <- data[-treatment_rows[-c(1L, length(treatment_rows))], , drop = FALSE]
  }
  if (fixture_id == "survival-invalid-probability") {
    data$survival[[2L]] <- 1.2
  }
  if (fixture_id == "timeseries-duplicate-key") {
    data <- rbind(data, data[1L, , drop = FALSE])
  }
  if (fixture_id == "timeseries-irregular-dates") {
    irregular <- c(0, 1, 3, 7, 12)
    data$time <- rep(irregular, length.out = nrow(data))
  }
  if (fixture_id == "volcano-large-input") {
    count <- 2000L
    fold_change <- seq(-3.5, 3.5, length.out = count)
    adjusted_p <- pmax(1e-6, pmin(0.99, abs(sin(seq_len(count))) / 5))
    class <- ifelse(
      adjusted_p < 0.05 & fold_change <= -1,
      "Down",
      ifelse(
        adjusted_p < 0.05 & fold_change >= 1,
        "Up",
        "Not_significant"
      )
    )
    data <- data.frame(
      feature = sprintf("SYN%04d", seq_len(count)),
      log2_fold_change = fold_change,
      adjusted_p = adjusted_p,
      class = class,
      stringsAsFactors = FALSE
    )
  }
  if (fixture_id == "volcano-negative-p") {
    data$adjusted_p[[1L]] <- -0.01
  }
  result$data <- data
  result$mapping <- result$mapping[
    result$mapping$input_column %in% names(data),
    ,
    drop = FALSE
  ]
  result
}

write_fixture_metadata <- function(spec, path) {
  error_value <- if (nzchar(spec$failure_category)) {
    spec$failure_category
  } else {
    "none"
  }
  writeLines(
    c(
      "schema_version: 1",
      paste0("fixture_id: ", spec$fixture_id),
      "synthetic_test_fixture: true",
      "scientific_claims: none",
      paste0("public_case_id: ", spec$public_case_id),
      paste0("chart_family: ", spec$chart_family),
      paste0("outcome: ", spec$outcome),
      paste0("failure_category: ", error_value),
      paste0("seed: ", spec$seed)
    ),
    path,
    useBytes = TRUE
  )
}

generate_stress_fixtures <- function(output_dir, public_cases_dir) {
  if (!dir.exists(public_cases_dir)) {
    stop("Public cases directory does not exist: ", public_cases_dir)
  }
  if (dir.exists(output_dir) &&
      length(list.files(output_dir, all.files = TRUE, no.. = TRUE)) > 0L) {
    stop("Stress fixture output directory must be empty: ", output_dir)
  }
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  specs <- stress_fixture_specs()
  for (row_index in seq_len(nrow(specs))) {
    spec <- specs[row_index, , drop = FALSE]
    source_path <- file.path(
      public_cases_dir,
      spec$public_case_id,
      "data.csv"
    )
    if (!file.exists(source_path)) {
      stop("Missing public case data: ", source_path)
    }
    data <- read.csv(
      source_path,
      stringsAsFactors = FALSE,
      check.names = FALSE
    )
    transformed <- transform_stress_fixture(spec$fixture_id, data)
    fixture_dir <- file.path(output_dir, spec$fixture_id)
    dir.create(fixture_dir, recursive = TRUE, showWarnings = FALSE)
    write_fixture_metadata(spec, file.path(fixture_dir, "fixture.yml"))
    write.csv(
      transformed$data,
      file.path(fixture_dir, "input.csv"),
      row.names = FALSE,
      fileEncoding = "UTF-8",
      na = ""
    )
    write.csv(
      transformed$mapping,
      file.path(fixture_dir, "mapping.csv"),
      row.names = FALSE,
      fileEncoding = "UTF-8",
      na = ""
    )
  }
  write.csv(
    specs,
    file.path(output_dir, "manifest.csv"),
    row.names = FALSE,
    fileEncoding = "UTF-8",
    na = ""
  )
  invisible(specs)
}
