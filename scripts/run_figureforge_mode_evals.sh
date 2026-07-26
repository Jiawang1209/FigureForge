#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
OUTPUT_DIR="$REPO_ROOT/outputs/figureforge-v110/mode-evals/current"
CODEX_BIN=${CODEX_BIN:-codex}
MODEL=${FIGUREFORGE_LIVE_EVAL_MODEL:-}

usage() {
  echo "Usage: run_figureforge_mode_evals.sh [--output-dir PATH] [--codex PATH] [--model MODEL]"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --output-dir)
      [ "$#" -ge 2 ] || { usage >&2; exit 2; }
      OUTPUT_DIR=$2
      shift 2
      ;;
    --codex)
      [ "$#" -ge 2 ] || { usage >&2; exit 2; }
      CODEX_BIN=$2
      shift 2
      ;;
    --model)
      [ "$#" -ge 2 ] || { usage >&2; exit 2; }
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
  echo "Unable to resolve executable Rscript for mode evaluations" >&2
  exit 2
fi
if ! "$RSCRIPT" --vanilla -e \
    'quit(status = if (requireNamespace("jsonlite", quietly = TRUE)) 0L else 1L)'; then
  echo "mode evaluations require the R package jsonlite" >&2
  exit 2
fi
resolve_trusted_reader() {
  FIGUREFORGE_READER_NAME=$1 \
    "$RSCRIPT" --vanilla -e '
      name <- Sys.getenv("FIGUREFORGE_READER_NAME")
      candidates <- file.path(c("/bin", "/usr/bin"), name)
      candidates <- candidates[file.exists(candidates)]
      targets <- unique(vapply(
        candidates,
        normalizePath,
        character(1L),
        mustWork = TRUE,
        USE.NAMES = FALSE
      ))
      valid <- targets[vapply(targets, function(path) {
        isTRUE(file_test("-f", path)) &&
          identical(Sys.readlink(path), "") &&
          identical(basename(path), name) &&
          identical(unname(file.access(path, mode = 1L)), 0L)
      }, logical(1L))]
      if (length(valid) < 1L) quit(status = 1L)
      cat(valid[[1L]])
    '
}
TRUSTED_CAT=$(resolve_trusted_reader cat)
TRUSTED_SED=$(resolve_trusted_reader sed)
if [ -e "$OUTPUT_DIR" ] &&
    [ -n "$(find "$OUTPUT_DIR" -mindepth 1 -maxdepth 1 -print -quit)" ]; then
  echo "Mode-eval output directory must be empty: $OUTPUT_DIR" >&2
  exit 2
fi
mkdir -p "$OUTPUT_DIR"

ARCHIVE="$OUTPUT_DIR/figureforge-skill.tar.gz"
MANIFEST="$OUTPUT_DIR/release-manifest.csv"
"$RSCRIPT" \
  "$REPO_ROOT/skills/figureforge/scripts/package_skill.R" \
  --archive "$ARCHIVE" \
  --manifest "$MANIFEST" \
  >"$OUTPUT_DIR/package.log" 2>&1
chmod a-w "$ARCHIVE" "$MANIFEST" "$ARCHIVE.sha256"

