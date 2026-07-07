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

1. Clarify your plotting goal, data type, target output, ecosystem, and language.
2. Search `references/gallery-index.md` and case metadata for matching chart types and aliases.
3. Open the case's `case.md`, `plot.R`, and data **before editing**.
4. Build a column-mapping table from your data to the case schema.
5. Adapt the case-specific script, preserving the useful visual structure.
6. Render the figure and run the QA checklist.
7. Report the case used, mapping decisions, outputs, verification, and remaining limits.

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
skills/figureforge/cases/NNN-case-name/
├── case.md            # metadata + adaptation notes (required)
├── data.csv           # plotting data (required)
├── plot.R             # reproducible plotting script (required)
├── reproduction.pdf   # / .png — our reproduction, when available
└── original.png       # reference image, only if redistribution is allowed
```

`case.md` follows a fixed set of headings so it stays machine-readable and consistent across cases:

```text
## Chart Type            ## Visual Encoding
## Chart Type Chinese    ## ggplot Components
## Aliases               ## Adaptation Notes
## Best For              ## Common Pitfalls
## Best For Chinese
## Data Schema
```

See `skills/figureforge/cases/_template/case.md` for the canonical template. The `_template` folder is a format guide, **not** a curated figure reproduction.

## Helper scripts

All scripts are plain `Rscript` and run from the repo root:

```bash
# Validate a case folder has the required files and case.md headings
Rscript skills/figureforge/scripts/validate_case.R <case_dir>

# Render a case's plot.R to a figure file
Rscript skills/figureforge/scripts/render_case.R <case_dir> [output_path]

# Rebuild the machine-readable case index (CSV)
Rscript skills/figureforge/scripts/index_cases.R [cases_dir] [output_csv]
```

`render_case.R` and `validate_case.R` are deliberately kept simple and case-specific — each case stays independently understandable and reproducible rather than being hidden behind a generic plotting framework.

## Authoring a new case

1. Add or select a real figure reproduction.
2. Fill in `case.md`: chart type, data schema, visual encodings, ggplot2 components, adaptation notes, pitfalls, and Chinese/English aliases.
3. Keep `plot.R` case-specific and reproducible.
4. Render it: `Rscript .../render_case.R <case_dir>`.
5. Validate structure: `Rscript .../validate_case.R <case_dir>`.
6. Update the index: `Rscript .../index_cases.R`.
7. Run the QA checklist before calling the figure publication-ready.

## Roadmap

- [ ] Curate a 12–20 case R/ggplot2 MVP covering bars, boxplots, violins, labeled scatter, trend lines, heatmaps, facets, multi-panel, and complex annotations.
- [ ] Verify an AI agent can select and adapt one case to a new dataset end-to-end.
- [ ] Build the local-first FigureForge MCP server for case discovery, inspection, validation, indexing, rendering, and mapping suggestions.
- [ ] Expand the curated gallery once the adaptation workflow proves useful.
- [ ] Add Python examples after the R-first workflow stabilizes.
- [ ] Explore a software/resource, data-descriptor, or methods publication.

See [`PROJECT_HANDOFF.md`](PROJECT_HANDOFF.md) for the full vision and positioning.

## Status

Early MVP. The skill workflow, references, scripts, and case template are in place; the curated public case set is being assembled from the private corpus.

## License

No license has been selected yet. **Add a license before public reuse or redistribution.** Note that individual cases may reference third-party figures and data under their own terms.
