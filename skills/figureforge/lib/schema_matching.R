normalize_search_text <- function(value) {
  value <- tolower(trimws(value))
  value <- gsub("[_-]+", " ", value, perl = TRUE)
  value <- gsub("[[:punct:]]+", " ", value, perl = TRUE)
  gsub("\\s+", " ", trimws(value), perl = TRUE)
}

search_tokens <- function(value) {
  normalized <- normalize_search_text(value)
  if (!nzchar(normalized)) return(character(0))
  unique(strsplit(normalized, "\\s+", perl = TRUE)[[1L]])
}

mapping_data_frame <- function(mapping) {
  if (is.data.frame(mapping)) {
    if (!all(c("role", "input_column") %in% names(mapping))) {
      stop("Mapping requires role and input_column columns")
    }
    return(mapping[, c("role", "input_column"), drop = FALSE])
  }
  if (is.null(names(mapping)) || any(!nzchar(names(mapping)))) {
    stop("Named mapping values are required")
  }
  data.frame(
    role = names(mapping),
    input_column = unname(as.character(mapping)),
    stringsAsFactors = FALSE
  )
}

match_case_schema <- function(metadata, profile, mapping) {
  mapping <- mapping_data_frame(mapping)
  required_specs <- metadata$required_roles
  required_specs$required <- rep(TRUE, nrow(required_specs))
  optional_specs <- metadata$optional_roles
  optional_specs$required <- rep(FALSE, nrow(optional_specs))
  role_specs <- rbind(required_specs, optional_specs)
  missing_required <- setdiff(
    metadata$required_roles$role,
    mapping$role[
      mapping$input_column %in% profile$column &
        nzchar(mapping$input_column)
    ]
  )
  field_rows <- list()
  type_conflicts <- character(0)
  transformations <- character(0)
  assumptions <- character(0)

  for (row_index in seq_len(nrow(mapping))) {
    role <- mapping$role[[row_index]]
    input_column <- mapping$input_column[[row_index]]
    spec_index <- match(role, role_specs$role)
    profile_index <- match(input_column, profile$column)
    if (is.na(spec_index) || is.na(profile_index)) next
    expected_type <- role_specs$type[[spec_index]]
    expected_cardinality <- role_specs$cardinality[[spec_index]]
    inferred_type <- profile$inferred_type[[profile_index]]
    inferred_cardinality <- profile$cardinality[[profile_index]]
    status <- "compatible"
    safe_numeric <- expected_type == "numeric" && inferred_type == "integer"
    if (safe_numeric) {
      status <- "convertible"
      transformations <- c(
        transformations,
        paste0(role, ": integer to numeric")
      )
      assumptions <- c(
        assumptions,
        paste0("Column ", input_column, " is safely widened to numeric.")
      )
    } else if (!identical(expected_type, inferred_type)) {
      status <- "conflict"
      type_conflicts <- c(
        type_conflicts,
        paste0(role, ": expected ", expected_type, ", got ", inferred_type)
      )
    }
    cardinality_ok <- identical(
      expected_cardinality,
      inferred_cardinality
    ) || (
      expected_type == "numeric" &&
        expected_cardinality == "temporal" &&
        inferred_cardinality == "continuous"
    )
    if (!cardinality_ok && status != "conflict") {
      status <- "conflict"
      type_conflicts <- c(
        type_conflicts,
        paste0(
          role,
          ": expected ",
          expected_cardinality,
          ", got ",
          inferred_cardinality
        )
      )
    }
    field_rows[[length(field_rows) + 1L]] <- data.frame(
      role = role,
      input_column = input_column,
      required = role_specs$required[[spec_index]],
      expected_type = expected_type,
      inferred_type = inferred_type,
      expected_cardinality = expected_cardinality,
      inferred_cardinality = inferred_cardinality,
      mapping_status = status,
      stringsAsFactors = FALSE
    )
  }
  fields <- if (length(field_rows) > 0L) {
    do.call(rbind, field_rows)
  } else {
    data.frame(
      role = character(0),
      input_column = character(0),
      required = logical(0),
      expected_type = character(0),
      inferred_type = character(0),
      expected_cardinality = character(0),
      inferred_cardinality = character(0),
      mapping_status = character(0),
      stringsAsFactors = FALSE
    )
  }
  status <- if (length(missing_required) > 0L ||
      length(type_conflicts) > 0L) {
    "incompatible"
  } else if (length(transformations) > 0L) {
    "partially_compatible"
  } else {
    "compatible"
  }
  list(
    status = status,
    field_mappings = fields,
    missing_required_roles = missing_required,
    type_conflicts = unique(type_conflicts),
    allowed_transformations = unique(transformations),
    assumptions = unique(assumptions)
  )
}

