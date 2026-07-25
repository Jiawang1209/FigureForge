# FigureForge Plotting Capability Enhancer Design

Date: 2026-07-25

## Status

Approved design for FigureForge Skill v1.1.0. This specification changes the
user-facing operating model of the Skill. It does not remove the existing case
corpus, validation tools, release infrastructure, or planned MCP layer.

## Product Definition

FigureForge is an R-based scientific plotting capability enhancer for AI
agents. A user should be able to ask:

> Use `xxx.csv` and the FigureForge Skill to draw a scatter plot, and give me
> the R script.

The agent reads the real data, understands the scientific intent, draws on the
FigureForge case library, writes and runs a reusable R script, checks the
result, and returns three artifacts:

```text
plot.R
plot.png
plot.pdf
```

The default plotting grammar is ggplot2. The agent may use specialist R
packages such as ggNetView, ggtree, or ComplexHeatmap when the requested
visualization benefits from them. Python plotting is outside the v1.1.0 scope.

## Design Decision

Retain one public `figureforge` Skill, but separate the user-facing plotting
workflow from maintainer and governance concerns.

The main Skill becomes a concise, task-oriented plotting workflow. Existing
case search, schema support, dependency diagnostics, rendering, QA, case
validation, distribution validation, stress testing, packaging, and release
verification remain available as supporting infrastructure. Maintainer-only
rules move out of the ordinary plotting path and into dedicated references.

The alternatives were rejected for the following reasons:

- Editing only the wording of the current `SKILL.md` would leave user,
  maintainer, governance, and release responsibilities entangled.
- Publishing separate `figureforge` and `figureforge-maintainer` Skills would
  create avoidable installation, versioning, and documentation overhead at
  this stage.

## User Experience

### Default request

The normal interaction is a natural-language request containing some
combination of:

- an input data file;
- the scientific relationship or comparison to communicate;
- a requested chart family or reference appearance;
- optional labels, statistics, annotations, dimensions, or style preferences.

The user does not need to know the internal case schema, adaptation contract,
private corpus layout, or release process.

### Default workflow

For an ordinary plotting request, the agent:

1. reads the input data and inspects real column names, types, missingness,
   grouping levels, duplicates, and potentially relevant values;
2. interprets the scientific intent, honoring an explicitly requested chart
   family when it is valid for the data;
3. searches the FigureForge gallery in the background;
4. selects one primary case for overall composition and may use secondary
   cases for local ideas such as palettes, annotations, or layout;
5. determines the field mapping and asks a question only when unresolved
   ambiguity would change the scientific meaning;
6. writes a standalone R script for the user's data;
7. runs the script to create PNG and PDF outputs;
8. performs a task-level result check and corrects failures before delivery;
9. returns the three artifact paths with a short explanation of the mapping
   and material design choices.

Case retrieval is an internal reasoning aid, not a sequence the user must
operate manually.

### Iteration

Follow-up requests such as changing point size, palette, labels, facets,
annotations, dimensions, or statistical layers update the existing `plot.R`
and regenerate both output formats. FigureForge should preserve prior
confirmed mappings and design choices unless the user asks to change them.

## Case Library Model

The case library is the agent's visual experience and code knowledge base. It
is not a gate that turns every task into a formal case migration.

For each request:

- one primary case supplies the closest overall scientific comparison, data
  shape, and visual grammar;
- zero or more secondary cases may supply reusable local patterns;
- the final script is newly adapted to the user's data and may combine
  compatible ideas from multiple cases;
- the agent does not mechanically copy a case script or require the output to
  remain structurally identical to one case;
- provenance and distribution metadata are consulted when their constraints
  are relevant, not displayed as routine user ceremony.

The normal inspection path prioritizes the selected case's explanation,
plotting code, and relevant data structure. Reading every case artifact is no
longer mandatory for every plotting request.

## Skill Boundary

### Main Skill responsibilities

The main `SKILL.md` covers only:

- request and data interpretation;
- case-backed visual design;
- R package and visual-encoding selection;
- script creation and execution;
- task-level visual and artifact checks;
- delivery and conversational iteration.

### Background resources

The agent may use:

- `scripts/search_cases.R` for case retrieval;
- `references/ggplot-patterns.md` for reusable plotting patterns;
- `references/theme-and-export.md` for publication-oriented styling and
  export;
- `references/data-mapping.md` for complex field mapping;
- `scripts/doctor.R` when runtime or dependency problems arise;
- case `plot.R`, narrative, metadata, and example schema as needed.

These resources support the task without dictating a visible multi-stage user
workflow.

### Maintainer responsibilities

The following remain in the repository and package but move out of the normal
plotting flow:

