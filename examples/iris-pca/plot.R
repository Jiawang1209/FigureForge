#!/usr/bin/env Rscript

all_args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", all_args, value = TRUE)
if (length(file_arg) != 1L) {
  stop("Could not determine the plot.R script path.", call. = FALSE)
}
script_path <- normalizePath(
  sub("^--file=", "", file_arg[[1L]]),
  mustWork = TRUE
)

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2L) {
  stop(
    "Usage: Rscript plot.R <input-file> <output-directory>",
    call. = FALSE
  )
}

main <- function() {
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
components <- colnames(pca$rotation)
component_signs <- vapply(
  seq_along(components),
  function(index) {
    anchor <- which.max(abs(pca$rotation[, index]))
    if (pca$rotation[anchor, index] < 0) -1 else 1
  },
  numeric(1)
)
pca$rotation <- sweep(pca$rotation, 2L, component_signs, FUN = "*")
pca$x <- sweep(pca$x, 2L, component_signs, FUN = "*")
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

staging_directory <- tempfile(
  pattern = ".figureforge-iris-pca-stage-",
  tmpdir = output_directory
)
if (!dir.create(staging_directory, showWarnings = FALSE)) {
  abort("Could not create a temporary staging directory for generated outputs.")
}
on.exit({
  if (dir.exists(staging_directory)) {
    unlink(staging_directory, recursive = TRUE, force = TRUE)
  }
}, add = TRUE)

staged_path <- function(filename) {
  file.path(staging_directory, filename)
}

utils::write.csv(
  variance,
  staged_path("pca-variance.csv"),
  row.names = FALSE
)
utils::write.csv(
  scores,
  staged_path("pca-scores.csv"),
  row.names = FALSE
)
utils::write.csv(
  loadings,
  staged_path("pca-loadings.csv"),
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
loading_plot$label_x <- loading_plot$PC1_plot * 1.15
loading_plot$label_y <- loading_plot$PC2_plot * 1.15 +
  c(-0.12, 0.12, 0.18, -0.16)
loading_plot$label_hjust <- ifelse(
  loading_plot$PC1_plot >= 0,
  -0.08,
  1.08
)
loading_plot$label_vjust <- c(1.10, -0.10, -0.10, 1.10)

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

covariance_ellipse <- function(group_data, level = 0.95, points = 181L) {
  coordinates <- as.matrix(group_data[, c("PC1", "PC2"), drop = FALSE])
  center <- colMeans(coordinates)
  covariance <- stats::cov(coordinates)
  decomposition <- eigen(covariance, symmetric = TRUE)
  largest_eigenvalue <- max(c(decomposition$values, 0))
  eigenvalue_floor <- max(
    largest_eigenvalue * 1e-10,
    .Machine$double.eps
  )
  stable_eigenvalues <- pmax(decomposition$values, eigenvalue_floor)
  angles <- seq(0, 2 * pi, length.out = points)
  unit_circle <- rbind(cos(angles), sin(angles))
  transform <- decomposition$vectors %*%
    diag(sqrt(stable_eigenvalues), nrow = 2L)
  ellipse <- sqrt(stats::qchisq(level, df = 2L)) *
    transform %*% unit_circle
  ellipse <- sweep(ellipse, 1L, center, FUN = "+")
  data.frame(
    PC1 = ellipse[1L, ],
    PC2 = ellipse[2L, ],
    Species = factor(
      rep(as.character(group_data$Species[[1L]]), ncol(ellipse)),
      levels = species_levels
    ),
    check.names = FALSE
  )
}

ellipse_data <- do.call(
  rbind,
  lapply(
    split(plot_data, plot_data$Species, drop = TRUE),
    covariance_ellipse
  )
)

p <- ggplot2::ggplot(
  plot_data,
  ggplot2::aes(x = PC1, y = PC2, color = Species, shape = Species)
) +
  ggplot2::geom_hline(yintercept = 0, color = "#B8B8B8", linewidth = 0.35) +
  ggplot2::geom_vline(xintercept = 0, color = "#B8B8B8", linewidth = 0.35) +
  ggplot2::geom_path(
    data = ellipse_data,
    ggplot2::aes(x = PC1, y = PC2, color = Species, group = Species),
    inherit.aes = FALSE,
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
      label = variable,
      hjust = label_hjust,
      vjust = label_vjust
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
  staged_path("plot.png"),
  plot = p,
  width = 10,
  height = 7.2,
  units = "in",
  dpi = 300,
  bg = "white"
)
ggplot2::ggsave(
  staged_path("plot.pdf"),
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
  components
)
input_basename <- basename(input_file)

relative_path <- function(target, from_directory) {
  target <- normalizePath(target, winslash = "/", mustWork = TRUE)
  from_directory <- normalizePath(
    from_directory,
    winslash = "/",
    mustWork = TRUE
  )
  target_volume <- sub("^(([A-Za-z]:)?/).*$", "\\1", target)
  from_volume <- sub("^(([A-Za-z]:)?/).*$", "\\1", from_directory)
  if (!identical(tolower(target_volume), tolower(from_volume))) {
    abort("Script, input, and output must be on the same filesystem volume.")
  }
  target_parts <- strsplit(
    sub("^([A-Za-z]:)?/", "", target),
    "/",
    fixed = FALSE
  )[[1L]]
  from_parts <- strsplit(
    sub("^([A-Za-z]:)?/", "", from_directory),
    "/",
    fixed = FALSE
  )[[1L]]
  common_count <- 0L
  limit <- min(length(target_parts), length(from_parts))
  while (
    common_count < limit &&
      identical(
        target_parts[[common_count + 1L]],
        from_parts[[common_count + 1L]]
      )
  ) {
    common_count <- common_count + 1L
  }
  upward <- if (common_count < length(from_parts)) {
    rep("..", length(from_parts) - common_count)
  } else {
    character()
  }
  downward <- if (common_count < length(target_parts)) {
    target_parts[seq.int(common_count + 1L, length(target_parts))]
  } else {
    character()
  }
  result <- paste(c(upward, downward), collapse = "/")
  if (nzchar(result)) result else "."
}

url_encode_relative_path <- function(path) {
  parts <- strsplit(enc2utf8(path), "/", fixed = TRUE)[[1L]]
  encoded_parts <- vapply(
    parts,
    function(part) {
      if (part %in% c("", ".", "..")) {
        part
      } else {
        utils::URLencode(part, reserved = TRUE)
      }
    },
    character(1)
  )
  paste(encoded_parts, collapse = "/")
}

output_path <- normalizePath(output_directory, winslash = "/", mustWork = TRUE)
script_relative <- relative_path(script_path, output_path)
input_relative <- relative_path(input_file, output_path)
readme_path <- file.path(dirname(script_path), "README.md")

file_link <- function(target, label) {
  if (!file.exists(target) || isTRUE(file.info(target)$isdir)) {
    return("")
  }
  paste0(
    "<li><a href=\"",
    html_escape(url_encode_relative_path(relative_path(target, output_path))),
    "\">",
    html_escape(label),
    "</a></li>"
  )
}

rerun_command <- paste(
  "Rscript",
  shQuote(script_relative, type = "sh"),
  shQuote(input_relative, type = "sh"),
  "."
)
loading_headers <- paste0(
  "<th>",
  html_escape(components),
  "</th>",
  collapse = ""
)

html <- c(
  "<!doctype html>",
  "<html lang=\"en\">",
  "<head>",
  "<meta charset=\"UTF-8\">",
  "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">",
  "<link rel=\"icon\" href=\"data:,\">",
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
    "<code>stats::prcomp</code>. Species use both color and shape, normal ellipses summarize groups, and scaled loading arrows explain direction.</p>"
  ),
  paste0(
    "<section><h2>Case-grounded provenance</h2>",
    "<p>At the generation stage, FigureForge read the primary <code>20230925_PCA</code> case evidence: ",
    "<code>case.md</code>, <code>plot.R</code>, and the verified <code>qa.md</code>. ",
    "The generation trace passed strict validation against those evidence files and this generated script. ",
    "The public rerun is standalone: it reads only the supplied Iris CSV and does not access the private case.</p>",
    "<p>The user-visible README and HTML do not display private paths, private source code, private data, or hashes. ",
    "The hidden trace retains SHA-256 hashes for provenance auditing.</p>",
    "<h3>Schema mapping</h3><ul>",
    "<li>The case's feature-by-sample value matrix maps to row-wise Iris measurement columns.</li>",
    "<li>The case's sample group maps to <code>Species</code>.</li>",
    "<li>The case's <code>Dim.1</code>/<code>Dim.2</code> roles map to <code>PC1</code>/<code>PC2</code>.</li>",
    "</ul>",
    "<h3>Adopted patterns</h3><ul>",
    "<li>A PC1-PC2 ordination composition with variance explained in both axis labels.</li>",
    "<li>Group encoding through points, color, and shape.</li>",
    "<li>Group-boundary ellipses layered with zero reference axes.</li>",
    "</ul>",
    "<h3>Departures</h3><ul>",
    "<li>Feature-by-sample input became row-wise Iris observations.</li>",
    "<li>Four panels became a single biplot.</li>",
    "<li><code>FactoMineR</code> became <code>stats::prcomp</code>.</li>",
    "<li>Fixed limits became data-aware limits.</li>",
    "<li>Loading arrows were added as an explanatory extension.</li>",
    "</ul></section>"
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
  paste0(
    "<section><h2>Loading summary</h2><div class=\"table-wrap\"><table><thead><tr><th>Variable</th>",
    loading_headers,
    "</tr></thead><tbody>"
  ),
  loading_rows,
  "</tbody></table></div></section>",
  "</div>",
  "<h2>Files</h2><ul>",
  "<li><a href=\"plot.png\">PNG figure</a></li>",
  "<li><a href=\"plot.pdf\">PDF figure</a></li>",
  "<li><a href=\"pca-variance.csv\">PCA variance CSV</a></li>",
  "<li><a href=\"pca-scores.csv\">PCA scores CSV</a></li>",
  "<li><a href=\"pca-loadings.csv\">PCA loadings CSV</a></li>",
  file_link(input_file, "Input CSV"),
  file_link(script_path, "R script"),
  file_link(readme_path, "README"),
  "</ul>",
  "<h2>Reproduce</h2>",
  paste0(
    "<p>From this directory, run <code>",
    html_escape(rerun_command),
    "</code>.</p>"
  ),
  "</main></body>",
  "</html>"
)
writeLines(
  html,
  staged_path("index.html"),
  useBytes = TRUE
)

staged_outputs <- file.path(staging_directory, output_filenames)
if (
  !all(file.exists(staged_outputs)) ||
    !all(file.info(staged_outputs)$size > 0L)
) {
  abort("Generation failed because one or more staged outputs are missing or empty.")
}

is_symbolic_link <- function(path) {
  target <- Sys.readlink(path)
  length(target) == 1L && !is.na(target) && nzchar(target)
}

destination_paths <- stats::setNames(
  file.path(output_directory, output_filenames),
  output_filenames
)
if (file.access(output_directory, mode = 2L) != 0L) {
  abort("Output directory is not writable; no outputs were published.")
}
for (filename in output_filenames) {
  destination <- destination_paths[[filename]]
  destination_exists <- file.exists(destination) ||
    is_symbolic_link(destination)
  if (destination_exists && isTRUE(file.info(destination)$isdir)) {
    abort(paste0(
      "Cannot publish ",
      filename,
      " because its destination is a directory; no outputs were published."
    ))
  }
  resolved_destination <- normalizePath(
    destination,
    winslash = "/",
    mustWork = FALSE
  )
  if (identical(resolved_destination, resolved_input)) {
    abort(paste0(
      "Cannot publish ",
      filename,
      " because its destination resolves to the input file."
    ))
  }
}

backup_directory <- tempfile(
  pattern = ".figureforge-iris-pca-backup-",
  tmpdir = output_directory
)
if (!dir.create(backup_directory, showWarnings = FALSE)) {
  abort("Could not create a same-filesystem backup area; no outputs were published.")
}
backup_recovery_path <- normalizePath(
  backup_directory,
  winslash = "/",
  mustWork = TRUE
)

backed_up <- character()
published <- character()
publication_succeeded <- FALSE
rollback_attempted <- FALSE
rollback_complete <- FALSE

rollback_publication <- function() {
  rollback_errors <- character()
  for (filename in rev(published)) {
    destination <- destination_paths[[filename]]
    if (file.exists(destination) || is_symbolic_link(destination)) {
      if (
        isTRUE(file.info(destination)$isdir) ||
          unlink(destination, recursive = FALSE, force = TRUE) != 0L
      ) {
        rollback_errors <- c(
          rollback_errors,
          paste0("could not remove newly published ", filename)
        )
      }
    }
  }
  for (filename in backed_up) {
    backup_file <- file.path(backup_directory, filename)
    destination <- destination_paths[[filename]]
    backup_available <- file.exists(backup_file) ||
      is_symbolic_link(backup_file)
    restore_failed <- TRUE
    if (backup_available) {
      restore_failed <-
        file.exists(destination) ||
          is_symbolic_link(destination) ||
          !isTRUE(suppressWarnings(file.rename(backup_file, destination)))
    }
    restore_confirmed <- (
      file.exists(destination) || is_symbolic_link(destination)
    ) && !(
      file.exists(backup_file) || is_symbolic_link(backup_file)
    )
    if (restore_failed || !restore_confirmed) {
      rollback_errors <- c(
        rollback_errors,
        paste0("could not confirm restoration of original ", filename)
      )
    }
  }
  rollback_errors
}

on.exit({
  if (!publication_succeeded && !rollback_attempted) {
    exit_rollback_errors <- rollback_publication()
    rollback_attempted <- TRUE
    rollback_complete <- length(exit_rollback_errors) == 0L
  }
  backup_safe_to_delete <- publication_succeeded || rollback_complete
  if (backup_safe_to_delete && dir.exists(backup_directory)) {
    unlink(backup_directory, recursive = TRUE, force = TRUE)
  } else if (dir.exists(backup_directory)) {
    warning(
      paste0(
        "Rollback was incomplete. Backup preserved at ",
        backup_recovery_path,
        ". Move the remaining backup files into ",
        output_path,
        " before rerunning plot.R."
      ),
      call. = FALSE
    )
  }
}, add = TRUE)

publication_error <- tryCatch(
  {
    for (filename in output_filenames) {
      destination <- destination_paths[[filename]]
      if (file.exists(destination) || is_symbolic_link(destination)) {
        backup_file <- file.path(backup_directory, filename)
        if (!isTRUE(suppressWarnings(file.rename(destination, backup_file)))) {
          stop(
            paste0("Could not back up existing output: ", filename),
            call. = FALSE
          )
        }
        backed_up <- c(backed_up, filename)
      }
    }

    for (filename in output_filenames) {
      staged_file <- staged_path(filename)
      destination <- destination_paths[[filename]]
      if (!isTRUE(suppressWarnings(file.rename(staged_file, destination)))) {
        stop(
          paste0("Could not atomically publish generated output: ", filename),
          call. = FALSE
        )
      }
      published <- c(published, filename)
    }
    NULL
  },
  error = function(error) error
)

if (inherits(publication_error, "error")) {
  rollback_errors <- rollback_publication()
  rollback_attempted <- TRUE
  rollback_complete <- length(rollback_errors) == 0L
  if (length(rollback_errors) == 0L) {
    abort(paste0(
      "Output publication failed; every original output was restored. ",
      conditionMessage(publication_error)
    ))
  }
  abort(paste0(
    "Output publication failed and rollback was incomplete: ",
    paste(rollback_errors, collapse = "; "),
    ". Original error: ",
    conditionMessage(publication_error),
    ". Backup preserved at ",
    backup_recovery_path,
    ". Recovery: move the remaining backup files into ",
    output_path,
    " before rerunning plot.R."
  ))
}

publication_succeeded <- TRUE
backup_cleanup_status <- unlink(
  backup_directory,
  recursive = TRUE,
  force = TRUE
)
if (backup_cleanup_status != 0L || dir.exists(backup_directory)) {
  abort("Outputs were published, but the temporary backup area could not be removed.")
}

message("FigureForge Iris PCA outputs written to: ", output_directory)
}

main()
