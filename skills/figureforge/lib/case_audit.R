is_nonempty_file <- function(path) {
  file.exists(path) && !dir.exists(path) && isTRUE(file.info(path)$size > 0)
}

read_text_safely <- function(path) {
  if (!file.exists(path) || dir.exists(path)) {
    return(character(0))
  }
  tryCatch(
    readLines(path, warn = FALSE, encoding = "UTF-8"),
    error = function(error) character(0)
  )
}

detect_scaffold <- function(case_dir) {
  candidate_files <- file.path(
    case_dir,
    c("case.md", "plot.R", "source-script.R")
  )
  text <- paste(unlist(lapply(candidate_files, read_text_safely)), collapse = "\n")
  markers <- c(
    "compact reproducible data scaffold",
    "Replace `data.csv` with real analysis output",
    "Generated compact reproducible scaffold"
  )
  any(vapply(markers, grepl, logical(1), x = text, fixed = TRUE))
}

detect_source_assets <- function(case_dir) {
  entries <- list.files(
    case_dir,
    all.files = TRUE,
    no.. = TRUE,
    full.names = FALSE,
    recursive = FALSE
  )
  canonical <- c(
    "case.md",
    "data.csv",
    "plot.R",
    "qa.md",
    "blocker.md",
    "distribution.yml",
    "reproduction.png",
    "reproduction.pdf",
    "reproduction.svg",
    "output.png",
    "output.pdf",
    "output.svg"
  )
  source_assets <- entries[!entries %in% canonical]
  source_assets <- source_assets[
    !startsWith(source_assets, ".") &
      file.exists(file.path(case_dir, source_assets))
  ]
  sort(source_assets)
}

detect_reproduction <- function(case_dir) {
  paths <- file.path(
    case_dir,
    c("reproduction.png", "reproduction.pdf", "reproduction.svg")
  )
  any(vapply(paths, is_nonempty_file, logical(1)))
}

detect_qa_verified <- function(case_dir) {
  lines <- trimws(read_text_safely(file.path(case_dir, "qa.md")))
  required_sections <- c(
    "## Data",
    "## Visual Fidelity",
    "## Reproducibility",
    "## Export",
    "## Limits"
  )
  has_status <- any(tolower(lines) == "status: verified")
  has_sections <- all(required_sections %in% lines)
  has_status && has_sections
}

detect_distribution <- function(case_dir) {
  lines <- trimws(
    read_text_safely(file.path(case_dir, "distribution.yml"))
  )
  allowed <- any(
    grepl(
      "^redistribution\\s*:\\s*allowed\\s*$",
      lines,
      ignore.case = TRUE,
      perl = TRUE
    )
  )
  reviewed_assets <- sub(
    "^\\s*-\\s*",
    "",
    lines[grepl("^\\s*-\\s*\\S+", lines, perl = TRUE)]
  )
  list(
    public_ready = allowed && length(reviewed_assets) > 0,
    reviewed_assets = reviewed_assets
  )
}

render_case_for_audit <- function(
  case_dir,
  output_path,
  rscript = "/usr/local/bin/Rscript",
  input_path = NULL
) {
  plot_script <- file.path(case_dir, "plot.R")
  if (is.null(input_path)) {
    input_path <- file.path(case_dir, "data.csv")
  }

  if (!is_nonempty_file(plot_script) || !is_nonempty_file(input_path)) {
    return(list(
      ok = FALSE,
      status = NA_integer_,
      log = "Missing non-empty plot.R or data.csv"
    ))
  }
  if (!is_nonempty_file(rscript)) {
    return(list(
      ok = FALSE,
      status = NA_integer_,
      log = paste("Rscript runtime not found:", rscript)
    ))
  }

  dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
  if (file.exists(output_path)) {
    unlink(output_path)
  }
  log_path <- tempfile("figureforge-render-", fileext = ".log")
  on.exit(unlink(log_path), add = TRUE)

  status <- tryCatch(
    system2(
      rscript,
      args = shQuote(c(plot_script, input_path, output_path)),
      stdout = log_path,
      stderr = log_path
    ),
    error = function(error) {
      attr(1L, "audit_error") <- conditionMessage(error)
      1L
    }
  )
  log_lines <- read_text_safely(log_path)
  error_detail <- attr(status, "audit_error")
  if (!is.null(error_detail)) {
    log_lines <- c(log_lines, error_detail)
  }

  list(
    ok = identical(as.integer(status), 0L) && is_nonempty_file(output_path),
    status = as.integer(status),
    log = paste(log_lines, collapse = "\n")
  )
}

