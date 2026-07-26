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

sha256_file <- function(path) {
  shasum <- Sys.which("shasum")
  assert_true(nzchar(shasum), "shasum is required for input preservation tests")
  output <- system2(
    shasum,
    c("-a", "256", shQuote(path)),
    stdout = TRUE,
    stderr = TRUE
  )
  assert_true(
    is.null(attr(output, "status")) && length(output) == 1L,
    paste("Could not calculate SHA-256 for", path)
  )
  sub("[[:space:]].*$", "", output[[1L]])
}

orient_pca <- function(model) {
  component_signs <- vapply(
    seq_len(ncol(model$rotation)),
    function(index) {
      anchor <- which.max(abs(model$rotation[, index]))
      if (model$rotation[anchor, index] < 0) -1 else 1
    },
    numeric(1)
  )
  model$rotation <- sweep(model$rotation, 2L, component_signs, FUN = "*")
  model$x <- sweep(model$x, 2L, component_signs, FUN = "*")
  model
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

contains_remote_resource_dependency <- function(document) {
  if (grepl("<script\\b", document, ignore.case = TRUE, perl = TRUE)) {
    return(TRUE)
  }
  resource_tags <- regmatches(
    document,
    gregexpr(
      "(?is)<(?:link|img|source|iframe|video|audio|object|embed|track)\\b[^>]*>",
      document,
      perl = TRUE
    )
  )[[1L]]
  remote_url <- "^(?:(?:https?:)?//)"
  for (tag in resource_tags) {
    tag_name <- tolower(sub(
      "^<[[:space:]]*([A-Za-z]+)[\\s\\S]*$",
      "\\1",
      tag,
      perl = TRUE
    ))
    relevant_attributes <- switch(
      tag_name,
      link = "href",
      img = c("src", "srcset"),
      source = c("src", "srcset"),
      iframe = "src",
      video = c("src", "poster"),
      audio = c("src", "poster"),
      object = "data",
      embed = "src",
      track = "src",
      character()
    )
    if (length(relevant_attributes) == 0L) {
      next
    }
    attribute_pattern <- paste0(
      "(?:",
      paste(relevant_attributes, collapse = "|"),
      ")[[:space:]]*=[[:space:]]*",
      "(?:\"[^\"]*\"|'[^']*'|[^[:space:]>]+)"
    )
    attribute_matches <- regmatches(
      tag,
      gregexpr(
        attribute_pattern,
        tag,
        ignore.case = TRUE,
        perl = TRUE
      )
    )[[1L]]
    for (attribute in attribute_matches) {
      attribute_name <- tolower(trimws(sub("=.*$", "", attribute)))
      value <- trimws(sub("^[^=]+=", "", attribute))
      value <- sub(
        "^[\"'](.*)[\"']$",
        "\\1",
        value,
        perl = TRUE
      )
      candidate_urls <- if (identical(attribute_name, "srcset")) {
        vapply(
          strsplit(value, ",", fixed = TRUE)[[1L]],
          function(candidate) {
            sub("[[:space:]].*$", "", trimws(candidate))
          },
          character(1)
        )
      } else {
        trimws(value)
      }
      if (any(grepl(
        remote_url,
        candidate_urls,
        ignore.case = TRUE,
        perl = TRUE
      ))) {
        return(TRUE)
      }
    }
  }

  remote_css_url <- grepl(
    "url\\([[:space:]]*[\"']?[[:space:]]*(?:(?:https?:)?//)",
    document,
    ignore.case = TRUE,
    perl = TRUE
  )
  remote_css_import <- grepl(
    "@import[[:space:]]+(?:url\\([[:space:]]*)?[\"']?[[:space:]]*(?:(?:https?:)?//)",
    document,
    ignore.case = TRUE,
    perl = TRUE
  )
  remote_css_url || remote_css_import
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

remote_resource_examples <- c(
  "<script src='https://cdn.example.org/framework.js'></script>",
  "<script src='./assets/app.js'></script>",
  "<script>document.body.classList.add('ready')</script>",
  "<link rel='stylesheet' href='//cdn.example.org/theme.css'>",
  "<img src=https://cdn.example.org/plot.png>",
  paste0(
    "<img src='plot.png' ",
    "srcset='plot.png 1x, https://cdn.example.org/plot@2x.png 2x'>"
  ),
  "<source src='plot.png' srcset='plot.png 1x, //cdn.example.org/plot@2x.png 2x'>",
  "<object data='https://cdn.example.org/report.svg'></object>",
  "<embed src='//cdn.example.org/widget.svg'>",
  "<track src='https://cdn.example.org/captions.vtt'>",
  "<style>.hero { background: url(https://cdn.example.org/bg.png); }</style>",
  "<style>@import '//cdn.example.org/fonts.css';</style>"
)
assert_true(
  all(vapply(
    remote_resource_examples,
    contains_remote_resource_dependency,
    logical(1)
  )),
  "Offline portability detection must reject remote CDN resources"
)
local_resource_examples <- c(
  paste0(
    "<link rel='stylesheet' href='styles.css'>",
    "<img src='plot.png'>",
    "<source src='plot.png' srcset='plot.png 1x, ./plot@2x.png 2x'>",
    "<object data='diagram.svg'></object>",
    "<embed src='preview.svg'>",
    "<track src='captions.vtt'>",
    "<video src='movie.mp4' poster='poster.png'></video>",
    "<audio src='data:audio/ogg;base64,T2dn'></audio>"
  ),
  "<a href='https://example.org/project'>External project page</a>"
)
assert_true(
  !any(vapply(
    local_resource_examples,
    contains_remote_resource_dependency,
    logical(1)
  )),
  "Offline portability detection must allow relative/data resources and external navigation anchors"
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
      "pca-loadings.csv",
      "index.html"
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

assert_invalid_input <- function(data, fixture_name, expected_patterns) {
  input_path <- tempfile(
    paste0("figureforge-iris-pca-", fixture_name, "-"),
    fileext = ".csv"
  )
  output_path <- tempfile(
    paste0("figureforge-iris-pca-", fixture_name, "-output-")
  )
  log_path <- tempfile(
    paste0("figureforge-iris-pca-", fixture_name, "-"),
    fileext = ".log"
  )
  write.csv(data, input_path, row.names = FALSE, na = "")
  status <- system2(
    file.path(R.home("bin"), "Rscript"),
    c(
      shQuote(plot_script_path),
      shQuote(input_path),
      shQuote(output_path)
    ),
    stdout = log_path,
    stderr = log_path
  )
  assert_true(
    length(status) == 1L &&
      !is.na(as.integer(status)) &&
      as.integer(status) != 0L,
    paste("plot.R must reject the", fixture_name, "fixture")
  )
  output <- paste(readLines(log_path, warn = FALSE), collapse = "\n")
  for (pattern in expected_patterns) {
    assert_true(
      grepl(pattern, output, ignore.case = TRUE, perl = TRUE),
      paste(
        "The",
        fixture_name,
        "failure must explain",
        shQuote(pattern),
        "but output was:",
        output
      )
    )
  }
}

missing_column <- iris_data
missing_column$Sepal.Width <- NULL
assert_invalid_input(
  missing_column,
  "missing-required-column",
  c("missing|required", "Sepal\\.Width")
)

nonnumeric <- iris_data
nonnumeric$Sepal.Length <- as.character(nonnumeric$Sepal.Length)
nonnumeric$Sepal.Length[[1L]] <- "not-a-number"
assert_invalid_input(
  nonnumeric,
  "nonnumeric-measure",
  c("numeric", "Sepal\\.Length")
)

missing_value <- iris_data
missing_value$Petal.Length[[1L]] <- NA_real_
assert_invalid_input(
  missing_value,
  "missing-value",
  c("missing|NA", "Petal\\.Length")
)

nonfinite_value <- iris_data
nonfinite_value$Petal.Width[[1L]] <- Inf
assert_invalid_input(
  nonfinite_value,
  "nonfinite-value",
  c("finite|Inf", "Petal\\.Width")
)

zero_variance <- iris_data
zero_variance$Sepal.Width <- 1
assert_invalid_input(
  zero_variance,
  "zero-variance-measure",
  c("zero|constant|variance", "Sepal\\.Width")
)

empty_species <- iris_data
empty_species$Species[[1L]] <- ""
assert_invalid_input(
  empty_species,
  "empty-species",
  c("empty|blank|missing", "Species")
)

undersized_group <- iris_data[
  iris_data$Species != "setosa" |
    seq_len(nrow(iris_data)) %in% which(iris_data$Species == "setosa")[1:2],
  ,
  drop = FALSE
]
assert_invalid_input(
  undersized_group,
  "fewer-than-three-per-group",
  c("at least[[:space:]]+3|fewer than[[:space:]]+3|minimum.*3", "group|Species")
)

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
  "pca-loadings.csv",
  "index.html"
)
assert_true(
  all(file.exists(file.path(rerun_root, generated_outputs))),
  "The two-argument plot.R contract must generate every named output"
)
assert_true(
  all(file.info(file.path(rerun_root, generated_outputs))$size > 0L),
  "Every independently rerun output must be non-empty"
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
    c(
      "component",
      "eigenvalue",
      "explained_percent",
      "cumulative_percent"
    )
  ),
  "pca-variance.csv has an unexpected schema"
)
assert_true(
  identical(
    names(scores),
    c("sample_id", "Species", paste0("PC", 1:4))
  ),
  "pca-scores.csv has an unexpected schema"
)
assert_true(
  identical(names(loadings), c("variable", paste0("PC", 1:4))),
  "pca-loadings.csv has an unexpected schema"
)
assert_true(nrow(variance) == 4L, "pca-variance.csv must contain all four PCs")
assert_true(
  nrow(scores) == nrow(iris_data) &&
    length(unique(scores$sample_id)) == nrow(scores) &&
    all(nzchar(scores$sample_id)),
  "pca-scores.csv must contain one unique, non-empty sample_id per input row"
)
assert_true(
  nrow(loadings) == length(measure_columns),
  "pca-loadings.csv must contain one row per measure"
)

pca <- orient_pca(prcomp(
  iris_data[measure_columns],
  center = TRUE,
  scale. = TRUE
))
variance_percent <- 100 * pca$sdev^2 / sum(pca$sdev^2)
expected_variance <- data.frame(
  component = paste0("PC", seq_along(variance_percent)),
  eigenvalue = pca$sdev^2,
  explained_percent = variance_percent,
  cumulative_percent = cumsum(variance_percent),
  check.names = FALSE
)
expected_scores <- data.frame(
  sample_id = scores$sample_id,
  Species = iris_data$Species,
  pca$x[, paste0("PC", 1:4), drop = FALSE],
  check.names = FALSE
)
expected_loadings <- data.frame(
  variable = measure_columns,
  pca$rotation[measure_columns, paste0("PC", 1:4), drop = FALSE],
  check.names = FALSE
)
assert_true(
  identical(variance$component, expected_variance$component),
  "pca-variance.csv must identify PC1 through PC4"
)
assert_numeric_equal(
  variance[c("eigenvalue", "explained_percent", "cumulative_percent")],
  expected_variance[
    c("eigenvalue", "explained_percent", "cumulative_percent")
  ],
  "pca-variance.csv"
)
assert_true(
  identical(scores$Species, expected_scores$Species),
  "pca-scores.csv Species values must preserve iris.csv row order"
)
assert_numeric_equal(
  scores[paste0("PC", 1:4)],
  expected_scores[paste0("PC", 1:4)],
  "pca-scores.csv"
)
assert_true(
  identical(loadings$variable, expected_loadings$variable),
  "pca-loadings.csv variables must preserve measure-column order"
)
assert_numeric_equal(
  loadings[paste0("PC", 1:4)],
  expected_loadings[paste0("PC", 1:4)],
  "pca-loadings.csv"
)
loading_anchor_values <- vapply(
  paste0("PC", 1:4),
  function(component) {
    values <- loadings[[component]]
    values[[which.max(abs(values))]]
  },
  numeric(1)
)
assert_true(
  all(loading_anchor_values > 0),
  "Each PCA component must use the deterministic positive anchor-loading sign"
)
assert_numeric_equal(
  as.matrix(scores[paste0("PC", 1:4)]) %*%
    t(as.matrix(loadings[paste0("PC", 1:4)])),
  scale(
    iris_data[measure_columns],
    center = pca$center,
    scale = pca$scale
  ),
  "Sign-oriented PCA scores and loadings reconstruction",
  tolerance = 1e-7
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

pdfinfo <- Sys.which("pdfinfo")
pdftoppm <- Sys.which("pdftoppm")
assert_true(nzchar(pdfinfo), "pdfinfo is required to validate plot.pdf")
assert_true(nzchar(pdftoppm), "pdftoppm is required to render plot.pdf")

assert_rendered_artifacts <- function(root, label) {
  png_path <- file.path(root, "plot.png")
  png_size <- decoded_png_dimensions(png_path)
  assert_true(
    png_size[["width"]] > 0 && png_size[["height"]] > 0,
    paste(label, "plot.png must decode with positive dimensions")
  )

  pdf_path <- file.path(root, "plot.pdf")
  pdf_info <- system2(
    pdfinfo,
    shQuote(pdf_path),
    stdout = TRUE,
    stderr = TRUE
  )
  assert_true(
    is.null(attr(pdf_info, "status")),
    paste(label, "plot.pdf must be readable by pdfinfo")
  )
  page_line <- grep("^Pages:[[:space:]]+", pdf_info, value = TRUE)
  page_count <- if (length(page_line) == 1L) {
    as.integer(sub("^Pages:[[:space:]]+", "", page_line))
  } else {
    NA_integer_
  }
  assert_true(
    !is.na(page_count) && page_count == 1L,
    paste(label, "plot.pdf must contain exactly one page")
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
      shQuote(pdf_path),
      shQuote(render_prefix)
    ),
    stdout = render_log,
    stderr = render_log
  )
  rendered_png <- paste0(render_prefix, ".png")
  assert_true(
    identical(as.integer(render_status), 0L) &&
      file.exists(rendered_png) &&
      file.info(rendered_png)$size > 0L,
    paste(label, "plot.pdf must render its first page successfully")
  )
  rendered_size <- decoded_png_dimensions(rendered_png)
  assert_true(
    rendered_size[["width"]] > 0 && rendered_size[["height"]] > 0,
    paste(label, "rendered PDF preview must decode successfully")
  )
}

has_relative_href <- function(document, filename) {
  candidates <- c(
    paste0("href=\"", filename, "\""),
    paste0("href='", filename, "'"),
    paste0("href=\"./", filename, "\""),
    paste0("href='./", filename, "'")
  )
  any(vapply(
    candidates,
    grepl,
    logical(1),
    x = document,
    ignore.case = TRUE,
    fixed = TRUE
  ))
}

decode_html_text <- function(value) {
  replacements <- c(
    "&nbsp;" = " ",
    "&#160;" = " ",
    "&amp;" = "&",
    "&#38;" = "&",
    "&#038;" = "&",
    "&#x26;" = "&",
    "&lt;" = "<",
    "&#60;" = "<",
    "&#060;" = "<",
    "&#x3c;" = "<",
    "&gt;" = ">",
    "&#62;" = ">",
    "&#062;" = ">",
    "&#x3e;" = ">",
    "&quot;" = "\"",
    "&#34;" = "\"",
    "&#034;" = "\"",
    "&#x22;" = "\"",
    "&#39;" = "'",
    "&#039;" = "'",
    "&#x27;" = "'",
    "&apos;" = "'"
  )
  for (entity in names(replacements)) {
    value <- gsub(
      entity,
      replacements[[entity]],
      value,
      ignore.case = TRUE,
      fixed = TRUE
    )
  }
  trimws(gsub("[[:space:]]+", " ", value))
}

extract_html_table_rows <- function(html) {
  row_markup <- regmatches(
    html,
    gregexpr(
      "(?s)<tr[^>]*>.*?</tr>",
      html,
      ignore.case = TRUE,
      perl = TRUE
    )
  )[[1L]]
  lapply(row_markup, function(row) {
    cell_markup <- regmatches(
      row,
      gregexpr(
        "(?s)<t[dh][^>]*>.*?</t[dh]>",
        row,
        ignore.case = TRUE,
        perl = TRUE
      )
    )[[1L]]
    vapply(
      cell_markup,
      function(cell) {
        decode_html_text(gsub("<[^>]+>", "", cell, perl = TRUE))
      },
      character(1)
    )
  })
}

parse_html_number <- function(value) {
  normalized <- gsub("%", "", value, fixed = TRUE)
  normalized <- gsub(",", "", normalized, fixed = TRUE)
  normalized <- gsub("\u2212", "-", normalized, fixed = TRUE)
  suppressWarnings(as.numeric(trimws(normalized)))
}

assert_numeric_table_row <- function(
    table_rows,
    row_label,
    expected,
    label,
    tolerance = 0.01) {
  candidates <- Filter(
    function(row) length(row) >= length(expected) + 1L &&
      identical(row[[1L]], row_label),
    table_rows
  )
  assert_true(
    length(candidates) >= 1L,
    paste(label, "index.html must contain a table row for", row_label)
  )
  matches <- vapply(
    candidates,
    function(row) {
      actual <- vapply(
        row[seq_len(length(expected)) + 1L],
        parse_html_number,
        numeric(1)
      )
      all(is.finite(actual)) &&
        all(abs(actual - expected) <= tolerance)
    },
    logical(1)
  )
  assert_true(
    any(matches),
    paste(
      label,
      "index.html table row",
      row_label,
      "must numerically match its CSV values"
    )
  )
}

assert_live_html <- function(
    html_path,
    live_input,
    live_variance,
    live_loadings,
    label,
    extra_links = character()) {
  html <- read_text(html_path)
  assert_true(
    grepl(
      "<meta[^>]+name=[\"']viewport[\"'][^>]+content=[\"'][^\"']*width=device-width",
      html,
      ignore.case = TRUE,
      perl = TRUE
    ),
    paste(label, "index.html must declare a responsive viewport")
  )
  assert_true(
    grepl("FigureForge", html, ignore.case = TRUE, fixed = TRUE) &&
      grepl("request", html, ignore.case = TRUE, fixed = TRUE) &&
      grepl("Iris", html, ignore.case = TRUE, fixed = TRUE) &&
      grepl("PCA", html, ignore.case = TRUE, fixed = TRUE),
    paste(label, "index.html must identify FigureForge and the Iris PCA request")
  )
  assert_true(
    contains_all(html, c("PC1", "PC2")),
    paste(label, "index.html must explain the PC1-PC2 result")
  )
  dimension_pattern <- paste0(
    "(?:",
    nrow(live_input),
    "[[:space:]]*(?:rows|observations).{0,80}",
    ncol(live_input),
    "[[:space:]]*columns|",
    nrow(live_input),
    "[[:space:]]*[x×][[:space:]]*",
    ncol(live_input),
    ")"
  )
  assert_true(
    grepl(
      dimension_pattern,
      html,
      ignore.case = TRUE,
      perl = TRUE
    ),
    paste(label, "index.html must show the live input dimensions")
  )
  assert_true(
    grepl("prcomp", html, ignore.case = TRUE, fixed = TRUE) &&
      grepl("center", html, ignore.case = TRUE, fixed = TRUE) &&
      grepl("scal", html, ignore.case = TRUE, fixed = TRUE) &&
      grepl("adapt", html, ignore.case = TRUE, fixed = TRUE),
    paste(label, "index.html must explain the PCA method and adaptation")
  )
  assert_true(
    grepl(
      "<img[^>]+src=[\"'](?:\\./)?plot\\.png[\"']",
      html,
      ignore.case = TRUE,
      perl = TRUE
    ),
    paste(label, "index.html must display plot.png")
  )

  result_links <- c(
    "plot.png",
    "plot.pdf",
    "pca-variance.csv",
    "pca-scores.csv",
    "pca-loadings.csv",
    extra_links
  )
  for (filename in result_links) {
    assert_true(
      has_relative_href(html, filename),
      paste(label, "index.html must link", filename)
    )
  }

  assert_true(
    grepl(
      "<code>Rscript[[:space:]][^<]+</code>",
      html,
      perl = TRUE
    ),
    paste(label, "index.html must show a portable Rscript rerun command")
  )
  assert_true(
    !contains_absolute_local_path(html),
    paste(label, "index.html must not contain an absolute local path")
  )
  assert_true(
    !contains_remote_resource_dependency(html),
    paste(
      label,
      "index.html must be offline-portable without remote resource dependencies"
    )
  )

  table_rows <- extract_html_table_rows(html)
  for (index in seq_len(nrow(live_variance))) {
    assert_numeric_table_row(
      table_rows,
      live_variance$component[[index]],
      unlist(
        live_variance[
          index,
          c("eigenvalue", "explained_percent", "cumulative_percent")
        ],
        use.names = FALSE
      ),
      label
    )
  }
  loading_components <- setdiff(names(live_loadings), "variable")
  for (index in seq_len(nrow(live_loadings))) {
    assert_numeric_table_row(
      table_rows,
      live_loadings$variable[[index]],
      unlist(
        live_loadings[index, loading_components],
        use.names = FALSE
      ),
      label
    )
  }
}

rerun_variance <- read.csv(
  file.path(rerun_root, "pca-variance.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
rerun_loadings <- read.csv(
  file.path(rerun_root, "pca-loadings.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
assert_rendered_artifacts(demo_root, "Committed")
assert_rendered_artifacts(rerun_root, "Independent rerun")
assert_live_html(
  file.path(demo_root, "index.html"),
  iris_data,
  variance,
  loadings,
  "Committed",
  extra_links = c("iris.csv", "plot.R", "README.md")
)
assert_live_html(
  file.path(rerun_root, "index.html"),
  iris_data,
  rerun_variance,
  rerun_loadings,
  "Independent rerun"
)

run_valid_case <- function(data, case_label) {
  input_root <- tempfile(
    paste0("figureforge-iris-pca-", case_label, "-input-")
  )
  output_root <- tempfile(
    paste0("figureforge-iris-pca-", case_label, "-output-")
  )
  dir.create(input_root, recursive = TRUE)
  dir.create(output_root, recursive = TRUE)
  input_path <- file.path(input_root, "iris.csv")
  write.csv(data, input_path, row.names = FALSE)
  log_path <- tempfile(
    paste0("figureforge-iris-pca-", case_label, "-"),
    fileext = ".log"
  )
  status <- system2(
    file.path(R.home("bin"), "Rscript"),
    c(
      shQuote(plot_script_path),
      shQuote(input_path),
      shQuote(output_root)
    ),
    stdout = log_path,
    stderr = log_path
  )
  if (!identical(as.integer(status), 0L)) {
    stop(
      paste(
        case_label,
        "valid input failed:",
        paste(readLines(log_path, warn = FALSE), collapse = "\n")
      ),
      call. = FALSE
    )
  }
  assert_true(
    all(file.exists(file.path(output_root, generated_outputs))) &&
      all(file.info(file.path(output_root, generated_outputs))$size > 0L),
    paste(case_label, "valid run must generate every non-empty output")
  )

  case_variance <- read.csv(
    file.path(output_root, "pca-variance.csv"),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  case_scores <- read.csv(
    file.path(output_root, "pca-scores.csv"),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  case_loadings <- read.csv(
    file.path(output_root, "pca-loadings.csv"),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  case_pca <- orient_pca(prcomp(
    data[measure_columns],
    center = TRUE,
    scale. = TRUE
  ))
  case_components <- colnames(case_pca$rotation)
  assert_true(
    identical(
      names(case_variance),
      c(
        "component",
        "eigenvalue",
        "explained_percent",
        "cumulative_percent"
      )
    ),
    paste(case_label, "variance CSV has an unexpected schema")
  )
  assert_true(
    identical(
      names(case_scores),
      c("sample_id", "Species", case_components)
    ),
    paste(case_label, "scores CSV has an unexpected schema")
  )
  assert_true(
    identical(names(case_loadings), c("variable", case_components)),
    paste(case_label, "loadings CSV has an unexpected schema")
  )

  case_percent <- 100 * case_pca$sdev^2 / sum(case_pca$sdev^2)
  assert_true(
    identical(case_variance$component, case_components),
    paste(case_label, "variance CSV must identify every available component")
  )
  assert_numeric_equal(
    case_variance[
      c("eigenvalue", "explained_percent", "cumulative_percent")
    ],
    data.frame(
      eigenvalue = case_pca$sdev^2,
      explained_percent = case_percent,
      cumulative_percent = cumsum(case_percent)
    ),
    paste(case_label, "variance CSV")
  )
  assert_true(
    identical(case_scores$Species, data$Species),
    paste(case_label, "scores CSV must preserve Species row order")
  )
  assert_numeric_equal(
    case_scores[case_components],
    case_pca$x[, case_components, drop = FALSE],
    paste(case_label, "scores CSV")
  )
  assert_true(
    identical(case_loadings$variable, measure_columns),
    paste(case_label, "loadings CSV must preserve measure order")
  )
  assert_numeric_equal(
    case_loadings[case_components],
    case_pca$rotation[
      measure_columns,
      case_components,
      drop = FALSE
    ],
    paste(case_label, "loadings CSV")
  )

  assert_rendered_artifacts(output_root, case_label)
  assert_live_html(
    file.path(output_root, "index.html"),
    data,
    case_variance,
    case_loadings,
    case_label
  )
  list(
    root = output_root,
    variance = case_variance,
    loadings = case_loadings,
    html = read_text(file.path(output_root, "index.html")),
    log = paste(readLines(log_path, warn = FALSE), collapse = "\n")
  )
}

balanced_indices <- unlist(
  lapply(
    split(seq_len(nrow(iris_data)), iris_data$Species),
    head,
    n = 12L
  ),
  use.names = FALSE
)
altered_input <- iris_data[balanced_indices, , drop = FALSE]
altered_input$Sepal.Length <- altered_input$Sepal.Length +
  seq_len(nrow(altered_input)) * 0.013
altered_input$Sepal.Width <- altered_input$Sepal.Width +
  rep(c(-0.12, 0.04, 0.09), length.out = nrow(altered_input))
altered_input$Petal.Length <- altered_input$Petal.Length *
  rep(c(0.96, 1.03), length.out = nrow(altered_input))
altered_result <- run_valid_case(altered_input, "Altered balanced input")
assert_true(
  !isTRUE(all.equal(
    altered_result$variance$explained_percent[1:2],
    variance$explained_percent[1:2],
    tolerance = 1e-3
  )),
  "Altered input must produce non-canonical live PC1/PC2 variance values"
)

three_row_input <- data.frame(
  Sepal.Length = c(1, 2, 3),
  Sepal.Width = c(2, 4, 6),
  Petal.Length = c(3, 6, 9),
  Petal.Width = c(4, 8, 12),
  Species = rep("single-group", 3L),
  check.names = FALSE
)
three_row_result <- run_valid_case(
  three_row_input,
  "Three-row degenerate single group"
)
assert_true(
  identical(
    names(three_row_result$loadings),
    c("variable", "PC1", "PC2", "PC3")
  ),
  "A three-row input must expose only the three PCA components prcomp returns"
)
assert_true(
  !grepl("warning", three_row_result$log, ignore.case = TRUE),
  paste(
    "Three-row degenerate ellipse rendering must not warn:",
    three_row_result$log
  )
)

hardlink_root <- tempfile("figureforge-iris-pca-hardlink-")
dir.create(hardlink_root, recursive = TRUE)
hardlink_input <- file.path(hardlink_root, "source.csv")
assert_true(
  file.copy(file.path(demo_root, "iris.csv"), hardlink_input),
  "Hard-link fixture input must be created"
)
hardlink_output <- file.path(hardlink_root, "pca-scores.csv")
assert_true(
  file.link(hardlink_input, hardlink_output),
  "Hard-link fixture output alias must be created"
)
hardlink_sha_before <- sha256_file(hardlink_input)
hardlink_log <- tempfile("figureforge-iris-pca-hardlink-", fileext = ".log")
hardlink_status <- system2(
  file.path(R.home("bin"), "Rscript"),
  c(
    shQuote(plot_script_path),
    shQuote(hardlink_input),
    shQuote(hardlink_root)
  ),
  stdout = hardlink_log,
  stderr = hardlink_log
)
assert_true(
  identical(as.integer(hardlink_status), 0L),
  paste(
    "Pre-existing hard-link output run failed:",
    paste(readLines(hardlink_log, warn = FALSE), collapse = "\n")
  )
)
assert_true(
  identical(sha256_file(hardlink_input), hardlink_sha_before),
  "Publishing over a hard-link output target must preserve input SHA-256"
)
assert_true(
  all(file.exists(file.path(hardlink_root, generated_outputs))) &&
    all(file.info(file.path(hardlink_root, generated_outputs))$size > 0L),
  "Hard-link regression must still generate every non-empty output"
)
assert_true(
  !any(grepl(
    "^\\.figureforge-iris-pca-stage-",
    list.files(hardlink_root, all.files = TRUE)
  )),
  "Temporary staging directories must be cleaned after publication"
)
hardlink_input_data <- read.csv(
  hardlink_input,
  stringsAsFactors = FALSE,
  check.names = FALSE
)
hardlink_scores <- read.csv(
  hardlink_output,
  stringsAsFactors = FALSE,
  check.names = FALSE
)
assert_true(
  identical(names(hardlink_input_data), c(measure_columns, "Species")) &&
    identical(
      names(hardlink_scores),
      c("sample_id", "Species", paste0("PC", 1:4))
    ),
  "Hard-link publication must leave input and generated scores independently valid"
)

write_old_outputs <- function(root, filenames) {
  for (filename in filenames) {
    writeBin(
      charToRaw(paste0("OLD-", filename, "\n")),
      file.path(root, filename)
    )
  }
}

output_hashes <- function(root, filenames) {
  stats::setNames(
    vapply(
      file.path(root, filenames),
      sha256_file,
      character(1)
    ),
    filenames
  )
}

assert_no_transaction_residue <- function(root, label) {
  residue <- list.files(
    root,
    pattern = "^\\.figureforge-iris-pca-(?:stage|backup)-",
    all.files = TRUE
  )
  assert_true(
    length(residue) == 0L,
    paste(label, "must remove staging and backup residue:", paste(residue, collapse = ", "))
  )
}

preflight_root <- tempfile("figureforge-iris-pca-preflight-")
dir.create(preflight_root, recursive = TRUE)
preflight_input <- file.path(preflight_root, "source.csv")
assert_true(
  file.copy(file.path(demo_root, "iris.csv"), preflight_input),
  "Preflight fixture input must be created"
)
replaceable_outputs <- setdiff(generated_outputs, "index.html")
write_old_outputs(preflight_root, replaceable_outputs)
preflight_hashes_before <- output_hashes(
  preflight_root,
  replaceable_outputs
)
dir.create(file.path(preflight_root, "index.html"))
preflight_log <- tempfile(
  "figureforge-iris-pca-preflight-",
  fileext = ".log"
)
preflight_status <- system2(
  file.path(R.home("bin"), "Rscript"),
  c(
    shQuote(plot_script_path),
    shQuote(preflight_input),
    shQuote(preflight_root)
  ),
  stdout = preflight_log,
  stderr = preflight_log
)
assert_true(
  !identical(as.integer(preflight_status), 0L),
  "A directory blocking the late index.html target must reject publication"
)
assert_true(
  identical(
    output_hashes(preflight_root, replaceable_outputs),
    preflight_hashes_before
  ),
  "Destination preflight failure must leave every OLD output byte-identical"
)
assert_true(
  isTRUE(file.info(file.path(preflight_root, "index.html"))$isdir),
  "Destination preflight must leave the blocking index.html directory unchanged"
)
assert_no_transaction_residue(preflight_root, "Preflight failure")

rollback_root <- tempfile("figureforge-iris-pca-rollback-")
dir.create(rollback_root, recursive = TRUE)
rollback_input <- file.path(rollback_root, "source.csv")
assert_true(
  file.copy(file.path(demo_root, "iris.csv"), rollback_input),
  "Rollback fixture input must be created"
)
write_old_outputs(rollback_root, generated_outputs)
rollback_hashes_before <- output_hashes(rollback_root, generated_outputs)
rollback_log <- tempfile(
  "figureforge-iris-pca-rollback-",
  fileext = ".log"
)
rollback_status <- system2(
  file.path(R.home("bin"), "Rscript"),
  c(
    shQuote(plot_script_path),
    shQuote(rollback_input),
    shQuote(rollback_root)
  ),
  env = "FIGUREFORGE_INTERNAL_TEST_FAIL_AFTER_PUBLISH=3",
  stdout = rollback_log,
  stderr = rollback_log
)
assert_true(
  !identical(as.integer(rollback_status), 0L),
  "Injected mid-publication failure must make plot.R fail"
)
assert_true(
  grepl(
    "inject|test.*fail|fail.*publish",
    paste(readLines(rollback_log, warn = FALSE), collapse = "\n"),
    ignore.case = TRUE,
    perl = TRUE
  ),
  "Injected mid-publication failure must be explained in the error output"
)
assert_true(
  identical(
    output_hashes(rollback_root, generated_outputs),
    rollback_hashes_before
  ),
  "Mid-publication rollback must restore every OLD output byte-identical"
)
assert_no_transaction_residue(rollback_root, "Mid-publication rollback")

renamed_root <- tempfile("figureforge-iris-pca-renamed-input-")
dir.create(renamed_root, recursive = TRUE)
renamed_filename <- "input#frag? 50% O'Reilly-数据.csv"
renamed_path <- file.path(renamed_root, renamed_filename)
assert_true(
  file.copy(file.path(demo_root, "iris.csv"), renamed_path),
  "Renamed-input fixture must be created"
)
renamed_log <- tempfile("figureforge-iris-pca-renamed-input-", fileext = ".log")
renamed_status <- system2(
  file.path(R.home("bin"), "Rscript"),
  c(
    shQuote(plot_script_path),
    shQuote(renamed_path),
    shQuote(renamed_root)
  ),
  stdout = renamed_log,
  stderr = renamed_log
)
assert_true(
  identical(as.integer(renamed_status), 0L),
  paste(
    "Same-directory renamed input failed:",
    paste(readLines(renamed_log, warn = FALSE), collapse = "\n")
  )
)
renamed_html <- read_text(file.path(renamed_root, "index.html"))
assert_true(
  grepl(
    paste0(
      "href=[\"']",
      "input%23frag%3F%2050%25%20O%27Reilly-",
      "%E6%95%B0%E6%8D%AE\\.csv",
      "[\"']"
    ),
    renamed_html,
    ignore.case = TRUE,
    perl = TRUE
  ),
  "Special input filename must be URL component encoded in its working link"
)
assert_true(
  !has_relative_href(renamed_html, "plot.R") &&
    !has_relative_href(renamed_html, "README.md"),
  "Report must not emit broken same-directory plot.R or README.md links"
)
renamed_hrefs <- regmatches(
  renamed_html,
  gregexpr(
    "href=[\"'][^\"']+[\"']",
    renamed_html,
    ignore.case = TRUE,
    perl = TRUE
  )
)[[1L]]
renamed_targets <- vapply(
  renamed_hrefs,
  function(attribute) {
    utils::URLdecode(decode_html_text(sub(
        "^href=[\"']([^\"']+)[\"']$",
        "\\1",
        attribute,
        ignore.case = TRUE,
        perl = TRUE
      )))
  },
  character(1)
)
assert_true(
  all(file.exists(file.path(renamed_root, renamed_targets))),
  paste(
    "Every renamed-input report link must resolve to a real relative target; missing:",
    paste(
      renamed_targets[
        !file.exists(file.path(renamed_root, renamed_targets))
      ],
      collapse = ", "
    )
  )
)
rerun_markup <- regmatches(
  renamed_html,
  regexpr(
    "<code>Rscript[[:space:]][^<]+</code>",
    renamed_html,
    perl = TRUE
  )
)
assert_true(
  length(rerun_markup) == 1L && nzchar(rerun_markup),
  "Renamed-input report must contain one rerun command"
)
rerun_command <- decode_html_text(gsub("<[^>]+>", "", rerun_markup, perl = TRUE))
assert_true(
  grepl(renamed_filename, rerun_command, fixed = TRUE),
  "Rerun command must keep the live input filename human-readable"
)
old_working_directory <- getwd()
setwd(renamed_root)
rerun_status <- system(
  rerun_command,
  ignore.stdout = TRUE,
  ignore.stderr = TRUE
)
setwd(old_working_directory)
assert_true(
  identical(as.integer(rerun_status), 0L),
  paste("Report rerun command must execute successfully:", rerun_command)
)

escaping_input <- iris_data[seq_len(12L), , drop = FALSE]
unsafe_species_labels <- c(
  "A & B",
  "C < D",
  "<script data-note=\"O'Reilly\">E > F</script>"
)
escaping_input$Species <- rep(unsafe_species_labels, each = 4L)
assert_true(
  identical(
    as.integer(table(escaping_input$Species)),
    rep(4L, 3L)
  ),
  "Escaping fixture must retain exactly three valid four-row groups"
)
escaping_result <- run_valid_case(escaping_input, "Escaped species input")
escaping_html <- escaping_result$html
escaping_visible_text <- decode_html_text(gsub(
  "<[^>]+>",
  " ",
  escaping_html,
  perl = TRUE
))
assert_true(
  !grepl(
    "<script[^>]*data-note",
    escaping_html,
    ignore.case = TRUE,
    perl = TRUE
  ),
  "Dynamic Species labels must not create a raw script element"
)
for (unsafe_label in unsafe_species_labels) {
  assert_true(
    !grepl(unsafe_label, escaping_html, fixed = TRUE),
    paste("Escaped report must not contain raw Species label", shQuote(unsafe_label))
  )
}

optional_escaped_labels <- list(
  list(
    label = unsafe_species_labels[[1L]],
    pattern = "A[[:space:]]*&(?:amp|#0*38|#x0*26);[[:space:]]*B"
  ),
  list(
    label = unsafe_species_labels[[2L]],
    pattern = "C[[:space:]]*&(?:lt|#0*60|#x0*3c);[[:space:]]*D"
  ),
  list(
    label = unsafe_species_labels[[3L]],
    pattern = paste0(
      "&(?:lt|#0*60|#x0*3c);script[^\\r\\n]*",
      "&(?:gt|#0*62|#x0*3e);E[[:space:]]*",
      "&(?:gt|#0*62|#x0*3e);[[:space:]]*F",
      "&(?:lt|#0*60|#x0*3c);/script",
      "&(?:gt|#0*62|#x0*3e);"
    )
  )
)
for (fixture in optional_escaped_labels) {
  if (grepl(fixture$label, escaping_visible_text, fixed = TRUE)) {
    assert_true(
      grepl(
        fixture$pattern,
        escaping_html,
        ignore.case = TRUE,
        perl = TRUE
      ),
      paste(
        "Emitted Species label must safely escape dynamic &, <, or >:",
        shQuote(fixture$label)
      )
    )
  }
}

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
