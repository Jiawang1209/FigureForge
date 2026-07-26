#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2L) {
  stop(
    "Usage: Rscript plot.R <input-file> <output-directory>",
    call. = FALSE
  )
}

input_file <- args[[1L]]
output_directory <- args[[2L]]
measure_columns <- c(
  "Sepal.Length",
  "Sepal.Width",
  "Petal.Length",
  "Petal.Width"
)
required_columns <- c(measure_columns, "Species")

abort <- function(message) {
  stop(message, call. = FALSE)
}

if (!file.exists(input_file) || isTRUE(file.info(input_file)$isdir)) {
  abort(paste0("Input file does not exist or is not a file: ", input_file))
}
if (!requireNamespace("ggplot2", quietly = TRUE)) {
  abort("The ggplot2 package is required. Install it with install.packages('ggplot2').")
}

input <- tryCatch(
  utils::read.csv(
    input_file,
    stringsAsFactors = FALSE,
    check.names = FALSE
  ),
  error = function(error) {
    abort(paste0("Could not read input CSV: ", conditionMessage(error)))
  }
)

missing_columns <- setdiff(required_columns, names(input))
if (length(missing_columns) > 0L) {
  abort(paste0(
    "Input is missing required column(s): ",
    paste(missing_columns, collapse = ", ")
  ))
}
if (nrow(input) == 0L) {
  abort("Input must contain at least one data row.")
}

for (column in measure_columns) {
  values <- input[[column]]
  if (!is.numeric(values)) {
    abort(paste0("Required measure ", column, " must be numeric."))
  }
  if (anyNA(values)) {
    abort(paste0("Required measure ", column, " contains missing or NA values."))
  }
  if (any(!is.finite(values))) {
    abort(paste0("Required measure ", column, " contains non-finite or Inf values."))
  }
  if (!is.finite(stats::var(values)) || stats::var(values) == 0) {
    abort(paste0(
      "Required measure ",
      column,
      " has zero variance or is constant."
    ))
  }
}

species <- as.character(input$Species)
if (anyNA(species) || any(!nzchar(trimws(species)))) {
  abort("Species contains missing, empty, or blank values.")
}
group_sizes <- table(species)
if (any(group_sizes < 3L)) {
  undersized <- names(group_sizes)[group_sizes < 3L]
  abort(paste0(
    "Every Species group must contain at least 3 rows; undersized group(s): ",
    paste(undersized, collapse = ", ")
  ))
}
input$Species <- species

if (file.exists(output_directory) && !isTRUE(file.info(output_directory)$isdir)) {
  abort(paste0("Output path exists but is not a directory: ", output_directory))
}
if (!dir.exists(output_directory)) {
  created <- dir.create(output_directory, recursive = TRUE, showWarnings = FALSE)
  if (!created) {
    abort(paste0("Could not create output directory: ", output_directory))
  }
}
output_filenames <- c(
  "plot.png",
  "plot.pdf",
  "pca-variance.csv",
  "pca-scores.csv",
  "pca-loadings.csv",
  "index.html"
)
resolved_input <- normalizePath(input_file, mustWork = TRUE)
resolved_outputs <- vapply(
  file.path(output_directory, output_filenames),
  normalizePath,
  character(1),
  mustWork = FALSE
)
if (resolved_input %in% resolved_outputs) {
  abort(
    "Input file would be overwritten by a generated output; choose a different output directory."
  )
}

pca <- stats::prcomp(
  input[measure_columns],
  center = TRUE,
  scale. = TRUE
)
components <- paste0("PC", seq_along(pca$sdev))
eigenvalues <- pca$sdev^2
explained_percent <- 100 * eigenvalues / sum(eigenvalues)

