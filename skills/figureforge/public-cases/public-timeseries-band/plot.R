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
required <- c("time", "estimate", "lower", "upper", "group")
missing <- setdiff(required, names(data))
if (length(missing) > 0L) {
  stop("Missing required columns: ", paste(missing, collapse = ", "))
}
for (column in c("time", "estimate", "lower", "upper")) {
  data[[column]] <- suppressWarnings(as.numeric(data[[column]]))
  if (any(!is.finite(data[[column]]))) {
    stop(column, " must contain finite numbers")
  }
}
if (any(data$lower > data$estimate) || any(data$estimate > data$upper)) {
  stop("Intervals must satisfy lower <= estimate <= upper")
}
if (any(!nzchar(trimws(data$group)))) stop("group must not be empty")
data <- data[order(data$group, data$time), , drop = FALSE]
plot <- ggplot2::ggplot(
  data,
  ggplot2::aes(x = time, y = estimate, color = group, fill = group)
) +
  ggplot2::geom_ribbon(
    ggplot2::aes(ymin = lower, ymax = upper),
    alpha = 0.18,
    color = NA
  ) +
  ggplot2::geom_line(linewidth = 0.8) +
  ggplot2::geom_point(size = 2) +
  ggplot2::scale_color_manual(values = c("#3A6EA5", "#C45B45")) +
  ggplot2::scale_fill_manual(values = c("#3A6EA5", "#C45B45")) +
  ggplot2::labs(x = "Time", y = "Estimate", color = "Group", fill = "Group") +
  ggplot2::theme_minimal(base_size = 11) +
  ggplot2::theme(panel.grid.minor = ggplot2::element_blank())
dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
ggplot2::ggsave(output_path, plot, width = 6.2, height = 4.2, units = "in")
message("Wrote figure: ", output_path)
