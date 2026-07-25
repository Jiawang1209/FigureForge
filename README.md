# FigureForge

**An AI-ready, reproducible, case-based skillbase for publication-ready scientific visualization.**

> From reproduction to adaptation.

English · [简体中文](README.zh.md)

FigureForge turns real publication-figure reproductions into reusable, AI-driven plotting workflows. Each case connects a reference image, reproducible data, plotting code, adaptation notes, and QA rules — so an AI agent (or a human) can pick the closest example and adapt it to a brand-new scientific dataset instead of prompting a model to invent a figure from scratch.

The first release is **R / ggplot2 first**, built from a long-running figure-reproduction series (*在模仿中精进数据可视化*). Python support is planned once the R workflow stabilizes.

---

## FigureForge Skill 1.0.1

FigureForge Skill 1.0.1 is independently usable without the private corpus.
It ships 15 public cases: 3 authentic open-data cases with recorded provenance,
licenses, hashes, attribution, and human-verified QA, plus 12 synthetic
demonstration cases that make no scientific claims. The release also includes
24 synthetic stress fixtures and 30 deterministic bilingual forward
evaluations. MCP is planned and unimplemented.

Release inventory: 15 public cases, 3 authentic open-data cases, 12 synthetic demonstration cases, 24 stress fixtures, and 30 deterministic bilingual forward evaluations.

The local 165-case private corpus, source figures, reproductions, audit output,
and live-evaluation transcripts are never packaged. Each public case's
`case.yml`, `distribution.yml`, `source.yml` when present, and `qa.md` control
its claims and distribution boundary.

### Install and discover

Build the public-only archive, manifest, and adjacent SHA-256 sidecar:

```bash
Rscript skills/figureforge/scripts/package_skill.R \
  --archive /tmp/figureforge-skill-1.0.1.tar.gz \
  --manifest /tmp/figureforge-skill-1.0.1-manifest.csv
```

Install it into a repository Skill root:

```bash
mkdir -p .agents/skills
tar -xzf /tmp/figureforge-skill-1.0.1.tar.gz -C .agents/skills
test -s .agents/skills/figureforge/SKILL.md
```

For a user-level installation, extract into the corresponding user Skill root
instead. The archive itself is rooted at `figureforge/`; it never creates an
extra `skills/figureforge/` layer.

Set the installed root for copyable commands:

```bash
export FIGUREFORGE_SKILL_ROOT="$PWD/.agents/skills/figureforge"
```

Codex discovers the Skill from `.agents/skills/figureforge`. Explicit requests
may use `$figureforge`; data-only English or Chinese visualization requests
are also covered by the Skill description.

### Runtime and public workflow

Subprocess-capable commands resolve Rscript in this order: explicit
`--rscript`, `FIGUREFORGE_RSCRIPT`, the `/usr/local/bin/Rscript`
compatibility path, then `Rscript` on `PATH`. An invalid explicit choice fails
instead of silently falling through.

```bash
export FIGUREFORGE_RSCRIPT="${FIGUREFORGE_RSCRIPT:-Rscript}"

"$FIGUREFORGE_RSCRIPT" \
  "$FIGUREFORGE_SKILL_ROOT/scripts/doctor.R"

"$FIGUREFORGE_RSCRIPT" \
  "$FIGUREFORGE_SKILL_ROOT/scripts/search_cases.R" \
  --public --query "相关性 heatmap" --limit 5

"$FIGUREFORGE_RSCRIPT" \
  "$FIGUREFORGE_SKILL_ROOT/scripts/match_schema.R" \
  --case public-timeseries-band --input <input.csv> --output <match.csv>

"$FIGUREFORGE_RSCRIPT" \
  "$FIGUREFORGE_SKILL_ROOT/scripts/create_adaptation.R" \
  --case public-timeseries-band --input <input.csv> \
  --workspace <external_adaptation_dir>

"$FIGUREFORGE_RSCRIPT" \
  "$FIGUREFORGE_SKILL_ROOT/scripts/visual_qa.R" \
  --render <external_adaptation_dir>/output.pdf \
  --report <external_report_dir>/visual-qa.json
```

Keep every adaptation and render outside the installed Skill. The packaged
demo enforces that boundary. Synthetic adaptations remain
`Status: review_required` until authorized human review; automated QA never
grants verified status.

```bash
sh "$FIGUREFORGE_SKILL_ROOT/examples/public-demo/run_demo.sh" \
  /tmp/figureforge-public-demo
```

### Verify, evaluate, and upgrade

Verify the outer sidecar, archive structure, allowlisted members, byte counts,
and every file hash before installation:

