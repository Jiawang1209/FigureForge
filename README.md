# FigureForge

**An AI-ready, reproducible, case-based skillbase for publication-ready scientific visualization.**

> From reproduction to adaptation.

English · [简体中文](README.zh.md)

FigureForge turns real publication-figure reproductions into reusable, AI-driven plotting workflows. Each case connects a reference image, reproducible data, plotting code, adaptation notes, and QA rules — so an AI agent (or a human) can pick the closest example and adapt it to a brand-new scientific dataset instead of prompting a model to invent a figure from scratch.

The first release is **R / ggplot2 first**, built from a long-running figure-reproduction series (*在模仿中精进数据可视化*). Python support is planned once the R workflow stabilizes.

---

## Why FigureForge

Generic "make a Nature-style figure" prompts give you a guess. FigureForge gives you **evidence**:

- **Case-based selection** — start from a real figure that already works, not a blank prompt.
- **Real code adaptation** — reuse a concrete, reproducible `plot.R`, not synthesized boilerplate.
- **Data-schema mapping** — map your columns onto a documented case schema.
- **Visual QA** — verify the result against a reference reproduction and a checklist.
- **Bilingual by design** — case metadata and search keywords include Chinese chart names and aliases (`柱状图`, `箱线图`, `小提琴图`, `散点图`, `折线图`, `热图`, `分面图`, `多面板`, …).

The asset is not a single instruction file — it's the accumulated gallery of examples, data, scripts, and metadata.

## How it works

```
Your goal + data  ─▶  search gallery  ─▶  pick closest case  ─▶  map columns
                                                                      │
                  publication-ready figure  ◀─  QA checklist  ◀─  adapt plot.R
```

An AI agent driving the `figureforge` skill will:

1. Inspect the scientific goal and the actual input schema.
2. Search case metadata in English or Chinese and prioritize completed cases.
3. Open the case's `case.md`, `data.csv`, `plot.R`, and `qa.md`
   **before editing**.
4. Check dependencies and build an explicit field-mapping record.
5. Adapt the real case-specific script in a workspace outside the private
   corpus.
6. Render, visually review, and independently re-render with the adaptation
   validator.
7. Report the selected case, mapping, commands, outputs, QA, distribution
   boundary, and remaining limits.

## Skill + MCP product direction

FigureForge is designed to grow into a **Skill + MCP dual-layer product**:

- **Skill layer** — teaches AI agents the case-based workflow: choose a real example, inspect its metadata and code, map the user's data schema, adapt the plotting script, render, and QA the result.
- **MCP layer** — exposes FigureForge as callable tools for other agents, so they can discover cases, inspect metadata, validate case structure, rebuild indexes, render figures, and draft column mappings without manually parsing the repository.

Planned MCP tools include:

- `figureforge_health`
- `figureforge_list_cases`
- `figureforge_search_cases`
- `figureforge_get_case`
- `figureforge_validate_case`
- `figureforge_build_index`
- `figureforge_render_case`
- `figureforge_suggest_mapping`

The MCP server should be **local-first**: it can use a private local case corpus, while public releases should include only redistributable cases and assets. See [`docs/superpowers/specs/2026-07-07-figureforge-skill-mcp-dual-layer-design.md`](docs/superpowers/specs/2026-07-07-figureforge-skill-mcp-dual-layer-design.md) and [`docs/superpowers/plans/2026-07-07-figureforge-skill-mcp-dual-layer.md`](docs/superpowers/plans/2026-07-07-figureforge-skill-mcp-dual-layer.md) for the full design and implementation plan.

## Repository layout

```text
FigureForge/
├── README.md
├── PROJECT_HANDOFF.md            # vision, positioning, and roadmap
├── docs/superpowers/            # design spec and implementation plan
└── skills/figureforge/
    ├── SKILL.md                 # skill entrypoint and workflow
    ├── references/              # gallery index + reusable guidance
    │   ├── gallery-index.md     # case navigation, metadata fields, aliases
    │   ├── data-mapping.md      # column mapping & Chinese field handling
    │   ├── ggplot-patterns.md   # recurring ggplot2 components
    │   ├── theme-and-export.md  # publication export expectations
    │   └── qa-checklist.md      # final verification checklist
    ├── cases/                   # case corpus (see note below)
    │   └── _template/           # format guide — NOT a curated case
    └── scripts/                 # R helpers (validate / render / index)
```

### A note on the case corpus

This repository ships the **skill framework** — the workflow, references, helper scripts, and a case template. The full curated case corpus (165+ figure reproductions) lives in `skills/figureforge/cases/` locally but is **gitignored and private by default**, since many cases include third-party reference figures and source data that can't be redistributed.

