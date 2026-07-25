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
required <- c("group", "time", "survival", "lower", "upper")
missing <- setdiff(required, names(data))
if (length(missing)) stop("Missing required columns: ", paste(missing, collapse = ", "))
for (column in c("time", "survival", "lower", "upper")) {
  data[[column]] <- suppressWarnings(as.numeric(data[[column]]))
  if (any(!is.finite(data[[column]]))) stop(column, " must be finite")
}
if (any(data$time < 0)) stop("time must be non-negative")
if (any(data$lower < 0 | data$upper > 1) ||
    any(data$lower > data$survival | data$survival > data$upper)) {
  stop("Survival intervals must satisfy 0 <= lower <= survival <= upper <= 1")
}
if (anyDuplicated(data[c("group", "time")])) stop("group and time keys must be unique")
data <- data[order(data$group, data$time), , drop = FALSE]
plot <- ggplot2::ggplot(
  data,
  ggplot2::aes(time, survival, color = group, fill = group)
) +
  ggplot2::geom_ribbon(
    ggplot2::aes(ymin = lower, ymax = upper),
    alpha = 0.15,
    color = NA
  ) +
  ggplot2::geom_step(linewidth = 0.9, direction = "hv") +
  ggplot2::scale_y_continuous(limits = c(0, 1)) +
  ggplot2::scale_color_manual(values = c("#3A6EA5", "#C45B45")) +
  ggplot2::scale_fill_manual(values = c("#3A6EA5", "#C45B45")) +
  ggplot2::labs(x = "Time", y = "Survival probability", color = "Group", fill = "Group") +
  ggplot2::theme_minimal(base_size = 11)
dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
ggplot2::ggsave(output_path, plot, width = 6, height = 4.5, units = "in")
message("Wrote figure: ", output_path)
