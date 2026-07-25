required_adaptation_headings <- function() {
  c(
    "## Selected Case",
    "## Field Mapping",
    "## Transformations",
    "## Required R Packages",
    "## Run Command"
  )
}

render_adaptation <- function(
  adaptation_dir,
  output_path,
  rscript = "/usr/local/bin/Rscript"
) {
  plot_script <- file.path(adaptation_dir, "plot.R")
  input_path <- file.path(adaptation_dir, "input.csv")
  if (!is_nonempty_file(plot_script) || !is_nonempty_file(input_path)) {
    return(list(
      ok = FALSE,
      status = NA_integer_,
      log = "Missing non-empty plot.R or input.csv"
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
  log_path <- tempfile("figureforge-adaptation-", fileext = ".log")
  on.exit(unlink(log_path), add = TRUE)
  status <- system2(
    rscript,
    shQuote(c(plot_script, input_path, output_path)),
    stdout = log_path,
    stderr = log_path
  )
  log <- paste(read_text_safely(log_path), collapse = "\n")
  list(
    ok = identical(as.integer(status), 0L) &&
      is_nonempty_file(output_path),
    status = as.integer(status),
    log = log
  )
}

validate_adaptation <- function(
  adaptation_dir,
  render_output = NULL,
  rscript = "/usr/local/bin/Rscript"
) {
  required_files <- c("input.csv", "plot.R", "mapping.md", "qa.md")
  file_checks <- vapply(
    file.path(adaptation_dir, required_files),
    is_nonempty_file,
    logical(1)
  )
  names(file_checks) <- paste("non-empty", required_files)

  mapping_lines <- read_text_safely(
    file.path(adaptation_dir, "mapping.md")
  )
  heading_checks <- vapply(
    required_adaptation_headings(),
    function(heading) any(trimws(mapping_lines) == heading),
    logical(1)
  )
  names(heading_checks) <- paste(
    "mapping heading",
    required_adaptation_headings()
  )
  plot_lines <- read_text_safely(file.path(adaptation_dir, "plot.R"))
  argument_contract <- all(c(
    any(grepl(
      "commandArgs\\s*\\(\\s*trailingOnly\\s*=\\s*TRUE\\s*\\)",
      plot_lines,
      perl = TRUE
    )),
    any(grepl("\\binput_path\\b", plot_lines, perl = TRUE)),
    any(grepl("\\boutput_path\\b", plot_lines, perl = TRUE))
  ))
  package_section <- trimws(extract_markdown_section(
    mapping_lines,
    "## Required R Packages"
  ))
  declared_packages <- sub(
    "^[-*]\\s+",
    "",
    package_section[
      grepl("^[-*]\\s+\\S+", package_section, perl = TRUE)
    ]
  )
  qa_lines <- trimws(read_text_safely(file.path(adaptation_dir, "qa.md")))
  qa_status <- if (any(tolower(qa_lines) == "status: verified")) {
    "verified"
  } else if (any(tolower(qa_lines) == "status: review_required")) {
    "review_required"
  } else {
    ""
  }
  checks <- c(
    file_checks,
    heading_checks,
    "declared R packages" = length(declared_packages) > 0,
    "plot argument contract" = argument_contract,
    "QA status recorded" = qa_status %in% c("review_required", "verified")
  )
  messages <- character(0)
  render <- NULL
  if (!is.null(render_output)) {
    render <- render_adaptation(
      adaptation_dir,
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
      required_r_packages = declared_packages,
      qa_status = qa_status,
      render_status = if (is.null(render)) NA_integer_ else render$status,
      render_log = if (is.null(render)) "" else render$log,
      render_output = if (is.null(render_output)) "" else render_output
    )
  )
}