- case authoring, standardization, indexing, and corpus auditing;
- provenance, distribution, blocker, and completion validation;
- private corpus governance;
- stress fixture generation and forward evaluation;
- Skill packaging, upgrade checks, archive verification, and release
  certification;
- the complete adaptation and release contracts.

A maintainer workflow reference will provide the entry point for these
responsibilities. Existing scripts should be retained unless a later
implementation review demonstrates that a script is redundant.

## Artifact Contract

Each successful plotting task creates an output directory containing:

```text
figureforge-output/
├── plot.R
├── plot.png
└── plot.pdf
```

The script must support:

```bash
Rscript plot.R <input-file> <output-directory>
```

The same script invocation produces `plot.png` and `plot.pdf`. The script must:

- validate its input file and required columns;
- emit clear errors for invalid or incompatible values;
- load or check its required packages explicitly;
- use deterministic settings for stochastic layouts or label placement;
- avoid dependence on temporary agent-session state;
- preserve Chinese column names and labels when R and the selected packages
  support them;
- generate non-empty outputs at caller-selected paths.

The filenames may be extended only when the user explicitly requests multiple
figures or a different naming convention.

## Ambiguity and Error Handling

The agent asks the user only when a decision could materially alter the
scientific meaning, including:

- multiple plausible x or y variables;
- an unknown grouping variable;
- ambiguous aggregation, normalization, or repeated-measure semantics;
- an unsupported statistical test or transformation;
- missing units that affect interpretation.

The agent chooses professional defaults for non-scientific presentation
details such as theme, font sizing, legend placement, point size, export
dimensions, and initial palette. These remain conversationally editable.

When a required R package is missing, the agent may use a compatible
alternative only if it preserves the scientific and visible intent. Otherwise
it reports the exact dependency and installation guidance. It must not silently
downgrade the requested visualization.

If code or rendering fails, the agent diagnoses the failure, updates the
script, and reruns it. Failed or unexecuted example code is not a successful
delivery. If the data cannot support the requested chart, the agent explains
why and recommends the closest valid representation.

## Task-Level Quality Check

Before delivery, the agent verifies:

- `plot.R`, `plot.png`, and `plot.pdf` exist and are non-empty;
- the script reruns successfully against the supplied input;
- the PNG and PDF can be opened or rendered;
- expected rows, groups, labels, and legends are represented;
- obvious clipping, overlap, empty panels, or unreadable labels are absent;
- the visual encoding still answers the user's stated scientific question.

This check is deliberately narrower than corpus audit or release
certification. Full case governance remains a maintainer concern.

## Documentation and Positioning

The English and Chinese READMEs will describe FigureForge first as an
AI-driven, case-enhanced scientific plotting capability for R. The primary
quick-start example will use a natural-language plotting request and show the
three returned artifacts.

The case corpus remains a core product asset, but the public explanation
changes from "follow a controlled case migration workflow" to "use accumulated
case knowledge to help an agent design and execute better plots."

The planned MCP layer remains local-first and unimplemented. Future MCP tools
may expose case retrieval, inspection, validation, rendering, and mapping to
other agents, but MCP does not define the user-facing Skill workflow.

## Compatibility and Versioning

This change is targeted for FigureForge Skill v1.1.0.

Existing validation, search, package, archive, and release commands remain
supported. The v1.0.1 release evidence remains valid for v1.0.1 and is not
rewritten. New v1.1.0 evidence will distinguish:

- user plotting behavior and artifact delivery;
- platform, corpus, distribution, and package reliability.

Existing case data and scripts are not deleted or redistributed differently by
this design.

## Acceptance Criteria

The implementation is accepted when:

1. the main Skill presents FigureForge as a plotting capability enhancer and
   no longer exposes maintainer governance as the ordinary user workflow;
2. a request using a real CSV and an explicit chart family produces a
   standalone `plot.R`, `plot.png`, and `plot.pdf`;
3. the delivered script regenerates both images in an independent run;
4. the agent uses one primary case and can draw local patterns from secondary
   cases without mechanically copying a single case;
5. Chinese columns, missing values, groups, and long labels are covered by
   behavioral evaluations;
6. questions are reserved for ambiguity that changes scientific meaning;
7. follow-up style or annotation requests update the script and both renders;
8. existing case, distribution, packaging, upgrade, and release tests remain
   available as maintainer reliability checks;
9. README and README.zh.md remain aligned on the new product definition;
10. no MCP implementation is claimed or required.

## Out of Scope

- Python plotting support;
- an MCP server implementation;
- deletion or replacement of the private case corpus;
- automatic scientific validation of the user's conclusions;
- automatic installation of R or system dependencies;
- a graphical application or interactive plot editor;
- splitting maintainer capabilities into a second installable Skill.
