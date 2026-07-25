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
required <- c("treatment", "response", "condition")
missing <- setdiff(required, names(data))
if (length(missing) > 0L) {
  stop("Missing required columns: ", paste(missing, collapse = ", "))
}
data$response <- suppressWarnings(as.numeric(data$response))
if (any(!is.finite(data$response)) || any(data$response < 0)) {
  stop("response must contain finite non-negative numbers")
}
if (any(!nzchar(trimws(data$treatment))) ||
    any(!nzchar(trimws(data$condition)))) {
  stop("treatment and condition must not be empty")
}
data$treatment <- factor(data$treatment, levels = unique(data$treatment))
data$condition <- factor(data$condition, levels = unique(data$condition))
plot <- ggplot2::ggplot(
  data,
  ggplot2::aes(x = treatment, y = response, fill = condition)
) +
  ggplot2::geom_col(
    position = ggplot2::position_dodge(width = 0.78),
    width = 0.68
  ) +
  ggplot2::scale_y_continuous(expand = ggplot2::expansion(mult = c(0, 0.08))) +
  ggplot2::scale_fill_manual(values = c("#3977A8", "#E07A5F")) +
  ggplot2::labs(x = "Treatment", y = "Response", fill = "Condition") +
  ggplot2::theme_minimal(base_size = 11) +
  ggplot2::theme(
    panel.grid.major.x = ggplot2::element_blank(),
    panel.grid.minor = ggplot2::element_blank()
  )
dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
ggplot2::ggsave(output_path, plot, width = 6.2, height = 4.2, units = "in")
message("Wrote figure: ", output_path)
