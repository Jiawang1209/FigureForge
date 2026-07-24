# Gallery Index

The gallery index is FigureForge's local discovery layer. The private case
corpus is not committed; generate `case-index.csv` from the corpus available on
the current machine.

## Generate

```bash
/usr/local/bin/Rscript skills/figureforge/scripts/index_cases.R \
  skills/figureforge/cases \
  skills/figureforge/references/case-index.csv
```

The generated CSV is intentionally gitignored because paths and case metadata
may describe private assets.

## Search

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

The local audit completed a 15-case Skill MVP spanning grouped scatter,
bubble, volcano, PCA, fitted trends, ANOVA, donut, heatmap, time series,
bidirectional bars, phylogenetic annotations, network, seamless multi-panel,
and tree/domain/motif/gene-structure compositions. These remain private-only
unless separately approved for redistribution.

For full-corpus work, run `plan_case_batches.R` against a rendered audit. A
pending case may use `blocked_source_missing` or another supported blocker only
after the record passes `validate_blocker.R`; an unvalidated note remains
`terminal_outcome = pending`.
