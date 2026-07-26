# FigureForge Case-Grounded Generation Design

**Date:** 2026-07-26
**Status:** Approved

## Goal

Make FigureForge case knowledge materially and audibly participate in plot
generation. An agent may describe a result as "generated from FigureForge case
knowledge" only when it actually read the selected case, adapted concrete
knowledge from it, and produced a valid trace of that work.

Preserve general plotting ability. When no sufficiently relevant and readable
case exists, FigureForge may use a general R plotting method, but it must label
the result as a general fallback rather than case-grounded generation.

## Corrected Product Contract

FigureForge supports two explicit generation modes:

### `case_based`

Use this mode only when the agent:

1. searches the FigureForge gallery against the user's scientific intent and
   real data schema;
2. selects one primary case;
3. reads the primary case's `case.md` and `plot.R`;
4. reads `qa.md` when it exists and records when it does not;
5. maps the user's fields to the case's documented roles;
6. records the visual or code patterns it adopted;
7. records intentional departures and their reasons;
8. writes a new standalone `plot.R` for the user's real input;
9. renders and reviews the PNG and PDF;
10. validates the case-use trace before making a case-grounded claim.

Searching for or naming a case is not evidence that the case was used.
Reading metadata without reading the implementation is also insufficient.

### `general_fallback`

Use this mode when no candidate is sufficiently relevant, readable, or
adaptable. The task still produces the normal R script and rendered artifacts.
The trace must record why case-based generation was not used and may record
cases that were considered and rejected.

A fallback result must not claim that its design or implementation was
generated from FigureForge case knowledge.

## User Experience

The ordinary request remains concise:

> Use this data and the FigureForge Skill to draw a PCA plot, and give me the R
> script.

The default visible response still returns:

```text
plot.R
plot.png
plot.pdf
```

Case discovery, evidence capture, and trace validation happen in the
background. The response adds one short provenance statement:

- case-based: identify the primary case and summarize material adaptations;
- fallback: state that no sufficiently matching case was used and that the
  result was produced with a general R plotting method.

## Generation Flow

```text
inspect user data
        |
search FigureForge cases
        |
is a sufficiently relevant case readable?
        |
    +---+---+
    |       |
   yes      no
    |       |
case_based  general_fallback
    |       |
read case   record fallback reason
evidence    and rejected candidates
    |       |
map schema and design the plot
        |
write and run standalone plot.R
        |
inspect plot.png and plot.pdf
        |
write and validate case-use trace
        |
return the three default artifacts
```

## Case-Use Trace

Each task writes an internal trace outside the installed Skill and all case
directories:

```text
figureforge-output/
├── plot.R
├── plot.png
├── plot.pdf
└── .figureforge/
    └── case-trace.yml
```

The hidden trace does not add a fourth default user-facing deliverable.

### Required common fields

- `schema_version`
- `generation_mode`
- `figureforge_version`
- `generated_script_sha256`

### Required `case_based` fields

- `primary_case_id`
- `case_evidence`
  - `case.md` filename and SHA-256
  - `plot.R` filename and SHA-256
  - `qa.md` filename and SHA-256 when present
  - explicit `qa_status: missing` when absent
- `schema_mapping`
- `adopted_patterns`
- `departures`

`adopted_patterns` must name concrete material decisions, such as the overall
composition, layer strategy, specialist idiom, annotation approach, or
validated implementation technique. Generic statements such as "used colors"
or "made a scientific plot" are insufficient.

### Required `general_fallback` fields

- `fallback_reason`
- optional `considered_cases` with rejection reasons

A fallback trace must not contain a case-grounded generation claim.

### Privacy boundary

The trace stores case IDs, relative evidence filenames, hashes, and abstracted
design decisions. It must not store private case source code, private data,
absolute corpus paths, or source figures.

## Components

### Skill contract

Update `skills/figureforge/SKILL.md` so case use is a provenance-bearing
operation, not an informal suggestion. Keep the main workflow concise and
route detailed requirements to a new reference.

### Case-use reference

Add `skills/figureforge/references/case-use-contract.md` with:

- mode selection rules;
- trace schema and examples;
- claim language;
- evidence quality rules;
- common invalid shortcuts.

### Trace validator

Add `skills/figureforge/scripts/validate_case_trace.R` and a focused library
module. Reuse existing metadata, checksum, and adaptation utilities where they
fit rather than creating a parallel validation framework.

