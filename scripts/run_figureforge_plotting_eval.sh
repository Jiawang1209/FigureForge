#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
OUTPUT_DIR="$REPO_ROOT/outputs/figureforge-v110/plotting-eval/current"
CODEX_BIN=${CODEX_BIN:-codex}
MODEL=${FIGUREFORGE_LIVE_EVAL_MODEL:-}

usage() {
  cat <<'USAGE'
Usage: run_figureforge_plotting_eval.sh [--output-dir PATH] [--codex PATH] [--model MODEL]
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --output-dir)
      if [ "$#" -lt 2 ]; then
        usage >&2
        exit 2
      fi
      OUTPUT_DIR=$2
      shift 2
      ;;
    --codex)
      if [ "$#" -lt 2 ]; then
        usage >&2
        exit 2
      fi
      CODEX_BIN=$2
      shift 2
      ;;
    --model)
      if [ "$#" -lt 2 ]; then
        usage >&2
        exit 2
      fi
      MODEL=$2
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage >&2
      exit 2
      ;;
  esac
done

if [ -n "${FIGUREFORGE_RSCRIPT:-}" ]; then
  RSCRIPT=$FIGUREFORGE_RSCRIPT
elif [ -x /usr/local/bin/Rscript ]; then
  RSCRIPT=/usr/local/bin/Rscript
else
  RSCRIPT=$(command -v Rscript || true)
fi
if [ -z "$RSCRIPT" ] || [ ! -x "$RSCRIPT" ]; then
  echo "Unable to resolve executable Rscript for plotting evaluation" >&2
  exit 2
fi

if ! "$RSCRIPT" --vanilla -e \
    'quit(status = if (requireNamespace("jsonlite", quietly = TRUE) && requireNamespace("png", quietly = TRUE)) 0L else 1L)'; then
  echo "plotting evaluation requires R packages jsonlite and png" >&2
  exit 2
fi

PDFINFO=$(command -v pdfinfo || true)
PDFTOPPM=$(command -v pdftoppm || true)
if [ -z "$PDFINFO" ] || [ ! -x "$PDFINFO" ] ||
    [ -z "$PDFTOPPM" ] || [ ! -x "$PDFTOPPM" ]; then
  echo "plotting evaluation requires pdfinfo and pdftoppm" >&2
  exit 2
fi

skill_read_succeeded() {
  "$RSCRIPT" --vanilla - "$1" "$WORKSPACE_ROOT" <<'RSCRIPT'
args <- commandArgs(trailingOnly = TRUE)
transcript_path <- args[[1L]]
workspace_root <- args[[2L]]
skill_path <- normalizePath(
  file.path(workspace_root, ".agents", "skills", "figureforge", "SKILL.md"),
  mustWork = TRUE
)
read_commands <- c("awk", "cat", "head", "less", "more", "sed", "tail")

matched <- tryCatch({
  lines <- readLines(transcript_path, warn = FALSE, encoding = "UTF-8")
  lines <- lines[nzchar(trimws(lines))]
  events <- lapply(
    lines,
    jsonlite::fromJSON,
    simplifyVector = FALSE
  )
  any(vapply(events, function(event) {
    item <- event$item
    if (!identical(event$type, "item.completed") ||
        !is.list(item) ||
        !identical(item$type, "command_execution") ||
        !is.numeric(item$exit_code) ||
        length(item$exit_code) != 1L ||
        is.na(item$exit_code) ||
        item$exit_code != 0 ||
        !is.character(item$command) ||
        length(item$command) != 1L) {
      return(FALSE)
    }
    tokens <- strsplit(trimws(item$command), "[[:space:]]+")[[1L]]
    tokens <- gsub("^[\"']|[\"']$", "", tokens)
    if (length(tokens) == 0L ||
        !basename(tokens[[1L]]) %in% read_commands) {
      return(FALSE)
    }
    targets <- tokens[-1L]
    targets <- targets[!startsWith(targets, "-")]
    if (length(targets) == 0L) {
      return(FALSE)
    }
    resolved_targets <- vapply(targets, function(target) {
      if (startsWith(target, "/")) {
        normalizePath(target, mustWork = FALSE)
      } else {
        normalizePath(
          file.path(workspace_root, target),
          mustWork = FALSE
        )
      }
    }, character(1L))
    any(resolved_targets == skill_path)
  }, logical(1L)))
}, error = function(error) FALSE)

quit(status = if (isTRUE(matched)) 0L else 1L)
RSCRIPT
}