If you clone this repo, you get everything needed to run the workflow and author your own cases; the original figures and proprietary data are not included.

## Case format

Each real case is a self-contained folder:

```text
skills/figureforge/cases/<case-id>/
├── case.md            # metadata + adaptation notes (required)
├── data.csv           # plotting data (required)
├── plot.R             # reproducible plotting script (required)
├── reproduction.pdf   # / .png — our reproduction, when available
├── qa.md               # explicit verification record for completed cases
├── distribution.yml    # optional; absent means private_only
└── original.png       # reference image, only if redistribution is allowed
```

`case.md` follows a fixed set of headings so it stays machine-readable and consistent across cases:

```text
## Chart Type            ## Visual Encoding
## Chart Type Chinese    ## ggplot Components
## Aliases               ## Adaptation Notes
## Best For              ## Common Pitfalls
## Best For Chinese
## Data Provenance
## Data Schema
## Required R Packages
```

See `skills/figureforge/cases/_template/case.md` for the canonical template. The `_template` folder is a format guide, **not** a curated figure reproduction.

## Helper scripts

Run the R workflow from the repository root with
`/usr/local/bin/Rscript`:

```bash
# Validate a case folder has the required files and case.md headings
/usr/local/bin/Rscript skills/figureforge/scripts/validate_case.R <case_dir>

# Search English/Chinese metadata and schema roles
/usr/local/bin/Rscript skills/figureforge/scripts/search_cases.R \
  --query "correlation heatmap" --completed-only

# Rebuild the machine-readable case index (CSV)
/usr/local/bin/Rscript skills/figureforge/scripts/index_cases.R \
  [cases_dir] [output_csv]

# Check every dependency declared by one case
/usr/local/bin/Rscript skills/figureforge/scripts/check_dependencies.R \
  --case-dir <case_dir> --strict

# Render a case or a new input through its standard plot.R contract
/usr/local/bin/Rscript skills/figureforge/scripts/render_case.R \
  <case_dir> --input <input_csv> --output <output_path>

# Validate and freshly re-render a new-data adaptation
/usr/local/bin/Rscript skills/figureforge/scripts/validate_adaptation.R \
  <adaptation_dir> --render --output <validation_output>

# Validate an evidence-backed terminal blocker
/usr/local/bin/Rscript skills/figureforge/scripts/validate_blocker.R \
  <case_dir>

# Plan pending cases in deterministic evidence-first waves
/usr/local/bin/Rscript skills/figureforge/scripts/plan_case_batches.R \
  --readiness <case-readiness.csv> \
  --output <batch-manifest.csv> \
  --batch-size 20
```

The helpers orchestrate discovery and verification; plotting logic remains
case-specific and independently readable rather than being hidden behind a
generic plotting framework.

## Case Readiness Audit

Having `case.md`, `data.csv`, and `plot.R` proves only that a case has the
expected structure. It does not prove that the files use authentic source data,
faithfully reproduce the original figure, or are safe to redistribute.

Run the read-only audit against a local corpus:

```bash
/usr/local/bin/Rscript skills/figureforge/scripts/audit_cases.R \
  --cases-dir /absolute/path/to/skills/figureforge/cases \
  --output-dir outputs/figureforge-audit \
  --rscript /usr/local/bin/Rscript \
  --render
```

The audit records independent evidence flags:

- `raw`: additional source assets exist;
- `scaffolded`: generated placeholder content was detected;
- `runnable`: an isolated fresh render succeeded;
- `reproduced`: a non-empty reproduction artifact exists;
- `qa_verified`: an explicit, complete `qa.md` record exists;
- `public_ready`: redistribution was explicitly reviewed and allowed;
- `private_only`: public readiness is absent or denied.

The complete-corpus audit also records `terminal_outcome`:

- `completed`: non-scaffolded, runnable, reproduced, and QA-verified;
- `blocked`: a strict evidence record passes `validate_blocker.R`;
- `pending`: neither terminal contract passes.

Supported categories include `blocked_source_missing`,
`blocked_dependency`, `blocked_visual_reference`, `blocked_corrupt_asset`,
`blocked_ambiguous_mapping`, and `blocked_rights`. A verified QA record and a
valid blocker cannot coexist. Workload and elapsed time are not blocker
evidence.

Scaffolded cases are not completed cases. A successful render proves execution,
not visual fidelity. Missing distribution review always defaults to
`private_only`. Reports are written under ignored `outputs/` and must not be
committed with private corpus information.

