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
required <- c("group", "value", "sample_id")
missing <- setdiff(required, names(data))
if (length(missing) > 0L) {
  stop("Missing required columns: ", paste(missing, collapse = ", "))
}
data$value <- suppressWarnings(as.numeric(data$value))
if (any(!is.finite(data$value))) stop("value must contain finite numbers")
if (any(!nzchar(trimws(data$group)))) stop("group must not be empty")
if (anyDuplicated(data$sample_id)) stop("sample_id must be unique")
data$group <- factor(data$group, levels = unique(data$group))
set.seed(1102)
plot <- ggplot2::ggplot(
  data,
  ggplot2::aes(x = group, y = value, fill = group)
) +
  ggplot2::geom_violin(width = 0.85, alpha = 0.45, color = NA) +
  ggplot2::geom_boxplot(width = 0.18, outlier.shape = NA, alpha = 0.8) +
  ggplot2::geom_point(
    position = ggplot2::position_jitter(width = 0.09, height = 0, seed = 1102),
    size = 2,
    alpha = 0.75
  ) +
  ggplot2::scale_fill_manual(values = c("#5B8E7D", "#D88C67")) +
  ggplot2::labs(x = NULL, y = "Observed value") +
  ggplot2::theme_minimal(base_size = 11) +
  ggplot2::theme(
    legend.position = "none",
    panel.grid.major.x = ggplot2::element_blank()
  )
dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
ggplot2::ggsave(output_path, plot, width = 5.4, height = 4.4, units = "in")
message("Wrote figure: ", output_path)
