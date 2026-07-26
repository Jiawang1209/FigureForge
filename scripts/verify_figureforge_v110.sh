#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
PYTHON=${FIGUREFORGE_PYTHON:-/usr/bin/python3}
SKILL_VALIDATOR=${FIGUREFORGE_SKILL_VALIDATOR:-/Users/liuyue/.codex/skills/.system/skill-creator/scripts/quick_validate.py}
RUN_LIVE=${FIGUREFORGE_RUN_LIVE_EVALS:-0}

stage() {
  printf '\n==> %s\n' "$1"
}

resolve_rscript() {
  if [ -n "${FIGUREFORGE_RSCRIPT:-}" ]; then
    if [ ! -x "$FIGUREFORGE_RSCRIPT" ]; then
      echo "FIGUREFORGE_RSCRIPT is not executable: $FIGUREFORGE_RSCRIPT" >&2
      return 1
    fi
    printf '%s\n' "$FIGUREFORGE_RSCRIPT"
    return
  fi
  if [ -x /usr/local/bin/Rscript ]; then
    printf '%s\n' /usr/local/bin/Rscript
    return
  fi
  resolved=$(command -v Rscript || true)
  if [ -z "$resolved" ] || [ ! -x "$resolved" ]; then
    echo "Unable to resolve Rscript from compatibility path or PATH" >&2
    return 1
  fi
  printf '%s\n' "$resolved"
}

RSCRIPT=$(resolve_rscript)
export FIGUREFORGE_RSCRIPT="$RSCRIPT"
export FIGUREFORGE_PYTHON="$PYTHON"
export FIGUREFORGE_SKILL_VALIDATOR="$SKILL_VALIDATOR"

if [ ! -x "$PYTHON" ]; then
  echo "Python runtime is unavailable: $PYTHON" >&2
  exit 1
fi
if [ ! -f "$SKILL_VALIDATOR" ]; then
  echo "Official Skill validator is unavailable: $SKILL_VALIDATOR" >&2
  exit 1
fi

if [ -n "${FIGUREFORGE_V110_OUTPUT_DIR:-}" ]; then
  VERIFY_ROOT=$FIGUREFORGE_V110_OUTPUT_DIR
  if [ -e "$VERIFY_ROOT" ] &&
      [ -n "$(find "$VERIFY_ROOT" -mindepth 1 -maxdepth 1 -print -quit)" ]; then
    echo "Verification output directory must be empty: $VERIFY_ROOT" >&2
    exit 1
  fi
  mkdir -p "$VERIFY_ROOT"
else
  VERIFY_ROOT=$(mktemp -d /tmp/figureforge-v110.XXXXXX)
fi

PUBLIC_CASES="$REPO_ROOT/skills/figureforge/public-cases"
STRESS_FIXTURES="$REPO_ROOT/tests/fixtures/figureforge/stress"
EVAL_CATALOG="$REPO_ROOT/skills/figureforge/references/trigger-evals-v1.csv"
ARCHIVE="$VERIFY_ROOT/figureforge-skill-1.1.0.tar.gz"
MANIFEST="$VERIFY_ROOT/figureforge-skill-1.1.0-manifest.csv"
CHECKSUM="$ARCHIVE.sha256"
INSTALL_ROOT="$VERIFY_ROOT/installed-project/.agents/skills"
INSTALLED="$INSTALL_ROOT/figureforge"

