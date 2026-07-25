metadata_pipe_values <- function(value) {
  if (is.null(value) || length(value) == 0L || !nzchar(trimws(value))) {
    return(character(0))
  }
  values <- trimws(strsplit(value, "|", fixed = TRUE)[[1L]])
  unique(values[nzchar(values)])
}

parse_role_spec <- function(value) {
  specifications <- metadata_pipe_values(value)
  empty <- data.frame(
    role = character(0),
    type = character(0),
    cardinality = character(0),
    stringsAsFactors = FALSE
  )
  if (length(specifications) == 0L) {
    return(empty)
  }
  parts <- strsplit(specifications, ":", fixed = TRUE)
  if (any(lengths(parts) != 3L)) {
    stop(
      "Role specifications must use role:type:cardinality: ",
      specifications[which(lengths(parts) != 3L)[[1L]]]
    )
  }
  data.frame(
    role = trimws(vapply(parts, `[[`, character(1), 1L)),
    type = trimws(vapply(parts, `[[`, character(1), 2L)),
    cardinality = trimws(vapply(parts, `[[`, character(1), 3L)),
    stringsAsFactors = FALSE
  )
}

figureforge_public_taxonomy <- function() {
  data.frame(
    family = c(
      "bar",
      "distribution",
      "scatter",
      "time_series",
      "heatmap",
      "enrichment",
      "omics",
      "network",
      "survival",
      "tree",
      "gene_structure",
      "composition"
    ),
    subfamily = c(
      "grouped_stacked",
      "box_violin_raincloud",
      "fitted_scatter",
      "uncertainty_band",
      "correlation",
      "bubble",
      "volcano",
      "node_edge",
      "kaplan_meier",
      "phylogeny_annotation",
      "feature_track",
      "multi_panel"
    ),
    title_en = c(
      "Grouped or stacked bar",
      "Distribution comparison",
      "Fitted scatter",
      "Time series with uncertainty",
      "Correlation heatmap",
      "Enrichment bubble",
      "Volcano plot",
      "Node edge network",
      "Kaplan Meier curve",
      "Annotated phylogeny",
      "Gene feature track",
      "Multi panel composition"
    ),
    title_zh = c(
      "分组或堆积柱状图",
      "箱线小提琴或雨云图",
      "散点拟合图",
      "带不确定性的时序图",
      "相关性热图",
      "富集气泡图",
      "火山图",
      "节点边网络图",
      "生存曲线",
      "带注释进化树",
      "基因结构图",
      "多面板组合图"
    ),
    stringsAsFactors = FALSE
  )
}

case_metadata_required_keys <- function() {
  c(
    "schema_version",
    "case_id",
    "title_en",
    "title_zh",
    "chart_family",
    "chart_subfamily",
    "aliases_en",
    "aliases_zh",
    "scientific_intents",
    "required_roles",
    "optional_roles",
    "annotations",
    "layouts",
    "required_packages",
    "optional_packages",
    "qa_status",
    "distribution_status",
    "synthetic_test_fixture"
  )
}

read_case_metadata <- function(case_dir) {
  metadata_path <- file.path(case_dir, "case.yml")
  raw <- parse_simple_metadata(metadata_path)
  value <- function(key) as.character(raw[[key]] %||% "")
  list(
    schema_version = value("schema_version"),
    case_id = value("case_id"),
    title_en = value("title_en"),
    title_zh = value("title_zh"),
    chart_family = value("chart_family"),
    chart_subfamily = value("chart_subfamily"),
    aliases_en = metadata_pipe_values(value("aliases_en")),
    aliases_zh = metadata_pipe_values(value("aliases_zh")),
    scientific_intents = metadata_pipe_values(value("scientific_intents")),
    required_roles = parse_role_spec(value("required_roles")),
    optional_roles = parse_role_spec(value("optional_roles")),
    annotations = metadata_pipe_values(value("annotations")),
    layouts = metadata_pipe_values(value("layouts")),
    required_packages = metadata_pipe_values(value("required_packages")),
    optional_packages = metadata_pipe_values(value("optional_packages")),
    qa_status = value("qa_status"),
    distribution_status = value("distribution_status"),
    synthetic_test_fixture = metadata_flag(value("synthetic_test_fixture")),
    raw_keys = names(raw),
    case_path = normalizePath(case_dir, mustWork = TRUE)
  )
}