variance <- data.frame(
  component = components,
  eigenvalue = eigenvalues,
  explained_percent = explained_percent,
  cumulative_percent = cumsum(explained_percent),
  check.names = FALSE
)
scores <- data.frame(
  sample_id = sprintf("iris_%03d", seq_len(nrow(input))),
  Species = input$Species,
  pca$x[, components, drop = FALSE],
  check.names = FALSE
)
loadings <- data.frame(
  variable = measure_columns,
  pca$rotation[measure_columns, components, drop = FALSE],
  check.names = FALSE
)

utils::write.csv(
  variance,
  file.path(output_directory, "pca-variance.csv"),
  row.names = FALSE
)
utils::write.csv(
  scores,
  file.path(output_directory, "pca-scores.csv"),
  row.names = FALSE
)
utils::write.csv(
  loadings,
  file.path(output_directory, "pca-loadings.csv"),
  row.names = FALSE
)

score_extent <- max(abs(scores[, c("PC1", "PC2")]))
loading_extent <- max(abs(loadings[, c("PC1", "PC2")]))
arrow_scale <- if (loading_extent > 0) {
  0.72 * score_extent / loading_extent
} else {
  1
}
loading_plot <- loadings
loading_plot$PC1_plot <- loading_plot$PC1 * arrow_scale
loading_plot$PC2_plot <- loading_plot$PC2 * arrow_scale
loading_plot$label_x <- loading_plot$PC1_plot * 1.08
loading_plot$label_y <- loading_plot$PC2_plot * 1.08 +
  c(-0.10, 0.08, 0.18, -0.12)

species_levels <- unique(input$Species)
okabe_ito <- c("#0072B2", "#E69F00", "#009E73")
if (length(species_levels) > length(okabe_ito)) {
  extra_colors <- grDevices::hcl.colors(
    length(species_levels) - length(okabe_ito),
    palette = "Dark 3"
  )
  species_colors <- c(okabe_ito, extra_colors)
} else {
  species_colors <- okabe_ito[seq_along(species_levels)]
}
names(species_colors) <- species_levels
shape_values <- rep(c(16, 17, 15, 3, 7, 8), length.out = length(species_levels))
names(shape_values) <- species_levels

plot_data <- scores
plot_data$Species <- factor(plot_data$Species, levels = species_levels)
p <- ggplot2::ggplot(
  plot_data,
  ggplot2::aes(x = PC1, y = PC2, color = Species, shape = Species)
) +
  ggplot2::geom_hline(yintercept = 0, color = "#B8B8B8", linewidth = 0.35) +
  ggplot2::geom_vline(xintercept = 0, color = "#B8B8B8", linewidth = 0.35) +
  ggplot2::stat_ellipse(
    ggplot2::aes(group = Species),
    type = "norm",
    level = 0.95,
    linewidth = 0.7,
    alpha = 0.75,
    show.legend = FALSE
  ) +
  ggplot2::geom_point(size = 2.7, alpha = 0.82, stroke = 0.35) +
  ggplot2::geom_segment(
    data = loading_plot,
    ggplot2::aes(
      x = 0,
      y = 0,
      xend = PC1_plot,
      yend = PC2_plot
    ),
    inherit.aes = FALSE,
    color = "#3A3A3A",
    linewidth = 0.55,
    arrow = grid::arrow(length = grid::unit(0.16, "inches"))
  ) +
  ggplot2::geom_text(
    data = loading_plot,
    ggplot2::aes(
      x = label_x,
      y = label_y,
      label = variable
    ),
    inherit.aes = FALSE,
    color = "#252525",
    size = 3.4,
    fontface = "bold",
    check_overlap = TRUE
  ) +
  ggplot2::scale_color_manual(values = species_colors) +
  ggplot2::scale_shape_manual(values = shape_values) +
  ggplot2::coord_equal() +
  ggplot2::labs(
    title = "Iris measurements in principal-component space",
    subtitle = "Scaled PCA with 95% normal ellipses and variable loadings",
    x = sprintf("PC1 (%.2f%%)", explained_percent[[1L]]),
    y = sprintf("PC2 (%.2f%%)", explained_percent[[2L]]),
    color = "Species",
    shape = "Species",
    caption = "Arrows show scaled variable loadings; ellipse level = 95%."
  ) +
  ggplot2::theme_minimal(base_size = 12) +
  ggplot2::theme(
    panel.grid.minor = ggplot2::element_blank(),
    panel.grid.major = ggplot2::element_line(color = "#E7E7E7", linewidth = 0.35),
    plot.title = ggplot2::element_text(face = "bold", size = 17),
    plot.subtitle = ggplot2::element_text(color = "#555555"),
    legend.position = "right",
    plot.caption = ggplot2::element_text(color = "#666666", hjust = 0)
  )

