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

if [ -e "$OUTPUT_DIR" ] &&
    [ -n "$(find "$OUTPUT_DIR" -mindepth 1 -maxdepth 1 -print -quit)" ]; then
  echo "Plotting-eval output directory must be empty: $OUTPUT_DIR" >&2
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
if [ -s "$TRANSCRIPT" ] &&
    grep -Fq '.agents/skills/figureforge/SKILL.md' "$TRANSCRIPT"; then
  skill_loaded=true
fi
if [ -s "$SCRIPT_PATH" ]; then
  script_exists=true
fi
if [ -s "$PNG_PATH" ]; then
  png_exists=true
fi
if [ -s "$PDF_PATH" ]; then
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
if [ -s "$RERENDER_DIR/plot.png" ]; then
  rerender_png=true
fi
if [ -s "$RERENDER_DIR/plot.pdf" ]; then
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
