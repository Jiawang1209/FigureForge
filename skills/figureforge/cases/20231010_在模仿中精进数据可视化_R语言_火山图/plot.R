#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
input_path <- if (length(args) >= 1) args[[1]] else "data.csv"
output_path <- if (length(args) >= 2) args[[2]] else "volcano_plot.pdf"

if (!file.exists(input_path)) {
  stop("Input data file not found: ", input_path)
}

required_packages <- c("ggplot2", "ggrepel")
missing_packages <- required_packages[!vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing_packages) > 0) {
  stop("Missing required R package(s): ", paste(missing_packages, collapse = ", "))
}

df <- read.csv(input_path, stringsAsFactors = FALSE, check.names = FALSE)
required_columns <- c("SYMBOL", "log2FoldChange", "padj")
missing_columns <- setdiff(required_columns, names(df))
if (length(missing_columns) > 0) {
  stop("Missing required column(s): ", paste(missing_columns, collapse = ", "))
}

df$SYMBOL <- sub(",.*$", "", df$SYMBOL)
if (!"change" %in% names(df)) {
  df$change <- ifelse(df$log2FoldChange >= log2(1.5) & df$padj < 0.05, "Up",
    ifelse(df$log2FoldChange <= -log2(1.5) & df$padj < 0.05, "Down", "Normal")
  )
}
df$padj_plot <- pmax(df$padj, .Machine$double.xmin)
df$neg_log10_padj <- -log10(df$padj_plot)

label_df <- df[!is.na(df$SYMBOL) & df$change != "Normal", ]
label_df <- head(label_df[order(-label_df$neg_log10_padj), ], 15)

plot <- ggplot2::ggplot(df, ggplot2::aes(x = log2FoldChange, y = neg_log10_padj)) +
  ggplot2::geom_point(ggplot2::aes(color = log2FoldChange, size = neg_log10_padj), alpha = 0.85) +
  ggplot2::geom_point(data = label_df, shape = 21, color = "black", fill = "white", show.legend = FALSE) +
  ggrepel::geom_text_repel(data = label_df, ggplot2::aes(label = SYMBOL), size = 3, max.overlaps = Inf) +
  ggplot2::scale_color_gradientn(colours = c("#3288bd", "#66c2a5", "#ffffbf", "#f46d43", "#9e0142")) +
  ggplot2::scale_size(range = c(1, 7)) +
  ggplot2::geom_vline(xintercept = c(-log2(1.5), log2(1.5)), linetype = 2) +
  ggplot2::geom_hline(yintercept = -log10(0.05), linetype = 4) +
  ggplot2::labs(x = "log2FoldChange", y = "-log10(adjusted p-value)", color = "log2FC", size = "-log10(padj)") +
  ggplot2::theme_bw(base_size = 12) +
  ggplot2::theme(panel.grid = ggplot2::element_blank())

ggplot2::ggsave(output_path, plot = plot, height = 6, width = 8)
message("Wrote figure: ", output_path)
