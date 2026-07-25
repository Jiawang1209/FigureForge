doctor_check <- function(
  check_id,
  layer,
  requirement,
  detected_version,
  status,
  remediation,
  capability,
  detected_path = "",
  resolution_source = ""
) {
  data.frame(
    check_id = check_id,
    layer = layer,
    requirement = requirement,
    detected_version = detected_version,
    detected_path = detected_path,
    resolution_source = resolution_source,
    status = status,
    remediation = remediation,
    capability = capability,
    stringsAsFactors = FALSE
  )
}

default_command_detector <- function(name) nzchar(Sys.which(name))

default_package_detector <- function(name) {
  requireNamespace(name, quietly = TRUE)
}

detected_package_version <- function(name, installed) {
  if (!installed) return("")
  tryCatch(
    as.character(utils::packageVersion(name)),
    error = function(error) "installed"
  )
}

run_doctor <- function(
  case_dir = NULL,
  rscript = NULL,
  runtime_resolver = resolve_rscript,
  command_detector = default_command_detector,
  package_detector = default_package_detector
) {
  runtime <- tryCatch(
    runtime_resolver(cli_path = rscript),
    error = function(error) list(
      path = "",
      source = if (is.null(rscript)) "" else "cli",
      version = "",
      error = conditionMessage(error)
    )
  )
  version_ok <- !nzchar(runtime$error %||% "") &&
    tryCatch(
      utils::compareVersion(runtime$version, "4.1.0") >= 0L,
      error = function(error) FALSE
    )
  rows <- list(doctor_check(
    "runtime-rscript",
    "runtime",
    "required",
    runtime$version,
    if (version_ok) "pass" else "error",
    if (version_ok) {
      ""
    } else if (nzchar(runtime$error %||% "")) {
      runtime$error
    } else {
      paste(
        "Install R 4.1 or newer, pass --rscript PATH, or set",
        "FIGUREFORGE_RSCRIPT."
      )
    },
    "R plotting and validation",
    detected_path = runtime$path,
    resolution_source = runtime$source
  ))

  commands <- data.frame(
    name = c("sh", "git", "pdfinfo", "pdftoppm"),
    requirement = c("required", "required", "optional", "optional"),
    capability = c(
      "shell workflows",
      "release and clean-clone checks",
      "PDF metadata inspection",
      "PDF raster preview"
    ),
    stringsAsFactors = FALSE
  )
  for (row_index in seq_len(nrow(commands))) {
    command <- commands[row_index, , drop = FALSE]
    installed <- isTRUE(command_detector(command$name))
    status <- if (installed) {
      "pass"
    } else if (command$requirement == "required") {
      "error"
    } else {
      "warning"
    }
    rows[[length(rows) + 1L]] <- doctor_check(
      paste0("system-", command$name),
      "system",
      command$requirement,
      if (installed) "available" else "",
      status,
      if (installed) "" else paste("Install system command", command$name),
      command$capability
    )
  }

  required_packages <- c("base", "ggplot2")
  optional_packages <- character(0)
  if (!is.null(case_dir)) {
    metadata <- read_case_metadata(case_dir)
    required_packages <- metadata$required_packages
    optional_packages <- metadata$optional_packages
  }
  package_groups <- list(
    required_r_package = unique(required_packages),
    optional_r_package = unique(optional_packages)
  )
  for (layer in names(package_groups)) {
    packages <- package_groups[[layer]]
    requirement <- if (layer == "required_r_package") {
      "required"
    } else {
      "optional"
    }
    for (package in packages[nzchar(packages)]) {
      installed <- isTRUE(package_detector(package))
      status <- if (installed) {
        "pass"
      } else if (requirement == "required") {
        "error"
      } else {
        "warning"
      }
      rows[[length(rows) + 1L]] <- doctor_check(
        paste0("r-package-", package),
        layer,
        requirement,
        detected_package_version(package, installed),
        status,
        if (installed) "" else paste("Install R package", package),
        if (requirement == "required") {
          "case rendering"
        } else {
          paste(package, "enhancement")
        }
      )
    }
  }
  report <- do.call(rbind, rows)
  layer_order <- match(
    report$layer,
    c("runtime", "system", "required_r_package", "optional_r_package")
  )
  report[order(layer_order, report$check_id), , drop = FALSE]
}

doctor_exit_status <- function(report, strict = FALSE) {
  if (isTRUE(strict) && any(report$status == "error")) 1L else 0L
}

json_escape <- function(value) {
  value <- gsub("\\\\", "\\\\\\\\", value)
  value <- gsub("\"", "\\\\\"", value, fixed = TRUE)
  value <- gsub("\n", "\\\\n", value, fixed = TRUE)
  value <- gsub("\r", "\\\\r", value, fixed = TRUE)
  gsub("\t", "\\\\t", value, fixed = TRUE)
}

json_quote <- function(value) paste0("\"", json_escape(value), "\"")

write_doctor_json <- function(report, path) {
  fields <- names(report)
  rows <- vapply(seq_len(nrow(report)), function(row_index) {
    values <- vapply(fields, function(field) {
      paste0(json_quote(field), ":", json_quote(report[[field]][[row_index]]))
    }, character(1))
    paste0("{", paste(values, collapse = ","), "}")
  }, character(1))
  payload <- paste0(
    "{\"schema_version\":1,\"checks\":[",
    paste(rows, collapse = ","),
    "]}"
  )
  writeLines(payload, path, useBytes = TRUE)
  invisible(path)
}

write_doctor_text <- function(report, path = stdout()) {
  display <- report[
    ,
    c("layer", "check_id", "requirement", "status", "detected_version",
      "detected_path", "resolution_source", "capability", "remediation"),
    drop = FALSE
  ]
  write.table(
    display,
    file = path,
    row.names = FALSE,
    sep = "\t",
    quote = FALSE
  )
  invisible(path)
}
