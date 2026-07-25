#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
script_path <- if (length(file_arg) > 0L) {
  normalizePath(sub("^--file=", "", file_arg[[1L]]), mustWork = TRUE)
} else {
  normalizePath(
    "tests/figureforge/test_plotting_eval_contract.R",
    mustWork = TRUE
  )
}
repo_root <- normalizePath(
  file.path(dirname(script_path), "..", ".."),
  mustWork = TRUE
)
harness_path <- file.path(
  repo_root,
  "scripts",
  "run_figureforge_plotting_eval.sh"
)
fixture_path <- file.path(
  repo_root,
  "tests",
  "fixtures",
  "figureforge",
  "plotting-eval",
  "scatter.csv"
)

stopifnot(file.exists(harness_path))
stopifnot(identical(
  as.integer(system2("bash", c("-n", shQuote(harness_path)))),
  0L
))
harness_text <- paste(
  readLines(harness_path, warn = FALSE, encoding = "UTF-8"),
  collapse = "\n"
)
for (phrase in c(
  "--sandbox workspace-write",
  "plot.R",
  "plot.png",
  "plot.pdf",
  "independent-rerender",
  ': >"$FINAL_MESSAGE"'
)) {
  if (!grepl(phrase, harness_text, fixed = TRUE)) {
    stop("plotting harness is missing required text: ", phrase, call. = FALSE)
  }
}
stopifnot(file.exists(fixture_path))

fake_root <- tempfile("figureforge-plotting-eval-")
dir.create(fake_root, recursive = TRUE)
fake_codex <- file.path(fake_root, "fake-codex")
rscript <- Sys.getenv("FIGUREFORGE_RSCRIPT", unset = "")
if (!nzchar(rscript)) {
  rscript <- if (file.exists("/usr/local/bin/Rscript")) {
    "/usr/local/bin/Rscript"
  } else {
    Sys.which("Rscript")
  }
}
stopifnot(nzchar(rscript), file.exists(rscript))

fake_lines <- c(
  "#!/bin/sh",
  "set -eu",
  "cwd=",
  "final_message=",
  "while [ \"$#\" -gt 0 ]; do",
  "  case \"$1\" in",
  "    -C)",
  "      cwd=$2",
  "      shift 2",
  "      ;;",
  "    -o)",
  "      final_message=$2",
  "      shift 2",
  "      ;;",
  "    *)",
  "      shift",
  "      ;;",
  "  esac",
  "done",
  "test -n \"$cwd\"",
  "test -n \"$final_message\"",
  "mkdir -p \"$cwd/figureforge-output\"",
  "cat >\"$cwd/figureforge-output/plot.R\" <<'PLOT_R'",
  "#!/usr/bin/env Rscript",
  "",
  "args <- commandArgs(trailingOnly = TRUE)",
  "if (length(args) != 2L) {",
  "  stop(\"Usage: plot.R <input-file> <output-directory>\", call. = FALSE)",
  "}",
  "",
  "data <- read.csv(",
  "  args[[1L]],",
  "  fileEncoding = \"UTF-8\",",
  "  check.names = FALSE,",
  "  stringsAsFactors = FALSE",
  ")",
  "required <- c(\"喙长_mm\", \"喙深_mm\", \"物种\")",
  "missing <- setdiff(required, names(data))",
  "if (length(missing) > 0L) {",
  "  stop(",
  "    paste(\"Missing required columns:\", paste(missing, collapse = \", \")),",
  "    call. = FALSE",
  "  )",
  "}",
  "",
  "output_dir <- args[[2L]]",
  "dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)",
  "species <- factor(data[[\"物种\"]], levels = sort(unique(data[[\"物种\"]])))",
  "palette <- setNames(c(\"#0072B2\", \"#D55E00\", \"#009E73\"), levels(species))",
  "",
  "draw_plot <- function(open_device) {",
  "  open_device()",
  "  on.exit(dev.off(), add = TRUE)",
  "  plot(",
  "    data[[\"喙长_mm\"]],",
  "    data[[\"喙深_mm\"]],",
  "    col = unname(palette[as.character(species)]),",
  "    pch = 19,",
  "    xlab = \"Bill length (mm)\",",
  "    ylab = \"Bill depth (mm)\"",
  "  )",
  "  legend(",
  "    \"topright\",",
  "    legend = levels(species),",
  "    col = unname(palette[levels(species)]),",
  "    pch = 19,",
  "    bty = \"n\"",
  "  )",
  "}",
  "",
  "draw_plot(function() {",
  "  png(",
  "    file.path(output_dir, \"plot.png\"),",
  "    width = 1600,",
  "    height = 1200,",
  "    res = 180",
  "  )",
  "})",
  "draw_plot(function() {",
  "  pdf(file.path(output_dir, \"plot.pdf\"), width = 8, height = 6)",
  "})",
  "PLOT_R",
  paste(
    shQuote(rscript),
    "\"$cwd/figureforge-output/plot.R\"",
    "\"$cwd/scatter.csv\"",
    "\"$cwd/figureforge-output\""
  ),
  "printf '%s\\n' \"$cwd/figureforge-output/plot.R\" >\"$final_message\"",
  "printf '%s\\n' \"$cwd/figureforge-output/plot.png\" >>\"$final_message\"",
  "printf '%s\\n' \"$cwd/figureforge-output/plot.pdf\" >>\"$final_message\"",
  "printf '%s\\n' '{\"type\":\"item.completed\",\"item\":{\"type\":\"command_execution\",\"command\":\"sed -n 1,240p .agents/skills/figureforge/SKILL.md\"}}'"
)
writeLines(fake_lines, fake_codex, useBytes = TRUE)
Sys.chmod(fake_codex, mode = "0755")

