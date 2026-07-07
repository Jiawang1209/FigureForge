# FigureForge Skill + MCP Dual-Layer Design

Date: 2026-07-07

## Goal

Develop FigureForge from a Codex skillbase into a dual-layer product:

- A skill layer that teaches AI agents how to reason through case-based scientific visualization adaptation.
- An MCP layer that exposes stable tools for case discovery, metadata inspection, validation, indexing, and rendering.

The product should remain grounded in real reproducible figure cases. It should not become a generic "make a Nature-style figure" prompt library or an over-abstracted plotting framework.

## Current Repository Reality

FigureForge already has the right foundation for a dual-layer product:

- `skills/figureforge/SKILL.md` defines the agent workflow.
- `skills/figureforge/references/` defines the reference knowledge base.
- `skills/figureforge/scripts/index_cases.R` builds a case index.
- `skills/figureforge/scripts/validate_case.R` validates case structure.
- `skills/figureforge/scripts/render_case.R` renders a case through `Rscript`.
- Local private cases exist under `skills/figureforge/cases/`.
- `.gitignore` keeps the full case corpus private by default.

The MCP layer should wrap and stabilize these capabilities rather than replacing them.

## Product Positioning

FigureForge should be positioned as:

> A case-based scientific visualization skillbase and MCP tool server that helps AI agents discover, inspect, adapt, validate, and render reproducible publication-style figures.

The skill is the guidance layer. The MCP server is the callable capability layer. The case corpus is the asset layer.

## Product Layers

### 1. Skill Layer

The skill layer stays in `skills/figureforge/`.

Responsibilities:

- Explain the end-to-end workflow for adapting a figure case.
- Tell agents to prefer concrete case evidence over style prompts.
- Require agents to inspect `case.md`, `plot.R`, and data before editing.
- Require a column-mapping table before code changes.
- Require rendering and QA before calling a figure complete.
- Explain fallback behavior when no case matches.

The skill should continue to work even when MCP is unavailable. In that mode, the agent can read files and run scripts directly.

### 2. MCP Tool Layer

The MCP layer should live under a new `mcp/figureforge/` package.

Responsibilities:

- Provide machine-callable tools with stable schemas.
- Hide file-system scanning details from agents.
- Return structured metadata instead of forcing agents to parse Markdown manually.
- Run existing helper scripts safely.
- Keep rendering outputs in explicit output directories.
- Report errors as structured tool results.

The first MCP version should be local-first. It should run against a local FigureForge checkout and local R installation.

### 3. Case Corpus Layer

The case corpus remains under `skills/figureforge/cases/`.

Two distribution modes are required:

- Private/local mode: the user's complete private corpus can be indexed and used locally.
- Public/redistributable mode: only cleaned cases with safe data, metadata, scripts, and allowed images are shipped.

The MCP server must not assume that every local case can be redistributed.

### 4. Generated Index Layer

The MCP server should prefer a machine-readable index when available.

Initial index files:

- `skills/figureforge/references/case-index.csv`
- Future: `skills/figureforge/references/case-index.json`
- Future: `skills/figureforge/references/case-status.csv`

The index is generated from local case metadata and can be ignored by git when it represents private local state.

## Recommended MCP Tools

### `figureforge_health`

Purpose: Verify that the server can see the FigureForge root, scripts, cases directory, and R runtime.

Returns:

- repository root
- cases directory
- number of discovered cases
- Rscript path
- missing dependencies or warnings

### `figureforge_list_cases`

Purpose: Return case summaries from the generated index or by scanning `case.md` files.

Inputs:

- `limit`
- `offset`
- optional `status`
- optional `ecosystem`

Returns:

- case id
- title
- chart type
- Chinese chart type
- aliases
- best-for summary
- status

### `figureforge_search_cases`

Purpose: Search cases by English or Chinese query.

Inputs:

- `query`
- optional `chart_type`
- optional `ecosystem`
- optional `limit`

Returns:

- ranked case summaries
- match fields
- score or reason

Search should start simple: lowercase substring matching across title, chart type, Chinese chart type, aliases, and best-for fields. More advanced ranking can come later.

### `figureforge_get_case`

Purpose: Return structured metadata and safe file references for one case.

Inputs:

- `case_id`
- optional `include_plot_script`
- optional `include_data_preview`

Returns:

- parsed `case.md` sections
- required schema
- visual encoding
- ggplot components
- adaptation notes
- common pitfalls
- safe local paths for `plot.R`, `data.csv`, and reproduction output when present
- data preview with row and column limits

This tool should avoid returning large binary files. It can return paths and summaries instead.

### `figureforge_validate_case`

Purpose: Run structural validation for a case.

Inputs:

- `case_id`

Returns:

- success boolean
- missing files
- missing headings
- raw validator output

This wraps `skills/figureforge/scripts/validate_case.R`.

### `figureforge_build_index`

Purpose: Rebuild the local case index.

Inputs:

- optional `cases_dir`
- optional `output_path`

Returns:

- output path
- row count
- warnings

This wraps `skills/figureforge/scripts/index_cases.R`.

### `figureforge_render_case`

Purpose: Render a case using its existing `plot.R`.

Inputs:

