#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
script_path <- if (length(file_arg) > 0L) {
  normalizePath(sub("^--file=", "", file_arg[[1L]]), mustWork = TRUE)
} else {
  normalizePath(
    "tests/figureforge/test_iris_pca_demo.R",
    mustWork = TRUE
  )
}
repo_root <- normalizePath(
  file.path(dirname(script_path), "..", ".."),
  mustWork = TRUE
)
demo_root <- file.path(repo_root, "examples", "iris-pca")

assert_true <- function(condition, message) {
  if (!isTRUE(condition)) {
    stop(message, call. = FALSE)
  }
}

read_text <- function(path) {
  assert_true(file.exists(path), paste("Missing file:", path))
  paste(
    readLines(path, warn = FALSE, encoding = "UTF-8"),
    collapse = "\n"
  )
}

contains_all <- function(document, terms) {
  all(vapply(terms, grepl, logical(1), x = document, fixed = TRUE))
}

assert_numeric_equal <- function(actual, expected, label, tolerance = 1e-7) {
  assert_true(
    isTRUE(all.equal(
      unname(as.matrix(actual)),
      unname(as.matrix(expected)),
      tolerance = tolerance,
      check.attributes = FALSE
    )),
    paste(label, "does not match the scaled PCA computed from iris.csv")
  )
}

decoded_png_dimensions <- function(path) {
  assert_true(
    requireNamespace("png", quietly = TRUE),
    "The available R png package is required to decode plot.png"
  )
  decoded <- tryCatch(
    png::readPNG(path, native = FALSE),
    error = function(error) error
  )
  assert_true(
    !inherits(decoded, "error"),
    "plot.png must decode successfully with the R png package"
  )
  dimensions <- dim(decoded)
  assert_true(
    length(dimensions) >= 2L,
    "Decoded plot.png must have height and width dimensions"
  )
  c(
    width = dimensions[[2L]],
    height = dimensions[[1L]]
  )
}

contains_absolute_local_path <- function(document) {
  attribute_matches <- regmatches(
    document,
    gregexpr(
      "(?:href|src)[[:space:]]*=[[:space:]]*[\"'][^\"']+[\"']",
      document,
      ignore.case = TRUE,
      perl = TRUE
    )
  )[[1L]]
  attribute_values <- if (
    length(attribute_matches) == 1L &&
      identical(attribute_matches, "")
  ) {
    character()
  } else {
    sub(
      "^[^=]+=[[:space:]]*[\"']([^\"']+)[\"']$",
      "\\1",
      attribute_matches,
      perl = TRUE
    )
  }
  unsafe_attribute <- any(grepl(
    "^(?:file://|/|[A-Za-z]:[\\\\/]|\\\\\\\\)",
    attribute_values,
    ignore.case = TRUE,
    perl = TRUE
  ))

  visible_text <- gsub("<[^>]+>", " ", document, perl = TRUE)
  unsafe_text_patterns <- c(
    "file://",
    "(^|[[:space:]\"'(=])/[A-Za-z0-9._~-]+",
    "(^|[[:space:]\"'(=])[A-Za-z]:[\\\\/]",
    "(^|[[:space:]\"'(=])\\\\\\\\[A-Za-z0-9._~-]+[\\\\/]"
  )
  unsafe_attribute || any(vapply(
    unsafe_text_patterns,
    grepl,
    logical(1),
    x = visible_text,
    ignore.case = TRUE,
    perl = TRUE
  ))
}

unsafe_path_examples <- c(
  "<code>/opt/figureforge/demo</code>",
  "<a href='/var/tmp/plot.png'>plot</a>",
  "<code>C:\\Users\\analyst\\plot.png</code>",
  "<a href='\\\\server\\share\\plot.png'>plot</a>",
  "<a href='file:///tmp/plot.png'>plot</a>"
)
assert_true(
  all(vapply(
    unsafe_path_examples,
    contains_absolute_local_path,
    logical(1)
  )),
  "Absolute-path detection must cover Unix, Windows, UNC, and file paths"
)
safe_path_examples <- c(
  "<a href='plot.png'>plot</a>",
  "<a href='./pca-scores.csv'>scores</a>",
  "<a href='https://example.org/results/plot.png'>external result</a>"
)
assert_true(
  !any(vapply(
    safe_path_examples,
    contains_absolute_local_path,
    logical(1)
  )),
  "Absolute-path detection must allow relative links and normal web URLs"
)

