# FigureForge Skill v1.0 Public Distribution Design

Date: 2026-07-25

## Status

Approved design. This specification defines the public FigureForge Skill v1.0
release. It does not authorize or include an MCP Server.

## Goal

Turn the existing FigureForge Skill framework into a publicly installable,
independently usable v1.0 package with:

- a small redistributable gallery derived from general visual patterns learned
  from the completed private corpus;
- at least 20 explicit synthetic adaptation stress tests;
- safe workspace generation outside every source case directory;
- layered dependency diagnostics;
- machine-readable classification, schema matching, and bilingual ranking;
- assisted visual QA that never grants verified status automatically; and
- versioned documentation, packaging, and clean-environment acceptance proof.

The private 165-case corpus remains a local validation and design resource. It
is not part of the public package.

## Decision

Use a controlled public-curation architecture.

The v1.0 package will ship 12 newly authored public cases and at least 20
separate synthetic adaptation fixtures. Public cases are user-facing examples.
Stress fixtures are test assets. They must remain distinguishable in metadata,
documentation, search results, and QA reports.

The public assets may reuse only general plotting ideas and visual grammar from
private cases. Public scripts, data, prose, and metadata must be newly authored
or come from a source whose redistribution terms are recorded and compatible.
No private data, third-party reference images, paper attachments, historical
reproductions, or rights-uncertain text may be copied into the public package.

## Repository Boundaries

The public release lives entirely in the existing public worktree and branch:

```text
.worktrees/figureforge-skill-mvp/
└── skills/figureforge/
    ├── SKILL.md
    ├── VERSION
    ├── agents/
    ├── public-cases/
    ├── references/
    ├── schemas/
    ├── scripts/
    └── lib/
```

Public tests and fixtures live under:

```text
tests/
├── figureforge/
└── fixtures/figureforge/
    ├── adaptations/
    ├── public-cases/
    └── stress/
```

The private corpus remains at:

```text
/Users/liuyue/Desktop/Github_repos/FigureForge/skills/figureforge/cases
```

Generated renders, indexes, QA reports, package archives, clean-clone
workspaces, and logs must stay in ignored output or temporary directories.
Public code may read an explicitly supplied private case root, but no build,
test, package, or clean-clone acceptance step may require that private root.

## Public Case Contract

The initial curated gallery contains exactly 12 cases selected to provide broad
visual-family coverage rather than one-to-one copies of private cases:

1. grouped or stacked bar;
2. box, violin, or raincloud distribution;
3. scatter with fit and optional significance annotation;
4. time series with uncertainty;
5. heatmap or correlation matrix;
6. bubble plot or enrichment display;
7. volcano or ordination plot;
8. network graph;
9. survival curve;
10. phylogenetic tree with annotation;
11. gene structure, motif, or domain diagram;
12. faceted or multi-panel composition.

Each public case contains:

```text
public-cases/<case-id>/
├── case.md
├── case.yml
├── data.csv
├── plot.R
├── qa.md
└── distribution.yml
```

Every case must:

- provide `case.yml` as the versioned machine-readable authority for
  classification, schema roles, bilingual aliases, QA, distribution, and
  synthetic-data disclosure, while `case.md` remains the human-readable
  explanation;
- accept `input_path` and `output_path` as its first two command-line
  arguments;
- validate the input file, required columns, types, and critical values;
- declare required and optional R packages separately;
- render successfully with `/usr/local/bin/Rscript` into a caller-selected
  external path;
- document its chart family, scientific use, schema roles, transformations,
  limits, data origin, and distribution decision;
- use `Status: review_required` until a human performs and records visual QA;
  and
- pass public case validation without consulting the private corpus.

`distribution.yml` is fail-closed and names every distributed asset. It
records:

- `distribution_status: public_ready`;
- the asset list;
- origin and copyright holder for each asset class;
- license or public-domain basis;
- whether the data are synthetic;
- review date; and
- reviewer or release authority.

Absence, ambiguity, an unrecognized license, or an asset missing from the
allowlist makes the case non-distributable.

For v1.0, generated data are the default. Every generated public dataset must
declare:

```yaml
synthetic_test_fixture: true
scientific_claims: none
```

The accompanying prose must state that the values exist only for
demonstration and testing and do not represent a real study.

## Synthetic Stress-Test Contract

Stress tests are not gallery cases and are never described as authentic
research examples. The suite contains at least 20 scenarios spanning the
public chart families and adaptation failure modes.

Each stress scenario contains machine-readable metadata, an input file, an
expected mapping, and assertions. Its metadata includes:

- stable fixture ID;
- `synthetic_test_fixture: true`;
- source public-case ID;
- chart family;
- tested schema roles;
- intended success or failure outcome;
- expected warnings or errors; and
- deterministic generation seed.

The minimum suite covers:

- renamed English columns;
- Chinese column names and labels;
- reordered factors;
- missing optional values;
- rejected missing required values;
- duplicate keys;
- invalid numeric values;
- zero and negative values where semantically relevant;
- outliers;
- long labels;
- sparse groups;
- imbalanced groups;
- large row counts;
- dates and irregular time intervals;
- faceting;
- multi-panel inputs;
- deterministic stochastic layouts;
- optional-package absence;
- unsupported schema mappings; and
- attempts to write inside a source case directory.

At least one successful scenario must exercise each public case. Failure
fixtures must assert the exact failure category, not merely a non-zero exit
status. Test output must be written outside fixture directories.

## Safe Adaptation Workspace

Add one workspace generator with a stable command-line interface:

```bash
/usr/local/bin/Rscript skills/figureforge/scripts/create_adaptation.R \
  --case "<public-case-id-or-path>" \
  --input "<user-data.csv>" \
  --workspace "<new-output-directory>" \
  [--mapping "<mapping.csv>"] \
  [--force-empty]
```

The generator:

1. resolves and canonicalizes the case, input, and workspace paths;
2. rejects a workspace equal to, inside, or containing a source case
   directory;
3. rejects the private corpus and repository case roots as output targets;
4. creates only a new directory or an explicitly allowed empty directory;
5. copies the redistributable plotting script, never source case data or
   reproductions;
6. copies user input to `input.csv` without modifying the source;
7. writes a draft `mapping.md` and `qa.md`;
8. records the source public-case ID, script checksum, tool version, and
   creation time in `adaptation.yml`; and
9. leaves QA as `Status: review_required`.

`--force-empty` permits reuse only when the target exists, is empty, and is
outside all protected roots. It never authorizes deletion or overwrite.
Partial failures must remove only files created by the current invocation and
must never alter the user input or source case.

## Dependency Doctor

Add:

```bash
/usr/local/bin/Rscript skills/figureforge/scripts/doctor.R \
  [--case "<case-id-or-path>"] \
  [--format text|json] \
  [--strict]
```

The doctor reports four layers independently:

1. runtime: supported R version and the resolved `Rscript`;
2. system tools: commands needed for parsing, rendering, PDF inspection, or
   packaging;
3. required R packages: necessary for the selected operation or case;
4. optional R packages: enable particular chart families or enhancements.

Every check returns a stable ID, layer, requirement level, detected version,
status, remediation text, and affected capability. Text output is human
readable; JSON output is deterministic and versioned.

Missing optional dependencies produce warnings and name disabled
capabilities. Missing required dependencies make `--strict` fail. The doctor
must not install packages or system tools.

## Classification, Schema Matching, and Search

Add a versioned public case schema and taxonomy under
`skills/figureforge/schemas/`. Machine-readable case metadata must include:

- stable case ID and schema version;
- English and Chinese title;
- chart family and subfamily;
- aliases in both languages;
- scientific intents;
- required and optional schema roles;
- accepted types and cardinalities;
- supported annotations and layouts;
- required and optional packages;
- QA status;
- distribution status; and
- synthetic-data disclosure.

The public index is a tracked, deterministic release asset generated only from
public cases. Local private indexes remain ignored and separate.

Search ranking is deterministic and exposes component scores. Ranking order is:

1. exact case ID;
2. exact bilingual title or alias;
3. chart family or subfamily;
4. schema-role compatibility;
5. scientific intent;
6. annotation or layout compatibility;
7. QA and dependency readiness.

Distribution status is a filter and safety gate, not a relevance bonus.
Private-only cases never enter the packaged public index. Equal scores use
stable case ID ordering.

Schema matching reports:

- compatible, partially compatible, or incompatible;
- explicit field-to-role mappings;
- missing required roles;
- type or cardinality conflicts;
- allowed transformations;
- assumptions needing human confirmation; and
- candidate cases with score breakdowns.

Chinese and English query tests use paired intents and assert stable top
results and score explanations rather than relying on undocumented substring
behavior.

## Assisted Visual QA

Add a visual-QA assistant that accepts a rendered output and optional reference
or prior approved render:

```bash
/usr/local/bin/Rscript skills/figureforge/scripts/visual_qa.R \
  --render "<output.pdf-or-image>" \
  [--reference "<reference.pdf-or-image>"] \
  --report "<qa-report.json>"
```

The assistant may collect:

- file existence, format, page count, dimensions, and size;
- rasterization success;
- blank or near-blank output;
- clipping risk at image boundaries;
- low-contrast or overly dense regions;
- reference dimension mismatch;
- deterministic pixel or perceptual-difference summaries; and
- manual-review prompts derived from the chart family.

Its output status is always one of:

- `review_required`;
- `tool_check_failed`; or
- `not_applicable`.

The tool must never emit or write `verified`, modify a source `qa.md`, or
claim scientific correctness. A human reviewer may use its report as evidence
and separately update the adaptation or public case QA record.

