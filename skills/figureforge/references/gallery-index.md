# Gallery Index

The tracked public gallery is FigureForge's default discovery layer. It
contains 12 redistributable cases under `public-cases/`; every dataset is a
declared synthetic fixture with `Status: review_required`.

## Public Search

```bash
/usr/local/bin/Rscript skills/figureforge/scripts/search_cases.R \
  --public \
  --query "相关性 热图 correlation" \
  --explain-scores \
  --limit 5
```

Add `--schema "<input.csv>"` to rank by required-role compatibility. The
deterministic tracked catalog is `references/public-case-index.csv`.

The 24 synthetic stress fixtures under `tests/fixtures/figureforge/stress`
exercise compatible and intentionally invalid adaptations. They are test
inputs, not gallery cases and not scientific evidence.

## Optional Private Index

Private cases are optional local extensions and are not committed. Generate
`case-index.csv` only from an explicitly available local corpus:

## Generate

```bash
/usr/local/bin/Rscript skills/figureforge/scripts/index_cases.R \
  skills/figureforge/cases \
  skills/figureforge/references/case-index.csv
```

The generated CSV is intentionally gitignored because paths and case metadata
may describe private assets.

Search that explicit private root separately:

```bash
/usr/local/bin/Rscript skills/figureforge/scripts/search_cases.R \
  --cases-dir skills/figureforge/cases \
  --query "相关性 热图 correlation" \
  --completed-only \
  --limit 5
```

Search matches the case ID, title, English and Chinese chart types, aliases,
scientific use, schema roles, and R packages. Completed cases receive a ranking
bonus, but scientific fit and schema compatibility still require inspection.

Public search uses the machine-readable `case.yml` taxonomy and reports score
components. Private search uses the legacy Markdown-derived local catalog.

## Index Fields

| Field | Meaning |
| --- | --- |
| `case_id` | Stable local folder name |
| `title` | Human-readable case title |
| `chart_type` | Primary chart family |
| `chart_type_zh` | Chinese chart family |
| `aliases` | Searchable English and Chinese aliases |
| `best_for` / `best_for_zh` | Scientific use in both languages |
| `required_columns` | Roles parsed from `## Data Schema` |
| `required_r_packages` | Packages declared by the case |
| `completion_status` | `raw`, `scaffolded`, `structured`, or `qa_verified` |
| `distribution_status` | `public_ready` or conservative `private_only` |
| `terminal_outcome` | Audit result: `completed`, `blocked`, or `pending` |
| `case_path` | Absolute local case path |
| `search_text` | Normalized discovery text |

## Selection Rule

Do not select by chart name alone. Compare candidates in this order:

1. scientific relationship and intended inference;
2. input shape and required roles;
3. statistics and annotations;
4. layout and visual grammar;
5. verified reproduction evidence;
6. installed dependencies;
7. distribution boundary.

An optional local audit records 152 completed cases: the 15-case Skill
MVP plus 137 verified cases from eight complete-corpus waves. In addition to the
original families, the verified private set now includes multi-track GO
circles, fan trees with five bar rings, aligned tree/composition panels,
annotated phenotype heatmaps, radar small multiples, grouped bubble matrices,
sunbursts, and genomic synteny circles. It also includes promoter matrices,
STRING PPI networks, PCoA/NMDS, alluvial composition, qRT-PCR, symmetric bars,
grouped heatmaps, enrichment bubbles, additional phylogeny layouts, raincloud
and violin distributions, functional-gene bidirectional bars, circular
lollipops, Sankey flow, marker heatmaps, dual-axis and paired-subject panels,
advanced volcano plots, chromosome ideograms, radar profiles, and world
sampling maps. The corpus
also contains PCA with marginal statistics, treemaps, fan glyphs, additional
GO/KEGG and gene-family layouts, promoter matrices, expression heatmaps,
qRT-PCR, paired trees, a source-recovered Nature Microbiology tree, pie-node
networks, taxonomy circle packing, Venn diagrams, double-hub networks,
four-panel correlation/significance matrices, and rotated triangle heatmaps.
The corpus has 13 validated blockers: 6 `blocked_source_missing`, 4
`blocked_visual_reference`, and 3 `blocked_ambiguous_mapping`; zero cases
remain pending. All 165 remain private-only unless separately approved for
redistribution.

For full-corpus work, run `plan_case_batches.R` against a rendered audit. A
pending case may use `blocked_source_missing` or another supported blocker only
after the record passes `validate_blocker.R`; an unvalidated note remains
`terminal_outcome = pending`.

Automated search and execution evidence do not constitute human visual QA.
