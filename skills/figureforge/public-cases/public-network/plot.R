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
required <- c("record_type", "node_id", "node_label", "x", "y", "group", "source", "target")
missing <- setdiff(required, names(data))
if (length(missing)) stop("Missing required columns: ", paste(missing, collapse = ", "))
if (any(!data$record_type %in% c("node", "edge"))) stop("record_type must be node or edge")
nodes <- data[data$record_type == "node", , drop = FALSE]
edges <- data[data$record_type == "edge", , drop = FALSE]
if (!nrow(nodes)) stop("At least one node is required")
if (anyDuplicated(nodes$node_id) || any(!nzchar(nodes$node_id))) {
  stop("node_id must be non-empty and unique")
}
nodes$x <- suppressWarnings(as.numeric(nodes$x))
nodes$y <- suppressWarnings(as.numeric(nodes$y))
if (any(!is.finite(nodes$x)) || any(!is.finite(nodes$y))) {
  stop("node coordinates must be finite")
}
if (any(!edges$source %in% nodes$node_id) || any(!edges$target %in% nodes$node_id)) {
  stop("Every edge endpoint must reference an existing node")
}
edges$x <- nodes$x[match(edges$source, nodes$node_id)]
edges$y <- nodes$y[match(edges$source, nodes$node_id)]
edges$xend <- nodes$x[match(edges$target, nodes$node_id)]
edges$yend <- nodes$y[match(edges$target, nodes$node_id)]
plot <- ggplot2::ggplot() +
  ggplot2::geom_segment(
    data = edges,
    ggplot2::aes(x, y, xend = xend, yend = yend),
    linewidth = 0.8,
    color = "#8A8A8A"
  ) +
  ggplot2::geom_point(
    data = nodes,
    ggplot2::aes(x, y, color = group),
    size = 5
  ) +
  ggplot2::geom_text(
    data = nodes,
    ggplot2::aes(x, y, label = node_label),
    nudge_y = 0.18,
    size = 3.4
  ) +
  ggplot2::scale_color_manual(values = c(Core = "#315B7D", Peripheral = "#D07C46")) +
  ggplot2::coord_equal() +
  ggplot2::theme_void(base_size = 11) +
  ggplot2::theme(legend.position = "bottom")
dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
ggplot2::ggsave(output_path, plot, width = 5.6, height = 5, units = "in")
message("Wrote figure: ", output_path)
