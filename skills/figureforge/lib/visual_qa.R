visual_check <- function(check_id, status, detail) {
  data.frame(
    check_id = check_id,
    status = status,
    detail = detail,
    stringsAsFactors = FALSE
  )
}

extract_svg_number <- function(text, attribute) {
  pattern <- paste0(attribute, "\\s*=\\s*[\"']([0-9.]+)")
  match <- regexec(pattern, text, perl = TRUE, ignore.case = TRUE)
  captured <- regmatches(text, match)[[1L]]
  if (length(captured) < 2L) return(NA_real_)
  suppressWarnings(as.numeric(captured[[2L]]))
}

inspect_svg_metadata <- function(path) {
  text <- paste(readLines(path, warn = FALSE), collapse = "\n")
  if (!grepl("<svg\\b", text, perl = TRUE, ignore.case = TRUE)) {
    stop("Invalid SVG document")
  }
  visible_pattern <- paste0(
    "<(path|circle|ellipse|rect|line|polyline|polygon|text|image)\\b"
  )
  visible_count <- lengths(regmatches(
    text,
    gregexpr(visible_pattern, text, perl = TRUE, ignore.case = TRUE)
  ))
  list(
    width = extract_svg_number(text, "width"),
    height = extract_svg_number(text, "height"),
    pages = 1L,
    non_blank = visible_count > 0L,
    detail = paste(visible_count, "visible SVG elements")
  )
}

inspect_pdf_metadata <- function(path) {
  header <- rawToChar(readBin(path, "raw", n = 4L))
  if (!identical(header, "%PDF")) stop("Invalid PDF signature")
  pages <- 1L
  width <- NA_real_
  height <- NA_real_
  detail <- "PDF signature is valid; optional metadata unavailable"
  if (nzchar(Sys.which("pdfinfo"))) {
    output <- system2(
      "pdfinfo",
      shQuote(path),
      stdout = TRUE,
      stderr = TRUE
    )
    page_line <- grep("^Pages:", output, value = TRUE)
    if (length(page_line) > 0L) {
      pages <- as.integer(trimws(sub("^Pages:", "", page_line[[1L]])))
    }
    size_line <- grep("^Page size:", output, value = TRUE)
    if (length(size_line) > 0L) {
      size_match <- regexec(
        "Page size:\\s*([0-9.]+) x ([0-9.]+)",
        size_line[[1L]],
        perl = TRUE
      )
      captured <- regmatches(size_line[[1L]], size_match)[[1L]]
      if (length(captured) >= 3L) {
        width <- as.numeric(captured[[2L]])
        height <- as.numeric(captured[[3L]])
      }
    }
    detail <- "PDF metadata inspected with pdfinfo"
  }
  list(
    width = width,
    height = height,
    pages = pages,
    non_blank = TRUE,
    detail = detail
  )
}

inspect_png_metadata <- function(path) {
  connection <- file(path, "rb")
  on.exit(close(connection), add = TRUE)
  signature <- readBin(connection, "raw", n = 8L)
  expected <- as.raw(c(137, 80, 78, 71, 13, 10, 26, 10))
  if (!identical(signature, expected)) stop("Invalid PNG signature")
  readBin(connection, "raw", n = 8L)
  width <- readBin(connection, "integer", n = 1L, size = 4L, endian = "big")
  height <- readBin(connection, "integer", n = 1L, size = 4L, endian = "big")
  list(
    width = as.numeric(width),
    height = as.numeric(height),
    pages = 1L,
    non_blank = NA,
    detail = "PNG signature and dimensions inspected"
  )
}

inspect_render_metadata <- function(path) {
  format <- tolower(tools::file_ext(path))
  if (!format %in% c("svg", "pdf", "png")) {
    stop("Unsupported visual format: ", format)
  }
  metadata <- switch(
    format,
    svg = inspect_svg_metadata(path),
    pdf = inspect_pdf_metadata(path),
    png = inspect_png_metadata(path)
  )
  metadata$format <- format
  metadata
}

failed_visual_report <- function(path, detail) {
  list(
    schema_version = 1L,
    status = "tool_check_failed",
    render = list(
      path = path,
      format = tolower(tools::file_ext(path)),
      bytes = if (file.exists(path)) file.info(path)$size else 0,
      width = NA_real_,
      height = NA_real_,
      pages = NA_integer_
    ),
    checks = visual_check("inspect_render", "error", detail),
    reference_comparison = list(
      status = "not_applicable",
      dimension_match = NA
    ),
    manual_review_prompts = c(
      "Resolve the tool failure before performing human visual review."
    )
  )
}

