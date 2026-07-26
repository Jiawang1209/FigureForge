# FigureForge README Quickstart Design

**Date:** 2026-07-26  
**Status:** Approved

## Goal

Rewrite the English and Chinese root READMEs as concise user entry points,
following the practical shape of the ggNetView Skill README. A new user should
be able to answer two questions immediately:

1. How do I install the FigureForge Skill?
2. What do I say to an agent to use it?

## Information architecture

Both `README.md` and `README.zh.md` will use the same short structure:

1. product name and one-sentence positioning;
2. installation;
3. usage examples;
4. default deliverables;
5. links for maintainers and contributors;
6. current scope and license.

The root README will not reproduce case-maintenance, validation, packaging,
release, or private-corpus procedures. Those details already have dedicated
documents and will be linked instead.

## Installation contract

The primary installation path will use the repository's tested project-level
Skill layout:

```text
.agents/skills/figureforge/SKILL.md
```

The README will provide copyable commands to clone FigureForge and copy
`skills/figureforge` into `.agents/skills/figureforge`. It will also explain
that users of another Skill-compatible agent may copy the same directory into
that agent's supported Skill root.

The README will not copy ggNetView's Claude Plugin marketplace commands because
FigureForge is currently distributed as a standard Skill directory rather than
a Claude Plugin marketplace.

## Usage contract

Usage will be demonstrated primarily as natural-language prompts, including:

```text
Use data.csv with the FigureForge Skill to draw a scatter plot and give me the R script.
```

The Chinese README will carry the equivalent Chinese prompt. Additional examples
may cover a chart with grouping/color requirements and a request that implicitly
invokes the plotting capability.

The documented default result is exactly:

- `plot.R`
- `plot.png`
- `plot.pdf`

The README will state that FigureForge uses R/ggplot2 by default and specialist
R packages when the requested chart requires them. Python plotting and an MCP
server remain outside the shipped scope.

## Maintainer links

The concise README will link to:

- the Skill entry point;
- plotting workflow reference;
- maintainer workflow reference;
- v1.1.0 certification evidence;
- current project status;
- contribution guidance where applicable.

## Validation

The documentation change is complete when:

- English and Chinese sections have matching structure and meaning;
- all relative links resolve;
- install commands produce `.agents/skills/figureforge/SKILL.md`;
- both READMEs name the three default deliverables;
- existing v1, v1.0.1, and v1.1.0 documentation tests are updated or preserved
  without weakening release and private-corpus boundaries;
- `git diff --check` passes.
