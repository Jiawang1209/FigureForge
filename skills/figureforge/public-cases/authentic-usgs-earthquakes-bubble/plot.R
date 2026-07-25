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
required <- c("time", "depth", "mag", "place")
missing <- setdiff(required, names(data))
if (length(missing) > 0L) {
  stop("Missing required columns: ", paste(missing, collapse = ", "))
}
data$time <- as.POSIXct(
  data$time,
  format = "%Y-%m-%dT%H:%M:%OSZ",
  tz = "UTC"
)
if (any(is.na(data$time))) stop("time must contain ISO 8601 UTC values")
for (column in c("depth", "mag")) {
  data[[column]] <- suppressWarnings(as.numeric(data[[column]]))
  if (any(!is.finite(data[[column]]))) {
    stop(column, " must contain finite numbers")
  }
}
if (any(data$depth < 0)) stop("depth must be non-negative")
if (any(!nzchar(trimws(data$place)))) stop("place must not be empty")
data <- data[order(data$time, data$place), , drop = FALSE]
plot <- ggplot2::ggplot(
  data,
  ggplot2::aes(x = time, y = depth, size = mag, color = mag)
) +
  ggplot2::geom_point(alpha = 0.72) +
  ggplot2::scale_y_reverse() +
  ggplot2::scale_size_continuous(range = c(2, 10)) +
  ggplot2::scale_color_viridis_c(option = "C", direction = -1) +
  ggplot2::guides(size = "none") +
  ggplot2::labs(
    x = "Event time (UTC)",
    y = "Depth (km)",
    size = "Magnitude",
    color = "Magnitude",
    title = "USGS magnitude 5+ earthquakes, January 2024"
  ) +
  ggplot2::theme_minimal(base_size = 11) +
  ggplot2::theme(
    panel.grid.minor = ggplot2::element_blank(),
    legend.position = "right"
  )
dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
ggplot2::ggsave(output_path, plot, width = 7.2, height = 4.6, units = "in")
message("Wrote figure: ", output_path)
