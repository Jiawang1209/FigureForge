#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)

if (length(args) == 1L) {
  output_path <- args[[1L]]
  set.seed(3101)
  time <- rep(0:7, times = 2L)
  group <- rep(c("对照组", "处理组"), each = 8L)
  baseline <- ifelse(group == "处理组", 0.8, 0)
  estimate <- 2.5 + baseline + 0.35 * time +
    stats::rnorm(length(time), sd = 0.08)
  spread <- 0.22 + 0.02 * time
  data <- data.frame(
    时间 = time,
    均值 = round(estimate, 3),
    下限 = round(estimate - spread, 3),
    上限 = round(estimate + spread, 3),
    处理组 = group,
    check.names = FALSE
  )
  dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
  write.csv(
    data,
    output_path,
    row.names = FALSE,
    fileEncoding = "UTF-8"
  )
  message("Wrote deterministic Chinese-column input: ", output_path)
} else if (length(args) == 3L && identical(args[[1L]], "--canonicalize")) {
  input_path <- args[[2L]]
  output_path <- args[[3L]]
  data <- read.csv(
    input_path,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  required <- c("时间", "均值", "下限", "上限", "处理组")
  missing <- setdiff(required, names(data))
  if (length(missing) > 0L) {
    stop("Missing Chinese demo columns: ", paste(missing, collapse = ", "))
  }
  canonical <- data.frame(
    time = data[["时间"]],
    estimate = data[["均值"]],
    lower = data[["下限"]],
    upper = data[["上限"]],
    group = data[["处理组"]],
    check.names = FALSE
  )
  write.csv(
    canonical,
    output_path,
    row.names = FALSE,
    fileEncoding = "UTF-8"
  )
  message("Wrote canonical adaptation input: ", output_path)
} else {
  stop(
    "Usage: generate_input.R OUTPUT.csv\n",
    "   or: generate_input.R --canonicalize INPUT.csv OUTPUT.csv"
  )
}
