# FigureForge Skill MVP Status

Date: 2026-07-25

## Outcome

The FigureForge Skill layer is implemented as a locally verifiable MVP. MCP
implementation remains paused.

## Evidence

| Acceptance area | Result |
| --- | --- |
| Private corpus audit | 165 real case directories classified independently |
| Completed representative cases | 35 private cases pass provenance, standard arguments, reproduction, QA, and fresh-render gates |
| Current corpus terminal counts | 35 completed, 0 blocked, 130 pending after a rendered 165-case audit |
| Visual coverage | grouped scatter, bubble, volcano, PCA, fitted trend, ANOVA, donut/sunburst, heatmap, time series, bidirectional bars, phylogeny, multi-ring tree annotation, GO circles, radar, network, genomic synteny, seamless multi-panel, and complex genomic annotations |
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

Complete-corpus Wave 1 added 20 fully verified cases. The current rendered
audit records 35 completed, 0 blocked, and 130 pending cases. The audit records
`terminal_outcome`; `blocked_source_missing` and the other supported blocker
categories require concrete evidence and never coexist with verified QA.

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
