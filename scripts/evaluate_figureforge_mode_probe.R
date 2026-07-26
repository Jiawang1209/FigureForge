#!/usr/bin/env Rscript

args_all <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args_all, value = TRUE)
decode_rscript_file_path <- function(path) {
  gsub("~+~", " ", path, fixed = TRUE)
}
script_path <- normalizePath(
  decode_rscript_file_path(sub("^--file=", "", file_arg[[1L]])),
  mustWork = TRUE
)
source(file.path(
  dirname(script_path),
  "lib",
  "live_mode_evaluation.R"
))

parse_args <- function(args) {
  values <- list()
  index <- 1L
  while (index <= length(args)) {
    key <- args[[index]]
    if (!startsWith(key, "--") || index == length(args)) {
      stop("Unknown or incomplete argument: ", key)
    }
    values[[sub("^--", "", key)]] <- args[[index + 1L]]
    index <- index + 2L
  }
  required <- c(
    "expected-mode",
    "workspace",
    "installed-skill",
    "manifest",
    "trusted-cat",
    "trusted-sed",
    "transcript",
    "validator-log",
    "validator-status",
    "output"
  )
  missing <- setdiff(required, names(values))
  if (length(missing) > 0L) {
    stop("Missing arguments: ", paste(missing, collapse = ", "))
  }
  values
}

options <- parse_args(commandArgs(trailingOnly = TRUE))
result <- evaluate_live_mode_probe(
  expected_mode = options[["expected-mode"]],
  workspace_root = options[["workspace"]],
  installed_skill_root = options[["installed-skill"]],
  manifest_path = options[["manifest"]],
  trusted_reader_paths = c(
    cat = options[["trusted-cat"]],
    sed = options[["trusted-sed"]]
  ),
  transcript_path = options[["transcript"]],
  validator_log = options[["validator-log"]],
  validator_status = as.integer(options[["validator-status"]])
)
write.csv(
  result,
  options[["output"]],
  row.names = FALSE,
  quote = TRUE,
  fileEncoding = "UTF-8"
)
if (!isTRUE(result$passed[[1L]])) quit(status = 1L)
