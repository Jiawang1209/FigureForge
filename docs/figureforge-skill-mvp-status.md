# FigureForge Skill MVP Status

Date: 2026-07-25

## Outcome

The FigureForge Skill layer is implemented as a locally verifiable MVP. MCP
implementation remains paused.

## Evidence

| Acceptance area | Result |
| --- | --- |
| Private corpus audit | 165 real case directories classified independently |
| Completed representative cases | 142 private cases pass provenance, standard arguments, reproduction, QA, and fresh-render gates |
| Current corpus terminal counts | 142 completed, 13 validated blockers, 10 pending after a rendered 165-case audit |
| Visual coverage | grouped scatter, bubble, expression-aware volcano, Manhattan, PCA/PCoA/NMDS/UMAP, fitted trend, ANOVA, box/violin/raincloud, donut/sunburst, heatmap, time series and confidence bands, bidirectional and circular bars, dual axes, paired trajectories, phylogeny and taxonomy trees, multi-ring tree annotation, GO circles and reordered labels, enrichment composites, radar, alluvial/Sankey, STRING PPI and custom microbial networks, WGCNA module dendrograms, chromosome ideograms and nucleotide tracks, promoter matrices, genomic synteny, world sampling maps, correlation/Mantel connectors, seamless multi-panel, and complex genomic annotations |
| New-data migration | 3 different public R datasets migrated to 3 chart families |
| Skill package | standard metadata, end-to-end workflow, references, template, and official package validation |
| Public tooling | discovery, index, dependency check, render, case validation, adaptation validation, and corpus audit |
| Distribution | all local completed cases remain `private_only`; generated audit and adaptation artifacts remain ignored |

## Public Skill Commands

```bash
/usr/local/bin/Rscript skills/figureforge/scripts/search_cases.R \
  --query "<terms>" --completed-only

/usr/local/bin/Rscript skills/figureforge/scripts/check_dependencies.R \
  --case-dir "<case_dir>" --strict

/usr/local/bin/Rscript skills/figureforge/scripts/render_case.R \
  "<case_dir>" --input "<input_csv>" --output "<output_path>"

/usr/local/bin/Rscript skills/figureforge/scripts/validate_case.R \
  "<case_dir>" --complete --render --output "<external_output>"

/usr/local/bin/Rscript skills/figureforge/scripts/validate_adaptation.R \
  "<adaptation_dir>" --render --output "<external_output>"

/usr/local/bin/Rscript skills/figureforge/scripts/validate_blocker.R \
  "<case_dir>"

/usr/local/bin/Rscript skills/figureforge/scripts/plan_case_batches.R \
  --readiness "<case-readiness.csv>" \
  --output "<batch-manifest.csv>" \
  --batch-size 20
```

Complete-corpus Waves 1 through 7 added 127 fully verified cases and classified
13 cases with validated blockers. The current rendered audit records 142
completed, 13 blocked, and 10 pending cases. Blockers currently comprise 6
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

MCP work remains paused until all 165 cases have been processed and the Skill
and corpus pass final acceptance. It should then begin from these verified
contracts, not from assumptions about the private corpus.
