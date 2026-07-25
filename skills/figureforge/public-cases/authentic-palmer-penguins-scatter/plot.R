#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 2L) stop("Usage: plot.R <input.csv> <output>")
input_path <- args[[1L]]
output_path <- args[[2L]]
if (!file.exists(input_path)) stop("Input file does not exist: ", input_path)
if (!requireNamespace("ggplot2", quietly = TRUE)) {
  stop("Required R package is missing: ggplot2")
}
data <- read.csv(input_path, stringsAsFactors = FALSE, check.names = FALSE)
required <- c(
  "species",
  "bill_length_mm",
  "bill_depth_mm",
  "body_mass_g",
  "sex"
)
missing <- setdiff(required, names(data))
if (length(missing) > 0L) {
  stop("Missing required columns: ", paste(missing, collapse = ", "))
}
for (column in c("bill_length_mm", "bill_depth_mm", "body_mass_g")) {
  data[[column]] <- suppressWarnings(as.numeric(data[[column]]))
  if (any(!is.finite(data[[column]]) | data[[column]] <= 0)) {
    stop(column, " must contain finite positive numbers")
  }
}
for (column in c("species", "sex")) {
  if (any(!nzchar(trimws(data[[column]])))) {
    stop(column, " must not be empty")
  }
}
data$species <- factor(
  data$species,
  levels = c("Adelie", "Chinstrap", "Gentoo")
)
if (any(is.na(data$species))) stop("species contains an unsupported value")
plot <- ggplot2::ggplot(
  data,
  ggplot2::aes(
    x = bill_length_mm,
    y = bill_depth_mm,
    color = species
  )
) +
  ggplot2::geom_point(alpha = 0.72, size = 2) +
  ggplot2::geom_smooth(
    method = "lm",
    formula = y ~ x,
    se = FALSE,
    linewidth = 0.8
  ) +
  ggplot2::scale_color_manual(
    values = c(
      Adelie = "#E69F00",
      Chinstrap = "#56B4E9",
      Gentoo = "#009E73"
    )
  ) +
  ggplot2::labs(
    x = "Bill length (mm)",
    y = "Bill depth (mm)",
    color = "Species",
    title = "Palmer Penguins bill measurements"
  ) +
  ggplot2::theme_minimal(base_size = 11) +
  ggplot2::theme(panel.grid.minor = ggplot2::element_blank())
dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
ggplot2::ggsave(output_path, plot, width = 6.4, height = 4.5, units = "in")
message("Wrote figure: ", output_path)
