catalog_section_text <- function(lines, heading) {
  paste(
    trimws(extract_markdown_section(lines, heading)),
    collapse = " "
  )
}

catalog_title <- function(lines, fallback) {
  title_line <- lines[grepl("^#\\s+\\S", lines, perl = TRUE)]
  if (length(title_line) == 0) {
    return(fallback)
  }
  trimws(sub("^#\\s+", "", title_line[[1]], perl = TRUE))
}

catalog_schema_roles <- function(lines) {
  section <- trimws(extract_markdown_section(lines, "## Data Schema"))
  bullets <- section[grepl("^[-*]\\s+\\S+", section, perl = TRUE)]
  if (length(bullets) == 0) {
    return(character(0))
  }
  roles <- sub("^[-*]\\s+", "", bullets, perl = TRUE)
  roles <- sub("\\s*:.*$", "", roles, perl = TRUE)
  roles <- gsub("`", "", trimws(roles), fixed = TRUE)
  unique(roles[nzchar(roles)])
}

case_completion_label <- function(case_dir) {
  if (detect_scaffold(case_dir)) {
    return("scaffolded")
  }
  completion <- validate_case_completion(case_dir)
  if (isTRUE(completion$ok)) {
    return("qa_verified")
  }
  structure <- validate_case_structure(case_dir)
  if (isTRUE(structure$ok)) {
    return("structured")
  }
  "raw"
}

case_distribution_label <- function(case_dir) {
  distribution <- detect_distribution(case_dir)
  if (isTRUE(distribution$public_ready)) "public_ready" else "private_only"
}

build_case_catalog <- function(cases_dir) {
  cases_dir <- normalizePath(cases_dir, mustWork = TRUE)
  case_dirs <- list.dirs(cases_dir, recursive = FALSE, full.names = TRUE)
  case_dirs <- case_dirs[basename(case_dirs) != "_template"]
  case_dirs <- sort(case_dirs)

  rows <- lapply(case_dirs, function(case_dir) {
    case_path <- file.path(case_dir, "case.md")
    lines <- read_text_safely(case_path)
    if (length(lines) == 0) {
      lines <- character(0)
    }
    packages <- declared_r_packages(lines)
    roles <- catalog_schema_roles(lines)
    row <- data.frame(
      case_id = basename(case_dir),
      title = catalog_title(lines, basename(case_dir)),
      chart_type = catalog_section_text(lines, "## Chart Type"),
      chart_type_zh = catalog_section_text(
        lines,
        "## Chart Type Chinese"
      ),
      aliases = catalog_section_text(lines, "## Aliases"),
      best_for = catalog_section_text(lines, "## Best For"),
      best_for_zh = catalog_section_text(
        lines,
        "## Best For Chinese"
      ),
      required_columns = paste(roles, collapse = ", "),
      required_r_packages = paste(packages, collapse = ", "),
      completion_status = case_completion_label(case_dir),
      distribution_status = case_distribution_label(case_dir),
      case_path = normalizePath(case_dir, mustWork = TRUE),
      stringsAsFactors = FALSE
    )
    row$search_text <- tolower(paste(
      row$case_id,
      row$title,
      row$chart_type,
      row$chart_type_zh,
      row$aliases,
      row$best_for,
      row$best_for_zh,
      row$required_columns,
      row$required_r_packages
    ))
    row
  })

  if (length(rows) == 0) {
    return(data.frame(
      case_id = character(0),
      title = character(0),
      chart_type = character(0),
      chart_type_zh = character(0),
      aliases = character(0),
      best_for = character(0),
      best_for_zh = character(0),
      required_columns = character(0),
      required_r_packages = character(0),
      completion_status = character(0),
      distribution_status = character(0),
      case_path = character(0),
      search_text = character(0),
      stringsAsFactors = FALSE
    ))
  }
  catalog <- do.call(rbind, rows)
  catalog[order(catalog$case_id), , drop = FALSE]
}

search_case_catalog <- function(
  catalog,
  query,
  limit = 10L,
  completed_only = FALSE
) {
  if (nrow(catalog) == 0) {
    return(catalog)
  }
  query <- trimws(tolower(query))
  if (!nzchar(query)) {
    stop("Search query must not be empty")
  }
  candidates <- catalog
  if (isTRUE(completed_only)) {
    candidates <- candidates[
      candidates$completion_status == "qa_verified",
      ,
      drop = FALSE
    ]
  }
  if (nrow(candidates) == 0) {
    return(candidates)
  }

  tokens <- unique(strsplit(query, "\\s+", perl = TRUE)[[1]])
  phrase_match <- grepl(
    query,
    candidates$search_text,
    fixed = TRUE
  )
  token_score <- vapply(
    candidates$search_text,
    function(text) sum(vapply(
      tokens,
      function(token) grepl(token, text, fixed = TRUE),
      logical(1)
    )),
    numeric(1)
  )
  status_bonus <- ifelse(
    candidates$completion_status == "qa_verified",
    2,
    0
  )
  candidates$score <- as.numeric(phrase_match) * 5 +
    token_score +
    status_bonus
  candidates <- candidates[candidates$score > status_bonus, , drop = FALSE]
  if (nrow(candidates) == 0) {
    return(candidates)
  }
  candidates <- candidates[
    order(-candidates$score, candidates$case_id),
    ,
    drop = FALSE
  ]
  head(candidates, as.integer(limit))
}

check_r_packages <- function(packages) {
  packages <- unique(trimws(packages))
  packages <- packages[nzchar(packages)]
  data.frame(
    package = packages,
    installed = vapply(
      packages,
      requireNamespace,
      logical(1),
      quietly = TRUE
    ),
    stringsAsFactors = FALSE
  )
}

check_case_dependencies <- function(case_dir) {
  case_path <- file.path(case_dir, "case.md")
  if (!file.exists(case_path)) {
    stop("Missing case metadata: ", case_path)
  }
  packages <- declared_r_packages(read_text_safely(case_path))
  if (length(packages) == 0) {
    stop("No packages declared under ## Required R Packages")
  }
  check_r_packages(packages)
}