ggplot2::ggsave(
  file.path(output_directory, "plot.png"),
  plot = p,
  width = 10,
  height = 7.2,
  units = "in",
  dpi = 300,
  bg = "white"
)
ggplot2::ggsave(
  file.path(output_directory, "plot.pdf"),
  plot = p,
  width = 10,
  height = 7.2,
  units = "in",
  device = grDevices::cairo_pdf,
  bg = "white"
)

html_escape <- function(value) {
  value <- enc2utf8(as.character(value))
  value <- gsub("&", "&amp;", value, fixed = TRUE)
  value <- gsub("<", "&lt;", value, fixed = TRUE)
  value <- gsub(">", "&gt;", value, fixed = TRUE)
  value <- gsub("\"", "&quot;", value, fixed = TRUE)
  gsub("'", "&#39;", value, fixed = TRUE)
}

numeric_table_rows <- function(data, label_column, numeric_columns, digits = 6L) {
  vapply(seq_len(nrow(data)), function(index) {
    values <- vapply(
      data[index, numeric_columns, drop = FALSE],
      function(value) formatC(
        value[[1L]],
        digits = digits,
        format = "f",
        decimal.mark = "."
      ),
      character(1)
    )
    paste0(
      "<tr><th scope=\"row\">",
      html_escape(data[[label_column]][[index]]),
      "</th><td>",
      paste(html_escape(values), collapse = "</td><td>"),
      "</td></tr>"
    )
  }, character(1))
}

variance_rows <- numeric_table_rows(
  variance,
  "component",
  c("eigenvalue", "explained_percent", "cumulative_percent")
)
loading_rows <- numeric_table_rows(
  loadings,
  "variable",
  paste0("PC", 1:4)
)
input_basename <- basename(input_file)
input_link <- ""
same_directory <- identical(
  normalizePath(dirname(input_file), mustWork = TRUE),
  normalizePath(output_directory, mustWork = TRUE)
)
if (same_directory) {
  input_link <- paste0(
    "<li><a href=\"",
    html_escape(input_basename),
    "\">Input CSV</a></li>"
  )
}

