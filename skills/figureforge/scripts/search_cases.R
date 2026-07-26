#!/usr/bin/env Rscript

command_args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", command_args, value = TRUE)
script_path <- if (length(file_arg) > 0) {
  normalizePath(sub("^--file=", "", file_arg[[1]]), mustWork = TRUE)
} else {
  normalizePath(
    "skills/figureforge/scripts/search_cases.R",
    mustWork = TRUE
  )
}
repo_root <- normalizePath(
  file.path(dirname(script_path), "..", "..", ".."),
  mustWork = TRUE
)
source(file.path(repo_root, "skills", "figureforge", "lib", "case_audit.R"))
source(file.path(repo_root, "skills", "figureforge", "lib", "checksums.R"))
source(file.path(
  repo_root,
  "skills",
  "figureforge",
  "lib",
  "case_validation.R"
))
source(file.path(
  repo_root,
  "skills",
  "figureforge",
  "lib",
  "case_catalog.R"
))
source(file.path(repo_root, "skills", "figureforge", "lib", "distribution_validation.R"))
source(file.path(repo_root, "skills", "figureforge", "lib", "metadata.R"))
source(file.path(repo_root, "skills", "figureforge", "lib", "schema_matching.R"))

usage <- function() {
  paste(
    "Usage: search_cases.R --query TEXT",
    "[--cases-dir PATH]",
    "[--limit N]",
    "[--completed-only]",
    "[--public]",
    "[--schema INPUT.csv]",
    "[--search-intent INTENT]",
    "[--explain-scores]",
    "[--output PATH]"
  )
}

supported_search_intents <- function() {
  c(
    "relationship",
    "comparison",
    "distribution",
    "composition",
    "trend",
    "ordination",
    "network",
    "spatial",
    "uncertainty",
    "other"
  )
}

parse_cli <- function(args) {
  result <- list(
    query = NULL,
    cases_dir = file.path(repo_root, "skills", "figureforge", "cases"),
    limit = 10L,
    completed_only = FALSE,
    public = FALSE,
    schema = NULL,
    search_intent = NULL,
    explain_scores = FALSE,
    output = NULL
  )
  index <- 1L
  while (index <= length(args)) {
    argument <- args[[index]]
    if (argument == "--completed-only") {
      result$completed_only <- TRUE
      index <- index + 1L
      next
    }
    if (argument == "--public") {
      result$public <- TRUE
      index <- index + 1L
      next
    }
    if (argument == "--explain-scores") {
      result$explain_scores <- TRUE
      index <- index + 1L
      next
    }
    if (argument %in% c(
      "--query",
      "--cases-dir",
      "--limit",
      "--schema",
      "--search-intent",
      "--output"
    )) {
      if (index == length(args)) {
        stop("Missing value for ", argument, "\n", usage())
      }
      value <- args[[index + 1L]]
      if (argument == "--query") result$query <- value
      if (argument == "--cases-dir") result$cases_dir <- value
      if (argument == "--limit") result$limit <- as.integer(value)
      if (argument == "--schema") result$schema <- value
      if (argument == "--search-intent") result$search_intent <- value
      if (argument == "--output") result$output <- value
      index <- index + 2L
      next
    }
    stop("Unknown argument: ", argument, "\n", usage())
  }
  if (is.null(result$query) || !nzchar(trimws(result$query))) {
    stop("--query is required\n", usage())
  }
  if (is.na(result$limit) || result$limit < 1L) {
    stop("--limit must be a positive integer")
  }
  if (
    !is.null(result$search_intent) &&
      !result$search_intent %in% supported_search_intents()
  ) {
    stop(
      "--search-intent must be one of: ",
      paste(supported_search_intents(), collapse = ", ")
    )
  }
  if (!is.null(result$output) && is.null(result$search_intent)) {
    stop("--search-intent is required with --output")
  }
  result
}

resolved_path_identity <- function(path, must_work = FALSE) {
  link_target <- Sys.readlink(path)
  if (
    file.exists(path) ||
      (!is.na(link_target) && nzchar(link_target))
  ) {
    return(normalizePath(path, mustWork = must_work))
  }
  parent <- normalizePath(dirname(path), mustWork = must_work)
  file.path(parent, basename(path))
}

path_is_within <- function(path, directory) {
  path <- resolved_path_identity(path, must_work = FALSE)
  directory <- normalizePath(directory, mustWork = TRUE)
  identical(path, directory) ||
    startsWith(path, paste0(directory, .Platform$file.sep))
}

validate_receipt_destination <- function(
  output,
  schema,
  cases_dir,
  case_dirs = character(0)
) {
  link_target <- Sys.readlink(output)
  if (!is.na(link_target) && nzchar(link_target)) {
    stop("--output must not be an existing symbolic link")
  }
  if (dir.exists(output)) {
    stop("--output must not be a directory")
  }
  output_parent <- dirname(output)
  dir.create(output_parent, recursive = TRUE, showWarnings = FALSE)
  if (!dir.exists(output_parent)) {
    stop("Unable to create --output directory")
  }
  output_identity <- resolved_path_identity(output, must_work = FALSE)
  if (
    !is.null(schema) &&
      identical(
        output_identity,
        resolved_path_identity(schema, must_work = TRUE)
      )
  ) {
    stop("--output must not overwrite --schema")
  }
  if (dir.exists(cases_dir) && path_is_within(output, cases_dir)) {
    stop("--output must not overwrite or enter the case evidence directory")
  }
  protected_case_dirs <- unique(as.character(case_dirs))
  protected_case_dirs <- protected_case_dirs[dir.exists(protected_case_dirs)]
  if (
    length(protected_case_dirs) > 0L &&
      any(vapply(
        protected_case_dirs,
        function(case_dir) path_is_within(output, case_dir),
        logical(1L)
      ))
  ) {
    stop("--output must not overwrite resolved case evidence")
  }
  invisible(output_identity)
}

