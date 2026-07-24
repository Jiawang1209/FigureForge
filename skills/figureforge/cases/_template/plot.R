#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
input_path <- if (length(args) >= 1) args[[1]] else "data.csv"
output_path <- if (length(args) >= 2) args[[2]] else "template-output.png"

if (!file.exists(input_path)) {
  stop("Input data file not found: ", input_path)
}

required_packages <- c("ggplot2")
missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]
if (length(missing_packages) > 0) {
  stop(
    "Missing required R package(s): ",
    paste(missing_packages, collapse = ", ")
  )
}

data <- read.csv(input_path, stringsAsFactors = FALSE)
required_columns <- c("x", "y", "group", "label")
missing_columns <- setdiff(required_columns, names(data))
if (length(missing_columns) > 0) {
  stop("Missing required column(s): ", paste(missing_columns, collapse = ", "))
}

plot <- ggplot2::ggplot(
  data,
  ggplot2::aes(x = x, y = y, color = group)
) +
  ggplot2::geom_point(size = 2.8) +
  ggplot2::geom_line(ggplot2::aes(group = group), linewidth = 0.6) +
  ggplot2::labs(x = "Template x", y = "Template y", color = "Group") +
  ggplot2::theme_minimal(base_size = 11) +
  ggplot2::theme(panel.grid.minor = ggplot2::element_blank())

ggplot2::ggsave(
  output_path,
  plot = plot,
  width = 5,
  height = 3.5,
  dpi = 300
)
message("Wrote figure: ", output_path)
