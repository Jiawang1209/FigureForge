supported_blocker_statuses <- function() {
  c(
    "blocked_source_missing",
    "blocked_dependency",
    "blocked_visual_reference",
    "blocked_corrupt_asset",
    "blocked_ambiguous_mapping",
    "blocked_rights"
  )
}

required_blocker_headings <- function() {
  c(
    "## Files Inspected",
    "## Commands Run",
    "## Recovery Attempts",
    "## Why Unsafe To Infer",
    "## Unblock Requirement"
  )
}

blocker_section_has_evidence <- function(lines, heading) {
  section <- trimws(extract_markdown_section(lines, heading))
  section <- section[nzchar(section)]
  if (length(section) == 0) {
    return(FALSE)
  }
  text <- tolower(paste(section, collapse = " "))
  template_markers <- c(
    "replace this text",
    "describe the",
    "add evidence",
    "tbd",
    "todo"
  )
  !any(vapply(
    template_markers,
    grepl,
    logical(1),
    x = text,
    fixed = TRUE
  ))
}

validate_blocker_record <- function(case_dir) {
  blocker_path <- file.path(case_dir, "blocker.md")
  lines <- read_text_safely(blocker_path)
  status_lines <- trimws(lines[
    grepl("^Status\\s*:", trimws(lines), ignore.case = TRUE, perl = TRUE)
  ])
  status <- if (length(status_lines) == 1L) {
    trimws(sub(
      "^Status\\s*:\\s*",
      "",
      status_lines[[1]],
      ignore.case = TRUE,
      perl = TRUE
    ))
  } else {
    ""
  }
  headings <- required_blocker_headings()
  heading_checks <- vapply(
    headings,
    function(heading) any(trimws(lines) == heading),
    logical(1)
  )
  evidence_checks <- vapply(
    headings,
    function(heading) blocker_section_has_evidence(lines, heading),
    logical(1)
  )
  checks <- c(
    "non-empty blocker.md" = is_nonempty_file(blocker_path),
    "one status" = length(status_lines) == 1L,
    "supported status" = status %in% supported_blocker_statuses(),
    "required headings" = all(heading_checks),
    "non-empty evidence sections" = all(evidence_checks),
    "not QA verified" = !detect_qa_verified(case_dir)
  )
  unsafe_lines <- trimws(extract_markdown_section(
    lines,
    "## Why Unsafe To Infer"
  ))
  unsafe_lines <- unsafe_lines[nzchar(unsafe_lines)]
  summary <- if (length(unsafe_lines) == 0) "" else unsafe_lines[[1]]

  list(
    ok = all(checks),
    status = status,
    summary = summary,
    checks = checks,
    failed_checks = names(checks)[!checks],
    evidence = list(
      blocker_path = blocker_path,
      headings = stats::setNames(heading_checks, headings),
      sections = stats::setNames(evidence_checks, headings)
    )
  )
}
