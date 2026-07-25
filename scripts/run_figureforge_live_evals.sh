#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
OUTPUT_DIR="$REPO_ROOT/outputs/figureforge-v101/live-evals/current"
CODEX_BIN=${CODEX_BIN:-codex}
MODEL=${FIGUREFORGE_LIVE_EVAL_MODEL:-}

if [ -n "${FIGUREFORGE_RSCRIPT:-}" ]; then
  RSCRIPT=$FIGUREFORGE_RSCRIPT
elif [ -x /usr/local/bin/Rscript ]; then
  RSCRIPT=/usr/local/bin/Rscript
else
  RSCRIPT=$(command -v Rscript || true)
fi
if [ -z "$RSCRIPT" ] || [ ! -x "$RSCRIPT" ]; then
  echo "Unable to resolve Rscript for live evaluations" >&2
  exit 2
fi

usage() {
  echo "Usage: run_figureforge_live_evals.sh [--output-dir PATH] [--codex PATH] [--model MODEL]"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --output-dir)
      OUTPUT_DIR=$2
      shift 2
      ;;
    --codex)
      CODEX_BIN=$2
      shift 2
      ;;
    --model)
      MODEL=$2
      shift 2
      ;;
    *)
      usage >&2
      exit 2
      ;;
  esac
done

if [ -e "$OUTPUT_DIR" ] &&
    [ -n "$(find "$OUTPUT_DIR" -mindepth 1 -maxdepth 1 -print -quit)" ]; then
  echo "Live-eval output directory must be empty: $OUTPUT_DIR" >&2
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

INSTALL_ROOT=$(mktemp -d /tmp/figureforge-live-evals.XXXXXX)
mkdir -p "$INSTALL_ROOT/.agents/skills"
tar -xzf "$ARCHIVE" -C "$INSTALL_ROOT/.agents/skills"
test -s "$INSTALL_ROOT/.agents/skills/figureforge/SKILL.md"
printf '%s\n' "$INSTALL_ROOT" >"$OUTPUT_DIR/install-root.txt"

PROMPTS="$OUTPUT_DIR/prompts.tsv"
{
  printf 'explicit\t001\t%s\n' \
    'Use $figureforge with a CSV to create a publication-ready R scatter plot. Return only the selected capability and the three artifact names it would create. Do not execute the plotting task.'
  printf 'implicit\t001\t%s\n' \
    'I have a CSV with time, group, estimate, lower, and upper columns for a publication-ready time series. Return only the selected capability and the three artifact names it would create. Do not execute the plotting task.'
  printf 'implicit\t002\t%s\n' \
    '我的 CSV 有处理组、条件和响应值三列，想做适合论文的分组柱状图。Return only the selected capability and the three artifact names it would create. Do not execute the plotting task.'
  printf 'implicit\t003\t%s\n' \
    'I have feature, log2 fold change, adjusted p-value, and class columns for a volcano plot. Return only the selected capability and the three artifact names it would create. Do not execute the plotting task.'
  printf 'implicit\t004\t%s\n' \
    '我只有 variable_x、variable_y 和 correlation 三列数据，想做相关性热图。Return only the selected capability and the three artifact names it would create. Do not execute the plotting task.'
  printf 'implicit\t005\t%s\n' \
    'My table contains group, time, survival, lower, and upper for a publication-ready survival curve. Return only the selected capability and the three artifact names it would create. Do not execute the plotting task.'
  printf 'implicit\t006\t%s\n' \
    '我想把 group、value、sample_id 三列做成雨云图，但不希望修改原始数据。Return only the selected capability and the three artifact names it would create. Do not execute the plotting task.'
  printf 'implicit\t007\t%s\n' \
    'I have deterministic node and edge records with coordinates for a publication-ready network plot. Return only the selected capability and the three artifact names it would create. Do not execute the plotting task.'
  printf 'implicit\t008\t%s\n' \
    'I need a species-colored fitted scatter plot from bill measurements. Return only the selected capability and the three artifact names it would create. Do not execute the plotting task.'
  printf 'implicit\t009\t%s\n' \
    '我有国家、年份和人口三列，要制作可复现的人口时序图。Return only the selected capability and the three artifact names it would create. Do not execute the plotting task.'
  printf 'implicit\t010\t%s\n' \
    'I was told to make a bubble plot, but the term is ambiguous and I only have data columns. Return only the selected capability and the three artifact names it would create. Do not execute the plotting task.'
} >"$PROMPTS"

