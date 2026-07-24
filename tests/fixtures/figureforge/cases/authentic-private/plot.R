#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
input_path <- args[[1]]
output_path <- args[[2]]
data <- read.csv(input_path)
grDevices::pdf(output_path)
graphics::plot(data$x, data$y)
grDevices::dev.off()
