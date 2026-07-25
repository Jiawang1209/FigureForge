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
4. Choose one primary case for overall composition and use secondary cases only
   for useful local patterns.
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
  --schema "<input-file>" \
  --explain-scores \
  --limit 5
```

Use a candidate's explanation, `plot.R`, and schema as knowledge. Adapt the
plot newly to the user's data and request, and combine cases when a secondary
case offers a useful local pattern. The gallery is experience, not a gate:
avoid mechanical copying and do not impose metadata ceremony on an ordinary
plotting task.

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