SUMMARY="$OUTPUT_DIR/summary.csv"
printf 'kind,probe_id,exit_status,skill_loaded,capability_selected,artifact_contract,passed\n' \
  >"$SUMMARY"

explicit_total=0
explicit_passed=0
implicit_total=0
implicit_passed=0

while IFS=$'\t' read -r kind probe_id prompt; do
  stem="$kind-$probe_id"
  transcript="$OUTPUT_DIR/$stem.jsonl"
  final_message="$OUTPUT_DIR/$stem-last.txt"
  stderr_log="$OUTPUT_DIR/$stem.stderr"
  codex_args=(
    exec
    --ephemeral
    --skip-git-repo-check
    --sandbox read-only
    -C "$INSTALL_ROOT"
    --json
    -o "$final_message"
  )
  if [ -n "$MODEL" ]; then
    codex_args+=(--model "$MODEL")
  fi
  probe_prompt="$prompt Before answering, read the selected capability's installed SKILL.md."
  if "$CODEX_BIN" "${codex_args[@]}" "$probe_prompt" \
      </dev/null >"$transcript" 2>"$stderr_log"; then
    exit_status=0
  else
    exit_status=$?
  fi

  skill_loaded=false
  capability_selected=false
  artifact_contract=false
  if grep -Fq '.agents/skills/figureforge/SKILL.md' "$transcript"; then
    skill_loaded=true
  fi
  if [ -s "$final_message" ] &&
      grep -qi 'figureforge' "$final_message"; then
    capability_selected=true
  fi
  if [ -s "$final_message" ] &&
      grep -Fq 'plot.R' "$final_message" &&
      grep -Fq 'plot.png' "$final_message" &&
      grep -Fq 'plot.pdf' "$final_message"; then
    artifact_contract=true
  fi
  passed=false
  if [ "$exit_status" -eq 0 ] &&
      [ "$skill_loaded" = true ] &&
      [ "$capability_selected" = true ] &&
      [ "$artifact_contract" = true ]; then
    passed=true
  fi
  printf '%s,%s,%s,%s,%s,%s,%s\n' \
    "$kind" "$probe_id" "$exit_status" "$skill_loaded" \
    "$capability_selected" "$artifact_contract" "$passed" >>"$SUMMARY"

  if [ "$kind" = explicit ]; then
    explicit_total=$((explicit_total + 1))
    if [ "$passed" = true ]; then
      explicit_passed=$((explicit_passed + 1))
    fi
  else
    implicit_total=$((implicit_total + 1))
    if [ "$passed" = true ]; then
      implicit_passed=$((implicit_passed + 1))
    fi
  fi
done <"$PROMPTS"

explicit_rate=$(
  awk -v passed="$explicit_passed" -v total="$explicit_total" \
    'BEGIN { if (total == 0) print 0; else printf "%.6f", passed / total }'
)
implicit_rate=$(
  awk -v passed="$implicit_passed" -v total="$implicit_total" \
    'BEGIN { if (total == 0) print 0; else printf "%.6f", passed / total }'
)
{
  printf 'explicit_passed=%s\n' "$explicit_passed"
  printf 'explicit_total=%s\n' "$explicit_total"
  printf 'explicit_rate=%s\n' "$explicit_rate"
  printf 'implicit_passed=%s\n' "$implicit_passed"
  printf 'implicit_total=%s\n' "$implicit_total"
  printf 'implicit_rate=%s\n' "$implicit_rate"
} >"$OUTPUT_DIR/thresholds.txt"

echo "Explicit live probes: $explicit_passed/$explicit_total"
echo "Implicit live probes: $implicit_passed/$implicit_total"
echo "Raw transcripts: $OUTPUT_DIR"

awk -v explicit="$explicit_rate" -v implicit="$implicit_rate" \
  'BEGIN { exit !(explicit == 1 && implicit >= 0.90) }'