inspect_visual_output <- function(render_path, reference_path = NULL) {
  if (!file.exists(render_path) || file.info(render_path)$size <= 0L) {
    return(failed_visual_report(
      render_path,
      "Render file is missing or empty."
    ))
  }
  metadata <- tryCatch(
    inspect_render_metadata(render_path),
    error = identity
  )
  if (inherits(metadata, "error")) {
    return(failed_visual_report(
      render_path,
      conditionMessage(metadata)
    ))
  }
  blank_status <- if (is.na(metadata$non_blank)) {
    "not_applicable"
  } else if (metadata$non_blank) {
    "pass"
  } else {
    "warning"
  }
  checks <- rbind(
    visual_check("file_nonempty", "pass", "Render exists and is non-empty."),
    visual_check("format_readable", "pass", metadata$detail),
    visual_check(
      "non_blank",
      blank_status,
      if (blank_status == "warning") {
        "No visible drawing elements were detected."
      } else if (blank_status == "pass") {
        "Visible drawing content was detected."
      } else {
        "Blank-content detection is unavailable for this format."
      }
    )
  )
  comparison <- list(
    status = "not_applicable",
    dimension_match = "not_applicable"
  )
  if (!is.null(reference_path)) {
    reference <- tryCatch(
      inspect_render_metadata(reference_path),
      error = identity
    )
    if (inherits(reference, "error")) {
      comparison <- list(
        status = "warning",
        dimension_match = NA
      )
    } else if (all(is.finite(c(
      metadata$width,
      metadata$height,
      reference$width,
      reference$height
    )))) {
      matches <- isTRUE(all.equal(
        c(metadata$width, metadata$height),
        c(reference$width, reference$height)
      ))
      comparison <- list(
        status = if (matches) "pass" else "warning",
        dimension_match = matches
      )
    }
  }
  list(
    schema_version = 1L,
    status = "review_required",
    render = list(
      path = normalizePath(render_path, mustWork = TRUE),
      format = metadata$format,
      bytes = unname(file.info(render_path)$size),
      width = metadata$width,
      height = metadata$height,
      pages = metadata$pages
    ),
    checks = checks,
    reference_comparison = comparison,
    manual_review_prompts = c(
      "Confirm every visual encoding matches the scientific meaning.",
      "Inspect labels, clipping, overlap, contrast, scales, and legends.",
      "Confirm dimensions and export format suit the publication context.",
      "Record remaining limitations before human approval."
    )
  )
}

visual_json_escape <- function(value) {
  value <- gsub("\\\\", "\\\\\\\\", value)
  value <- gsub("\"", "\\\\\"", value, fixed = TRUE)
  value <- gsub("\n", "\\\\n", value, fixed = TRUE)
  value <- gsub("\r", "\\\\r", value, fixed = TRUE)
  gsub("\t", "\\\\t", value, fixed = TRUE)
}

visual_json_encode <- function(value) {
  if (is.null(value)) return("null")
  if (is.data.frame(value)) {
    rows <- lapply(seq_len(nrow(value)), function(index) {
      as.list(value[index, , drop = FALSE])
    })
    return(visual_json_encode(rows))
  }
  if (is.list(value)) {
    if (length(value) == 0L) return("[]")
    if (!is.null(names(value)) && all(nzchar(names(value)))) {
      fields <- paste0(
        "\"", visual_json_escape(names(value)), "\":",
        vapply(value, visual_json_encode, character(1))
      )
      return(paste0("{", paste(fields, collapse = ","), "}"))
    }
    return(paste0(
      "[",
      paste(vapply(value, visual_json_encode, character(1)), collapse = ","),
      "]"
    ))
  }
  if (length(value) > 1L) {
    return(paste0(
      "[",
      paste(vapply(as.list(value), visual_json_encode, character(1)),
            collapse = ","),
      "]"
    ))
  }
  if (length(value) == 0L || is.na(value)) return("null")
  if (is.logical(value)) return(if (value) "true" else "false")
  if (is.numeric(value)) return(as.character(value))
  paste0("\"", visual_json_escape(as.character(value)), "\"")
}

write_visual_qa_report <- function(report, output_path) {
  allowed <- c("review_required", "tool_check_failed", "not_applicable")
  if (!report$status %in% allowed) {
    stop("Unsupported visual QA status: ", report$status)
  }
  dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
  writeLines(
    visual_json_encode(report),
    output_path,
    useBytes = TRUE
  )
  invisible(output_path)
}
