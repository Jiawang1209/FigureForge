#!/usr/bin/env Rscript
args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 2L) stop("Usage: plot.R <input.csv> <output>")
input_path <- args[[1]]
output_path <- args[[2]]
if (!file.exists(input_path)) stop("Input file does not exist: ", input_path)
if (!requireNamespace("ggplot2", quietly = TRUE)) stop("Required R package is missing: ggplot2")
data <- read.csv(input_path, stringsAsFactors = FALSE, check.names = FALSE)
required <- c("panel", "x", "y", "group", "lower", "upper")
missing <- setdiff(required, names(data))
if (length(missing)) stop("Missing required columns: ", paste(missing, collapse = ", "))
for (column in c("x", "y", "lower", "upper")) {
  data[[column]] <- suppressWarnings(as.numeric(data[[column]]))
  if (any(!is.finite(data[[column]]))) stop(column, " must be finite")
}
if (any(data$lower > data$y | data$y > data$upper)) {
  stop("Intervals must satisfy lower <= y <= upper")
}
if (anyDuplicated(data[c("panel", "x", "group")])) stop("panel, x, and group keys must be unique")
data <- data[order(data$panel, data$group, data$x), , drop = FALSE]
plot <- ggplot2::ggplot(
  data,
  ggplot2::aes(x, y, color = group, fill = group)
) +
  ggplot2::geom_ribbon(
    ggplot2::aes(ymin = lower, ymax = upper),
    alpha = 0.16,
    color = NA
  ) +
  ggplot2::geom_line(linewidth = 0.8) +
  ggplot2::geom_point(size = 1.8) +
  ggplot2::facet_wrap(ggplot2::vars(panel), nrow = 1) +
  ggplot2::scale_color_manual(values = c("#3A6EA5", "#C45B45")) +
  ggplot2::scale_fill_manual(values = c("#3A6EA5", "#C45B45")) +
  ggplot2::labs(x = "Index", y = "Response", color = "Group", fill = "Group") +
  ggplot2::theme_minimal(base_size = 11) +
  ggplot2::theme(panel.grid.minor = ggplot2::element_blank())
dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
ggplot2::ggsave(output_path, plot, width = 8.2, height = 4.2, units = "in")
message("Wrote figure: ", output_path)
