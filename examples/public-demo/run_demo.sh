#!/bin/sh
set -eu

if [ "$#" -ne 1 ]; then
  echo "Usage: run_demo.sh EXTERNAL_OUTPUT_DIR" >&2
  exit 2
fi

RSCRIPT=${FIGUREFORGE_RSCRIPT:-}
if [ -z "$RSCRIPT" ]; then
  RSCRIPT=$(command -v Rscript || true)
fi
if [ -z "$RSCRIPT" ]; then
  echo "Rscript not found; set FIGUREFORGE_RSCRIPT or add Rscript to PATH" >&2
  exit 1
fi
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
LAYOUT_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)
if [ -f "$LAYOUT_ROOT/SKILL.md" ]; then
  SKILL_ROOT=$LAYOUT_ROOT
else
  SKILL_ROOT="$LAYOUT_ROOT/skills/figureforge"
fi
OUTPUT_DIR=$1
PREP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/figureforge-demo.XXXXXX")
trap 'rm -rf "$PREP_DIR"' EXIT HUP INT TERM

CHINESE_INPUT="$PREP_DIR/input-zh.csv"
MAPPING="$PREP_DIR/mapping.csv"
MATCH_REPORT="$PREP_DIR/schema-match.csv"

"$RSCRIPT" "$SCRIPT_DIR/generate_input.R" "$CHINESE_INPUT"
printf '%s\n' \
  'role,input_column' \
  'time,时间' \
  'estimate,均值' \
  'lower,下限' \
  'upper,上限' \
  'group,处理组' >"$MAPPING"

"$RSCRIPT" "$SKILL_ROOT/scripts/match_schema.R" \
  --case public-timeseries-band \
  --input "$CHINESE_INPUT" \
  --mapping "$MAPPING" \
  --output "$MATCH_REPORT"

"$RSCRIPT" "$SKILL_ROOT/scripts/create_adaptation.R" \
  --case public-timeseries-band \
  --input "$CHINESE_INPUT" \
  --mapping "$MAPPING" \
  --workspace "$OUTPUT_DIR"

"$RSCRIPT" "$SCRIPT_DIR/generate_input.R" \
  --canonicalize "$OUTPUT_DIR/input.csv" "$PREP_DIR/input-canonical.csv"
mv "$PREP_DIR/input-canonical.csv" "$OUTPUT_DIR/input.csv"
cp "$MATCH_REPORT" "$OUTPUT_DIR/schema-match.csv"

"$RSCRIPT" "$OUTPUT_DIR/plot.R" \
  "$OUTPUT_DIR/input.csv" \
  "$OUTPUT_DIR/output.pdf"

"$RSCRIPT" "$SKILL_ROOT/scripts/visual_qa.R" \
  --render "$OUTPUT_DIR/output.pdf" \
  --report "$OUTPUT_DIR/visual-qa.json"

"$RSCRIPT" "$SKILL_ROOT/scripts/validate_adaptation.R" \
  "$OUTPUT_DIR" \
  --render \
  --output "$OUTPUT_DIR/validation-output.pdf" \
  --rscript "$RSCRIPT"

echo "FigureForge public demo: PASS"