required_files <- c(
  "iris.csv",
  "plot.R",
  "plot.png",
  "plot.pdf",
  "pca-variance.csv",
  "pca-scores.csv",
  "pca-loadings.csv",
  "index.html",
  "README.md"
)
missing_files <- required_files[
  !file.exists(file.path(demo_root, required_files))
]
assert_true(
  length(missing_files) == 0L,
  paste(
    "Iris PCA demo is missing required files:",
    paste(missing_files, collapse = ", ")
  )
)
assert_true(
  all(file.info(file.path(demo_root, required_files))$size > 0L),
  "Every Iris PCA demo artifact must be non-empty"
)

iris_data <- read.csv(
  file.path(demo_root, "iris.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
measure_columns <- c(
  "Sepal.Length",
  "Sepal.Width",
  "Petal.Length",
  "Petal.Width"
)
assert_true(nrow(iris_data) == 150L, "iris.csv must contain 150 rows")
assert_true(
  identical(names(iris_data), c(measure_columns, "Species")),
  "iris.csv must contain the four Iris measures followed by Species"
)
assert_true(
  all(vapply(iris_data[measure_columns], is.numeric, logical(1))),
  "The four Iris measure columns must be numeric"
)
assert_true(
  setequal(
    unique(iris_data$Species),
    c("setosa", "versicolor", "virginica")
  ),
  "iris.csv must contain the three canonical Iris species"
)

plot_script_path <- file.path(demo_root, "plot.R")
plot_script <- read_text(plot_script_path)
assert_true(
  grepl("commandArgs\\s*\\(\\s*trailingOnly\\s*=\\s*TRUE\\s*\\)", plot_script),
  "plot.R must read its two positional arguments"
)
assert_true(
  grepl("length\\s*\\([^)]*args[^)]*\\)\\s*(!=|==)\\s*2", plot_script),
  "plot.R must enforce exactly two positional arguments"
)
assert_true(
  grepl("prcomp\\s*\\(", plot_script) &&
    grepl("scale\\s*\\.\\s*=\\s*TRUE", plot_script),
  "plot.R must perform PCA with prcomp(..., scale. = TRUE)"
)
assert_true(
  contains_all(plot_script, c(measure_columns, "Species")),
  "plot.R must require all four Iris measures and Species"
)
assert_true(
  contains_all(
    plot_script,
    c(
      "plot.png",
      "plot.pdf",
      "pca-variance.csv",
      "pca-scores.csv",
      "pca-loadings.csv"
    )
  ),
  "plot.R must name every required output explicitly"
)
assert_true(
  !grepl(
    "skills/figureforge/cases|/Users/|/home/|/private/",
    plot_script,
    ignore.case = TRUE,
    perl = TRUE
  ),
  "plot.R must not depend on a private case or machine-local path"
)

invalid_invocations <- list(
  zero_arguments = character(),
  one_argument = shQuote(file.path(demo_root, "iris.csv")),
  three_arguments = c(
    shQuote(file.path(demo_root, "iris.csv")),
    shQuote(tempfile("figureforge-iris-pca-invalid-output-")),
    "unexpected-third-argument"
  )
)
for (invocation_name in names(invalid_invocations)) {
  invalid_log <- tempfile(
    paste0("figureforge-iris-pca-", invocation_name, "-"),
    fileext = ".log"
  )
  invalid_status <- system2(
    file.path(R.home("bin"), "Rscript"),
    c(
      shQuote(plot_script_path),
      invalid_invocations[[invocation_name]]
    ),
    stdout = invalid_log,
    stderr = invalid_log
  )
  assert_true(
    length(invalid_status) == 1L &&
      !is.na(as.integer(invalid_status)) &&
      as.integer(invalid_status) != 0L,
    paste(
      "plot.R must reject",
      gsub("_", " ", invocation_name, fixed = TRUE)
    )
  )
}

rerun_root <- tempfile("figureforge-iris-pca-")
dir.create(rerun_root, recursive = TRUE)
rerun_log <- tempfile("figureforge-iris-pca-", fileext = ".log")
rerun_status <- system2(
  file.path(R.home("bin"), "Rscript"),
  c(
    shQuote(plot_script_path),
    shQuote(file.path(demo_root, "iris.csv")),
    shQuote(rerun_root)
  ),
  stdout = rerun_log,
  stderr = rerun_log
)
if (!identical(as.integer(rerun_status), 0L)) {
  stop(
    paste(readLines(rerun_log, warn = FALSE), collapse = "\n"),
    call. = FALSE
  )
}
generated_outputs <- c(
  "plot.png",
  "plot.pdf",
  "pca-variance.csv",
  "pca-scores.csv",
  "pca-loadings.csv"
)
assert_true(
  all(file.exists(file.path(rerun_root, generated_outputs))),
  "The two-argument plot.R contract must generate every named output"
)

variance <- read.csv(
  file.path(demo_root, "pca-variance.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
scores <- read.csv(
  file.path(demo_root, "pca-scores.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
loadings <- read.csv(
  file.path(demo_root, "pca-loadings.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
assert_true(
  identical(
    names(variance),
    c("component", "variance_percent", "cumulative_percent")
  ),
  "pca-variance.csv has an unexpected schema"
)
assert_true(
  identical(names(scores), c("PC1", "PC2", "Species")),
  "pca-scores.csv has an unexpected schema"
)
assert_true(
  identical(names(loadings), c("variable", "PC1", "PC2")),
  "pca-loadings.csv has an unexpected schema"
)

pca <- prcomp(
  iris_data[measure_columns],
  center = TRUE,
  scale. = TRUE
)
variance_percent <- 100 * pca$sdev^2 / sum(pca$sdev^2)
expected_variance <- data.frame(
  component = paste0("PC", seq_along(variance_percent)),
  variance_percent = variance_percent,
  cumulative_percent = cumsum(variance_percent),
  check.names = FALSE
)
expected_scores <- data.frame(
  PC1 = pca$x[, "PC1"],
  PC2 = pca$x[, "PC2"],
  Species = iris_data$Species,
  check.names = FALSE
)
expected_loadings <- data.frame(
  variable = measure_columns,
  PC1 = pca$rotation[measure_columns, "PC1"],
  PC2 = pca$rotation[measure_columns, "PC2"],
  check.names = FALSE
)
assert_true(
  identical(variance$component, expected_variance$component),
  "pca-variance.csv must identify PC1 through PC4"
)
assert_numeric_equal(
  variance[c("variance_percent", "cumulative_percent")],
  expected_variance[c("variance_percent", "cumulative_percent")],
  "pca-variance.csv"
)
assert_true(
  identical(scores$Species, expected_scores$Species),
  "pca-scores.csv Species values must preserve iris.csv row order"
)
assert_numeric_equal(
  scores[c("PC1", "PC2")],
  expected_scores[c("PC1", "PC2")],
  "pca-scores.csv"
)
assert_true(
  identical(loadings$variable, expected_loadings$variable),
  "pca-loadings.csv variables must preserve measure-column order"
)
assert_numeric_equal(
  loadings[c("PC1", "PC2")],
  expected_loadings[c("PC1", "PC2")],
  "pca-loadings.csv"
)

for (filename in c(
  "pca-variance.csv",
  "pca-scores.csv",
  "pca-loadings.csv"
)) {
  committed <- read.csv(
    file.path(demo_root, filename),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  rerun <- read.csv(
    file.path(rerun_root, filename),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  assert_true(
    isTRUE(all.equal(committed, rerun, tolerance = 1e-7)),
    paste(filename, "must be reproducible through plot.R")
  )
}

png_size <- decoded_png_dimensions(file.path(demo_root, "plot.png"))
assert_true(
  png_size[["width"]] > 0 && png_size[["height"]] > 0,
  "Decoded plot.png dimensions must be positive"
)

pdfinfo <- Sys.which("pdfinfo")
pdftoppm <- Sys.which("pdftoppm")
assert_true(nzchar(pdfinfo), "pdfinfo is required to validate plot.pdf")
assert_true(nzchar(pdftoppm), "pdftoppm is required to render plot.pdf")
pdf_info <- system2(
  pdfinfo,
  shQuote(file.path(demo_root, "plot.pdf")),
  stdout = TRUE,
  stderr = TRUE
)
assert_true(
  is.null(attr(pdf_info, "status")),
  "plot.pdf must be readable by pdfinfo"
)
page_line <- grep("^Pages:[[:space:]]+", pdf_info, value = TRUE)
page_count <- if (length(page_line) == 1L) {
  as.integer(sub("^Pages:[[:space:]]+", "", page_line))
} else {
  NA_integer_
}
assert_true(
  !is.na(page_count) && page_count >= 1L,
  "plot.pdf must contain at least one page"
)
render_prefix <- tempfile("figureforge-iris-pca-pdf-")
render_log <- tempfile("figureforge-iris-pca-pdf-", fileext = ".log")
render_status <- system2(
  pdftoppm,
  c(
    "-f", "1",
    "-l", "1",
    "-singlefile",
    "-png",
    shQuote(file.path(demo_root, "plot.pdf")),
    shQuote(render_prefix)
  ),
  stdout = render_log,
  stderr = render_log
)
assert_true(
  identical(as.integer(render_status), 0L) &&
    file.exists(paste0(render_prefix, ".png")) &&
    file.info(paste0(render_prefix, ".png"))$size > 0L,
  "plot.pdf must render successfully as a one-page image"
)

html <- read_text(file.path(demo_root, "index.html"))
assert_true(
  grepl(
    "<meta[^>]+name=[\"']viewport[\"'][^>]+content=[\"'][^\"']*width=device-width",
    html,
    ignore.case = TRUE,
    perl = TRUE
  ),
  "index.html must declare a responsive viewport"
)
assert_true(
  grepl("FigureForge", html, ignore.case = TRUE, fixed = TRUE) &&
    grepl("request", html, ignore.case = TRUE, fixed = TRUE) &&
    grepl("Iris", html, ignore.case = TRUE, fixed = TRUE) &&
    grepl("PCA", html, ignore.case = TRUE, fixed = TRUE),
  "index.html must identify FigureForge and state the Iris PCA request"
)
assert_true(
  contains_all(html, c("PC1", "PC2")),
  "index.html must explain the PC1-PC2 result"
)
assert_true(
  grepl(
    "<img[^>]+src=[\"'](?:\\./)?plot\\.png[\"']",
    html,
    ignore.case = TRUE,
    perl = TRUE
  ),
  "index.html must display plot.png"
)
assert_true(
  contains_all(html, c(required_files[required_files != "index.html"])),
  "index.html must name the input, script, figures, CSV results, and README"
)
linked_results <- setdiff(
  required_files,
  c("index.html", "plot.png")
)
for (filename in linked_results) {
  relative_hrefs <- c(
    paste0("href=\"", filename, "\""),
    paste0("href='", filename, "'"),
    paste0("href=\"./", filename, "\""),
    paste0("href='./", filename, "'")
  )
  assert_true(
    any(vapply(
      relative_hrefs,
      grepl,
      logical(1),
      x = html,
      ignore.case = TRUE,
      fixed = TRUE
    )),
    paste("index.html must link", filename)
  )
}
assert_true(
  grepl(
    "Rscript[[:space:]]+plot\\.R[[:space:]]+iris\\.csv[[:space:]]+\\.",
    html,
    perl = TRUE
  ),
  "index.html must show the portable rerun command"
)
assert_true(
  !contains_absolute_local_path(html),
  "index.html must not contain an absolute local path"
)

english <- read_text(file.path(repo_root, "README.md"))
chinese <- read_text(file.path(repo_root, "README.zh.md"))
for (document in list(english, chinese)) {
  assert_true(
    contains_all(
      document,
      c(
        "git clone",
        "mkdir -p .agents/skills",
        "cp -R skills/figureforge",
        ".agents/skills/figureforge",
        "examples/iris-pca",
        "plot.R",
        "plot.png",
        "plot.pdf"
      )
    ),
    "Both root READMEs must cover installation, the Iris demo, and default outputs"
  )
}
assert_true(
  grepl("Rscript examples/iris-pca/plot\\.R", english, perl = TRUE) &&
    grepl("Rscript examples/iris-pca/plot\\.R", chinese, perl = TRUE),
  "Both root READMEs must include the Iris PCA rerun command"
)

message("Iris PCA demo contract tests: PASS")