stage "FigureForge R tests (excluding recursive acceptance and named upgrade gates)"
for test_file in "$REPO_ROOT"/tests/figureforge/*.R; do
  case "$(basename "$test_file")" in
    test_v1_acceptance.R|test_upgrade_compatibility.R)
      continue
      ;;
  esac
  "$RSCRIPT" "$test_file"
done

stage "15 public cases with external fresh renders"
mkdir -p "$VERIFY_ROOT/public-renders"
case_count=0
for case_dir in "$PUBLIC_CASES"/*; do
  [ -d "$case_dir" ] || continue
  case_id=$(basename "$case_dir")
  "$RSCRIPT" \
    "$REPO_ROOT/skills/figureforge/scripts/validate_public_case.R" \
    "$case_dir" \
    --render \
    --output "$VERIFY_ROOT/public-renders/$case_id.pdf" \
    --rscript "$RSCRIPT"
  case_count=$((case_count + 1))
done
[ "$case_count" -eq 15 ]

stage "24 synthetic stress fixtures"
"$RSCRIPT" "$REPO_ROOT/skills/figureforge/scripts/run_stress_tests.R" \
  --fixtures "$STRESS_FIXTURES" \
  --public-cases "$PUBLIC_CASES" \
  --output-dir "$VERIFY_ROOT/stress-renders" \
  --report "$VERIFY_ROOT/stress-report.csv" \
  --rscript "$RSCRIPT"
FIGUREFORGE_STRESS_REPORT="$VERIFY_ROOT/stress-report.csv" \
  "$RSCRIPT" -e \
  'x<-read.csv(Sys.getenv("FIGUREFORGE_STRESS_REPORT")); stopifnot(nrow(x)==24L, all(x$passed))'

stage "30 deterministic bilingual forward evaluations"
"$RSCRIPT" "$REPO_ROOT/skills/figureforge/scripts/evaluate_skill.R" \
  --catalog "$EVAL_CATALOG" \
  --output-dir "$VERIFY_ROOT/forward-renders" \
  --report "$VERIFY_ROOT/forward-report.csv" \
  --rscript "$RSCRIPT"
FIGUREFORGE_FORWARD_REPORT="$VERIFY_ROOT/forward-report.csv" \
  "$RSCRIPT" -e \
  'x<-read.csv(Sys.getenv("FIGUREFORGE_FORWARD_REPORT")); stopifnot(nrow(x)==30L, all(x$passed))'

stage "doctor text and JSON"
"$RSCRIPT" "$REPO_ROOT/skills/figureforge/scripts/doctor.R" \
  >"$VERIFY_ROOT/doctor.txt"
"$RSCRIPT" "$REPO_ROOT/skills/figureforge/scripts/doctor.R" \
  --format json >"$VERIFY_ROOT/doctor.json"
FIGUREFORGE_DOCTOR_JSON="$VERIFY_ROOT/doctor.json" \
  "$PYTHON" -c \
  'import json, os; x=json.load(open(os.environ["FIGUREFORGE_DOCTOR_JSON"], encoding="utf-8")); assert any(c["check_id"]=="runtime-rscript" and c["status"]=="pass" for c in x["checks"])'

stage "archive, manifest, and SHA-256 sidecar"
"$RSCRIPT" "$REPO_ROOT/skills/figureforge/scripts/package_skill.R" \
  --archive "$ARCHIVE" \
  --manifest "$MANIFEST"
[ -s "$ARCHIVE" ]
[ -s "$MANIFEST" ]
[ -s "$CHECKSUM" ]
grep -Eq "^[0-9a-f]{64}  $(basename "$ARCHIVE")$" "$CHECKSUM"

stage "strict archive verification and extraction"
"$RSCRIPT" "$REPO_ROOT/skills/figureforge/scripts/verify_release.R" \
  --archive "$ARCHIVE" \
  --manifest "$MANIFEST" \
  --extract-dir "$INSTALL_ROOT"
[ -s "$INSTALLED/SKILL.md" ]
[ "$(sed -n '1p' "$INSTALLED/VERSION")" = "1.1.0" ]

stage "installed official validation, doctor, search, demo, and rerender"
"$PYTHON" "$SKILL_VALIDATOR" "$INSTALLED"

# Packaging/CLI smoke only: use a shipped public case and an external workspace.
# Copying its script proves installed evidence and executable anchors resolve;
# behavioral forward evaluation remains the responsibility of the eval stages.
INSTALLED_CASE_DIR="$INSTALLED/public-cases/public-correlation-heatmap"
INSTALLED_CASE_WORKSPACE="$VERIFY_ROOT/installed-case-trace-workspace"
INSTALLED_CASE_TRACE="$INSTALLED_CASE_WORKSPACE/.figureforge/case-trace.yml"
INSTALLED_CASE_SEARCH="$INSTALLED_CASE_WORKSPACE/.figureforge/case-search.csv"
INSTALLED_CASE_SEARCH_SCHEMA="$INSTALLED_CASE_WORKSPACE/search-schema.csv"
INSTALLED_CASE_SCRIPT="$INSTALLED_CASE_WORKSPACE/plot.R"
INSTALLED_CASE_TRACE_LOG="$VERIFY_ROOT/installed-case-trace.log"
mkdir -p "$INSTALLED_CASE_WORKSPACE/.figureforge"
cp "$INSTALLED_CASE_DIR/plot.R" "$INSTALLED_CASE_SCRIPT"
{
  echo "variable_x,variable_y,correlation"
  echo "a,b,0.5"
} >"$INSTALLED_CASE_SEARCH_SCHEMA"
installed_sha256() {
  FIGUREFORGE_CHECKSUMS_R="$INSTALLED/lib/checksums.R" \
    FIGUREFORGE_HASH_FILE="$1" \
    "$RSCRIPT" -e \
    'source(Sys.getenv("FIGUREFORGE_CHECKSUMS_R")); cat(figureforge_sha256(Sys.getenv("FIGUREFORGE_HASH_FILE")))'
}
installed_generated_sha=$(
  installed_sha256 "$INSTALLED_CASE_SCRIPT"
)
installed_case_md_sha=$(
  installed_sha256 "$INSTALLED_CASE_DIR/case.md"
)
installed_plot_r_sha=$(
  installed_sha256 "$INSTALLED_CASE_DIR/plot.R"
)
installed_qa_md_sha=$(
  installed_sha256 "$INSTALLED_CASE_DIR/qa.md"
)
"$RSCRIPT" "$INSTALLED/scripts/search_cases.R" \
  --public \
  --query "correlation heatmap" \
  --schema "$INSTALLED_CASE_SEARCH_SCHEMA" \
  --limit 5 \
  --output "$INSTALLED_CASE_SEARCH"
installed_search_sha=$(
  installed_sha256 "$INSTALLED_CASE_SEARCH"
)
{
  echo "schema_version: 1"
  echo "generation_mode: case_based"
  echo "figureforge_version: 1.1.0"
  echo "generated_script_sha256: $installed_generated_sha"
  echo "claim: case_grounded"
  echo "search_query: correlation heatmap"
  echo "search_receipt_file: case-search.csv"
  echo "search_receipt_sha256: $installed_search_sha"
  echo "primary_case_id: public-correlation-heatmap"
  echo "case_md_file: case.md"
  echo "case_md_sha256: $installed_case_md_sha"
  echo "plot_r_file: plot.R"
  echo "plot_r_sha256: $installed_plot_r_sha"
  echo "schema_mapping: variable_x -> variable_x; variable_y -> variable_y; correlation -> correlation"
  echo "adopted_patterns: case.md#Diverging fill encodes sign and magnitude => plot.R#ggplot2::scale_fill_gradient2"
  echo "departures: none; copied public case script for installed CLI packaging smoke"
  echo "qa_md_file: qa.md"
  echo "qa_md_sha256: $installed_qa_md_sha"
  echo "qa_status: review_required"
} >"$INSTALLED_CASE_TRACE"
"$RSCRIPT" "$INSTALLED/scripts/validate_case_trace.R" \
  "$INSTALLED_CASE_TRACE" \
  --case-dir "$INSTALLED_CASE_DIR" \
  --script "$INSTALLED_CASE_SCRIPT" \
  >"$INSTALLED_CASE_TRACE_LOG" 2>&1
grep -F "Verification level: strict" "$INSTALLED_CASE_TRACE_LOG"
grep -F "Case trace validation OK:" "$INSTALLED_CASE_TRACE_LOG"

"$RSCRIPT" "$INSTALLED/scripts/doctor.R" \
  --format text >"$VERIFY_ROOT/installed-doctor.txt"
"$RSCRIPT" "$INSTALLED/scripts/search_cases.R" \
  --public \
  --query "相关性热图" \
  --limit 3 \
  --output "$VERIFY_ROOT/installed-search.csv"
FIGUREFORGE_SEARCH_REPORT="$VERIFY_ROOT/installed-search.csv" \
  "$RSCRIPT" -e \
  'x<-read.csv(Sys.getenv("FIGUREFORGE_SEARCH_REPORT")); stopifnot(x$case_id[[1L]]=="public-correlation-heatmap")'
sh "$INSTALLED/examples/public-demo/run_demo.sh" \
  "$VERIFY_ROOT/installed-demo"
"$RSCRIPT" "$INSTALLED/scripts/validate_adaptation.R" \
  "$VERIFY_ROOT/installed-demo" \
  --render \
  --output "$VERIFY_ROOT/installed-independent-rerender.pdf" \
  --rscript "$RSCRIPT"
[ -s "$VERIFY_ROOT/installed-demo/output.pdf" ]
[ -s "$VERIFY_ROOT/installed-independent-rerender.pdf" ]

stage "v1.0.0 to current-version upgrade compatibility"
"$RSCRIPT" "$REPO_ROOT/tests/figureforge/test_upgrade_compatibility.R"

if [ "$RUN_LIVE" = "1" ]; then
  stage "bounded live trigger probes"
  bash "$REPO_ROOT/scripts/run_figureforge_live_evals.sh" \
    --output-dir "$VERIFY_ROOT/live-trigger-evals"
  stage "bounded executable plotting artifact probe"
  bash "$REPO_ROOT/scripts/run_figureforge_plotting_eval.sh" \
    --output-dir "$VERIFY_ROOT/live-plotting-eval"
else
  stage "bounded live probes skipped"
  echo "Set FIGUREFORGE_RUN_LIVE_EVALS=1 to run both the installed trigger and executable plotting artifact gates."
fi

stage "parse every tracked public R file"
git -C "$REPO_ROOT" ls-files '*.R' |
while IFS= read -r relative_r; do
  case "$relative_r" in
    skills/figureforge/cases/*)
      case "$relative_r" in
        skills/figureforge/cases/_template/*) ;;
        *)
          echo "Private case R file is tracked: $relative_r" >&2
          exit 1
          ;;
      esac
      ;;
  esac
  FIGUREFORGE_R_FILE="$REPO_ROOT/$relative_r" \
    "$RSCRIPT" -e \
    'parse(file=Sys.getenv("FIGUREFORGE_R_FILE"))' >/dev/null
done

stage "tracked and packaged private/generated boundary"
boundary_hits=$(
  git -C "$REPO_ROOT" ls-files |
  awk '
    /^outputs\// { print; next }
    /(^|\/)(reproduction|original)\./ { print; next }
    /^skills\/figureforge\/cases\// &&
      $0 !~ /^skills\/figureforge\/cases\/_template\// { print }
  '
)
if [ -n "$boundary_hits" ]; then
  echo "Forbidden tracked files:" >&2
  echo "$boundary_hits" >&2
  exit 1
fi
FIGUREFORGE_MANIFEST="$MANIFEST" \
  "$RSCRIPT" -e \
  'x<-read.csv(Sys.getenv("FIGUREFORGE_MANIFEST"),stringsAsFactors=FALSE,check.names=FALSE); stopifnot(!any(grepl("^skills/figureforge/cases/(?!_template/)",x$source_path,perl=TRUE)), !any(grepl("^outputs/|[.]log$|(^|/)(reproduction|original)[.]",x$source_path,perl=TRUE)))'
tar -tzf "$ARCHIVE" >"$VERIFY_ROOT/archive-list.txt"
archive_boundary_hits=$(
  awk '
    /(^|\/)outputs\// { print; next }
    /(^|\/)(reproduction|original)\./ { print; next }
    /^figureforge\/cases\// &&
      $0 !~ /^figureforge\/cases\/_template\// { print }
  ' "$VERIFY_ROOT/archive-list.txt"
)
if [ -n "$archive_boundary_hits" ]; then
  echo "Forbidden release archive member detected" >&2
  echo "$archive_boundary_hits" >&2
  exit 1
fi
[ ! -d "$INSTALLED/skills" ]

stage "official source validation and git diff"
"$PYTHON" "$SKILL_VALIDATOR" "$REPO_ROOT/skills/figureforge"
(cd "$REPO_ROOT" && git diff --check)

printf '\nVerification artifacts: %s\n' "$VERIFY_ROOT"
echo "FigureForge Skill v1.1.0 acceptance: PASS"
