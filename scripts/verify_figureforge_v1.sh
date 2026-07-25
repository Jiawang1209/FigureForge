#!/bin/sh
set -eu

RSCRIPT=/usr/local/bin/Rscript
PYTHON=/usr/bin/python3
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
PUBLIC_CASES="$REPO_ROOT/skills/figureforge/public-cases"
STRESS_FIXTURES="$REPO_ROOT/tests/fixtures/figureforge/stress"
VERIFY_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/figureforge-v1.XXXXXX")
trap 'rm -rf "$VERIFY_ROOT"' EXIT HUP INT TERM

stage() {
  echo "==> $1"
}

stage "FigureForge R tests"
for test_file in "$REPO_ROOT"/tests/figureforge/*.R; do
  if [ "$(basename "$test_file")" = "test_v1_acceptance.R" ]; then
    continue
  fi
  "$RSCRIPT" "$test_file"
done

stage "public distribution and external renders"
case_count=0
for case_dir in "$PUBLIC_CASES"/*; do
  [ -d "$case_dir" ] || continue
  case_id=$(basename "$case_dir")
  case_count=$((case_count + 1))
  "$RSCRIPT" \
    "$REPO_ROOT/skills/figureforge/scripts/validate_distribution.R" \
    "$case_dir"
  "$RSCRIPT" \
    "$REPO_ROOT/skills/figureforge/scripts/validate_public_case.R" \
    "$case_dir" \
    --render \
    --output "$VERIFY_ROOT/public-renders/$case_id.pdf" \
    --rscript "$RSCRIPT"
done
[ "$case_count" -eq 12 ]

stage "24 synthetic stress scenarios"
"$RSCRIPT" "$REPO_ROOT/skills/figureforge/scripts/run_stress_tests.R" \
  --fixtures "$STRESS_FIXTURES" \
  --public-cases "$PUBLIC_CASES" \
  --output-dir "$VERIFY_ROOT/stress-renders" \
  --report "$VERIFY_ROOT/stress-report.csv" \
  --rscript "$RSCRIPT"
"$RSCRIPT" -e \
  "x <- read.csv('$VERIFY_ROOT/stress-report.csv'); stopifnot(nrow(x) == 24L, all(x\$passed))"

stage "doctor text and JSON"
"$RSCRIPT" "$REPO_ROOT/skills/figureforge/scripts/doctor.R" \
  >"$VERIFY_ROOT/doctor.txt"
"$RSCRIPT" "$REPO_ROOT/skills/figureforge/scripts/doctor.R" \
  --format json >"$VERIFY_ROOT/doctor.json"
"$PYTHON" -c \
  "import json; json.load(open('$VERIFY_ROOT/doctor.json', encoding='utf-8'))"

stage "paired bilingual public search"
"$RSCRIPT" "$REPO_ROOT/skills/figureforge/scripts/search_cases.R" \
  --public --query "correlation heatmap" \
  --output "$VERIFY_ROOT/search-en.csv"
"$RSCRIPT" "$REPO_ROOT/skills/figureforge/scripts/search_cases.R" \
  --public --query "相关性热图" \
  --output "$VERIFY_ROOT/search-zh.csv"
"$RSCRIPT" -e \
  "a <- read.csv('$VERIFY_ROOT/search-en.csv'); b <- read.csv('$VERIFY_ROOT/search-zh.csv'); stopifnot(a\$case_id[[1L]] == b\$case_id[[1L]], a\$case_id[[1L]] == 'public-correlation-heatmap')"

stage "schema match and protected path rejection"
"$RSCRIPT" "$REPO_ROOT/skills/figureforge/scripts/match_schema.R" \
  --case public-timeseries-band \
  --input "$PUBLIC_CASES/public-timeseries-band/data.csv" \
  --output "$VERIFY_ROOT/schema-match.csv"
forbidden="$PUBLIC_CASES/public-timeseries-band/forbidden-adaptation"
if "$RSCRIPT" "$REPO_ROOT/skills/figureforge/scripts/create_adaptation.R" \
  --case public-timeseries-band \
  --input "$PUBLIC_CASES/public-timeseries-band/data.csv" \
  --workspace "$forbidden" >"$VERIFY_ROOT/protected.log" 2>&1; then
  echo "Protected workspace test unexpectedly succeeded" >&2
  exit 1
fi
[ ! -e "$forbidden" ]

stage "public demo, visual QA, and independent validation"
sh "$REPO_ROOT/examples/public-demo/run_demo.sh" "$VERIFY_ROOT/public-demo"
"$PYTHON" -c \
  "import json; x=json.load(open('$VERIFY_ROOT/public-demo/visual-qa.json', encoding='utf-8')); assert x['status']=='review_required'; assert 'verified' not in open('$VERIFY_ROOT/public-demo/visual-qa.json', encoding='utf-8').read().lower()"
[ -s "$VERIFY_ROOT/public-demo/output.pdf" ]
[ -s "$VERIFY_ROOT/public-demo/validation-output.pdf" ]

stage "release manifest and archive"
"$RSCRIPT" \
  "$REPO_ROOT/skills/figureforge/scripts/build_release_manifest.R" \
  --output "$VERIFY_ROOT/release-manifest.csv"
"$RSCRIPT" "$REPO_ROOT/skills/figureforge/scripts/package_skill.R" \
  --archive "$VERIFY_ROOT/figureforge-skill-1.0.0.tar.gz" \
  --manifest "$VERIFY_ROOT/archive-manifest.csv"
"$RSCRIPT" -e \
  "a <- read.csv('$VERIFY_ROOT/release-manifest.csv', check.names=FALSE); b <- read.csv('$VERIFY_ROOT/archive-manifest.csv', check.names=FALSE); stopifnot(identical(a,b)); z <- system2('tar', c('-tzf', '$VERIFY_ROOT/figureforge-skill-1.0.0.tar.gz'), stdout=TRUE); z <- ifelse(startsWith(z, './'), substring(z, 3L), z); stopifnot(identical(sort(z), sort(a\$package_path)))"

stage "R parse, official Skill validation, and diff check"
find "$REPO_ROOT/skills/figureforge" \
  "$REPO_ROOT/tests/figureforge" \
  "$REPO_ROOT/examples/public-demo" \
  -type f -name '*.R' -print | sort |
while IFS= read -r r_file; do
  "$RSCRIPT" -e "parse(file='$r_file')" >/dev/null
done
"$PYTHON" \
  /Users/liuyue/.codex/skills/.system/skill-creator/scripts/quick_validate.py \
  "$REPO_ROOT/skills/figureforge"
git -C "$REPO_ROOT" diff --check

echo "FigureForge Skill v1.0 acceptance: PASS"