validate_case_metadata <- function(metadata) {
  taxonomy <- figureforge_public_taxonomy()
  taxonomy_key <- paste(taxonomy$family, taxonomy$subfamily, sep = "/")
  metadata_key <- paste(
    metadata$chart_family %||% "",
    metadata$chart_subfamily %||% "",
    sep = "/"
  )
  roles <- rbind(
    metadata$required_roles,
    metadata$optional_roles
  )
  supported_types <- c(
    "character",
    "numeric",
    "integer",
    "logical",
    "date",
    "datetime"
  )
  supported_cardinalities <- c(
    "continuous",
    "categorical",
    "identifier",
    "temporal"
  )
  raw_keys <- metadata$raw_keys %||% character(0)

  checks <- c(
    "required metadata keys" = all(
      case_metadata_required_keys() %in% raw_keys
    ),
    "supported metadata schema" = identical(metadata$schema_version, "1"),
    "stable public case ID" = grepl(
      "^public-[a-z0-9]+(?:-[a-z0-9]+)*$",
      metadata$case_id,
      perl = TRUE
    ),
    "bilingual titles and aliases" =
      nzchar(metadata$title_en) &&
      nzchar(metadata$title_zh) &&
      length(metadata$aliases_en) > 0L &&
      length(metadata$aliases_zh) > 0L,
    "known chart taxonomy" = metadata_key %in% taxonomy_key,
    "required schema roles" = nrow(metadata$required_roles) > 0L,
    "unique schema roles" = !anyDuplicated(roles$role),
    "supported schema role types" =
      all(roles$type %in% supported_types) &&
      all(roles$cardinality %in% supported_cardinalities),
    "declared required packages" =
      length(metadata$required_packages) > 0L,
    "QA remains review required" =
      identical(metadata$qa_status, "review_required"),
    "public distribution status" =
      identical(metadata$distribution_status, "public_ready"),
    "synthetic fixture disclosure" =
      isTRUE(metadata$synthetic_test_fixture)
  )
  list(
    ok = all(checks),
    checks = checks,
    failed_checks = names(checks)[!checks]
  )
}

collapse_metadata_values <- function(values) {
  paste(values, collapse = "|")
}

collapse_role_specs <- function(roles) {
  if (nrow(roles) == 0L) {
    return("")
  }
  paste(
    roles$role,
    roles$type,
    roles$cardinality,
    sep = ":",
    collapse = "|"
  )
}

empty_public_catalog <- function() {
  data.frame(
    schema_version = character(0),
    case_id = character(0),
    title_en = character(0),
    title_zh = character(0),
    chart_family = character(0),
    chart_subfamily = character(0),
    aliases_en = character(0),
    aliases_zh = character(0),
    scientific_intents = character(0),
    required_roles = character(0),
    optional_roles = character(0),
    annotations = character(0),
    layouts = character(0),
    required_packages = character(0),
    optional_packages = character(0),
    qa_status = character(0),
    distribution_status = character(0),
    synthetic_test_fixture = logical(0),
    case_path = character(0),
    stringsAsFactors = FALSE
  )
}

build_public_catalog <- function(public_cases_dir) {
  if (!dir.exists(public_cases_dir)) {
    stop("Public cases directory does not exist: ", public_cases_dir)
  }
  case_dirs <- sort(list.dirs(
    public_cases_dir,
    recursive = FALSE,
    full.names = TRUE
  ))
  if (length(case_dirs) == 0L) {
    return(empty_public_catalog())
  }
  rows <- lapply(case_dirs, function(case_dir) {
    metadata <- read_case_metadata(case_dir)
    validation <- validate_case_metadata(metadata)
    if (!isTRUE(validation$ok)) {
      stop(
        "Invalid public case metadata for ",
        metadata$case_id,
        ": ",
        paste(validation$failed_checks, collapse = ", ")
      )
    }
    data.frame(
      schema_version = metadata$schema_version,
      case_id = metadata$case_id,
      title_en = metadata$title_en,
      title_zh = metadata$title_zh,
      chart_family = metadata$chart_family,
      chart_subfamily = metadata$chart_subfamily,
      aliases_en = collapse_metadata_values(metadata$aliases_en),
      aliases_zh = collapse_metadata_values(metadata$aliases_zh),
      scientific_intents = collapse_metadata_values(
        metadata$scientific_intents
      ),
      required_roles = collapse_role_specs(metadata$required_roles),
      optional_roles = collapse_role_specs(metadata$optional_roles),
      annotations = collapse_metadata_values(metadata$annotations),
      layouts = collapse_metadata_values(metadata$layouts),
      required_packages = collapse_metadata_values(
        metadata$required_packages
      ),
      optional_packages = collapse_metadata_values(
        metadata$optional_packages
      ),
      qa_status = metadata$qa_status,
      distribution_status = metadata$distribution_status,
      synthetic_test_fixture = metadata$synthetic_test_fixture,
      case_path = metadata$case_path,
      stringsAsFactors = FALSE
    )
  })
  catalog <- do.call(rbind, rows)
  catalog[order(catalog$case_id), , drop = FALSE]
}
