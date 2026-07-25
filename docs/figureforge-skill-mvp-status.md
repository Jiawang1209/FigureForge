# FigureForge Skill MVP Status

Date: 2026-07-25

## Outcome

FigureForge Skill 1.0.1 is a locally certified, independently usable release
candidate. The complete private corpus remains a local optional extension.
MCP remains planned and unimplemented.

## Evidence

| Acceptance area | Result |
| --- | --- |
| Public gallery | 15 public cases: 3 authentic open-data cases with verified provenance/QA and 12 synthetic demonstration cases |
| Stress suite | 24 synthetic stress fixtures across all 12 public families |
| Forward evaluation | 30 deterministic English/Chinese rows; Top-1, Top-3, mapping, render, and safe rejection all passed |
| Live trigger gate | Explicit 1/1; implicit 10/10, exceeding the 100% and 90% thresholds |
| Public workflow | doctor, bilingual search, schema match, protected workspace, render, visual QA, and independent validation |
| Public packaging | install-shaped archive, manifest, SHA-256 sidecar, structural verifier, and per-member checksum validation |
| Upgrade | v1.0.0 is atomically replaced by v1.0.1 without stale files; preserved external adaptation hashes and independent rerender pass |
| Private corpus audit | 165 real case directories classified independently |
| Completed representative cases | 152 private cases pass provenance, standard arguments, reproduction, QA, and fresh-render gates |
| Current corpus terminal counts | 152 completed, 13 validated blockers, 0 pending after a rendered 165-case audit |
| Visual coverage | grouped scatter, bubble, expression-aware volcano, Manhattan, PCA/PCoA/NMDS/UMAP, fitted trend, ANOVA, box/violin/raincloud, donut/sunburst, heatmap, time series and confidence bands, bidirectional and circular bars, dual axes, paired trajectories, phylogeny and taxonomy trees, multi-ring tree annotation, GO circles and reordered labels, enrichment composites, radar, alluvial/Sankey, STRING PPI and custom microbial networks, WGCNA module dendrograms, chromosome ideograms and nucleotide tracks, promoter matrices, genomic synteny, world sampling maps, correlation/Mantel connectors, seamless multi-panel, and complex genomic annotations |
| New-data migration | 3 different public R datasets migrated to 3 chart families |
| Skill package | `.agents/skills/figureforge` layout, standard metadata, packaged demo, and official installed-package validation |
| Public tooling | discovery, index, dependency check, render, case validation, adaptation validation, and corpus audit |
| Distribution | all local completed cases remain `private_only`; generated audit and adaptation artifacts remain ignored |

## Public Skill Commands

```bash
export FIGUREFORGE_RSCRIPT="${FIGUREFORGE_RSCRIPT:-Rscript}"

"$FIGUREFORGE_RSCRIPT" skills/figureforge/scripts/search_cases.R \
  --public --query "<terms>"

"$FIGUREFORGE_RSCRIPT" skills/figureforge/scripts/doctor.R \
  --case "<public-case-id>" --strict

"$FIGUREFORGE_RSCRIPT" skills/figureforge/scripts/match_schema.R \
  --case "<public-case-id>" --input "<input_csv>" --output "<match.csv>"

"$FIGUREFORGE_RSCRIPT" skills/figureforge/scripts/create_adaptation.R \
  --case "<public-case-id>" --input "<input_csv>" \
  --workspace "<external_adaptation>"

"$FIGUREFORGE_RSCRIPT" skills/figureforge/scripts/visual_qa.R \
  --render "<external_adaptation>/output.pdf" \
  --report "<external_report>/visual-qa.json"

"$FIGUREFORGE_RSCRIPT" skills/figureforge/scripts/package_skill.R \
  --archive /tmp/figureforge-skill-1.0.1.tar.gz \
  --manifest /tmp/figureforge-skill-1.0.1-manifest.csv

"$FIGUREFORGE_RSCRIPT" skills/figureforge/scripts/verify_release.R \
  --archive /tmp/figureforge-skill-1.0.1.tar.gz \
  --manifest /tmp/figureforge-skill-1.0.1-manifest.csv

"$FIGUREFORGE_RSCRIPT" skills/figureforge/scripts/evaluate_skill.R \
  --catalog skills/figureforge/references/trigger-evals-v1.csv \
  --output-dir /tmp/figureforge-evals \
  --report /tmp/figureforge-evals.csv \
  --rscript "$FIGUREFORGE_RSCRIPT"

sh examples/public-demo/run_demo.sh "<external_demo_output>"
```

Complete-corpus Waves 1 through 8 added 137 fully verified cases and classified
13 cases with validated blockers. The final rendered audit records 152
completed, 13 blocked, and 0 pending cases. Blockers comprise 6
`blocked_source_missing`, 4 `blocked_visual_reference`, and 3
`blocked_ambiguous_mapping`. The audit records `terminal_outcome`; every
supported blocker category requires concrete evidence and never coexists with
verified QA.

## New-Data Proofs

The ignored local directory `outputs/figureforge-adaptations/` contains:

1. `HairEyeColor` adapted to a three-strategy donut composition;
2. `USArrests` adapted to a signed correlation bubble heatmap;
3. `ChickWeight` adapted to four longitudinal diet trajectories with t-based
   confidence ribbons and an inset.

Each proof includes `input.csv`, `mapping.md`, migrated `plot.R`, `qa.md`,
`output.pdf`, a preview, and an independently generated validation PDF.

## MCP Input Boundary

The future local-first MCP layer may wrap the stable public commands and return
their structured results. It must:

- accept an explicit local case-root path;
- preserve the independent readiness and distribution fields;
- never return or package private data, source figures, or reproductions by
  default;
- render only to an explicit output workspace outside the source case;
- expose planned capability as planned until executable tools and tests exist.

All 165 private cases have now been processed and the Skill/corpus acceptance
boundary is stable. The public v1.0.1 release adds only reviewed public assets;
private cases remain local. MCP work has not started; any future implementation
must begin as a separate task from these verified contracts, not from
assumptions about the private corpus.
