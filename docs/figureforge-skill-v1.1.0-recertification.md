# FigureForge Skill 1.1.0 Recertification Procedure

Use this procedure only after all release-input work is committed and the
intended source HEAD is stable. Every certification must bind fresh evidence
to that exact committed source.

## Certification identity

`certification-identity.tsv` is the machine-readable currentness record. It
binds:

- the committed source commit and complete Git tree;
- a SHA-256 over every packaged source file plus the deterministic verifier,
  live harnesses, and certification machinery;
- the release manifest row count, byte count, and SHA-256; and
- the exact run-specific archive byte count and SHA-256; and
- the SHA-256 of the validated trigger, plotting, and two-mode live summaries.

The manifest remains the portable package identity. The archive identity is
also retained because gzip/tar bytes may vary between otherwise equivalent
packaging runs.

The checker rejects a missing identity, an unreachable or tree-mismatched
source commit, changed release inputs, or a changed manifest identity. It does
not silently inherit the historical v1.1.0 certification.

## Required inputs

Before starting, obtain:

1. the final committed source HEAD;
2. a clean worktree for every release-input path;
3. the output directory from a successful deterministic v1.1.0 verifier run;
4. its manifest, archive, and archive SHA-256 sidecar; and
5. fresh live-trigger, plotting, and generation-mode gate outputs when the
   release claim includes live-model behavior.

Do not copy a commit, tree, manifest hash, archive hash, row count, or byte
count from an older evidence bundle.

## Exact procedure

From the repository root:

```bash
test -z "$(git status --porcelain)"
SOURCE_COMMIT="$(git rev-parse HEAD)"
SOURCE_TREE="$(git rev-parse HEAD^{tree})"

VERIFY_ROOT="$(mktemp -d /tmp/figureforge-v110-recert.XXXXXX)"
FIGUREFORGE_RUN_LIVE_EVALS=0 \
FIGUREFORGE_V110_OUTPUT_DIR="$VERIFY_ROOT" \
  /bin/sh scripts/verify_figureforge_v110.sh

MANIFEST="$VERIFY_ROOT/figureforge-skill-1.1.0-manifest.csv"
ARCHIVE="$VERIFY_ROOT/figureforge-skill-1.1.0.tar.gz"
test -s "$MANIFEST"
test -s "$ARCHIVE"
test -s "$ARCHIVE.sha256"
```

Run the live gates from the same `SOURCE_COMMIT` before claiming fresh live
certification:

```bash
LIVE_ROOT="$(mktemp -d /tmp/figureforge-v110-live-recert.XXXXXX)"
bash scripts/run_figureforge_live_evals.sh \
  --output-dir "$LIVE_ROOT/triggers"
bash scripts/run_figureforge_plotting_eval.sh \
  --output-dir "$LIVE_ROOT/plotting"
bash scripts/run_figureforge_mode_evals.sh \
  --output-dir "$LIVE_ROOT/modes"
test -s "$LIVE_ROOT/triggers/summary.csv"
test -s "$LIVE_ROOT/plotting/summary.csv"
test -s "$LIVE_ROOT/modes/summary.csv"
cmp "$LIVE_ROOT/triggers/release-manifest.csv" \
  "$LIVE_ROOT/plotting/release-manifest.csv"
cmp "$LIVE_ROOT/triggers/release-manifest.csv" \
  "$LIVE_ROOT/modes/release-manifest.csv"
test "$(git rev-parse HEAD)" = "$SOURCE_COMMIT"
test "$(git rev-parse HEAD^{tree})" = "$SOURCE_TREE"

/usr/local/bin/Rscript \
  scripts/write_figureforge_v110_certification_identity.R \
  --manifest "$LIVE_ROOT/modes/release-manifest.csv" \
  --archive "$LIVE_ROOT/modes/figureforge-skill.tar.gz" \
  --live-trigger-summary "$LIVE_ROOT/triggers/summary.csv" \
  --live-plotting-summary "$LIVE_ROOT/plotting/summary.csv" \
  --live-mode-summary "$LIVE_ROOT/modes/summary.csv" \
  --output \
  docs/figureforge-skill-v1.1.0-evidence/certification-identity.tsv
```

Require explicit 1/1 and implicit 10/10 trigger passes, one plotting pass, and
both mode passes (`case_based`/`case_grounded` and
`general_fallback`/`general_method`). Generate the certification identity from
one of these gates only after confirming that all three manifests are
byte-identical.

Regenerate the portable evidence summaries from those exact outputs. Update
`source-binding.tsv`, `commands.tsv`, package and artifact identities,
sanitized trigger, plotting, and mode logs, and then regenerate `SHA256SUMS` for
every evidence file except `SHA256SUMS` itself. Never edit hashes by hand and
never mix runs from different source commits.

Before changing README or status wording from “pending recertification” to
“currently certified”, run:

```bash
/usr/local/bin/Rscript \
  scripts/check_figureforge_v110_certification.R
```

The command must exit zero and print `certification identity: CURRENT`. Commit
the regenerated evidence and documentation. A documentation-only commit may
follow the certified source commit because currentness is bound to the release
inputs and manifest, not to unrelated prose. Run the checker and the full
deterministic verifier once more after that documentation commit.

If any release input changes, discard the candidate identity and restart from
the deterministic verifier. A partial refresh is not certification.