write_receipt_atomic <- function(receipt, output) {
  output_parent <- normalizePath(dirname(output), mustWork = TRUE)
  temporary <- tempfile(
    ".figureforge-search-receipt-",
    tmpdir = output_parent,
    fileext = ".csv"
  )
  on.exit(unlink(temporary, force = TRUE), add = TRUE)
  write.csv(
    receipt,
    temporary,
    row.names = FALSE,
    fileEncoding = "UTF-8",
    na = ""
  )
  temporary_info <- file.info(temporary)
  if (
    !isTRUE(file_test("-f", temporary)) ||
      is.na(temporary_info$size[[1L]]) ||
      temporary_info$size[[1L]] < 1
  ) {
    stop("Unable to create a non-empty search receipt")
  }
  link_target <- Sys.readlink(output)
  if (!is.na(link_target) && nzchar(link_target)) {
    stop("--output became a symbolic link before publication")
  }
  if (!file.rename(temporary, output)) {
    stop("Unable to publish search receipt atomically")
  }
  invisible(output)
}

tryCatch(
  {
    options <- parse_cli(commandArgs(trailingOnly = TRUE))
    effective_cases_dir <- options$cases_dir
    if (options$public) {
      default_private <- file.path(
        repo_root,
        "skills",
        "figureforge",
        "cases"
      )
      public_cases <- if (identical(options$cases_dir, default_private)) {
        file.path(repo_root, "skills", "figureforge", "public-cases")
      } else {
        options$cases_dir
      }
      effective_cases_dir <- public_cases
      catalog <- build_public_catalog(public_cases)
      if (!is.null(options$output)) {
        validate_receipt_destination(
          options$output,
          options$schema,
          effective_cases_dir,
          catalog$case_path
        )
      }
      profile <- if (is.null(options$schema)) {
        NULL
      } else {
        profile_data_frame(read.csv(
          options$schema,
          stringsAsFactors = FALSE,
          check.names = FALSE
        ))
      }
      results <- rank_public_cases(
        catalog,
        options$query,
        profile = profile,
        limit = options$limit
      )
      score_columns <- c(
        "score_id",
        "score_alias",
        "score_family",
        "score_schema",
        "score_intent",
        "score_layout",
        "score_readiness",
        "score_total"
      )
      display_columns <- c(
        "case_id",
        "title_en",
        "title_zh",
        "chart_family",
        "chart_subfamily",
        "required_roles",
        "qa_status",
        "distribution_status",
        "case_path",
        if (options$explain_scores) score_columns else "score_total"
      )
    } else {
      catalog <- build_case_catalog(options$cases_dir)
      if (!is.null(options$output)) {
        validate_receipt_destination(
          options$output,
          options$schema,
          effective_cases_dir,
          catalog$case_path
        )
      }
      results <- search_case_catalog(
        catalog,
        options$query,
        limit = options$limit,
        completed_only = options$completed_only
      )
      display_columns <- c(
        "score",
        "case_id",
        "title",
        "chart_type",
        "chart_type_zh",
        "required_columns",
        "completion_status",
        "distribution_status",
        "case_path"
      )
    }
    display <- results[
      ,
      intersect(display_columns, names(results)),
      drop = FALSE
    ]
    if (!is.null(options$output)) {
      result_count <- max(1L, nrow(results))
      result_case_ids <- if (nrow(results) > 0L) {
        as.character(results$case_id)
      } else {
        character(0)
      }
      result_scores <- if (nrow(results) > 0L) {
        score_column <- if (options$public) "score_total" else "score"
        as.numeric(results[[score_column]])
      } else {
        numeric(0)
      }
      receipt <- data.frame(
        receipt_schema_version = rep("2", result_count),
        receipt_generator = rep(
          "figureforge-search_cases",
          result_count
        ),
        search_query_sha256 = rep(
          figureforge_sha256_text(options$query),
          result_count
        ),
        search_intent = rep(options$search_intent, result_count),
        search_scope = rep(
          if (options$public) "public" else "private",
          result_count
        ),
        schema_sha256 = rep(
          if (is.null(options$schema)) {
            "none"
          } else {
            figureforge_sha256(options$schema)
          },
          result_count
        ),
        search_limit = rep(options$limit, result_count),
        completed_only = rep(options$completed_only, result_count),
        explain_scores = rep(options$explain_scores, result_count),
        result_rank = if (nrow(results) > 0L) {
          seq_len(nrow(results))
        } else {
          NA_integer_
        },
        case_id_sha256 = if (nrow(results) > 0L) {
          vapply(
            result_case_ids,
            figureforge_sha256_text,
            character(1L)
          )
        } else {
          ""
        },
        score = if (nrow(results) > 0L) {
          result_scores
        } else {
          NA_real_
        },
        stringsAsFactors = FALSE
      )
      write_receipt_atomic(receipt, options$output)
      message("Wrote search receipt: ", options$output)
    }
    if (nrow(display) == 0) {
      message("No matching cases.")
    } else {
      write.table(
        display,
        row.names = FALSE,
        sep = "\t",
        quote = FALSE,
        file = stdout()
      )
    }
  },
  error = function(error) {
    message(conditionMessage(error))
    quit(status = 1L)
  }
)