Validate one developed case against the complete contract and perform a fresh
render outside its source directory:

```bash
/usr/local/bin/Rscript skills/figureforge/scripts/validate_case.R <case_dir> --complete --render --output <output_path>
```

The default validator command checks structure only. `--complete` additionally
requires authentic-data provenance, declared R packages, no scaffold markers,
the standard plotting argument contract, reproduction evidence, and verified
QA. `--render` adds fresh execution evidence. Distribution permission remains
a separate review and defaults to `private_only`.

## Authoring a new case

1. Add or select authentic source data, code, and reproduction evidence.
2. Fill in `case.md`: provenance, schema, visual encodings, dependencies,
   adaptation notes, pitfalls, and bilingual aliases.
3. Normalize authentic data into `data.csv` without deleting source assets.
4. Refactor `plot.R` to accept explicit input and output paths.
5. Render outside the source directory and compare with the authentic
   reference.
6. Save a complete `qa.md`; review distribution separately.
7. Run `validate_case.R --complete --render`, then rebuild the local index.

## Verified Skill MVP

The local private corpus contains 165 audited cases. After four
complete-corpus waves, 94 cases pass the complete case contract: the original
15-case MVP plus 79 newly recovered cases. Coverage now also includes
multi-track GO enrichment circles, fan trees with five bar rings, aligned
tree-and-composition panels, annotated phenotype heatmaps, radar small
multiples, grouped bubble matrices, sunbursts, genomic synteny circles, and
additional complex phylogenetic annotations. Wave 2 adds promoter-element
matrices, authentic STRING PPI networks, PCoA/NMDS comparisons, alluvial
composition plots, qRT-PCR panels, symmetric bars, custom enrichment bubbles,
grouped heatmaps, and four more phylogeny layouts. Wave 3 adds raincloud and
violin distributions, mirrored functional-gene bars, circular lollipops and
bars, Sankey flow, marker heatmaps, dual-axis and paired-subject plots,
expression-aware volcano plots, chromosome ideograms, radar profiles, and
world sampling maps with composition pies. Wave 4 adds PCA with marginal
statistics, treemaps, fan glyphs, GO/KEGG panels, circos and gene-family
layouts, promoter matrices, PPI, expression heatmaps, qRT-PCR, a
source-recovered Nature Microbiology tree, paired trees, and enrichment
figures. The rendered audit records 94 completed, 1 evidence-backed
`blocked_source_missing`, and 70 pending cases. All 165 remain `private_only`
because redistribution has not been approved.

Three new-data migrations prove the workflow goes beyond reproduction:

- R `HairEyeColor` → three-strategy donut composition;
- R `USArrests` → signed correlation bubble heatmap;
- R `ChickWeight` → four-diet time series with 95% t intervals and inset.

Each migration has a different input, field mapping, migrated `plot.R`, exact
command, rendered PDF, written QA, and successful independent re-render under
ignored `outputs/figureforge-adaptations/`.

## Roadmap

- [x] Complete a 15-case private R/ggplot2 MVP with authentic provenance,
      fresh renders, and recorded visual QA.
- [x] Complete corpus Wave 1: develop and fully validate 20 additional cases.
- [x] Complete corpus Wave 2: develop and fully validate 20 additional cases.
- [x] Complete corpus Wave 3: develop and fully validate 20 additional cases.
- [x] Complete corpus Wave 4: verify 19 additional cases and classify 1 case
      with a validated source-missing blocker.
- [x] Verify end-to-end migration on three different new datasets and chart
      families.
- [ ] Process the remaining 70 private cases to a completed or evidence-backed
      blocked terminal outcome.
- [ ] Build the local-first FigureForge MCP server only after final Skill and
      corpus acceptance.
- [ ] Expand the public curated gallery after separate distribution review.
- [ ] Add Python examples after the R-first workflow stabilizes.
- [ ] Explore a software/resource, data-descriptor, or methods publication.

See [`PROJECT_HANDOFF.md`](PROJECT_HANDOFF.md) for the full vision and positioning.

## Status

**Skill MVP implemented and locally verified.** Discovery, indexing, dependency
diagnosis, safe rendering, case validation, adaptation validation, templates,
references, and three new-data proofs are in place. Ninety-four of 165 private
cases meet the complete contract; 70 remain pending and 1 has a validated
`blocked_source_missing` record. The public curated case set is still being
prepared. The MCP server remains planned, unimplemented, and paused until the
Skill and case corpus reach final acceptance.

## License

No license has been selected yet. **Add a license before public reuse or redistribution.** Note that individual cases may reference third-party figures and data under their own terms.
