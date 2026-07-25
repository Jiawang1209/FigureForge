#!/usr/bin/env Rscript
args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 2L) stop("Usage: plot.R <input.csv> <output>")
input_path <- args[[1]]
output_path <- args[[2]]
if (!file.exists(input_path)) stop("Input file does not exist: ", input_path)
if (!requireNamespace("ggplot2", quietly = TRUE)) stop("Required R package is missing: ggplot2")
data <- read.csv(input_path, stringsAsFactors = FALSE, check.names = FALSE, na.strings = "")
required <- c("node", "parent", "x", "y", "label", "clade", "is_tip")
missing <- setdiff(required, names(data))
if (length(missing)) stop("Missing required columns: ", paste(missing, collapse = ", "))
if (anyDuplicated(data$node) || any(!nzchar(data$node))) stop("node must be unique and non-empty")
data$x <- suppressWarnings(as.numeric(data$x))
data$y <- suppressWarnings(as.numeric(data$y))
if (any(!is.finite(data$x)) || any(!is.finite(data$y))) stop("coordinates must be finite")
data$is_tip <- tolower(as.character(data$is_tip)) == "true"
non_root <- !is.na(data$parent) & nzchar(data$parent)
if (any(!data$parent[non_root] %in% data$node)) stop("Every parent must reference an existing node")
edges <- data[non_root, , drop = FALSE]
edges$parent_x <- data$x[match(edges$parent, data$node)]
edges$parent_y <- data$y[match(edges$parent, data$node)]
tips <- data[data$is_tip, , drop = FALSE]
plot <- ggplot2::ggplot() +
  ggplot2::geom_segment(
    data = edges,
    ggplot2::aes(x = parent_x, y = y, xend = x, yend = y),
    linewidth = 0.7,
    color = "#555555"
  ) +
  ggplot2::geom_segment(
    data = edges,
    ggplot2::aes(x = parent_x, y = parent_y, xend = parent_x, yend = y),
    linewidth = 0.7,
    color = "#555555"
  ) +
  ggplot2::geom_point(data = tips, ggplot2::aes(x, y, color = clade), size = 3) +
  ggplot2::geom_text(
    data = tips,
    ggplot2::aes(x, y, label = label, color = clade),
    hjust = -0.12,
    size = 3.3
  ) +
  ggplot2::scale_color_manual(values = c(Clade_1 = "#3A6EA5", Clade_2 = "#C45B45")) +
  ggplot2::coord_cartesian(clip = "off") +
  ggplot2::theme_void(base_size = 11) +
  ggplot2::theme(plot.margin = ggplot2::margin(8, 70, 8, 8))
dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
ggplot2::ggsave(output_path, plot, width = 6, height = 4.6, units = "in")
message("Wrote figure: ", output_path)
