#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
script_path <- if (length(file_arg) > 0L) {
  normalizePath(sub("^--file=", "", file_arg[[1L]]), mustWork = TRUE)
} else {
  normalizePath(
    "tests/figureforge/test_schema_matching.R",
    mustWork = TRUE
  )
}
repo_root <- normalizePath(
  file.path(dirname(script_path), "..", ".."),
  mustWork = TRUE
)
source(file.path(
  repo_root,
  "skills",
  "figureforge",
  "lib",
  "distribution_validation.R"
))
source(file.path(
  repo_root,
  "skills",
  "figureforge",
  "lib",
  "checksums.R"
))
source(file.path(
  repo_root,
  "skills",
  "figureforge",
  "lib",
  "metadata.R"
))
source(file.path(
  repo_root,
  "skills",
  "figureforge",
  "lib",
  "schema_matching.R"
))

public_cases_dir <- file.path(
  repo_root,
  "skills",
  "figureforge",
  "public-cases"
)
timeseries_metadata <- read_case_metadata(file.path(
  public_cases_dir,
  "public-timeseries-band"
))
profile <- data.frame(
  column = c("处理组", "时间", "均值", "下限", "上限"),
  inferred_type = c(
    "character",
    "numeric",
    "numeric",
    "numeric",
    "numeric"
  ),
  cardinality = c("categorical", rep("continuous", 4L)),
  stringsAsFactors = FALSE
)
mapping <- c(
  group = "处理组",
  time = "时间",
  estimate = "均值",
  lower = "下限",
  upper = "上限"
)
match <- match_case_schema(timeseries_metadata, profile, mapping)
stopifnot(identical(match$status, "compatible"))
stopifnot(length(match$missing_required_roles) == 0L)
stopifnot(nrow(match$field_mappings) == 5L)

missing_mapping <- mapping[names(mapping) != "upper"]
missing <- match_case_schema(
  timeseries_metadata,
  profile,
  missing_mapping
)
stopifnot(identical(missing$status, "incompatible"))
stopifnot(identical(missing$missing_required_roles, "upper"))

integer_profile <- profile
integer_profile$inferred_type[integer_profile$column == "时间"] <- "integer"
partial <- match_case_schema(
  timeseries_metadata,
  integer_profile,
  mapping
)
stopifnot(identical(partial$status, "partially_compatible"))
stopifnot(length(partial$allowed_transformations) >= 1L)
stopifnot(length(partial$assumptions) >= 1L)

