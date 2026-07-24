detect_planning_source_script <- function(source_assets) {
  grepl(
    "(^|\\|)(source-script\\.R|R\\.R|[^|]+\\.R)($|\\|)",
    source_assets,
    ignore.case = TRUE,
    perl = TRUE
  )
}

detect_planning_source_data <- function(source_assets) {
  grepl(
    "\\.(csv|tsv|txt|xls|xlsx|rds|rdata|tree|treefile|nwk|newick|bed|gff|gff3)(\\||$)",
    source_assets,
    ignore.case = TRUE,
    perl = TRUE
  )
}

planning_reason <- function(
  reproduced,
  source_script,
  source_data,
  runnable,
  missing_dependencies
) {
  reasons <- character(0)
  if (isTRUE(reproduced)) reasons <- c(reasons, "reproduced")
  if (isTRUE(source_script)) reasons <- c(reasons, "source script")
  if (isTRUE(source_data)) reasons <- c(reasons, "source data")
  if (isTRUE(runnable)) reasons <- c(reasons, "runnable")
  if (missing_dependencies > 0L) {
    reasons <- c(
      reasons,
      paste0(missing_dependencies, " missing dependencies")
    )
  }
  if (length(reasons) == 0) "pending without priority evidence" else {
    paste(reasons, collapse = "; ")
  }
}

plan_case_batches <- function(readiness, batch_size = 20L) {
  batch_size <- as.integer(batch_size)
  if (is.na(batch_size) || batch_size < 1L) {
    stop("batch_size must be a positive integer")
  }
  required_columns <- c(
    "case_id",
    "processed",
    "reproduced",
    "runnable",
    "scaffolded",
    "source_assets"
  )
  missing_columns <- setdiff(required_columns, names(readiness))
  if (length(missing_columns) > 0) {
    stop(
      "Readiness table is missing column(s): ",
      paste(missing_columns, collapse = ", ")
    )
  }
  if (!"missing_dependencies" %in% names(readiness)) {
    readiness$missing_dependencies <- 0L
  }

  pending <- readiness[
    readiness$processed %in% FALSE,
    ,
    drop = FALSE
  ]
  pending$priority_score <- numeric(nrow(pending))
  pending$priority_reason <- character(nrow(pending))
  pending$wave <- integer(nrow(pending))
  if (nrow(pending) == 0L) {
    return(pending)
  }

  source_script <- detect_planning_source_script(pending$source_assets)
  source_data <- detect_planning_source_data(pending$source_assets)
  missing_dependencies <- suppressWarnings(
    as.integer(pending$missing_dependencies)
  )
  missing_dependencies[is.na(missing_dependencies)] <- 0L
  pending$priority_score <-
    as.numeric(pending$reproduced) * 100 +
    as.numeric(source_script) * 40 +
    as.numeric(source_data) * 30 +
    as.numeric(pending$runnable) * 20 -
    missing_dependencies * 10
  pending$priority_reason <- vapply(
    seq_len(nrow(pending)),
    function(index) planning_reason(
      pending$reproduced[[index]],
      source_script[[index]],
      source_data[[index]],
      pending$runnable[[index]],
      missing_dependencies[[index]]
    ),
    character(1)
  )
  pending <- pending[
    order(-pending$priority_score, pending$case_id),
    ,
    drop = FALSE
  ]
  pending$wave <- as.integer(ceiling(seq_len(nrow(pending)) / batch_size))
  rownames(pending) <- NULL
  pending
}