audit_case <- function(
  case_dir,
  render_dir = NULL,
  rscript = "/usr/local/bin/Rscript"
) {
  case_id <- basename(case_dir)
  source_assets <- detect_source_assets(case_dir)
  distribution <- detect_distribution(case_dir)
  blocker <- validate_blocker_record(case_dir)
  render <- list(ok = FALSE, status = NA_integer_, log = "Render not attempted")

  if (!is.null(render_dir)) {
    output_path <- file.path(render_dir, paste0(case_id, ".pdf"))
    render <- render_case_for_audit(
      case_dir,
      output_path,
      rscript = rscript
    )
  }

  scaffolded <- detect_scaffold(case_dir)
  reproduced <- detect_reproduction(case_dir)
  qa_verified <- detect_qa_verified(case_dir)
  runnable <- isTRUE(render$ok)
  completed <- runnable && reproduced && qa_verified && !scaffolded
  blocked <- isTRUE(blocker$ok)
  processed <- completed || blocked
  terminal_outcome <- if (completed) {
    "completed"
  } else if (blocked) {
    "blocked"
  } else {
    "pending"
  }

  data.frame(
    case_id = case_id,
    raw = length(source_assets) > 0,
    scaffolded = scaffolded,
    runnable = runnable,
    reproduced = reproduced,
    qa_verified = qa_verified,
    public_ready = isTRUE(distribution$public_ready),
    private_only = !isTRUE(distribution$public_ready),
    blocked = blocked,
    blocked_status = if (blocked) blocker$status else "",
    blocked_summary = if (blocked) blocker$summary else "",
    processed = processed,
    terminal_outcome = terminal_outcome,
    has_case_md = is_nonempty_file(file.path(case_dir, "case.md")),
    has_data_csv = is_nonempty_file(file.path(case_dir, "data.csv")),
    has_plot_r = is_nonempty_file(file.path(case_dir, "plot.R")),
    source_assets = paste(source_assets, collapse = "|"),
    render_status = if (is.na(render$status)) "" else as.character(render$status),
    render_log = render$log,
    stringsAsFactors = FALSE
  )
}

audit_cases <- function(
  cases_dir,
  render_dir = NULL,
  rscript = "/usr/local/bin/Rscript"
) {
  if (!dir.exists(cases_dir)) {
    stop("Cases directory not found: ", cases_dir)
  }

  case_dirs <- sort(list.dirs(
    cases_dir,
    full.names = TRUE,
    recursive = FALSE
  ))
  case_dirs <- case_dirs[basename(case_dirs) != "_template"]

  if (length(case_dirs) == 0) {
    return(data.frame(
      case_id = character(0),
      raw = logical(0),
      scaffolded = logical(0),
      runnable = logical(0),
      reproduced = logical(0),
      qa_verified = logical(0),
      public_ready = logical(0),
      private_only = logical(0),
      blocked = logical(0),
      blocked_status = character(0),
      blocked_summary = character(0),
      processed = logical(0),
      terminal_outcome = character(0),
      has_case_md = logical(0),
      has_data_csv = logical(0),
      has_plot_r = logical(0),
      source_assets = character(0),
      render_status = character(0),
      render_log = character(0),
      stringsAsFactors = FALSE
    ))
  }

  rows <- lapply(case_dirs, function(case_dir) {
    tryCatch(
      audit_case(
        case_dir,
        render_dir = render_dir,
        rscript = rscript
      ),
      error = function(error) {
        data.frame(
          case_id = basename(case_dir),
          raw = FALSE,
          scaffolded = FALSE,
          runnable = FALSE,
          reproduced = FALSE,
          qa_verified = FALSE,
          public_ready = FALSE,
          private_only = TRUE,
          blocked = FALSE,
          blocked_status = "",
          blocked_summary = "",
          processed = FALSE,
          terminal_outcome = "pending",
          has_case_md = FALSE,
          has_data_csv = FALSE,
          has_plot_r = FALSE,
          source_assets = "",
          render_status = "",
          render_log = conditionMessage(error),
          stringsAsFactors = FALSE
        )
      }
    )
  })
  results <- do.call(rbind, rows)
  rownames(results) <- NULL
  results
}