catalog <- build_public_catalog(public_cases_dir)
paired_queries <- list(
  c("correlation heatmap", "相关性热图"),
  c("time series uncertainty", "时序图 不确定性"),
  c("gene structure", "基因结构图"),
  c("survival curve", "生存曲线")
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
for (query_pair in paired_queries) {
  english <- rank_public_cases(catalog, query_pair[[1L]], limit = 5L)
  chinese <- rank_public_cases(catalog, query_pair[[2L]], limit = 5L)
  stopifnot(nrow(english) >= 1L, nrow(chinese) >= 1L)
  stopifnot(identical(english$case_id[[1L]], chinese$case_id[[1L]]))
  stopifnot(all(score_columns %in% names(english)))
  stopifnot(all(score_columns %in% names(chinese)))
}

tie_catalog <- catalog[catalog$case_id %in% c(
  "public-bar-grouped",
  "public-scatter-fit"
), , drop = FALSE]
tie <- rank_public_cases(tie_catalog, "synthetic fixture", limit = 2L)
stopifnot(identical(tie$case_id, sort(tie$case_id)))
stopifnot(!"score_distribution" %in% names(tie))

input_path <- tempfile("figureforge-schema-", fileext = ".csv")
mapping_path <- tempfile("figureforge-mapping-", fileext = ".csv")
write.csv(
  data.frame(
    处理组 = c("A", "A", "B", "B"),
    时间 = c(0, 1, 0, 1),
    均值 = c(2.0, 2.5, 2.2, 3.0),
    下限 = c(1.8, 2.2, 2.0, 2.7),
    上限 = c(2.2, 2.8, 2.4, 3.3),
    check.names = FALSE
  ),
  input_path,
  row.names = FALSE,
  fileEncoding = "UTF-8"
)
write.csv(
  data.frame(
    role = names(mapping),
    input_column = unname(mapping),
    stringsAsFactors = FALSE
  ),
  mapping_path,
  row.names = FALSE,
  fileEncoding = "UTF-8"
)

matcher_cli <- file.path(
  repo_root,
  "skills",
  "figureforge",
  "scripts",
  "match_schema.R"
)
match_output <- tempfile("figureforge-schema-match-", fileext = ".csv")
match_log <- tempfile("figureforge-schema-match-", fileext = ".log")
match_status <- system2(
  "/usr/local/bin/Rscript",
  shQuote(c(
    matcher_cli,
    "--case", "public-timeseries-band",
    "--input", input_path,
    "--mapping", mapping_path,
    "--output", match_output
  )),
  stdout = match_log,
  stderr = match_log
)
stopifnot(identical(as.integer(match_status), 0L))
match_report <- read.csv(
  match_output,
  stringsAsFactors = FALSE,
  check.names = FALSE
)
stopifnot(all(match_report$status == "compatible"))

search_cli <- file.path(
  repo_root,
  "skills",
  "figureforge",
  "scripts",
  "search_cases.R"
)
search_output <- tempfile("figureforge-public-search-", fileext = ".csv")
search_log <- tempfile("figureforge-public-search-", fileext = ".log")
search_status <- system2(
  "/usr/local/bin/Rscript",
  shQuote(c(
    search_cli,
    "--public",
    "--query", "相关性热图",
    "--search-intent", "relationship",
    "--schema", input_path,
    "--explain-scores",
    "--output", search_output
  )),
  stdout = search_log,
  stderr = search_log
)
stopifnot(identical(as.integer(search_status), 0L))
search_results <- read.csv(
  search_output,
  stringsAsFactors = FALSE,
  check.names = FALSE,
  na.strings = character(0)
)
expected_receipt_columns <- c(
  "receipt_schema_version",
  "receipt_generator",
  "search_query_sha256",
  "search_intent",
  "search_scope",
  "schema_sha256",
  "search_limit",
  "completed_only",
  "explain_scores",
  "result_rank",
  "case_id_sha256",
  "score"
)
stopifnot(identical(names(search_results), expected_receipt_columns))
stopifnot(all(search_results$receipt_schema_version == 2L))
stopifnot(all(search_results$receipt_generator == "figureforge-search_cases"))
stopifnot(all(
  search_results$search_query_sha256 ==
    figureforge_sha256_text("相关性热图")
))
stopifnot(all(search_results$search_intent == "relationship"))
stopifnot(all(search_results$search_scope == "public"))
stopifnot(all(
  search_results$schema_sha256 == figureforge_sha256(input_path)
))
stopifnot(all(search_results$search_limit == 10L))
stopifnot(all(!search_results$completed_only))
stopifnot(all(search_results$explain_scores))
stopifnot(identical(
  search_results$case_id_sha256[[1L]],
  figureforge_sha256_text("public-correlation-heatmap")
))
stopifnot(!any(c(
  "case_id",
  "title_en",
  "title_zh",
  "case_path"
) %in% names(search_results)))
stopifnot(!any(vapply(
  unlist(search_results, use.names = FALSE),
  function(value) grepl(
    "(^/|file://|^[A-Za-z]:[\\\\/])",
    as.character(value),
    perl = TRUE,
    ignore.case = TRUE
  ),
  logical(1L)
)))
search_log_text <- paste(
  readLines(search_log, warn = FALSE, encoding = "UTF-8"),
  collapse = "\n"
)
stopifnot(grepl(
  "public-correlation-heatmap",
  search_log_text,
  fixed = TRUE
))
stopifnot(grepl(
  "Wrote search receipt:",
  search_log_text,
  fixed = TRUE
))
stopifnot(!grepl(
  "Wrote search results:",
  search_log_text,
  fixed = TRUE
))

run_search <- function(arguments, output = tempfile(fileext = ".log")) {
  result <- suppressWarnings(system2(
    "/usr/local/bin/Rscript",
    c(shQuote(search_cli), shQuote(arguments)),
    stdout = output,
    stderr = output
  ))
  list(
    status = if (is.null(attr(result, "status"))) {
      as.integer(result)
    } else {
      as.integer(attr(result, "status"))
    },
    text = paste(readLines(output, warn = FALSE), collapse = "\n")
  )
}

sensitive_query <- paste(
  "SSN 123-45-6789",
  "password=super-secret",
  "source(user_identifier, api_key)",
  sep = "\n"
)
privacy_receipt <- tempfile("figureforge-private-query-", fileext = ".csv")
privacy_search <- run_search(c(
  "--public",
  "--query", sensitive_query,
  "--search-intent", "relationship",
  "--schema", input_path,
  "--output", privacy_receipt
))
stopifnot(identical(privacy_search$status, 0L))
privacy_bytes <- paste(
  readLines(privacy_receipt, warn = FALSE, encoding = "UTF-8"),
  collapse = "\n"
)
stopifnot(!grepl("123-45-6789", privacy_bytes, fixed = TRUE))
stopifnot(!grepl("super-secret", privacy_bytes, fixed = TRUE))
stopifnot(!grepl("user_identifier", privacy_bytes, fixed = TRUE))
privacy_data <- read.csv(
  privacy_receipt,
  stringsAsFactors = FALSE,
  check.names = FALSE,
  na.strings = character(0)
)
stopifnot(all(
  privacy_data$search_query_sha256 ==
    figureforge_sha256_text(sensitive_query)
))
stopifnot(all(privacy_data$search_intent == "relationship"))

invalid_intent_receipt <- tempfile(
  "figureforge-invalid-intent-",
  fileext = ".csv"
)
invalid_intent <- run_search(c(
  "--public",
  "--query", "group comparison",
  "--search-intent", "patient-123 password=secret",
  "--schema", input_path,
  "--output", invalid_intent_receipt
))
stopifnot(identical(as.integer(invalid_intent$status), 1L))
stopifnot(!file.exists(invalid_intent_receipt))

schema_before <- readBin(input_path, "raw", n = file.info(input_path)$size)
schema_collision <- run_search(c(
  "--public",
  "--query", "relationship",
  "--search-intent", "relationship",
  "--schema", input_path,
  "--output", input_path
))
stopifnot(identical(as.integer(schema_collision$status), 1L))
stopifnot(identical(
  readBin(input_path, "raw", n = file.info(input_path)$size),
  schema_before
))

schema_alias <- tempfile("figureforge-schema-alias-", fileext = ".csv")
stopifnot(file.symlink(input_path, schema_alias))
schema_alias_collision <- run_search(c(
  "--public",
  "--query", "relationship",
  "--search-intent", "relationship",
  "--schema", input_path,
  "--output", schema_alias
))
stopifnot(identical(as.integer(schema_alias_collision$status), 1L))
stopifnot(Sys.readlink(schema_alias) != "")
stopifnot(identical(
  readBin(input_path, "raw", n = file.info(input_path)$size),
  schema_before
))

case_evidence <- file.path(
  public_cases_dir,
  "public-correlation-heatmap",
  "case.md"
)
case_evidence_before <- readBin(
  case_evidence,
  "raw",
  n = file.info(case_evidence)$size
)
evidence_collision <- run_search(c(
  "--public",
  "--query", "correlation heatmap",
  "--search-intent", "relationship",
  "--schema", input_path,
  "--output", case_evidence
))
stopifnot(identical(as.integer(evidence_collision$status), 1L))
stopifnot(identical(
  readBin(case_evidence, "raw", n = file.info(case_evidence)$size),
  case_evidence_before
))

symlink_target <- tempfile("figureforge-receipt-target-", fileext = ".csv")
writeLines("preserve this target", symlink_target)
symlink_output <- tempfile("figureforge-receipt-link-", fileext = ".csv")
stopifnot(file.symlink(symlink_target, symlink_output))
symlink_collision <- run_search(c(
  "--public",
  "--query", "relationship",
  "--search-intent", "relationship",
  "--schema", input_path,
  "--output", symlink_output
))
stopifnot(identical(as.integer(symlink_collision$status), 1L))
stopifnot(identical(readLines(symlink_target), "preserve this target"))

rollback_receipt <- tempfile("figureforge-rollback-", fileext = ".csv")
writeLines("existing receipt remains", rollback_receipt)
failed_search <- run_search(c(
  "--cases-dir", file.path(tempdir(), "missing-cases"),
  "--query", "relationship",
  "--search-intent", "relationship",
  "--schema", input_path,
  "--output", rollback_receipt
))
stopifnot(identical(as.integer(failed_search$status), 1L))
stopifnot(identical(
  readLines(rollback_receipt),
  "existing receipt remains"
))

message("schema matching tests: PASS")
