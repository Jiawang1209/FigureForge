#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
input_path <- if (length(args) >= 1) args[[1]] else "data.csv"
output_path <- if (length(args) >= 2) args[[2]] else "p_all.pdf"

if (!file.exists(input_path)) {
  stop("Input data file not found: ", input_path)
}

required_packages <- c("ggplot2")
missing_packages <- required_packages[!vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing_packages) > 0) {
  stop("Missing required R package(s): ", paste(missing_packages, collapse = ", "))
}

data <- read.csv(input_path, check.names = FALSE)
numeric_data <- data[vapply(data, is.numeric, logical(1))]
if (ncol(numeric_data) < 2) {
  stop("Correlation heatmap requires at least two numeric columns")
}

cor_matrix <- stats::cor(numeric_data, use = "pairwise.complete.obs")
diag(cor_matrix) <- NA

df <- as.data.frame(as.table(cor_matrix), stringsAsFactors = FALSE)
names(df) <- c("ID", "Type", "Value")
df <- df[!is.na(df$Value), ]
df$ID <- factor(df$ID, levels = colnames(cor_matrix))
df$Type <- factor(df$Type, levels = colnames(cor_matrix))

plot <- ggplot2::ggplot(df, ggplot2::aes(x = ID, y = Type)) +
  ggplot2::geom_tile(fill = "white", color = "gray60", linewidth = 0.45) +
  ggplot2::geom_point(ggplot2::aes(fill = Value, size = abs(Value)), shape = 21, color = "black", stroke = 0.25) +
  ggplot2::geom_abline(slope = 1, intercept = 0, linewidth = 0.6) +
  ggplot2::scale_fill_gradient2(low = "#3288bd", mid = "white", high = "#d53e4f", midpoint = 0, limits = c(-1, 1)) +
  ggplot2::scale_size(range = c(2, 9), guide = "none") +
  ggplot2::scale_x_discrete(position = "top") +
  ggplot2::labs(x = NULL, y = NULL, fill = "r") +
  ggplot2::coord_fixed() +
  ggplot2::theme_minimal(base_size = 11) +
  ggplot2::theme(
    panel.grid = ggplot2::element_blank(),
    axis.text.x = ggplot2::element_text(angle = 45, hjust = 0),
    axis.text = ggplot2::element_text(color = "black")
  )

ggplot2::ggsave(output_path, plot = plot, height = 7, width = 7)
message("Wrote figure: ", output_path)
