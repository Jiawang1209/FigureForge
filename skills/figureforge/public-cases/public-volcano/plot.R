#!/usr/bin/env Rscript
args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 2L) stop("Usage: plot.R <input.csv> <output>")
input_path <- args[[1]]
output_path <- args[[2]]
if (!file.exists(input_path)) stop("Input file does not exist: ", input_path)
if (!requireNamespace("ggplot2", quietly = TRUE)) {
  stop("Required R package is missing: ggplot2")
}
data <- read.csv(input_path, stringsAsFactors = FALSE, check.names = FALSE)
required <- c("feature", "log2_fold_change", "adjusted_p", "class")
missing <- setdiff(required, names(data))
if (length(missing)) stop("Missing required columns: ", paste(missing, collapse = ", "))
data$log2_fold_change <- suppressWarnings(as.numeric(data$log2_fold_change))
data$adjusted_p <- suppressWarnings(as.numeric(data$adjusted_p))
if (any(!is.finite(data$log2_fold_change))) stop("log2_fold_change must be finite")
if (any(!is.finite(data$adjusted_p)) ||
    any(data$adjusted_p <= 0 | data$adjusted_p > 1)) {
  stop("adjusted_p must be greater than 0 and at most 1")
}
if (anyDuplicated(data$feature)) stop("feature must be unique")
allowed <- c("Down", "Not_significant", "Up")
if (any(!data$class %in% allowed)) stop("class contains unsupported values")
data$minus_log10_p <- -log10(data$adjusted_p)
plot <- ggplot2::ggplot(
  data,
  ggplot2::aes(log2_fold_change, minus_log10_p, color = class)
) +
  ggplot2::geom_hline(yintercept = -log10(0.05), linetype = 2, color = "grey55") +
  ggplot2::geom_vline(xintercept = c(-1, 1), linetype = 2, color = "grey55") +
  ggplot2::geom_point(size = 2.7, alpha = 0.85) +
  ggplot2::scale_color_manual(
    values = c(Down = "#3B6FB6", Not_significant = "#A8A8A8", Up = "#C84A43")
  ) +
  ggplot2::labs(
    x = expression(log[2]~fold~change),
    y = expression(-log[10]~adjusted~p),
    color = "Class"
  ) +
  ggplot2::theme_minimal(base_size = 11)
dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
ggplot2::ggsave(output_path, plot, width = 5.8, height = 4.5, units = "in")
message("Wrote figure: ", output_path)