## Skill Workflow

The v1.0 `SKILL.md` keeps the evidence-based workflow but works from a clean
public installation:

```text
understand goal
→ inspect actual data
→ search the public gallery in Chinese or English
→ compare schema matches and dependency readiness
→ create an external adaptation workspace
→ confirm mapping
→ render
→ run assisted visual checks
→ perform human visual QA
→ independently re-render
→ report provenance, limits, and distribution boundary
```

An explicitly supplied local private case root may extend search and local
adaptation, but public cases are always available and public commands never
assume the private corpus exists.

## Versioning, Packaging, and Documentation

The release adds:

- `skills/figureforge/VERSION` containing `1.0.0`;
- a top-level `CHANGELOG.md`;
- aligned English and Chinese installation, upgrade, quick-start, and
  distribution documentation;
- a public demo that starts from generated data and produces an adaptation
  outside the installed Skill;
- a reproducible packaging script or documented package command; and
- a machine-readable release manifest listing included public files and their
  checksums.

The package must exclude:

- the private `cases/` corpus except the existing authoring template if it is
  explicitly retained;
- third-party images and paper attachments;
- historical reproductions;
- local indexes and audits;
- rendered demo or QA outputs;
- caches, logs, and temporary workspaces; and
- all MCP Server code and dependencies.

README files must describe MCP only as planned and must not list an
implemented MCP command.

## Testing Strategy

All behavior changes use red-green-refactor:

1. write one focused failing test;
2. run it and confirm the expected failure;
3. implement the smallest behavior that passes;
4. rerun the focused and full FigureForge suites; and
5. commit the public change.

The test layers are:

- unit tests for path safety, license allowlists, taxonomy validation, score
  calculation, schema matching, doctor classification, and QA status;
- contract tests for all command-line interfaces and JSON schemas;
- render tests for every public case;
- at least 20 synthetic adaptation stress scenarios;
- bilingual ranking tests;
- negative distribution and protected-path tests;
- package-content tests;
- official Skill validation; and
- clean-clone end-to-end acceptance.

Tests must verify that source cases and fixtures retain their original
checksums and modification times.

## Seven-Stage Delivery

### Stage 1: Public curated gallery

Implement the distribution schema and validator first. Review and author the
12 public cases, then validate their metadata, assets, rendering, QA boundary,
and package eligibility.

### Stage 2: Synthetic adaptation stress suite

Add a deterministic fixture generator and at least 20 declared scenarios.
Record pass/fail outcomes by chart family and failure category.

### Stage 3: Safe workspace generator

Implement path protection, atomic workspace creation, provenance recording,
mapping drafts, and source immutability tests.

### Stage 4: Dependency doctor

Implement layered detection, text and JSON output, strict behavior, and
capability-specific remediation.

### Stage 5: Classification and search

Implement the versioned taxonomy, deterministic public index, schema matcher,
score explanations, and paired bilingual ranking tests.

### Stage 6: Assisted visual QA

Implement non-authoritative automated checks and machine-readable reports.
Prove that no automated path can grant verified status.

### Stage 7: Release acceptance

Finalize versioning, changelog, bilingual documentation, public demo,
packaging, release manifest, and clean-clone end-to-end verification.

Each stage ends with the full FigureForge test suite, R parse checks,
`quick_validate.py`, `git diff --check`, a public-only local commit, and no
push.

## Acceptance Gates

Skill v1.0 is complete only when current evidence proves all of the following:

- 12 public cases are independently rendered and pass distribution validation;
- every distributed asset appears in an approved allowlist with a recorded
  redistribution basis;
- at least 20 declared synthetic stress scenarios pass with outputs outside
  fixture and source directories;
- the workspace generator rejects every protected-path and overwrite attempt;
- doctor text and JSON modes correctly distinguish runtime, system, required,
  and optional dependencies;
- the public index validates against the versioned schema;
- bilingual and schema-aware ranking tests are deterministic;
- assisted visual QA never emits or writes verified status;
- the demo works without the private corpus;
- the package manifest contains only public allowlisted files;
- all FigureForge tests and R parse checks pass;
- official Skill validation passes;
- a clean local clone can install, diagnose, search, generate an adaptation,
  render, run assisted QA, validate, and package the Skill;
- README, README.zh, status documentation, version, and changelog agree;
- MCP remains planned and absent; and
- all commits are local and nothing is pushed.

## Git and Review Policy

Only public code, tests, templates, schemas, and documentation are committed.
Private cases and generated artifacts remain untracked or ignored. Each stage
uses a clear local commit. Before every commit, inspect staged paths to prove
that no private or generated material is included.

The final report lists stage commits, public cases, stress scenarios, family
coverage, dependency capabilities, verification commands and outputs, package
contents, ignored local evidence locations, and the stable future MCP input
boundary. The final report does not describe MCP as implemented.
