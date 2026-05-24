#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
input_path <- if (length(args) >= 1) args[[1]] else "data.csv"
output_path <- if (length(args) >= 2) args[[2]] else "One-way_ANOVA.pdf"

if (!file.exists(input_path)) {
  stop("Input data file not found: ", input_path)
}

required_packages <- c("ggplot2")
missing_packages <- required_packages[!vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing_packages) > 0) {
  stop("Missing required R package(s): ", paste(missing_packages, collapse = ", "))
}

wide <- read.csv(input_path, check.names = FALSE)
if (ncol(wide) == 0) {
  stop("Input data has no columns: ", input_path)
}

long <- stack(wide)
names(long) <- c("Value", "Sample")
long <- long[!is.na(long$Value), ]
long$Group <- sub("_.*$", "", long$Sample)
long$Group <- factor(long$Group, levels = unique(long$Group))

anova_model <- stats::aov(Value ~ Group, data = long)
anova_p <- summary(anova_model)[[1]][["Pr(>F)"]][[1]]
subtitle <- paste0("One-way ANOVA p = ", format.pval(anova_p, digits = 3))

plot <- ggplot2::ggplot(long, ggplot2::aes(x = Group, y = Value, color = Group)) +
  ggplot2::geom_boxplot(outlier.shape = NA, linewidth = 0.5) +
  ggplot2::geom_jitter(width = 0.18, alpha = 0.65, size = 1.4) +
  ggplot2::labs(x = "Group", y = "Value", subtitle = subtitle) +
  ggplot2::theme_bw(base_size = 11) +
  ggplot2::theme(
    panel.grid = ggplot2::element_blank(),
    legend.position = "none",
    axis.text.x = ggplot2::element_text(angle = 45, hjust = 1)
  )

ggplot2::ggsave(output_path, plot = plot, height = 5.5, width = 8)
message("Wrote figure: ", output_path)
