---
name: figureforge
description: Use when a user needs an R-based scientific plot from real data, including explicit or data-only Chinese or English requests, reusable R scripts, rendering, or visual refinement.
---

# FigureForge

FigureForge is a case-enhanced scientific plotting capability for R. Read the
user's real data, understand the scientific relationship, use the gallery as
visual and code experience, write and run a standalone R script, and return:

- `plot.R`
- `plot.png`
- `plot.pdf`

Use ggplot2 by default and specialist R packages when the chart family benefits
from them. MCP is planned and unimplemented.

## Default Workflow

1. Inspect the real input: columns, types, missingness, groups, duplicate keys,
   and values relevant to the requested relationship.
2. Interpret the scientific intent. Honor an explicit chart family when it is
   supported by the data.
3. Search the gallery in the background for relevant visual grammar and code
   experience.
4. Choose exactly one generation mode after search: `case_based` or
   `general_fallback`. In `case_based`, choose one primary case for overall
   composition and use secondary cases only for useful local patterns.
5. Ask the user only when unresolved ambiguity would change the scientific
   meaning. Otherwise apply professional presentation defaults.
6. Write a standalone `plot.R` that reads the real input rather than embedding
   or replacing it.
7. Run the script to generate `plot.png` and `plot.pdf`, inspect the results,
   and fix and rerun as needed.
8. Return the three artifact paths with a concise explanation of mappings and
   design choices.

## Data and Case Use

Resolve `FIGUREFORGE_SKILL_ROOT` to the directory containing this `SKILL.md`.
Common locations are `.agents/skills/figureforge` in a project installation
and `skills/figureforge` in a source checkout.

Search public cases using the user's scientific intent and the real schema:

```bash
Rscript "$FIGUREFORGE_SKILL_ROOT/scripts/search_cases.R" \
  --public \
  --query "<scientific intent, relationship, or chart family>" \
  --search-intent "<controlled intent>" \
  --schema "<input-file>" \
  --explain-scores \
  --limit 5 \
  --output "<output-directory>/.figureforge/case-search.csv"
```

Run `search_cases.R` with `--output` before choosing the generation mode.
Keep the nonempty CSV beside `case-trace.yml`, then record its
`search_query_sha256`, controlled `search_intent`, `search_receipt_file`, and
`search_receipt_sha256` in the trace. Never copy the raw query into the trace
or receipt. The command still prints candidates for selection, while the
persisted versioned receipt binds the query hash and search context and stores
only hashed candidate IDs. A console-only search is not a valid search receipt.
These hashes are pseudonymous and linkable, not encryption. Keep the raw
search query abstract and never include credentials, row values, personal
identifiers, or other secrets.

Choose exactly one generation mode after search:

- Use `case_based` only when a sufficiently relevant primary case is readable;
  actually read `case.md` and `plot.R`, and read `qa.md` when it exists. Record
  schema mapping, adopted patterns, and departures in
  `.figureforge/case-trace.yml`.
- Use `general_fallback` when no case matches sufficiently or required case
  evidence cannot be read. Record the reason and proceed with a general R
  method.

For `case_based`, run `validate_case_trace.R` with the primary case directory,
generated script, and real input schema. For `general_fallback`, pass the
generated script and real input schema.
Only a successful strict validation authorizes a case-grounded claim.
Structural or partial validation never authorizes that claim.
Never describe `general_fallback` output as case-grounded; its claim is
`general_method`.

The trace is hidden workflow state, not a fourth visible deliverable. The
search receipt is hidden workflow state too, not another visible deliverable.
Do not ask the user to inspect, select, or operate the case library. See
[Case Use Contract](references/case-use-contract.md) for the trace schema,
mapping and anchor format, departures, validation command, and claim rules.

## Artifact Contract

The delivered script must run as:

```bash
Rscript plot.R <input-file> <output-directory>
```

It must validate the input and required columns, declare dependencies
explicitly, use deterministic behavior when needed, preserve supported Chinese
column names and labels, and create nonempty `plot.png` and `plot.pdf` in the
output directory. Keep temporary agent state out of the delivered artifacts.

## When to Ask

Ask about x/y roles, grouping, aggregation, normalization, repeated measures,
statistical tests, or units only when the answer would change the scientific
meaning. Do not interrupt the task for presentation defaults such as palette,
font sizing, spacing, legend placement, or export dimensions.

## Render, Inspect, and Repair

Run `plot.R` before delivery and confirm all three artifacts exist. Independently
rerun it from the documented command, then open or render the images. Verify
that expected rows and groups are represented and that mappings, labels,
legends, clipping, overlap, empty panels, and overall readability are correct.
Repair and rerun instead of delivering unexecuted code.

See [Plotting Workflow](references/plotting-workflow.md) for the full task
checklist. Consult [ggplot Patterns](references/ggplot-patterns.md),
[Theme and Export](references/theme-and-export.md), and
[Data Mapping](references/data-mapping.md) when useful.

## Iteration

For follow-up refinements, modify the existing `plot.R` and regenerate both
images. Preserve confirmed mappings, scientific decisions, and constraints
unless the user changes them.

## Maintainer Boundary

Case authoring, corpus auditing, blockers, provenance, distribution, stress
evaluation, packaging, and release certification are maintainer concerns, not
ordinary user ceremony. Maintainers should follow the separate
[Maintainer Workflow](references/maintainer-workflow.md).