```bash
Rscript skills/figureforge/scripts/verify_release.R \
  --archive /tmp/figureforge-skill-1.0.1.tar.gz \
  --manifest /tmp/figureforge-skill-1.0.1-manifest.csv \
  --extract-dir /tmp/figureforge-skill-1.0.1-verified
```

Run the deterministic bilingual evaluation catalog:

```bash
Rscript skills/figureforge/scripts/evaluate_skill.R \
  --catalog skills/figureforge/references/trigger-evals-v1.csv \
  --output-dir /tmp/figureforge-forward-evals \
  --report /tmp/figureforge-forward-evals.csv \
  --rscript "${FIGUREFORGE_RSCRIPT:-Rscript}"
```

Live Codex trigger probes are an explicit, bounded release gate:

```bash
bash scripts/run_figureforge_live_evals.sh \
  --output-dir outputs/figureforge-v101/live-evals/manual
```

For a 1.0.0-to-1.0.1 upgrade, preserve external adaptations, verify 1.0.1 in a
sibling staging directory, rename the existing exact
`.agents/skills/figureforge` target to a target-specific backup, atomically
rename the verified stage into place, validate it, and only then remove that
exact backup. Do not merge files into the old directory: full replacement
prevents stale v1.0.0 libraries from surviving.

See
[`docs/figureforge-skill-v1.0.1-release.md`](docs/figureforge-skill-v1.0.1-release.md)
for the release boundary, source hashes, test evidence, and local-only release
policy.

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

The local private corpus contains 165 audited cases. After eight
complete-corpus waves, 152 cases pass the complete case contract: the original
15-case MVP plus 137 newly recovered cases. Coverage now also includes
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
figures. Wave 5 adds microbial taxonomy fans and trees, composite taxonomy
panels, annotated networks, table/bar and donut compositions, geometric
primitives, Manhattan plots, GO annotation and enrichment, legend engineering,
WGCNA module trees, metabolite IQR intervals, and reordered GO labels. Wave 6
adds an annotated single-cell UMAP, confidence-band time series, alluvial
composition, PPI layout comparisons, paired differential-expression bubbles,
microbial correlation networks, single-chromosome composition tracks, circular
GO panels, and correlation/Mantel connector matrices. Wave 7 adds clustered
and annotated heatmaps, correlation chords/networks, single and multi-contrast
differential-expression plots, interaction circos, faceted ANOVA, and advanced
sampling maps. Wave 8 closes the final pending set with pie-node composition
networks, nested taxonomy circle packing, grouped taxonomic composition bars,
sign-aware and annotated correlation heatmaps, Venn diagrams, four-panel
correlation/significance matrices, double-hub regulatory networks, comic-font
plots, and rotated triangle heatmaps. The final rendered audit records 152
completed, 13 evidence-backed blocked cases, and zero pending cases. The
blockers comprise 6
`blocked_source_missing`, 3 `blocked_ambiguous_mapping`, and 4
`blocked_visual_reference`. All 165 remain
`private_only` because redistribution has not been approved.

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
- [x] Complete corpus Wave 5: verify 16 additional cases and classify 4 cases
      with source-missing, visual-reference, or ambiguous-mapping evidence.
- [x] Complete corpus Wave 6: verify 14 additional cases and classify 6 cases
      with source-missing, visual-reference, or ambiguous-mapping evidence.
- [x] Complete corpus Wave 7: verify 18 additional cases and classify 2 cases
      with visual-reference evidence.
- [x] Complete corpus Wave 8: fully verify the final 10 cases.
- [x] Verify end-to-end migration on three different new datasets and chart
      families.
- [x] Process all 165 private cases to a completed or evidence-backed blocked
      terminal outcome; no case remains pending.
- [ ] Build the local-first FigureForge MCP server only after final Skill and
      corpus acceptance.
- [ ] Expand the public curated gallery after separate distribution review.
- [ ] Add Python examples after the R-first workflow stabilizes.
- [ ] Explore a software/resource, data-descriptor, or methods publication.

See [`PROJECT_HANDOFF.md`](PROJECT_HANDOFF.md) for the full vision and positioning.

## Status

**FigureForge Skill 1.0.1 is the locally certified release candidate.** It
includes 15 public cases (3 authentic open-data and 12 synthetic
demonstrations), 24 stress fixtures, and 30 deterministic bilingual forward
evaluations. One hundred fifty-two of 165 private cases meet the complete
local contract; the other 13 have validated case-specific blocker records, and
none remain pending. The private corpus is not part of the public package.
MCP is planned and unimplemented; no MCP endpoint or server is shipped.

## License

The public framework is available under the repository MIT
[`LICENSE`](LICENSE). Each public case has its own explicit
`distribution.yml`. Private cases and third-party source assets are not
covered by the public release.