run_probe() {
  expected_mode=$1
  input_source=$2
  input_name=$3
  prompt=$4
  probe_dir="$OUTPUT_DIR/$expected_mode"
  workspace=$(mktemp -d "/tmp/figureforge-${expected_mode}-eval.XXXXXX")
  trusted_extract="$probe_dir/trusted-install"
  installed_skill="$trusted_extract/figureforge"
  mkdir -p "$workspace/.agents/skills" "$probe_dir"
  "$RSCRIPT" \
    "$REPO_ROOT/skills/figureforge/scripts/verify_release.R" \
    --archive "$ARCHIVE" \
    --manifest "$MANIFEST" \
    --extract-dir "$trusted_extract" \
    >"$probe_dir/trusted-install.log" 2>&1
  test -s "$installed_skill/SKILL.md"
  chmod -R a-w "$trusted_extract"
  ln -s "$installed_skill" "$workspace/.agents/skills/figureforge"
  cp "$input_source" "$workspace/$input_name"
  printf '%s\n' "$workspace" >"$probe_dir/workspace-root.txt"

  transcript="$probe_dir/transcript.jsonl"
  final_message="$probe_dir/final.txt"
  stderr_log="$probe_dir/codex.stderr"
  : >"$transcript"
  : >"$final_message"
  : >"$stderr_log"
  codex_args=(
    exec
    --ephemeral
    --skip-git-repo-check
    --sandbox workspace-write
    -C "$workspace"
    --json
    -o "$final_message"
  )
  if [ -n "$MODEL" ]; then
    codex_args+=(--model "$MODEL")
  fi
  if (
    cd "$workspace"
    "$CODEX_BIN" "${codex_args[@]}" "$prompt" \
      </dev/null >"$transcript" 2>"$stderr_log"
  ); then
    codex_status=0
  else
    codex_status=$?
  fi
  printf '%s\n' "$codex_status" >"$probe_dir/codex-status.txt"

  output_root="$workspace/figureforge-output"
  trace_path="$output_root/.figureforge/case-trace.yml"
  script_path="$output_root/plot.R"
  validator_log="$probe_dir/validator.log"
  validator_status=1
  if [ -s "$trace_path" ] && [ -s "$script_path" ]; then
    if [ "$expected_mode" = "case_based" ]; then
      primary_case_id=$(
        awk -F ':' '
          $1 == "primary_case_id" {
            sub(/^[[:space:]]+/, "", $2)
            print $2
            exit
          }
        ' "$trace_path"
      )
      case "$primary_case_id" in
        ''|*[!A-Za-z0-9._-]*)
          printf '%s\n' "Unsafe or missing primary_case_id" >"$validator_log"
          ;;
        *)
          case_dir="$installed_skill/public-cases/$primary_case_id"
          if "$RSCRIPT" "$installed_skill/scripts/validate_case_trace.R" \
              "$trace_path" \
              --case-dir "$case_dir" \
              --script "$script_path" \
              --schema "$workspace/$input_name" \
              >"$validator_log" 2>&1; then
            validator_status=0
          else
            validator_status=$?
          fi
          ;;
      esac
    else
      if "$RSCRIPT" "$installed_skill/scripts/validate_case_trace.R" \
          "$trace_path" \
          --script "$script_path" \
          --schema "$workspace/$input_name" \
          >"$validator_log" 2>&1; then
        validator_status=0
      else
        validator_status=$?
      fi
    fi
  else
    printf '%s\n' "Trace or generated script is missing" >"$validator_log"
  fi
  printf '%s\n' "$validator_status" >"$probe_dir/validator-status.txt"

  summary="$probe_dir/summary.csv"
  evaluator_status=0
  "$RSCRIPT" "$REPO_ROOT/scripts/evaluate_figureforge_mode_probe.R" \
    --expected-mode "$expected_mode" \
    --workspace "$workspace" \
    --installed-skill "$installed_skill" \
    --manifest "$MANIFEST" \
    --trusted-cat "$TRUSTED_CAT" \
    --trusted-sed "$TRUSTED_SED" \
    --transcript "$transcript" \
    --validator-log "$validator_log" \
    --validator-status "$validator_status" \
    --output "$summary" || evaluator_status=$?
  if [ "$codex_status" -ne 0 ] || [ "$evaluator_status" -ne 0 ]; then
    return 1
  fi
}

strong_prompt="Use the installed \$figureforge Skill with scatter.csv. Create a publication-ready grouped scatter plot of predictor versus response with a fitted linear trend. Follow the installed Skill workflow completely: search public cases with the input schema and save the search receipt, choose the justified generation mode, and create figureforge-output/plot.R, plot.png, plot.pdf plus the hidden .figureforge/case-trace.yml. If you use case_based, actually read the selected installed case.md, plot.R, and qa.md. For successful cat or sed commands retained in the raw transcript, use exactly $TRUSTED_CAT or $TRUSTED_SED -n as the executable path; do not use bare names, PATH overrides, aliases, wrappers, or symlink executables. Record concrete adopted patterns and departures, run strict trace validation, execute plot.R, and inspect the outputs. Return the three visible artifact paths."
fallback_prompt='Use the installed $figureforge Skill with iris.csv. Create a publication-ready PCA biplot with sample scores colored by Species, confidence ellipses, loading arrows, and variance-explained axis labels. Follow the installed Skill workflow completely: search public cases with the input schema and save the search receipt, choose the justified generation mode, and create figureforge-output/plot.R, plot.png, plot.pdf plus the hidden .figureforge/case-trace.yml. There is no public PCA or biplot case in this installed package, so use general_fallback if the search confirms there is no sufficiently relevant case; do not claim case grounding. Run strict trace validation, execute plot.R, and inspect the outputs. Return the three visible artifact paths.'

run_probe \
  case_based \
  "$REPO_ROOT/skills/figureforge/public-cases/public-scatter-fit/data.csv" \
  scatter.csv \
  "$strong_prompt"
run_probe \
  general_fallback \
  "$REPO_ROOT/examples/iris-pca/iris.csv" \
  iris.csv \
  "$fallback_prompt"

SUMMARY="$OUTPUT_DIR/summary.csv"
head -n 1 "$OUTPUT_DIR/case_based/summary.csv" >"$SUMMARY"
tail -n 1 "$OUTPUT_DIR/case_based/summary.csv" >>"$SUMMARY"
tail -n 1 "$OUTPUT_DIR/general_fallback/summary.csv" >>"$SUMMARY"
"$RSCRIPT" --vanilla - "$SUMMARY" <<'RSCRIPT'
summary_path <- commandArgs(trailingOnly = TRUE)[[1L]]
summary <- read.csv(
  summary_path,
  stringsAsFactors = FALSE,
  check.names = FALSE
)
stopifnot(
  nrow(summary) == 2L,
  identical(summary$expected_mode, c("case_based", "general_fallback")),
  all(summary$passed)
)
RSCRIPT

echo "FigureForge two-mode live evaluation: PASS"
echo "Raw transcripts and audit artifacts: $OUTPUT_DIR"