profile_data_frame <- function(data) {
  inferred_type <- vapply(data, function(column) {
    if (inherits(column, "Date")) return("date")
    if (inherits(column, "POSIXt")) return("datetime")
    if (is.numeric(column) || is.integer(column)) return("numeric")
    if (is.logical(column)) return("logical")
    "character"
  }, character(1))
  cardinality <- ifelse(
    inferred_type %in% c("numeric", "integer"),
    "continuous",
    ifelse(
      inferred_type %in% c("date", "datetime"),
      "temporal",
      "categorical"
    )
  )
  data.frame(
    column = names(data),
    inferred_type = unname(inferred_type),
    cardinality = unname(cardinality),
    stringsAsFactors = FALSE
  )
}

pipe_values <- function(value) {
  values <- trimws(strsplit(value, "|", fixed = TRUE)[[1L]])
  values[nzchar(values)]
}

token_overlap_count <- function(query_tokens, text) {
  normalized <- normalize_search_text(text)
  sum(vapply(
    query_tokens,
    function(token) nzchar(token) && grepl(token, normalized, fixed = TRUE),
    logical(1)
  ))
}

rank_public_cases <- function(catalog, query, profile = NULL, limit = 10L) {
  query_normalized <- normalize_search_text(query)
  if (!nzchar(query_normalized)) stop("Search query must not be empty")
  candidates <- catalog[
    catalog$distribution_status == "public_ready",
    ,
    drop = FALSE
  ]
  if (nrow(candidates) == 0L) return(candidates)
  taxonomy <- figureforge_public_taxonomy()
  query_tokens <- search_tokens(query)
  score_rows <- lapply(seq_len(nrow(candidates)), function(row_index) {
    row <- candidates[row_index, , drop = FALSE]
    aliases <- c(
      pipe_values(row$aliases_en),
      pipe_values(row$aliases_zh)
    )
    exact_values <- normalize_search_text(c(
      row$title_en,
      row$title_zh,
      aliases
    ))
    taxonomy_index <- which(
      taxonomy$family == row$chart_family &
        taxonomy$subfamily == row$chart_subfamily
    )
    family_text <- paste(
      row$chart_family,
      row$chart_subfamily,
      taxonomy$title_en[taxonomy_index],
      taxonomy$title_zh[taxonomy_index],
      row$aliases_en,
      row$aliases_zh
    )
    score_id <- if (identical(
      query_normalized,
      normalize_search_text(row$case_id)
    )) 100 else 0
    score_alias <- if (query_normalized %in% exact_values) 80 else 0
    score_family <- if (
      token_overlap_count(query_tokens, family_text) > 0L
    ) 40 else 0
    score_schema <- if (is.null(profile)) {
      0
    } else {
      roles <- sub(":.*$", "", pipe_values(row$required_roles))
      sum(roles %in% profile$column) * 8
    }
    score_intent <- token_overlap_count(
      query_tokens,
      row$scientific_intents
    ) * 6
    score_layout <- token_overlap_count(
      query_tokens,
      paste(row$annotations, row$layouts)
    ) * 4
    score_readiness <- if (
      row$qa_status == "review_required" &&
        row$distribution_status == "public_ready"
    ) 2 else 0
    data.frame(
      score_id = score_id,
      score_alias = score_alias,
      score_family = score_family,
      score_schema = score_schema,
      score_intent = score_intent,
      score_layout = score_layout,
      score_readiness = score_readiness,
      stringsAsFactors = FALSE
    )
  })
  scores <- do.call(rbind, score_rows)
  scores$score_total <- rowSums(scores)
  candidates <- cbind(candidates, scores)
  candidates <- candidates[
    order(-candidates$score_total, candidates$case_id),
    ,
    drop = FALSE
  ]
  head(candidates, as.integer(limit))
}
