make_validation_result <- function(checks, messages = character(0), evidence = list()) {
  check_names <- names(checks)
  checks <- as.logical(checks)
  names(checks) <- check_names
  failed <- names(checks)[!checks]
  list(
    ok = length(failed) == 0,
    checks = checks,
    failed_checks = failed,
    messages = messages,
    evidence = evidence
  )
}

required_case_headings <- function() {
  c(
    "## Chart Type",
    "## Chart Type Chinese",
    "## Aliases",
    "## Best For",
    "## Best For Chinese",
    "## Data Schema",
    "## Visual Encoding",
    "## ggplot Components",
    "## Adaptation Notes",
    "## Common Pitfalls"
  )
}

extract_markdown_section <- function(lines, heading) {
  start <- which(trimws(lines) == heading)
  if (length(start) == 0) {
    return(character(0))
  }
  start <- start[[1]] + 1L
  later_headings <- which(
    seq_along(lines) >= start &
      grepl("^## ", trimws(lines))
  )
  end <- if (length(later_headings) == 0) {
    length(lines)
  } else {
    later_headings[[1]] - 1L
  }
  if (start > end) {
    return(character(0))
  }
  lines[start:end]
}

validate_case_structure <- function(case_dir) {
  required_files <- c("case.md", "data.csv", "plot.R")
  file_checks <- vapply(
    file.path(case_dir, required_files),
    is_nonempty_file,
    logical(1)
  )
  names(file_checks) <- paste("non-empty", required_files)

  case_lines <- read_text_safely(file.path(case_dir, "case.md"))
  heading_checks <- vapply(
    required_case_headings(),
    function(heading) any(trimws(case_lines) == heading),
    logical(1)
  )
  names(heading_checks) <- paste("heading", required_case_headings())

  make_validation_result(c(file_checks, heading_checks))
}

declared_r_packages <- function(case_lines) {
  section <- trimws(
    extract_markdown_section(case_lines, "## Required R Packages")
  )
  items <- sub(
    "^[-*]\\s+",
    "",
    section[grepl("^[-*]\\s+\\S+", section, perl = TRUE)]
  )
  items[nzchar(items)]
}

validate_case_completion <- function(
  case_dir,
  render_output = NULL,
  rscript = "/usr/local/bin/Rscript"
) {
  structure <- validate_case_structure(case_dir)
  case_lines <- read_text_safely(file.path(case_dir, "case.md"))
  plot_lines <- read_text_safely(file.path(case_dir, "plot.R"))
  packages <- declared_r_packages(case_lines)
  distribution <- detect_distribution(case_dir)

  checks <- c(
    "structure" = structure$ok,
    "data provenance" = any(
      trimws(case_lines) == "## Data Provenance"
    ),
    "required R packages" = length(packages) > 0,
    "scaffold markers" = !detect_scaffold(case_dir),
    "plot argument contract" = all(c(
      any(grepl(
        "commandArgs\\s*\\(\\s*trailingOnly\\s*=\\s*TRUE\\s*\\)",
        plot_lines,
        perl = TRUE
      )),
      any(grepl("\\binput_path\\b", plot_lines, perl = TRUE)),
      any(grepl("\\boutput_path\\b", plot_lines, perl = TRUE))
    )),
    "reproduction evidence" = detect_reproduction(case_dir),
    "QA verified" = detect_qa_verified(case_dir)
  )

  messages <- c()
  if (!structure$ok) {
    messages <- c(
      messages,
      paste(
        "Structural failures:",
        paste(structure$failed_checks, collapse = ", ")
      )
    )
  }
  if (!isTRUE(distribution$public_ready)) {
    messages <- c(
      messages,
      "Distribution is not explicitly allowed; case remains private_only."
    )
  }

  render <- NULL
  if (!is.null(render_output)) {
    render <- render_case_for_audit(
      case_dir,
      render_output,
      rscript = rscript
    )
    checks <- c(checks, "render succeeded" = isTRUE(render$ok))
    if (!isTRUE(render$ok)) {
      messages <- c(
        messages,
        paste0(
          "Fresh render failed",
          if (is.na(render$status)) "" else paste0(" with status ", render$status),
          if (nzchar(render$log)) paste0(": ", render$log) else ""
        )
      )
    }
  }

  make_validation_result(
    checks,
    messages = messages,
    evidence = list(
      required_r_packages = packages,
      public_ready = isTRUE(distribution$public_ready),
      private_only = !isTRUE(distribution$public_ready),
      render_status = if (is.null(render)) NA_integer_ else render$status,
      render_log = if (is.null(render)) "" else render$log,
      render_output = if (is.null(render_output)) "" else render_output
    )
  )
}
