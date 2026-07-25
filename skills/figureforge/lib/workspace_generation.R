canonical_candidate_path <- function(path) {
  expanded <- path.expand(path)
  if (!grepl("^/", expanded)) {
    expanded <- file.path(getwd(), expanded)
  }
  candidate <- expanded
  suffix <- character(0)
  while (!file.exists(candidate) && !dir.exists(candidate)) {
    parent <- dirname(candidate)
    if (identical(parent, candidate)) break
    suffix <- c(basename(candidate), suffix)
    candidate <- parent
  }
  resolved <- normalizePath(candidate, mustWork = TRUE)
  if (length(suffix) > 0L) {
    resolved <- do.call(file.path, as.list(c(resolved, suffix)))
  }
  resolved
}

path_is_same_or_within <- function(path, root) {
  identical(path, root) ||
    startsWith(path, paste0(root, .Platform$file.sep))
}

validate_workspace_target <- function(
  workspace,
  case_dir,
  protected_roots,
  force_empty = FALSE
) {
  workspace_path <- canonical_candidate_path(workspace)
  case_path <- normalizePath(case_dir, mustWork = TRUE)
  roots <- unique(c(case_path, protected_roots))
  roots <- roots[dir.exists(roots)]
  roots <- unique(vapply(
    roots,
    normalizePath,
    character(1),
    mustWork = TRUE
  ))
  overlaps <- vapply(
    roots,
    function(root) {
      path_is_same_or_within(workspace_path, root) ||
        path_is_same_or_within(root, workspace_path)
    },
    logical(1)
  )
  if (any(overlaps)) {
    stop(
      "Workspace overlaps a protected source root: ",
      roots[which(overlaps)[[1L]]]
    )
  }
  if (file.exists(workspace_path) && !dir.exists(workspace_path)) {
    stop("Workspace target is an existing file: ", workspace_path)
  }
  if (dir.exists(workspace_path)) {
    entries <- list.files(
      workspace_path,
      all.files = TRUE,
      no.. = TRUE
    )
    if (length(entries) > 0L) {
      stop("Workspace target must be empty: ", workspace_path)
    }
    if (!isTRUE(force_empty)) {
      stop("Existing empty workspace requires --force-empty")
    }
  }
  list(path = workspace_path, exists = dir.exists(workspace_path))
}

workspace_sha256 <- function(path) {
  output <- system2(
    "shasum",
    c("-a", "256", shQuote(path)),
    stdout = TRUE,
    stderr = TRUE
  )
  status <- attr(output, "status")
  if (!is.null(status) && status != 0L) {
    stop("Unable to calculate SHA-256 for: ", path)
  }
  hash <- strsplit(output[[1L]], "\\s+", perl = TRUE)[[1L]][[1L]]
  if (!grepl("^[0-9a-f]{64}$", hash, perl = TRUE)) {
    stop("Invalid SHA-256 output for: ", path)
  }
  hash
}

workspace_version <- function(case_dir) {
  version_path <- file.path(dirname(dirname(case_dir)), "VERSION")
  if (!file.exists(version_path)) return("0.0.0-dev")
  version <- trimws(readLines(version_path, warn = FALSE)[[1L]])
  if (!nzchar(version)) "0.0.0-dev" else version
}

write_mapping_draft <- function(metadata, path, mapping_path = NULL) {
  if (!is.null(mapping_path)) {
    mapping <- read.csv(
      mapping_path,
      stringsAsFactors = FALSE,
      check.names = FALSE
    )
    required_columns <- c("role", "input_column")
    missing <- setdiff(required_columns, names(mapping))
    if (length(missing) > 0L) {
      stop(
        "Mapping file is missing columns: ",
        paste(missing, collapse = ", ")
      )
    }
  } else {
    mapping <- rbind(
      transform(
        metadata$required_roles,
        input_column = "",
        required = TRUE
      ),
      transform(
        metadata$optional_roles,
        input_column = "",
        required = FALSE
      )
    )
  }
  if (!"required" %in% names(mapping)) {
    mapping$required <- mapping$role %in% metadata$required_roles$role
  }
  package_lines <- paste0("- ", metadata$required_packages)
  if (length(package_lines) == 0L) package_lines <- "- base"
  lines <- c(
    "# Adaptation Mapping",
    "",
    "## Selected Case",
    "",
    paste0("- Case ID: `", metadata$case_id, "`"),
    paste0("- Title: ", metadata$title_en, " / ", metadata$title_zh),
    "",
    "## Field Mapping",
    "",
    "Complete and review this mapping before rendering.",
    "",
    "| Case role | Input column | Required | Type | Cardinality |",
    "| --- | --- | --- | --- | --- |"
  )
  for (row_index in seq_len(nrow(mapping))) {
    role <- mapping$role[[row_index]]
    role_specs <- rbind(metadata$required_roles, metadata$optional_roles)
    spec_index <- match(role, role_specs$role)
    role_type <- if (is.na(spec_index)) "" else role_specs$type[[spec_index]]
    cardinality <- if (is.na(spec_index)) {
      ""
    } else {
      role_specs$cardinality[[spec_index]]
    }
    lines <- c(
      lines,
      paste0(
        "| `", role, "` | `", mapping$input_column[[row_index]],
        "` | ", tolower(as.character(mapping$required[[row_index]])),
        " | ", role_type, " | ", cardinality, " |"
      )
    )
  }
  lines <- c(
    lines,
    "",
    "## Transformations",
    "",
    "Record executable renames, derived fields, units, and factor ordering.",
    "",
    "## Required R Packages",
    "",
    package_lines,
    "",
    "## Run Command",
    "",
    "```bash",
    "/usr/local/bin/Rscript plot.R input.csv output.pdf",
    "```"
  )
  writeLines(lines, path, useBytes = TRUE)
}