valid_png() {
  path=$1
  "$RSCRIPT" --vanilla - "$path" <<'RSCRIPT'
path <- commandArgs(trailingOnly = TRUE)[[1L]]
valid <- tryCatch({
  info <- file.info(path)
  if (is.na(info$size) || info$size <= 0 || info$size > 100 * 1024^2) {
    FALSE
  } else {
    decoded <- png::readPNG(path)
    dimensions <- dim(decoded)
    length(dimensions) >= 2L && all(dimensions[1L:2L] > 0L)
  }
}, error = function(error) FALSE)
quit(status = if (isTRUE(valid)) 0L else 1L)
RSCRIPT
}

valid_pdf() {
  path=$1
  if [ ! -s "$path" ]; then
    return 1
  fi
  size=$(wc -c <"$path")
  if [ "$size" -gt 104857600 ]; then
    return 1
  fi
  scratch=$(mktemp -d "$VALIDATION_DIR/pdf.XXXXXX")
  if ! "$PDFINFO" "$path" >"$scratch/pdfinfo.txt" 2>"$scratch/pdfinfo.stderr"; then
    return 1
  fi
  pages=$(
    awk '$1 == "Pages:" { print $2; exit }' "$scratch/pdfinfo.txt"
  )
  case "$pages" in
    ''|*[!0-9]*|0)
      return 1
      ;;
  esac
  render_prefix="$scratch/page-1"
  if ! "$PDFTOPPM" \
      -f 1 \
      -singlefile \
      -png \
      "$path" \
      "$render_prefix" \
      >"$scratch/pdftoppm.stdout" \
      2>"$scratch/pdftoppm.stderr"; then
    return 1
  fi
  valid_png "$render_prefix.png"
}

if [ -e "$OUTPUT_DIR" ] &&
    [ -n "$(find "$OUTPUT_DIR" -mindepth 1 -maxdepth 1 -print -quit)" ]; then
  echo "Plotting-eval output directory must be empty: $OUTPUT_DIR" >&2
  exit 2
fi
mkdir -p "$OUTPUT_DIR"
VALIDATION_DIR="$OUTPUT_DIR/validation"
mkdir -p "$VALIDATION_DIR"

ARCHIVE="$OUTPUT_DIR/figureforge-skill.tar.gz"
MANIFEST="$OUTPUT_DIR/release-manifest.csv"
"$RSCRIPT" \
  "$REPO_ROOT/skills/figureforge/scripts/package_skill.R" \
  --archive "$ARCHIVE" \
  --manifest "$MANIFEST" \
  >"$OUTPUT_DIR/package.log" 2>&1

WORKSPACE_ROOT=$(mktemp -d /tmp/figureforge-plotting-eval.XXXXXX)
mkdir -p "$WORKSPACE_ROOT/.agents/skills"
tar -xzf "$ARCHIVE" -C "$WORKSPACE_ROOT/.agents/skills"
if [ ! -s "$WORKSPACE_ROOT/.agents/skills/figureforge/SKILL.md" ]; then
  echo "Packaged FigureForge Skill did not install correctly" >&2
  exit 2
fi
cp \
  "$REPO_ROOT/tests/fixtures/figureforge/plotting-eval/scatter.csv" \
  "$WORKSPACE_ROOT/scatter.csv"
printf '%s\n' "$WORKSPACE_ROOT" >"$OUTPUT_DIR/workspace-root.txt"