eval_output <- file.path(fake_root, "output")
eval_result <- system2(
  "bash",
  c(
    shQuote(harness_path),
    "--output-dir",
    shQuote(eval_output),
    "--codex",
    shQuote(fake_codex)
  ),
  stdout = TRUE,
  stderr = TRUE
)
if (!is.null(attr(eval_result, "status"))) {
  stop(
    "plotting harness failed:\n",
    paste(eval_result, collapse = "\n"),
    call. = FALSE
  )
}

workspace_root <- readLines(
  file.path(eval_output, "workspace-root.txt"),
  warn = FALSE
)[[1L]]
delivered <- file.path(
  workspace_root,
  "figureforge-output",
  c("plot.R", "plot.png", "plot.pdf")
)
rerendered <- file.path(
  eval_output,
  "independent-rerender",
  c("plot.png", "plot.pdf")
)
stopifnot(all(file.info(delivered)$size > 0))
stopifnot(all(file.info(rerendered)$size > 0))
stopifnot(file.exists(file.path(eval_output, "final.txt")))
stopifnot(identical(
  readLines(
    file.path(eval_output, "independent-rerender-status.txt"),
    warn = FALSE
  ),
  "0"
))

summary <- read.csv(
  file.path(eval_output, "summary.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
stopifnot(nrow(summary) == 1L)
stopifnot(identical(
  names(summary),
  c(
    "exit_status",
    "skill_loaded",
    "script_exists",
    "png_exists",
    "pdf_exists",
    "rerender_png",
    "rerender_pdf",
    "passed"
  )
))
stopifnot(summary$exit_status[[1L]] == 0L)
boolean_columns <- setdiff(names(summary), "exit_status")
stopifnot(all(vapply(
  summary[boolean_columns],
  function(column) identical(column[[1L]], "true"),
  logical(1L)
)))

failing_codex <- file.path(fake_root, "failing-codex")
writeLines(
  c("#!/bin/sh", "exit 23"),
  failing_codex,
  useBytes = TRUE
)
Sys.chmod(failing_codex, mode = "0755")
failure_output <- file.path(fake_root, "failure-output")
failure_result <- suppressWarnings(system2(
  "bash",
  c(
    shQuote(harness_path),
    "--output-dir",
    shQuote(failure_output),
    "--codex",
    shQuote(failing_codex)
  ),
  stdout = TRUE,
  stderr = TRUE
))
stopifnot(identical(attr(failure_result, "status"), 1L))
audit_files <- file.path(
  failure_output,
  c("transcript.jsonl", "final.txt", "codex.stderr")
)
stopifnot(all(file.exists(audit_files)))
failure_summary <- read.csv(
  file.path(failure_output, "summary.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
stopifnot(nrow(failure_summary) == 1L)
stopifnot(failure_summary$exit_status[[1L]] == 23L)
stopifnot(identical(failure_summary$passed[[1L]], "false"))

message("plotting eval contract tests: PASS")