The validator checks:

- required files and fields;
- allowed generation modes;
- required evidence for `case_based`;
- evidence and generated-script hashes;
- nonempty schema mappings and adopted patterns;
- recorded QA status;
- fallback reasons;
- contradictory mode or claim fields;
- absence of absolute private paths and embedded private source material.

### Existing adaptation workflow

Retain the full adaptation workspace for maintainers, formal migrations, and
case certification. The task-level case trace is intentionally smaller. It
borrows the adaptation workflow's provenance and mapping principles without
requiring ordinary users to receive `mapping.md`, `qa.md`, and
`adaptation.yml`.

## Error Handling

- If `case.md` or `plot.R` was not read, use `general_fallback`.
- If `qa.md` exists, read and hash it. If it does not, record
  `qa_status: missing` and a lower evidence level.
- If evidence changes between reading and validation, fail validation and
  reread the case before regenerating the trace.
- If a selected case cannot map meaningfully to the user's data, reject it and
  continue searching.
- If no usable case remains, complete the task in `general_fallback`.
- If a trace fails validation, do not make a case-grounded claim.
- Rendering or scientific-data failures remain normal task failures and must
  be diagnosed independently of provenance mode.

## Iris PCA Acceptance Demo

Replace the unsupported provenance in the Iris PCA demo with a genuine
case-grounded execution using private case `20230925_PCA`.

The implementation must read that case's `case.md`, `plot.R`, and `qa.md`.
The adapted result may differ from the source case, but it must explain:

- how Iris columns map onto the case's PCA roles;
- which source-case patterns were adopted;
- which source-case patterns were rejected or changed;
- why `stats::prcomp`, loading arrows, a single biplot, or other deviations
  were selected if they remain in the adapted result;
- the successful `case_based` trace validation result.

The HTML report should show this concise adaptation summary without exposing
private source code, data, or paths.

## Testing Strategy

### RED baseline

Preserve the observed failure as the baseline behavior: the previous Iris
implementation named `20230925_PCA` but its implementation task did not read
the case or the FigureForge Skill. This demonstrates that documentation-only
case selection is insufficient.

### Validator tests

Cover at least:

- a valid `case_based` trace;
- missing `case.md` evidence;
- missing `plot.R` evidence;
- changed evidence hash;
- changed generated-script hash;
- empty schema mapping;
- empty or generic adopted patterns;
- missing QA evidence when `qa.md` exists;
- valid recorded missing QA;
- a valid `general_fallback` trace;
- fallback without a reason;
- fallback containing a case-grounded claim;
- private absolute paths or embedded private material.

### Skill behavior tests

Run realistic plotting prompts against the old and revised Skill:

- a request with a strong matching case must produce readable case evidence
  and a valid `case_based` trace;
- a request without a sufficient match must complete through
  `general_fallback`;
- neither mode may overstate its provenance.

Forward tests must receive the task and Skill artifacts without the expected
answer or diagnosis.

### Artifact and demo tests

Continue to verify:

- the standalone `Rscript plot.R <input-file> <output-directory>` contract;
- nonempty, decodable PNG and renderable PDF;
- preservation of the input;
- deterministic tabular results where applicable;
- case-trace validation;
- correct provenance wording in the HTML and response;
- no distributed private case material.

## Documentation and Compatibility

Keep the English and Chinese READMEs aligned. Explain the two modes without
turning trace operation into user ceremony.

The three-artifact default and existing plotting-script interface remain
compatible. Existing case search, adaptation, packaging, and release commands
remain supported. The case trace adds internal evidence; it does not expose
the private corpus or require MCP.

This design supersedes the unsupported case-use claim in
`2026-07-26-figureforge-iris-pca-demo-design.md`. The statistical and artifact
requirements of that design remain valid.

## Completion Criteria

The feature is complete when:

- the Skill distinguishes `case_based` and `general_fallback`;
- only validated case-based tasks can claim FigureForge case knowledge;
- a deterministic validator enforces the trace contract;
- old failure behavior is covered by regression tests;
- forward tests demonstrate both modes;
- the Iris PCA demo reads and adapts `20230925_PCA` with a valid trace;
- all plotting, documentation, packaging, and release-boundary tests pass;
- no private case asset enters tracked output or a release archive.