- `case_id`
- optional `output_path`
- optional `format`

Returns:

- success boolean
- output path
- render logs
- error message if rendering failed

This wraps `skills/figureforge/scripts/render_case.R`. The tool should only write inside an explicit output directory by default, such as `outputs/figureforge/`.

### `figureforge_suggest_mapping`

Purpose: Suggest a mapping between user data columns and a case schema.

Inputs:

- `case_id`
- user data columns
- optional sample rows
- optional language hint

Returns:

- mapping table
- confidence per field
- missing required roles
- notes for derived variables

This can start as a deterministic helper based on column names and case schema. It does not need to call an LLM.

## Architecture

Use a TypeScript MCP server for the first implementation.

Reasons:

- MCP SDK examples and integrations are mature in Node/TypeScript.
- Tool schemas can be expressed cleanly with Zod.
- The server can call existing R scripts with child processes.
- It is easy for Claude Desktop, Codex, and other local agents to install and run.

Proposed structure:

```text
mcp/
  figureforge/
    package.json
    tsconfig.json
    src/
      index.ts
      config.ts
      caseStore.ts
      caseParser.ts
      rScripts.ts
      tools/
        health.ts
        listCases.ts
        searchCases.ts
        getCase.ts
        validateCase.ts
        buildIndex.ts
        renderCase.ts
        suggestMapping.ts
    tests/
      fixtures/
      caseParser.test.ts
      searchCases.test.ts
      tools.test.ts
```

The server should discover the FigureForge root from:

1. `FIGUREFORGE_ROOT`
2. current working directory if it contains `skills/figureforge/SKILL.md`
3. a `--root` CLI option later if needed

## Data Flow

Typical agent flow:

```text
Agent user request
  -> skill explains FigureForge workflow
  -> MCP health check
  -> MCP search/list cases
  -> MCP get selected case
  -> agent creates column mapping
  -> optional MCP suggest_mapping
  -> agent adapts script or creates a working copy
  -> MCP validate/render
  -> skill QA checklist
  -> final report with case, mapping, outputs, and limits
```

The MCP server should not silently edit the original case corpus. Adapted work should be created in a user-selected project directory or a generated output workspace in a later version.

## Public vs Private Boundary

This is a core product rule:

- Public repository: skill, MCP server, references, scripts, case template, and curated redistributable cases only.
- Private local corpus: full reproduction archive, third-party PDFs, original images, and restricted data.

The MCP server may read private local cases, but packaging and documentation must make clear that private content is not automatically publishable.

## Error Handling

The MCP layer should return structured errors:

- missing FigureForge root
- missing cases directory
- no cases indexed
- unknown case id
- missing required files
- Rscript unavailable
- R package missing
- render command failed
- output file not created

Tool results should include both a short user-facing message and a diagnostic detail field.

## Testing Strategy

Tests should not depend on the private 166-case corpus.

Use fixtures under `mcp/figureforge/tests/fixtures/`:

- one valid mini case
- one invalid case missing `plot.R`
- one invalid case missing headings
- one case with Chinese chart metadata

Test coverage:

- Markdown section parsing.
- Case discovery.
- Chinese/English search.
- Tool schema behavior.
- R script wrapper command construction.
- Validation failures.
- Render behavior using a tiny fixture case when R is available.

## Implementation Phases

### Phase 0: Product Contract

Finalize this design and the implementation plan. Update README later to mention the Skill + MCP dual-layer roadmap.

### Phase 1: MCP Read-Only Foundation

Build a local MCP server with:

- health
- list cases
- search cases
- get case

This proves that other agents can discover and inspect FigureForge cases without direct file parsing.

### Phase 2: Validation and Indexing

Add tools that wrap existing R helpers:

- build index
- validate case

This turns the existing scripts into reusable tool capabilities.

### Phase 3: Rendering

Add controlled rendering:

- render a case
- write outputs to a clear output directory
- return output paths and logs

### Phase 4: Mapping Assistant

Add deterministic data-schema mapping suggestions.

This should remain transparent and editable by the agent. It should not hide the mapping decision.

### Phase 5: Distribution

Add:

- install instructions for common MCP clients
- example config
- public/private corpus guidance
- small public demo case set
- versioned release checklist

## Non-Goals

- Do not build a web gallery in the first MCP milestone.
- Do not implement fully automatic figure adaptation in the MCP server.
- Do not mutate original case directories by default.
- Do not redistribute private case assets.
- Do not replace the skill with MCP. Both layers are needed.

## Success Criteria

The first successful dual-layer milestone is complete when:

- A fresh agent can connect to the FigureForge MCP server.
- The agent can run health, search cases, and inspect one case.
- The agent can validate a fixture case.
- The agent can render a tiny fixture case.
- The skill documentation explains when to use MCP tools and when to read files directly.
- The public/private case boundary is documented.

## Open Decisions

- Whether the MCP package should be published as a standalone npm package or remain inside the repo at first.
- Whether the public case set starts with 3 demo cases or a fuller 12-20 case MVP.
- Whether rendered outputs should default to repo-local `outputs/figureforge/` or a user project directory.
- Whether `case-index.json` should become the canonical index format instead of CSV.
