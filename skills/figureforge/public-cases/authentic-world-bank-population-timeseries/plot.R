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
required <- c("country_code", "country", "year", "population")
missing <- setdiff(required, names(data))
if (length(missing) > 0L) {
  stop("Missing required columns: ", paste(missing, collapse = ", "))
}
data$year <- suppressWarnings(as.integer(data$year))
data$population <- suppressWarnings(as.numeric(data$population))
if (any(is.na(data$year)) || any(data$year < 1900L)) {
  stop("year must contain valid integers")
}
if (any(!is.finite(data$population) | data$population <= 0)) {
  stop("population must contain finite positive numbers")
}
for (column in c("country_code", "country")) {
  if (any(!nzchar(trimws(data[[column]])))) {
    stop(column, " must not be empty")
  }
}
keys <- paste(data$country_code, data$year, sep = "\r")
if (anyDuplicated(keys)) stop("country_code and year must be unique")
data <- data[order(data$country_code, data$year), , drop = FALSE]
plot <- ggplot2::ggplot(
  data,
  ggplot2::aes(x = year, y = population, color = country)
) +
  ggplot2::geom_line(linewidth = 0.85) +
  ggplot2::geom_point(size = 1.4) +
  ggplot2::scale_y_continuous(
    labels = function(value) paste0(
      format(round(value / 1e6), trim = TRUE, scientific = FALSE),
      "M"
    )
  ) +
  ggplot2::scale_color_brewer(palette = "Dark2") +
  ggplot2::labs(
    x = "Year",
    y = "Population",
    color = "Country",
    title = "World Bank population estimates, 2000-2023"
  ) +
  ggplot2::theme_minimal(base_size = 11) +
  ggplot2::theme(
    panel.grid.minor = ggplot2::element_blank(),
    legend.position = "right"
  )
dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
ggplot2::ggsave(output_path, plot, width = 7.2, height = 4.6, units = "in")
message("Wrote figure: ", output_path)