count_true <- function(values) {
  sum(values %in% TRUE, na.rm = TRUE)
}

summarize_audit <- function(results) {
  c(
    "# FigureForge Case Audit Summary",
    "",
    paste0("- Cases audited: ", nrow(results)),
    paste0("- Raw source assets present: ", count_true(results$raw)),
    paste0("- Scaffolded: ", count_true(results$scaffolded)),
    paste0("- Runnable: ", count_true(results$runnable)),
    paste0("- Reproduced: ", count_true(results$reproduced)),
    paste0("- QA-verified: ", count_true(results$qa_verified)),
    paste0("- Public-ready: ", count_true(results$public_ready)),
    paste0("- Private-only: ", count_true(results$private_only)),
    paste0(
      "- Completed: ",
      sum(results$terminal_outcome == "completed", na.rm = TRUE)
    ),
    paste0(
      "- Blocked: ",
      sum(results$terminal_outcome == "blocked", na.rm = TRUE)
    ),
    paste0(
      "- Pending: ",
      sum(results$terminal_outcome == "pending", na.rm = TRUE)
    ),
    paste0("- Processed: ", count_true(results$processed)),
    "",
    "## Evidence Boundaries",
    "",
    paste(
      "Scaffolded means generated inventory files were detected;",
      "it does not mean the authentic case was developed."
    ),
    paste(
      "Runnable means a fresh isolated render exited successfully and created",
      "a non-empty output; it does not prove visual fidelity."
    ),
    paste(
      "Reproduced means that a non-empty reproduction artifact exists;",
      "it does not prove that a visual comparison was completed."
    ),
    paste(
      "QA-verified requires an explicit qa.md record with all required",
      "sections."
    ),
    "Missing distribution review defaults to private-only.",
    "",
    "## Recommended Next Actions",
    "",
    paste0(
      "1. Treat only the ",
      count_true(
        results$runnable &
          results$reproduced &
          results$qa_verified
      ),
      " runnable + reproduced + QA-verified case(s) as completed."
    ),
    "2. Continue authentic source review for scaffolded or unverified cases.",
    "3. Review distribution independently before publishing any case assets.",
    "4. Keep private corpus paths and generated reports out of Git."
  )
}

write_audit_reports <- function(results, output_dir) {
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  log_dir <- file.path(output_dir, "render-logs")
  dir.create(log_dir, recursive = TRUE, showWarnings = FALSE)

  ordered <- results[order(results$case_id), , drop = FALSE]
  for (index in seq_len(nrow(ordered))) {
    log_path <- file.path(
      log_dir,
      paste0(ordered$case_id[[index]], ".log")
    )
    writeLines(ordered$render_log[[index]], log_path, useBytes = TRUE)
  }

  csv_results <- ordered
  csv_results$render_log <- NULL
  write.csv(
    csv_results,
    file.path(output_dir, "case-readiness.csv"),
    row.names = FALSE,
    fileEncoding = "UTF-8"
  )
  writeLines(
    summarize_audit(ordered),
    file.path(output_dir, "summary.md"),
    useBytes = TRUE
  )

  invisible(list(
    csv = file.path(output_dir, "case-readiness.csv"),
    summary = file.path(output_dir, "summary.md"),
    logs = log_dir
  ))
}