write_adaptation_qa <- function(path) {
  writeLines(
    c(
      "# Adaptation QA",
      "",
      "Status: review_required",
      "",
      "## Data",
      "",
      "Review field mapping, units, missingness, and derived values.",
      "",
      "## Visual Fidelity",
      "",
      "Review encodings, labels, overlaps, scales, and annotations.",
      "",
      "## Reproducibility",
      "",
      "Run an independent render after completing the mapping.",
      "",
      "## Export",
      "",
      "Review format, dimensions, resolution, and clipping.",
      "",
      "## Limits",
      "",
      "Automated tools cannot grant verified status."
    ),
    path,
    useBytes = TRUE
  )
}

create_adaptation_workspace <- function(
  case_dir,
  input_path,
  workspace,
  mapping_path = NULL,
  force_empty = FALSE,
  protected_roots = character()
) {
  if (!dir.exists(case_dir)) stop("Case directory does not exist: ", case_dir)
  if (!file.exists(input_path)) stop("Input file does not exist: ", input_path)
  if (!is.null(mapping_path) && !file.exists(mapping_path)) {
    stop("Mapping file does not exist: ", mapping_path)
  }
  case_dir <- normalizePath(case_dir, mustWork = TRUE)
  input_path <- normalizePath(input_path, mustWork = TRUE)
  target <- validate_workspace_target(
    workspace,
    case_dir,
    protected_roots,
    force_empty = force_empty
  )
  metadata <- read_case_metadata(case_dir)
  plot_path <- file.path(case_dir, "plot.R")
  if (!file.exists(plot_path)) stop("Case plot script is missing: ", plot_path)

  parent <- dirname(target$path)
  dir.create(parent, recursive = TRUE, showWarnings = FALSE)
  temporary <- tempfile(
    paste0(".", basename(target$path), "-"),
    tmpdir = parent
  )
  dir.create(temporary, recursive = FALSE)
  committed <- FALSE
  on.exit({
    if (!committed && dir.exists(temporary)) {
      unlink(temporary, recursive = TRUE, force = TRUE)
    }
  }, add = TRUE)

  if (!file.copy(plot_path, file.path(temporary, "plot.R"))) {
    stop("Failed to copy the public plot script")
  }
  if (!file.copy(input_path, file.path(temporary, "input.csv"))) {
    stop("Failed to copy user input")
  }
  write_mapping_draft(
    metadata,
    file.path(temporary, "mapping.md"),
    mapping_path = mapping_path
  )
  write_adaptation_qa(file.path(temporary, "qa.md"))
  writeLines(
    c(
      "schema_version: 1",
      paste0("source_case_id: ", metadata$case_id),
      paste0("source_script_sha256: ", workspace_sha256(plot_path)),
      paste0("figureforge_version: ", workspace_version(case_dir)),
      "qa_status: review_required",
      "input_origin: user-supplied-copy",
      paste0(
        "created_at_utc: ",
        format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
      )
    ),
    file.path(temporary, "adaptation.yml"),
    useBytes = TRUE
  )

  if (target$exists) {
    unlink(target$path, recursive = TRUE, force = TRUE)
  }
  if (!file.rename(temporary, target$path)) {
    stop("Failed to atomically create workspace: ", target$path)
  }
  committed <- TRUE
  list(
    ok = TRUE,
    workspace = target$path,
    source_case_id = metadata$case_id
  )
}
