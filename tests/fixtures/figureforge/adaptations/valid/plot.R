#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
input_path <- args[[1]]
output_path <- args[[2]]
data <- read.csv(input_path, stringsAsFactors = FALSE)
grDevices::pdf(output_path)
graphics::barplot(data$value, names.arg = data$category)
grDevices::dev.off()