html <- c(
  "<!doctype html>",
  "<html lang=\"en\">",
  "<head>",
  "<meta charset=\"UTF-8\">",
  "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">",
  "<title>FigureForge Iris PCA report</title>",
  "<style>",
  ":root{color-scheme:light;--ink:#17202a;--muted:#59636e;--line:#dce3e8;--accent:#0072b2;--paper:#fff;--wash:#f3f7f9}",
  "*{box-sizing:border-box}body{margin:0;background:var(--wash);color:var(--ink);font:16px/1.55 system-ui,-apple-system,BlinkMacSystemFont,\"Segoe UI\",sans-serif}",
  "main{width:min(1120px,calc(100% - 2rem));margin:2rem auto;background:var(--paper);padding:clamp(1.1rem,3vw,3rem);border:1px solid var(--line);border-radius:14px;box-shadow:0 12px 34px rgba(24,43,58,.08)}",
  "h1,h2{line-height:1.2}h1{margin-top:0}h2{margin-top:2rem}p{max-width:78ch}.lede{font-size:1.08rem;color:var(--muted)}",
  "figure{margin:1.5rem 0}img{display:block;width:100%;height:auto;border:1px solid var(--line);border-radius:8px}figcaption{margin-top:.6rem;color:var(--muted)}",
  ".tables{display:grid;grid-template-columns:repeat(auto-fit,minmax(300px,1fr));gap:1.25rem;align-items:start}.table-wrap{overflow-x:auto}",
  "table{width:100%;border-collapse:collapse;font-size:.9rem}th,td{padding:.48rem .58rem;border-bottom:1px solid var(--line);text-align:right;white-space:nowrap}th:first-child,td:first-child{text-align:left}thead th{background:var(--wash)}",
  "a{color:var(--accent)}code{background:var(--wash);padding:.18rem .35rem;border-radius:4px;overflow-wrap:anywhere}",
  "@media(max-width:620px){main{width:100%;margin:0;border:0;border-radius:0;padding:1rem}body{background:var(--paper)}}",
  "</style>",
  "</head>",
  "<body><main>",
  "<h1>FigureForge Iris PCA report</h1>",
  paste0(
    "<p class=\"lede\"><strong>FigureForge request:</strong> Turn the Iris measurements into a clear PC1-PC2 biplot, ",
    "showing species structure, 95% group ellipses, and the variables that drive the projection.</p>"
  ),
  paste0(
    "<p><strong>Input:</strong> ",
    nrow(input),
    " rows × ",
    ncol(input),
    " columns from <code>",
    html_escape(input_basename),
    "</code>.</p>"
  ),
  paste0(
    "<p><strong>Method and adaptation:</strong> The four measurement columns were centered and scaled, then analyzed with ",
    "<code>stats::prcomp</code>. The referenced PCA case's visual grammar was adapted to this public dataset: species use both ",
    "color and shape, normal ellipses summarize groups, and scaled loading arrows explain direction without reusing private data or code.</p>"
  ),
  sprintf(
    "<p><strong>Result:</strong> PC1 explains %.6f%% and PC2 explains %.6f%% of scaled variance (%.6f%% cumulatively).</p>",
    explained_percent[[1L]],
    explained_percent[[2L]],
    sum(explained_percent[1:2])
  ),
  "<figure><img src=\"plot.png\" alt=\"PC1-PC2 biplot of Iris measurements by species with loading arrows\"><figcaption>Points encode Species by color and shape; outlines are 95% normal ellipses.</figcaption></figure>",
  "<div class=\"tables\">",
  "<section><h2>Variance summary</h2><div class=\"table-wrap\"><table><thead><tr><th>Component</th><th>Eigenvalue</th><th>Explained %</th><th>Cumulative %</th></tr></thead><tbody>",
  variance_rows,
  "</tbody></table></div></section>",
  "<section><h2>Loading summary</h2><div class=\"table-wrap\"><table><thead><tr><th>Variable</th><th>PC1</th><th>PC2</th><th>PC3</th><th>PC4</th></tr></thead><tbody>",
  loading_rows,
  "</tbody></table></div></section>",
  "</div>",
  "<h2>Files</h2><ul>",
  "<li><a href=\"plot.png\">PNG figure</a></li>",
  "<li><a href=\"plot.pdf\">PDF figure</a></li>",
  "<li><a href=\"pca-variance.csv\">PCA variance CSV</a></li>",
  "<li><a href=\"pca-scores.csv\">PCA scores CSV</a></li>",
  "<li><a href=\"pca-loadings.csv\">PCA loadings CSV</a></li>",
  input_link,
  if (same_directory) "<li><a href=\"plot.R\">R script</a></li>" else "",
  if (same_directory) "<li><a href=\"README.md\">README</a></li>" else "",
  "</ul>",
  "<h2>Reproduce</h2>",
  "<p>From this directory, run <code>Rscript plot.R iris.csv .</code>.</p>",
  "</main></body>",
  "</html>"
)
writeLines(
  html,
  file.path(output_directory, "index.html"),
  useBytes = TRUE
)

message("FigureForge Iris PCA outputs written to: ", output_directory)
