#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
input_path <- if (length(args) >= 1) args[[1]] else "data.csv"
output_path <- if (length(args) >= 2) args[[2]] else "plot_linearfitting.pdf"

if (!file.exists(input_path)) {
  stop("Input data file not found: ", input_path)
}

required_packages <- c("ggplot2")
missing_packages <- required_packages[!vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing_packages) > 0) {
  stop("Missing required R package(s): ", paste(missing_packages, collapse = ", "))
}

data <- read.csv(input_path, stringsAsFactors = FALSE)
required_columns <- c("carat", "price", "cut")
missing_columns <- setdiff(required_columns, names(data))
if (length(missing_columns) > 0) {
  stop("Missing required column(s): ", paste(missing_columns, collapse = ", "))
}

model <- stats::lm(price ~ carat, data = data)
adj_r2 <- summary(model)$adj.r.squared
subtitle <- paste0("Global linear fit adjusted R2 = ", round(adj_r2, 3))

plot <- ggplot2::ggplot(data, ggplot2::aes(x = carat, y = price, color = cut, group = cut)) +
  ggplot2::geom_point(ggplot2::aes(shape = cut), size = 2.6, alpha = 0.7) +
  ggplot2::geom_smooth(method = "lm", formula = y ~ x, se = FALSE, linewidth = 0.7) +
  ggplot2::labs(x = "Carat", y = "Price", color = "Cut", shape = "Cut", subtitle = subtitle) +
  ggplot2::theme_bw(base_size = 12) +
  ggplot2::theme(
    panel.grid = ggplot2::element_blank(),
    plot.subtitle = ggplot2::element_text(hjust = 0.5)
  )

ggplot2::ggsave(output_path, plot = plot, height = 6, width = 8)
message("Wrote figure: ", output_path)
