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
required <- c("term", "gene_ratio", "adjusted_p", "count", "category")
missing <- setdiff(required, names(data))
if (length(missing) > 0L) {
  stop("Missing required columns: ", paste(missing, collapse = ", "))
}
for (column in c("gene_ratio", "adjusted_p", "count")) {
  data[[column]] <- suppressWarnings(as.numeric(data[[column]]))
  if (any(!is.finite(data[[column]]))) {
    stop(column, " must contain finite numbers")
  }
}
if (any(data$gene_ratio < 0)) stop("gene_ratio must be non-negative")
if (any(data$adjusted_p <= 0 | data$adjusted_p > 1)) {
  stop("adjusted_p must be greater than 0 and at most 1")
}
if (any(data$count <= 0 | data$count != floor(data$count))) {
  stop("count must contain positive integers")
}
if (any(!nzchar(trimws(data$term))) ||
    any(!nzchar(trimws(data$category)))) {
  stop("term and category must not be empty")
}
data$significance <- -log10(data$adjusted_p)
data$term <- factor(data$term, levels = rev(data$term[order(data$gene_ratio)]))
plot <- ggplot2::ggplot(
  data,
  ggplot2::aes(
    x = gene_ratio,
    y = term,
    size = count,
    color = significance
  )
) +
  ggplot2::geom_point(alpha = 0.85) +
  ggplot2::facet_grid(
    rows = ggplot2::vars(category),
    scales = "free_y",
    space = "free_y"
  ) +
  ggplot2::scale_color_gradient(low = "#F3C677", high = "#8E2C2C") +
  ggplot2::scale_size_continuous(range = c(3, 8)) +
  ggplot2::labs(
    x = "Gene ratio",
    y = NULL,
    color = expression(-log[10](adjusted~p)),
    size = "Count"
  ) +
  ggplot2::theme_minimal(base_size = 10.5) +
  ggplot2::theme(
    panel.grid.major.y = ggplot2::element_blank(),
    strip.text.y = ggplot2::element_text(angle = 0)
  )
dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
ggplot2::ggsave(output_path, plot, width = 7.4, height = 5.2, units = "in")
message("Wrote figure: ", output_path)
