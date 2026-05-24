#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 1) {
  stop("Usage: render_case.R <case_dir> [output_path]")
}

case_dir <- normalizePath(args[[1]], mustWork = TRUE)
plot_script <- file.path(case_dir, "plot.R")
input_path <- file.path(case_dir, "data.csv")
output_path <- if (length(args) >= 2) args[[2]] else file.path(case_dir, "output.png")

if (!file.exists(plot_script)) {
  stop("Missing plot script: ", plot_script)
}
if (!file.exists(input_path)) {
  stop("Missing data file: ", input_path)
}

command_args <- c(plot_script, input_path, output_path)
status <- system2("Rscript", command_args)
if (!identical(status, 0L)) {
  stop("Case rendering failed with status: ", status)
}

message("Rendered case output: ", output_path)
