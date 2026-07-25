#!/usr/bin/env Rscript
args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 2L) stop("Usage: plot.R <input.csv> <output>")
input_path <- args[[1]]
output_path <- args[[2]]
if (!file.exists(input_path)) stop("Input file does not exist: ", input_path)
if (!requireNamespace("ggplot2", quietly = TRUE)) stop("Required R package is missing: ggplot2")
data <- read.csv(input_path, stringsAsFactors = FALSE, check.names = FALSE)
required <- c("gene", "feature", "start", "end", "strand", "track")
missing <- setdiff(required, names(data))
if (length(missing)) stop("Missing required columns: ", paste(missing, collapse = ", "))
for (column in c("start", "end", "track")) {
  data[[column]] <- suppressWarnings(as.numeric(data[[column]]))
  if (any(!is.finite(data[[column]]))) stop(column, " must be finite")
}
if (any(data$start < 0) || any(data$end <= data$start)) stop("coordinates require 0 <= start < end")
if (any(!data$strand %in% c("+", "-"))) stop("strand must be + or -")
if (any(data$track != floor(data$track))) stop("track must contain integers")
backbones <- aggregate(cbind(start, end) ~ gene + track, data, function(x) c(min(x), max(x)))
backbones <- do.call(rbind, lapply(split(data, data$gene), function(group) {
  data.frame(gene = group$gene[[1]], track = group$track[[1]],
             start = min(group$start), end = max(group$end))
}))
plot <- ggplot2::ggplot() +
  ggplot2::geom_segment(
    data = backbones,
    ggplot2::aes(x = start, xend = end, y = track, yend = track),
    linewidth = 1,
    color = "#555555"
  ) +
  ggplot2::geom_rect(
    data = data,
    ggplot2::aes(xmin = start, xmax = end, ymin = track - 0.22,
                 ymax = track + 0.22, fill = feature),
    color = "white",
    linewidth = 0.4
  ) +
  ggplot2::scale_y_continuous(breaks = backbones$track, labels = backbones$gene) +
  ggplot2::scale_fill_manual(values = c(Exon = "#3A6EA5", Domain = "#D07C46", Motif = "#7B6BA8")) +
  ggplot2::labs(x = "Coordinate", y = NULL, fill = "Feature") +
  ggplot2::theme_minimal(base_size = 11) +
  ggplot2::theme(panel.grid.major.y = ggplot2::element_blank())
dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
ggplot2::ggsave(output_path, plot, width = 7, height = 3.8, units = "in")
message("Wrote figure: ", output_path)
