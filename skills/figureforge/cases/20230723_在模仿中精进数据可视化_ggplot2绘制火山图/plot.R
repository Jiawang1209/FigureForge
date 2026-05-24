#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
input_path <- if (length(args) >= 1) args[[1]] else "data.csv"
output_path <- if (length(args) >= 2) args[[2]] else "figure.pdf"

if (!file.exists(input_path)) {
  stop("Input data file not found: ", input_path)
}

required_packages <- c("ggplot2", "ggrepel")
missing_packages <- required_packages[!vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing_packages) > 0) {
  stop("Missing required R package(s): ", paste(missing_packages, collapse = ", "))
}

deg <- read.csv(input_path, stringsAsFactors = FALSE)
required_columns <- c("Gene", "log2FoldChange1", "log2FoldChange2")
missing_columns <- setdiff(required_columns, names(deg))
if (length(missing_columns) > 0) {
  stop("Missing required column(s): ", paste(missing_columns, collapse = ", "))
}
deg <- deg[stats::complete.cases(deg[required_columns]), ]

deg$Change <- ifelse(
  deg$log2FoldChange1 > 0.25 & deg$log2FoldChange2 > 0.25,
  "Up",
  ifelse(deg$log2FoldChange1 < -0.25 & deg$log2FoldChange2 < -0.25, "Down", "Normal")
)
deg$value <- 0.5 * (deg$log2FoldChange1 + deg$log2FoldChange2)

up_labels <- head(deg[deg$Change == "Up", ][order(-deg[deg$Change == "Up", "log2FoldChange1"], -deg[deg$Change == "Up", "log2FoldChange2"]), ], 20)
down_labels <- head(deg[deg$Change == "Down", ][order(deg[deg$Change == "Down", "log2FoldChange1"], deg[deg$Change == "Down", "log2FoldChange2"]), ], 20)

plot <- ggplot2::ggplot(deg, ggplot2::aes(x = log2FoldChange1, y = log2FoldChange2, color = Change)) +
  ggplot2::geom_hline(yintercept = 0, linetype = "dashed", linewidth = 0.4) +
  ggplot2::geom_vline(xintercept = 0, linetype = "dashed", linewidth = 0.4) +
  ggplot2::geom_point(alpha = 0.85, size = 1.8) +
  ggrepel::geom_text_repel(
    data = up_labels,
    ggplot2::aes(label = Gene),
    color = "#d6604d",
    box.padding = 0.5,
    max.overlaps = Inf,
    size = 3
  ) +
  ggrepel::geom_text_repel(
    data = down_labels,
    ggplot2::aes(label = Gene),
    color = "#4393c3",
    box.padding = 0.5,
    max.overlaps = Inf,
    size = 3
  ) +
  ggplot2::scale_color_manual(values = c("Down" = "#92c5de", "Normal" = "#bababa", "Up" = "#f4a582")) +
  ggplot2::labs(x = "log2FoldChange 1", y = "log2FoldChange 2", color = "Change") +
  ggplot2::theme_bw(base_size = 12) +
  ggplot2::theme(panel.grid = ggplot2::element_blank())

ggplot2::ggsave(output_path, plot = plot, height = 6, width = 8)
message("Wrote figure: ", output_path)