TRANSCRIPT="$OUTPUT_DIR/transcript.jsonl"
STDERR_LOG="$OUTPUT_DIR/codex.stderr"
FINAL_MESSAGE="$OUTPUT_DIR/final.txt"
: >"$TRANSCRIPT"
: >"$STDERR_LOG"
: >"$FINAL_MESSAGE"
PROMPT='Use $figureforge with scatter.csv. Draw a publication-ready scatter plot of 喙长_mm versus 喙深_mm colored by 物种. Work without asking about presentation details. Create figureforge-output/plot.R, plot.png, and plot.pdf, execute the script, inspect the outputs, and return the three paths. Before acting, read the installed Skill.'
codex_args=(exec --ephemeral --skip-git-repo-check --sandbox workspace-write -C "$WORKSPACE_ROOT" --json -o "$FINAL_MESSAGE")
if [ -n "$MODEL" ]; then
  codex_args+=(--model "$MODEL")
fi

if (
  cd "$WORKSPACE_ROOT"
  "$CODEX_BIN" "${codex_args[@]}" "$PROMPT" \
    </dev/null >"$TRANSCRIPT" 2>"$STDERR_LOG"
); then
  exit_status=0
else
  exit_status=$?
fi

skill_loaded=false
script_exists=false
png_exists=false
pdf_exists=false
SCRIPT_PATH="$WORKSPACE_ROOT/figureforge-output/plot.R"
PNG_PATH="$WORKSPACE_ROOT/figureforge-output/plot.png"
PDF_PATH="$WORKSPACE_ROOT/figureforge-output/plot.pdf"
if skill_read_succeeded "$TRANSCRIPT"; then
  skill_loaded=true
fi
if [ -s "$SCRIPT_PATH" ]; then
  script_exists=true
fi
if valid_png "$PNG_PATH"; then
  png_exists=true
fi
if valid_pdf "$PDF_PATH"; then
  pdf_exists=true
fi

RERENDER_DIR="$OUTPUT_DIR/independent-rerender"
mkdir -p "$RERENDER_DIR"
if [ "$script_exists" = true ]; then
  if "$RSCRIPT" \
      "$SCRIPT_PATH" \
      "$WORKSPACE_ROOT/scatter.csv" \
      "$RERENDER_DIR" \
      >"$OUTPUT_DIR/independent-rerender.stdout" \
      2>"$OUTPUT_DIR/independent-rerender.stderr"; then
    rerender_status=0
  else
    rerender_status=$?
  fi
else
  rerender_status=127
  : >"$OUTPUT_DIR/independent-rerender.stdout"
  printf '%s\n' "Delivered plot.R is missing or empty" \
    >"$OUTPUT_DIR/independent-rerender.stderr"
fi
printf '%s\n' "$rerender_status" >"$OUTPUT_DIR/independent-rerender-status.txt"

rerender_png=false
rerender_pdf=false
if valid_png "$RERENDER_DIR/plot.png"; then
  rerender_png=true
fi
if valid_pdf "$RERENDER_DIR/plot.pdf"; then
  rerender_pdf=true
fi

passed=false
if [ "$exit_status" -eq 0 ] &&
    [ "$skill_loaded" = true ] &&
    [ "$script_exists" = true ] &&
    [ "$png_exists" = true ] &&
    [ "$pdf_exists" = true ] &&
    [ "$rerender_status" -eq 0 ] &&
    [ "$rerender_png" = true ] &&
    [ "$rerender_pdf" = true ]; then
  passed=true
fi

SUMMARY="$OUTPUT_DIR/summary.csv"
printf '%s\n' \
  'exit_status,skill_loaded,script_exists,png_exists,pdf_exists,rerender_png,rerender_pdf,passed' \
  >"$SUMMARY"
printf '%s,%s,%s,%s,%s,%s,%s,%s\n' \
  "$exit_status" \
  "$skill_loaded" \
  "$script_exists" \
  "$png_exists" \
  "$pdf_exists" \
  "$rerender_png" \
  "$rerender_pdf" \
  "$passed" \
  >>"$SUMMARY"

echo "Plotting evaluation passed: $passed"
echo "Audit workspace retained at: $WORKSPACE_ROOT"
echo "Evaluation artifacts: $OUTPUT_DIR"

if [ "$passed" != true ]; then
  exit 1
fi
