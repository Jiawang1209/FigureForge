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
required <- c("variable_x", "variable_y", "correlation")
missing <- setdiff(required, names(data))
if (length(missing) > 0L) {
  stop("Missing required columns: ", paste(missing, collapse = ", "))
}
data$correlation <- suppressWarnings(as.numeric(data$correlation))
if (any(!is.finite(data$correlation)) ||
    any(data$correlation < -1 | data$correlation > 1)) {
  stop("correlation must contain finite values from -1 to 1")
}
if (anyDuplicated(data[c("variable_x", "variable_y")])) {
  stop("variable_x and variable_y pairs must be unique")
}
levels <- unique(c(data$variable_x, data$variable_y))
data$variable_x <- factor(data$variable_x, levels = levels)
data$variable_y <- factor(data$variable_y, levels = rev(levels))
plot <- ggplot2::ggplot(
  data,
  ggplot2::aes(x = variable_x, y = variable_y, fill = correlation)
) +
  ggplot2::geom_tile(color = "white", linewidth = 0.8) +
  ggplot2::geom_text(
    ggplot2::aes(label = sprintf("%.2f", correlation)),
    size = 3.4
  ) +
  ggplot2::scale_fill_gradient2(
    low = "#3B6FB6",
    mid = "white",
    high = "#C84A43",
    midpoint = 0,
    limits = c(-1, 1)
  ) +
  ggplot2::coord_equal() +
  ggplot2::labs(x = NULL, y = NULL, fill = "Correlation") +
  ggplot2::theme_minimal(base_size = 11) +
  ggplot2::theme(panel.grid = ggplot2::element_blank())
dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
ggplot2::ggsave(output_path, plot, width = 5.5, height = 5, units = "in")
message("Wrote figure: ", output_path)
