#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
cases_dir <- if (length(args) >= 1) args[[1]] else "skills/figureforge/cases"
output_path <- if (length(args) >= 2) args[[2]] else "skills/figureforge/references/case-index.csv"

case_dirs <- list.dirs(cases_dir, recursive = FALSE, full.names = TRUE)
case_dirs <- case_dirs[basename(case_dirs) != "_template"]

extract_section <- function(lines, heading) {
  start <- which(trimws(lines) == heading)
  if (length(start) == 0) {
    return("")
  }
  start <- start[[1]] + 1
  end_candidates <- which(seq_along(lines) > start & grepl("^## ", lines))
  end <- if (length(end_candidates) == 0) length(lines) else end_candidates[[1]] - 1
  paste(trimws(lines[start:end]), collapse = " ")
}

rows <- lapply(case_dirs, function(case_dir) {
  case_md <- file.path(case_dir, "case.md")
  if (!file.exists(case_md)) {
    return(NULL)
  }
  lines <- readLines(case_md, warn = FALSE)
  data.frame(
    case_id = basename(case_dir),
    title = sub("^#\\s+", "", lines[[1]]),
    chart_type = extract_section(lines, "## Chart Type"),
    chart_type_zh = extract_section(lines, "## Chart Type Chinese"),
    aliases = extract_section(lines, "## Aliases"),
    best_for = extract_section(lines, "## Best For"),
    stringsAsFactors = FALSE
  )
})

valid_rows <- rows[!vapply(rows, is.null, logical(1))]
if (length(valid_rows) == 0) {
  index <- data.frame(
    case_id = character(0),
    title = character(0),
    chart_type = character(0),
    chart_type_zh = character(0),
    aliases = character(0),
    best_for = character(0)
  )
} else {
  index <- do.call(rbind, valid_rows)
}

dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
write.csv(index, output_path, row.names = FALSE, fileEncoding = "UTF-8")
message("Wrote case index: ", output_path)
