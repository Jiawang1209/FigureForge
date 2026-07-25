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
required <- c("predictor", "response")
missing <- setdiff(required, names(data))
if (length(missing) > 0L) {
  stop("Missing required columns: ", paste(missing, collapse = ", "))
}
data$predictor <- suppressWarnings(as.numeric(data$predictor))
data$response <- suppressWarnings(as.numeric(data$response))
if (any(!is.finite(data$predictor)) || any(!is.finite(data$response))) {
  stop("predictor and response must contain finite numbers")
}
if (!"group" %in% names(data)) data$group <- "All"
if (any(!nzchar(trimws(data$group)))) stop("group must not be empty")
plot <- ggplot2::ggplot(
  data,
  ggplot2::aes(x = predictor, y = response, color = group)
) +
  ggplot2::geom_smooth(
    ggplot2::aes(group = 1),
    method = "lm",
    formula = y ~ x,
    se = TRUE,
    color = "#505050",
    fill = "#B8C5D6",
    alpha = 0.25,
    linewidth = 0.7
  ) +
  ggplot2::geom_point(size = 2.7, alpha = 0.85) +
  ggplot2::scale_color_manual(values = c("#2F6690", "#D1495B", "#5B8E7D")) +
  ggplot2::labs(x = "Predictor", y = "Response", color = "Group") +
  ggplot2::theme_minimal(base_size = 11) +
  ggplot2::theme(panel.grid.minor = ggplot2::element_blank())
dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
ggplot2::ggsave(output_path, plot, width = 5.8, height = 4.4, units = "in")
message("Wrote figure: ", output_path)
